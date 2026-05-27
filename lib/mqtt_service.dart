import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'settings_service.dart';
import 'notification_service.dart';
import 'db_service.dart';

enum MqttConnectionState { connected, disconnected, connecting, error }

class MqttService {
  // ВИПРАВЛЕНО 1: Змінено 'late' на nullable '?', щоб уникнути LateInitializationError
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
  DateTime? _lastTempDbSave, _lastHumDbSave;
  DateTime? _lastTempAlert, _lastHumAlert;

  Stream<String> get tempStream => _tempStream.stream;
  Stream<String> get humStream => _humStream.stream;
  Stream<MqttConnectionState> get stateStream => _stateStream.stream;

  Future<void> connect() async {
    _reconnectTimer?.cancel();
    currentState = MqttConnectionState.connecting;
    _stateStream.add(MqttConnectionState.connecting);
    
    await settings.load();
    await _notifications.init();

    final String clientId = 'roman_iot_${DateTime.now().millisecondsSinceEpoch}';
    const String server = "broker.emqx.io";
    
    // ВИПРАВЛЕНО 2: Прибрано захардкоджені логіни. Використовуємо анонімний доступ, 
    // як у вашому sketch.ino, або їх треба витягувати з Env/Settings.
    const String mqttUser = ""; 
    const String mqttPass = "";

    // НАЛАШТУВАННЯ ДЛЯ ШИФРУВАННЯ
    if (kIsWeb) {
      // Для браузера використовуємо WSS (Secure WebSockets) на порту 8084
      client = MqttServerClient.withPort(server, clientId, 8084);
      client!.useWebSocket = true;
    } else {
      // Для мобільних додатків використовуємо порт 8883 (MQTTS)
      client = MqttServerClient.withPort(server, clientId, 8883);
      client!.useWebSocket = false;
    }

    client!.secure = true; // Увімкнено шифрування
    
    // ВИПРАВЛЕНО 4: Вимикаємо перевірку сертифікатів ТІЛЬКИ в режимі Debug. 
    // У продакшні сертифікати (Let's Encrypt для broker.emqx.io) будуть строго перевірятись.
    if (kDebugMode) {
      client!.onBadCertificate = (dynamic certificate) => true; 
    }
    
    client!.logging(on: false); // Краще вимкнути для чистоти логів
    client!.keepAlivePeriod = 20;
    
    // ВИПРАВЛЕНО 3: Вимкнено вбудований реконект, оскільки нижче реалізовано 
    // власний таймер з exponential backoff (_reconnectTimer).
    client!.autoReconnect = false; 
    
    client!.setProtocolV311();

    try {
      debugPrint("MQTT: Підключення до $server (Шифрування увімкнено)...");
      await client!.connect(mqttUser, mqttPass);
      
      _retryCount = 0; 
      currentState = MqttConnectionState.connected;
      _stateStream.add(MqttConnectionState.connected);
      
      client!.subscribe('roman_41ki/temp', MqttQos.atMostOnce);
      client!.subscribe('roman_41ki/hum', MqttQos.atMostOnce);

      client!.updates!.listen((c) {
        final recMess = c[0].payload as MqttPublishMessage;
        final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        _processData(c[0].topic, pt);
      });
    } catch (e) {
      _handleConnectionError(e);
    }
  }

  void _handleConnectionError(dynamic error) {
    debugPrint("MQTT SSL Error: $error");
    currentState = MqttConnectionState.error;
    _stateStream.add(MqttConnectionState.error);
    
    // Кастомна логіка реконекту (експоненційне зростання затримки до 60 сек)
    int delay = (2 << _retryCount).clamp(2, 60); 
    _retryCount++;
    _reconnectTimer = Timer(Duration(seconds: delay), () => connect());
  }

  void _processData(String topic, String payload) {
    double? val = double.tryParse(payload);
    if (val == null) return;
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

    // Логіка сповіщень
    String? alarmMsg = settings.checkAlarm(val, type);
    if (alarmMsg != null) {
      if (type == 'temp' && (_lastTempAlert == null || now.difference(_lastTempAlert!).inMinutes >= 5)) {
        _notifications.show("УВАГА: ТЕМПЕРАТУРА", alarmMsg);
        _lastTempAlert = now;
      } else if (type == 'hum' && (_lastHumAlert == null || now.difference(_lastHumAlert!).inMinutes >= 5)) {
        _notifications.show("УВАГА: ВОЛОГІСТЬ", alarmMsg);
        _lastHumAlert = now;
      }
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _tempStream.close(); 
    _humStream.close(); 
    _stateStream.close();
    
    // БЕЗПЕЧНИЙ ВИКЛИК: якщо connect() ще не ініціалізував client, 
    // помилки LateInitializationError не буде
    client?.disconnect(); 
  }
}