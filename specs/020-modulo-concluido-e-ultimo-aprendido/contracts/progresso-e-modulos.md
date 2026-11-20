# Contrato: Progresso Local, Marcação de Módulos/Seções e Último Módulo Concluído

## 1. Contrato de Dados e Domínio

### `ProgressoDeAprendizado` (`app/lib/features/aprendizado/data/progresso_de_aprendizado.dart`)
- Mantém `registrarChegadaAoPasso`, `registrarConclusao`, `concluidos`, `aplicativoMaisAprendido` e `apagar` sem alteração de comportamento retroativo.
- Expõe:
  - `Stream<void> get alteracoes` (broadcast). Emite após persistência bem-sucedida em `registrarConclusao` e após deleção em `apagar`.
  - `Future<Map<String, int>> ordensDeConclusao(String idDaConta)`
  - `Future<String?> ultimoConcluido(String idDaConta)`
- Garantia de segurança (`FR-042a` / `FR-042b`): nenhuma dependência HTTP/repositório; limpeza completa em `apagar()`.

### `estado_do_modulo.dart` (`app/lib/features/aprendizado/domain/estado_do_modulo.dart`)
- `bool moduloConcluido(Guia guia, Map<String, int> concluidos)`
- `String? chaveDoUltimoModuloConcluido(Map<String, int> ordens, Iterable<Guia> guias)`

## 2. Contrato de Apresentação e Chaves de Teste

### `TelaCatalogo` (`app/lib/features/assistente/presentation/telas/tela_catalogo.dart`)
- Novos parâmetros opcionais no construtor:
  - `final ProgressoDeAprendizado? progresso;`
  - `final String? idDaConta;`
- Nova chave de teste estática:
  - `static Key chaveConcluidoDoItem(String chave) => Key('catalogo.concluido.$chave');`
- Regra visual: dentro de `_ItemDoCatalogo`, o selo de capacidade existente e o selo condicional `BadgeDeStatus(key: TelaCatalogo.chaveConcluidoDoItem(servico.chave), rotulo: TextosGuias.moduloConcluido, icone: Icons.check_circle_rounded, tom: TomBadgeStatus.positivo)` ficam agrupados em `Wrap(spacing: MemoraEspacamento.xs, runSpacing: MemoraEspacamento.xs, ...)`. O selo `"Concluído"` só é renderizado quando `guia != null && moduloConcluido(guia, _concluidos)`.
- Conexão no fluxo principal (`FluxoAutenticacao._abrirCatalogo`): passa `progresso: widget.progresso` e `idDaConta: _pessoa?.id`.

### `TelaSeletorDeSecao` (`app/lib/features/aprendizado/presentation/tela_seletor_de_secao.dart`)
- Nova chave de teste estática:
  - `static Key chaveCheckDaSecao(String chave) => Key('seletor_secao.check.$chave');`
- Regra visual (`_CartaoSecao` via `LinhaDeLista`):
  - `direita`: quando `concluida == true`, renderiza `_CheckboxVerdeConcluido(key: TelaSeletorDeSecao.chaveCheckDaSecao(secao.chave))`; quando `false`, `null`.
  - `_CheckboxVerdeConcluido`: envolto em `ExcludeSemantics`, caixa `MemoraDimensoes.iconeDestaque × MemoraDimensoes.iconeDestaque`, cor `cores.sucesso`, canto `BorderRadius.circular(MemoraRaio.balaoPonta)`, borda `Border.all(color: cores.borda, width: MemoraDimensoes.bordaEnfase)` apenas quando `tema.id == MemoraTemaId.altoContraste`, ícone `Icons.check_rounded` de tamanho `MemoraDimensoes.iconePequeno` e cor `tema.id == MemoraTemaId.claro ? cores.superficie : cores.fundo`.
  - `rodape`: preserva `TextosGuias.secaoJaAprendida(contagem)` quando `concluida`.
  - `rotuloDoLeitor`:
    - `concluida == false`: `TextosGuias.secaoDescrita(secao.titulo, secao.subtitulo, textoMeta)` (inalterado).
    - `concluida == true`: `TextosGuias.secaoConcluidaDescrita(secao.titulo, secao.subtitulo, textoMeta)`.

### `TelaPerfil` (`app/lib/features/perfil/presentation/tela_perfil.dart`)
- Nova chave de teste estática:
  - `static const Key chaveUltimoAprendido = Key('perfil.ultimo_aprendido');`
- Ordem dentro de `ListaInformacao`:
  1. `TelaPerfil.chaveNome`
  2. `TelaPerfil.chaveCanal` (quando presente)
  3. `TelaPerfil.chaveMaisAprendido` (`O que você mais aprendeu` — preservado)
  4. `TelaPerfil.chaveUltimoAprendido` (`Último módulo concluído` — novo, valor `_carregouMaisAprendido ? (_ultimoAprendidoNome ?? TextosPerfil.ultimoAprendidoVazio) : '...'`, nunca clicável).

## 3. Contrato de Copy (`app/lib/l10n/`)
- `TextosGuias.moduloConcluido = 'Concluído'`
- `TextosGuias.secaoConcluidaDescrita(String titulo, String subtitulo, String meta) => '$titulo. $subtitulo. $meta. Concluído.'`
- `TextosPerfil.rotuloUltimoAprendido = 'Último módulo concluído'`
- `TextosPerfil.ultimoAprendidoVazio = 'Ainda vamos concluir o primeiro!'`
