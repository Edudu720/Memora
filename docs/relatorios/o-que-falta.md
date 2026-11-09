# O que falta para o Memora ficar pronto

**Atualizado em**: 2026-10-13, depois da revisão das PRs #44 a #48 e do
`/speckit-analyze` e do `/speckit-clarify` da 004
**Prazo de entrega**: novembro de 2026

Este documento junta, num lugar só, tudo o que ainda separa o repositório de um
Memora entregue. Cada item aponta a tarefa (`T…`) da feature correspondente,
para ninguém precisar caçar nos cinco `tasks.md`.

> ⚠️ **Há 15 PRs abertas (#44 a #58), e nenhuma tem revisão humana.** Elas
> passaram por revisores independentes (agentes), com os achados corrigidos em
> PRs próprias, mas **não** por uma pessoa da equipe. Revisar e mesclar **na
> ordem** é a primeira tarefa — a ordem está na seção 2, e mesclar fora dela
> quebra a compilação da `master`.

> 🚀 **2026-10-21 — o APK para outras pessoas vai usar o Render, e isso é a
> próxima sessão de quem pegar a implantação** (decisão do Henrique). Até lá, o
> app só fala com a IA no celular **por cabo** (`adb reverse`, ver o `CLAUDE.md`).
> O que separa o repositório de um APK instalável com backend e IA funcionando:
>
> 1. **T113 da 003 — `INTERNET` no manifesto principal**
>    (`app/android/app/src/main/AndroidManifest.xml`). Sem ela o APK de
>    **release** não fala com servidor nenhum; o de depuração só funciona porque
>    o Flutter põe a permissão nesse modo.
> 2. **Chave de assinatura própria do Memora.** Hoje o release é assinado com a
>    chave de **depuração da máquina de quem gera** (`build.gradle.kts`,
>    `signingConfigs.getByName("debug")`): APK de outra máquina não instala por
>    cima ("signatures do not match") e a pessoa perde o que está no aparelho.
>    A chave **não vai para o git**.
> 3. **Backend no Render**, com `https://` — o release recusa `http://` fora de
>    depuração (`Ambiente.exigirTlsForaDeDepuracao`). Não existe `Dockerfile`
>    ainda. Banco: Postgres gerenciado (do Render ou Neon). No plano gratuito o
>    serviço **dorme** sem uso e a primeira resposta leva 30-60 s, mais que os
>    30 s que o app espera pela primeira palavra (`esperaMaxima`).
> 4. **Variáveis fixas no Render**: `memora.token.segredo`,
>    `MEMORA_CHAVE_ORIGEM` (≥ 32 bytes), `MEMORA_ASSISTENTE_PROVEDOR=gemini`,
>    `GEMINI_API_KEY` e a URL do banco. Sem as duas primeiras fixas, cada
>    reinício derruba a sessão de todo mundo.
> 5. **Não suba com o perfil `producao`**: ele não tem `EnviadorDeCodigo`
>    (T065a) e a aplicação não sobe, de propósito. Sem ele, o código de
>    verificação e o de "Esqueci minha senha" vão **para o log** — avise quem
>    testar que recuperar a senha não funciona.
> 6. **Modelo do Gemini**: o padrão é `gemini-3.8-flash` (ADR-002), e em
>    2026-10-21 ele deu **503 por sobrecarga** e levou 25 s para dizer "oi". No
>    celular o teste correu com `MEMORA_ASSISTENTE_GEMINI_MODELO=gemini-3.6-flash`
>    (2,9 s). Trocar o padrão é decisão da equipe e emenda a ADR-002.
> 7. **Gerar o release** com
>    `--dart-define=MEMORA_URL_BASE=https://<servico>.onrender.com/v1 --dart-define=MEMORA_SERVIDOR_REAL=true`.

---

## 1. O que depende de decisão ou de gente — e não de código

Estes itens não se resolvem programando. Se ficarem para o fim, o Memora chega
a novembro com centenas de testes verdes e sem fazer o que promete.

| O quê | Quem | Bloqueia | Onde |
|---|---|---|---|
| **Revisar e mesclar as PRs #44 a #58**, na ordem | Henrique e Du3101 | Tudo o que vem depois; a T116 precisa delas no aparelho | Seção 2 deste documento |
| **Ratificar a spec da 004**, aprovada pelo Eduardo em 2026-10-13 | Henrique e Du3101, aprovando a #58 | Formalmente, o Princípio IV | `Status` da `spec.md` da 004 |
| **T116: segunda rodada da revisão de design, no celular** | Henrique | **O merge de toda tela nova** (decisão de 2026-10-13: portão do merge, não do código) | T116 da 004 |
| **Teste com 5 pessoas de 65+** | Equipe | Portão de saída das features 001, 002, 003 e 004 | T085 (001), T050/T051 (002), T071 (003), T105 (004) |
| ~~**Mesclar a `feature/003-fase11-convergencia`**~~ | — | ✅ **Na `master` em 2026-10-21**, junto com a fase 12, direto e sem PR (pedido do Henrique): o aviso e o consentimento da FR-051 estão no app, então a T071 pode usar a chave gratuita | T100-T113 da 003 |
| **Implantar no Render e gerar o APK de release** | Próxima sessão (decisão do Henrique, 2026-10-21) | Mandar o APK a qualquer pessoa com a IA funcionando | Lista de 7 passos no topo deste documento |
| **Provedor de envio de e-mail/SMS** | Equipe | Código de verificação e de recuperação chegarem a alguém; o perfil `producao` não sobe sem ele | T065a da 001 |
| **Registrar o app no Google e no Facebook** | Equipe | Login social; aprovação do Facebook não é rápida | Fase 8 da 001 (T079-T083) |
| **Verba para um provedor de IA que não treine com a conversa** | Equipe | Cumprir a FR-051 original; hoje é risco aceito, sem data (ADR-002) | ADR-002; FR-051 da 003 |
| **`MEMORA_CHAVE_ORIGEM` em produção** (≥ 32 bytes) | Quem implantar | Implantação | Seção 10 do `CLAUDE.md` |
| **Endereço oficial de download** | Equipe | O "Compartilhar" da Ajuda existir (hoje fica oculto) | R12 e T089 da 004 |
| **Capturas de tela dos guias** | Henrique | Os passo a passo da 004; sem elas o passo mostra "captura pendente" (FR-028a) | T070-T082 da 004, regras em `contracts/guias.md` |
| ~~**Corrigir a segurança da 005** (MQTT público sem TLS, `CESSAR_ALARME` aberto, tráfego sem cifra liberado no app inteiro)~~ | Du3101 | ✅ **Concluído em 2026-11-09**: `usesCleartextTraffic` removido do manifesto, `RepositorioContatoEmergenciaLocal` integrado à `LimpezaDeSessao` (`DadoLocalDaPessoa`), suporte a TLS (`8883`) e credenciais no MQTT e acionamento de socorro via WhatsApp com mensagem pré-pronta | Issue **#43** |

### Decisões da 004 — o que foi resolvido e o que ainda falta

| Decisão | Situação | Onde |
|---|---|---|
| Classificação da **data de nascimento** | ✅ **Confidencial, sem cifra**; fora da tela de informar, só a idade aparece (2026-10-13) | FR-042c, Threat Model |
| **Aprovação da spec** | ✅ Aprovada pelo Eduardo; ratificação na #58 (2026-10-13) | `Status` |
| Confirmação do **"Sair e esquecer este aparelho"** | ✅ Irreversível, em duas etapas (2026-10-13) | FR-041 |
| **Paleta** no tema de alto contraste | ✅ Não se aplica (2026-10-13) | FR-039 |
| A **T116** é portão? | ✅ Do merge, não do código; as PRs de tela abertas até 2026-10-13 ficam de fora (2026-10-13) | Assumptions, T116 |
| Qual "**Carteira Digital**" | ✅ O documento do gov.br (T080) | T124 |
| "**Ajustes**" no lugar de "Configurações" na barra | Implementado, **a confirmar** (B3 do analyze) | FR-015 |
| O aviso da conversa **volta a abrir** depois de apagar a conversa? | O código da #55 reabre; **falta registrar na spec** (B1) | FR-022 |
| "Sem vazio embaixo" (FR-009), a tela de volta com a Memora **ou** uma pessoa idosa (FR-009a), números de "toque grande" (FR-021) | Abertas (B2, B4, B5 do analyze) | — |
| **Capturas** de outros aplicativos nos guias (objeção acadêmica?) | Aberta; plano B são esquemas desenhados | R6 |

---

## 2. Por feature

### Fila de PRs e ordem de merge

**#49 → #44 → #50 → #45 → #51 → #46 → #52 → #55 e #56 → #47 → #53 → #48 →
#54**, e depois a **#58** (por último: o `tasks.md` dela conflita com a pilha;
a resolução é ficar com a marca da pilha **e** com o texto da #58). A **#57**
(esta passagem) é independente. Depois de cada merge, `gh pr edit N --base
master` na de cima.

A branch `integracao/revisao-44-a-48` tem da #44 à #54 mescladas nessa ordem,
com **1600 testes**, os validadores e o build do APK passando, e as resoluções
dos conflitos do caminho.

| # | O quê |
|---|---|
| #49 | O Android deixa de copiar os dados do aparelho para o backup do Google (D3 da 003, FR-042c) |
| #44 / #50 | T123, data de nascimento / correções da revisão |
| #45 / #51 | Fase 4, apresentação / correções (o "voltar" fechava o app) |
| #46 / #52 | Fase 9, Ajustes / correções (preferência corrompida impedia o app de abrir) |
| #55 | Fase 5, conversa com balões e o aviso que encolhe |
| #56 | Fase 8, Ajuda e a quinta porta |
| #47 / #53 | Fase 6, fundação dos guias / correções (origem do catálogo) |
| #48 / #54 | Relatório do pentest / correções (afirmava mais do que provou) |
| #57 | Passagem de contexto |
| #58 | Correções do analyze e o clarify da 004 |

### 001 — Autenticação acessível — 79 de 92 tarefas

- **Fase 8, login social** (T079-T083): bloqueio externo, ver acima.
- **T065a**: envio real do código. **T065b**: o que fazer com conta assistida
  abandonada, que trava o e-mail para sempre.
- **T027a**: o contrato documentar o `500`, o `404` e o `405` que o servidor já
  devolve (decisão de spec).
- **Fase 9, validação** (T084-T088), incluindo as 5 pessoas.

### 002 — Design System — 50 de 53 tarefas

- **T050 e T051**: os cenários V7 e V8, com as 5 pessoas.
- **T053**: as revisões obrigatórias da constituição.
- ⚠️ Dívida notada na revisão da #38: os botões da 002 (`BotaoBase`) mostram
  foco e toque **só pela cor** do `InkWell`. Os componentes da 004 já usam a
  `SuperficieTocavel`, com um segundo sinal; os da 002 ainda não.

### 003 — Hub e a assistente — 71 de 99 tarefas na `master`

- ✅ **Fase 8, o provedor**: **Gemini, nível gratuito** (T061-T065, ADR-002).
  Falta a **T068** (custo e latência) e provar quebrando o portão "a chave
  nunca vai na URL" (`chaveNoCabecalho`).
- ⚠️ A branch **`feature/003-fase11-convergencia`** (Henrique) tem **79 de
  106**: a clarificação de 2026-10-03 (FR-051 como transparência, janela
  deslizante de 20 turnos, voz para a 005, erros no stream) e as T101-T104 e
  T106. **Não tem PR.**
- **Fase 9, validação** (T071-T074), com as 5 pessoas. A T071 **pode** usar a
  chave gratuita, mas só depois que a `003-fase11` entrar (seção 1).
- **Fase 10, convergência** (T079-T099): quase toda sem dependência externa.
- **T021 e T036**: gerar o cliente Dart da 003 — adiadas até o contrato da 003
  ser fundido com o da 001.
- A spec continua `Draft`, como a da 004 estava; o analyze da 004 apontou o
  mesmo para a 003.

### 004 — Redesenho das telas — 84 de 131 tarefas, contando as PRs abertas

| Fase | O quê | Situação |
|---|---|---|
| 1, 2 | Fundação | ✅ na `master` |
| 3, 3b | **US2**: Início e Hub; o acabamento da T044 | ✅ na `master`. Falta a **T116** (revisão no celular, portão do merge) |
| 4 | **US1**: apresentação | ✅ #45/#51. Faltam a **T117** (boas-vindas na altura toda e a tela de volta, que reativa o teste pulado), a **T127** (teste das duas boas-vindas), a T047 e a T052 |
| 5 | **US3**: conversa com balões e o aviso que encolhe | ✅ #55 |
| 6 | **US4**: guias e "Meus aplicativos" em **lista** | Fundação na #47/#53. Faltam o passo a passo (T065-T067), a lista (T069, T119), os guias (T070-T075, dependem das capturas) e a captura pendente (T120) |
| 7 | **US5**: serviços sociais | Aberta (T076-T084, T124) |
| 8 | **US6**: Ajuda | ✅ #56 |
| 9 | **US7**: Ajustes | ✅ #46/#52. Falta a **T122** (paletas, pela metade) e a **T126** (a Conta sai quando a sessão expira) |
| 10 | **US8**: Perfil | Aberta (T096, T097 — apaga a `TelaPerfil` antiga) |
| 11 | **US9**: Planos fora | Aberta (T098) |
| 12 | Polimento | Aberta: T099 (telas fora do wireframe, agora com a recuperação), T100-T108, **T125** (`CaixaDeEtapa` nas telas que faltam), T109 e T110 (atividade pelo leitor de tela, pelo teclado e dentro de diálogo) |

**Se o prazo apertar**, o corte menos danoso é reduzir guias, nunca telas: um
item sem guia abre a conversa. O piso são os guias de TikTok, Gov.br, WhatsApp,
Instagram, YouTube e Meu INSS.

### 005 — Monitoramento IoT de quedas (Du3101) — 38 de 38 tarefas concluídas

✅ **Concluída em 2026-11-09** (incluindo migração para hardware **ESP32 DevKit físico** com MPU6050/9250/9255 autocalibrado e Pulse Sensor óptico no `GPIO 34`, acionamento de emergência via **WhatsApp com mensagem pré-pronta** e fechamento integral da **Issue #43**: remoção de `usesCleartextTraffic="true"` do `AndroidManifest.xml`, limpeza do contato de emergência na saída da sessão via `DadoLocalDaPessoa` e suporte a TLS na porta `8883` e autenticação MQTT por `--dart-define`). `flutter analyze` com 0 avisos, `validar_suite_cuidado.py` (`8/8`) e suíte de testes de `cuidado` 100% verdes.

---

## 3. Dívidas técnicas que não têm tarefa ainda

- **`cartao_de_porta_test.dart:31`** cria `MediaQueryData` do zero, e com isso
  mede o `CartaoDePorta` numa tela de altura zero (respiro sempre no mínimo).
  É otimista, mas não grave: o Hub de verdade é medido pela matriz.
- **A contagem "15 reprovaram (4 + 7 + 4)"** do relatório de pentest não bate
  com a contagem por classe. Conferir quebrando de novo.
- **A frase de Privacidade "o Memora não guarda cópia"** (#52) é verdade sobre
  o servidor, mas o Gemini gratuito pode guardar a conversa (FR-051). Rever
  junto com a decisão da 003.
- **As tags acentuadas do `openapi.yaml`** geram nomes mutilados no cliente
  (`sesso_api.dart`). Decisão de spec.
- **O springdoc** continua fora do `pom.xml`.
- **Versões do Flutter** diferem entre as duas máquinas (3.41 e 3.44), e o CI
  usa `stable` sem pino. Decidir se pina.
- **A soma do Surefire mente** de dois jeitos (relatório órfão sem `clean`, e
  `@Nested` com nomes repetidos no atributo `tests=`). Contar `<testcase`.

---

## 4. Números de hoje

| | Testes | Medido em |
|---|---|---|
| Aplicativo | **1600** + 1 pulado | `flutter test`, 2026-10-13, na branch `integracao/revisao-44-a-48` (da #44 à #54 mescladas) |
| Aplicativo | **1681** + 1 pulado | `flutter test`, 2026-10-13, na #56 (sobre a #52) |
| Backend | **413** | `mvnw clean test`, 2026-10-03, depois do Gemini (o backend não mudou desde então) |

O teste pulado é o da T047, que a T117 reativa.

Verificação completa: `flutter analyze`, `flutter test`, `validar_paleta.py`,
`validar_tokens.py` e os dois `--autoteste` — ver a seção 6 do `CLAUDE.md`.
