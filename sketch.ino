#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <DHT.h>

// Налаштування датчика
#define DHTPIN 15
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);

// Налаштування MQTT
const char* mqtt_server = "broker.emqx.io";
// Логін і пароль для Wokwi залишаємо порожніми для анонімного доступу
const char* mqtt_user = ""; 
const char* mqtt_pass = "";
#define STATUS_TOPIC "roman_41ki/status"

WiFiClientSecure espClient;
PubSubClient client(espClient);

void setup() {
  Serial.begin(115200);
  dht.begin();

  // --- Крок 1: Підключення до Wi-Fi у WOKWI ---
  Serial.print("Підключення до Wokwi-GUEST...");
  WiFi.begin("Wokwi-GUEST", "", 6); // Спеціальна мережа для симулятора Wokwi
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(250);
    Serial.print(".");
  }
  Serial.println("\nWiFi Підключено!");

  // --- Крок 2: Безпека SSL ---
  // Вимикаємо жорстку перевірку сертифіката (інакше Wokwi не пропустить)
  espClient.setInsecure();
  client.setServer(mqtt_server, 8883); // Використовуємо захищений порт
}

void reconnect() {
  while (!client.connected()) {
    // Унікальний ClientID на основі MAC-адреси
    String clientId = "ESP32_Roman_" + WiFi.macAddress();
    
    Serial.print("Спроба SSL підключення до MQTT...");
    
    // Анонімне підключення (без логіна і пароля)
    if (client.connect(clientId.c_str(), mqtt_user, mqtt_pass, STATUS_TOPIC, 1, true, "offline")) {
      client.publish(STATUS_TOPIC, "online", true);
      Serial.println(" Підключено (Зашифровано)!");
    } else {
      Serial.print(" помилка, rc=");
      Serial.print(client.state());
      Serial.println(" повтор через 5 сек");
      delay(5000);
    }
  }
}

void loop() {
  if (!client.connected()) reconnect();
  client.loop(); 

  static unsigned long lastMsg = 0;
  if (millis() - lastMsg > 5000) {
    lastMsg = millis();
    float h = dht.readHumidity();
    float t = dht.readTemperature(); 

    if (!isnan(h) && !isnan(t)) {
      client.publish("roman_41ki/temp", String(t, 1).c_str());
      client.publish("roman_41ki/hum", String(h, 1).c_str());
      Serial.printf("Дані надіслано (TLS) -> T:%.1f H:%.1f\n", t, h);
    } else {
      Serial.println("Помилка зчитування з датчика DHT!");
    }
  }
}