# Pesquisa Técnica e Decisões Arquiteturais: Ajustes Pós-Redesenho (`016`)

**Feature**: `016-ajustes-pos-redesenho` | **Branch**: `feature/016-ajustes-pos-redesenho` | **Data**: 2026-11-19  
**Spec**: [spec.md](spec.md)

---

## R1 — `ControladorDispositivoCuidado.simularQuedaTeste()` com ESP32/MQTT e remoção do Wokwi (Itens 7 e 8)

- **Achado no código atual**:
  - `ControladorDispositivoCuidado` (`app/lib/features/cuidado/presentation/controladores/controlador_dispositivo_cuidado.dart:20`) inicializa com `ProvedorDeTelemetriaMqtt()` por padrão (`ModoOperacaoIot.mqtt`).
  - `simularQuedaTeste()` (linhas 133–137) verifica `if (_provedorAtual is ProvedorDeTelemetriaSimulado)` e não faz nada nos outros casos. Assim, com o provedor ESP32/MQTT ativo, tocar em *"Simular queda"* (`tela_dispositivo_cuidado.dart:513-517`) não gera feedback nem abre a verificação de queda.
  - Quatro comentários residuais com *"Wokwi"* permanecem no módulo do aplicativo: `enums_cuidado.dart:33`, `provedor_telemetria.dart:6`, `controlador_dispositivo_cuidado.dart:93` e `app/pubspec.yaml:74` (nenhuma ocorrência em textos visíveis de `l10n/`).
- **Decisão**:
  - Quando `_provedorAtual` for `ProvedorDeTelemetriaSimulado`, `simularQuedaTeste()` continua delegando para `_provedorAtual.simularQueda()`.
  - Para qualquer outro provedor (como `ProvedorDeTelemetriaMqtt`, esteja conectado ou desconectado), `simularQuedaTeste()` instancia `EventoQueda.novo(bpm: _dispositivo.ultimaTelemetria?.bpm ?? 72, aceleracao: 2.8)`, atribui `_quedaAtiva` e chama `notifyListeners()`.
  - Adicionar **guarda contra reentrância** (`if (_quedaAtiva != null) return;`) no controlador e trava `_verificacaoQuedaAberta` em `TelaDispositivoCuidado` ao abrir `TelaVerificacaoQueda` (`Navigator.push(...).whenComplete(...)`), evitando múltiplas telas empilhadas em toques duplos rápidos.
  - Manter `ProvedorDeTelemetriaMqtt.enviarComandoCessarAlarme()` seguro como *no-op* quando desconectado (comportamento já presente na linha 199), garantindo que responder *"Estou bem"* funcione mesmo sem broker ativo no momento do teste.
  - Remover as 4 menções residuais a *"Wokwi"* nos arquivos Dart e `pubspec.yaml`, atualizando comentários para refletir exclusivamente o ESP32 físico via MQTT e o simulador local.
- **Justificativa**: Não depende de publicar mensagem de ida e volta num broker externo nem de o ESP32 físico estar conectado na bancada para validar o fluxo de verificação ("Você está bem?"), eliminando qualquer falha silenciosa em menos de 1 segundo e preservando os fluxos de `ControladorVerificacaoQueda` e `DispararSocorroEmergencia`.
- **Alternativas consideradas**:
  - *Publicar evento simulado no tópico MQTT*: rejeitado porque falha ou trava quando o usuário está sem rede ou sem broker configurado, violando US1 (Cenário 3) e SC-001.
  - *Exibir erro bloqueando a simulação no modo MQTT*: rejeitado porque impede testar a tela de verificação de queda quando o aparelho físico é o padrão do aplicativo.

---

## R2 — Remoção dos retratos `casalIdoso` e `pessoaComCelular` em Meu Perfil com fallback seguro (Item 9)

- **Achado no código atual**:
  - `AvatarIlustrado` (`app/lib/features/perfil/domain/retrato_de_perfil.dart:17-60`) define 6 opções: 4 poses da Memora (`memoraAcenando`, `memoraPensando`, `memoraComemorando`, `memoraProtegendo`) mais `casalIdoso` (`'casal_idoso'`) e `pessoaComCelular` (`'pessoa_com_celular'`).
  - `FotoDePerfilLocal.ler()` (`foto_de_perfil_local.dart:104-106`) resolve a chave lida com `AvatarIlustrado.porChave(chave)` e devolve `null` quando a chave não existe. `RetratoDoPerfil` trata `null` renderizando `_padraoNeutro` (iniciais do nome ou ícone neutro).
  - As ilustrações gerais `Ilustracao.casalIdoso`, `Ilustracao.pessoaComCelular` e os arquivos SVG `app/assets/ilustracoes/casal_idoso.svg` e `pessoa_com_celular.svg` são utilizados em outras áreas não relacionadas à escolha de retrato (`TelaConta`, `AssuntoDeAjuda`, `CartaoComAvatar`, `AvatarMemora`, `GaleriaMemora`).
- **Decisão**:
  - Remover `casalIdoso` e `pessoaComCelular` apenas de `AvatarIlustrado` (`retrato_de_perfil.dart`), de `DesenhoAvatarIlustrado` (`retrato_do_perfil.dart` — convertendo o `switch` para exaustivo sobre as 4 poses de `MemoraAnimada`) e das constantes não utilizadas `TextosPerfil.avatarCasalIdoso` / `TextosPerfil.avatarPessoaComCelular` (`textos_perfil.dart`).
  - **Preservar intactos** `Ilustracao.casalIdoso`, `Ilustracao.pessoaComCelular` e seus SVGs em `assets/ilustracoes/` para não quebrar `TelaConta`, `Ajuda` ou componentes do Design System.
  - Substituir referências nos testes existentes (`foto_de_perfil_local_test.dart`, `foto_perfil_widget_test.dart`, `saida_limpa_armazenamento_test.dart`) para avatares válidos e adicionar casos explícitos injetando JSON legado `{"tipo":"avatar","avatar":"casal_idoso"}` e `{"tipo":"avatar","avatar":"pessoa_com_celular"}` no `SharedPreferences` para garantir fallback seguro para `null` (retrato padrão neutro) e nova escolha posterior.
- **Justificativa**: Aproveita o mecanismo seguro de leitura já existente (`AvatarIlustrado.porChave` retornando `null` sem exceções), remove estritamente os dois retratos da escolha de foto de perfil (Item 9) e blinda contas já persistidas.
- **Alternativas consideradas**:
  - *Remover também `Ilustracao.casalIdoso` / `pessoaComCelular` de `assets/ilustracoes/`*: rejeitado por quebrar outras telas que estão fora do escopo e em uso ativo.
  - *Migrar a chave antiga para `memoraAcenando` silenciosamente*: rejeitado porque o requisito define retorno ao retrato padrão neutro (iniciais/silhueta neutra) sem confundir a pessoa usuária com o avatar da assistente sem escolha explícita.

---

## R3 — Conversão e ligação das 66 capturas reais dos 7 guias de `@Du3101` (Item 5, Q2: A)

- **Achado no repositório**:
  - Os 7 guias designados na Q2 ainda possuem apenas `passo_1..4.webp` provisórios (`8–13 KB` cada) em `app/assets/guias/<chave>/`, enquanto as capturas reais sanitizadas (0 PII, 0 círculos pintados) já estão no repositório em `apps/`:
    - `apps/INSS/` (19 imagens, `636×1254`) → `meu-inss` (`app/lib/features/aprendizado/data/guias/meu_inss.dart`)
    - `apps/TikTok/` (6 imagens, `636×1256`) → `tiktok` (`tiktok.dart`)
    - `apps/CNH/` (10 imagens, `636×1254`) → `carteira-digital` (`carteira_digital.dart`)
    - `apps/CLT/` (10 imagens, `636×1256`) → `carteira-de-trabalho` (`carteira_de_trabalho.dart`)
    - `apps/Poupatempo/` (10 imagens, `636×1238..1256`) → `poupatempo` (`poupatempo.dart`)
    - `apps/YouTube/` (7 imagens, `636×1260`) → `youtube` (`youtube.dart`)
    - `apps/GoogleFotos/` (4 imagens, `636×1258`) → `google-fotos` (`google_fotos.dart`)
  - O modelo `Guia` (`guia.dart:974-978`) exige entre `3` e `7` passos em guias lineares **ou** seções `SecaoDoGuia` com `3` a `7` passos por seção (modelo `fgts.dart`). Além disso, `catalogo_e_guias_test.dart` reprova imagem solta na pasta sem `Passo` correspondente e exige linha correspondente em `CAPTURAS.md`.
- **Decisão**:
  - Converter todas as 66 imagens de `apps/` para WebP qualidade `92` (`method=6`), mantendo largura máxima de `1080 px` **sem upscale** (preservando a largura nativa `636 px` já limpa e nítida) em `app/assets/guias/<chave>/passo_<N>.webp`. Verificar todas as imagens visualmente contra PII residual, senhas preenchidas e nitidez antes de medir regiões.
  - Adotar `SecaoDoGuia` (3 a 7 passos por seção) nos 4 guias com mais de 7 capturas (`meu-inss`: 4 seções / 19 capturas; `carteira-digital`: 2 seções / 10 capturas; `carteira-de-trabalho`: 2 seções / 10 capturas; `poupatempo`: 2 seções / 10 capturas) e manter fluxo linear com todos os passos reais nos 3 guias de 4 a 7 capturas (`tiktok`: 6 capturas; `youtube`: 7 capturas; `google-fotos`: 4 capturas).
  - Medir `RegiaoRelativa(x, y, largura, altura)` sobre as imagens limpas com grade visual (sem faixas sobrepostas) para que cada anel/destaque envolva exatamente o botão ou controle descrito no texto de `textos_guias.dart` (<= 2 frases curtas por passo, posição na tela explícita, aviso de senha onde `temCampoDeSenha: true`, 0 emojis).
  - Atualizar `CapturaDoGuia` (`guia.dart`), os 7 arquivos em `app/lib/features/aprendizado/data/guias/`, `textos_guias.dart`, e `app/assets/guias/CAPTURAS.md`, mantendo a lista de serviços de `RepositorioAssistenteSimulado` e as migrations do banco inalteradas (Q2: A).
- **Justificativa**: Entrega todas as 66 telas reais já preparadas no repositório seguindo 100% o contrato consolidado (`fgts.dart`, `contracts/guias.md`, `catalogo_e_guias_test.dart`).
- **Alternativas consideradas**:
  - *Descartar telas para caber em 4 passos lineares*: rejeitado porque deixaria parte das 66 capturas reais de fora ou perderia fluxos importantes (CNH/INSS/CLT/Poupatempo).
  - *Adicionar novos serviços ao catálogo nesta entrega*: descartado pela decisão **Q2: A** do usuário.

---

## R4 — Orçamento de tamanho de `app/assets/guias/` (`8 MB` → `12 MB`)

- **Medição real realizada em `app/assets/guias/` e conversão de teste com Pillow (`q=92`, `method=6`)**:
  - Os 9 guias que permanecem inalterados (`whatsapp`, `instagram`, `facebook`, `telegram`, `gov-br`, `e-titulo`, `serasa`, `fgts`, `correios`) já ocupam **`7,78 MB`** (`7,84 MB` incluindo os placeholders antigos dos 7 guias de ~`75 KB`). Só `instagram` (`2,28 MB`), `gov-br` (`1,29 MB`) e `serasa` (`1,25 MB`) consomem `4,82 MB`.
  - As 66 capturas convertidas dos 7 guias em WebP qualidade 92 somam **`~3,18 MB`** (`INSS`: `1007 KB`, `CLT`: `497 KB`, `CNH`: `417 KB`, `Poupatempo`: `397 KB`, `TikTok`: `350 KB`, `YouTube`: `338 KB`, `GoogleFotos`: `251 KB`). Mesmo reduzindo qualidade para `90` e largura para `720px`, o conjunto ainda soma `~2,89 MB`, tornando o total final (~`10,94 MB` a `q=92`) matematicamente impossível de caber no antigo limite de `8 MB` sem apagar ou degradar ativos dos colegas.
- **Decisão**:
  - Elevar o teto de `assets/guias/` de **`8 MB` para `12 MB`** nos três pontos que governam essa regra:
    1. `app/test/features/aprendizado/catalogo_e_guias_test.dart` (constante `limite12MB = 12 * 1024 * 1024`);
    2. `app/assets/guias/CAPTURAS.md`;
    3. `specs/004-redesenho-das-telas/contracts/guias.md` (nota de atualização de teto).
  - **Não tocar** nem recomprimir as capturas de `@Henrique-Sandrini` (`e-titulo`, `fgts`, `instagram`) nem as de `@Edudu720` (`whatsapp`, `facebook`, `telegram`, `gov-br`, `serasa`, `correios`).
- **Justificativa**: Preserva WebP qualidade 92 de alta legibilidade para as 66 capturas, evita conflito de merge com alterações de `@Edudu720` no Item 1 (WhatsApp) e ainda deixa `~1 MB` de margem dentro do APK sem impacto relevante de distribuição.
- **Alternativas consideradas**:
  - *Recomprimir as capturas de `instagram`/`fgts`/`gov-br`*: rejeitado porque invadiria arquivos revisados por outros colaboradores na Issue #106.
  - *Comprimir os 7 guias abaixo de qualidade 75*: rejeitado porque reduziria apenas ~300 KB com perda visível de nitidez em textos pequenos (violando R6 / FR-028b e `SC-004`).

---

## R5 — Convenção compartilhada de SVGs em `app/assets/icones_apps/` (Item 6 + alinhamento Item 13)

- **Achado no código atual**:
  - `IconeDoAplicativo` (`app/lib/design_system/componentes/ilustracao/icone_do_aplicativo.dart`) já importa Material e utiliza `flutter_svg: ^2.0.17` noutras partes do projeto (`pubspec.yaml:49`). Atualmente desenha à mão com `CustomPaint` (`YouTube`, `Instagram`) ou `Container`/`Icon` (`TikTok`, `Google Fotos`, `Meu INSS`, `e-Título`, `FGTS`, `Poupatempo`, `Carteira Digital`, `Carteira de Trabalho`), enquanto 6 aplicativos usam PNGs em `assets/ilustracoes/` (`whatsapp`, `facebook`, `telegram`, `gov_br`, `serasa`, `correios`).
  - Na Issue #106 (Itens 6 e 13), foi combinada com `@Henrique-Sandrini` a convenção `app/assets/icones_apps/<chave>.svg`.
- **Decisão**:
  - Criar o diretório `app/assets/icones_apps/` e declará-lo em `app/pubspec.yaml` (`- assets/icones_apps/`).
  - Adicionar os 7 arquivos vetoriais limpos (`viewBox="0 0 48 48"`, apenas geometria SVG estática auto-contida sem `<script>`, sem links externos e sem `<text>` dependente de fonte do sistema): `meu-inss.svg`, `tiktok.svg`, `carteira-digital.svg`, `carteira-de-trabalho.svg`, `poupatempo.svg`, `youtube.svg` e `google-fotos.svg`.
  - Em `IconeDoAplicativo`: declarar um mapa constante `_iconesSvgPorChave` mapeando chaves normalizadas para os caminhos dos SVGs; antes dos fallbacks manuais, renderizar `SvgPicture.asset(caminhoSvg, width: tamanho, height: tamanho, fit: BoxFit.contain, semanticsLabel: ...)`.
  - Remover a classe morta `_TrianguloBrancoPainter` (substituída por `youtube.svg`) e **preservar intactos** os 6 PNGs existentes e os 3 ramos manuais de `@Henrique-Sandrini` (`instagram`, `e-titulo`, `fgts`) para que no Item 13 ele apenas acrescente os 3 `.svg` ao mapa sem conflito.
  - Verificar se `IconeDoAplicativo` permanece isento em `validar_tokens.py` (já consta em `ISENTAS`, linha 47) para cores literais de marca ou usar apenas carregamento por asset no novo código.
- **Justificativa**: Cumpre literalmente o combinado na Issue #106, reduz desenho procedural impreciso nos 7 aplicativos, escala perfeitamente em qualquer densidade (`1x`–`4x`) e mantém total compatibilidade para o Item 13.
- **Alternativas consideradas**:
  - *Substituir os 16 ícones de uma vez (incluindo os de `@Henrique-Sandrini` e PNGs de `@Edudu720`)*: rejeitado por invadir escopo explícito do Item 13 e itens alheios.
  - *Carregar dinamicamente `assets/icones_apps/$chave.svg` sem mapa*: rejeitado porque `FutureBuilder` / fallback por `rootBundle` assíncrono piscaria em primeiro quadro e falharia em testes síncronos quando a chave for desconhecida.

---

## R6 — Melhoria visual, otimização e preparo de `TelaPerfil` (Item 10, Q1: A + alinhamento Item 14)

- **Achado no código atual**:
  - `TelaPerfil` (`app/lib/features/perfil/presentation/tela_perfil.dart`) usa `TituloComSos`, `SecaoFotoPerfil` solta no topo sem moldura/cartão próprio, `ListaInformacao` (3 `CampoInformacao`: `nome`, `canal` e `_maisAprendidoNome`) e `SecaoIdade` (em `Cartao`), todos empilhados com `SizedBox` de `xl`.
  - Em `InitState`/`didUpdateWidget`, `_carregarMaisAprendido()` itera linearmente `RepositorioAssistenteSimulado.catalogoDaDemonstracao` toda vez, e não possui guarda de identificador de conta contra conclusões assíncronas fora de ordem caso `idDaConta` mude rapidamente.
  - Testes existentes (`app/test/features/perfil/tela_perfil_test.dart`):
    - Exigem `TelaPerfil.chaveLista`, `TelaPerfil.chaveNome`, `TelaPerfil.chaveCanal`, `TelaPerfil.chaveMaisAprendido`, `TelaPerfil.chaveDesenho`;
    - Linha 153: `expect(find.text('Dona Ana'), findsOneWidget)` → **não duplicar** `widget.nome` fora de `TelaPerfil.chaveNome`;
    - Linhas 162–170: `CampoInformacao` nunca pode ter semântica de botão nem `InkWell`;
    - Linhas 222+: nenhum termo proibido (`plano`, `assinatura`, `pagamento`, etc.);
    - Chamadas de rede em abertura de tela: zero (`_RepositorioEspiao`).
- **Decisão**:
  - Reorganizar `TelaPerfil` em **cartões temáticos bem hierarquizados**, usando estritamente componentes e tokens do Design System (`TituloComSos`, `Cartao`, `TextoMemora`, `CampoInformacao`, `ListaInformacao`, `SecaoFotoPerfil`, `SecaoIdade`):
    1. **Cartão "Seu retrato"**: envolve `SecaoFotoPerfil` (ou `RetratoDoPerfil` quando sem `idDaConta`) com subtítulo curto explicativo em 1 frase;
    2. **Cartão "Sua conta"**: exibe `TelaPerfil.chaveNome` e `TelaPerfil.chaveCanal` com cabeçalho curto de seção;
    3. **Cartão "Seu aprendizado" (`TelaPerfil.chaveSecaoAprendizado`)**: exibe `TelaPerfil.chaveMaisAprendido` (com ícone contextual + nome do app quando disponível ou frase acolhedora quando vazio, e estado intermediário limpo sem `'...'` brusco — ex.: mantendo espaçamento reservado ou texto neutro legível) e prevê parâmetro opcional `final String? ultimoModuloConcluido;` (com chave reservada `TelaPerfil.chaveUltimoModulo`) pronto para receber diretamente o valor do Item 14 (`@Henrique-Sandrini`) quando integrado — sem renderizar linha vazia/placeholder artificial enquanto não houver valor nem lógica nova de contador.
    4. **`SecaoIdade`**: mantida logo abaixo como cartão de preferência estritamente local.
  - Otimizar a resolução do título do guia por mapa estático pré-indexado (`O(1)`) e adicionar verificação `contaAlvo != widget.idDaConta` no retorno assíncrono de `_carregarMaisAprendido()`, mantendo **0 chamadas de rede**.
  - Garantir `validar_tokens.py` com 0 violações e quebra de linha limpa em `320×568` e `200%` de escala.
- **Justificativa**: Atende exatamente **Q1: A**, elimina trabalho duplicado com o Item 14 do `@Henrique-Sandrini` e preserva todos os contratos de acessibilidade (`FR-012`, `FR-042a/b/c`) e chaves de teste existentes.
- **Alternativas consideradas**:
  - *Mostrar cartão "Último módulo concluído: em breve" quando nulo*: rejeitado porque induz confusão ou quebra a regra `FR-018` ("porta vazia é pior que não existir") e o requisito de textos limpos para idosos.

---

## R7 — Acesso seguro `https://` ao site tutorial na Ajuda (Item 11, Q3: A + Princípio II)

- **Achado no código atual**:
  - `Ambiente` (`app/lib/services/ambiente/ambiente.dart:72-82`) já implementa o validador rigoroso `Ambiente.enderecoOficial(String? bruto)`: aceita somente esquema `https`, exige `uri.host.isNotEmpty`, rejeita `uri.userInfo.isNotEmpty` (anti-spoofing `https://loja.com@golpe.com`) e rejeita espaços em branco.
  - `Composicao` e `FluxoAutenticacao` já seguem esse padrão exato com `Compartilhador.doAmbiente(ambiente)` e `TelaAjuda` (`tela_ajuda.dart`), que por sua vez é verificada por `tela_ajuda_test.dart:72` (`expect(find.byType(CaixaDeEtapa), findsOneWidget)`).
  - `url_launcher: ^6.3.1` já está no `pubspec.yaml` e em uso no projeto; em `AndroidManifest.xml`, `<queries>` ainda não declara `<intent>` explícito para esquema `https` (declarar torna `url_launcher` completamente previsível no Android 11+).
- **Decisão**:
  - Adicionar `final String? urlSiteTutorial;` em `Ambiente` (`ambiente.dart`), carregada via `--dart-define=MEMORA_URL_SITE_TUTORIAL` e filtrada obrigatoriamente por `Ambiente.enderecoOficial(...)` (default sem definição → `null`, mantendo o botão oculto automaticamente conforme **Q3: A**).
  - Criar `app/lib/features/ajuda/data/abridor_site_tutorial.dart` com:
    - Interface `AbridorDeSiteTutorial` (`String get endereco; Future<bool> abrir();`), método de fábrica `AbridorDeSiteTutorial.doAmbiente(Ambiente ambiente)` (retorna `null` se `urlSiteTutorial` ou `enderecoOficial(...)` for nulo);
    - `AbridorDeSiteTutorialUrlLauncher`: revalida `Ambiente.enderecoOficial(endereco)` e chama `launchUrl(Uri.parse(seguro), mode: LaunchMode.externalApplication)` dentro de `try/catch`;
    - `AbridorDeSiteTutorialSimulado`: registra endereços solicitados (`abertos`) e permite simular falha (`falharNoProximo`), nos moldes de `CompartilhadorSimulado`.
  - Declarar o intent `<action android:name="android.intent.action.VIEW"/>` + `<data android:scheme="https"/>` em `<queries>` do `AndroidManifest.xml`.
  - Injetar `AbridorDeSiteTutorial?` em `Composicao` → `main.dart` → `FluxoAutenticacao` → `TelaAjuda` (parâmetro opcional `this.abridorSiteTutorial`, default `null` preservando compatibilidade retroativa com testes existentes).
  - Em `TelaAjuda`, preservar exatamente o único `CaixaDeEtapa` dos assuntos (`tela_ajuda_test.dart:72`); quando `abridorSiteTutorial != null`, exibir abaixo dele um `_CartaoSiteTutorial` (`Cartao` + `BotaoSecundario` com `Key('ajuda.site_tutorial')` e textos em `TextosAjuda`, sem usar `www.`). Ao tocar:
    1. Abre diálogo modal acessível (`showDialog` com `AlertDialog(scrollable: true, ...)` garantindo zero overflow a `200%` de fonte em `320×568`), informando em até duas frases curtas que a pessoa sairá do Memora para o navegador oficial no endereço exibido (`abridor.endereco`);
    2. Ação de cancelamento (*"Agora não"*, `Key('ajuda.site_tutorial.cancelar')`): fecha o diálogo sem chamar `abrir()`;
    3. Ação primária (*"Sim, abrir o site"*, `Key('ajuda.site_tutorial.confirmar')`): fecha o diálogo e chama `abridor.abrir()`. Se retornar `false`, exibe aviso calmo inline com `Key('ajuda.site_tutorial.erro')` em `TextosAjuda` sem fechar a tela nem lançar exceção.
- **Justificativa**: Reutiliza exatamente o padrão auditado de segurança contra phishing da feature 004 (`Ambiente.enderecoOficial`), garante zero chamadas externas ao primeiro toque (Princípio II) e atende `Q3: A` sem quebrar nenhum teste existente da Ajuda.
- **Alternativas consideradas**:
  - *Incluir o site como mais um `IdDoAssunto` dentro do `CaixaDeEtapa`*: rejeitado porque `tela_ajuda_test.dart:95-105` fixa a lista exata de `IdDoAssunto`s esperados sem compartilhamento e o requisito pede um botão dedicado na Ajuda (Item 11).
  - *Pergunta apenas inline sem diálogo modal*: rejeitado porque `FR-019` especifica explicitamente diálogo modal de confirmação prévia; o risco de overflow em `320×568` a 200% é mitigado com `AlertDialog(scrollable: true)`.
