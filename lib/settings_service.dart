import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math'; // Додано для використання min() та max()

class SettingsService {
  // 1. Встановлюємо реалістичні межі за замовчуванням
  double tempMin = 10.0, tempMax = 30.0;
  double humMin = 30.0, humMax = 70.0;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    // 2. Змінюємо значення після ?? на відповідні реалістичні
    double loadedTempMin = prefs.getDouble('tempMin') ?? 10.0;
    double loadedTempMax = prefs.getDouble('tempMax') ?? 30.0;
    double loadedHumMin = prefs.getDouble('humMin') ?? 30.0;
    double loadedHumMax = prefs.getDouble('humMax') ?? 70.0;

    // Валідуємо дані при завантаженні (на випадок, якщо в пам'яті вже є "биті" дані)
    tempMin = min(loadedTempMin, loadedTempMax);
    tempMax = max(loadedTempMin, loadedTempMax);
    humMin = min(loadedHumMin, loadedHumMax);
    humMax = max(loadedHumMin, loadedHumMax);
  }

  Future<void> update(double tMin, double tMax, double hMin, double hMax) async {
    // ВАЛІДАЦІЯ: гарантуємо, що min ніколи не буде більше за max.
    // Якщо параметри переплутані, min() і max() автоматично розставлять їх на свої місця.
    final validTempMin = min(tMin, tMax);
    final validTempMax = max(tMin, tMax);
    final validHumMin = min(hMin, hMax);
    final validHumMax = max(hMin, hMax);

    tempMin = validTempMin; 
    tempMax = validTempMax; 
    humMin = validHumMin; 
    humMax = validHumMax;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tempMin', tempMin);
    await prefs.setDouble('tempMax', tempMax);
    await prefs.setDouble('humMin', humMin);
    await prefs.setDouble('humMax', humMax);
  }

  // ОНОВЛЕНО: Тепер метод повертає системні ключі (коди помилок) замість 
  // локалізованого тексту. Це робить сервіс незалежним від UI та мови.
  String? checkAlarm(double val, String type) {
    if (type == 'temp') {
      if (val < tempMin) return 'temp_low';
      if (val > tempMax) return 'temp_high';
    } else if (type == 'hum') {
      if (val < humMin) return 'hum_low';
      if (val > humMax) return 'hum_high';
    }
    return null; // Значення в нормі
  }
}