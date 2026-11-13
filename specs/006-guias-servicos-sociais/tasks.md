---

description: "Lista de tarefas ordenada por dependência para Guias Visuais de Serviços Sociais (Censura por Blur + Seções)"
---

# Tasks: Guias Visuais de Serviços Sociais (Gov.br, Serasa e Correios)

**Input**: Design documents from `specs/006-guias-servicos-sociais/`
**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/guias-com-secoes.md](contracts/guias-com-secoes.md), [quickstart.md](quickstart.md)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivos diferentes, sem dependências incompletas)
- **[Story]**: User Story correspondente (`[US1]`, `[US2]`, `[US3]`)
- Todos os caminhos de arquivo são relativos à raiz do repositório

---

## Phase 1: Setup (Infraestrutura Compartilhada)

**Purpose**: Preparação de backup seguro das imagens originais e estrutura inicial de assets.

- [X] T001 Criar diretórios de backup `apps/.originais/Correios/`, `apps/.originais/GOV/` e `apps/.originais/Serasa/` e copiar todos os arquivos originais de `apps/Correios/`, `apps/GOV/` e `apps/Serasa/` antes de qualquer processamento (mantendo proteção pelo `.gitignore` existente)
- [X] T002 [P] Verificar declarações de `assets/guias/gov-br/`, `assets/guias/serasa/`, `assets/guias/correios/` e `assets/ilustracoes/` em `app/pubspec.yaml`

---

## Phase 2: Foundational (Pré-requisitos Bloqueantes)

**Purpose**: Extensão do modelo de domínio `Guia`, `SecaoDoGuia` e `CapturaDoGuia` necessária para todas as User Stories.

**⚠️ CRITICAL**: Nenhuma User Story de UI ou conteúdo de guia seccionado deve iniciar antes da conclusão desta fase.

- [X] T003 Criar entidade imutável `SecaoDoGuia` (`chave`, `titulo`, `subtitulo`, `icone`, `passos` com 3 a 7 itens, `precisaTerEmMaos` opcional) em `app/lib/features/aprendizado/domain/guia.dart`
- [X] T004 Estender `Guia` com `final List<SecaoDoGuia> secoes` (padrão `const <SecaoDoGuia>[]`), getter `temSecoes` (`secoes.isNotEmpty`) e getter `todosOsPassos` (união de `passos` e `secoes`) em `app/lib/features/aprendizado/domain/guia.dart`
- [X] T005 Estender `CapturaDoGuia` com suporte opcional a `extensao` (padrão `'png'`) mantendo `caminho => 'assets/guias/$chave/passo_$numero.$extensao'` e declarar as constantes nomeadas `govBr1..govBr26`, `serasa1..serasa22` e `correios1..correios8` em `app/lib/features/aprendizado/domain/guia.dart`

**Checkpoint**: Modelo de domínio compatível com guias simples (legado) e guias seccionados pronto.

---

## Phase 3: User Story 1 - Escolher uma Seção Específica em Serviços Extensos (Priority: P1) 🎯 MVP

**Goal**: Quando a pessoa idosa toca em um serviço extenso (como Gov.br, Serasa ou Correios), ela escolhe primeiro o assunto desejado em uma tela acessível, indo direto aos 3–7 passos daquela tarefa sem enfrentar 40 telas seguidas.

**Independent Test**: Abrir um `Guia` com `secoes` preenchidas via `FluxoAutenticacao._abrirGuia` → verificar exibição de `TelaSeletorDeSecao` com `CartaoDePorta` (>= 48dp, contraste AA, sem overflow na matriz 4×3×3) → selecionar uma seção → verificar abertura de `TelaPassoAPasso` exibindo somente os passos da seção escolhida.

### Implementation for User Story 1

- [X] T006 [US1] Criar widget `TelaSeletorDeSecao` usando `CabecalhoDeTela`, `BalaoDeFala` da Memora, lista de `CartaoDePorta` (com ícone, título, subtítulo de 1 linha, contagem de passos e selo "Já aprendeu" quando concluída) e atalho final para `TelaConversa` em `app/lib/features/aprendizado/presentation/tela_seletor_de_secao.dart`
- [X] T007 [US1] Atualizar `TelaPassoAPasso` para aceitar título/chave opcional da seção selecionada e persistir progresso por seção (`'${guia.chave}:${secao.chave}'`) em `app/lib/features/aprendizado/presentation/tela_passo_a_passo.dart`
- [X] T008 [US1] Atualizar `_abrirGuia` para verificar `guia.temSecoes` e abrir `TelaSeletorDeSecao` antes de `TelaPassoAPasso` em `app/lib/features/autenticacao/presentation/fluxo_autenticacao.dart`
- [X] T009 [P] [US1] Criar testes unitários, semânticos (TalkBack) e de matriz completa (4 aparelhos × 3 escalas até 200% × 3 temas) para `TelaSeletorDeSecao` em `app/test/features/aprendizado/tela_seletor_de_secao_test.dart`

**Checkpoint**: `TelaSeletorDeSecao` funcional, testada e validada na matriz de acessibilidade sem regressão nos guias curtos.

---

## Phase 4: User Story 2 - Privacidade Garantida por Blur e Conteúdo dos Guias Sociais (Priority: P1)

**Goal**: Censurar via Gaussian Blur (`radius >= 22`) todas as informações pessoais e sigilosas das 77 capturas de Gov.br, Serasa e Correios, otimizar o tamanho total abaixo de 8 MB e popular os guias seccionados com linguagem acessível e avisos `FR-032`.

**Independent Test**: Executar `python scripts/censurar_servicos_sociais.py`, inspecionar visualmente as imagens geradas confirmando zero dados pessoais legíveis (CPF `524.957.408-47`, nomes `EDUARDO JUNCKER TORAS`, `"Eduardo"`, iniciais `ET`, Score `653`, rastreio), confirmar remoção da duplicata `[28]` do Serasa e verificar `app/assets/guias/` <= 8 MB.

### Implementation for User Story 2

- [X] T010 [US2] Criar pipeline `scripts/censurar_servicos_sociais.py` aplicando Gaussian Blur (`r >= 22`) nas regiões mapeadas de Gov.br (`[36]` CPF `524.957.408-47`, `[37]` e `[39]` nome completo + fotos), Serasa (`[4,5,6,9,13,22]` `"Eduardo"` + iniciais `ET`, `[8,9]` Score `653`, exclusão da duplicata `[28]`) e Correios (`[1]` código de rastreio e origem), salvando em `apps/{GOV,Serasa,Correios}/` e exportando em largura 480px otimizada para `app/assets/guias/{gov-br,serasa,correios}/`
- [X] T011 [US2] Executar `python scripts/censurar_servicos_sociais.py`, inspecionar visualmente por folha de contato todas as capturas censuradas garantindo zero PII legível e validar que o total de `app/assets/guias/` está abaixo de 8 MB
- [X] T012 [P] [US2] Adicionar constantes de títulos de seções, subtítulos, textos de passos (1 ação por passo, posição na tela, aviso `FR-032`) e `descricaoDaCaptura` (TalkBack) para Gov.br, Serasa e Correios em `app/lib/l10n/textos_guias.dart`
- [X] T013 [P] [US2] Estruturar `guiaGovBr` com as 6 seções temáticas (3 a 7 passos cada, marcando `temCampoDeSenha: true` na seção de login) em `app/lib/features/aprendizado/data/guias/gov_br.dart`
- [X] T014 [P] [US2] Estruturar `guiaSerasa` com as 5 seções temáticas (4 a 6 passos cada) em `app/lib/features/aprendizado/data/guias/serasa.dart`
- [X] T015 [P] [US2] Estruturar `guiaCorreios` com as 2 seções temáticas (4 passos cada, marcando `temCampoDeSenha: true` no passo Meu Correios) em `app/lib/features/aprendizado/data/guias/correios.dart`
- [X] T016 [US2] Atualizar a tabela de registro de capturas (chaves, datas, versões, aparelho e observações de seções) em `app/assets/guias/CAPTURAS.md`

**Checkpoint**: Todas as capturas dos serviços sociais censuradas por Blur, otimizadas (< 8 MB) e navegáveis por seção com textos acessíveis.

---

## Phase 5: User Story 3 - Logotipos Oficiais e Acolhimento Final com Abertura/Dúvidas (Priority: P2)

**Goal**: Integrar as logos oficiais de Gov.br, Serasa e Correios ao Design System e garantir que o último passo de cada seção ofereça acolhimento e encaminhamento contextual ao chatbot da Memora.

**Independent Test**: Verificar renderização de `IconeDoAplicativo` para chaves `'gov-br'`, `'serasa'` e `'correios'`; concluir uma seção no `TelaPassoAPasso` e confirmar que o botão *"Ficou com alguma dúvida? Pode perguntar"* preenche o rascunho da conversa com o nome do serviço e da seção.

### Implementation for User Story 3

- [X] T017 [P] [US3] Estender `scripts/censurar_servicos_sociais.py` para converter `apps/GOV/logo.png`, `apps/Serasa/serasa_logo.jfif` e `apps/Correios/correios-perfil-facebook.png` em PNGs quadrados 512×512 limpos em `app/assets/ilustracoes/gov_br_logo.png`, `serasa_logo.png` e `correios_logo.png`
- [X] T018 [US3] Atualizar `IconeDoAplicativo._desenharIcone` para carregar `gov_br_logo.png`, `serasa_logo.png` e `correios_logo.png` (seguindo o padrão de `whatsapp` e `facebook`) em `app/lib/design_system/componentes/ilustracao/icone_do_aplicativo.dart`
- [X] T019 [US3] Incluir o nome da seção concluída no texto de dúvida enviado por `aoTirarDuvida` no último passo de `TelaPassoAPasso` em `app/lib/features/aprendizado/presentation/tela_passo_a_passo.dart`

**Checkpoint**: Logos oficiais integradas no catálogo e fechamento contextual de dúvidas funcionando por seção.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Atualização dos portões automatizados, validação completa de qualidade, acessibilidade e build final.

- [X] T020 Atualizar `catalogo_e_guias_test.dart` para validar também cada `SecaoDoGuia` (3 a 7 passos, `todosOsPassos`, existência de capturas, `descricaoDaCaptura`, `CAPTURAS.md` e teto de 8 MB) em `app/test/features/aprendizado/catalogo_e_guias_test.dart`
- [X] T021 Executar `python specs/002-design-system/ferramentas/validar_tokens.py` e `flutter analyze` em `app/` garantindo zero violações e zero avisos
- [X] T022 Executar suíte completa de testes (`flutter test test/features/aprendizado/ test/acessibilidade/ test/design_system/`) em `app/` e validar todos os cenários descritos em `specs/006-guias-servicos-sociais/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — inicia imediatamente.
- **Foundational (Phase 2)**: Depende da Phase 1 — **BLOQUEIA** US1, US2 e US3.
- **US1 (Phase 3)**: Depende da Phase 2 (`SecaoDoGuia` e `Guia.secoes`).
- **US2 (Phase 4)**: Depende da Phase 2 (`CapturaDoGuia` atualizado). Pode rodar em paralelo com US1 após Phase 2!
- **US3 (Phase 5)**: Depende da Phase 2 e de `T010` (logos) / `T007` (`TelaPassoAPasso`).
- **Polish (Phase 6)**: Depende da conclusão de US1, US2 e US3.

### Parallel Opportunities

- `T001` e `T002` (Setup) podem rodar em paralelo.
- Após Phase 2, **US1 (`T006`–`T009`)** e **US2 (`T010`–`T016`)** podem ser executadas em paralelo.
- Dentro da US2, `T012`, `T013`, `T014` e `T015` (textos e arquivos individuais de guias) podem rodar em paralelo após `T010`/`T011`.
- `T017` (logos) pode rodar junto com `T010`.

---

## Parallel Example: User Story 2

```bash
# Após rodar T010/T011 (capturas censuradas e otimizadas):
Task: "T012 [P] [US2] Textos e descrições em app/lib/l10n/textos_guias.dart"
Task: "T013 [P] [US2] Seções do Gov.br em app/lib/features/aprendizado/data/guias/gov_br.dart"
Task: "T014 [P] [US2] Seções do Serasa em app/lib/features/aprendizado/data/guias/serasa.dart"
Task: "T015 [P] [US2] Seções dos Correios em app/lib/features/aprendizado/data/guias/correios.dart"
```

---

## Implementation Strategy

### MVP First (Phase 1 + Phase 2 + US1)
1. Concluir Phase 1 (backup seguro) e Phase 2 (`SecaoDoGuia` + `Guia` + `CapturaDoGuia`).
2. Implementar US1 (`TelaSeletorDeSecao` + integração + teste na matriz 4×3×3).
3. Validar que guias antigos continuam funcionando sem regressão.

### Incremental Delivery
1. Entregar US2 (pipeline de Blur nas 77 capturas + otimização < 8 MB + conteúdo das 13 seções de Gov.br, Serasa e Correios).
2. Entregar US3 (logos oficiais 512×512 em `IconeDoAplicativo` + contexto da seção no chatbot).
3. Rodar Phase 6 (portões de qualidade, tokens, análise estática e testes).
