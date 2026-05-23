// =====================================================================
//  APP STRINGS — UK / EN
//  Static translation dictionary used across the app.
//  Default language: Ukrainian. English is available as a toggle.
//  If a key is missing in the active language, falls back to Ukrainian.
// =====================================================================

class S {
  S._();

  static const List<String> supported = ['uk', 'en'];
  static const String fallback = 'uk';

  static const Map<String, Map<String, String>> _strings = {
    // ── UKRAINIAN ─────────────────────────────────────────────────
    'uk': {
      // Dashboard / AppBar
      'app_title': 'IoT MONITOR',
      'client_active': 'КЛІЄНТ АКТИВНИЙ',
      'user_name': 'Мунтян Роман',
      // Connection Status (Нові ключі для смужки статусу)
      'connected': 'ПІДКЛЮЧЕНО',
      'connecting': 'З\'ЄДНАННЯ…',
      'connection_error': 'ПОМИЛКА З\'ЄДНАННЯ',
      'disconnected': 'ВІДКЛЮЧЕНО',
      
      'link_error': 'ПОМИЛКА ЗВ\'ЯЗКУ', // Виправлено з "лінка"
      'live': 'НАЖИВО',
      'real_time_telemetry': 'РЕАЛЬНИЙ ЧАС',
      'realtime_subtitle':
          'Дані сенсорів передаються через MQTT і зберігаються локально для аналітики та експорту.',

      // Sensor cards
      'temperature': 'ТЕМПЕРАТУРА',
      'humidity': 'ВОЛОГІСТЬ',
      'ok': 'OK',
      'alarm': 'АВАРІЯ',
      'target': 'ЦІЛЬ',
      'tap_for_analytics': 'ТОРКНІТЬСЯ ДЛЯ АНАЛІТИКИ',
      'last_update': 'ОСТАННЄ ОНОВЛЕННЯ',

      // Drawer
      'iot_system_active': 'IoT СИСТЕМА АКТИВНА',
      'streaming_telemetry': 'Передача телеметрії через MQTT',
      'main_menu': 'ГОЛОВНЕ МЕНЮ',
      'export_section': 'ЕКСПОРТ',
      'online': 'ОНЛАЙН',
      'iot_monitor_pro': 'IoT MONITOR PRO V1.0',
      'limits_settings': 'Налаштування лімітів',
      'limits_settings_sub': 'НАЛАШТУВАННЯ ПОРОГІВ',
      'event_log': 'Журнал подій',
      'event_log_sub': 'ЖУРНАЛ ПОДІЙ',
      'analytics': 'Аналітика',
      'analytics_sub': 'АНАЛІТИКА',
      'download_csv': 'Завантажити CSV',
      'download_csv_sub': 'ЕКСПОРТ ДАНИХ',

      // Settings sheet
      'settings_title': 'НАЛАШТУВАННЯ',
      'reset': 'СКИНУТИ',
      'language': 'МОВА',
      'theme': 'ТЕМА',
      'light': 'СВІТЛА',
      'dark': 'ТЕМНА',

      // Alarms
      'temp_too_low': 'Температура занизька',
      'temp_too_high': 'Температура зависока',
      'hum_too_low': 'Вологість занизька',
      'hum_too_high': 'Вологість зависока',

      // Empty / messages
      'log_empty_msg': 'Журнал порожній. Немає даних для завантаження.',
      'no_data_yet': 'ЩЕ НЕМАЄ ДАНИХ',
      'waiting_telemetry': 'Очікування даних з сенсорів…',
      'tap_chart_point': 'Торкніться графіка для точного значення',

      // Analytics
      'analytics_title': 'АНАЛІТИКА',
      'last_samples': 'ОСТАННІ 20 ЗАМІРІВ',
      'temp_now': 'ТЕМП. ЗАРАЗ',
      'hum_now': 'ВОЛ. ЗАРАЗ',
      'temp_avg': 'ТЕМП. СЕРЕД.',
      'hum_avg': 'ВОЛ. СЕРЕД.',
      'timeline': 'ТАЙМЛАЙН',
      'temp_short': 'ТЕМП',
      'hum_short': 'ВОЛ',

      // Log screen
      'log_title': 'ЖУРНАЛ ДАНИХ',
      'event_log_telemetry': 'ЖУРНАЛ ПОДІЙ / ТЕЛЕМЕТРІЯ',
      'filter_by_type': 'ФІЛЬТР ЗА ТИПОМ',
      'all': 'ВСІ',
      'any_date': 'БУДЬ-ЯКА ДАТА',
      'today': 'Сьогодні',
      'no_records': 'НЕМАЄ ЗАПИСІВ',
      'records_appear': 'Записи з\'являться тут після фіксації телеметрії',
      'entries': 'ЗАПИСІВ',
      'delete': 'ВИДАЛИТИ',
      'record_deleted': 'ЗАПИС ВИДАЛЕНО',
      'temperature_label': 'ТЕМПЕРАТУРА / TEMPERATURE',
      'humidity_label': 'ВОЛОГІСТЬ / HUMIDITY',
      'error': 'ПОМИЛКА',
      'info': 'ІНФО',
      'snack_ok': 'OK',
      
      // Clear-all action
      'clear_all': 'ОЧИСТИТИ',
      'confirm_delete_title': 'ВИДАЛИТИ ВСІ ЛОГИ?',
      'confirm_delete_msg':
          'Цю дію неможливо скасувати. Усі записи журналу будуть видалені назавжди.',
      'cancel': 'СКАСУВАТИ',
      'confirm_delete': 'ВИДАЛИТИ',
      'all_logs_cleared': 'УСІ ЛОГИ ВИДАЛЕНО',
    },

    // ── ENGLISH ───────────────────────────────────────────────────
    'en': {
      // Dashboard / AppBar
      'app_title': 'IoT MONITOR',
      'client_active': 'CLIENT ACTIVE',
      'user_name': 'Muntian Roman',
      // Connection Status (Нові ключі для смужки статусу)
      'connected': 'CONNECTED',
      'connecting': 'CONNECTING…',
      'connection_error': 'CONNECTION ERROR',
      'disconnected': 'DISCONNECTED',
      
      'link_error': 'LINK ERROR',
      'live': 'LIVE',
      'real_time_telemetry': 'REAL-TIME TELEMETRY',
      'realtime_subtitle':
          'Sensor data is streamed over MQTT and stored locally for analytics & export.',

      // Sensor cards
      'temperature': 'TEMPERATURE',
      'humidity': 'HUMIDITY',
      'ok': 'OK',
      'alarm': 'ALARM',
      'target': 'TARGET',
      'tap_for_analytics': 'TAP FOR ANALYTICS',
      'last_update': 'LAST UPDATE',

      // Drawer
      'iot_system_active': 'IoT SYSTEM ACTIVE',
      'streaming_telemetry': 'Streaming sensor telemetry over MQTT',
      'main_menu': 'MAIN MENU',
      'export_section': 'EXPORT',
      'online': 'ONLINE',
      'iot_monitor_pro': 'IoT MONITOR PRO V1.0',
      'limits_settings': 'Threshold Settings',
      'limits_settings_sub': 'THRESHOLD SETTINGS',
      'event_log': 'Event Log',
      'event_log_sub': 'EVENT LOGS',
      'analytics': 'Analytics',
      'analytics_sub': 'ANALYTICS',
      'download_csv': 'Download CSV',
      'download_csv_sub': 'EXPORT DATA',

      // Settings sheet
      'settings_title': 'SETTINGS',
      'reset': 'RESET',
      'language': 'LANGUAGE',
      'theme': 'THEME',
      'light': 'LIGHT',
      'dark': 'DARK',

      // Alarms
      'temp_too_low': 'Temperature too low',
      'temp_too_high': 'Temperature too high',
      'hum_too_low': 'Humidity too low',
      'hum_too_high': 'Humidity too high',

      // Empty / messages
      'log_empty_msg': 'Log is empty. No data to download.',
      'no_data_yet': 'NO DATA YET',
      'waiting_telemetry': 'Waiting for sensor telemetry…',
      'tap_chart_point': 'Tap any chart point for exact reading',

      // Analytics
      'analytics_title': 'ANALYTICS',
      'last_samples': 'LAST 20 SAMPLES PER METRIC',
      'temp_now': 'TEMP NOW',
      'hum_now': 'HUM NOW',
      'temp_avg': 'TEMP AVG',
      'hum_avg': 'HUM AVG',
      'timeline': 'TIMELINE',
      'temp_short': 'TEMP',
      'hum_short': 'HUM',

      // Log screen
      'log_title': 'EVENT LOG',
      'event_log_telemetry': 'EVENT LOG / TELEMETRY',
      'filter_by_type': 'FILTER BY TYPE',
      'all': 'ALL',
      'any_date': 'ANY DATE',
      'today': 'Today',
      'no_records': 'NO RECORDS',
      'records_appear': 'Records will appear here once telemetry is captured',
      'entries': 'ENTRIES',
      'delete': 'DELETE',
      'record_deleted': 'RECORD DELETED',
      'temperature_label': 'TEMPERATURE',
      'humidity_label': 'HUMIDITY',
      'error': 'ERROR',
      'info': 'INFO',
      'snack_ok': 'OK',
      
      // Clear-all action
      'clear_all': 'CLEAR ALL',
      'confirm_delete_title': 'DELETE ALL LOGS?',
      'confirm_delete_msg':
          'This action cannot be undone. All log entries will be permanently deleted.',
      'cancel': 'CANCEL',
      'confirm_delete': 'DELETE',
      'all_logs_cleared': 'ALL LOGS CLEARED',
    },
  };

  /// Look up a translation. Falls back to Ukrainian if [langCode] or
  /// the key is missing. As a last resort, returns the key itself.
  static String tr(String key, String langCode) {
    final code = supported.contains(langCode) ? langCode : fallback;
    return _strings[code]?[key] ?? _strings[fallback]?[key] ?? key;
  }
}