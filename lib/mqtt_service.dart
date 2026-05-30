import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'settings_service.dart';
import 'notification_service.dart';
import 'db_service.dart';
import 'i18n/app_strings.dart';

enum MqttConnectionState { connected, disconnected, connecting, error }

class MqttService {
  MqttServerClient? client;

  final settings = SettingsService();
  final _notifications = NotificationService();
  final _dbService = DbService();

  final _tempStream = StreamController<String>.broadcast();
  final _humStream = StreamController<String>.broadcast();
  final _stateStream = StreamController<MqttConnectionState>.broadcast();

  MqttConnectionState currentState = MqttConnectionState.disconnected;
  int _retryCount = 0;
  Timer? _reconnectTimer;
  Timer? _watchdogTimer;        // слідкує чи живий ESP32
  bool _isConnecting = false;

  // Таймери для бази даних
  DateTime? _lastTempDbSave, _lastHumDbSave;

  // 4 окремі таймери для сповіщень
  DateTime? _lastTempHighAlert, _lastTempLowAlert;
  DateTime? _lastHumHighAlert, _lastHumLowAlert;

  // Скільки секунд чекаємо даних від ESP32 перш ніж вважати його офлайн
  static const int _watchdogSeconds = 15;

  Stream<String> get tempStream => _tempStream.stream;
  Stream<String> get humStream => _humStream.stream;
  Stream<MqttConnectionState> get stateStream => _stateStream.stream;

  Future<void> connect() async {
    if (_isConnecting) return;
    _isConnecting = true;
    _reconnectTimer?.cancel();

    currentState = MqttConnectionState.connecting;
    _stateStream.add(MqttConnectionState.connecting);

    await settings.load();
    await _notifications.init();

    final String clientId = 'roman_iot_${DateTime.now().millisecondsSinceEpoch}';
    const String server = "broker.emqx.io";
    const String mqttUser = "";
    const String mqttPass = "";

    if (kIsWeb) {
      client = MqttServerClient.withPort(server, clientId, 8084);
      client!.useWebSocket = true;
    } else {
      client = MqttServerClient.withPort(server, clientId, 8883);
      client!.useWebSocket = false;
    }

    client!.secure = true;

    if (kDebugMode) {
      client!.onBadCertificate = (dynamic certificate) => true;
    }

    client!.logging(on: false);
    client!.keepAlivePeriod = 20;
    client!.autoReconnect = false;
    client!.setProtocolV311();

    try {
      debugPrint("MQTT: Підключення до $server...");
      final connResult = await client!.connect(mqttUser, mqttPass);

      if (connResult?.returnCode != MqttConnectReturnCode.connectionAccepted) {
        throw Exception('Broker відхилив: ${connResult?.returnCode}');
      }

      _retryCount = 0;
      _isConnecting = false;

      // З'єднання з брокером є, але ESP32 ще не підтвердив —
      // показуємо connecting поки не прийдуть реальні дані
      currentState = MqttConnectionState.connecting;
      _stateStream.add(MqttConnectionState.connecting);

      // Запускаємо watchdog: якщо за _watchdogSeconds даних немає — disconnected
      _resetWatchdog();

      client!.subscribe('roman_41ki/temp', MqttQos.atMostOnce);
      client!.subscribe('roman_41ki/hum', MqttQos.atMostOnce);

      client!.onDisconnected = () {
        _isConnecting = false;
        _watchdogTimer?.cancel();
        currentState = MqttConnectionState.disconnected;
        _stateStream.add(MqttConnectionState.disconnected);

        int delay = (2 << _retryCount).clamp(2, 60);
        _retryCount++;
        debugPrint("MQTT: розрив, перепідключення через ${delay}s");
        _reconnectTimer = Timer(Duration(seconds: delay), () => connect());
      };

      client!.updates!.listen((c) {
        final recMess = c[0].payload as MqttPublishMessage;
        final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        _processData(c[0].topic, pt);
      });
    } catch (e) {
      _isConnecting = false;
      _handleConnectionError(e);
    }
  }

  /// Перезапускає watchdog таймер при кожному новому повідомленні від ESP32.
  /// Якщо за _watchdogSeconds секунд нічого не прийшло — ESP32 офлайн.
  void _resetWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(const Duration(seconds: _watchdogSeconds), () {
      debugPrint("MQTT watchdog: немає даних від ESP32 $_watchdogSeconds с");
      if (currentState != MqttConnectionState.error) {
        currentState = MqttConnectionState.disconnected;
        _stateStream.add(MqttConnectionState.disconnected);
      }
    });
  }

  void _handleConnectionError(dynamic error) {
    debugPrint("MQTT Error: $error");
    _watchdogTimer?.cancel();
    currentState = MqttConnectionState.error;
    _stateStream.add(MqttConnectionState.error);

    int delay = (2 << _retryCount).clamp(2, 60);
    _retryCount++;
    _reconnectTimer = Timer(Duration(seconds: delay), () => connect());
  }

  void _processData(String topic, String payload) {
    double? val = double.tryParse(payload);
    if (val == null) return;

    // Дані від ESP32 прийшли — він живий, скидаємо watchdog
    _resetWatchdog();

    // Якщо були в стані connecting/disconnected — переходимо в connected
    if (currentState != MqttConnectionState.connected) {
      currentState = MqttConnectionState.connected;
      _stateStream.add(MqttConnectionState.connected);
    }

    String type = topic.contains('temp') ? 'temp' : 'hum';
    DateTime now = DateTime.now();

    if (type == 'temp') {
      _tempStream.add(payload);
      if (_lastTempDbSave == null || _lastTempDbSave!.minute != now.minute) {
        _dbService.insertLog(type, val);
        _lastTempDbSave = now;
      }
    } else {
      _humStream.add(payload);
      if (_lastHumDbSave == null || _lastHumDbSave!.minute != now.minute) {
        _dbService.insertLog(type, val);
        _lastHumDbSave = now;
      }
    }

    String? alarmMsg = settings.checkAlarm(val, type);

    if (alarmMsg != null) {
      bool shouldNotify = false;

      if (alarmMsg == 'temp_high') {
        if (_lastTempHighAlert == null || now.difference(_lastTempHighAlert!).inMinutes >= 5) {
          shouldNotify = true;
          _lastTempHighAlert = now;
        }
      } else if (alarmMsg == 'temp_low') {
        if (_lastTempLowAlert == null || now.difference(_lastTempLowAlert!).inMinutes >= 5) {
          shouldNotify = true;
          _lastTempLowAlert = now;
        }
      } else if (alarmMsg == 'hum_high') {
        if (_lastHumHighAlert == null || now.difference(_lastHumHighAlert!).inMinutes >= 5) {
          shouldNotify = true;
          _lastHumHighAlert = now;
        }
      } else if (alarmMsg == 'hum_low') {
        if (_lastHumLowAlert == null || now.difference(_lastHumLowAlert!).inMinutes >= 5) {
          shouldNotify = true;
          _lastHumLowAlert = now;
        }
      }

      if (shouldNotify) {
        String currentLang = 'uk';
        String localizedBody = S.tr(alarmMsg, currentLang);
        String titleKey = type == 'temp' ? 'alert_temp_title' : 'alert_hum_title';
        String localizedTitle = S.tr(titleKey, currentLang);
        _notifications.show(localizedTitle, localizedBody);
      }
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _watchdogTimer?.cancel();
    _tempStream.close();
    _humStream.close();
    _stateStream.close();
    client?.disconnect();
  }
}