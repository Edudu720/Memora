# Pull Request: Implementação do Monitoramento IoT, Detecção de Quedas e Integração Wokwi (Feature 005)

## 📌 Resumo da PR

Esta PR implementa a integração completa do **Dispositivo de Cuidado IoT** (ESP32 com MPU6050 e medidor de BPM simulado com potenciômetro) com o aplicativo Memora, devidamente sincronizada com o estado mais recente da `master` (Features 003 e 004). O sistema monitora batimentos cardíacos e movimentação do idoso em tempo real e, ao detectar uma queda brusca, inicia um protocolo de segurança e verificação de bem-estar:

1. **Alerta Imediato**: O celular vibra e apresenta uma tela de confirmação acessível com a pergunta *"Você está bem?"* e um cronômetro regressivo de 45 segundos.
2. **Resposta Positiva ("Estou bem")**: Interrompe o alarme imediatamente no celular e envia um comando via MQTT ao ESP32 (`{"comando":"CESSAR_ALARME"}`), desligando o buzzer sonoro.
3. **Falta de Resposta (45 s) ou Resposta Negativa ("Preciso de ajuda")**: Aciona automaticamente socorro duplo ao contato de emergência cadastrado:
   - Abre o discador nativo do Android (`ACTION_DIAL`) com o telefone pré-preenchido.
   - Prepara o disparo de mensagem nativa (`ACTION_SENDTO`) contendo aviso com hora, data e texto de segurança antigolpe (Princípio II da Constituição).
4. **Integração Real-Time com o Simulador Wokwi**: Permite conexão direta via broker MQTT 3.1.1 (`broker.hivemq.com:1883`) com o firmware em execução no Wokwi (`https://wokwi.com/projects/477262321619688449`), além de um modo simulador integrado para testes offline.

---

## 🛠️ Arquivos Modificados e Justificativas

### 1. Configuração e Dependências
- `app/pubspec.yaml`:
  - Adicionada dependência `mqtt_client: ^10.3.3` para comunicação bidirecional em tempo real com o broker MQTT.
- `app/android/app/src/main/AndroidManifest.xml`:
  - Adicionadas permissões `<uses-permission android:name="android.permission.INTERNET"/>` e `<uses-permission android:name="android.permission.VIBRATE"/>`.
  - Habilitado `android:usesCleartextTraffic="true"` na `<application>` para permitir tráfego TCP/MQTT na porta 1883 com o broker público do Wokwi (`broker.hivemq.com`), preservando integralmente as regras de segurança `allowBackup="false"`, `fullBackupContent` e `dataExtractionRules` da `master`.
  - Adicionadas as `<intent>` para `android.intent.action.DIAL` (esquema `tel`) e `android.intent.action.SENDTO` (esquema `smsto`) dentro de `<queries>` (junto aos pacotes de aplicativos e TikTok da `master`), exigido pelo Android 11+ para interação entre aplicativos.

### 2. Integração no Hub Principal e Casca de Navegação
- `app/lib/features/autenticacao/presentation/fluxo_autenticacao.dart`:
  - Sincronizado com a `master` (mantendo a porta `Ajuda do aplicativo` e guias de assunto) e adicionada a porta do Hub para o **Dispositivo de Cuidado**, conectando a navegação à `TelaDispositivoCuidado`, inicializando o repositório de contatos e injetando o nome da pessoa idosa.
- `app/test/features/casca/profundidade_test.dart` e `app/test/acessibilidade/hub_cabe_sem_rolar_test.dart`:
  - Registrada a rota `deCuidado` no teste de profundidade máxima (SC-006: máximo de 3 toques a partir do Hub) e ajustada a dimensão vertical de referência do Hub para acomodar as 6 portas do sistema sem rolagem.

---

## 📂 Arquivos Criados no Módulo IoT (`app/lib/features/cuidado/`) e Detalhamento

### Camada de Domínio (`app/lib/features/cuidado/domain/`)

#### 1. Entidades (`domain/entidades/`)
- `enums_cuidado.dart`:
  - `StatusConexaoIot`: Estados da conexão (`desconectado`, `conectando`, `conectado`).
  - `StatusConfirmacaoQueda`: Estados da máquina de confirmação (`aguardandoConfirmacao`, `canceladoPeloUsuario`, `socorroAcionado`, `tempoExpirado`).
  - `ModoOperacaoIot`: Modos de execução do provedor (`simulado`, `mqtt`).
- `telemetria_iot.dart`:
  - Entidade `TelemetriaIot`: Dados instantâneos do sensor (`timestamp`, `bpm`, `aceleracaoG`, `nivelMovimento`, `emMovimento`, `estadoSensor`).
  - Métodos: `fromJson(Map<String, dynamic>)` resiliente com fallbacks, `toJson()`, `copyWith(...)`, `operator ==`, `hashCode`.
- `evento_queda.dart`:
  - Entidade `EventoQueda`: Registra o evento de queda com dados no momento do impacto.
  - Métodos: `EventoQueda.novo(...)` com contador padrão de 45 segundos, `fromJson(...)`, `toJson()`, `copyWith(...)`.
- `contato_emergencia.dart`:
  - Entidade `ContatoEmergencia`: Pessoa de confiança (`id`, `nome`, `telefone`, `parentesco`, `ativo`).
  - Propriedades/Métodos:
    - `telefoneNumeros`: Normaliza caracteres não numéricos e remove automaticamente prefixo internacional `+55` quando presente.
    - `ehValido`: Valida se o nome está preenchido e se o telefone possui 10 ou 11 dígitos com DDD.
    - `fromJson(...)`, `toJson()`, `copyWith(...)`.
- `dispositivo_cuidado.dart`:
  - Entidade `DispositivoCuidado`: Agregador do dispositivo (`id`, `nome`, `statusConexao`, `modoOperacao`, `brokerHost`, `topicoBase`, `ultimaTelemetria`).
  - Propriedade: `estaConectado`.

#### 2. Repositórios e Provedores (`domain/repositorios/`)
- `provedor_telemetria.dart`:
  - Interface `ProvedorDeTelemetria` com Streams reativos: `streamTelemetria`, `streamQueda`, `streamStatusConexao`.
  - Métodos contratuais: `conectar()`, `desconectar()`, `enviarComandoCessarAlarme()`, `descartar()`.
- `repositorio_contato_emergencia.dart`:
  - Interface `RepositorioContatoEmergencia`: Métodos `obterContato()`, `salvarContato(...)`, `removerContato()`.

#### 3. Casos de Uso (`domain/casos_de_uso/`)
- `disparar_socorro_emergencia.dart`:
  - Classe `DispararSocorroEmergencia`:
    - `executar(...)`: Dispara a chamada nativa via `AndroidIntent(action: 'android.intent.action.DIAL', data: 'tel:...')` e prepara SMS via `AndroidIntent(action: 'android.intent.action.SENDTO', data: 'smsto:...')`.
    - `_formatarMensagemSocorro(...)`: Gera a mensagem padronizada contendo data, horário, identificação da pessoa e o aviso de segurança: *"(AVISO DE SEGURANÇA: O Memora NUNCA solicita dinheiro, transferências ou senhas)"*, cumprindo o Princípio II (Antigolpe).

---

### Camada de Dados (`app/lib/features/cuidado/data/`)

#### 1. Provedores de Telemetria (`data/provedores/`)
- `provedor_telemetria_simulado.dart`:
  - `ProvedorDeTelemetriaSimulado`: Gerador mock que emite batimentos oscilando entre 68 e 76 BPM e movimento em repouso/ativo a cada 1 segundo.
  - Métodos: `conectar()`, `desconectar()`, `simularQueda(...)` (injeta alerta de queda com 45 s de timeout), `atualizarTelemetriaManual(...)`, `enviarComandoCessarAlarme()`, `descartar()`.
- `provedor_telemetria_mqtt.dart`:
  - `ProvedorDeTelemetriaMqtt`: Cliente MQTT real via `MqttServerClient`.
  - Recursos de resiliência em emulador/dispositivo:
    - Sanitização automática de host (remove esquemas `mqtt://`, `tcp://`, barras e portas coladas) e de tópico base.
    - Resolução DNS priorizando IPv4 (`InternetAddress.lookup(host, type: InternetAddressType.IPv4)`) para evitar falhas de rota IPv6 em emuladores Android.
    - Negociação explícita do protocolo **MQTT 3.1.1** (`setProtocolV311()`), compatível com `broker.hivemq.com` e `PubSubClient` do ESP32.
  - Métodos:
    - `conectar()`: Estabelece conexão com o broker HiveMQ e assina tópicos de telemetria (`/telemetria`) e alerta (`/alerta`).
    - `_processarMensagensMqtt(...)`: Desserializa payloads JSON e repassa para os streams de domínio.
    - `enviarComandoCessarAlarme()`: Publica a mensagem `{"comando":"CESSAR_ALARME"}` no tópico `/comando` com QoS 1.
    - `desconectar()` e `descartar()`.

#### 2. Repositório Local (`data/repositorios/`)
- `repositorio_contato_emergencia_local.dart`:
  - `RepositorioContatoEmergenciaLocal`: Persistência do contato de emergência em formato JSON utilizando `SharedPreferences`.

---

### Camada de Apresentação (`app/lib/features/cuidado/presentation/`)

#### 1. Widgets do Design System (`presentation/widgets/`)
- `medidor_bpm.dart`:
  - `MedidorBpm`: Exibe a frequência cardíaca com tipografia `MemoraTipografia.destaque` (36 sp) e `MemoraTipografia.corpo`, ícone `MemoraDimensoes.iconeDestaque` e texto de apoio com classificação médica acessível.
- `indicador_movimento.dart`:
  - `IndicadorMovimento`: Exibe o estado da pessoa ("Em movimento ativo" ou "Em repouso tranquilo") com cores semânticas (`cores.sucesso` / `cores.primaria`) e ícones de alta visibilidade.
- `cronometro_regressivo_queda.dart`:
  - `CronometroRegressivoQueda`: Exibe o tempo restante com números destacados, barra de progresso linear e texto explicativo, respeitando a separação mínima de toque e espaçamentos do DS.

#### 2. Controladores de Estado (`presentation/controladores/`)
- `controlador_dispositivo_cuidado.dart`:
  - `ControladorDispositivoCuidado`: Escuta os streams do provedor atual, mantém a última telemetria, gerencia o modo de operação (`simulado` vs `mqtt`), expõe mensagens de diagnóstico em caso de falha de rede (`ultimoErroConexao`), carrega e salva contatos de emergência e propaga eventos de queda para a tela.
- `controlador_verificacao_queda.dart`:
  - `ControladorVerificacaoQueda`: Gerencia a contagem regressiva de 45 segundos através de um `Timer.periodic`.
  - Métodos:
    - `responderEstouBem()`: Cancela o temporizador, muda status para `canceladoPeloUsuario`, envia `enviarComandoCessarAlarme()` ao broker e fecha a tela.
    - `responderPrecisoDeAjuda()`: Cancela o temporizador e aciona socorro imediato.
    - `_aoExpirarTempo()`: Disparado aos 0 segundos, acionando o socorro automaticamente.
    - `_acionarSocorro()`: Chama o caso de uso `DispararSocorroEmergencia`.

#### 3. Telas (`presentation/telas/`)
- `tela_dispositivo_cuidado.dart`:
  - Tela principal do módulo contendo:
    - Indicador de status de conexão com cor do Design System e texto explícito.
    - Cartões de frequência cardíaca (`MedidorBpm`) e movimentação (`IndicadorMovimento`).
    - Cartão com os dados do contato de emergência e botão para cadastrar/editar.
    - Painel expansível para integração com Wokwi (configuração de host/tópico MQTT) e botão de teste `BotaoPerigo` para simulação manual de queda.
- `tela_verificacao_queda.dart`:
  - Tela de alerta imediato com affordance maximizada para idosos:
    - Pergunta em destaque *"Você está bem?"* (`MemoraTipografia.destaque`).
    - Botão verde de confirmação *"Estou bem"* com altura `MemoraDimensoes.alvoDecisao` (56 dp) e ícone claro.
    - Botão `BotaoPerigo` de emergência *"Preciso de ajuda"* separado com espaçamento seguro para evitar toques acidentais.
    - Aviso de segurança contra golpes em conformidade com o piso de 16 sp (`MemoraTipografia.apoio`).
- `dialogo_contato_emergencia.dart`:
  - Modal para registro do contato de confiança contendo campos validados (`CampoTexto`) para nome, telefone com DDD e parentesco.

---

### Firmware ESP32 Wokwi (`specs/005-monitoramento-iot-quedas/firmware_wokwi.ino`)

Código C++ completo desenvolvido para execução no simulador Wokwi:
- Conexão Wi-Fi com a rede `Wokwi-GUEST`.
- Leitura dos registradores do acelerômetro e giroscópio MPU6050 via protocolo I2C (pinos 21 e 22).
- Leitura da simulação de BPM via conversor analógico-digital (ADC, pino 34).
- Máquina de estados de detecção de queda: `INERTE` ➔ `MOVIMENTO` ➔ `QUEDA_LIVRE` ➔ `AGUARDANDO_IMPACTO` ➔ `POS_IMPACTO`.
- Acionamento do buzzer contínuo em frequência fixa (2000 Hz) na confirmação de queda.
- Assinatura do tópico MQTT `memora/iot/demonstracao-01/comando` para escuta do comando `CESSAR_ALARME`, executando `noTone(BUZZER_PIN)` e retornando o estado para `INERTE`.

---

## 🧪 Testes Automatizados e Portões de Qualidade

1. **`flutter analyze`**:
   - **0 avisos, 0 erros, 0 infos** (100% documentado com Dartdoc conforme `public_member_api_docs`).
2. **`specs/005-monitoramento-iot-quedas/validar_suite_cuidado.py`**:
   - Suíte completa em Python que executa e valida 7 passos críticos (7/7 aprovados):
     - Validação de contraste WCAG 2.2 AA e AAA (66 pares aprovados em `validar_paleta.py`).
     - Validação de tokens semânticos (0 literais visuais em `validar_tokens.py`).
     - Validação estrutural do firmware ESP32 Wokwi.
     - Validação dos esquemas JSON de payload MQTT.
     - Validação das regras de DDD e normalização `+55` de telefones.
     - Validação da cláusula de segurança antigolpe.
     - Verificação da integridade de todos os arquivos.
3. **Testes Unitários, de Widget e de Acessibilidade**:
   - `app/test/features/cuidado/domain/entidades_test.dart`
   - `app/test/features/cuidado/data/provedores_test.dart` (inclui teste real de conexão ao broker `broker.hivemq.com`)
   - `app/test/features/cuidado/presentation/tela_dispositivo_cuidado_test.dart`
   - `app/test/features/cuidado/presentation/tela_verificacao_queda_test.dart`
   - `app/test/features/casca/profundidade_test.dart` e `app/test/acessibilidade/hub_cabe_sem_rolar_test.dart`
   - Matriz de testes cobrindo 4 aparelhos (320x568 até 390x844), 3 escalas de texto (100%, 150%, 200%) e 3 temas (claro, escuro, alto contraste) com zero estouro de layout.

---

## 📋 Checklist de Validação

- [x] Sincronizado com a `master` mais recente (Features 001, 002, 003 e 004).
- [x] Conformidade total com a Constituição Memora (WCAG 2.2 AA, piso 16 sp, tokens semânticos).
- [x] Zero valores visuais literais fora de `design_system/tokens/` (`validar_tokens.py` zerado).
- [x] `flutter analyze` com zero pendências.
- [x] Alarme com 45 segundos de tolerância antes da escalada de emergência.
- [x] Silenciamento sonoro bidirecional imediato via MQTT ao responder "Estou bem".
- [x] Suporte ao simulador Wokwi via broker público HiveMQ (MQTT 3.1.1 + IPv4).
- [x] Suporte a números nacionais e com prefixo `+55`.
