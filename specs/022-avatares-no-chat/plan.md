# Implementation Plan: Avatares da Memora e da Pessoa Usuária no Chat

**Branch**: `feature/022-avatares-no-chat` | **Date**: 2026-11-22 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/022-avatares-no-chat/spec.md`

## Summary

Corrigir a interface da conversa (`TelaConversa`) para restaurar o padrão visual ilustrado na tela demonstrativa (*Passo 2 de 5*), exibindo o rosto mini da Memora à esquerda de cada balão da assistente e o retrato de perfil selecionado em Meu Perfil à direita de cada balão `"Você"`. A arquitetura preserva a fronteira entre Design System e módulos de domínio: `BalaoDeFala` passa a aceitar um `Widget? avatarPessoa` desacoplado e controle `rostoAnimado`, enquanto `ArmazenamentoDeFotoDePerfil` expõe um fluxo reativo local (`alteracoes`) para que `TelaConversa` reflita em tempo real foto própria, avatar ilustrado ou padrão neutro sem chamadas de rede, sem vazamento de imagens entre contas, com recuo automático em ampliação `>= 175%` e mantendo apenas a Memora do cabeçalho superior animada.

## Technical Context

**Language/Version**: Dart / Flutter (SDK `3.47.7` no CI)  
**Primary Dependencies**: Flutter Material, Design System próprio (`app/lib/design_system/`), `shared_preferences`, `path_provider` (sem novas dependências no `pubspec.yaml`)  
**Storage**: Somente armazenamento local no aparelho já existente (`FotoDePerfilLocal` — índice em `SharedPreferences` por conta e arquivos JPEG sanitizados `1:1` sem EXIF/GPS em `fotos_perfil/`, além de `FotoDePerfilEmMemoria` para testes e demonstração); zero persistência no servidor  
**Testing**: `flutter test` (`flutter_test`), `flutter analyze`, `python specs/002-design-system/ferramentas/validar_tokens.py`, `python specs/002-design-system/ferramentas/validar_paleta.py`  
**Target Platform**: Android (aparelhos de entrada a intermediários, largura `320×568` a `412×915`)  
**Project Type**: Mobile app modular (Feature-First + Clean Architecture em `app/lib/`)  
**Performance Goals**: Zero novos `AnimationController`s rodando por item na lista do chat (`rostoAnimado: false` nos balões); leitura assíncrona local única ao abrir ou quando houver evento em `alteracoes`, sem travar rolagem nem digitação em aparelhos Galaxy A/M  
**Constraints**: Contraste WCAG 2.2 AA/AAA nos 3 temas e 6 paletas; zero literais visuais fora de `design_system/tokens/` (`FR-032` / `validar_tokens.py`); TalkBack sem duplicidade (`ExcludeSemantics`); ampliação até `200%` sem overflow (`escala >= 1.75` oculta avatares laterais dos balões)  
**Scale/Scope**: Correção focal envolvendo Design System (`BalaoDeFala`), armazenamento local do Perfil (`ArmazenamentoDeFotoDePerfil`), injeção de fluxo (`FluxoAutenticacao`), conversa (`TelaConversa`) e reconciliação de testes automatizados; zero alterações em `backend/`, `site/` ou contratos OpenAPI.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Segurança Acima de Tudo**: APROVADO. Retrato próprio local nunca é enviado ao backend nem à API do Gemini; isolado por `idDaConta` codificado com `contaSegura` e removido no `esquecerDoAparelho`.
- **II. Segurança Contra Engenharia Social**: APROVADO. Avisos antigolpe e de privacidade da conversa permanecem intactos no topo; posição lateral (Memora à esquerda / pessoa à direita), moldura circular de perfil e rótulos escritos (`"Memora"` / `"Você"`) impedem confusão de identidade mesmo quando a pessoa escolhe avatar ilustrado da Memora no Perfil.
- **III. Acessibilidade (`memora-ux`)**: APROVADO. Contraste herdado de `RetratoDoPerfil` e `MemoraPersonagem`; `ExcludeSemantics` nos avatares decorativos evita anúncios repetidos no TalkBack; ocultamento automático para `escala >= MemoraDimensoes.escalaTextoAlta` (`1.75`) garante uso completo a `200%` em `320×568`; `rostoAnimado: false` respeita movimento reduzido sem tickers extras.
- **IV. Especificação Antes de Código**: APROVADO. Spec (`spec.md`), plano (`plan.md`), pesquisa (`research.md`), modelo de dados (`data-model.md`), contrato UI (`contracts/avatares-conversa-ui.md`) e tarefas (`tasks.md`) completos antes de alterar qualquer código.
- **V. Arquitetura Limpa e Feature-First**: APROVADO. `design_system/` não importa `features/perfil/`; o retrato entra via slot `Widget? avatarPessoa` injetado por `TelaConversa`.
- **VI. A IA Nunca Age Sozinha & VII. Ensinar, Não Substituir**: N/A (sem alteração de fluxo autônomo nem ações da IA; apenas fidelidade visual e de identidade do usuário).

*Reavaliação pós-Phase 1*: Todas as decisões mantiveram zero acoplamento indevido, zero novos literais visuais e zero impacto em rotas/APIs externas.

## Project Structure

### Documentation (this feature)

```text
specs/022-avatares-no-chat/
├── spec.md                              # Especificação funcional e critérios mensuráveis
├── plan.md                              # Este plano técnico
├── research.md                          # Decisões arquiteturais (D1–D5) e análise do código atual
├── data-model.md                        # Modelo de dados local e estado de retrato no chat
├── quickstart.md                        # Roteiro de validação automatizada e visual
├── checklists/
│   └── requirements.md                  # Checklist de qualidade da especificação
├── contracts/
│   └── avatares-conversa-ui.md          # Contrato de interfaces entre BalaoDeFala, Perfil e TelaConversa
└── tasks.md                             # Lista ordenada e rastreável de tarefas
```

### Source Code (repository root)

```text
app/
├── lib/
│   ├── design_system/
│   │   └── componentes/conversa/
│   │       └── balao_de_fala.dart                         # Adiciona `avatarPessoa` e `rostoAnimado` (sem importar features)
│   └── features/
│       ├── perfil/
│       │   ├── data/
│       │   │   └── foto_de_perfil_local.dart              # Adiciona stream reativo `alteracoes` em ArmazenamentoDeFotoDePerfil
│       │   └── presentation/widgets/
│       │       └── retrato_do_perfil.dart                 # Protege ajuste proporcional das iniciais em 40 dp sob escala 150%
│       ├── autenticacao/
│       │   └── presentation/
│       │       └── fluxo_autenticacao.dart                # Repassa `_fotos`, `idDaConta` e `nomeTratamento` em `_abrirConversa`
│       └── assistente/
│           └── presentation/telas/
│               └── tela_conversa.dart                     # Carrega/assina retrato local e liga `comRosto` com `rostoAnimado: false`
└── test/
    ├── design_system/
    │   ├── balao_de_fala_test.dart                        # Cobre `avatarPessoa` customizado e `rostoAnimado: false`
    │   └── icones_e_toque_test.dart                       # Atualiza regra de única Memora animada na BarraSuperior vs balões estáticos
    ├── features/
    │   ├── perfil/
    │   │   └── foto_de_perfil_local_test.dart             # Testa emissão em `alteracoes` (salvarFoto, salvarAvatar, apagar, esquecer)
    │   └── assistente/
    │       ├── memora_no_topo_da_conversa_test.dart       # Reconcilia asserções de `comRosto` vs Memora viva única no topo
    │       ├── tela_conversa_test.dart                    # Reconcilia L227–242 com avatares estáticos nos balões da conversa
    │       └── avatares_da_conversa_test.dart             # Novo: foto própria, 4 avatares, iniciais/fallback, live update, troca de conta e matriz 4×3 a 200%

specs/
└── 013-redesenho-final/
    └── spec.md                                            # Nota de revisão formal da FR-042 remetendo à spec 022
CHANGELOG.md                                               # Registro da correção visual na entrega 022
```

**Structure Decision**: Manter o módulo móvel modular Feature-First existente em `app/lib/`, preservando o isolamento de `design_system/` (recebendo o retrato já pronto como `Widget?`) e adicionando fluxo de eventos no repositório de retrato (`ArmazenamentoDeFotoDePerfil`) seguindo exatamente a convenção consolidada por `ProgressoDeAprendizado` na feature `020`.

## Complexity Tracking

Nenhuma violação da Constituição. Todos os mecanismos reutilizam componentes, tokens e padrões arquiteturais já presentes no repositório.
