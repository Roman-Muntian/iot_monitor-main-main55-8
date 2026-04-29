#include <WiFi.h>
#include <WiFiClientSecure.h> // Повертаємо захищений клієнт
#include <PubSubClient.h>
#include <DHT.h>

#define DHTPIN 15
#define DHTTYPE DHT22
#define STATUS_TOPIC "roman_41ki/status"

const char* mqtt_server = "broker.emqx.io";
const char* mqtt_user = "your_username"; 
const char* mqtt_pass = "your_password";

DHT dht(DHTPIN, DHTTYPE);
WiFiClientSecure espClient; // Використовуємо захищений клієнт
PubSubClient client(espClient);

void setup() {
  Serial.begin(115200);
  dht.begin();

  Serial.print("Connecting to Wokwi-GUEST");
  WiFi.begin("Wokwi-GUEST", "", 6); 
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi Connected!");

  // Налаштування шифрування
  espClient.setInsecure(); // Дозволяє з'єднання без перевірки сертифіката CA (важливо для Wokwi)
  client.setServer(mqtt_server, 8883); // Порт для SSL
}

void reconnect() {
  while (!client.connected()) {
    String clientId = "ESP32_Roman_" + String(random(0, 0xffff), HEX);
    Serial.print("Attempting SSL connection...");
    
    if (client.connect(clientId.c_str(), mqtt_user, mqtt_pass, STATUS_TOPIC, 1, true, "offline")) {
      client.publish(STATUS_TOPIC, "online", true);
      Serial.println("connected (Encrypted)");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
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
      Serial.printf("Encrypted Send -> T:%.1f H:%.1f\n", t, h);
    }
  }
}