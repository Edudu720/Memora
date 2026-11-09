# Quickstart: Validação do Monitoramento IoT com ESP32 Físico e Alertas de Queda

Cenários de validação manual e automatizada para provar que a Feature 005 funciona de ponta a ponta com o **hardware ESP32 físico** (`ESP32 DevKit` + `MPU6050/9250/9255` + `Pulse Sensor PPG`) e com o modo Simulador do aplicativo.

---

## 1. Pré-requisitos

### No Aplicativo Flutter:
```powershell
cd app; flutter pub get
```

### Na Montagem Física do ESP32:
- **Placa**: ESP32 DevKit (30 ou 38 pinos).
- **Sensor Inercial (MPU6050 / MPU9250 / MPU9255)**:
  - `VCC` → `3V3`
  - `GND` → `GND`
  - `SDA` → `GPIO 21`
  - `SCL` → `GPIO 22`
- **Sensor Cardíaco Óptico (Pulse Sensor Analógico)**:
  - `VCC` → `3V3`
  - `GND` → `GND`
  - `Sinal (S)` → `GPIO 34` (`ADC1`)
- **Rede Wi-Fi 2,4 GHz**: Configurar `WIFI_SSID` e `WIFI_PASS` no sketch `specs/005-monitoramento-iot-quedas/firmware_wokwi.ino`.

---

## 2. Execução da Suíte Automatizada de Portões (8/8)

Na raiz do repositório:

```powershell
python specs/005-monitoramento-iot-quedas/validar_suite_cuidado.py
```

E para os testes automatizados do Flutter e análise estática:

```powershell
cd app
flutter analyze
flutter test test/features/cuidado/
```

---

## 3. Cenários de Validação Ponta a Ponta

### V1 — Inicialização e Autocalibração do MPU no ESP32 Físico
1. Energizar o ESP32 com o módulo MPU apoiado e imóvel sobre uma superfície plana.
2. Abrir o Serial Monitor em `115200 baud`.
3. **Espera-se**:
   - Identificação I2C do MPU (`0x68` ou `0x69`, `WHO_AM_I` reconhecido).
   - Conclusão da calibração de 300 amostras com magnitude corrigida próxima de `1.00 g`.
   - Inicialização do `PulseSensor Playground` no `GPIO 34`.
   - Conexão ao Wi-Fi e ao broker MQTT (`broker.hivemq.com:1883`) com ClientID `Memora-ESP32-<MAC>`.

---

### V2 — Aferição de BPM Óptico e Movimento em Tempo Real no App (FR-001 a FR-004, FR-013)
1. No aplicativo Memora, abrir a porta **"Dispositivo de Cuidado"** a partir do Hub.
2. Conectar ao dispositivo via MQTT (`broker.hivemq.com`, tópico `memora/iot/demonstracao-01`).
3. Apoiar suavemente a ponta do dedo sobre a face óptica do Pulse Sensor sem pressionar em excesso.
4. **Espera-se**:
   - Quando sem o dedo no sensor (`bpm_valido: false`), o cartão exibe `-- BPM` com mensagem orientativa.
   - Com o dedo apoiado (`bpm_valido: true`), o cartão passa a exibir o BPM real atualizado a cada `500 ms`.
   - Ao movimentar ou girar a placa, o estado alterna de `"Em repouso tranquilo"` (`INERTE`) para `"Em movimento ativo"` (`EM_MOVIMENTO`).

---

### V3 — Detecção de Queda Física com Filtro Pós-Impacto e Resposta "Estou bem" (FR-005 a FR-008)
1. Com o ESP32 conectado ao aplicativo, simular uma queda livre rápida (`< 0.55 g` por `>= 80 ms`) seguida de batida/impacto (`>= 2.5 g`) sobre uma almofada/mesa e manter o sensor imóvel por **3 segundos** (`POS_IMPACTO`).
2. **Espera-se**:
   - O Serial Monitor exibe `QUEDA DETECTADA` e publica no tópico `/alerta`.
   - O celular vibra imediatamente e abre a tela **"Você está bem?"** com contagem regressiva de **45 segundos**.
3. Tocar no botão **"Estou bem"**.
4. **Espera-se**:
   - A tela de alerta fecha imediatamente (< 300 ms).
   - O aplicativo publica `{"comando":"CESSAR_ALARME"}` no tópico `/comando`.
   - O ESP32 recebe o comando e retorna do estado `QUEDA_DETECTADA` para `INERTE`.

---

### V4 — Descarte Automático de Falso Positivo Pós-Impacto
1. Provocar um movimento brusco seguido de impacto no sensor, mas continuar movimentando o módulo nos 3 segundos seguintes (`movimentoMedioPosImpacto >= 10.0`).
2. **Espera-se**:
   - O firmware registra `>>> Possivel queda descartada: movimento medio apos impacto ...` e retorna para `EM_MOVIMENTO` sem disparar falso alarme no celular.

---

### V5 — Escalada de Emergência via WhatsApp com Mensagem Pré-Pronta (FR-009, FR-010, FR-020)
1. Cadastrar um contato de emergência válido com DDD na `TelaDispositivoCuidado`.
2. Disparar um evento de queda (pelo ESP32 físico ou pelo botão *"Simular Queda de Teste"* no modo Simulador).
3. Tocar em **"Preciso de ajuda"** (ou aguardar os 45 segundos zerarem).
4. **Espera-se**:
   - Abertura imediata da conversa do contato de emergência no **WhatsApp** (`whatsapp://send?phone=55<numero>&text=<mensagem>`) com a mensagem de socorro, data, horário e a cláusula obrigatória antigolpe já preenchidos e prontos para envio (ou fallback para `wa.me` / SMS / discador caso o WhatsApp não esteja instalado).

---

### V6 — Privacidade na Saída da Conta e Segurança de Rede (FR-021, FR-022, Issue #43)
1. Com um contato de emergência salvo, encerrar a sessão da conta no aplicativo (`LimpezaDeSessao.executar()`).
2. **Espera-se**:
   - O `RepositorioContatoEmergenciaLocal` apaga o contato de emergência do `SharedPreferences` via `DadoLocalDaPessoa.apagar()`.
   - O `AndroidManifest.xml` não contém `android:usesCleartextTraffic="true"` e o `ProvedorDeTelemetriaMqtt` suporta conexão TLS (`porta 8883`) e credenciais de autenticação.
