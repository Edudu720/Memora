# Implementation Plan: Feature 010 — Correções da Revisão da PR #71 (Privacidade, Voz Local e Localizador Real)

**Branch**: `feature/009-localizador-servicos` | **Date**: 2026-11-15 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `c:\Users\Eduardo\Memora\specs\010-revisao-pr71-localizador\spec.md` e artefatos de design [research.md](research.md), [data-model.md](data-model.md), [contracts/localizador-e-privacidade.md](contracts/localizador-e-privacidade.md) e [quickstart.md](quickstart.md).

---

## Summary

Este plano endereça sistematicamente os quatro eixos apontados na revisão da PR #71 sobre a branch `feature/009-localizador-servicos`:
1. **Privacidade, expurgo de PII e histórico Git limpo**: substituir todas as referências ao CPF real e dados pessoais de captura nos scripts e na spec `006`, remover `Memora-Desing-Ideias/` do controle de versão e adicioná-la ao `.gitignore`, consolidando todas as mudanças da branch em **1 único commit limpo sobre `origin/develop`** antes do `git push --force-with-lease`.
2. **Ditado por voz estritamente offline (`onDevice: true`)**: configurar `SpeechListenOptions(onDevice: true)` em `LeitorDeVozSpeechToText`, sem fallback para nuvem, preservando o botão de microfone com diálogo educativo prévio e mensagem clara orientando o teclado ou pacote de voz offline em português em caso de indisponibilidade.
3. **Localizador conectado ao servidor real e modo simulado seguro**: injetar `RepositorioLocalizadorApi` via `Composicao` e `FluxoAutenticacao` quando `usaServidorReal == true` (alinhando o caminho `/servicos/buscar` vs `/v1`, cabeçalho Bearer e `ChamadaComRenovacao`), eliminar os fallbacks silenciosos para dados fictícios de Americana - SP tanto no app quanto no `ProvedorOpenStreetMapOverpass`, definir `telefone: null` em `RepositorioLocalizadorSimulado` e exibir banner explícito de demonstração na `TelaLocalizador`.
4. **Transparência OpenStreetMap, nomenclatura honesta e higiene de Specs/CI**: explicitar a consulta pública ao OpenStreetMap no `DialogoPermissaoLocalizacao`, adicionar `User-Agent` identificável e limitador `<= 1 req/s` ao Nominatim no backend, renomear `InterpretadorDeIntencaoComGemini` para `InterpretadorDeIntencaoPorPalavrasChave`, atualizar o status das specs `006`, `007` e `009`, e restaurar `flutter-version: '3.47.7'` com `flutter analyze` estrito em `.github/workflows/verificacao.yml`.

---

## Technical Context

**Language/Version**: Flutter `3.47.7` (Dart `3.x`) no aplicativo mobile; Java 21 / Spring Boot `3.4` no backend; Python `3.x` nos scripts utilitários/portões.  
**Primary Dependencies**:
- *App*: `speech_to_text`, `flutter_map`, `latlong2`, `geolocator`, `url_launcher`, `dio`, `memora_api`, `shared_preferences`.
- *Backend*: Spring Web, Spring Security (JWT Bearer), `RestTemplate` / HTTP client para OpenStreetMap Nominatim e Overpass API.  
**Storage**: Nenhuma persistência de áudio de voz, coordenadas geográficas ou região pesquisada; apenas placeholders sintéticos e metadados em repositório Git.  
**Testing**:
- Flutter: `flutter test` (`test/features/assistente/`, `test/features/localizador/`, `test/services/`) + `flutter analyze` estrito + `dart analyze` / `dart test` em `app/pacotes/memora_api`.
- Backend: JUnit 5 + Mockito (`./mvnw --batch-mode test` em `backend/`), com dublês HTTP/relógio para validar rate limit do Nominatim e indisponibilidade transparente (`503`/`400`).
- Design System / Privacidade: `validar_paleta.py`, `validar_tokens.py` e varredura `git grep` / `git log origin/develop..feature/009-localizador-servicos -G`.  
**Target Platform**: Android (API 26+) e ambiente Linux/JVM no backend e CI GitHub Actions.  
**Project Type**: Mobile Application (`app/`) + REST API (`backend/`) + documentação/scripts (`specs/`, `scripts/`, `.github/`).  
**Performance Goals**: Taxa controlada ao Nominatim estritamente limitada a no máximo `1 req/s` (`>= 1000 ms` entre chamadas); testes unitários do rate limiter determinísticos sem lentidão de espera real desnecessária usando relógio/controlador injetável.  
**Constraints**:
- Zero fallback silencioso de reconhecimento de voz em nuvem (`onDevice: true` estrito).
- Zero fallback silencioso de estabelecimentos simulados ou coordenadas hardcoded em modo real (`usaServidorReal == true`).
- Zero números de telefone clicáveis/discáveis em `RepositorioLocalizadorSimulado` (`telefone: null`).
- Zero `--no-fatal-infos` no CI; Flutter `3.47.7` obrigatório.
**Scale/Scope**: 1 módulo backend (`localizador`), 3 áreas Flutter (`assistente`, `localizador`, `services/ambiente` + `autenticacao`), 8 arquivos de scripts/specs para expurgo de PII, 3 arquivos de status de specs (`006`, `007`, `009`), `.gitignore`, `.github/workflows/verificacao.yml` e 1 commit limpo sobre `origin/develop`.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Avaliação Pré-Design e Pós-Design

1. **Princípio I — Segurança e Privacidade Acima de Tudo**:
   - **PASS (Pré e Pós-Design)**: Remove CPF real e menções nominais do histórico Git da PR #71 (`FR-001`–`FR-003`), restringe ditado por voz ao processamento local (`onDevice: true`, `FR-004`), ativa autenticação JWT + `ChamadaComRenovacao` na integração real do Localizador (`FR-006`) e elimina qualquer persistência de coordenadas.
2. **Princípio II — Segurança Contra Engenharia Social**:
   - **PASS (Pré e Pós-Design)**: Atualiza `DialogoPermissaoLocalizacao` para informar com clareza a consulta ao OpenStreetMap sem envio de dados pessoais (`FR-009`), suprime telefones discáveis inventados no modo simulado (`FR-008`, `telefone: null`) e destaca visualmente dados de demonstração na UI.
3. **Princípio III — Acessibilidade Como Requisito**:
   - **PASS (Pré e Pós-Design)**: Mantém o botão de microfone disponível sem regressão de navegação (`Q2`), oferece instruções simples em português caso falte pacote offline de voz (`FR-005`) e mantém banner/avisos de erro legíveis em todos os temas e tokens existentes (`validar_tokens.py`, `validar_paleta.py`).
4. **Princípio IV — Especificação Antes do Código**:
   - **PASS (Pré e Pós-Design)**: Toda a refatoração decorre de [spec.md](spec.md) clarificada (`Q1`–`Q3`), [research.md](research.md), [data-model.md](data-model.md), [contracts/localizador-e-privacidade.md](contracts/localizador-e-privacidade.md) e [quickstart.md](quickstart.md).
5. **Princípio V — Arquitetura Limpa e Feature-First**:
   - **PASS (Pré e Pós-Design)**: Mantém `Composicao` como único ponto de decisão real vs. simulado (`app/lib/services/ambiente/composicao.dart`), injeta `RepositorioLocalizador` em `FluxoAutenticacao` sem acoplar regras HTTP à apresentação e separa claramente interface `ProvedorGeografico` de `ProvedorOpenStreetMapOverpass` e `InterpretadorDeIntencaoPorPalavrasChave`.
6. **Princípio VI — IA Nunca Age Sozinha / Transparência de Algoritmos**:
   - **PASS (Pré e Pós-Design)**: Renomeia `InterpretadorDeIntencaoComGemini` para `InterpretadorDeIntencaoPorPalavrasChave` (`FR-011`) eliminando falsa atribuição de uso do Gemini; toda resposta vem de dados geográficos reais ou erro explícito sem alucinação ou base fictícia escondida (`FR-007`).
7. **Princípio VII — Ensinar, Não Substituir**:
   - **PASS (Pré e Pós-Design)**: Orienta a usuária idosa a digitar ou habilitar pacote offline em português quando o ditado local indisponibiliza, além de oferecer tentativa manual transparente em falhas do mapa (`FR-005`, `FR-007`).

---

## Project Structure

### Documentation (this feature)

```text
specs/010-revisao-pr71-localizador/
├── spec.md                              # Especificação clarificada (Q1, Q2, Q3)
├── checklists/
│   ├── requirements.md                  # Checklist da especificação (16/16)
│   └── pr71-revisao.md                  # Checklist completo de qualidade dos requisitos (30/30 [x])
├── plan.md                              # Este plano de implementação
├── research.md                          # Fase 0: decisões técnicas e alternativas
├── data-model.md                        # Fase 1: entidades, estados e invariantes
├── quickstart.md                        # Fase 1: passos e comandos de verificação V1–V4
├── tasks.md                             # Fase 2: tarefas executáveis (/speckit-tasks)
└── contracts/
    └── localizador-e-privacidade.md     # Fase 1: contratos API, OSM, voz, demo e Git/CI
```

### Source Code & Repository Touchpoints

```text
.gitignore                                                                 # [MOD] Adicionar Memora-Desing-Ideias/
.github/workflows/verificacao.yml                                          # [MOD] flutter-version: '3.47.7', flutter analyze estrito, dart test
Memora-Desing-Ideias/                                                      # [UNTRACK] Remover do índice Git (git rm -r --cached)

scripts/
├── censurar_servicos_sociais.py                                           # [MOD] Substituir CPF/nomes por XXX.XXX.XXX-XX
└── processar_guias_visuais.py                                             # [MOD] Substituir CPF/nomes de captura por placeholders

specs/
├── 006-guias-servicos-sociais/                                            # [MOD] Expurgar PII + atualizar status em spec.md
│   ├── spec.md
│   ├── plan.md
│   ├── research.md
│   ├── quickstart.md
│   ├── tasks.md
│   └── contracts/guias-com-secoes.md
├── 007-redesenho-visual-profissional/spec.md                              # [MOD] Atualizar campo Status no cabeçalho
└── 009-localizador-servicos/spec.md                                       # [MOD] Alinhar Status (PR #71) e nota de reconciliação (palavras-chave sem Gemini)

app/
├── lib/
│   ├── main.dart                                                          # [MOD] Repassar composicao.localizador ao FluxoAutenticacao
│   ├── l10n/textos_assistente.dart                                        # [MOD] Adicionar mensagem educativa de ditado offline indisponível
│   ├── services/ambiente/composicao.dart                                  # [MOD] Resolver RepositorioLocalizadorApi vs Simulado
│   ├── features/
│   │   ├── assistente/
│   │   │   ├── data/leitor_de_voz_nativo.dart                             # [MOD] onDevice: true estrito em SpeechListenOptions e mensagem offline
│   │   │   └── presentation/controladores/controlador_conversa.dart       # [MOD] Garantir aviso offline acolhedor e preservação do rascunho em erro permanente
│   │   ├── autenticacao/presentation/fluxo_autenticacao.dart              # [MOD] Receber RepositorioLocalizador? opcional e repassar ao Hub/Tela
│   │   └── localizador/
│   │       ├── domain/repositorios/repositorio_localizador.dart           # [MOD] Campos ehDemonstracao, latitudeRegiao e longitudeRegiao em ResultadoBuscaServicos
│   │       ├── data/fontes/fonte_localizador_api.dart                     # [MOD] Caminho compatível com /v1, Bearer secure extra e ChamadaComRenovacao
│   │       ├── data/modelos/estabelecimento_servico_dto.dart              # [MOD] Propagar latitudeRegiao/longitudeRegiao de regiaoOrigem e ehDemonstracao: false
│   │       ├── data/repositorios/repositorio_localizador_api.dart         # [MOD] Remover fallback simulado; propagar erro transparente
│   │       ├── data/repositorios/repositorio_localizador_simulado.dart    # [MOD] ehDemonstracao: true e telefone: null em todos os itens
│   │       └── presentation/
│   │           ├── controladores/controlador_localizador.dart             # [MOD] Limpar lista em falha real, expor flag ehDemonstracao e centro da região
│   │           ├── telas/tela_localizador.dart                            # [MOD] Banner de demonstração (lista/mapa), sem busca prematura pré-diálogo, sem Americana padrão e nota OSM na busca manual
│   │           └── widgets/dialogo_permissao_localizacao.dart             # [MOD] Texto transparente sobre OpenStreetMap sem envio de conta
└── test/features/
    ├── assistente/ditado_por_voz_test.dart                                # [MOD/ADD] Cobrir onDevice: true / indisponível sem fallback nuvem
    └── localizador/
        ├── acoes_seguras_test.dart                                        # [MOD] Usar fixture explícita com telefone no teste do diálogo
        ├── controlador_localizador_test.dart                              # [MOD] Testar propagação de erro e ausência de fallback fake
        ├── repositorio_localizador_test.dart *(novo)*                     # [ADD] FonteLocalizadorApi, Composicao e RepositorioLocalizadorSimulado (telefone == null)
        └── tela_localizador_test.dart                                     # [MOD] Testar banner de demonstração e texto OSM no diálogo

backend/src/
├── main/java/br/fatec/memora/localizador/
│   ├── api/LocalizadorController.java                                     # [MOD] Suportar /v1/servicos e /api/v1/servicos + HTTP 503 em falha externa
│   ├── aplicacao/
│   │   ├── InterpretadorDeIntencaoPorPalavrasChave.java                   # [RENOMEAR de InterpretadorDeIntencaoComGemini.java]
│   │   └── ServicoLocalizador.java                                        # [MOD] Injetar InterpretadorDeIntencaoPorPalavrasChave e propagar erro de região/provedor
│   └── infra/
│       ├── ProvedorGeograficoIndisponivelException.java *(novo)*          # [ADD] Exceção explícita para mapear HTTP 503 em falha externa
│       └── ProvedorOpenStreetMapOverpass.java                           # [MOD] User-Agent do projeto, rate limit <= 1 req/s Nominatim, remover Americana/contingência
└── test/java/br/fatec/memora/localizador/
    ├── api/LocalizadorControllerTest.java                                 # [MOD] Cobrir resposta 503 em falha de provedor externo
    ├── aplicacao/
    │   ├── InterpretadorDeIntencaoPorPalavrasChaveTest.java               # [RENOMEAR de InterpretadorDeIntencaoComGeminiTest.java]
    │   └── ServicoLocalizadorTest.java                                    # [MOD] Atualizar referência para InterpretadorDeIntencaoPorPalavrasChave
    └── infra/ProvedorOpenStreetMapOverpassTest.java *(novo)*              # [ADD] Validar User-Agent, rate limit >= 1s no Nominatim e erro sem contingência
```

---

## Complexity Tracking

Nenhuma violação ou exceção aos princípios constitucionais foi necessária. Todas as soluções reutilizam os padrões existentes do repositório (`Composicao`, `ChamadaComRenovacao`, `TextosAssistente`, `Design System 2.0`, serviços Spring gerenciados) mantendo complexidade mínima e testabilidade unitária determinística.
