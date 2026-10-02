# O que falta para o Memora ficar pronto

**Atualizado em**: 2026-10-01, depois do merge das PRs #36 a #39
**Prazo de entrega**: novembro de 2026

Este documento junta, num lugar só, tudo o que ainda separa o repositório de um
Memora entregue. Cada item aponta a tarefa (`T…`) da feature correspondente,
para ninguém precisar caçar nos quatro `tasks.md`.

> ⚠️ **As PRs #36 a #39 entraram na `master` sem revisão humana**, por decisão
> do Eduardo em 2026-10-01, para destravar a próxima fase. Elas passaram por
> revisão de três agentes independentes (os achados estão corrigidos na #39),
> mas **não** por uma pessoa da equipe. A primeira tarefa da próxima sessão é a
> equipe revisar o que entrou — a #27 já mostrou o que a fila custa quando
> ninguém olha.

---

## 1. O que depende de decisão ou de gente — e não de código

Estes itens não se resolvem programando. Se ficarem para o fim, o Memora chega
a novembro com centenas de testes verdes e sem fazer o que promete.

| O quê | Quem | Bloqueia | Onde |
|---|---|---|---|
| **Escolher o provedor de IA** | Equipe | A assistente pensar de verdade (hoje é simulado) | R2 de `specs/003-hub-e-assistente/research.md`; fase 8 da 003 (T061-T065, T068) |
| **Provedor de envio de e-mail/SMS** | Equipe | Código de verificação e de recuperação chegarem a alguém; o perfil `producao` não sobe sem ele | T065a da 001 |
| **Teste com 5 pessoas de 65+** | Equipe | Portão de saída das features 001, 002, 003 e 004 | T085 (001), T050/T051 (002), T071 (003), T105 (004) |
| **Registrar o app no Google e no Facebook** | Equipe | Login social; aprovação do Facebook não é rápida | Fase 8 da 001 (T079-T083) |
| **Conta e chave do provedor de IA, e quem paga** | Equipe | Implantação | — |
| **`MEMORA_CHAVE_ORIGEM` em produção** (≥ 32 bytes) | Quem implantar | Implantação | Seção 10 do `CLAUDE.md` |
| **Endereço oficial de download** | Equipe | O "Compartilhar" da Ajuda existir (hoje fica oculto) | R12 da 004 |
| **Capturas de tela dos ~16 guias** | Equipe | Os passo a passo da 004 | T070-T082 da 004, regras em `contracts/guias.md` |

### Decisões pendentes da feature 004

| Decisão | Situação | Onde |
|---|---|---|
| "**Ajustes**" no lugar de "Configurações" na barra | Implementado, **a confirmar** | FR-015 da 004; uma linha em `TextosCasca` |
| **Pictograma** no lugar do logotipo oficial nos serviços sociais | Decidido no plano, reabrível | R7 da 004 |
| Qual "**Carteira Digital**" o wireframe quis dizer | Aberta | T080 da 004 |
| **Capturas** de outros aplicativos nos guias (objeção acadêmica?) | Aberta; plano B são esquemas desenhados | R6 da 004 |
| No tema claro, o **medalhão** das portas tem a cor da pílula e some | Para a revisão de design | T044 da 004 |
| O que fazer com a `TelaPerfil` antiga | Resolvida pela T097 da 004 (apagar) | — |

---

## 2. Por feature

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

### 003 — Hub e a assistente — 66 de 99 tarefas

- **Fase 8, o provedor** (T061-T065, T068): espera a escolha.
- **Fase 9, validação** (T071-T074), com as 5 pessoas.
- **Fase 10, convergência** (T079-T099): quase toda sem dependência externa —
  filtro de senha no resumo do pedido, retenção da trilha, apagar mensagens com
  mais de 30 dias, a Memora dizer que é um programa, a recusa explicada de
  pedido financeiro, o dia do limite no fuso de São Paulo, e as T096-T099 da
  revisão de 2026-10-01. A **T098** é decisão de spec.
- **T021 e T036**: gerar o cliente Dart da 003 — adiadas até o contrato da 003
  ser fundido com o da 001.

### 004 — Redesenho das telas — 28 de 114 tarefas

Feito: as fases 1 e 2 (fundação) — fonte, tokens, a Memora, os componentes
novos, a casca com barra inferior, o fim da casca de demonstração.

| Fase | O quê | Situação |
|---|---|---|
| Fundação | **T029-T033**: a `chave` do catálogo (V8 no backend, contrato, simulado, teste de ligação) | **Falta** — ficou fora porque o pedido foi o front-end |
| Fundação | **T011**: ilustrações da Ajuda, de Ajustes e os pictogramas dos serviços sociais | Parcial; nascem nas fases que as usam |
| 3 | **US2**: Início e Hub novos | **Próxima**. Termina na **revisão de design da equipe (T044)** — se reprovar, tudo para |
| 4 | **US1**: apresentação da Memora, boas-vindas, cadastro e login redesenhados | — |
| 5 | **US3**: conversa com balões e aviso compacto | — |
| 6 | **US4**: "Meus aplicativos" em grade, passo a passo, canal Android, guias | O maior bloco, e o conteúdo é o caminho crítico |
| 7 | **US5**: serviços sociais (V10 e guias) | Depende da US4 |
| 8-11 | **US6** Ajuda, **US7** Ajustes, **US8** Perfil, **US9** Planos fora | — |
| 12 | Polimento, álbum de telas, revisão de design, 5 pessoas | — |
| Revisão | **T109**: atividade pelo **leitor de tela** e pelo **teclado** contar como atividade — quem usa TalkBack é avisado de inatividade mesmo ativo. **T110**: toque dentro de diálogo | Pré-existente desde a 001; achado na revisão da #38 |

**Se o prazo apertar**, o corte menos danoso é reduzir guias, nunca telas: um
item sem guia abre a conversa. O piso são os guias de TikTok, Gov.br, WhatsApp,
Instagram, YouTube e Meu INSS.

---

## 3. Dívidas técnicas que não têm tarefa ainda

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
| Aplicativo | **768** | `flutter test`, 2026-10-01, na `master` depois do merge da #39 |
| Backend | **361** | `mvnw clean test`, 2026-10-01 (o backend não mudou desde então) |

Verificação completa: `flutter analyze`, `flutter test`, `validar_paleta.py`,
`validar_tokens.py` e `validar_tokens.py --autoteste` — ver a seção 6 do
`CLAUDE.md`.
