#include <Arduino.h>
#include <Wire.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <PulseSensorPlayground.h>
#include <math.h>

// ============================================================
// MEMORA - ESP32 + MPU6050/MPU9250 (acelerometro/giroscopio)
//        + Pulse Sensor analogico (BPM) + Wi-Fi/MQTT
//
// Hardware utilizado:
//   ESP32 DevKit (ESP32 classico)
//   MPU conectado por I2C
//   Pulse Sensor analogico conectado ao GPIO 34
//
// Nao utiliza LEDs nem buzzer.
// ============================================================

// ----------------------- WI-FI -------------------------------
// Troque pelos dados da rede Wi-Fi 2,4 GHz.
const char* WIFI_SSID = "Kian";
const char* WIFI_PASS = "K14n S4b3";

// ----------------------- MQTT -------------------------------
// Broker publico apenas para testes/demonstracao.
const char* MQTT_BROKER = "broker.hivemq.com";
const uint16_t MQTT_PORT = 1883;

// Mantidos iguais aos topicos do sketch anterior para preservar
// a integracao existente com o Memora.
const char* TOPICO_TELEMETRIA = "memora/iot/demonstracao-01/telemetria";
const char* TOPICO_ALERTA = "memora/iot/demonstracao-01/alerta";
const char* TOPICO_COMANDO = "memora/iot/demonstracao-01/comando";

WiFiClient wifiClient;
PubSubClient mqttClient(wifiClient);

unsigned long ultimaTentativaWiFi = 0;
unsigned long ultimaTentativaMQTT = 0;
unsigned long ultimaTelemetriaMQTT = 0;
const unsigned long INTERVALO_RECONEXAO_WIFI = 10000;
const unsigned long INTERVALO_RECONEXAO_MQTT = 5000;
const unsigned long INTERVALO_TELEMETRIA = 500;

// ----------------------- PINOS --------------------------------
#define SDA_PIN 21
#define SCL_PIN 22
#define PULSE_PIN 34  // ADC1: pode ser usado junto com Wi-Fi

// ----------------------- MPU ----------------------------------
#define MPU_ADDR_1 0x68
#define MPU_ADDR_2 0x69
#define WHO_AM_I_REG 0x75
#define PWR_MGMT_1 0x6B
#define CONFIG_REG 0x1A
#define SMPLRT_DIV 0x19
#define GYRO_CONFIG 0x1B
#define ACCEL_CONFIG 0x1C
#define ACCEL_XOUT_H 0x3B

uint8_t mpuAddress = MPU_ADDR_1;

// O acelerometro sera configurado em +/-8 g para nao saturar
// tao facilmente durante impactos. Sensibilidade: 4096 LSB/g.
const float ACCEL_SCALE = 4096.0f;
// Giroscopio em +/-250 graus/s: 131 LSB/(grau/s).
const float GYRO_SCALE = 131.0f;

float ax = 0.0f, ay = 0.0f, az = 0.0f;
float gx = 0.0f, gy = 0.0f, gz = 0.0f;
float aceleracaoG = 1.0f;
float aceleracaoAnterior = 1.0f;
float deltaAceleracao = 0.0f;
float velocidadeRotacao = 0.0f;

// Correcoes calculadas durante a calibracao inicial.
float fatorCorrecaoAceleracao = 1.0f;
float gyroOffsetX = 0.0f;
float gyroOffsetY = 0.0f;
float gyroOffsetZ = 0.0f;

// ----------------------- PULSE SENSOR -------------------------
PulseSensorPlayground pulseSensor;
const int PULSE_THRESHOLD = 550;  // ponto inicial; pode exigir ajuste
bool pulseSensorDisponivel = false;
int bpm = 0;
bool bpmValido = false;
unsigned long ultimaBatidaDetectada = 0;
const unsigned long TIMEOUT_BPM_MS = 8000;
const int BPM_MINIMO_VALIDO = 35;
const int BPM_MAXIMO_VALIDO = 200;
int bpmAntesDaQueda = -1;

// ----------------------- DETECCAO DE MOVIMENTO ----------------
// Indice experimental de 0 a 100, combinando mudanca de aceleracao
// e velocidade angular. Nao representa uma medida clinica.
float nivelMovimentoBruto = 0.0f;
float nivelMovimento = 0.0f;
const float MOVIMENTO_LIGAR = 3.0f;
const float MOVIMENTO_DESLIGAR = 1.5f;

// ----------------------- DETECCAO DE QUEDA --------------------
const float LIMIAR_QUEDA_LIVRE_G = 0.55f;
const unsigned long TEMPO_MIN_QUEDA_LIVRE_MS = 80;
const unsigned long JANELA_IMPACTO_MS = 1000;
const float LIMIAR_IMPACTO_G = 2.5f;
const unsigned long TEMPO_POS_IMPACTO_MS = 3000;
const float MOVIMENTO_MEDIO_MAX_POS_IMPACTO = 10.0f;

// ----------------------- ESTADOS ------------------------------
enum Estado {
  INERTE,
  EM_MOVIMENTO,
  QUEDA_LIVRE,
  AGUARDANDO_IMPACTO,
  POS_IMPACTO,
  QUEDA_DETECTADA
};

Estado estadoAtual = INERTE;
unsigned long inicioQuedaLivre = 0;
unsigned long inicioAguardandoImpacto = 0;
unsigned long inicioPosImpacto = 0;
float somaMovimentoPosImpacto = 0.0f;
unsigned int quantidadeAmostrasPosImpacto = 0;
float movimentoMedioPosImpacto = 0.0f;
bool alertaPendente = false;

// ============================================================
// FUNCOES AUXILIARES I2C / MPU
// ============================================================

bool escreverRegistro(uint8_t reg, uint8_t valor) {
  Wire.beginTransmission(mpuAddress);
  Wire.write(reg);
  Wire.write(valor);
  return Wire.endTransmission() == 0;
}

bool lerRegistro(uint8_t reg, uint8_t &valor) {
  Wire.beginTransmission(mpuAddress);
  Wire.write(reg);
  if (Wire.endTransmission(false) != 0) return false;

  uint8_t recebidos = Wire.requestFrom(mpuAddress, (uint8_t)1);
  if (recebidos != 1 || !Wire.available()) return false;

  valor = Wire.read();
  return true;
}

int16_t lerInt16I2C() {
  uint8_t alto = Wire.read();
  uint8_t baixo = Wire.read();
  return (int16_t)((uint16_t)alto << 8 | baixo);
}

bool detectarMPU() {
  const uint8_t enderecos[] = {MPU_ADDR_1, MPU_ADDR_2};

  for (uint8_t endereco : enderecos) {
    Wire.beginTransmission(endereco);
    if (Wire.endTransmission() != 0) continue;

    mpuAddress = endereco;
    uint8_t id = 0;
    if (!lerRegistro(WHO_AM_I_REG, id)) continue;

    Serial.printf("MPU encontrado no endereco I2C 0x%02X; WHO_AM_I=0x%02X\n", mpuAddress, id);

    if (id == 0x68) {
      Serial.println("Identificacao compativel com MPU6050.");
      return true;
    }
    if (id == 0x71) {
      Serial.println("Identificacao compativel com MPU9250.");
      return true;
    }
    if (id == 0x73) {
      Serial.println("Identificacao compativel com MPU9255.");
      return true;
    }

    Serial.println("Dispositivo respondeu, mas WHO_AM_I nao e reconhecido por este sketch.");
  }

  return false;
}

bool inicializarMPU() {
  if (!detectarMPU()) {
    Serial.println("ERRO: MPU nao encontrado. Confira VCC, GND, SDA e SCL.");
    return false;
  }

  // Acorda o sensor e seleciona PLL do giroscopio como clock.
  if (!escreverRegistro(PWR_MGMT_1, 0x00)) return false;
  delay(100);
  if (!escreverRegistro(PWR_MGMT_1, 0x01)) return false;

  // DLPF habilitado; com divisor 9, taxa nominal de amostragem de 100 Hz.
  if (!escreverRegistro(CONFIG_REG, 0x03)) return false;
  if (!escreverRegistro(SMPLRT_DIV, 9)) return false;

  // Giroscopio +/-250 graus/s.
  if (!escreverRegistro(GYRO_CONFIG, 0x00)) return false;

  // Acelerometro +/-8 g (AFS_SEL=2).
  if (!escreverRegistro(ACCEL_CONFIG, 0x10)) return false;

  delay(100);
  return true;
}

bool lerSensoresMPU() {
  Wire.beginTransmission(mpuAddress);
  Wire.write(ACCEL_XOUT_H);
  if (Wire.endTransmission(false) != 0) return false;

  uint8_t recebidos = Wire.requestFrom(mpuAddress, (uint8_t)14);
  if (recebidos != 14 || Wire.available() < 14) return false;

  int16_t rawAX = lerInt16I2C();
  int16_t rawAY = lerInt16I2C();
  int16_t rawAZ = lerInt16I2C();
  (void)lerInt16I2C(); // temperatura, nao utilizada
  int16_t rawGX = lerInt16I2C();
  int16_t rawGY = lerInt16I2C();
  int16_t rawGZ = lerInt16I2C();

  ax = (rawAX / ACCEL_SCALE) * fatorCorrecaoAceleracao;
  ay = (rawAY / ACCEL_SCALE) * fatorCorrecaoAceleracao;
  az = (rawAZ / ACCEL_SCALE) * fatorCorrecaoAceleracao;

  gx = (rawGX / GYRO_SCALE) - gyroOffsetX;
  gy = (rawGY / GYRO_SCALE) - gyroOffsetY;
  gz = (rawGZ / GYRO_SCALE) - gyroOffsetZ;

  aceleracaoG = sqrtf(ax * ax + ay * ay + az * az);
  deltaAceleracao = fabsf(aceleracaoG - aceleracaoAnterior);
  aceleracaoAnterior = aceleracaoG;
  velocidadeRotacao = sqrtf(gx * gx + gy * gy + gz * gz);

  return true;
}

bool calibrarMPU() {
  Serial.println();
  Serial.println("Calibrando MPU: mantenha o modulo parado e na posicao em que sera utilizado.");
  delay(2000);

  const int AMOSTRAS = 300;
  float somaMagnitude = 0.0f;
  float somaGX = 0.0f, somaGY = 0.0f, somaGZ = 0.0f;
  int validas = 0;

  // A correcao ainda e 1.0 nesta etapa; gyro offsets ainda sao zero.
  for (int i = 0; i < AMOSTRAS; i++) {
    if (lerSensoresMPU()) {
      somaMagnitude += sqrtf(ax * ax + ay * ay + az * az);
      somaGX += gx;
      somaGY += gy;
      somaGZ += gz;
      validas++;
    }
    delay(10);
  }

  if (validas < (AMOSTRAS * 0.9f)) {
    Serial.printf("Falha na calibracao do MPU: apenas %d/%d leituras validas.\n", validas, AMOSTRAS);
    return false;
  }

  float mediaG = somaMagnitude / validas;
  if (mediaG < 0.5f || mediaG > 1.8f) {
    Serial.printf("Referencia de aceleracao inesperada: %.3f g. Verifique a montagem.\n", mediaG);
    return false;
  }

  // Compensa o erro de escala observado no modulo (ex.: repouso em ~1.10 g).
  // Nao substitui calibracao multiponto nem corrige todos os erros de eixo.
  fatorCorrecaoAceleracao = 1.0f / mediaG;
  gyroOffsetX = somaGX / validas;
  gyroOffsetY = somaGY / validas;
  gyroOffsetZ = somaGZ / validas;

  // Faz uma leitura inicial ja com as correcoes aplicadas.
  if (!lerSensoresMPU()) return false;

  Serial.println("Calibracao do MPU concluida.");
  Serial.printf("Magnitude antes da correcao: %.3f g\n", mediaG);
  Serial.printf("Fator de correcao: %.4f\n", fatorCorrecaoAceleracao);
  Serial.printf("Offsets gyro X/Y/Z: %.3f / %.3f / %.3f graus/s\n", gyroOffsetX, gyroOffsetY, gyroOffsetZ);
  Serial.println("Repouso corrigido deve ficar proximo de 1.00 g.");
  Serial.println();

  aceleracaoAnterior = aceleracaoG;
  return true;
}

// ============================================================
// PULSE SENSOR - BPM REAL
// ============================================================

void inicializarPulseSensor() {
  // A biblioteca PulseSensor Playground utiliza amostras de 10 bits.
  analogReadResolution(10);
  pinMode(PULSE_PIN, INPUT);

  pulseSensor.analogInput(PULSE_PIN);
  pulseSensor.setThreshold(PULSE_THRESHOLD);

  pulseSensorDisponivel = pulseSensor.begin();
  if (pulseSensorDisponivel) {
    Serial.println("Pulse Sensor iniciado no GPIO 34.");
    Serial.println("Coloque a face optica no dedo e mantenha-o apoiado sem pressionar demais.");
  } else {
    Serial.println("AVISO: PulseSensor Playground nao iniciou. BPM ficara indisponivel; MPU/MQTT continuarao.");
  }
}

void atualizarBPM() {
  if (!pulseSensorDisponivel) {
    bpm = 0;
    bpmValido = false;
    return;
  }

  // Deve ser consultado frequentemente; o timer interno da biblioteca
  // faz a amostragem do sinal a 500 Hz no ESP32.
  if (pulseSensor.sawStartOfBeat()) {
    ultimaBatidaDetectada = millis();
  }

  int bpmBiblioteca = pulseSensor.getBeatsPerMinute();
  bool batidaRecente = (ultimaBatidaDetectada != 0) &&
                       (millis() - ultimaBatidaDetectada <= TIMEOUT_BPM_MS);

  if (batidaRecente && bpmBiblioteca >= BPM_MINIMO_VALIDO && bpmBiblioteca <= BPM_MAXIMO_VALIDO) {
    bpm = bpmBiblioteca;
    bpmValido = true;
  } else {
    bpm = 0;
    bpmValido = false;
  }
}

// ============================================================
// MOVIMENTO
// ============================================================

float calcularNivelMovimento() {
  // Delta de magnitude detecta aceleracoes/translacoes; gyro detecta rotacoes
  // mesmo quando a magnitude total continua perto de 1 g.
  float scoreAceleracao = (deltaAceleracao / 0.15f) * 100.0f;
  float scoreGiroscopio = (velocidadeRotacao / 30.0f) * 100.0f;

  scoreAceleracao = constrain(scoreAceleracao, 0.0f, 100.0f);
  scoreGiroscopio = constrain(scoreGiroscopio, 0.0f, 100.0f);

  float scoreBruto = (scoreAceleracao * 0.40f) + (scoreGiroscopio * 0.60f);
  return constrain(scoreBruto, 0.0f, 100.0f);
}

const char* nomeEstado() {
  switch (estadoAtual) {
    case INERTE: return "INERTE";
    case EM_MOVIMENTO: return "EM_MOVIMENTO";
    case QUEDA_LIVRE: return "QUEDA_LIVRE";
    case AGUARDANDO_IMPACTO: return "AGUARDANDO_IMPACTO";
    case POS_IMPACTO: return "POS_IMPACTO";
    case QUEDA_DETECTADA: return "QUEDA_DETECTADA";
    default: return "DESCONHECIDO";
  }
}

// ============================================================
// MQTT
// ============================================================

void publicarAlertaQueda();

void callbackMQTT(char* topic, byte* payload, unsigned int length) {
  String mensagem;
  mensagem.reserve(length + 1);
  for (unsigned int i = 0; i < length; i++) mensagem += (char)payload[i];

  Serial.printf("Comando MQTT recebido em %s: %s\n", topic, mensagem.c_str());

  if (mensagem.indexOf("CESSAR_ALARME") >= 0) {
    estadoAtual = INERTE;
    alertaPendente = false;
    somaMovimentoPosImpacto = 0.0f;
    quantidadeAmostrasPosImpacto = 0;
    Serial.println(">>> Evento de queda reconhecido/encerrado pelo Memora. <<<");
  }
}

void iniciarWiFi() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.printf("Conectando ao Wi-Fi: %s", WIFI_SSID);

  unsigned long inicio = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - inicio < 15000) {
    delay(250);
    Serial.print('.');
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf("\nWi-Fi conectado. IP: %s\n", WiFi.localIP().toString().c_str());
  } else {
    Serial.println("\nWi-Fi ainda indisponivel. O monitoramento local continuara e novas tentativas serao feitas.");
  }
}

void reconectarWiFiSeNecessario() {
  if (WiFi.status() == WL_CONNECTED) return;
  if (millis() - ultimaTentativaWiFi < INTERVALO_RECONEXAO_WIFI) return;

  ultimaTentativaWiFi = millis();
  Serial.println("Tentando reconectar ao Wi-Fi...");
  WiFi.disconnect();
  WiFi.begin(WIFI_SSID, WIFI_PASS);
}

void publicarTelemetriaMQTT() {
  if (!mqttClient.connected()) return;
  if (millis() - ultimaTelemetriaMQTT < INTERVALO_TELEMETRIA) return;
  ultimaTelemetriaMQTT = millis();

  char payload[300];
  bool emMovimento = (estadoAtual == EM_MOVIMENTO);

  snprintf(payload, sizeof(payload),
           "{\"bpm\":%d,\"bpm_valido\":%s,\"movimento\":%.1f,\"aceleracao\":%.2f,\"em_movimento\":%s,\"estado\":\"%s\",\"timestamp\":%lu}",
           bpm,
           bpmValido ? "true" : "false",
           nivelMovimento,
           aceleracaoG,
           emMovimento ? "true" : "false",
           nomeEstado(),
           (unsigned long)millis());

  mqttClient.publish(TOPICO_TELEMETRIA, payload, false);
}

void publicarAlertaQueda() {
  if (!mqttClient.connected() || !alertaPendente) return;

  char payload[300];
  snprintf(payload, sizeof(payload),
           "{\"evento\":\"QUEDA_DETECTADA\",\"bpm\":%d,\"bpm_valido\":%s,\"bpm_antes_da_queda\":%d,\"aceleracao\":%.2f,\"movimento_pos_impacto\":%.1f,\"timestamp\":%lu}",
           bpm,
           bpmValido ? "true" : "false",
           bpmAntesDaQueda,
           aceleracaoG,
           movimentoMedioPosImpacto,
           (unsigned long)millis());

  if (mqttClient.publish(TOPICO_ALERTA, payload, false)) {
    alertaPendente = false;
    Serial.println(">>> ALERTA DE QUEDA publicado no MQTT. <<<");
  }
}

void reconectarMQTTSeNecessario() {
  if (WiFi.status() != WL_CONNECTED || mqttClient.connected()) return;
  if (millis() - ultimaTentativaMQTT < INTERVALO_RECONEXAO_MQTT) return;

  ultimaTentativaMQTT = millis();

  // Identificador derivado do MAC para reduzir colisao entre clientes.
  String clientId = "Memora-ESP32-" + String((uint32_t)(ESP.getEfuseMac() & 0xFFFFFFFF), HEX);
  Serial.print("Conectando ao MQTT... ");

  if (mqttClient.connect(clientId.c_str())) {
    Serial.println("conectado!");
    mqttClient.subscribe(TOPICO_COMANDO);
    if (alertaPendente) publicarAlertaQueda();
  } else {
    Serial.printf("falhou, estado=%d\n", mqttClient.state());
  }
}

// ============================================================
// MAQUINA DE ESTADOS DE MOVIMENTO E QUEDA
// ============================================================

void processarEstados() {
  // A queda deve ser verificada antes da classificacao normal de movimento.
  switch (estadoAtual) {
    case INERTE:
    case EM_MOVIMENTO:
      if (aceleracaoG < LIMIAR_QUEDA_LIVRE_G) {
        inicioQuedaLivre = millis();
        bpmAntesDaQueda = bpmValido ? bpm : -1;
        estadoAtual = QUEDA_LIVRE;
        Serial.println("\n>>> POSSIVEL QUEDA: queda livre detectada.");
      } else if (estadoAtual == INERTE && nivelMovimento >= MOVIMENTO_LIGAR) {
        estadoAtual = EM_MOVIMENTO;
      } else if (estadoAtual == EM_MOVIMENTO && nivelMovimento <= MOVIMENTO_DESLIGAR) {
        estadoAtual = INERTE;
      }
      break;

    case QUEDA_LIVRE: {
      unsigned long duracao = millis() - inicioQuedaLivre;

      if (aceleracaoG >= LIMIAR_QUEDA_LIVRE_G) {
        if (duracao >= TEMPO_MIN_QUEDA_LIVRE_MS) {
          if (aceleracaoG >= LIMIAR_IMPACTO_G) {
            // O pico de impacto pode ocorrer justamente na amostra que encerra a queda livre.
            inicioPosImpacto = millis();
            somaMovimentoPosImpacto = 0.0f;
            quantidadeAmostrasPosImpacto = 0;
            estadoAtual = POS_IMPACTO;
            Serial.println(">>> IMPACTO detectado na saida da queda livre.");
          } else {
            inicioAguardandoImpacto = millis();
            estadoAtual = AGUARDANDO_IMPACTO;
            Serial.println(">>> Queda livre confirmada; aguardando impacto.");
          }
        } else {
          estadoAtual = (nivelMovimento >= MOVIMENTO_LIGAR) ? EM_MOVIMENTO : INERTE;
          Serial.println(">>> Queda livre curta; evento descartado.");
        }
      } else if (duracao > JANELA_IMPACTO_MS) {
        estadoAtual = (nivelMovimento >= MOVIMENTO_LIGAR) ? EM_MOVIMENTO : INERTE;
        Serial.println(">>> Evento cancelado: queda livre excedeu o tempo esperado.");
      }
      break;
    }

    case AGUARDANDO_IMPACTO:
      if (aceleracaoG >= LIMIAR_IMPACTO_G) {
        inicioPosImpacto = millis();
        somaMovimentoPosImpacto = 0.0f;
        quantidadeAmostrasPosImpacto = 0;
        estadoAtual = POS_IMPACTO;
        Serial.println(">>> IMPACTO detectado; avaliando movimento apos o impacto.");
      } else if (millis() - inicioAguardandoImpacto > JANELA_IMPACTO_MS) {
        estadoAtual = (nivelMovimento >= MOVIMENTO_LIGAR) ? EM_MOVIMENTO : INERTE;
        Serial.println(">>> Evento cancelado: nenhum impacto significativo detectado.");
      }
      break;

    case POS_IMPACTO:
      somaMovimentoPosImpacto += nivelMovimento;
      quantidadeAmostrasPosImpacto++;

      if (millis() - inicioPosImpacto >= TEMPO_POS_IMPACTO_MS) {
        movimentoMedioPosImpacto = quantidadeAmostrasPosImpacto > 0
                                      ? somaMovimentoPosImpacto / quantidadeAmostrasPosImpacto
                                      : 100.0f;

        if (movimentoMedioPosImpacto < MOVIMENTO_MEDIO_MAX_POS_IMPACTO) {
          estadoAtual = QUEDA_DETECTADA;
          alertaPendente = true;
          Serial.println("\n========================================");
          Serial.println("          QUEDA DETECTADA");
          Serial.println("========================================");
          Serial.print("BPM atual: ");
          if (bpmValido) Serial.print(bpm);
          else Serial.print("indisponivel");
          Serial.printf(" | BPM antes da queda: %d\n", bpmAntesDaQueda);
          Serial.printf("Movimento medio apos impacto: %.1f/100\n", movimentoMedioPosImpacto);
          publicarAlertaQueda();
        } else {
          estadoAtual = EM_MOVIMENTO;
          Serial.printf(">>> Possivel queda descartada: movimento medio apos impacto %.1f/100.\n", movimentoMedioPosImpacto);
        }
      }
      break;

    case QUEDA_DETECTADA:
      // Mantem o estado ate receber CESSAR_ALARME pelo topico MQTT.
      break;
  }
}

// ============================================================
// SETUP
// ============================================================

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println();
  Serial.println("============================================");
  Serial.println(" MEMORA - MONITORAMENTO DE MOVIMENTO E QUEDA");
  Serial.println(" ESP32 + MPU + PULSE SENSOR + MQTT");
  Serial.println("============================================");

  // I2C do MPU.
  Wire.begin(SDA_PIN, SCL_PIN);
  Wire.setClock(100000); // 100 kHz: conservador para montagem em protoboard.

  if (!inicializarMPU()) {
    Serial.println("Verifique as ligacoes do MPU e reinicie o ESP32.");
    while (true) delay(1000);
  }

  if (!calibrarMPU()) {
    Serial.println("Calibracao do MPU falhou. Deixe-o parado e reinicie.");
    while (true) delay(1000);
  }

  // Inicializa o sensor de pulso depois de configurar ADC para 10 bits.
  inicializarPulseSensor();

  // Inicia Wi-Fi sem impedir o funcionamento local se a rede estiver fora.
  iniciarWiFi();

  mqttClient.setServer(MQTT_BROKER, MQTT_PORT);
  mqttClient.setCallback(callbackMQTT);
  mqttClient.setBufferSize(512);
  mqttClient.setKeepAlive(30);
  mqttClient.setSocketTimeout(3);

  Serial.println("\nSistema iniciado. Abra o Serial Monitor em 115200 baud.");
  Serial.println("Para medir BPM, posicione o dedo sobre o sensor sem pressionar excessivamente.");
  Serial.println("Durante a calibracao inicial, mantenha o MPU imovel.");
  Serial.println();
}

// ============================================================
// LOOP
// ============================================================

void loop() {
  // Mantem o processamento do MQTT e as reconexoes.
  reconectarWiFiSeNecessario();
  reconectarMQTTSeNecessario();
  if (mqttClient.connected()) mqttClient.loop();

  // Le o MPU. Se ocorrer erro de I2C, nao atualiza o estado usando dados antigos.
  if (!lerSensoresMPU()) {
    Serial.println("Erro de comunicacao com o MPU (I2C).");
    delay(20);
    return;
  }

  // Leitura do BPM gerada pela biblioteca atraves do timer de amostragem.
  atualizarBPM();

  // Filtragem simples do nivel de movimento para reduzir ruido.
  nivelMovimentoBruto = calcularNivelMovimento();
  nivelMovimento = (0.75f * nivelMovimento) + (0.25f * nivelMovimentoBruto);
  nivelMovimento = constrain(nivelMovimento, 0.0f, 100.0f);

  processarEstados();
  publicarTelemetriaMQTT();

  // Diagnostico periodico no Serial Monitor.
  static unsigned long ultimoPrint = 0;
  if (millis() - ultimoPrint >= 500) {
    ultimoPrint = millis();

    Serial.printf("AX: %.2f | AY: %.2f | AZ: %.2f | Acel: %.2f g | Giro: %.1f deg/s | Movimento: %.1f/100 | ",
                  ax, ay, az, aceleracaoG, velocidadeRotacao, nivelMovimento);

    Serial.print("BPM: ");
    if (bpmValido) Serial.print(bpm);
    else Serial.print("--");

    Serial.printf(" | Sinal PPG: %d | Estado: %s | MQTT: %s\n",
                  pulseSensorDisponivel ? pulseSensor.getLatestSample() : 0,
                  nomeEstado(),
                  mqttClient.connected() ? "conectado" : "desconectado");
  }

  // O PulseSensor Playground usa timer de hardware no ESP32 para amostrar
  // o PPG a 500 Hz; este pequeno intervalo limita as leituras do MPU a ~100 Hz.
  delay(10);
}
