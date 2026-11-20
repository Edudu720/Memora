# Implementation Plan: Ajustes Pós-Redesenho — Issue #106 (@Du3101)

**Branch**: `feature/016-ajustes-pos-redesenho` | **Date**: 2026-11-19 | **Spec**: [spec.md](file:///c:/Users/Eduardo/Memora/specs/016-ajustes-pos-redesenho/spec.md)

**Input**: Feature specification from `/specs/016-ajustes-pos-redesenho/spec.md` (esclarecida em 2026-11-19 com `Q1: A, Q2: A, Q3: A` e alinhada na [Issue #106](https://github.com/Edudu720/Memora/issues/106#issuecomment-7021833862)).

---

## Summary

Consolidar no aplicativo móvel Memora as cinco entregas atribuídas a `@Du3101` após o redesenho final (#105):

1. **Dispositivo de Cuidado sem Wokwi (Itens 7 e 8)**: corrigir `ControladorDispositivoCuidado.simularQuedaTeste()` para abrir a verificação de queda também com `ProvedorDeTelemetriaMqtt` (ESP32 físico) ativo, protegido contra duplo toque, com teste dedicado que reprova com o defeito original e remoção das menções residuais ao simulador aposentado Wokwi.
2. **Retratos de Meu Perfil com fallback seguro (Item 9)**: remover `AvatarIlustrado.casalIdoso` e `AvatarIlustrado.pessoaComCelular` da seleção em `SecaoFotoPerfil`/`AvatarIlustrado` mantendo `FotoDePerfilLocal` e `RetratoDoPerfil` resilientes (retorno automático ao retrato padrão neutro ao ler chaves legadas).
3. **Capturas reais e SVGs dos 7 guias (Itens 5 e 6, `Q2: A`)**: converter as 66 capturas higienizadas em `apps/` (`Meu INSS`, `TikTok`, `CNH/Carteira Digital`, `Carteira de Trabalho`, `Poupatempo`, `YouTube` e `Google Fotos`) para WebP qualidade 92 em `app/assets/guias/<chave>/`, adotar `SecaoDoGuia` nos guias longos (> 7 passos), medir `RegiaoRelativa` sobre imagem limpa, atualizar `CAPTURAS.md`, elevar o orçamento total de `app/assets/guias/` para `12 MB` sem alterar ativos de colegas e adicionar os 7 SVGs compartilhados em `app/assets/icones_apps/<chave>.svg` em `IconeDoAplicativo`.
4. **Melhoria visual e otimização de Meu Perfil (Item 10, `Q1: A`)**: reorganizar `TelaPerfil` em cartões claros por tema (*Seu retrato*, *Sua conta*, *Seu aprendizado*, além de `SecaoIdade`), com carregamento 100% local instantâneo, guarda contra troca rápida de conta, zero chamadas de rede e espaço opcional compatível com `ultimoModuloConcluido` (Item 14).
5. **Acesso seguro `https://` ao site de tutoriais na Ajuda (Item 11, `Q3: A`)**: estender `Ambiente.urlSiteTutorial` (reaproveitando `Ambiente.enderecoOficial`), criar `AbridorDeSiteTutorial` e adicionar em `TelaAjuda` um botão com confirmação modal rolável obrigatória antes de abrir o navegador externo — permanecendo oculto automaticamente até a URL oficial de produção ser configurada.

---

## Technical Context

**Language/Version**: Dart 3.13.5 (`sdk: ^3.11.4`), Flutter 3.47.7 (canal stable), Python 3.11+ (ferramentas de auditoria e conversão de imagens).  
**Primary Dependencies**: `flutter_svg: ^2.0.17`, `url_launcher: ^6.3.1`, `mqtt_client: ^10.3.3`, `shared_preferences: ^2.5.5`, `path_provider: ^2.1.5` (todas já declaradas em `app/pubspec.yaml`; nenhuma dependência nova necessária).  
**Storage**: Somente armazenamento local existente no aparelho (`SharedPreferences` e diretório privado de suporte para `FotoDePerfilLocal`, arquivo local `progresso_de_aprendizado.json`, ativos embarcados `assets/guias/` e `assets/icones_apps/`). Nenhuma mudança de esquema no backend nesta feature (`Q2: A`).  
**Testing**: `flutter analyze`, `flutter test` (`flutter_test`, mocks/simulados em memória de `ProvedorDeTelemetria`, `FotoDePerfilEmMemoria`, `AbridorDeSiteTutorialSimulado`, testes de contrato em `catalogo_e_guias_test.dart`) e `py specs/002-design-system/ferramentas/validar_tokens.py`.  
**Target Platform**: Android (API configurada em `app/android/`, `<queries>` Android 11+) e runtime de testes Flutter em Windows.  
**Project Type**: Aplicativo móvel multiplataforma (`app/`) dentro de monorepo com especificações (`specs/`).  
**Performance Goals**: Abertura instantânea da `TelaPerfil` com **0 chamadas de rede** e indexação `O(1)` de nome de guia; resposta da ação *"Simular queda"* em < 1 s mesmo com broker offline; teto total de `app/assets/guias/` em **12 MB** (~10,94 MB medidos para todos os 16 guias).  
**Constraints**: Conformidade integral com Design System 2.0 (zero literais em `validar_tokens.py`), WCAG 2.2 AA/AAA (contraste 4,5:1 / 3:1, alvos >= 48×48 dp, escala de fonte até `200%` sem overflow em `320×568`), texto `<= 2` frases curtas com zero emojis e gênero neutro (`.claude/skills/memora-ux/SKILL.md`), protocolo estrito `https://` fixo no build, zero exposição de PII nas capturas, paridade estrita entre catálogo conectado e offline.  
**Scale/Scope**: 66 capturas reais em 7 guias (4 com seções `SecaoDoGuia`, 3 lineares), 7 ícones SVG novos em `app/assets/icones_apps/`, 5 telas/componentes principais (`ControladorDispositivoCuidado`/`TelaDispositivoCuidado`, `RetratoDePerfil`/`SecaoFotoPerfil`, `TelaPerfil`, `IconeDoAplicativo`, `TelaAjuda`).

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio Constitucional | Verificação Pré-Design | Reavaliação Pós-Design (Phase 1) |
|---|---|---|
| **I. Modelagem de Ameaças (Security by Design)** | Vetores mapeados em `spec.md`: link externo (`https://`), reentrância/disparo acidental de SOS, PII em capturas e dados locais de Perfil. | **Aprovado**: `Ambiente.enderecoOficial` bloqueia `http://`, `userInfo`, espaços e URL dinâmica; `AbridorDeSiteTutorial.abrir()` não recebe parâmetros; simulação de queda cancelável com `"Estou bem"` sem disparar emergência; 66 capturas higienizadas e senhas vazias; zero rede em `TelaPerfil`. |
| **II. Engenharia Social e Proteção** | Pergunta *"Como um golpista tentaria explorar esta tela?"* respondida para todas as telas alteradas. | **Aprovado**: botão do site na Ajuda oculto se sem URL oficial; quando ativo, exibe diálogo modal explícito com o domínio completo antes de deixar o app (`0%` saída ao primeiro toque). |
| **III. Acessibilidade Sênior (`WCAG 2.2 AA/AAA` + `memora-ux`)** | Alvos `>= 48×48 dp` (`56 dp` em botões principais), espaçamento `8 dp`, texto `<= 2` frases, zero emojis, sem cor isolada e zoom `200%`. | **Aprovado**: diálogo modal usa `AlertDialog(scrollable: true)` para evitar overflow a `200%` em `320×568`; `TelaPerfil` mantém campos não clicáveis (`isButton: false`); SVGs vetoriais nítidos >= 3:1; `validar_tokens.py` com 0 literais. |
| **IV. Spec antes do Código** | Especificação `016-ajustes-pos-redesenho` criada, esclarecida (`Q1: A, Q2: A, Q3: A`) e validada (16/16) antes do plano e tarefas. | **Aprovado**: alterações em contratos documentadas (`contracts/`, atualizações explícitas em `CAPTURAS.md` e `specs/004-redesenho-das-telas/contracts/guias.md`). |
| **V. Arquitetura Limpa & Injeção de Dependências** | Separação `domain`/`data`/`presentation`, abstrações simuláveis (`ProvedorDeTelemetria`, `ArmazenamentoDeFotoDePerfil`, `AbridorDeSiteTutorial`) e composição em `Composicao`. | **Aprovado**: `AbridorDeSiteTutorial` desacoplado via interface + simulado em `ajuda/data/`; `TelaPerfil` mantém `0` imports de rede; `SecaoFotoPerfil` e `ControladorDispositivoCuidado` injetáveis em teste. |
| **VI. IA Nunca Age Sozinha** | Escopo não amplia autonomia da IA; toda saída externa do usuário exige confirmação explícita. | **Aprovado**: confirmação explícita do usuário em *"Sim, abrir o site"* (Ajuda) e *"Estou bem"* (Verificação de queda). |
| **VII. Ensinar, Não Substituir** | Capturas reais + destaques relativos reforçam aprendizado autônomo em apps cotidianos e serviços sensíveis com aviso de senha oficial. | **Aprovado**: todas as capturas sensíveis mantêm `precisaTerEmMaos` e aviso de senha; acesso ao site complementar na Ajuda educa sem substituir o app. |

---

## Project Structure

### Documentation (this feature)

```text
specs/016-ajustes-pos-redesenho/
├── spec.md                       # Especificação funcional e critérios de aceitação (16/16 pronta)
├── plan.md                       # Este arquivo (/speckit-plan)
├── research.md                   # Decisões arquiteturais R1–R7 (Phase 0)
├── data-model.md                 # Entidades, estados e invariantes (Phase 1)
├── quickstart.md                 # Roteiro executável de verificação (Phase 1)
├── tasks.md                      # Lista executável de tarefas (/speckit-tasks)
├── checklists/
│   ├── requirements.md           # Checklist de qualidade da especificação (16/16)
│   └── revisao-pr.md             # Checklist de revisão pré-PR dos requisitos (24/24)
└── contracts/
    ├── icones-e-guias.md         # Contrato compartilhado SVGs em icones_apps/ e guias WebP q92
    └── ajuda-e-perfil.md         # Contrato UI/segurança de Ajuda, Meu Perfil e Simulação de Queda
```

### Source Code (repository root)

```text
app/
├── pubspec.yaml                                         # Remover comentário Wokwi; declarar assets/icones_apps/
├── android/app/src/main/AndroidManifest.xml             # Intent query https para url_launcher em Android 11+
├── assets/
│   ├── icones_apps/                                     # [NOVO] 7 ícones SVG oficiais (@Du3101, Item 6)
│   │   ├── meu-inss.svg
│   │   ├── tiktok.svg
│   │   ├── carteira-digital.svg
│   │   ├── carteira-de-trabalho.svg
│   │   ├── poupatempo.svg
│   │   ├── youtube.svg
│   │   └── google-fotos.svg
│   └── guias/
│       ├── CAPTURAS.md                                  # Registro atualizado dos 7 guias + teto 12 MB
│       ├── meu-inss/                                    # passo_1..19.webp
│       ├── tiktok/                                      # passo_1..6.webp
│       ├── carteira-digital/                            # passo_1..10.webp
│       ├── carteira-de-trabalho/                        # passo_1..10.webp
│       ├── poupatempo/                                  # passo_1..10.webp
│       ├── youtube/                                     # passo_1..7.webp
│       └── google-fotos/                                # passo_1..4.webp
├── lib/
│   ├── main.dart                                        # Passar abridorSiteTutorial para FluxoAutenticacao
│   ├── design_system/componentes/ilustracao/
│   │   └── icone_do_aplicativo.dart                     # Carregar SVGs de assets/icones_apps/ via SvgPicture.asset
│   ├── l10n/
│   │   ├── textos_ajuda.dart                            # Textos do botão, confirmação modal e erro do site tutorial
│   │   ├── textos_guias.dart                            # Textos, descrições e seções dos 7 guias reais
│   │   └── textos_perfil.dart                           # Remover rótulos de retratos aposentados; textos dos cartões
│   ├── services/ambiente/
│   │   ├── ambiente.dart                                # Campo urlSiteTutorial via MEMORA_URL_SITE_TUTORIAL
│   │   └── composicao.dart                              # Instanciar AbridorDeSiteTutorial.doAmbiente(ambiente)
│   └── features/
│       ├── ajuda/
│       │   ├── data/abridor_site_tutorial.dart          # [NOVO] Interface + UrlLauncher + Simulado
│       │   └── presentation/tela_ajuda.dart             # _CartaoSiteTutorial + modal rolável com aviso https://
│       ├── aprendizado/
│       │   ├── domain/guia.dart                         # Constantes CapturaDoGuia para 66 capturas dos 7 guias
│       │   └── data/guias/
│       │       ├── meu_inss.dart                        # Refeito em SecaoDoGuia (19 telas)
│       │       ├── tiktok.dart                          # 6 telas reais medidas
│       │       ├── carteira_digital.dart                # Refeito em SecaoDoGuia (10 telas)
│       │       ├── carteira_de_trabalho.dart            # Refeito em SecaoDoGuia (10 telas)
│       │       ├── poupatempo.dart                      # Refeito em SecaoDoGuia (10 telas)
│       │       ├── youtube.dart                         # 7 telas reais medidas
│       │       └── google_fotos.dart                    # 4 telas reais medidas
│       ├── autenticacao/presentation/
│       │   └── fluxo_autenticacao.dart                  # Injetar abridorSiteTutorial em TelaAjuda
│       ├── cuidado/
│       │   ├── domain/entidades/enums_cuidado.dart      # Remover comentário Wokwi
│       │   ├── domain/repositorios/provedor_telemetria.dart # Remover comentário Wokwi
│       │   └── presentation/
│       │       ├── controladores/controlador_dispositivo_cuidado.dart # Corrigir simularQuedaTeste() + guarda
│       │       └── telas/tela_dispositivo_cuidado.dart  # Trava _verificacaoQuedaAberta anti-duplicação
│       └── perfil/
│           ├── domain/retrato_de_perfil.dart            # Remover casalIdoso e pessoaComCelular de AvatarIlustrado
│           └── presentation/
│               ├── widgets/retrato_do_perfil.dart       # DesenhoAvatarIlustrado só para 4 avatares da Memora
│               └── tela_perfil.dart                     # Reorganização em cartões, O(1), slot ultimoModuloConcluido
└── test/
    ├── design_system/icone_do_aplicativo_test.dart      # [NOVO/ATUALIZADO] Carregamento dos 7 SVGs + fallback
    └── features/
        ├── ajuda/tela_ajuda_test.dart                   # Oculto sem URL, diálogo modal, cancelar, confirmar, erro
        ├── aprendizado/catalogo_e_guias_test.dart       # Atualizar teto para 12 MB + conferir seções/capturas
        ├── autenticacao/saida_limpa_armazenamento_test.dart # Atualizar fixture de avatar para chave válida
        ├── cuidado/presentation/tela_dispositivo_cuidado_test.dart # Teste que reprova com bug original no MQTT
        └── perfil/
            ├── foto_de_perfil_local_test.dart           # Fallback de casal_idoso / pessoa_com_celular -> null
            ├── foto_perfil_widget_test.dart             # 4 avatares na grade + fallback legado seguro
            └── tela_perfil_test.dart                    # Cartões, zero rede, 200% em 320×568, ultimoModuloConcluido

specs/004-redesenho-das-telas/contracts/guias.md         # Nota do teto atualizado de 8 MB para 12 MB
```

**Structure Decision**: Toda a implementação ocorre dentro da estrutura Clean/Feature-first existente em `app/` (respeitando `domain`, `data`, `presentation`, `design_system`, `l10n` e `services`), sem criar projetos paralelos e isolando inteiramente arquivos de outros colaboradores (`e-titulo`, `fgts`, `instagram`, `whatsapp`, `facebook`, `telegram`, `gov-br`, `serasa`, `correios`).

---

## Complexity Tracking

> Nenhuma violação constitucional necessária. O único ajuste de parâmetro herdado de spec anterior está justificado abaixo por medição em disco:

| Ajuste de Regra Herdada | Motivo | Alternativa Mais Simples Rejeitada Porque |
|---|---|---|
| Teto de `app/assets/guias/`: **`8 MB` → `12 MB`** (em `catalogo_e_guias_test.dart`, `CAPTURAS.md` e `specs/004-redesenho-das-telas/contracts/guias.md`) | Os 9 guias existentes já ocupam `7,78 MB` (só `instagram` usa `2,28 MB`); as 66 capturas WebP q92 adicionam `~3,18 MB`, totalizando `~10,94 MB` nos 16 guias e deixando ~1 MB de margem. | Recomprimir `instagram`, `gov-br` ou `serasa` invadiria arquivos de outros colaboradores (`#106` Itens 1 e 13); degradar q92 abaixo de 75 comprometeria nitidez dos textos ao ampliar. |
