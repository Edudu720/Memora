# Tasks: Feature 009 — Localizador de Serviços

**Input**: Documentos de design em `specs/009-localizador-servicos/` ([spec.md](spec.md), [plan.md](plan.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/localizador-api.md](contracts/localizador-api.md), [quickstart.md](quickstart.md)).

**Prerequisites**: `plan.md` (arquitetura e stack), `spec.md` (requisitos funcionais e não-funcionais), `constitution.md` (princípios inegociáveis de segurança e acessibilidade).

**Organization**: Tarefas agrupadas por fases e User Stories independentes para permitir implementação e verificação incremental.

---

## Phase 1: Setup & Dependências Compartilhadas

**Propósito**: Configuração de dependências no frontend e backend, e estrutura de pastas da feature.

- [ ] T001 [P] Adicionar dependências no mobile em `app/pubspec.yaml` (`flutter_map: ^7.0.2`, `latlong2: ^0.9.1`, `geolocator: ^13.0.2`, `url_launcher: ^6.3.1`) e executar `flutter pub get`
- [ ] T002 [P] Configurar permissões de localização no Android em `app/android/app/src/main/AndroidManifest.xml` (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`) com intent query para mapas e discador
- [ ] T003 [P] Criar árvore de diretórios do frontend em `app/lib/features/localizador/` (`domain/entidades`, `domain/repositorios`, `data/modelos`, `data/fontes`, `data/repositorios`, `presentation/controladores`, `presentation/telas`, `presentation/widgets`)
- [ ] T004 [P] Criar árvore de pacotes do backend em `backend/src/main/java/br/fatec/memora/localizador/` (`api/dto`, `aplicacao`, `dominio`, `infra`)

---

## Phase 2: Foundational (Infraestrutura e Contratos Base)

**Propósito**: Entidades de domínio, DTOs e contratos que desbloqueiam as histórias de usuário.

- [ ] T005 [P] Criar enums de domínio no backend em `backend/src/main/java/br/fatec/memora/localizador/dominio/CategoriaServico.java` (`SAUDE`, `SERVICOS_PUBLICOS`, `EMERGENCIA`, `COTIDIANO`) e `FonteDados.java`
- [ ] T006 [P] Criar DTOs de requisição e resposta da API no backend em `backend/src/main/java/br/fatec/memora/localizador/api/dto/BuscarServicosRequest.java` e `BuscarServicosResponse.java` conforme o contrato `contracts/localizador-api.md`
- [ ] T007 [P] Criar entidade de domínio no backend em `backend/src/main/java/br/fatec/memora/localizador/dominio/Estabelecimento.java` e `Endereco.java`
- [ ] T008 [P] Criar entidades imutáveis de domínio no mobile em `app/lib/features/localizador/domain/entidades/categoria_servico.dart`, `endereco_servico.dart` e `estabelecimento_servico.dart`
- [ ] T009 [P] Criar interface de repositório no mobile em `app/lib/features/localizador/domain/repositorios/repositorio_localizador.dart`
- [ ] T010 [P] Criar DTO e serialização JSON no mobile em `app/lib/features/localizador/data/modelos/estabelecimento_servico_dto.dart`
- [ ] T011 [P] Criar repositório simulado em memória para testes no mobile em `app/lib/features/localizador/data/repositorios/repositorio_localizador_simulado.dart` com dados realistas de Americana/SP

---

## Phase 3: User Story 1 (P1) — Pesquisa por Categoria e Provedores Geo no Backend

**Meta**: O backend integra com fontes abertas (OSM Overpass / Nominatim) e disponibiliza endpoint seguro de busca por categoria e coordenadas geográficas, sem armazenar localização no banco de dados.

### Testes da User Story 1
- [ ] T012 [P] [US1] Criar teste de integração de API no backend em `backend/src/test/java/br/fatec/memora/localizador/api/LocalizadorControllerTest.java` validando contrato `POST /api/v1/servicos/buscar`, cálculo de distância e erro 400 sem região
- [ ] T013 [P] [US1] Criar teste unitário de cálculo geodésico e mapeamento em `backend/src/test/java/br/fatec/memora/localizador/infra/ProvedorOpenStreetMapOverpassTest.java` com respostas JSON simuladas

### Implementação da User Story 1
- [ ] T014 [US1] Implementar interface `ProvedorGeografico` e cliente `ProvedorOpenStreetMapOverpass.java` em `backend/src/main/java/br/fatec/memora/localizador/infra/` consultando postos, farmácias, Poupatempo e serviços essenciais via Overpass QL
- [ ] T015 [US1] Implementar geocodificação de endereços e bairros em `backend/src/main/java/br/fatec/memora/localizador/infra/ProvedorNominatimGeocoding.java` com cache em memória (Caffeine/Map)
- [ ] T016 [US1] Implementar `ServicoLocalizador.java` em `backend/src/main/java/br/fatec/memora/localizador/aplicacao/` orquestrando busca por categoria, geodistância Haversine, ordenação e mensagens de transparência (dados não informados)
- [ ] T017 [US1] Criar controlador REST protegido em `backend/src/main/java/br/fatec/memora/localizador/api/LocalizadorController.java` anotado com `@PreAuthorize("isAuthenticated()")` e validações de DTO
- [ ] T018 [US1] Implementar cliente HTTP no mobile em `app/lib/features/localizador/data/fontes/fonte_localizador_api.dart` e `app/lib/features/localizador/data/repositorios/repositorio_localizador_api.dart`

---

## Phase 4: User Story 2 (P1) — Interpretação de Necessidade em Linguagem Natural com Gemini

**Meta**: O backend interpreta expressões livres do usuário (texto ou voz) usando o Gemini API para inferir a categoria e os termos de busca de forma estruturada, sem inventar estabelecimentos.

### Testes da User Story 2
- [ ] T019 [P] [US2] Criar teste unitário em `backend/src/test/java/br/fatec/memora/localizador/aplicacao/InterpretadorDeIntencaoComGeminiTest.java` validando classificação de intenção (ex: *"onde tomo vacina"* -> `SAUDE`/`UBS`) e fallback quando o Gemini falhar

### Implementação da User Story 2
- [ ] T020 [US2] Implementar componente `InterpretadorDeIntencaoComGemini.java` em `backend/src/main/java/br/fatec/memora/localizador/aplicacao/` usando `gemini-3.8-flash` com system prompt estrito (retorno puramente JSON com categoria e tags, sem alucinação de locais)
- [ ] T021 [US2] Integrar o interpretador em `ServicoLocalizador.java` para converter o campo `consulta` em filtros de busca do OpenStreetMap quando presente
- [ ] T022 [US2] Adicionar fallback determinístico por palavras-chave em `InterpretadorDeIntencaoComGemini.java` caso a cota ou conexão do Gemini esteja indisponível

---

## Phase 5: User Story 3 (P1) — Experiência do Usuário Sênior: Lista, Localização e Busca Manual

**Meta**: O usuário idoso abre o Localizador, recebe explicação pedagógica para o GPS, ou pesquisa manualmente por bairro/cidade se preferir ou recusar o GPS, visualizando os resultados em cartões espaçosos de alto contraste.

### Testes da User Story 3
- [ ] T023 [P] [US3] Criar testes de widget e acessibilidade em `app/test/features/localizador/tela_localizador_test.dart` (renderização em 320x568 e 390x844, escala 200%, chips de categoria e busca manual)
- [ ] T024 [P] [US3] Criar teste de fluxo em `app/test/features/localizador/controlador_localizador_test.dart` validando estados com permissão concedida, negada e busca manual por cidade

### Implementação da User Story 3
- [ ] T025 [P] [US3] Implementar serviço de geolocalização do dispositivo em `app/lib/features/localizador/data/fontes/servico_geolocalizacao_dispositivo.dart` via `geolocator` com tratamento de GPS desligado e permissão negada
- [ ] T026 [P] [US3] Criar diálogo pedagógico de permissão em `app/lib/features/localizador/presentation/widgets/dialogo_permissao_localizacao.dart` explicando com clareza o motivo do acesso antes de chamar o diálogo nativo do sistema
- [ ] T027 [P] [US3] Criar componente `CartaoEstabelecimento` em `app/lib/features/localizador/presentation/widgets/cartao_estabelecimento.dart` usando `Cartao` do DS 2.0, `BadgeDeStatus` para a categoria, tipografia `AtkinsonHyperlegibleNext` e aviso de dados não informados
- [ ] T028 [P] [US3] Criar componente de filtro em pílulas `SeletorCategoriasChips` em `app/lib/features/localizador/presentation/widgets/seletor_categorias_chips.dart` usando `ChipFiltro` do DS 2.0 (alvo >= 48 dp)
- [ ] T029 [US3] Implementar gerenciamento de estado em `app/lib/features/localizador/presentation/controladores/controlador_localizador.dart` coordenando categoria ativa, GPS, busca manual, filtro e lista de resultados
- [ ] T030 [US3] Criar a tela principal `TelaLocalizador` em `app/lib/features/localizador/presentation/telas/tela_localizador.dart` com `BarraSuperior`, campo de busca por texto com botão de ditado por voz, alternância de lista/mapa e aviso antigolpe

---

## Phase 6: User Story 4 (P2) — Mapa de Alto Contraste e Ações Seguras (Rotas e Ligações)

**Meta**: O usuário pode alternar para visualização em mapa com botões de zoom grandes e acionar rotas ou ligações telefônicas exclusivamente com confirmação prévia em duas etapas.

### Testes da User Story 4
- [ ] T031 [P] [US4] Criar teste em `app/test/features/localizador/acoes_seguras_test.dart` validando que tocar em *"Como chegar"* e *"Ligar"* exibe confirmação antes de invocar `url_launcher`

### Implementação da User Story 4
- [ ] T032 [P] [US4] Implementar `MapaServicosAcessivel` em `app/lib/features/localizador/presentation/widgets/mapa_servicos_acessivel.dart` usando `flutter_map` com tiles em alto contraste, marcadores ampliados por categoria e botões de zoom dedicados (`+` e `-` com 56x56 dp)
- [ ] T033 [US4] Integrar o mapa e o botão de alternância (*"Ver no mapa"* / *"Ver em lista"*) na `TelaLocalizador`
- [ ] T034 [P] [US4] Criar diálogo modal de confirmação de trajeto em `app/lib/features/localizador/presentation/widgets/dialogo_confirmacao_rota.dart` alertando que o mapa do celular será aberto e fornecendo opções de voltar ou prosseguir
- [ ] T035 [P] [US4] Criar diálogo modal de confirmação de chamada em `app/lib/features/localizador/presentation/widgets/dialogo_confirmacao_ligacao.dart` destacando o número em tamanho grande antes de abrir o discador nativo

---

## Phase 7: Polish, Integração no Início/Hub, Portões Globais & Álbum

**Propósito**: Integrar o ponto de entrada do Localizador nas telas principais, validar acessibilidade em toda a suíte e registrar documentação viva.

- [ ] T036 Integrar o atalho do Localizador de Serviços na grade 2x2 da `TelaInicio` (`app/lib/features/inicio/presentation/tela_inicio.dart`) e no catálogo da `TelaHub` (`app/lib/features/hub/presentation/telas/tela_hub.dart`)
- [ ] T037 [P] Atualizar testes de regressão de layout em `app/test/acessibilidade/hub_cabe_sem_rolar_test.dart` e `app/test/features/inicio/inicio_ocupa_a_altura_test.dart` garantindo zero quebra com a nova porta
- [ ] T038 [P] Atualizar documentação viva em `CHANGELOG.md` e `docs/VISAO_GERAL_E_FUNCOES_DO_PROJETO.md` com a entrada da Feature 009
- [ ] T039 Executar auditoria global de literais visuais via `python specs/002-design-system/ferramentas/validar_tokens.py` e `--autoteste` garantindo saída `0`
- [ ] T040 Executar auditoria de contraste WCAG 2.2 AA/AAA via `python specs/002-design-system/ferramentas/validar_paleta.py` e `--autoteste` garantindo saída `0`
- [ ] T041 Executar análise estática completa via `flutter analyze` em `app/` garantindo zero erros e zero avisos
- [ ] T042 Adicionar a `TelaLocalizador` ao álbum em `app/test/album/album_de_telas_test.dart` e regenerar capturas nos 3 modos (`Claro`, `Escuro`, `Alto Contraste`)
- [ ] T043 Executar suíte de testes do aplicativo via `flutter test test/features/localizador/` e testes de regressão

---

## Dependências & Ordem de Execução

```text
Phase 1: Setup & Dependências (T001-T004)
   └─> Phase 2: Foundational (T005-T011) [BLOQUEANTE]
          ├─> Phase 3: US1 - Backend OpenStreetMap & API (T012-T018) [P1]
          │      └─> Phase 4: US2 - NLU com Gemini (T019-T022) [P1]
          ├─> Phase 5: US3 - Mobile Lista, Localização & Busca Manual (T023-T030) [P1] [MVP]
          │      └─> Phase 6: US4 - Mapa de Alto Contraste & Ações Seguras (T031-T035) [P2]
          └─> Phase 7: Polish, Portões Globais, Álbum & Documentação (T036-T043)
```

---

## Estratégia de Entrega (MVP Primeiro)

1. **MVP (Fases 1, 2, 3 e 5)**: O idoso pode pesquisar por postos de saúde e serviços essenciais tocando nas categorias ou digitando o bairro manualmente, visualizando nome, endereço, telefone e distância em uma lista ampla e acessível.
2. **Incremento 2 (Fase 4 - US2)**: Pesquisa em linguagem natural interpretada pelo Gemini.
3. **Incremento 3 (Fase 6 - US4)**: Visualização em mapa interativo com marcadores ampliados e botões de zoom acessíveis.
4. **Fechamento (Fase 7)**: Verificação de contraste, tokens, álbum de telas e CI.
