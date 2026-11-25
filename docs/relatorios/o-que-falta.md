# O que falta para o Memora ficar pronto

**Atualizado em**: 2026-11-13, após o fechamento técnico da Feature 006 (`BotaoBase` com `SuperficieTocavel`, expurgo de contas assistidas abandonadas `T065b`, envio real de e-mail via SMTP em produção `T065a`/`T068` e higiene de testes/documentação)
**Prazo de entrega**: novembro de 2026

Este documento junta, num lugar só, tudo o que ainda separa o repositório de um
Memora entregue. Cada item aponta a tarefa (`T…`) da feature correspondente,
para ninguém precisar caçar nos seis `tasks.md`.

> ✅ **Histórico de PRs #44 a #58 e Fase 11 da 003**: toda a fila de integração
> das Features 003, 004 e 005 (`#44` a `#58`, `003-fase11-convergencia` e Issue
> `#43`) já foi mesclada na linha principal (`master`/`develop`). No momento, as
> PRs abertas de conteúdo dos guias são a **#68** (guias de CLT, CNH,
> Poupatempo, Fotos e YouTube — CI 100% verde) e a **#66** (guias do Facebook —
> com revisão solicitando ajustes pontuais de PII e gitignore).

> 🚀 **Checklist de implantação do APK + Backend no Render**:
>
> 1. ✅ **T113 da 003 — `INTERNET` no manifesto principal**
>    (`app/android/app/src/main/AndroidManifest.xml`): permissão já declarada no
>    manifesto principal e `usesCleartextTraffic` removido (Issue #43).
> 2. ⚠️ **Chave de assinatura própria do Memora (pendente operacional):** o
>    release ainda usa `signingConfigs.getByName("debug")` em
>    `app/android/app/build.gradle.kts`. Para atualizar o APK sem desinstalar em
>    aparelhos diferentes, gerar um keystore próprio fora do git antes da
>    distribuição final.
> 3. ✅ **Docker e manifesto do Render prontos:** `backend/Dockerfile`,
>    `render.yaml` e o passo a passo completo em
>    `docs/deploy/render.md` já estão configurados no repositório.
> 4. ⚠️ **Variáveis fixas no painel do Render (ao publicar):**
>    `MEMORA_TOKEN_SEGREDO`, `MEMORA_CHAVE_ORIGEM` (≥ 32 bytes),
>    `MEMORA_ASSISTENTE_PROVEDOR=gemini`, `GEMINI_API_KEY` e a conexão do
>    PostgreSQL gerenciado.
> 5. ✅ **Adaptadores de produção de e-mail (`T065a` e `T068` — Feature 006):**
>    `EnviadorDeCodigoPorEmail` e `NotificadorDeContaPorEmail` agora existem sob
>    `@Profile("producao")` via SMTP (`SPRING_MAIL_HOST`, `SPRING_MAIL_PORT`,
>    `SPRING_MAIL_USERNAME`, `SPRING_MAIL_PASSWORD`, `MEMORA_EMAIL_REMETENTE`),
>    com falha rápida (*fail-fast*) na subida se faltar host ou remetente. No
>    plano gratuito do Render sem servidor SMTP configurado, basta manter o
>    perfil padrão (`!producao`), que preserva `EnviadorDeCodigoEmLog` e
>    `NotificadorDeContaEmLog`.
> 6. **Modelo do Gemini**: o padrão é `gemini-3.8-flash` (ADR-002), configurável
>    por `MEMORA_ASSISTENTE_GEMINI_MODELO`.
> 7. **Gerar o release** com
>    `--dart-define=MEMORA_URL_BASE=https://<servico>.onrender.com/v1 --dart-define=MEMORA_SERVIDOR_REAL=true`.

---

## 1. O que depende de decisão ou de gente — e não de código

Estes itens não se resolvem programando. Se ficarem para o fim, o Memora chega
à entrega com milhares de testes verdes e pendências operacionais/humanas.

| O quê | Quem | Bloqueia | Onde |
|---|---|---|---|
| ~~**Revisar e mesclar as PRs #44 a #58**, na ordem~~ | Henrique e Du3101 | ✅ **Concluído**: toda a pilha #44–#58 já está integrada em `master`/`develop` | Seção 2 deste documento |
| ~~**Ratificar a spec da 004**, aprovada pelo Eduardo em 2026-10-13~~ | Henrique e Du3101 | ✅ **Concluído** com a integração da #58 | `Status` da `spec.md` da 004 |
| **Revisão humana do álbum de design (`T104` / `T116`)** | Eduardo, Henrique e Du3101 | Portão humano de validação visual das 30 telas × 3 temas | `T104` e `T116` da 004 |
| **Teste presencial com 5 pessoas de 65+** | Equipe | Portão de saída das features 001, 002, 003 e 004 | T085 (001), T050/T051 (002), T071 (003), T105 (004) |
| ~~**Mesclar a `feature/003-fase11-convergencia`**~~ | — | ✅ **Na `master` em 2026-10-21**, junto com a fase 12: o aviso e o consentimento da FR-051 estão no app | T100-T113 da 003 |
| **Publicar serviço no Render e gerar o APK de release** | Equipe | Disponibilizar o APK em nuvem sem depender de `adb reverse` | `docs/deploy/render.md` |
| ~~**Implementar adaptador de envio de e-mail em produção (`T065a`/`T068`)**~~ | Equipe | ✅ **Código concluído na Feature 006** (`EnviadorDeCodigoPorEmail` e `NotificadorDeContaPorEmail` via SMTP em `@Profile("producao")`). Resta apenas contratar/configurar credenciais SMTP quando ativar o perfil `producao` (e gateway SMS futuro para canal `TELEFONE`) | T065a e T068 da 001; Feature 006 |
| **Registrar o app no Google e no Facebook** | Equipe | Login social; aprovação externa | Fase 8 da 001 (T079-T083) |
| **Verba para um provedor de IA que não treine com a conversa** | Equipe | Cumprir a FR-051 original; hoje é risco aceito com transparência e consentimento no app (ADR-002) | ADR-002; FR-051 da 003 |
| **`MEMORA_CHAVE_ORIGEM` em produção** (≥ 32 bytes) | Quem implantar | Implantação no Render | `docs/deploy/render.md` |
| **Endereço oficial de download** | Equipe | O botão "Compartilhar" da Ajuda exibir link real (hoje fica oculto enquanto vazio) | R12 e T089 da 004 |
| **Capturas de tela restantes dos guias** | Equipe | Fechar PRs #66 (Facebook) e #68 (CLT, CNH, Poupatempo, Fotos, YouTube) | T070-T082 da 004, `contracts/guias.md` |
| ~~**Corrigir a segurança da 005** (MQTT público sem TLS, `CESSAR_ALARME` aberto, tráfego sem cifra liberado no app inteiro)~~ | Du3101 | ✅ **Concluído em 2026-11-09**: `usesCleartextTraffic` removido do manifesto, `RepositorioContatoEmergenciaLocal` integrado à `LimpezaDeSessao` (`DadoLocalDaPessoa`), suporte a TLS (`8883`) e credenciais no MQTT e acionamento de socorro via WhatsApp com mensagem pré-pronta | Issue **#43** |

### Decisões da 004 — situação consolidada

| Decisão | Situação | Onde |
|---|---|---|
| Classificação da **data de nascimento** | ✅ **Confidencial, sem cifra**; fora da tela de informar, só a idade aparece (2026-10-13) | FR-042c, Threat Model |
| **Aprovação da spec** | ✅ Aprovada e ratificada na #58 | `Status` |
| Confirmação do **"Sair e esquecer este aparelho"** | ✅ Irreversível, em duas etapas | FR-041 |
| **Paleta** no tema de alto contraste | ✅ Não se aplica | FR-039 |
| A **T116** é portão? | ✅ Portão humano de revisão de design | Assumptions, T116 |
| Qual "**Carteira Digital**" | ✅ Carteira de Trabalho Digital / CNH Digital (PR #68) | T080, T124 |
| Divergências entre spec e código (`B1`–`B5`) | ✅ Documentadas e reconciliadas em `specs/004-redesenho-das-telas/divergencias.md` (`T107`) | `divergencias.md` |

---

## 2. Por feature

### 001 — Autenticação acessível — 81 de 92 tarefas concluídas

- ✅ **T065a e T068 (envio real em produção)**: concluídas na Feature 006 com
  `EnviadorDeCodigoPorEmail` e `NotificadorDeContaPorEmail` (`@Profile("producao")`),
  mantendo os adaptadores em log para `@Profile("!producao")`.
- ✅ **T065b (conta assistida abandonada)**: concluída na Feature 006 com
  `ServicoDeExpurgoDeContaPendente` — contas em `PENDENTE_VERIFICACAO` há mais
  de 24 horas são expurgadas tanto sob demanda no cadastro (após o hash Argon2id
  em tempo constante, preservando a FR-010) quanto por rotina agendada
  (`@Scheduled`).
- **Fase 8, login social** (T079-T083): bloqueio externo (registro OAuth no
  Google e Facebook).
- **T027a**: documentar no `openapi.yaml` os códigos `500`, `404` e `405` já
  devolvidos pelo servidor.
- **Fase 9, validação** (T084-T088), incluindo o teste presencial com 5 pessoas.

### 002 — Design System — 50 de 53 tarefas concluídas

- ✅ **Duplo sinal visual em `BotaoBase` (achado da revisão da #38)**: concluído
  na Feature 006. `BotaoBase` agora reutiliza `SuperficieTocavel`, exibindo anel
  de foco externo (`MemoraDimensoes.bordaSelecao` com `strokeAlignOutside`) e
  escala tátil (`MemoraMovimento.escalaPressionado`) nas 4 variantes (`primario`,
  `secundario`, `terciario`, `perigo`), respeitando `MediaQuery.disableAnimations`.
- **T050 e T051**: cenários V7 e V8 com as 5 pessoas 65+.
- **T053**: revisões humanas obrigatórias da constituição.

### 003 — Hub e a assistente — Fases 1 a 8, 11 e 12 integradas

- ✅ **Fase 8 (Gemini, ADR-002)** e **Fases 11 e 12** (`003-fase11-convergencia`,
  aviso de transparência da FR-051, janela deslizante de 20 turnos e `INTERNET`
  no manifesto) já integradas em `master`/`develop`.
- **T068**: medição de custo e latência em lote.
- **Fase 9, validação** (T071-T074): teste presencial com 5 pessoas 65+.
- **Fase 10, convergência** (T079-T099) e **T021/T036** (unificação do cliente
  OpenAPI com a 001).

### 004 — Redesenho das telas — 135 de 138 tarefas concluídas

| Fase | O quê | Situação |
|---|---|---|
| 1 a 11 | Fundação, licenças (`LICENCAS.md`), Início/Hub, Apresentação, Conversa, Guias, Serviços Sociais, Ajuda, Ajustes, Perfil e Planos fora (`T001`–`T098`, `T111`–`T132`) | ✅ Concluída |
| 12 | Polimento, `CaixaDeEtapa` (`T125a`–`T125e`), álbum completo de 30 telas × 3 temas (`T101`), inventário e divergências (`T102`, `T107`) e verificação completa (`T103`) | ✅ Código, testes, álbum e documentação 100% concluídos. Restam apenas as 3 tarefas humanas/presenciais: `T104` (revisão do álbum pelos 3 integrantes), `T105` (teste com 5 pessoas 65+) e `T106` (revisões humanas de PR) |

### 005 — Monitoramento IoT de quedas (Du3101) — 38 de 38 tarefas concluídas

✅ **Concluída em 2026-11-09** (incluindo migração para hardware **ESP32 DevKit físico** com MPU6050/9250/9255 autocalibrado e Pulse Sensor óptico no `GPIO 34`, acionamento de emergência via **WhatsApp com mensagem pré-pronta** e fechamento integral da **Issue #43**).

### 006 — Polimento de Acessibilidade, Robustez de Conta e Rastreabilidade — 20 de 20 tarefas concluídas

✅ **Concluída em 2026-11-13**:
- **US1 (`BotaoBase` + `SuperficieTocavel`)**: segundo sinal visual de foco e toque nas 4 variantes de botão do Design System.
- **US2 (`T065b`)**: expurgo transacional de contas em `PENDENTE_VERIFICACAO` após 24 horas (sob demanda no cadastro após Argon2id em tempo constante e via rotina agendada `@Scheduled`).
- **US3 (`T065a` e `T068`)**: adaptadores SMTP de produção (`EnviadorDeCodigoPorEmail` e `NotificadorDeContaPorEmail`) com validação *fail-fast*, mensagens sem links na voz da Memora e zero vazamento de código em log.
- **US4**: preservação de dimensões reais da janela de teste via `MediaQuery.of(context).copyWith` em `cartao_de_porta_test.dart` e atualização documental.

---

## 3. Dívidas técnicas remanescentes (baixa prioridade)

- ~~**`cartao_de_porta_test.dart:31`** cria `MediaQueryData` do zero~~ → ✅
  **Corrigido na Feature 006 (`T015`)** usando `Builder` +
  `MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(escala))`.
- **A contagem "15 reprovaram (4 + 7 + 4)"** do relatório de pentest pode ser
  reconciliada por classe em revisão futura de documentação.
- **As tags acentuadas do `openapi.yaml`** geram nomes sem acento no cliente
  gerado (`sesso_api.dart`).
- **O springdoc** continua fora do `pom.xml`.
- ~~**Versões do Flutter no CI sem pino**~~ → ✅ **Pinada em `3.47.7` em `.github/workflows/verificacao.yml` na Feature 006** (evitando quebra de análise estática pelo `stable 3.50.0+`).
- **A soma do Surefire** em classes com `@Nested` exige contar `<testcase` nos
  XMLs para obter o número exato de casos.

---

## 4. Números de hoje

| Camada | Testes | Medido em |
|---|---|---|
| Aplicativo (`app/`) | **2283** (0 pulados) | `flutter test`, 2026-11-13, na Feature 006 (`feature/006-acessibilidade-e-robustez`) |
| Aplicativo (`app/`) | **2279** (0 pulados) | `flutter test`, 2026-11-09, após fechamento técnico da Feature 004 (`feature/004-fechamento-tecnico`) |
| Backend (`backend/`) | **422** (+9 novos na Feature 006) | `mvnw test` (`ServicoDeExpurgoDeContaPendenteTest`, `ExpurgoDeContaPendenteTest`, `EnvioRealDeEmailTest`), 2026-11-13 |
| Backend (`backend/`) | **413** | `mvnw clean test`, 2026-10-03, depois do Gemini |

Verificação completa: `flutter analyze` (0 avisos), `flutter test` (2283/2283),
`validar_paleta.py`, `validar_tokens.py` e os dois `--autoteste` — ver a seção 6
do `CLAUDE.md`.
