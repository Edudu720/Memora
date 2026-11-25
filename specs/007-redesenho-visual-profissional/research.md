# Pesquisa Técnica e Decisões de Arquitetura — Feature 007

**Feature**: Redesenho Visual e Padronização Profissional (`007-redesenho-visual-profissional`)  
**Data**: 2026-11-13 (revisada pós-Clarify)

---

## Decisão 1: Hierarquia de Superfícies 2.0 (Canvas Tonal + Cartões Elevados sem Wireframe)

- **Decisão**: Atualizar `MemoraCores` com canvas frio suave (`fundo: #F4F6FA` no claro, `#0F141E` no escuro, `#000000` no alto contraste), `superficie` (`#FFFFFF` / `#182030` / `#0A0A0A`), `superficieSutil`, `superficieBarra` (`#FFFFFF` no claro em vez de `#D8D8D8`), `bordaSutil` (`#E2E8F0` / `#2B364B` decorativa no Claro/Escuro), preservando `borda` (`>= 3.0:1`) para campos de entrada, estados de foco, opções selecionáveis e modo Alto Contraste; e sombras em duas camadas em `MemoraElevacao` (`listaSombrasCartao`, `listaSombrasBarra`).
- **Racional**: Ao cruzar `design-2.jpg` (`Leafora`), `design-1.jpg`, `7fe4db...webp` e `fkhvix...jfif`, a aparência limpa vem da separação por contraste tonal entre canvas (`#F4F6FA`) e cartões (`#FFFFFF`) com cantos arredondados (`20–24 dp`) e sombra difusa — eliminando bordas `#6B6B6B` em volta de todo bloco passivo.
- **Alternativas consideradas**:
  - *Manter `Border.all(color: cores.borda)` em cartões informativos*: rejeitada (causa-raiz do aspecto wireframe).
  - *Remover bordas em inputs e Alto Contraste*: rejeitada (viola WCAG 2.2 SC 1.4.11 e AAA do Alto Contraste).

---

## Decisão 2: Gradientes com Tokens e Contraste Auditável para Heróis (`Início` e `Cuidado`)

- **Decisão**: Adicionar pares `gradienteHeroiInicio`/`Fim` + `sobreGradienteHeroi` e `gradienteSaudeInicio`/`Fim` + `sobreGradienteSaude` em `MemoraCores` e `PaletaDeDestaque` (6 paletas × Claro/Escuro, além de fallback sólido `>= 7.0:1` em Alto Contraste), auditados em ambas as extremidades por `validar_paleta.py` e `contraste_test.dart`.
- **Racional**: Garante que os banners heróis inspirados em `fkhvix`, `design-1` e `7fe4db...webp` tenham contraste matemático `>= 4.5:1` com o texto sobreposto em qualquer paleta escolhida pelo usuário.
- **Alternativas consideradas**:
  - *Gradientes ad-hoc com opacidade nas telas*: rejeitada (`validar_tokens.py` proíbe literais fora de `tokens/`).

---

## Decisão 3: Unificação Retrocompatível do Mascote (`ExpressaoDaMemora`)

- **Decisão**: Preservar intactos os 4 membros existentes de `ExpressaoDaMemora` e seus PNGs já vinculados em `app/lib/design_system/componentes/ilustracao/memora_personagem.dart` (`neutra -> memora_perfil_robo.png`, `falando -> memora_ajuda_robo.png`, `comemorando -> memora_conclusao_robo.png`, `preocupada -> memora_alerta_robo.png`) e **adicionar apenas os 2 membros novos** correspondentes às artes já presentes em `app/assets/ilustracoes/`: `dica -> memora_dica_robo.png` e `mini -> memora_mini_robo.png`, preservando o fundo claro em medalhões nos temas escuros (`memora_personagem.dart:L48`).
- **Racional**: Os 4 valores atuais já são consumidos por múltiplas features (`raizes_provisorias.dart`, `cabecalho_de_tela.dart`, `balao_de_fala.dart`) e testes (`ilustracao_e_destaque_test.dart`). Mantê-los evita quebras retroativas enquanto completa o conjunto das 6 poses oficiais de `Gemini_Generated_Image_ou3ujaou3ujaou3u.jfif`.
- **Alternativas consideradas**:
  - *Renomear `neutra`/`falando`/`comemorando`/`preocupada` para `boasVindas`/`ajuda`/`conclusao`/`alerta`*: rejeitada (quebraria chamadores e testes existentes sem ganho).

---

## Decisão 4: Separação Estrita entre Informação e Ação (`002/FR-012` / Q2) + Barra em 3 Abas (Q1)

- **Decisão**:
  - **`NavegacaoInferior` & `CascaInterna`**: manter exatamente os **3 destinos fixos** de `DestinoDaCasca` (`Ajustes`, `Início`, `Meu perfil`), mantendo `Conversa`, `Aplicativos`, `Cuidado` e `Ajuda` acessíveis a partir do `Início`.
  - **`Cartao` e `PainelHeroi` (leitura) vs `CartaoHeroi`, `TileAcaoRapida` e `LinhaDeLista` (ação)**:
    - `Cartao` permanece **estritamente sem `aoTocar`** (informação nunca vira botão).
    - `PainelHeroi` é o banner em gradiente **somente leitura** (usado no topo de `TelaDispositivoCuidado`), sem callback de toque.
    - `CartaoHeroi` (usado no `Início`/`Hub`) e `TileAcaoRapida` exigem `VoidCallback aoTocar` e pista visual explícita de ação (pílula/rótulo `"Começar"` / `"Abrir"` ou seta + semântica `isButton: true`).
    - `LinhaDeLista` com `aoTocar != null` exibe seta direcional e semântica de botão; sem `aoTocar` é estritamente informativa.
- **Racional**: Respeita as decisões de esclarecimento Q1 e Q2, mantém `3` botões largos na barra inferior mesmo a `200%` em telas de `320 px`, e zera qualquer risco de idosos tocarem painéis informativos como `MedidorBpm`.
- **Alternativas consideradas**:
  - *Adicionar `aoTocar` em `Cartao` ou expandir barra inferior para 5 itens*: rejeitadas por violar `002/FR-012` / comprometer alvos a `200%` e contrariar decisões Q1/Q2.

---

## Decisão 5: Fluxo da Conversa — Consentimento (Q3) e Ditado por Voz Seguro (Q4 / FR-013)

- **Decisão**:
  - **Consentimento obrigatório (`Emenda 1 ao Princípio I`)**: `_ExplicacaoDoAceite` (`chaveAceite`, `chaveAceitar`, `chaveRecusarAceite`) permanece exibida **antes** da grade `2x2` de sugestões e da barra de mensagem enquanto `controlador.precisaDoAceite == true`, recebendo acabamento visual limpo da `CaixaDeEtapa` evoluída.
  - **Ditado por voz completo (`FR-013`)**:
    - Dependência escolhida: `speech_to_text: ^7.3.0` (compatível com Dart `^3.11.4` e `compileSdk`/`minSdk` do projeto em `app/android/app/build.gradle.kts`).
    - Configuração Android (`app/android/app/src/main/AndroidManifest.xml`): declarar `<uses-permission android:name="android.permission.RECORD_AUDIO"/>` e `<queries><intent><action android:name="android.speech.RecognitionService"/></intent></queries>` (obrigatório para visibilidade no Android 11+).
    - Arquitetura Clean (Princípio V): definir abstração `LeitorDeVoz` (em `app/lib/features/assistente/domain/leitor_de_voz.dart`) com estados (`EstadoDitado`: `ocioso`, `aguardandoPermissao`, `ouvindo`, `indisponivel`, `erro`) e implementação concreta `LeitorDeVozSpeechToText` em `app/lib/features/assistente/data/leitor_de_voz_nativo.dart`, permitindo injeção determinística com `FakeLeitorDeVoz` em testes de widget/acessibilidade sem microfone real.
    - Guardrails de UX & Segurança (Princípios II, III e VI):
      1. Botão `"Falar"` / `"Parar"` com ícone + rótulo visível (`>= 48×48 dp`) ao lado ou acima conforme espaço da barra a `200%`.
      2. No primeiro toque sem autorização prévia registrada, abrir `DialogoMemora` explicando em linguagem simples por que o microfone é pedido (Princípio II) antes de invocar o diálogo do sistema.
      3. A fala reconhecida (preferencialmente `pt_BR`) **preenche apenas o rascunho de texto** (`c.escrever(...)` / `_campo`), permitindo revisão antes do toque manual em `"Perguntar"` — nunca envia automaticamente.
      4. Permissão negada ou dispositivo sem suporte exibe aviso claro sem erro técnico e preserva a digitação livre por teclado; nenhum áudio é gravado em disco nem logado.
- **Alternativas consideradas**:
  - *Platform Channel nativo manual em Kotlin*: rejeitada por maior custo de manutenção e casos de borda do Android SpeechRecognizer já resolvidos por `speech_to_text`.
  - *Enviar mensagem automaticamente ao parar de falar*: rejeitada por violar autonomia sênior e Princípio VI ante erros de reconhecimento de fala.

---

## Decisão 6: Responsividade até 200%, Chaves de Teste e Verificação APK (Q5)

- **Decisão**: Grids `2x2` (`TileAcaoRapida` e sugestões de conversa) usam `LayoutBuilder` + `MediaQuery.textScalerOf(context)` para exibir `2 colunas` em `>= 340 px` a escalas normais e colapsar para `1 coluna` em telas estreitas (`320 px`) ou ampliações `>= 1.5x`; `TelaHub` permanece calibrada para passar em `hub_cabe_sem_rolar_test.dart`; e `SC-006` valida visualmente os 3 temas pelo `album_de_telas_test.dart` + `flutter build apk --release` conforme Q5.
- **Alternativas consideradas**:
  - *Grid fixa de 2 colunas*: rejeitada por causar `RenderFlex overflow` a `200%`.
