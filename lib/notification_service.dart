import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  
  // Додаємо внутрішній лічильник для генерації унікальних ID
  int _notificationId = 0;

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true, 
      requestBadgePermission: true, 
      requestSoundPermission: true
    );
    
    // ПРАВИЛЬНО: iOS з великих літер
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: iosSettings),
    );
  }

  Future<void> show(String title, String body) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'iot_alerts', 'IoT Monitoring', 
        importance: Importance.max, 
        priority: Priority.high
      ),
      iOS: DarwinNotificationDetails(),
    );
    
    // Формуємо унікальний ID: беремо поточний час у секундах та додаємо лічильник.
    // Використання .remainder(2147483647) гарантує, що ми не вийдемо за 
    // межі максимального розміру 32-бітного числа (ліміт Android Notification ID).
    final int uniqueId = (DateTime.now().millisecondsSinceEpoch ~/ 1000 + _notificationId++)
        .remainder(2147483647);
        
    await _plugin.show(uniqueId, title, body, details);
  }
}