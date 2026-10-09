#include <Wire.h>
#include <math.h>

// ============================================================
// ESP32 + MPU6050 + BPM SIMULADO
// ============================================================
//
// MPU6050:
//   Movimento
//   Rotação
//   Queda
//
// Potenciômetro:
//   Simula BPM
//
// ============================================================


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
#define ACCEL_CONFIG2  0x1D

#define ACCEL_XOUT_H   0x3B

const float ACCEL_SCALE = 16384.0;
const float GYRO_SCALE = 131.0;


// ============================================================
// ACELERÔMETRO
// ============================================================

float ax = 0;
float ay = 0;
float az = 0;

float aceleracaoG = 0;
float aceleracaoAnterior = 0;

float deltaAceleracao = 0;


// ============================================================
// GIROSCÓPIO
// ============================================================

float gx = 0;
float gy = 0;
float gz = 0;

float velocidadeRotacao = 0;

float gyroOffsetX = 0;
float gyroOffsetY = 0;
float gyroOffsetZ = 0;


// ============================================================
// REFERÊNCIA DO SENSOR
// ============================================================

float referenciaG = 1.0;


// ============================================================
// MOVIMENTO
// ============================================================

// Sensibilidade do acelerômetro
const float ACCEL_MOVEMENT_THRESHOLD = 0.025;

// Sensibilidade do giroscópio
const float GYRO_MOVEMENT_THRESHOLD = 3.0;


// ============================================================
// QUEDA
// ============================================================

// Percentual da aceleração de referência
const float FREEFALL_THRESHOLD = 0.55;


// Queda livre deve durar pelo menos 80 ms
const unsigned long FREEFALL_MIN_TIME = 80;


// Tempo máximo para procurar impacto
const unsigned long IMPACT_WINDOW = 1000;


// Impacto
const float IMPACT_THRESHOLD = 2.5;


// Tempo observando a pessoa depois do impacto
const unsigned long POST_IMPACT_TIME = 3000;


// Movimento máximo para considerar imobilidade
const float POST_IMPACT_MOVEMENT = 10.0;


// ============================================================
// ESTADOS
// ============================================================

enum Estado
{
  INERTE,
  MOVIMENTO,
  QUEDA_LIVRE,
  AGUARDANDO_IMPACTO,
  POS_IMPACTO
};

Estado estadoAtual = INERTE;


// ============================================================
// TEMPORIZADORES
// ============================================================

unsigned long inicioQuedaLivre = 0;
unsigned long inicioImpacto = 0;
unsigned long inicioPosImpacto = 0;

unsigned long ultimoPrint = 0;


// ============================================================
// MOVIMENTO PÓS-IMPACTO
// ============================================================

float somaMovimento = 0;
int quantidadeAmostras = 0;


// ============================================================
// BPM
// ============================================================

int bpm = 0;

int bpmAnterior = 0;

int bpmInicial = 0;

unsigned long ultimoBPM = 0;


// ============================================================
// ESCREVER REGISTRO
// ============================================================

void escreverRegistro(
  uint8_t registrador,
  uint8_t valor
)
{
  Wire.beginTransmission(MPU_ADDR);

  Wire.write(registrador);

  Wire.write(valor);

  Wire.endTransmission();
}


// ============================================================
// LER REGISTRO
// ============================================================

uint8_t lerRegistro(
  uint8_t registrador
)
{
  Wire.beginTransmission(MPU_ADDR);

  Wire.write(registrador);

  Wire.endTransmission(false);

  Wire.requestFrom(
    MPU_ADDR,
    (uint8_t)1
  );

  if (Wire.available())
  {
    return Wire.read();
  }

  return 0;
}


// ============================================================
// INICIALIZAR MPU
// ============================================================

bool inicializarMPU()
{
  uint8_t id =
    lerRegistro(WHO_AM_I);

  Serial.print("WHO_AM_I: 0x");
  Serial.println(id, HEX);


  if (id != 0x68 &&
      id != 0x71 &&
      id != 0x73)
  {
    Serial.println(
      "MPU nao reconhecido!"
    );

    return false;
  }


  Serial.println(
    "MPU reconhecido."
  );


  // Acordar
  escreverRegistro(
    PWR_MGMT_1,
    0x00
  );

  delay(100);


  // Clock
  escreverRegistro(
    PWR_MGMT_1,
    0x01
  );


  // Filtro
  escreverRegistro(
    CONFIG,
    0x03
  );


  // Aproximadamente 100 Hz
  escreverRegistro(
    SMPLRT_DIV,
    9
  );


  // Gyro ±250°/s
  escreverRegistro(
    GYRO_CONFIG,
    0x00
  );


  // Acelerômetro ±2g
  escreverRegistro(
    ACCEL_CONFIG,
    0x00
  );


  // Filtro acelerômetro
  escreverRegistro(
    ACCEL_CONFIG2,
    0x04
  );


  delay(100);


  return true;
}


// ============================================================
// LER SENSOR
// ============================================================

bool lerSensores()
{
  Wire.beginTransmission(MPU_ADDR);

  Wire.write(ACCEL_XOUT_H);

  if (
    Wire.endTransmission(false) != 0
  )
  {
    return false;
  }


  // AX
  // AY
  // AZ
  // TEMP
  // GX
  // GY
  // GZ

  Wire.requestFrom(
    MPU_ADDR,
    (uint8_t)14
  );


  if (
    Wire.available() != 14
  )
  {
    return false;
  }


  int16_t rawAX =
    (Wire.read() << 8) |
    Wire.read();


  int16_t rawAY =
    (Wire.read() << 8) |
    Wire.read();


  int16_t rawAZ =
    (Wire.read() << 8) |
    Wire.read();


  // temperatura
  Wire.read();
  Wire.read();


  int16_t rawGX =
    (Wire.read() << 8) |
    Wire.read();


  int16_t rawGY =
    (Wire.read() << 8) |
    Wire.read();


  int16_t rawGZ =
    (Wire.read() << 8) |
    Wire.read();


  // ----------------------------------------------------------
  // Acelerômetro
  // ----------------------------------------------------------

  ax =
    rawAX / ACCEL_SCALE;

  ay =
    rawAY / ACCEL_SCALE;

  az =
    rawAZ / ACCEL_SCALE;


  // ----------------------------------------------------------
  // Giroscópio
  // ----------------------------------------------------------

  gx =
    (rawGX / GYRO_SCALE)
    - gyroOffsetX;


  gy =
    (rawGY / GYRO_SCALE)
    - gyroOffsetY;


  gz =
    (rawGZ / GYRO_SCALE)
    - gyroOffsetZ;


  return true;
}


// ============================================================
// MAGNITUDE
// ============================================================

float magnitude(
  float x,
  float y,
  float z
)
{
  return sqrt(
    x * x +
    y * y +
    z * z
  );
}


// ============================================================
// CALIBRAÇÃO
// ============================================================

void calibrar()
{
  Serial.println();

  Serial.println(
    "Calibrando..."
  );

  Serial.println(
    "Nao mova o MPU!"
  );

  delay(2000);


  const int AMOSTRAS = 200;


  float somaG = 0;

  float somaGX = 0;
  float somaGY = 0;
  float somaGZ = 0;


  int validas = 0;


  for (
    int i = 0;
    i < AMOSTRAS;
    i++
  )
  {
    if (lerSensores())
    {
      somaG +=
        magnitude(
          ax,
          ay,
          az
        );


      somaGX += gx;
      somaGY += gy;
      somaGZ += gz;


      validas++;
    }


    delay(10);
  }


  if (validas == 0)
  {
    Serial.println(
      "Falha na calibracao!"
    );

    return;
  }


  referenciaG =
    somaG / validas;


  gyroOffsetX =
    somaGX / validas;


  gyroOffsetY =
    somaGY / validas;


  gyroOffsetZ =
    somaGZ / validas;


  Serial.println();

  Serial.print(
    "Referencia G: "
  );

  Serial.println(
    referenciaG,
    3
  );


  Serial.print(
    "Gyro X offset: "
  );

  Serial.println(
    gyroOffsetX,
    3
  );


  Serial.print(
    "Gyro Y offset: "
  );

  Serial.println(
    gyroOffsetY,
    3
  );


  Serial.print(
    "Gyro Z offset: "
  );

  Serial.println(
    gyroOffsetZ,
    3
  );


  Serial.println();

  Serial.println(
    "Calibracao concluida!"
  );

  Serial.println();
}


// ============================================================
// LER BPM SIMULADO
// ============================================================

int lerBPM()
{
  int valor =
    analogRead(BPM_PIN);


  // 0 - 4095
  //
  // convertido para:
  //
  // 40 - 160 BPM

  int resultado =
    map(
      valor,
      0,
      4095,
      40,
      160
    );


  return resultado;
}


// ============================================================
// NÍVEL DE MOVIMENTO
// ============================================================

float calcularMovimento()
{
  float acel =
    (deltaAceleracao / 0.30)
    * 100.0;


  float gyro =
    (velocidadeRotacao / 100.0)
    * 100.0;


  if (acel > 100)
    acel = 100;


  if (gyro > 100)
    gyro = 100;


  float nivel =
    (acel * 0.40) +
    (gyro * 0.60);


  if (nivel > 100)
    nivel = 100;


  return nivel;
}


// ============================================================
// NOME DO ESTADO
// ============================================================

const char* nomeEstado()
{
  switch (estadoAtual)
  {
    case INERTE:
      return "INERTE";

    case MOVIMENTO:
      return "EM MOVIMENTO";

    case QUEDA_LIVRE:
      return "QUEDA LIVRE";

    case AGUARDANDO_IMPACTO:
      return "AGUARDANDO IMPACTO";

    case POS_IMPACTO:
      return "POS-IMPACTO";

    default:
      return "DESCONHECIDO";
  }
}


// ============================================================
// LEDS
// ============================================================

void atualizarLEDs()
{
  digitalWrite(
    LED_VERDE,
    estadoAtual == INERTE
  );


  digitalWrite(
    LED_AMARELO,
    estadoAtual == MOVIMENTO
  );


  digitalWrite(
    LED_VERMELHO,
    estadoAtual == QUEDA_LIVRE ||
    estadoAtual == AGUARDANDO_IMPACTO ||
    estadoAtual == POS_IMPACTO
  );
}


// ============================================================
// SETUP
// ============================================================

void setup()
{
  Serial.begin(
    115200
  );


  delay(1000);


  // ----------------------------------------------------------
  // LEDS
  // ----------------------------------------------------------

  pinMode(
    LED_VERDE,
    OUTPUT
  );

  pinMode(
    LED_AMARELO,
    OUTPUT
  );

  pinMode(
    LED_VERMELHO,
    OUTPUT
  );


  // ----------------------------------------------------------
  // BUZZER
  // ----------------------------------------------------------

  pinMode(
    BUZZER_PIN,
    OUTPUT
  );


  // ----------------------------------------------------------
  // BPM
  // ----------------------------------------------------------

  pinMode(
    BPM_PIN,
    INPUT
  );


  // ----------------------------------------------------------
  // I2C
  // ----------------------------------------------------------

  Wire.begin(
    SDA_PIN,
    SCL_PIN
  );

  Wire.setClock(
    400000
  );


  Serial.println();

  Serial.println(
    "========================================"
  );

  Serial.println(
    " SISTEMA DE MONITORAMENTO"
  );

  Serial.println(
    " ESP32 + MPU6050 + BPM"
  );

  Serial.println(
    "========================================"
  );

  Serial.println();


  // ----------------------------------------------------------
  // MPU
  // ----------------------------------------------------------

  if (!inicializarMPU())
  {
    Serial.println(
      "Erro ao inicializar MPU!"
    );

    while (true)
    {
      delay(1000);
    }
  }


  // ----------------------------------------------------------
  // CALIBRAÇÃO
  // ----------------------------------------------------------

  calibrar();


  // ----------------------------------------------------------
  // PRIMEIRA LEITURA
  // ----------------------------------------------------------

  lerSensores();


  aceleracaoG =
    magnitude(
      ax,
      ay,
      az
    );


  aceleracaoAnterior =
    aceleracaoG;


  // ----------------------------------------------------------
  // BPM INICIAL
  // ----------------------------------------------------------

  bpm =
    lerBPM();

  bpmInicial =
    bpm;

  bpmAnterior =
    bpm;


  Serial.println(
    "Sistema pronto!"
  );

  Serial.println();


  digitalWrite(
    LED_VERDE,
    HIGH
  );
}


// ============================================================
// LOOP
// ============================================================

void loop()
{
  // ==========================================================
  // LEITURA MPU
  // ==========================================================

  if (!lerSensores())
  {
    Serial.println(
      "Erro de leitura MPU."
    );

    delay(100);

    return;
  }


  // ==========================================================
  // ACELERAÇÃO
  // ==========================================================

  aceleracaoG =
    magnitude(
      ax,
      ay,
      az
    );


  // ==========================================================
  // VARIAÇÃO DA ACELERAÇÃO
  // ==========================================================

  deltaAceleracao =
    fabs(
      aceleracaoG -
      aceleracaoAnterior
    );


  aceleracaoAnterior =
    aceleracaoG;


  // ==========================================================
  // GIRO
  // ==========================================================

  velocidadeRotacao =
    magnitude(
      gx,
      gy,
      gz
    );


  // ==========================================================
  // MOVIMENTO
  // ==========================================================

  float nivelMovimento =
    calcularMovimento();


  // ==========================================================
  // BPM
  // ==========================================================

  bpm =
    lerBPM();


  // ==========================================================
  // MÁQUINA DE ESTADOS
  // ==========================================================

  switch (estadoAtual)
  {

    // ========================================================
    // INERTE
    // ========================================================

    case INERTE:
    {
      // Queda livre

      if (
        aceleracaoG <
        referenciaG *
        FREEFALL_THRESHOLD
      )
      {
        estadoAtual =
          QUEDA_LIVRE;

        inicioQuedaLivre =
          millis();


        Serial.println();

        Serial.println(
          ">>> POSSIVEL QUEDA"
        );

        Serial.println(
          ">>> QUEDA LIVRE DETECTADA"
        );

        Serial.println();


        noTone(
          BUZZER_PIN
        );
      }


      // Movimento

      else if (
        nivelMovimento >
        2.0
      )
      {
        estadoAtual =
          MOVIMENTO;
      }


      break;
    }


    // ========================================================
    // MOVIMENTO
    // ========================================================

    case MOVIMENTO:
    {
      // Queda livre

      if (
        aceleracaoG <
        referenciaG *
        FREEFALL_THRESHOLD
      )
      {
        estadoAtual =
          QUEDA_LIVRE;

        inicioQuedaLivre =
          millis();


        Serial.println();

        Serial.println(
          ">>> POSSIVEL QUEDA"
        );

        Serial.println(
          ">>> QUEDA LIVRE DETECTADA"
        );

        Serial.println();
      }


      // Voltou a ficar parado

      else if (
        nivelMovimento <
        2.0
      )
      {
        estadoAtual =
          INERTE;
      }


      break;
    }


    // ========================================================
    // QUEDA LIVRE
    // ========================================================

    case QUEDA_LIVRE:
    {
      unsigned long tempo =
        millis() -
        inicioQuedaLivre;


      // Ainda em queda livre

      if (
        aceleracaoG <
        referenciaG *
        FREEFALL_THRESHOLD
      )
      {
        // continua
      }


      else
      {
        // Queda livre suficiente?

        if (
          tempo >=
          FREEFALL_MIN_TIME
        )
        {
          estadoAtual =
            AGUARDANDO_IMPACTO;

          inicioImpacto =
            millis();


          Serial.println();

          Serial.println(
            ">>> QUEDA LIVRE CONFIRMADA"
          );

          Serial.println(
            ">>> AGUARDANDO IMPACTO"
          );

          Serial.println();
        }

        else
        {
          estadoAtual =
            MOVIMENTO;
        }
      }


      // Segurança

      if (
        millis() -
        inicioQuedaLivre >
        IMPACT_WINDOW
      )
      {
        estadoAtual =
          MOVIMENTO;

        Serial.println(
          ">>> Queda cancelada."
        );
      }


      break;
    }


    // ========================================================
    // AGUARDANDO IMPACTO
    // ========================================================

    case AGUARDANDO_IMPACTO:
    {
      unsigned long tempo =
        millis() -
        inicioImpacto;


      // Impacto

      if (
        aceleracaoG >
        referenciaG *
        IMPACT_THRESHOLD
      )
      {
        estadoAtual =
          POS_IMPACTO;

        inicioPosImpacto =
          millis();


        somaMovimento =
          0;

        quantidadeAmostras =
          0;


        Serial.println();

        Serial.println(
          "!!! IMPACTO DETECTADO !!!"
        );

        Serial.println(
          ">>> Observando movimento..."
        );

        Serial.println();


        tone(
          BUZZER_PIN,
          2000,
          200
        );
      }


      // Timeout

      else if (
        tempo >
        IMPACT_WINDOW
      )
      {
        estadoAtual =
          MOVIMENTO;


        Serial.println();

        Serial.println(
          ">>> QUEDA CANCELADA"
        );

        Serial.println(
          ">>> Nenhum impacto detectado."
        );

        Serial.println();
      }


      break;
    }


    // ========================================================
    // POS IMPACTO
    // ========================================================

    case POS_IMPACTO:
    {
      unsigned long tempo =
        millis() -
        inicioPosImpacto;


      // Guardar movimento

      somaMovimento +=
        nivelMovimento;

      quantidadeAmostras++;


      // ------------------------------------------------------
      // Após 3 segundos
      // ------------------------------------------------------

      if (
        tempo >=
        POST_IMPACT_TIME
      )
      {
        float movimentoMedio =
          somaMovimento /
          quantidadeAmostras;


        // ----------------------------------------------------
        // QUEDA DETECTADA
        // ----------------------------------------------------

        if (
          movimentoMedio <
          POST_IMPACT_MOVEMENT
        )
        {
          Serial.println();

          Serial.println(
            "========================================"
          );

          Serial.println(
            "       !!! QUEDA DETECTADA !!!"
          );

          Serial.println(
            "========================================"
          );


          Serial.println();


          // --------------------------------------------------
          // DADOS DA QUEDA
          // --------------------------------------------------

          Serial.print(
            "BPM no momento: "
          );

          Serial.println(
            bpm
          );


          Serial.print(
            "BPM inicial: "
          );

          Serial.println(
            bpmInicial
          );


          Serial.print(
            "Variacao BPM: "
          );


          Serial.print(
            bpm - bpmInicial
          );


          Serial.println(
            " BPM"
          );


          Serial.print(
            "Movimento apos impacto: "
          );


          Serial.print(
            movimentoMedio,
            1
          );


          Serial.println(
            " / 100"
          );


          Serial.println();


          // --------------------------------------------------
          // ALERTA
          // --------------------------------------------------

          tone(
            BUZZER_PIN,
            2000,
            1000
          );


          // --------------------------------------------------
          // Aqui futuramente podemos fazer:
          //
          // if (bpm confirmado)
          //     enviar alerta
          //
          // --------------------------------------------------
        }


        else
        {
          Serial.println();

          Serial.println(
            ">>> POSSIVEL QUEDA CANCELADA"
          );

          Serial.println(
            ">>> Movimento apos impacto."
          );

          Serial.println();
        }


        estadoAtual =
          INERTE;
      }


      break;
    }
  }


  // ==========================================================
  // LEDS
  // ==========================================================

  atualizarLEDs();


  // ==========================================================
  // SERIAL
  // ==========================================================

  if (
    millis() -
    ultimoPrint >=
    500
  )
  {
    ultimoPrint =
      millis();


    Serial.print(
      "Acel: "
    );

    Serial.print(
      aceleracaoG,
      2
    );


    Serial.print(
      " g"
    );


    Serial.print(
      " | Giro: "
    );


    Serial.print(
      velocidadeRotacao,
      1
    );


    Serial.print(
      " °/s"
    );


    Serial.print(
      " | Movimento: "
    );


    Serial.print(
      nivelMovimento,
      1
    );


    Serial.print(
      "/100"
    );


    Serial.print(
      " | BPM: "
    );


    Serial.print(
      bpm
    );


    Serial.print(
      " | Estado: "
    );


    Serial.println(
      nomeEstado()
    );
  }


  delay(10);
}