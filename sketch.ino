#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <WiFiManager.h> // Потрібно встановити через Library Manager

// Налаштування датчика
#define DHTPIN 15
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);

// Налаштування MQTT
const char* mqtt_server = "broker.emqx.io";
const char* mqtt_user = "your_username"; // Можна також винести в WiFiManager
const char* mqtt_pass = "your_password";
#define STATUS_TOPIC "roman_41ki/status"

// Кореневий сертифікат (Let's Encrypt / ISRG Root X1) для broker.emqx.io
// Це дозволяє ESP32 перевірити, що вона підключена до справжнього сервера
const char* root_ca = \
"-----BEGIN CERTIFICATE-----\n" \
"MIIFazCCA1OgAwIBAgIRAIIQz7DSQONZRGPgu2OCiwAwDQYJKoZIhvcNAQELBQAw\n" \
"TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh\n" \
"cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMTUwNjA0MTEwNDM4\n" \
"WhcNMzUwNjA0MTEwNDM4WjBPMQswCQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJu\n" \
"ZXQgU2VjdXJpdHkgUmVzZWFyY2ggR3JvdXAxFTATBgNVBA宣TMElTUkcgUm9vdCBY\n" \
"MTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAK3oJIsGZzSjcxFmSI6W\n" \
"..." // Тут має бути повний текст сертифіката брокера
"-----END CERTIFICATE-----\n";

WiFiClientSecure espClient;
PubSubClient client(espClient);

void setup() {
  Serial.begin(115200);
  dht.begin();

  // --- Крок 1: WiFiManager ---
  // Замість WiFi.begin("Wokwi-GUEST", ...) використовуємо розумне підключення
  WiFiManager wm;
  
  // Якщо ESP32 не знайде збережених мереж, вона створить свою точку "IoT_Monitor_Setup"
  // Ви зможете підключитися до неї з телефону та ввести пароль від вашого WiFi
  if (!wm.autoConnect("IoT_Monitor_Setup")) {
    Serial.println("Помилка підключення, перезавантаження...");
    delay(3000);
    ESP.restart();
  }
  Serial.println("\nWiFi Connected!");

  // --- Крок 2: Безпека SSL ---
  // Встановлюємо сертифікат для перевірки сервера (замість setInsecure)
  espClient.setCACert(root_ca);
  client.setServer(mqtt_server, 8883); // Використовуємо захищений порт
}

void reconnect() {
  while (!client.connected()) {
    // --- Крок 3: Унікальний ClientID ---
    // Використовуємо MAC-адресу плати, щоб ID ніколи не дублювався
    String clientId = "ESP32_Roman_" + WiFi.macAddress();
    
    Serial.print("Спроба SSL підключення до MQTT...");
    
    if (client.connect(clientId.c_str(), mqtt_user, mqtt_pass, STATUS_TOPIC, 1, true, "offline")) {
      client.publish(STATUS_TOPIC, "online", true);
      Serial.println(" Підключено (Зашифровано)");
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
    }
  }
}