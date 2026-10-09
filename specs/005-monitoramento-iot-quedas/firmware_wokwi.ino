#include <Wire.h>
#include <math.h>
#include <WiFi.h>
#include <PubSubClient.h>

// ============================================================
// ESP32 + MPU6050 + BPM SIMULADO + MQTT WOKWI
// ============================================================

// Wi-Fi (Wokwi Guest)
const char* WIFI_SSID = "Wokwi-GUEST";
const char* WIFI_PASS = "";

// MQTT Broker (HiveMQ público)
const char* MQTT_BROKER = "broker.hivemq.com";
const int MQTT_PORT = 1883;
const char* TOPICO_TELEMETRIA = "memora/iot/demonstracao-01/telemetria";
const char* TOPICO_ALERTA = "memora/iot/demonstracao-01/alerta";
const char* TOPICO_COMANDO = "memora/iot/demonstracao-01/comando";

WiFiClient espClient;
PubSubClient client(espClient);

// ============================================================
// PINOS
// ============================================================

#define SDA_PIN 21
#define SCL_PIN 22
#define BPM_PIN 34
#define LED_VERDE 25
#define LED_AMARELO 26
#define LED_VERMELHO 27
#define BUZZER_PIN 14

// ============================================================
// MPU6050
// ============================================================

#define MPU_ADDR 0x68
#define WHO_AM_I       0x75
#define PWR_MGMT_1     0x6B
#define CONFIG         0x1A
#define SMPLRT_DIV     0x19
#define GYRO_CONFIG    0x1B
#define ACCEL_CONFIG   0x1C

#define ACCEL_XOUT_H   0x3B

const float ACCEL_SCALE = 16384.0;
const float GYRO_SCALE = 131.0;

float ax = 0, ay = 0, az = 0;
float aceleracaoG = 0, aceleracaoAnterior = 0, deltaAceleracao = 0;
float gx = 0, gy = 0, gz = 0;
float velocidadeRotacao = 0;
float gyroOffsetX = 0, gyroOffsetY = 0, gyroOffsetZ = 0;
float referenciaG = 1.0;

// Constantes de detecção
const float ACCEL_MOVEMENT_THRESHOLD = 0.025;
const float GYRO_MOVEMENT_THRESHOLD = 3.0;
const float FREEFALL_THRESHOLD = 0.55;
const unsigned long FREEFALL_MIN_TIME = 80;
const unsigned long IMPACT_WINDOW = 1000;
const float IMPACT_THRESHOLD = 2.5;
const unsigned long POST_IMPACT_TIME = 3000;
const float POST_IMPACT_MOVEMENT = 10.0;

enum Estado
{
  INERTE,
  MOVIMENTO,
  QUEDA_LIVRE,
  AGUARDANDO_IMPACTO,
  POS_IMPACTO
};

Estado estadoAtual = INERTE;

unsigned long inicioQuedaLivre = 0;
unsigned long inicioImpacto = 0;
unsigned long inicioPosImpacto = 0;
unsigned long ultimoPrint = 0;
unsigned long ultimoMqttTelemetria = 0;

float somaMovimento = 0;
int quantidadeAmostras = 0;
int bpm = 0;
int bpmAnterior = 0;
int bpmInicial = 0;
unsigned long ultimoBPM = 0;
float nivelMovimento = 0;

// ============================================================
// I2C & MPU REGISTROS
// ============================================================

void escreverRegistro(uint8_t registrador, uint8_t valor) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(registrador);
  Wire.write(valor);
  Wire.endTransmission();
}

uint8_t lerRegistro(uint8_t registrador) {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(registrador);
  Wire.endTransmission(false);
  Wire.requestFrom(MPU_ADDR, (uint8_t)1);
  if (Wire.available()) return Wire.read();
  return 0;
}

bool inicializarMPU() {
  uint8_t id = lerRegistro(WHO_AM_I);
  if (id != 0x68 && id != 0x71 && id != 0x73) {
    Serial.println("MPU nao reconhecido!");
    return false;
  }
  escreverRegistro(PWR_MGMT_1, 0x00);
  delay(100);
  escreverRegistro(PWR_MGMT_1, 0x01);
  escreverRegistro(CONFIG, 0x03);
  escreverRegistro(SMPLRT_DIV, 9);
  escreverRegistro(GYRO_CONFIG, 0x00);
  escreverRegistro(ACCEL_CONFIG, 0x00);
  return true;
}

void calibrarSensores() {
  const int amostras = 100;
  float somaG = 0;
  for (int i = 0; i < amostras; i++) {
    Wire.beginTransmission(MPU_ADDR);
    Wire.write(ACCEL_XOUT_H);
    Wire.endTransmission(false);
    Wire.requestFrom(MPU_ADDR, 14);
    if (Wire.available() >= 14) {
      int16_t rawAx = (Wire.read() << 8) | Wire.read();
      int16_t rawAy = (Wire.read() << 8) | Wire.read();
      int16_t rawAz = (Wire.read() << 8) | Wire.read();
      Wire.read(); Wire.read(); // temp
      int16_t rawGx = (Wire.read() << 8) | Wire.read();
      int16_t rawGy = (Wire.read() << 8) | Wire.read();
      int16_t rawGz = (Wire.read() << 8) | Wire.read();
      float tax = rawAx / ACCEL_SCALE;
      float tay = rawAy / ACCEL_SCALE;
      float taz = rawAz / ACCEL_SCALE;
      somaG += sqrt(tax*tax + tay*tay + taz*taz);
      gyroOffsetX += rawGx / GYRO_SCALE;
      gyroOffsetY += rawGy / GYRO_SCALE;
      gyroOffsetZ += rawGz / GYRO_SCALE;
    }
    delay(10);
  }
  referenciaG = somaG / amostras;
  gyroOffsetX /= amostras;
  gyroOffsetY /= amostras;
  gyroOffsetZ /= amostras;
}

void lerSensores() {
  Wire.beginTransmission(MPU_ADDR);
  Wire.write(ACCEL_XOUT_H);
  Wire.endTransmission(false);
  Wire.requestFrom(MPU_ADDR, 14);
  if (Wire.available() >= 14) {
    int16_t rawAx = (Wire.read() << 8) | Wire.read();
    int16_t rawAy = (Wire.read() << 8) | Wire.read();
    int16_t rawAz = (Wire.read() << 8) | Wire.read();
    Wire.read(); Wire.read();
    int16_t rawGx = (Wire.read() << 8) | Wire.read();
    int16_t rawGy = (Wire.read() << 8) | Wire.read();
    int16_t rawGz = (Wire.read() << 8) | Wire.read();

    ax = rawAx / ACCEL_SCALE;
    ay = rawAy / ACCEL_SCALE;
    az = rawAz / ACCEL_SCALE;
    aceleracaoG = sqrt(ax*ax + ay*ay + az*az);
    deltaAceleracao = fabs(aceleracaoG - aceleracaoAnterior);
    aceleracaoAnterior = aceleracaoG;

    gx = (rawGx / GYRO_SCALE) - gyroOffsetX;
    gy = (rawGy / GYRO_SCALE) - gyroOffsetY;
    gz = (rawGz / GYRO_SCALE) - gyroOffsetZ;
    velocidadeRotacao = sqrt(gx*gx + gy*gy + gz*gz);
  }
}

void lerBPM() {
  if (millis() - ultimoBPM >= 100) {
    ultimoBPM = millis();
    int leitura = analogRead(BPM_PIN);
    bpm = map(leitura, 0, 4095, 40, 180);
  }
}

void atualizarLEDs() {
  digitalWrite(LED_VERDE, estadoAtual == INERTE || estadoAtual == MOVIMENTO);
  digitalWrite(LED_AMARELO, estadoAtual == AGUARDANDO_IMPACTO || estadoAtual == POS_IMPACTO);
  digitalWrite(LED_VERMELHO, estadoAtual == QUEDA_LIVRE);
}

const char* nomeEstado() {
  switch (estadoAtual) {
    case INERTE: return "INERTE";
    case MOVIMENTO: return "MOVIMENTO";
    case QUEDA_LIVRE: return "QUEDA_LIVRE";
    case AGUARDANDO_IMPACTO: return "AGUARDANDO_IMPACTO";
    case POS_IMPACTO: return "POS_IMPACTO";
    default: return "DESCONHECIDO";
  }
}

// ============================================================
// MQTT & WI-FI
// ============================================================

void callbackMqtt(char* topic, byte* payload, unsigned int length) {
  String msg = "";
  for (unsigned int i = 0; i < length; i++) {
    msg += (char)payload[i];
  }
  Serial.print("Mensagem recebida [");
  Serial.print(topic);
  Serial.print("]: ");
  Serial.println(msg);

  // Comando de cessação de alarme enviado pelo Memora
  if (msg.indexOf("CESSAR_ALARME") >= 0) {
    noTone(BUZZER_PIN);
    estadoAtual = INERTE;
    Serial.println(">>> ALARME CESSADO PELO APLICATIVO MEMORA <<<");
  }
}

void reconectarMqtt() {
  if (!client.connected()) {
    String clientId = "ESP32-Memora-" + String(random(0xffff), HEX);
    if (client.connect(clientId.c_str())) {
      Serial.println("Conectado ao Broker MQTT HiveMQ!");
      client.subscribe(TOPICO_COMANDO);
    }
  }
}

void publicarTelemetriaMqtt() {
  if (millis() - ultimoMqttTelemetria >= 500 && client.connected()) {
    ultimoMqttTelemetria = millis();
    String payload = "{";
    payload += "\"bpm\":" + String(bpm) + ",";
    payload += "\"movimento\":" + String(nivelMovimento, 1) + ",";
    payload += "\"aceleracao\":" + String(aceleracaoG, 2) + ",";
    payload += "\"em_movimento\":" + String(nivelMovimento >= 5.0 ? "true" : "false") + ",";
    payload += "\"estado\":\"" + String(nomeEstado()) + "\"";
    payload += "}";
    client.publish(TOPICO_TELEMETRIA, payload.c_str());
  }
}

void publicarAlertaQueda() {
  if (client.connected()) {
    String payload = "{";
    payload += "\"evento\":\"QUEDA_DETECTADA\",";
    payload += "\"bpm\":" + String(bpm) + ",";
    payload += "\"aceleracao\":" + String(aceleracaoG, 2) + ",";
    payload += "\"timestamp\":" + String(millis());
    payload += "}";
    client.publish(TOPICO_ALERTA, payload.c_str(), true);
    Serial.println(">>> ALERTA DE QUEDA PUBLICADO NO MQTT <<<");
  }
}

// ============================================================
// SETUP & LOOP
// ============================================================

void setup() {
  Serial.begin(115200);
  Wire.begin(SDA_PIN, SCL_PIN);
  pinMode(BPM_PIN, INPUT);
  pinMode(LED_VERDE, OUTPUT);
  pinMode(LED_AMARELO, OUTPUT);
  pinMode(LED_VERMELHO, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  Serial.println("Iniciando MPU6050...");
  if (inicializarMPU()) {
    calibrarSensores();
    Serial.println("MPU Pronto e Calibrado.");
  }

  // Wi-Fi Wokwi
  Serial.print("Conectando ao Wi-Fi ");
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  int tentativas = 0;
  while (WiFi.status() != WL_CONNECTED && tentativas < 20) {
    delay(500);
    Serial.print(".");
    tentativas++;
  }
  Serial.println("\nWi-Fi Conectado!");

  client.setServer(MQTT_BROKER, MQTT_PORT);
  client.setCallback(callbackMqtt);
}

void loop() {
  if (!client.connected()) {
    reconectarMqtt();
  }
  client.loop();

  lerSensores();
  lerBPM();

  nivelMovimento = (deltaAceleracao * 50.0) + (velocidadeRotacao * 0.5);
  if (nivelMovimento > 100) nivelMovimento = 100;

  // Máquina de estados de queda
  switch (estadoAtual) {
    case INERTE:
    case MOVIMENTO:
      if (aceleracaoG < (FREEFALL_THRESHOLD * referenciaG)) {
        inicioQuedaLivre = millis();
        estadoAtual = QUEDA_LIVRE;
      } else if (nivelMovimento > 5.0) {
        estadoAtual = MOVIMENTO;
      } else {
        estadoAtual = INERTE;
      }
      break;

    case QUEDA_LIVRE:
      if (aceleracaoG >= (FREEFALL_THRESHOLD * referenciaG)) {
        if (millis() - inicioQuedaLivre >= FREEFALL_MIN_TIME) {
          inicioImpacto = millis();
          estadoAtual = AGUARDANDO_IMPACTO;
        } else {
          estadoAtual = INERTE;
        }
      }
      break;

    case AGUARDANDO_IMPACTO:
      if (aceleracaoG > IMPACT_THRESHOLD) {
        inicioPosImpacto = millis();
        somaMovimento = 0;
        quantidadeAmostras = 0;
        bpmInicial = bpm;
        estadoAtual = POS_IMPACTO;
      } else if (millis() - inicioImpacto > IMPACT_WINDOW) {
        estadoAtual = INERTE;
      }
      break;

    case POS_IMPACTO:
      somaMovimento += nivelMovimento;
      quantidadeAmostras++;
      if (millis() - inicioPosImpacto >= POST_IMPACT_TIME) {
        float movimentoMedio = somaMovimento / max(1, quantidadeAmostras);
        if (movimentoMedio < POST_IMPACT_MOVEMENT) {
          Serial.println(">>> ALERTA DE QUEDA CONFIRMADA! <<<");
          tone(BUZZER_PIN, 2000, 1000);
          publicarAlertaQueda();
        }
        estadoAtual = INERTE;
      }
      break;
  }

  atualizarLEDs();
  publicarTelemetriaMqtt();
  delay(10);
}
