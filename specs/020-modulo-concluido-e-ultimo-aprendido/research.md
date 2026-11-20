# Pesquisa Técnica: Feature 020

## R1. Estado atual da persistência e chaves de conclusão
- **Achado**: `ProgressoDeAprendizado` em `app/lib/features/aprendizado/data/progresso_de_aprendizado.dart` já persiste `{'contas': {idDaConta: {chave: {'vezes': int, 'ordem': int}}}}` via escrita atômica (`.tmp` + `rename`) serializada por `_naFila`.
- **Achado**: `TelaPassoAPasso` grava `'<guia.chave>:<secao.chave>'` quando `widget.secao != null` e `'<guia.chave>'` quando o guia não tem seções.
- **Decisão**: Não alterar o esquema em disco (`progresso_de_aprendizado.json`), preservando 100% de retrocompatibilidade com dados existentes e testes de leitura/corrupção de arquivo. Adicionar apenas `alteracoes`, `ordensDeConclusao` e `ultimoConcluido`.

## R2. Atualização ao vivo entre telas vivas e empilhadas
- **Achado**:
  1. `CascaInterna` utiliza `TrocaDeDestino` mantendo todas as raízes vivas (incluindo `TelaPerfil`), logo `initState` de `TelaPerfil` não roda de novo ao trocar da aba `Início` para `Perfil` após concluir um passo a passo.
  2. Ao empilhar `TelaCatalogo -> TelaSeletorDeSecao -> TelaPassoAPasso`, `TelaCatalogo` e `TelaSeletorDeSecao` permanecem montadas abaixo da pilha; quando o usuário retorna pelo botão Voltar ou `"Voltar ao início"`, o progresso precisa já estar atualizado.
- **Decisão**: `ProgressoDeAprendizado` expõe `Stream<void> get alteracoes` via `StreamController<void>.broadcast()`. A emissão acontece **fora** do callback `_naFila` (imediatamente após `await _naFila(...)`), evitando deadlock caso algum ouvinte consulte `concluidos`/`ordensDeConclusao` no instante do evento. Telas inscrevem-se em `initState`, atualizam assinatura em `didUpdateWidget` e cancelam em `dispose`.
- **Impacto em doubles de teste**: Apenas `_ProgressoEmMemoria` em `app/test/features/perfil/tela_perfil_test.dart` usa `implements ProgressoDeAprendizado`; todos os outros dubles em testes usam `extends ProgressoDeAprendizado` e herdam automaticamente os novos membros. Atualizaremos `_ProgressoEmMemoria` para espelhar `ordem` e `alteracoes`.

## R3. Contraste WCAG 2.2 AA do checkbox verde arredondado
- **Achado nos tokens (`app/lib/design_system/tokens/cores.dart`)**:
  - Claro: `cores.sucesso = #186A2E`, `cores.superficie = #FFFFFF` -> contraste **6,6:1** (>= 4,5:1).
  - Escuro: `cores.sucesso = #7CD69A`, `cores.fundo = #0F141E` -> contraste **10,7:1** (>= 4,5:1).
  - Alto Contraste: `cores.sucesso = #7BE49B`, `cores.fundo = #000000` -> contraste **13,1:1** (>= 7,0:1), mais borda `cores.borda` com `MemoraDimensoes.bordaEnfase`.
- **Dimensões e formas com zero literais**:
  - Caixa `MemoraDimensoes.iconeDestaque` (`28 dp`) × `MemoraDimensoes.iconeDestaque` (`28 dp`), canto `BorderRadius.circular(MemoraRaio.balaoPonta)` (`6 dp`).
  - Ícone `Icons.check_rounded` (terminado em `_rounded`), tamanho `MemoraDimensoes.iconePequeno` (`20 dp`).
  - Wrapper `ExcludeSemantics` para não competir com o leitor de tela do `LinhaDeLista`.

## R4. Semântica TalkBack e testes existentes
- **Achado**:
  - `app/test/features/aprendizado/tela_seletor_de_secao_test.dart` verifica exatamente `find.bySemanticsLabel(TextosGuias.secaoDescrita('Baixar Certidões', ..., quantidadeDePassos(5)))` para seção NÃO concluída e `find.text(TextosGuias.secaoJaAprendida(quantidadeDePassos(5)))` no rodapé de seção concluída.
  - Em `app/test/features/perfil/tela_perfil_test.dart` linha 191, havia `expect(find.text('WhatsApp'), findsOneWidget)` porque antes só existia `chaveMaisAprendido`. Com `chaveUltimoAprendido` também exibindo `'WhatsApp'` no cenário de 1 módulo concluído, esse teste será atualizado para verificar explicitamente dentro de `chaveMaisAprendido` e `chaveUltimoAprendido`.
- **Decisão**: Para seção não concluída, manter `TextosGuias.secaoDescrita(...)` exatamente igual; para seção concluída, usar `TextosGuias.secaoConcluidaDescrita(...)` adicionando `'Concluído.'` ao fim do anúncio semântico e preservando `'Já aprendeu'` no rodapé.

## R5. Portões de lint, tokens, texto e planos
- `validar_tokens.py` proíbe qualquer literal fora de `tokens/`. Todos espaçamentos (`MemoraEspacamento.xs`), dimensões (`MemoraDimensoes.iconeDestaque`, `MemoraDimensoes.iconePequeno`, `MemoraDimensoes.bordaEnfase`), raios (`MemoraRaio.balaoPonta`) e cores (`cores.sucesso`, `cores.superficie`, `cores.fundo`, `cores.borda`) vêm dos tokens via `design_system.dart`.
- Nomes de chaves em `TelaPerfil` e textos (`'Concluído'`, `'Último aprendizado'`, `'Ainda vamos concluir o primeiro!'`) não contêm palavras proibidas por `texto_da_interface_test.dart` nem por `sem_planos_test.dart`.
