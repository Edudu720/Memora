---

description: "Lista de tarefas executável para redesenho visual, padronização profissional e ditado por voz seguro na Feature 007"
---

# Tarefas: Redesenho Visual, Padronização Profissional e Voz na Conversa

**Entrada**: Documentos de design em `specs/007-redesenho-visual-profissional/` ([plan.md](file:///c:/Users/Edu/Documents/Memora/specs/007-redesenho-visual-profissional/plan.md), [spec.md](file:///c:/Users/Edu/Documents/Memora/specs/007-redesenho-visual-profissional/spec.md), [research.md](file:///c:/Users/Edu/Documents/Memora/specs/007-redesenho-visual-profissional/research.md), [data-model.md](file:///c:/Users/Edu/Documents/Memora/specs/007-redesenho-visual-profissional/data-model.md), [design-system-redesign.md](file:///c:/Users/Edu/Documents/Memora/specs/007-redesenho-visual-profissional/contracts/design-system-redesign.md), [telas-padronizacao.md](file:///c:/Users/Edu/Documents/Memora/specs/007-redesenho-visual-profissional/contracts/telas-padronizacao.md), [quickstart.md](file:///c:/Users/Edu/Documents/Memora/specs/007-redesenho-visual-profissional/quickstart.md))  
**Branch**: `feature/007-redesenho-visual-profissional`  
**Organização**: Setup e Fundação de Tokens (bloqueantes), seguidos pelas Histórias de Usuário em ordem de prioridade (`P1`: US1, US2, US3, US4, US6 -> `P2`: US5, US7) e Fechamento Global (Documentação Viva, Portões Estáticos/Testes, Álbum nos 3 temas e APK Release).

## Formato: `- [ ] [ID] [P?] [Story?] Descrição com caminho exato de arquivo`

- **[P]**: Pode rodar em paralelo (arquivos distintos, sem dependência de tarefa incompleta)
- **[Story]**: História de usuário associada (`[US1]` a `[US7]`, omitida apenas em Setup, Foundational e Polish)
- **Portões Obrigatórios**: Zero literais visuais fora de `app/lib/design_system/tokens/` (`validar_tokens.py`) e contraste WCAG 2.2 AA (`>= 4.5:1` / `>= 3.0:1`) / AAA Alto Contraste (`>= 7.0:1`) em todas as 13 combinações (`validar_paleta.py`).

---

## Phase 1: Setup & Verificação de Linha de Base

**Objetivo**: Confirmar que os assets oficiais do mascote, portões estáticos e suíte de linha de base estão íntegros antes de alterar tokens e telas.

- [X] T001 Verificar a presença dos 6 PNGs oficiais do mascote (`memora_perfil_robo.png`, `memora_ajuda_robo.png`, `memora_dica_robo.png`, `memora_conclusao_robo.png`, `memora_alerta_robo.png`, `memora_mini_robo.png`) em `app/assets/ilustracoes/` e declaração em `app/pubspec.yaml`
- [X] T002 [P] Executar linha de base de auditoria de tokens via `python specs/002-design-system/ferramentas/validar_tokens.py` e `--autoteste` usando `specs/002-design-system/ferramentas/validar_tokens.py`
- [X] T003 [P] Executar linha de base de auditoria de contraste via `python specs/002-design-system/ferramentas/validar_paleta.py` e `--autoteste` usando `specs/002-design-system/ferramentas/validar_paleta.py`
- [X] T004 Executar suíte inicial do Design System e Acessibilidade via `flutter test test/design_system/ test/acessibilidade/` no diretório `app/` para registrar linha de base verde

---

## Phase 2: Foundational (Tokens 2.0 & Portões WCAG — Bloqueante para Todas as Histórias)

**Objetivo**: Atualizar todos os tokens visuais (`MemoraCores`, `MemoraRaio`, `MemoraElevacao`, `MemoraDimensoes`, `TemasMemora`) e expandir os validadores WCAG (`validar_paleta.py` e `contraste_test.dart`) antes de modificar qualquer componente ou tela.

**⚠️ CRÍTICO**: Nenhuma história de usuário visual (`Phase 3+`) pode começar antes de este checkpoint passar com `0` falhas de contraste.

- [X] T005 Atualizar `MemoraCores` em `app/lib/design_system/tokens/cores.dart` com canvas `fundo` (`#F4F6FA` claro, `#0F141E` escuro, `#000000` altoContraste), `superficie` (`#FFFFFF` claro, `#182030` escuro, `#0A0A0A` altoContraste), `superficieSutil` (`#EEF2FA` claro, `#222C40` escuro, `#141414` altoContraste), `superficieBarra` (`#FFFFFF` claro, `#161E2C` escuro, `#000000` altoContraste), `bordaSutil` (`#E2E8F0` claro, `#2B364B` escuro, `#FFFFFF` altoContraste — `1 px` decorativo no Claro/Escuro e `>= 3:1` no Alto Contraste), `borda` mantido (`>= 3.0:1` contra `fundo` e `superficie`), `gradienteHeroiInicio` (`#155EEF` claro, `#1E40AF` escuro, igual a `primaria` no AC), `gradienteHeroiFim` (`#0B3BC2` claro, `#162E7A` escuro, igual a `primaria` no AC), `sobreGradienteHeroi` (`#FFFFFF` claro/escuro, igual a `sobrePrimaria` no AC — `>= 4.5:1` / `7.0:1` AC em ambos os stops), `gradienteSaudeInicio` (`#0E7490` claro, `#0F5266` escuro, igual a `primaria` no AC), `gradienteSaudeFim` (`#155EEF` claro, `#183C8C` escuro, igual a `primaria` no AC), `sobreGradienteSaude` (`#FFFFFF` claro/escuro, igual a `sobrePrimaria` no AC — `>= 4.5:1` / `7.0:1` AC em ambos os stops), `saudeSuave` (`#E6F6F4` claro, `#123532` escuro, `#0A0A0A` altoContraste) e `sucessoTexto` (`#0F6A43` claro, `#6EE7B7` escuro, `#80FFAA` altoContraste — `>= 4.5:1` sobre `superficie` e `saudeSuave`), além de atualizar `copyWith` e `lerp`
- [X] T006 Estender `PaletaDeDestaque`, o mapa `paletas` (`azul`, `verde`, `roxo`, `laranja-terra`, `rosa`, `grafite`) e `comPaleta(...)` em `app/lib/design_system/tokens/cores.dart` com `superficieSutilClaro`, `superficieSutilEscuro`, `gradienteHeroiInicioClaro`, `gradienteHeroiInicioEscuro`, `gradienteHeroiFimClaro`, `gradienteHeroiFimEscuro`, `sobreGradienteHeroiClaro` e `sobreGradienteHeroiEscuro`, preservando isolamento total no modo `altoContraste` (depende de T005)
- [X] T007 [P] Atualizar `MemoraRaio` em `app/lib/design_system/tokens/raio.dart` adicionando `cartaoDestaque = 24.0` (mantendo `cartao = 24.0`), `cartaoMedio = 20.0` e `badge = 14.0`
- [X] T008 [P] Atualizar `MemoraElevacao` em `app/lib/design_system/tokens/elevacao.dart` adicionando `sombraCartaoDifusa` (`blur 16, offset (0, 4)`), `sombraContato` (`blur 3, offset (0, 1)`), `sombraBarra` (`blur 20, offset (0, -4)`), `listaSombrasCartao(MemoraCores cores)` (duas camadas Claro/Escuro, lista vazia em `altoContraste`) e `listaSombrasBarra(MemoraCores cores)`
- [X] T009 [P] Atualizar `MemoraDimensoes` em `app/lib/design_system/tokens/dimensoes.dart` adicionando `badgeAtalhoRapido = 48.0`, `espessuraBordaSutil = 1.0` e `indicadorAtivoBarra = 3.0`
- [X] T010 Ajustar `TemasMemora` em `app/lib/design_system/temas/temas_memora.dart` para refletir `cores.fundo`, superfícies limpas de `CardTheme`/`BottomSheetTheme` e separadores `cores.bordaSutil` (depende de T005–T009)
- [X] T011 Atualizar `TEMAS`, `PALETAS` e `PARES` em `specs/002-design-system/ferramentas/validar_paleta.py` para auditar todas as 13 combinações (claro × 6 paletas, escuro × 6 paletas, alto contraste) validando `sobre_gradiente_heroi` contra ambos os stops do gradiente herói, `sobre_gradiente_saude` contra ambos os stops do gradiente saúde, `texto` sobre `superficie_sutil`, `primaria` sobre `superficie_barra` e `sucesso_texto` sobre `superficie` e `saude_suave` (depende de T005–T006)
- [X] T012 Espelhar todos os novos pares de contraste em `app/test/design_system/contraste_test.dart` e validar que `python specs/002-design-system/ferramentas/validar_paleta.py`, `--autoteste` e `flutter test test/design_system/contraste_test.dart` retornam saída `0` (depende de T010–T011)

**Checkpoint**: Tokens 2.0 validados matematicamente nos 3 temas × 6 paletas — histórias do Design System e telas liberadas.

---

## Phase 3: User Story 1 — Identidade Visual Profissional, Separação Informação vs Ação e DS 2.0 (Priority: P1) 🎯 MVP

**Goal**: Eliminar contornos de wireframe (`#6B6B6B`) em cartões passivos e a barra inferior cinza (`#D8D8D8`), entregando os componentes base evoluídos e os 6 novos blocos do Design System respeitando estritamente `002/FR-012` (informação nunca vira botão) e `FR-004` (3 destinos fixos na barra inferior).

**Independent Test**: Abrir `GaleriaMemora` nos 3 modos e rodar `flutter test test/design_system/` (incluindo `informacao_nao_e_acao_test.dart`, `area_toque_test.dart`, `escala_texto_test.dart`, `caixa_de_etapa_test.dart`, `galeria_completa_test.dart`), confirmando cartões passivos não clicáveis, cards acionáveis com pista explícita + semântica de botão e zero overflow até `200%`.

- [X] T013 [P] [US1] Evoluir `Cartao` em `app/lib/design_system/componentes/cartoes/cartao.dart` mantendo assinatura retrocompatível (`const Cartao({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(MemoraEspacamento.lg), bool comBorda = false, super.key})`) e **estritamente não clicável (sem `aoTocar`, `002/FR-012`)**, aplicando `cores.superficie`, `MemoraRaio.cartao`, `MemoraElevacao.listaSombrasCartao(cores)` no Claro, `bordaSutil` (`1 px`) no Escuro e `Border.all(color: cores.borda, width: MemoraDimensoes.bordaEnfase)` automaticamente em `altoContraste` ou quando `comBorda == true`
- [X] T014 [P] [US1] Evoluir `CaixaDeEtapa` em `app/lib/design_system/componentes/cartoes/caixa_de_etapa.dart` preservando `const CaixaDeEtapa({required String instrucao, required Widget child, super.key})` e `Semantics(container: true, explicitChildNodes: true)` com leitura de `instrucao` antes do `child` (sem callback de toque), substituindo a faixa `#D8D8D8` + contorno `#6B6B6B` por `cores.superficie`, sombra difusa, cabeçalho tonal `cores.superficieSutil` e separador `1 px` `cores.bordaSutil` (revertendo para `cores.borda` no Alto Contraste)
- [X] T015 [P] [US1] Evoluir `DestaqueInformacao` e `ListaInformacao` em `app/lib/design_system/componentes/informacao/destaque_informacao.dart` e `app/lib/design_system/componentes/informacao/lista_informacao.dart` para adotar superfícies elevadas limpas sem borda pesada de wireframe no Claro/Escuro (mantendo não-interatividade e borda no Alto Contraste)
- [X] T016 [P] [US1] Modernizar `NavegacaoInferior` em `app/lib/design_system/componentes/navegacao/navegacao_inferior.dart` mantendo exatamente os **3 destinos fixos (`Ajustes`, `Início`, `Meu perfil`)**, usando `cores.superficieBarra`, separador superior `cores.bordaSutil` (`1 px`), `MemoraElevacao.listaSombrasBarra(cores)`, pílula tonal envolvente em `cores.destaque`, barra superior `MemoraDimensoes.indicadorAtivoBarra` em `cores.primaria`, ícone + rótulo visíveis em todos os itens, alvo `>= 48x48 dp` e altura mínima `>= 56 dp` seguro a `200%` em `320 px`
- [X] T017 [P] [US1] Modernizar `CabecalhoDeTela` e `BarraSuperior` em `app/lib/design_system/componentes/navegacao/cabecalho_de_tela.dart` e `app/lib/design_system/componentes/navegacao/barra_superior.dart` sobre canvas `cores.fundo`, botão `"Voltar"` em pílula tonal sutil (`Icon + Texto >= 48 dp`), tipografia `MemoraTipografia.tituloSecao`/`tituloTela` e slot opcional para `ExpressaoDaMemora.mini`
- [X] T018 [P] [US1] Criar componente **estritamente não clicável (sem `aoTocar`, `002/FR-012`)** `PainelHeroi` em `app/lib/design_system/componentes/informacao/painel_heroi.dart` (`String titulo`, `String? valorDestaque` com `MemoraTipografia.destaque` tabular, `Widget? badgeStatus`, `Widget? visualEsquerda`, `Widget? rodape`), com `LinearGradient(gradienteSaudeInicio -> gradienteSaudeFim)` (sólido no AC), texto em `sobreGradienteSaude` e `MemoraRaio.cartaoDestaque`
- [X] T019 [P] [US1] Criar componente **estritamente interativo** `CartaoHeroi` em `app/lib/design_system/componentes/cartoes/cartao_heroi.dart` (`required String titulo`, `String? subtitulo`, `required String rotuloAcao`, `IconData? icone`, `Widget? visualEsquerda`, `required VoidCallback aoTocar`, `Semantics(button: true)`), com `LinearGradient(gradienteHeroiInicio -> gradienteHeroiFim)` (sólido no AC), texto `sobreGradienteHeroi` em `MemoraTipografia.tituloSecao` + `apoio`, `MemoraRaio.cartaoDestaque` e **pista visual explícita obrigatória de ação (pílula/botão + ícone de seta `>= 4.5:1`)**
- [X] T020 [P] [US1] Criar componente `TileAcaoRapida` em `app/lib/design_system/componentes/cartoes/tile_acao_rapida.dart` (`required IconData icone`, `required String titulo`, `String? subtitulo`, `required VoidCallback? aoTocar`, `VarianteBadge variacao` (`primario | saude | alerta | neutro`), `String? pistaAcao`), com `cores.superficie`, `MemoraRaio.cartaoMedio`, badge quadrado `MemoraDimensoes.badgeAtalhoRapido` (`48.0`, `MemoraRaio.badge`), `MemoraTipografia.corpoForte` + `apoio`, contorno tonal (`bordaSutil` ou `borda` no AC) e **pista explícita de ação (`Icons.arrow_forward_rounded` / `pistaAcao` + semântica de botão)** quando interativo
- [X] T021 [P] [US1] Criar `ChipFiltro` em `app/lib/design_system/componentes/selecao/chip_filtro.dart` (`selecionado`, `rotulo`, `icone`, `aoTocar`, `minHeight >= 48 dp`, `MemoraTipografia.apoio` em negrito e alto contraste ativo)
- [X] T022 [P] [US1] Criar `BadgeDeStatus` em `app/lib/design_system/componentes/informacao/badge_de_status.dart` (**estritamente informativo, sem callback de toque**, `MemoraTipografia.apoio` com piso `16 sp`, `saudeSuave` + `sucessoTexto` ou tokens semânticos) e `LinhaDeLista` em `app/lib/design_system/componentes/informacao/linha_de_lista.dart` (`Widget? esquerda`, `required String titulo` em `corpoForte`, `String? subtitulo` em `apoio`, `VoidCallback? aoTocar` — exibindo `Icons.chevron_right_rounded` + `SuperficieTocavel >= 48 dp` quando `aoTocar != null`, e puramente informativa sem chevron/handler quando `aoTocar == null`)
- [X] T023 [US1] Reexportar `painel_heroi.dart`, `cartao_heroi.dart`, `tile_acao_rapida.dart`, `chip_filtro.dart`, `badge_de_status.dart` e `linha_de_lista.dart` em `app/lib/design_system/design_system.dart` (depende de T018–T022)
- [X] T024 [US1] Atualizar `GaleriaMemora` em `app/lib/design_system/galeria/galeria_memora.dart` para demonstrar os componentes evoluídos e todos os 6 novos blocos nos 3 temas (depende de T023)
- [X] T025 [US1] Atualizar e expandir `app/test/design_system/informacao_nao_e_acao_test.dart` (verificando explicitamente que `Cartao`, `PainelHeroi`, `BadgeDeStatus`, `CaixaDeEtapa` e `LinhaDeLista(aoTocar: null)` NÃO possuem ação de toque), `app/test/design_system/area_toque_test.dart`, `app/test/design_system/escala_texto_test.dart`, `app/test/design_system/caixa_de_etapa_test.dart` e `app/test/design_system/galeria_completa_test.dart` e executar `flutter test test/design_system/` em `app/` (depende de T013–T024)

**Checkpoint**: User Story 1 completa — Design System 2.0 limpo, FR-012 garantido por teste e validado na Galeria.

---

## Phase 4: User Story 2 — Mascote Memora Unificado e Ilustrações Coesas (Priority: P1)

**Goal**: Unificar o vocabulário ilustrativo do app em torno das 6 artes PNG oficiais do robô Memora sem quebrar nenhum consumidor atual de `ExpressaoDaMemora`, integrando medalhões, estados vazios/erro e cartões ilustrativos.

**Independent Test**: Renderizar todas as 6 variantes de `ExpressaoDaMemora` (`neutra`, `falando`, `comemorando`, `preocupada`, `dica`, `mini`) na `GaleriaMemora` e validar `ilustracao_e_destaque_test.dart`, `cartao_de_porta_test.dart`, `cabecalho_de_tela_test.dart` e `galeria_completa_test.dart` nos 3 temas.

- [X] T026 [US2] Expandir `ExpressaoDaMemora` e `MemoraPersonagem` em `app/lib/design_system/componentes/ilustracao/memora_personagem.dart` mantendo os 4 membros existentes intactos (`neutra` -> `memora_perfil_robo.png`, `falando` -> `memora_ajuda_robo.png`, `comemorando` -> `memora_conclusao_robo.png`, `preocupada` -> `memora_alerta_robo.png`), acrescentando **apenas `dica` (`assets/ilustracoes/memora_dica_robo.png`) e `mini` (`assets/ilustracoes/memora_mini_robo.png`)**, e preservando o medalhão/fundo claro nos modos escuro e alto contraste
- [X] T027 [P] [US2] Atualizar `MedalhaoDeIlustracao` e `AvatarMemora` em `app/lib/design_system/componentes/ilustracao/medalhao_de_ilustracao.dart` e `app/lib/design_system/componentes/ilustracao/avatar_memora.dart` alinhando o fundo tonal (`cores.superficieSutil` / `cores.medalhao`) sem contorno grosseiro
- [X] T028 [P] [US2] Padronizar `EstadoVazio` e `MensagemErro` em `app/lib/design_system/componentes/feedback/estado_vazio.dart` e `app/lib/design_system/componentes/feedback/mensagem_erro.dart` com `ExpressaoDaMemora.falando` e `ExpressaoDaMemora.preocupada` em composição limpa (`covid-19...avif`) sem caixas pesadas
- [X] T029 [P] [US2] Modernizar `CartaoDePorta` e `CartaoComAvatar` em `app/lib/design_system/componentes/cartoes/cartao_de_porta.dart` e `app/lib/design_system/componentes/cartoes/cartao_com_avatar.dart` com badges vetoriais limpos e pista de ação explícita (preservando chaves e rótulo+ícone)
- [X] T030 [US2] Atualizar `GaleriaMemora` em `app/lib/design_system/galeria/galeria_memora.dart` para exibir todas as **6 expressões PNG do robô Memora** (`neutra`, `falando`, `comemorando`, `preocupada`, `dica`, `mini`) com seus rótulos (depende de T026)
- [X] T031 [US2] Atualizar e executar `app/test/design_system/ilustracao_e_destaque_test.dart`, `app/test/design_system/cartao_de_porta_test.dart`, `app/test/design_system/cabecalho_de_tela_test.dart` e `app/test/design_system/galeria_completa_test.dart` cobrindo as 6 expressões (`dica` e `mini` incluídas) via `flutter test test/design_system/` em `app/` (depende de T026–T030)

**Checkpoint**: User Story 2 completa — mascote PNG unificado em todo o Design System sem regressões.

---

## Phase 5: User Story 3 — Casca Principal (`3 abas`), `Início` e `Hub` Modernos e Responsivos (Priority: P1)

**Goal**: Redesenhar `CascaInterna`, `TelaInicio` e `TelaHub` mantendo os **3 destinos fixos** (`Ajustes`, `Início`, `Meu perfil`), aplicando `CartaoHeroi` `"Conversar com a Memora"` e grade `2x2` responsiva de `TileAcaoRapida` com adaptação automática para 1 coluna em `320 px` ou `>= 1.5x`.

**Independent Test**: Rodar `flutter test test/features/casca/ test/features/inicio/ test/features/hub/ test/acessibilidade/hub_cabe_sem_rolar_test.dart test/acessibilidade/hub_acessibilidade_test.dart`, validando ZERO overflow em `320×568 @ 200%` e `TelaHub` cabendo sem rolagem em `360×800 @ 1.0x`.

- [X] T032 [US3] Atualizar `CascaInterna` em `app/lib/features/casca/casca_interna.dart` garantindo canvas `cores.fundo` contínuo e integração com a `NavegacaoInferior` elevada mantendo `DestinoDaCasca` (`ajustes`, `inicio`, `perfil`) e `CascaInterna.chaveDaBarra` intactos (depende de T016)
- [X] T033 [US3] Redesenhar `TelaInicio` em `app/lib/features/inicio/presentation/tela_inicio.dart` com saudação `"Oi, [Nome]!"` + `ExpressaoDaMemora.mini`, balão de boas-vindas sem wireframe, `CartaoHeroi` (`"Conversar com a Memora"`, pista `"Começar conversa"` centralizada em `app/lib/l10n/textos_assistente.dart`), grade `2x2` com `LayoutBuilder` + `textScalerOf` (colapsando para `1` coluna em `320 px` ou `>= 1.5x`) de `TileAcaoRapida` (`Meus aplicativos`, `Serviços sociais`, `Cuidado`, `Ajuda`) e resumo limpo do último acesso preservando todas as chaves de navegação e acessibilidade (depende de T019, T020, T026)
- [X] T034 [US3] Redesenhar `TelaHub` em `app/lib/features/hub/presentation/telas/tela_hub.dart` com `CartaoHeroi`, grade `2x2` de `TileAcaoRapida` / `CartaoDePorta` modernizado e ações secundárias calibradas para passar sem rolagem em `360×800 @ 1.0x` (depende de T019, T020, T029)
- [X] T035 [US3] Executar e ajustar caso chaves/expectativas visuais tenham evoluído `app/test/features/inicio/inicio_ocupa_a_altura_test.dart`, `app/test/features/inicio/tela_inicio_test.dart`, `app/test/features/hub/tela_hub_test.dart`, `app/test/acessibilidade/hub_cabe_sem_rolar_test.dart`, `app/test/acessibilidade/hub_acessibilidade_test.dart` e `app/test/features/casca/casca_interna_test.dart` via `flutter test` em `app/` (depende de T032–T034)

**Checkpoint**: User Story 3 completa — navegação em 3 abas, `Início` e `Hub` modernos e validados.

---

## Phase 6: User Story 4 — Conversa Segura (`_ExplicacaoDoAceite`, `AvisoCompacto`, Sugestões 2x2 e Ditado por Voz `FR-013`) (Priority: P1)

**Goal**: Elevar a tela de conversa ao padrão dos mockups `fkhvix`/`design-1`, preservando a tela prévia obrigatória `_ExplicacaoDoAceite` (`Emenda 1`), pílula antigolpe não-dispensável, balões limpos e **ditado por voz completo e seguro (`FR-013`)** que explica a permissão antes do pedido ao Android e preenche somente o rascunho sem envio automático.

**Independent Test**: Rodar testes unitários/widget do ditado por voz (`ditado_por_voz_test.dart` com `FakeLeitorDeVoz`) + `aviso_compacto_test.dart`, `balao_de_fala_test.dart`, `balao_de_fala_escrita_test.dart`, `conversa_acessibilidade_test.dart`, `sem_campo_de_segredo_test.dart`, `sem_backup_test.dart` e `test/features/assistente/`.

- [X] T036 [US4] Adicionar `speech_to_text: ^7.3.0` em `app/pubspec.yaml`, executar `flutter pub get` em `app/`, declarar `<uses-permission android:name="android.permission.RECORD_AUDIO"/>` e `<queries><intent><action android:name="android.speech.RecognitionService"/></intent></queries>` em `app/android/app/src/main/AndroidManifest.xml`, e validar que `flutter test test/services/seguranca/sem_backup_test.dart` continua verde
- [X] T037 [P] [US4] Criar contrato de domínio `EstadoDitado` (`ocioso`, `aguardandoPermissao`, `ouvindo`, `indisponivel`, `erro`), `ResultadoDitado` e interface abstrata `LeitorDeVoz` (`verificarDisponibilidade()`, `iniciarEscuta({required void Function(String textoParcial) aoReconhecer})`, `pararEscuta()`, `dispose()`) em `app/lib/features/assistente/domain/leitor_de_voz.dart` [NOVO]
- [X] T038 [US4] Implementar `LeitorDeVozSpeechToText` em `app/lib/features/assistente/data/leitor_de_voz_nativo.dart` [NOVO] encapsulando `speech_to_text` com preferência `pt_BR`, sem gravar arquivos de áudio em disco e sem registrar fala em logs de produção (depende de T036, T037)
- [X] T039 [P] [US4] Evoluir `AvisoCompacto` em `app/lib/design_system/componentes/avisos/aviso_compacto.dart` para pílula limpa de segurança no topo da conversa quando `fechadoEmUmaLinha == true` (`"Eu nunca peço sua senha nem código"`, escudo em `cores.perigo`, fundo `cores.superficie`, altura tocável `>= 48 dp` para expandir texto completo), preservando `fechadoSoEscudo`, `titulo` e proibição total de dispensa
- [X] T040 [P] [US4] Evoluir `BalaoDeFala` em `app/lib/design_system/componentes/conversa/balao_de_fala.dart` substituindo borda de wireframe por `cores.superficie` + `MemoraElevacao.listaSombrasCartao(cores)` com `ExpressaoDaMemora.mini` na esquerda (Memora) e `cores.superficieSutil` na direita (Pessoa), preservando `AutorDoBalao`, negrito `**`, escrita gradual e rótulos TalkBack
- [X] T041 [US4] Integrar suporte limpo de rascunho/ditado por voz opcional em `ControladorConversa` em `app/lib/features/assistente/presentation/controladores/controlador_conversa.dart` (garantindo retrocompatibilidade com assinaturas existentes, mantendo `AceiteDoAviso` obrigatório e preenchendo somente o rascunho via `escrever(...)` com zero envio automático — depende de T037)
- [X] T042 [US4] Redesenhar `TelaConversa` em `app/lib/features/assistente/presentation/telas/tela_conversa.dart` seguindo o fluxo em 3 estados (centralizando os novos rótulos em `app/lib/l10n/textos_assistente.dart`): (1) quando `precisaDoAceite == true`, exibir primeiro `_ExplicacaoDoAceite` com o novo visual limpo preservando `chaveAceite`, `chaveAceitar` e `chaveRecusarAceite`; (2) após aceite sem mensagens, exibir cabeçalho com `ExpressaoDaMemora.mini`, `AvisoCompacto`, recepção com `ExpressaoDaMemora.falando` e grade `2x2` responsiva (`2->1` col em `320 px`/`>= 1.5x`) de sugestões; (3) na conversa ativa, posicionar `AvisoCompacto` em pílula no topo, balões limpos e barra inferior elevada (`cores.superficieBarra`) com `CampoTexto` (`chaveCampo`), pílula `"Perguntar"` (`chaveEnviar`) e botão acessível de microfone (`>= 48x48 dp`, ícone + texto `"Falar"` / `"Parar"`, diálogo prévio explicando a permissão de microfone em português simples antes de solicitar ao SO, estado visual/semântico claro de escuta, fallback amigável quando negado/indisponível mantendo teclado livre e nunca enviando sem toque manual em `"Perguntar"`) — depende de T038–T041
- [X] T043 [US4] Criar testes dedicados de ditado por voz (`FakeLeitorDeVoz`) em `app/test/features/assistente/ditado_por_voz_test.dart` [NOVO] cobrindo explicação prévia à permissão, alternância `"Falar"`/`"Parar"`, preenchimento exclusivo do rascunho sem auto-envio, envio manual em `"Perguntar"` e fallback gracioso quando negado/indisponível (depende de T042)
- [X] T044 [US4] Atualizar e validar `app/test/design_system/aviso_compacto_test.dart`, `app/test/design_system/balao_de_fala_test.dart`, `app/test/design_system/balao_de_fala_escrita_test.dart`, `app/test/design_system/area_toque_test.dart`, `app/test/acessibilidade/conversa_acessibilidade_test.dart`, `app/test/features/casca/sem_campo_de_segredo_test.dart` e toda a pasta `app/test/features/assistente/` via `flutter test` em `app/` (depende de T042–T043)

**Checkpoint**: User Story 4 completa — consentimento prévio, proteção antigolpe, conversa editorial e ditado por voz seguro (`FR-013`) 100% funcionais e testados.

---

## Phase 7: User Story 6 — Dashboard Profissional de Cuidado & Saúde IoT (Priority: P1)

**Goal**: Transformar o módulo `Cuidado` em painel moderno de saúde (`7fe4db...webp` + `covid-19...avif`): **`PainelHeroi` não clicável** em gradiente de Saúde com BPM em destaque tabular, grade `2x2` de `TileAcaoRapida`/vitais com pistas de ação explícitas, detalhes técnicos MQTT recolhidos e tela de queda de alto contraste.

**Independent Test**: Rodar `flutter test test/features/cuidado/`, validando todos os estados do controlador (`conectado`, `desconectado`, `bpmValido == false` exibindo `-- BPM`, clique em `PainelHeroi` ignorado por `informacao_nao_e_acao`, queda e contato de emergência) sem bordas de wireframe nem overflow a `200%`.

- [X] T045 [P] [US6] Redesenhar `MedidorBpm` em `app/lib/features/cuidado/presentation/widgets/medidor_bpm.dart` removendo `Border.all(color: cores.borda)` no Claro/Escuro (preservando no Alto Contraste), usando `Cartao` limpo com badge tonal `cores.saudeSuave`, `BadgeDeStatus` e `FontFeature.tabularFigures()`
- [X] T046 [P] [US6] Redesenhar `IndicadorMovimento` em `app/lib/features/cuidado/presentation/widgets/indicador_movimento.dart` e `CronometroRegressivoQueda` em `app/lib/features/cuidado/presentation/widgets/cronometro_regressivo_queda.dart` eliminando contornos amadores e padronizando badges semânticos com `BadgeDeStatus` e alto contraste
- [X] T047 [US6] Redesenhar `TelaDispositivoCuidado` em `app/lib/features/cuidado/presentation/telas/tela_dispositivo_cuidado.dart` utilizando **`PainelHeroi` (não clicável, gradiente de Saúde)** no topo com `BadgeDeStatus` do vínculo, BPM em destaque tabular e resumo de movimento; grade `2x2` responsiva (`2->1` col) com vitais e `TileAcaoRapida` explícitos (`Medir BPM`, `Movimento`, `Contato de emergência`, `Histórico recente`); e detalhes técnicos de broker/tópico MQTT em painel recolhível discreto `"Detalhes técnicos do aparelho"` (com textos centralizados em constante/módulo local ou `l10n`), preservando chaves dos testes (depende de T018, T020, T022, T045, T046)
- [X] T048 [US6] Redesenhar `TelaVerificacaoQueda` e `DialogoContatoEmergencia` em `app/lib/features/cuidado/presentation/telas/tela_verificacao_queda.dart` e `app/lib/features/cuidado/presentation/telas/dialogo_contato_emergencia.dart` com layout centrado (`covid-19...avif` + `ExpressaoDaMemora.preocupada`), `CronometroRegressivoQueda` em destaque e botões em pílula grandes (`>= 56 dp`, `"Estou bem"` / `"Pedir ajuda agora"`) (depende de T026, T046)
- [X] T049 [US6] Executar e validar `flutter test test/features/cuidado/` no diretório `app/` garantindo cobertura de UI, queda, emergência e `PainelHeroi` não interativo (depende de T047–T048)

**Checkpoint**: User Story 6 completa — todas as histórias `P1` concluídas e verificadas.

---

## Phase 8: User Story 5 — Catálogo de Apps, Serviços Sociais, Módulos e Passo a Passo Editorial (Priority: P2)

**Goal**: Elevar `TelaCatalogo`, `TelaRegistro`, `TelaSeletorDeSecao`, `IndicadorDePasso`, `PassoIlustrado` e `TelaPassoAPasso` para estética editorial limpa, destacando os guias ilustrados corrigidos na feature 006.

**Independent Test**: Rodar `flutter test test/features/assistente/ test/features/aprendizado/ test/design_system/passo_ilustrado_test.dart test/acessibilidade/catalogo_acessibilidade_test.dart test/acessibilidade/registro_acessibilidade_test.dart` sem regressões nem overflow até `200%`.

- [X] T050 [US5] Redesenhar `TelaCatalogo` em `app/lib/features/assistente/presentation/telas/tela_catalogo.dart` com busca limpa no topo, `ChipFiltro` segmentado (`Apps do celular` | `Serviços sociais`), cartões horizontais brancos sem borda pesada com logo oficial em badge suave, descrição concisa, `BadgeDeStatus` não clicável `"✓ Eu te ensino e posso abrir"` e botões explícitos de ensinar/abrir com confirmação externa preservada (depende de T013, T021, T022)
- [X] T051 [P] [US5] Redesenhar `TelaRegistro` em `app/lib/features/assistente/presentation/telas/tela_registro.dart` agrupando o histórico em `Cartao` limpo com `LinhaDeLista` (com seta apenas nos itens acionáveis) em vez de caixas bordadas repetitivas (depende de T013, T022)
- [X] T052 [P] [US5] Redesenhar `TelaSeletorDeSecao` em `app/lib/features/aprendizado/presentation/tela_seletor_de_secao.dart` usando cabeçalho do app/serviço com `BadgeDeStatus` de progresso + `ExpressaoDaMemora.dica` + lista de módulos em `LinhaDeLista` com badges circulares numerados (depende de T022, T026)
- [X] T053 [P] [US5] Refinar `IndicadorDePasso` e `PassoIlustrado` em `app/lib/design_system/componentes/guia/indicador_de_passo.dart` e `app/lib/design_system/componentes/guia/passo_ilustrado.dart` eliminando contornos duros ao redor das capturas e aplicando `MemoraRaio.cartao` + sombra difusa `MemoraElevacao.listaSombrasCartao(cores)`
- [X] T054 [US5] Redesenhar `TelaPassoAPasso` em `app/lib/features/aprendizado/presentation/tela_passo_a_passo.dart` integrando `IndicadorDePasso`, `PassoIlustrado` protagonista, texto editorial em `AtkinsonHyperlegibleNext`, tela de conclusão com `ExpressaoDaMemora.comemorando` e barra fixa inferior em `cores.superficieBarra` com `"Anterior"` / `"Próximo"` (depende de T026, T053)
- [X] T055 [US5] Executar `flutter test test/features/assistente/ test/features/aprendizado/ test/design_system/passo_ilustrado_test.dart test/acessibilidade/catalogo_acessibilidade_test.dart test/acessibilidade/registro_acessibilidade_test.dart` em `app/` garantindo `100%` de aprovação (depende de T050–T054)

**Checkpoint**: User Story 5 completa — catálogo, registro, módulos e guias passo a passo da feature 006 totalmente padronizados.

---

## Phase 9: User Story 7 — Apresentação, Autenticação, Ajuda, Configurações, Aparência e Perfil Padronizados (Priority: P2)

**Goal**: Alinhar todas as telas restantes (`apresentacao`, `autenticacao`, `ajuda`, `configuracoes`, `tela_aparencia` e `perfil` incluindo `SecaoIdade`) à estética editorial limpa (`design-1`/`design-2`), mantendo `CaixaDeEtapa` acima de cada campo e todos os avisos antigolpe/segurança.

**Independent Test**: Rodar `flutter test test/features/apresentacao/ test/features/autenticacao/ test/features/ajuda/ test/features/configuracoes/ test/features/perfil/ test/design_system/preferencias/` garantindo `100%` de aprovação sem regressão de fluxo ou chaves.

- [X] T056 [P] [US7] Redesenhar `FluxoApresentacao` em `app/lib/features/apresentacao/presentation/fluxo_apresentacao.dart` e `TelaBoasVindas` em `app/lib/features/autenticacao/presentation/telas/tela_boas_vindas.dart` com layout editorial espaçoso, `ExpressaoDaMemora.neutra` e `ExpressaoDaMemora.dica`, indicadores de página em pílula e CTA ancorado no rodapé cabendo em `320×568` e `360×800` (depende de T026)
- [X] T057 [P] [US7] Padronizar widgets de segurança da autenticação (`AvisoAntigolpe` em `app/lib/features/autenticacao/presentation/widgets/aviso_antigolpe.dart`, `RegrasDeSenha` em `app/lib/features/autenticacao/presentation/widgets/regras_de_senha.dart` e `SaidaComConfirmacao` em `app/lib/features/autenticacao/presentation/widgets/saida_com_confirmacao.dart`) com `BadgeDeStatus` e `Cartao` limpo preservando contraste e avisos antigolpe (depende de T013, T022)
- [X] T058 [US7] Padronizar as telas de autenticação (`tela_login.dart`, `tela_cadastro.dart`, `tela_recuperacao.dart`, `tela_confirmar_canal.dart`, `tela_de_volta.dart`, `tela_entrega_do_aparelho.dart`, `tela_primeira_entrada.dart`) em `app/lib/features/autenticacao/presentation/telas/` usando `CaixaDeEtapa` evoluída (T014), cabeçalhos limpos e espaçamento editorial preservando todas as `Key`s e fluxo de validação (depende de T014, T056, T057)
- [X] T059 [P] [US7] Redesenhar telas de Ajuda (`tela_ajuda.dart`, `tela_assunto.dart`, `ajuda_guiada_da_conversa.dart`) em `app/lib/features/ajuda/presentation/` usando banner acolhedor com `ExpressaoDaMemora.falando` + listas limpas com `LinhaDeLista` e `Cartao` (depende de T013, T022, T026)
- [X] T060 [P] [US7] Redesenhar Configurações e Aparência (`tela_configuracoes.dart`, `tela_conta.dart`, `tela_privacidade.dart` em `app/lib/features/configuracoes/presentation/` e `tela_aparencia.dart` em `app/lib/design_system/preferencias/tela_aparencia.dart`) agrupando opções com `LinhaDeLista` dentro de `Cartao` limpo e preview interativo atualizado dos 3 temas × 6 paletas (depende de T010, T013, T022)
- [X] T061 [P] [US7] Redesenhar Perfil e Idade (`tela_perfil.dart`, `tela_data_de_nascimento.dart`, `secao_idade.dart`) em `app/lib/features/perfil/presentation/` com `ExpressaoDaMemora.neutra`, cartões brancos limpos e controles padronizados (depende de T013, T026)
- [X] T062 [US7] Executar `flutter test test/features/apresentacao/ test/features/autenticacao/ test/features/ajuda/ test/features/configuracoes/ test/features/perfil/ test/design_system/preferencias/` em `app/` garantindo `100%` de aprovação (depende de T058–T061)

**Checkpoint**: Todas as 7 Histórias de Usuário concluídas — 100% das telas do aplicativo unificadas sob o mesmo Design System 2.0.

---

## Phase 10: Polish, Documentação Viva, Portões Globais, Álbum & APK Release (`SC-001`–`SC-006`)

**Objetivo**: Atualizar a documentação viva exigida pela Constituição, passar todos os portões globais estáticos e automatizados, regenerar e inspecionar o álbum de telas nos 3 modos e compilar o APK de release limpo.

- [X] T063 [P] Atualizar documentação viva criando `CHANGELOG.md` na raiz do repositório (com entrada da Feature 007) e atualizando `docs/design/como-usar-o-design-system.md` (documentando Tokens 2.0, `PainelHeroi`, `CartaoHeroi`, `TileAcaoRapida`, `ChipFiltro`, `BadgeDeStatus`, `LinhaDeLista`, `ExpressaoDaMemora.dica`/`mini` e ditado por voz `FR-013`)
- [X] T064 [P] Executar auditoria global de literais visuais via `python specs/002-design-system/ferramentas/validar_tokens.py` e `--autoteste` garantindo saída `0` (`SC-001`)
- [X] T065 [P] Executar auditoria global de contraste WCAG 2.2 AA/AAA via `python specs/002-design-system/ferramentas/validar_paleta.py` e `--autoteste` garantindo saída `0` (`SC-002`)
- [X] T066 Executar análise estática completa (`flutter analyze`) em `app/` garantindo zero erros e zero avisos novos (`SC-003`)
- [ ] T067 Executar toda a suíte automatizada (`flutter test`) em `app/` garantindo `100%` de aprovação sem testes pulados (`SC-004`, inclui `ditado_por_voz_test.dart`, `informacao_nao_e_acao_test.dart`, `hub_cabe_sem_rolar_test.dart`, `sem_campo_de_segredo_test.dart` e `sem_backup_test.dart`)
- [X] T068 Atualizar e executar `app/test/album/album_de_telas_test.dart` gerando capturas completas nos 3 modos (`Claro`, `Escuro`, `Alto Contraste`) e inspecioná-las visualmente frente às 6 referências de `Memora-Desing-Ideias/` (`SC-005`, `SC-006`)
- [X] T069 Compilar e validar o build final via `flutter build apk --release` em `app/`, confirmando geração limpa de `app/build/app/outputs/flutter-apk/app-release.apk` sem erros (`SC-006`)

---

## Dependências & Ordem de Execução

### Dependências entre Fases

```text
Phase 1 (Setup)
   └─> Phase 2 (Foundational: Tokens 2.0 + validar_paleta) [BLOQUEANTE]
          ├─> Phase 3 (US1: Componentes Base DS, PainelHeroi/CartaoHeroi, 3 abas, Galeria) [MVP]
          └─> Phase 4 (US2: Mascote Unificado 6 PNGs + Ilustrações)
                 └─> Ambas destravam em paralelo:
                        ├─> Phase 5 (US3: Casca 3 abas, Início, Hub) [P1]
                        ├─> Phase 6 (US4: Conversa, Aceite prévio, AvisoCompacto, Voz FR-013) [P1]
                        ├─> Phase 7 (US6: Cuidado IoT com PainelHeroi + Queda) [P1]
                        ├─> Phase 8 (US5: Catálogo, Registro, Módulos, Passo a Passo) [P2]
                        └─> Phase 9 (US7: Apresentação, Auth, Ajuda, Ajustes, Perfil + SecaoIdade) [P2]
                               └─> Phase 10 (Documentação Viva, Portões Globais, Álbum & APK Release)
```

### Independência entre Histórias

- **US1 (P1 — MVP)** e **US2 (P1)** dependem apenas de **Phase 2 (`Foundational`)**.
- **US3 (P1)** depende dos blocos base de US1 (`NavegacaoInferior`, `CartaoHeroi`, `TileAcaoRapida`) e `ExpressaoDaMemora.mini` (US2).
- **US4 (P1)** inclui toda a infraestrutura de voz (`speech_to_text`, `AndroidManifest.xml`, `LeitorDeVoz`, `LeitorDeVozSpeechToText`, `ditado_por_voz_test.dart`) dentro de si mesma para poder ser desenvolvida e testada independentemente após US1/US2.
- **US6 (P1)** depende de `PainelHeroi`, `TileAcaoRapida`, `BadgeDeStatus` (US1) e `ExpressaoDaMemora.preocupada` (US2), permanecendo independente de US3/US4/US5/US7.
- **US5 (P2)** e **US7 (P2)** são independentes entre si e de US3/US4/US6.

### Exemplo de Execução Paralela — Phase 3 (`US1`) e Phase 6 (`US4`)

```text
# US1 em paralelo após Phase 2:
Paralelo Lote A (Evolução):  T013 (Cartao), T014 (CaixaDeEtapa), T015 (Destaque/Lista), T016 (NavegacaoInferior), T017 (Cabecalho/Barra)
Paralelo Lote B (Novos DS):  T018 (PainelHeroi), T019 (CartaoHeroi), T020 (TileAcaoRapida), T021 (ChipFiltro), T022 (Badge/LinhaDeLista)
Fechamento US1:              T023 -> T024 -> T025

# US4 em paralelo após US1/US2:
Base paralela:               T036 (pubspec/Manifest voice) -> T038 (LeitorDeVozSpeechToText)
Simultâneo a T036/T038:      T037 (domain LeitorDeVoz), T039 (AvisoCompacto), T040 (BalaoDeFala)
Integração & Verificação:    T041 -> T042 -> T043 -> T044
```

---

## Estratégia de Implementação (MVP Primeiro & Entregas Incrementais)

1. **MVP Base (`Phase 1` + `Phase 2` + `Phase 3 [US1]` + `Phase 4 [US2]`)**: Transforma Tokens 2.0, `GaleriaMemora` e os 6 PNGs oficiais com auditoria WCAG passando (`0` falhas) antes de redesenhar as telas.
2. **Core Crítico (`Phase 5 [US3]` + `Phase 6 [US4]` + `Phase 7 [US6]`)**: Redesenha Casca (`3 abas`), `Início`, `Hub`, `Conversa` (preservando `_ExplicacaoDoAceite`, `AvisoCompacto` e entregando o ditado por voz `FR-013`) e `Cuidado` (`PainelHeroi` não clicável).
3. **Cobertura Completa & Release (`Phase 8 [US5]` + `Phase 9 [US7]` + `Phase 10`)**: Padroniza Catálogo, Guias da feature 006, Onboarding, Autenticação, Ajuda, Ajustes e Perfil, atualiza `CHANGELOG.md`/`docs/`, valida o álbum nos 3 temas e gera `app-release.apk`.
