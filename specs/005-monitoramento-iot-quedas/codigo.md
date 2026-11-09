# Código do ESP32 Físico — Memora IoT (MPU6050/9250/9255 + Pulse Sensor + MQTT)

Consulte o sketch completo em [`firmware_wokwi.ino`](firmware_wokwi.ino), projetado para execução no **ESP32 DevKit físico** com:

- **MPU6050 / MPU9250 / MPU9255** via barramento I2C (`SDA=21`, `SCL=22`, clock `100 kHz`), fundo de escala `±8 g` e `±250 graus/s`, com calibração inicial automática de 300 amostras em repouso.
- **Pulse Sensor analógico (PPG)** no `GPIO 34` (`ADC1`, resolução de `10 bits`) utilizando a biblioteca `PulseSensorPlayground` (`500 Hz`).
- **Máquina de 6 estados**: `INERTE`, `EM_MOVIMENTO`, `QUEDA_LIVRE`, `AGUARDANDO_IMPACTO`, `POS_IMPACTO` (3 segundos de verificação de imobilidade pós-impacto) e `QUEDA_DETECTADA`.
- **Comunicação MQTT 3.1.1** (`broker.hivemq.com:1883`, com suporte opcional a credenciais `MQTT_USER` / `MQTT_PASS`) nos tópicos:
  - `memora/iot/demonstracao-01/telemetria`
  - `memora/iot/demonstracao-01/alerta`
  - `memora/iot/demonstracao-01/comando` (recebe `CESSAR_ALARME` para retornar a máquina de estados para `INERTE`).
