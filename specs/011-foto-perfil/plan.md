# Implementation Plan: Foto de Perfil da Pessoa Usuária

**Branch**: `feature/011-foto-perfil` | **Date**: 2026-11-16 | **Spec**: [spec.md](file:///c:/Users/Eduardo/Memora/specs/011-foto-perfil/spec.md)  
**Input**: Feature specification from `/specs/011-foto-perfil/spec.md`

---

## Summary

Implementar a escolha, pré-visualização, persistência local segura, troca e remoção de **foto de perfil** na tela de **Meu perfil** do aplicativo Flutter, atendendo integralmente às clarificações aprovadas:
1. **Exclusivamente local por conta (`Q1: A`)**: nenhuma imagem sai do aparelho nem altera backend/OpenAPI; o retrato fica no diretório privado de suporte do app + índice por conta (`SharedPreferences`) implementando `DadoLocalDoAparelho` (preservado na saída comum e expurgado em "Sair e esquecer este aparelho").
2. **Três origens (`Q2: B`)**: galeria do sistema (via Android Photo Picker no Android 13+ sem permissão ampla de mídia), câmera sob demanda (`CAMERA`) e coleção de **avatares ilustrados da Memora** embarcados (sem necessidade de permissões).
3. **Exibição e UX 65+ (`Q3: A`, `FR-001`–`FR-005`)**: destaque circular em "Meu perfil" dedicado exclusivamente à pessoa usuária (com retrato padrão neutro por iniciais/silhueta quando ausente), folha de escolha com explicação de privacidade integrada (`FR-004`), recorte quadrado centralizado automático para `<= 512×512 px` (entrada `<= 15 MB`) com remoção obrigatória de EXIF via pacote `image` em `Isolate.run`, tela simples de pré-visualização ("Usar esta foto" / "Escolher outra") e confirmação explícita para remoção.

---

## Technical Context

**Language/Version**: Dart `3.13.5` / Flutter `3.47.7` (app móvel; backend Java/Spring Boot intocado nesta feature por decisão `Q1: A`)  
**Primary Dependencies**: `image_picker` (seleção de galeria/câmera), `image` (decodificação segura, validação de formato real, `bakeOrientation`, crop quadrado `512×512`, re-encode JPEG sem EXIF em Dart puro), `path_provider: ^2.1.5` (já declarado), `shared_preferences: ^2.5.5` (já declarado), `android_intent_plus: ^5.3.0` (já declarado — abrir configurações do app em caso de permissão negada), Design System interno (`FolhaInferior`, `ConfirmacaoMemora`, `BotaoPrimario`/`Secundario`/`Terciario`, `AvisoCompacto` ou quadro de aviso, `TextoMemora`)  
**Storage**: Diretório privado do aplicativo (`getApplicationSupportDirectory()/fotos_perfil/`) para arquivos `.jpg` sanitizados + `SharedPreferences` (`memora.foto_perfil.v1.<contaSegura>`) como índice de tipo/arquivo/avatar por `idDaConta`, cobertos por `android:allowBackup="false"`  
**Testing**: `flutter test` (testes unitários de processamento/EXIF, testes de persistência/isolamento/limpeza `DadoLocalDoAparelho`, testes de widget em `TelaPerfil` cobrindo `US1`–`US3`, concorrência, permissões negadas, 3 temas e `textScaler` `2.0`) e `flutter analyze`  
**Target Platform**: Android (principal, API compatível com Flutter 3.47 + Photo Picker em Android 13+) / iOS / VM de testes `flutter test`  
**Project Type**: Mobile app Flutter (`app/`) dentro de monorepo  
**Performance Goals**: Processamento (`<= 15 MB` → crop `<= 512×512 px` + limpeza EXIF) fora da thread de UI via `Isolate.run` mantendo 60 fps na navegação; abertura offline instantânea do Perfil  
**Constraints**: Zero envio de imagem à rede; zero permissão `READ_MEDIA_IMAGES` / leitura ampla da galeria; entrada máxima `15 MB`; saída máxima `512×512 px` sem metadados EXIF; controles `>= 48×48 dp` com espaçamento `>= 8 dp`, contraste WCAG 2.2 AA nos 3 temas e texto sem corte até `200%`  
**Scale/Scope**: 1 tela modificada (`TelaPerfil`), 3 componentes/telas novos na feature `perfil` (`SecaoFotoPerfil`, `RetratoDoPerfil`, `TelaPreVisualizacaoFoto`), módulo de domínio/dados (`RetratoDePerfil`, `ProcessadorDeImagemDePerfil`, `SeletorDeImagemDoAparelho`, `FotoDePerfilLocal`), ligação em `Composicao` / `FluxoAutenticacao` / `main.dart` / `AndroidManifest.xml`, e suíte de testes em `app/test/features/perfil/` + `saida_limpa_armazenamento_test.dart`

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Gate Pré-Pesquisa (Pre-Design)
- **Princípio I — Segurança Acima de Tudo**:
  - ✅ Nenhum segredo/credencial afetado; `flutter_secure_storage` continua exclusivo para tokens (cenário V8 preservado).
  - ✅ Nenhuma nova superfície de servidor/API; armazenamento restrito à sandbox privada do app (`allowBackup="false"`).
  - ✅ Planejada validação binária real da imagem, limite `15 MB`, re-encode sem EXIF/GPS e chaveamento sanitizado por `idDaConta`.
- **Princípio II — Segurança Contra Engenharia Social**:
  - ✅ Explicação integrada em linguagem humana (`FR-004`), botões com texto explícito + ícone (nunca só ícone solto sobre miniatura), confirmação com duas ações ao remover, distinção visual clara entre retrato do usuário e assistente Memora.
- **Princípio III — Acessibilidade como Requisito**:
  - ✅ Tokens do Design System (`MemoraEspacamento`, `MemoraDimensoes`, `TemasMemora`), mínimo `48×48 dp`, `8 dp` de espaçamento, WCAG 2.2 AA nos 3 temas, escala `200%`, `Semantics` explícita e respeito a `reduzirMovimento`.
- **Princípio IV — Qualidade, Contratos e Spec First**:
  - ✅ Especificação aprovada e clarificada em [spec.md](file:///c:/Users/Eduardo/Memora/specs/011-foto-perfil/spec.md) (`17/17` no checklist) antes de qualquer código; nenhum contrato externo alterado.
- **Princípio VI / VII — Branches e Verificação Real**:
  - ✅ Trabalho isolado em `feature/011-foto-perfil` a partir de `develop`; plano exige `flutter analyze` e suíte completa `flutter test`.

### Reavaliação Pós-Design (Post-Design — após Phase 1)
- ✅ **Path Traversal / Cache Stale**: Mitigado no [data-model.md](file:///c:/Users/Eduardo/Memora/specs/011-foto-perfil/data-model.md) usando `contaSegura(idDaConta)` restrito a `[a-zA-Z0-9_-]` e arquivos versionados `<contaSegura>_<timestampMs>.jpg` com remoção do arquivo anterior na substituição.
- ✅ **Concorrência e Bloqueio por Inatividade**: Mitigado nos contratos em [interfaces-foto-perfil.md](file:///c:/Users/Eduardo/Memora/specs/011-foto-perfil/contracts/interfaces-foto-perfil.md) com guarda `_ocupado`, conferência de `mounted` e preservação do `idDaConta` capturado no início da operação antes de persistir ou atualizar estado.
- ✅ **Zero Permissão Desnecessária**: Mitigado no [research.md](file:///c:/Users/Eduardo/Memora/specs/011-foto-perfil/research.md) (`R1`, `R4`): Photo Picker no Android 13+, `CAMERA` declarada sem `android:required="true"` e avatares ilustrados embarcados sem permissões.

---

## Project Structure

### Documentation (this feature)

```text
specs/011-foto-perfil/
├── spec.md                              # Especificação clarificada (Clarifications 2026-11-16)
├── plan.md                              # Este arquivo (/speckit-plan)
├── research.md                          # Decisões técnicas R1–R5
├── data-model.md                        # Entidades, esquema local e máquina de estados
├── quickstart.md                        # Guia de validação e comandos
├── contracts/
│   └── interfaces-foto-perfil.md        # Contratos entre domínio, dados e UI
└── checklists/
    ├── requirements.md                  # Checklist da especificação (17/17)
    └── pr-review.md                     # Checklist de revisão de qualidade (18/18)
```

### Source Code (repository root)

```text
app/
├── pubspec.yaml                                               # Adicionar image_picker e image
├── android/app/src/main/AndroidManifest.xml                   # Permissão CAMERA e feature opcional + query settings se necessário
├── lib/
│   ├── main.dart                                              # Instanciar FotoDePerfilLocal e passar à Composicao
│   ├── l10n/
│   │   └── textos_perfil.dart                                 # Textos acessíveis de foto, avatares, pré-visualização, remoção e erros
│   ├── services/
│   │   └── ambiente/
│   │       └── composicao.dart                                # Injetar FotoDePerfilDoAparelho + registrar em LimpezaDeSessao (dadosDoAparelho)
│   └── features/
│       ├── autenticacao/presentation/
│       │   └── fluxo_autenticacao.dart                        # Repassar fotoDePerfil (+ opcional seletorDeImagem) para TelaPerfil
│       └── perfil/
│           ├── domain/
│           │   ├── retrato_de_perfil.dart                     # RetratoDePerfil (FotoPropria / AvatarIlustrado), AvatarIlustrado, PoliticaDeImagemDePerfil
│           │   └── processador_de_imagem.dart                 # Validação binária/15MB, bakeOrientation, crop 1:1 <=512px, JPEG sem EXIF
│           ├── data/
│           │   ├── foto_de_perfil_local.dart                  # ArmazenamentoDeFotoDePerfil, FotoDePerfilLocal (DadoLocalDoAparelho), FotoDePerfilEmMemoria
│           │   └── seletor_de_imagem.dart                     # SeletorDeImagemDoAparelho (image_picker + android_intent_plus + exceções mapeadas)
│           └── presentation/
│               ├── tela_perfil.dart                           # Substitui MemoraPersonagem do cabeçalho pela SecaoFotoPerfil / RetratoDoPerfil
│               ├── secao_foto_perfil.dart                     # Controle completo (folha FR-004, grade avatares, remoção, avisos FR-011, guarda FR-012)
│               ├── tela_pre_visualizacao_foto.dart            # Pré-visualização "Usar esta foto" / "Escolher outra"
│               └── widgets/
│                   └── retrato_do_perfil.dart                 # Círculo com foto própria, avatar ilustrado ou Retrato Padrão (iniciais/silhueta)
└── test/
    └── features/
        ├── autenticacao/
        │   └── saida_limpa_armazenamento_test.dart            # Provar que saída comum mantém foto e esquecerTudo apaga tudo
        └── perfil/
            ├── processador_de_imagem_test.dart                # Validação de formato, >15MB, crop 1:1 <=512px, remoção comprovada de EXIF/GPS
            ├── foto_de_perfil_local_test.dart                 # Isolamento por conta, fallback se arquivo sumiu, limpeza total
            └── foto_perfil_widget_test.dart                   # US1, US2, US3, concorrência, acessibilidade 200%, 3 temas + atualização de tela_perfil_test.dart
```

---

## Complexity Tracking

Nenhuma violação à Constituição ou exceção arquitetural é necessária:
- Zero endpoints ou migrations de backend adicionais.
- Zero novas credenciais ou armazenamento sensível fora da sandbox privada do aplicativo.
- Reutilização integral dos padrões de `DadoLocalDoAparelho`, `Composicao`, `FolhaInferior`, `ConfirmacaoMemora` e `SecaoIdade`.
