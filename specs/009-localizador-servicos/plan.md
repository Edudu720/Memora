# Implementation Plan: Feature 009 — Localizador de Serviços

**Branch**: `feature/009-localizador-servicos` | **Date**: 15/11/2026 | **Spec**: [specs/009-localizador-servicos/spec.md](spec.md)

**Input**: Feature specification from `specs/009-localizador-servicos/spec.md` e artefatos de design em [research.md](research.md), [data-model.md](data-model.md), [contracts/localizador-api.md](contracts/localizador-api.md) e [quickstart.md](quickstart.md).

---

## Summary

O módulo **Localizador de Serviços** permite que pessoas idosas encontrem serviços essenciais próximos (saúde, serviços públicos, emergência e utilidades cotidianas), utilizando localização geográfica assistida e autorizada ou pesquisa manual por cidade/bairro/endereço, com apresentação simplificada das informações, total proteção de privacidade (sem rastreamento permanente) e orientação acessível compatível com o Design System 2.0 (WCAG 2.2 AA/AAA, escala de texto 200%, alvos >= 48/56 dp).

---

## Technical Context

**Language/Version**: Flutter 3.47.7 (Dart 3.x) no aplicativo mobile; Java 21 / Spring Boot 3.4 no backend.

**Primary Dependencies**:
- *Frontend*: `flutter_map` (visualização de mapas via Leaflet / tiles de alto contraste), `latlong2`, `geolocator` (obtenção sob demanda de GPS com consentimento explícito), `url_launcher` (intents de rotas e discagem segura).
- *Backend*: Spring Web, Spring Security, Spring Data JPA, Google Gemini Client (para extração semântica de intenções), WebClient / RestTemplate para consulta aos serviços geoespaciais (OpenStreetMap / Overpass / Nominatim).

**Storage**:
- PostgreSQL para persistência do sistema geral.
- **Zero persistência de coordenadas geográficas**: Coordenadas e histórico de rotas do usuário **não** são armazenados no banco de dados, em estrito cumprimento da LGPD e do Princípio da Privacidade.

**Testing**:
- Flutter: `flutter test` com testes de unidade de domínio, repositório simulado, testes de widget na matriz de acessibilidade (`320×568` até `390×844`, escala `100%` a `200%`, temas Claro, Escuro e Alto Contraste).
- Backend: JUnit 5, Mockito, MockMvc, WireMock para dublês de serviços de mapas e Gemini.

**Target Platform**: Android (smartphones de entrada e intermediários, Android 8.0+ / API 26+).

**Project Type**: Mobile Application (Flutter) + Secure Backend REST API (Spring Boot).

**Performance Goals**: Tempo de resposta de busca inferior a 2,5 segundos em rede 4G móvel; renderização fluida do mapa e listas com 60 fps sem travamento de rolagem.

**Constraints**:
- Conformidade WCAG 2.2 AA/AAA em todas as 13 combinações de tema e paleta.
- Alvos de toque mínimos de `48×48 dp` (`56 dp` em botões de ação e decisões).
- Separação estrita entre informação e ação (`002/FR-012`).
- Nenhuma dependência obrigatória de GPS para a utilização da busca manual por texto.
- A IA (Gemini) **nunca** inventa estabelecimentos ou telefones (apenas interpreta a intenção).

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Princípio I (Segurança Acima de Tudo)**:
  - PASS. Threat modeling documentado em `research.md`. Endpoint protegido com autenticação Bearer JWT. Sem armazenamento permanente de coordenadas do usuário.
- **Princípio II (Segurança contra Engenharia Social)**:
  - PASS. Diálogo pedagógico prévio antes de qualquer permissão. Ligações telefônicas e abertura de rotas em aplicativos externos exigem confirmação explícita em 2 etapas.
- **Princípio III (Acessibilidade como Requisito)**:
  - PASS. Tipografia Atkinson Hyperlegible Next (`>= 16 sp`), alvos `>= 48/56 dp`, escala `200%` sem overflow, controles de zoom grandes (`+` e `-`) na tela de mapa.
- **Princípio IV (Especificação Antes do Código)**:
  - PASS. Spec, contratos de API, modelo de dados e cenários de teste definidos antes da implementação de código.
- **Princípio V (Arquitetura Limpa e Feature-First)**:
  - PASS. Estrutura em `features/localizador/` com separação estrita em `domain/`, `data/` e `presentation/`.
- **Princípio VI (A IA Nunca Age Sozinha)**:
  - PASS. A IA (Gemini) é restrita à categorização da intenção; os estabelecimentos retornados provêm de dados geoespaciais reais verificáveis.
- **Princípio VII (Ensinar, Não Substituir)**:
  - PASS. A ferramenta ensina o caminho e mostra o endereço e opções de trajeto, sem realizar agendamentos ou ações invasivas pelo usuário.

---

## Project Structure

### Documentation (this feature)

```text
specs/009-localizador-servicos/
├── plan.md              # Este plano de implementação
├── research.md          # Decisões de arquitetura, provedores geo e NLU
├── data-model.md        # Entidades e enums de domínio
├── quickstart.md        # Guia rápido de verificação e testes ponta a ponta
├── contracts/
│   └── localizador-api.md  # Contrato OpenAPI/REST do endpoint de busca
└── tasks.md             # Tarefas geradas pelo comando /speckit-tasks
```

### Source Code Layout

#### Frontend (Flutter): `app/lib/features/localizador/`

```text
app/lib/features/localizador/
├── domain/
│   ├── entidades/
│   │   ├── categoria_servico.dart
│   │   ├── endereco_servico.dart
│   │   └── estabelecimento_servico.dart
│   └── repositorios/
│       └── repositorio_localizador.dart
├── data/
│   ├── modelos/
│   │   └── estabelecimento_servico_dto.dart
│   ├── fontes/
│   │   ├── fonte_localizador_api.dart
│   │   └── servico_geolocalizacao_dispositivo.dart
│   └── repositorios/
│       ├── repositorio_localizador_api.dart
│       └── repositorio_localizador_simulado.dart
└── presentation/
    ├── controladores/
    │   └── controlador_localizador.dart
    ├── telas/
    │   ├── tela_localizador.dart
    │   └── tela_detalhe_estabelecimento.dart
    └── widgets/
        ├── cartao_estabelecimento.dart
        ├── mapa_servicos_acessivel.dart
        ├── seletor_categorias_chips.dart
        └── dialogo_permissao_localizacao.dart
```

#### Backend (Spring Boot): `backend/src/main/java/br/fatec/memora/localizador/`

```text
backend/src/main/java/br/fatec/memora/localizador/
├── api/
│   ├── LocalizadorController.java
│   ├── dto/
│   │   ├── BuscarServicosRequest.java
│   │   └── BuscarServicosResponse.java
│   └── dto/
│       └── EstabelecimentoServicoResponse.java
├── aplicacao/
│   ├── ServicoLocalizador.java
│   └── InterpretadorDeIntencaoComGemini.java
├── dominio/
│   ├── CategoriaServico.java
│   └── Estabelecimento.java
└── infra/
    ├── ProvedorGeografico.java
    ├── ProvedorOpenStreetMapOverpass.java
    └── ProvedorNominatimGeocoding.java
```

---

## Implementation Phases & Strategy

### Phase 1: Contratos e Fundação do Backend (Spring Boot)
1. Criar DTOs e validações da API de busca (`BuscarServicosRequest`, `BuscarServicosResponse`).
2. Implementar `InterpretadorDeIntencaoComGemini` via prompts seguros e estruturados.
3. Implementar cliente `ProvedorOpenStreetMapOverpass` e geocodificação via Nominatim com cache em memória.
4. Integrar `ServicoLocalizador` e expor endpoint seguro em `LocalizadorController`.
5. Testes automatizados de backend com respostas simuladas.

### Phase 2: Fundação de Domínio e Dados no Mobile (Flutter)
1. Adicionar dependências (`flutter_map`, `latlong2`, `geolocator`, `url_launcher`).
2. Criar entidades imutáveis de domínio (`EstabelecimentoServico`, `EnderecoServico`, `CategoriaServico`).
3. Implementar contrato de repositório e cliente HTTP (`RepositorioLocalizadorApi` e `RepositorioLocalizadorSimulado`).
4. Implementar serviço de permissão com diálogo explicativo (`ServicoGeolocalizacaoDispositivo`).
5. Testes de unidade de domínio e repositório.

### Phase 3: Interface Acessível e Design System 2.0 (Flutter)
1. Implementar `ControladorLocalizador` gerenciando estados: `inicial`, `carregando`, `sucesso_lista`, `sucesso_mapa`, `permissao_necessaria`, `vazio`, `erro_rede`.
2. Criar `CartaoEstabelecimento` respeitando a separação informação vs ação (categoria em badge tonal, endereço amplo, distância destacada).
3. Criar `MapaServicosAcessivel` usando `flutter_map` com marcadores táteis ampliados e controles de zoom dedicados (`+` e `-` de `56 dp`).
4. Criar barra superior com busca por texto/voz e chips de categoria.
5. Criar diálogos seguros de confirmação para rotas externas e chamadas telefônicas.

### Phase 4: Integração, Portões de Qualidade e Álbum
1. Adicionar atalho rápido *"Serviços Próximos"* na grade 2x2 do Início e no catálogo do Hub.
2. Executar auditorias de tokens (`validar_tokens.py`) e contraste (`validar_paleta.py`).
3. Executar `flutter analyze` e a suíte completa de testes de acessibilidade e layout sem overflow.
4. Atualizar o álbum de capturas nos modos Claro, Escuro e Alto Contraste.
