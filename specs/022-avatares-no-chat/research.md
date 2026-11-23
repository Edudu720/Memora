# Research: Avatares da Memora e da Pessoa Usuária no Chat

**Feature**: `022-avatares-no-chat` | **Date**: 2026-11-22

---

## D1 — Causa raiz da ausência de ícones no chat atual

- **Achado**: Em `app/lib/features/assistente/presentation/telas/tela_conversa.dart`, tanto `_fala` (linha 318) quanto `BalaoDeFala.escrevendo(comRosto: false)` (linha 553) e o balão em streaming (`comRosto: false`, linha 561) desligavam explicitamente os ícones laterais (`comRosto: false`), deixando apenas `TelaConversa.chaveConvite` (linha 530) com o padrão `comRosto: true`. Por outro lado, `AjudaGuiadaDaConversa` (`ajuda_guiada_da_conversa.dart`) utiliza `comRosto: true` (padrão), motivo pelo qual o exemplo (*Passo 2 de 5*) exibia o ícone mini da Memora e o ícone de usuário enquanto o chat real mostrava apenas os rótulos `"Memora"` e `"Você"`.
- **Origem histórica**: Decisão `T059` / `FR-042` da entrega `013-redesenho-final` havia desligado os rostos nos balões para evitar múltiplas `MemoraAnimada` animadas na tela (`FR-006`). Contudo, nos testes reais do usuário, balões sem ícone lateral empobreceram a identificação visual imediata em comparação direta com a própria tela demonstrativa do aplicativo.
- **Decisão**: Restaurar `comRosto` ativo na conversa (para `scale < MemoraDimensoes.escalaTextoAlta`), preservando **uma única Memora animada/falando** no cabeçalho (`BarraSuperior`) e tornando os rostos nos balões marcadores visuais estáticos (`rostoAnimado: false`), além de injetar o retrato real de perfil do usuário ao lado direito dos balões `"Você"`.

---

## D2 — Fronteira arquitetural de `BalaoDeFala` (`design_system` sem acoplamento a `perfil`)

- **Problema**: `BalaoDeFala` pertence a `app/lib/design_system/componentes/conversa/balao_de_fala.dart`. Importar `RetratoDoPerfil` ou `RetratoDePerfil` de `features/perfil/` violaria o isolamento do Design System (Princípio V).
- **Decisão**:
  1. Adicionar `final Widget? avatarPessoa;` ao `BalaoDeFala`: quando `_daMemora` é `false` e `comRosto` é `true`, renderiza `avatarPessoa ?? _RostoDaPessoa(cores: cores)`. Como `avatarPessoa` já é `Widget?`, `TelaConversa` pode injetar diretamente `ExcludeSemantics(child: RetratoDoPerfil(..., tamanho: MemoraDimensoes.pisoDeIlustracao))` sem que `BalaoDeFala` conheça nada de perfil.
  2. Adicionar `final bool rostoAnimado;` (padrão `true`, presente também em `BalaoDeFala.escrevendo` para manter compatibilidade com `AjudaGuiadaDaConversa` e apresentação). Quando `rostoAnimado == false` (usado pela lista da conversa), `MemoraPersonagem` é construído com `reageAoToque: false` envolvido em `MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), ...)`, garantindo:
     - zero tickers de animação rodando dentro dos balões roláveis;
     - zero interferência em gestos de rolagem/toque (Princípio III / `FR-005c`);
     - zero concorrência visual com a `MemoraPersonagem` da `BarraSuperior` que continua falando em tempo real enquanto os trechos chegam.
  3. **Sinal visual distintivo para avatares ilustrados**: Quando a pessoa escolhe em Meu Perfil um dos 4 avatares ilustrados da Memora, `RetratoDoPerfil` desenha a ilustração com `DesenhoAvatarIlustrado` dentro de uma moldura circular preenchida (`cores.medalhao`) com borda enfática (`cores.borda`, `MemoraDimensoes.bordaEnfase`), **à direita** e com rótulo `"Você"`; já os balões da assistente trazem à esquerda o rosto mini livre (`ExpressaoDaMemora.mini`, sem moldura circular nem borda) e rótulo `"Memora"`. A distinção visual permanece imediata em todos os 3 temas.
  4. **Iniciais compactas no círculo de `40 dp` em `150%`**: Em `RetratoDoPerfil._padraoNeutro`, proteger o texto das iniciais puramente decorativas com `FittedBox(fit: BoxFit.scaleDown)` (ou `MediaQuery.withNoTextScaling`) para impedir recorte lateral de letras largas (`"WM"`) quando a conversa exibe avatares de `40 dp` sob ampliação `150%`.

---

## D3 — Atualização reativa do retrato entre as abas da `CascaInterna`

- **Problema**: O usuário navega entre **Início** (onde pode abrir ou manter a conversa) e **Meu Perfil** (`CascaInterna`), podendo trocar sua foto ou voltar ao padrão neutro a qualquer momento durante a sessão. Além disso, `_DonaDaConversa` mantém `TelaConversa` montada enquanto estiver na pilha de navegação ou ao voltar de configurações. Se `TelaConversa` lesse o retrato apenas no `initState()`, mudanças no Perfil não seriam refletidas imediatamente em conversas já abertas ou abas mantidas vivas.
- **Verificação na base de código**: O `git grep` em `app/` confirmou que apenas duas classes implementam `ArmazenamentoDeFotoDePerfil`: `FotoDePerfilLocal` e `FotoDePerfilEmMemoria`. Nenhum duble ad-hoc nos testes implementa a interface diretamente.
- **Decisão**: Adicionar `Stream<void> get alteracoes;` à interface `ArmazenamentoDeFotoDePerfil` em `app/lib/features/perfil/data/foto_de_perfil_local.dart`, emitindo evento via `StreamController<void>.broadcast()` em `salvarFoto`, `salvarAvatar`, `apagar` e `esquecerDoAparelho` tanto em `FotoDePerfilLocal` quanto em `FotoDePerfilEmMemoria`. Esse padrão espelha diretamente `ProgressoDeAprendizado.alteracoes` implementado na feature `020`.
- **Gestão do ciclo de vida**: Em `_TelaConversaState`, assinar `widget.fotoDePerfil?.alteracoes`, re-assinar e recarregar em `didUpdateWidget` se `fotoDePerfil` ou `idDaConta` mudar, cancelar a assinatura no `dispose()` e proteger o `Future` de carga com contador monotônico `_versaoRetrato` + `if (!mounted || versao != _versaoRetrato)` + `try/catch` seguro (padrão de `TelaPerfil`).

---

## D4 — Cadeia de injeção `FluxoAutenticacao` → `_DonaDaConversa` → `TelaConversa`

- **Verificação na base de código**:
  - `main.dart` e `Composicao` já passam `fotoDePerfil: composicao.fotoDePerfil` para `FluxoAutenticacao`.
  - `_FluxoAutenticacaoState` já possui `late final ArmazenamentoDeFotoDePerfil _fotos` (linha 311), `_pessoa?.id` e `_pessoa?.nomeTratamento` — exatamente como já passa para `TelaPerfil` na linha 1249.
- **Decisão**:
  - Estender `TelaConversa` com três parâmetros **opcionais**: `final ArmazenamentoDeFotoDePerfil? fotoDePerfil;`, `final String? idDaConta;` e `final String? nomeDaPessoa;`.
  - Repassar esses dados em `FluxoAutenticacao._abrirConversa` e `_DonaDaConversa` para `TelaConversa`.
  - Manter todos os parâmetros novos opcionais para preservar 100% da compatibilidade com testes de widget/acessibilidade existentes que montam `TelaConversa(controlador: c)` isoladamente:
    - Quando houver `fotoDePerfil` e `idDaConta` não vazio, lê o retrato local do aparelho e usa `RetratoDoPerfil(nome: widget.nomeDaPessoa ?? '', retrato: _retrato, tamanho: MemoraDimensoes.pisoDeIlustracao)`.
    - Quando não houver `fotoDePerfil`/`idDaConta`, mas houver `nomeDaPessoa` não vazio, exibe `RetratoDoPerfil` com as iniciais (padrão neutro).
    - Quando nenhum dos dois for passado (testes isolados mínimos), `avatarPessoa` fica `null` e `BalaoDeFala` renderiza o fallback circular neutro `_RostoDaPessoa`.

---

## D5 — Reconciliação de testes existentes e regra de ampliação tipográfica (`>= 175%`)

- **Ampliação (`memora-ux` R2 regra 7)**: Em telas estreitas (`320×568`) a `200%`, um círculo/rosto lateral de `40 dp` + espaçamento de `8 dp` (`MemoraEspacamento.sm`) consome `48 dp` da linha do balão, restringindo a largura disponível para texto ampliado e aumentando risco de cortes ou quebras apertadas. Usando `final bool mostrarRosto = escala < MemoraDimensoes.escalaTextoAlta;` (`1.75` — mesmo limiar pelo qual `CabecalhoDeTela` e `BarraSuperior` removem a ilustração decorativa), garantimos simultaneamente fidelidade total em `100%` e `150%` e aproveitamento integral da largura de leitura em `175%`–`200%`.
- **Reconciliação necessária de asserções de teste anteriores (`013`)**:
  - `app/test/features/assistente/memora_no_topo_da_conversa_test.dart` (linhas 198–239) afirmava que balões fora do convite não tinham `MemoraPersonagem`/`MemoraAnimada` nem `Icons.person_rounded`.
  - `app/test/features/assistente/tela_conversa_test.dart` (linhas 227–242) afirmava a ausência de `MemoraPersonagem`, `MemoraAnimada` e `Icons.person_rounded` nos balões da conversa.
  - `app/test/design_system/icones_e_toque_test.dart` (linhas 133–166) afirmava que `TelaConversa` tinha no máximo 1 `MemoraAnimada` fora do convite.
  - **Predicado unificado de validação**: Tanto `MemoraPersonagem` (balões da assistente) quanto `DesenhoAvatarIlustrado` (quando usuário escolhe avatar ilustrado da Memora no Perfil) renderizam `MemoraAnimada` na árvore; portanto, os testes reconciliados devem verificar que: (a) fora de `BalaoDeFala`, existe no máximo 1 `MemoraAnimada` (na `BarraSuperior`, ativa e falante); e (b) toda `MemoraAnimada` descendente de `BalaoDeFala` na conversa está em modo estático (`reageAoToque == false` e com ancestral `MediaQuery.disableAnimations == true`), além de respeitar o ocultamento automático quando `escala >= 1.75`.
