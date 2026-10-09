# Quickstart: Validação do Monitoramento IoT e Alertas de Queda

Cenários de validação manual e automatizada para provar que a feature 005 funciona de ponta a ponta.

---

## 1. Pré-requisitos

```powershell
cd app; flutter pub get
```

Ter o emulador Android ou celular conectado (Galaxy S20 FE do Henrique ou Pixel 6).

---

## 2. Cenários de Validação

### V1 — Visualizar Tela do Dispositivo de Cuidado (FR-001 a FR-004)
1. Abrir o Memora e navegar para o Hub ou Configurações.
2. Tocar no cartão **"Dispositivo de Cuidado"** (ou "Minha Pulseira").
3. **Espera-se**:
   - Exibição do status "Conectado" ou "Aguardando conexão".
   - Frequência cardíaca atual em números grandes (BPM).
   - Indicador de estado de movimento ("Em movimento" ou "Em repouso").
   - Nenhum corte ou estouro de layout.

---

### V2 — Telemetria Dinâmica em Tempo Real (FR-003, FR-013)
1. No modo simulado ou conectado ao Wokwi, alterar o potenciômetro de BPM no simulador ou nos controles de teste.
2. **Espera-se**:
   - O valor na tela atualiza em menos de 1 segundo de forma suave.
   - O indicador de movimento reage às oscilações do sensor.

---

### V3 — Queda Detectada e Confirmação "Estou bem" (FR-005 a FR-008)
1. Injetar um evento de queda (no simulador ou simulando no Wokwi movimentando o MPU6050 bruscamente para baixo e mantendo parado).
2. **Espera-se**:
   - O celular toca aviso sonoro alto e começa a vibrar.
   - A tela assume o alerta com a pergunta: *"Você está bem?"*.
   - Cronômetro inicia a contagem de 45 segundos.
3. Tocar no botão *"Estou bem"*.
4. **Espera-se**:
   - O som e a vibração cessam imediatamente (< 300 ms).
   - A tela fecha e volta à tela anterior com tranquilidade.
   - Nenhum socorro externo é acionado.

---

### V4 — Queda sem Resposta / Expiração de 45 Segundos (FR-009, FR-010, FR-020)
1. Cadastrar um contato de emergência (ex.: "Filho Carlos" com número de teste).
2. Injetar um evento de queda.
3. Aguardar a contagem regressiva de 45 segundos expirar sem tocar na tela.
4. **Espera-se**:
   - Ao atingir 0 segundos, o app aciona o discador do Android com o número do contato preenchido.
   - Prepara o disparo da mensagem de socorro contendo o aviso antigolpe e horário do ocorrido.

---

### V5 — Toque Direto em "Preciso de ajuda" (FR-010, FR-020)
1. Disparar o alerta de queda.
2. Tocar imediatamente no botão *"Preciso de ajuda"*.
3. **Espera-se**:
   - O socorro é acionado instantaneamente sem aguardar o restante dos 45 segundos.

---

### V6 — Integração com o Simulador Wokwi via MQTT (FR-013)
1. Abrir o projeto no Wokwi (`https://wokwi.com/projects/477262321619688449`).
2. Executar a simulação com as rotinas MQTT ativas.
3. No app Memora, selecionar o modo MQTT e conectar no tópico de demonstração.
4. **Espera-se**:
   - Telemetria do Wokwi refletida em tempo real no app Memora.
