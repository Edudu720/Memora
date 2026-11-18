import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_assistente.dart';
import '../../../../l10n/textos_atalhos_aplicativos.dart';
import '../../../../services/aplicativos/consulta_de_aplicativos.dart';
import '../../../aprendizado/data/guias/guias.dart';
import '../../../aprendizado/domain/busca.dart';
import '../../../aprendizado/domain/guia.dart';
import '../../domain/assistente.dart';

/// Catálogo unificado de aplicativos e serviços sociais (`T050`, `FR-023`).
///
/// Apresenta busca limpa no topo, filtro segmentado (`Apps do celular` e
/// `Serviços sociais`), logo oficial em badge suave, `BadgeDeStatus` não
/// clicável informando o que a Memora pode fazer e ações explícitas sem
/// confundir cartão informativo com botão (`002/FR-012`).
class TelaCatalogo extends StatefulWidget {
  /// Chave da lista.
  static const Key chaveLista = Key('catalogo.lista');

  /// Chave do campo de busca.
  static const Key chaveBusca = Key('catalogo.busca');

  /// Chave de um item, pelo nome do serviço.
  static Key chaveDoItem(String nome) => Key('catalogo.item.$nome');

  /// Chave do botão para entrar na lista de abertura direta (`015`).
  static const Key chaveAtalhosDiretos = Key('catalogo.atalhos_diretos');

  /// De onde vêm os serviços.
  final RepositorioAssistente repositorio;

  /// Categoria exibida ao abrir a tela.
  final CategoriaDoServico categoria;

  /// Abre a conversa já perguntando sobre um serviço (a Memora **ensina**).
  final void Function(ServicoDoCatalogo servico)? aoEscolher;

  /// Abre a conversa já **pedindo para a Memora abrir** o aplicativo.
  ///
  /// É um caminho à parte do [aoEscolher]: o botão "Pedir para a Memora abrir"
  /// não pode reaproveitá-lo, ou o rascunho sai "Você me ensina…" e a Memora
  /// ensina em vez de abrir. Nulo, o botão não aparece.
  final void Function(ServicoDoCatalogo servico)? aoPedirParaAbrir;

  /// Abre o guia passo a passo quando disponível.
  final void Function(Guia guia, ServicoDoCatalogo servico)? aoAbrirGuia;

  /// Consulta de plataforma dos aplicativos instalados (se disponível).
  final ConsultaDeAplicativos? consultaAplicativos;

  /// Abre a tela dedicada para abrir um aplicativo direto (`015`).
  final VoidCallback? aoAbrirAtalhosDiretos;

  /// Volta ao início.
  final VoidCallback? aoVoltar;

  /// Estado de teste forçado (`FR-006`).
  final String? estadoDeTeste;

  /// Cria a tela de catálogo.
  const TelaCatalogo({
    required this.repositorio,
    required this.categoria,
    this.aoEscolher,
    this.aoPedirParaAbrir,
    this.aoAbrirGuia,
    this.consultaAplicativos,
    this.aoAbrirAtalhosDiretos,
    this.aoVoltar,
    this.estadoDeTeste,
    super.key,
  });

  @override
  State<TelaCatalogo> createState() => _TelaCatalogoState();
}

class _TelaCatalogoState extends State<TelaCatalogo> {
  List<ServicoDoCatalogo>? _todosServicos;
  Map<String, bool> _instalacaoPorChave = const <String, bool>{};
  late CategoriaDoServico _categoriaAtiva;
  bool _falhou = false;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _categoriaAtiva = widget.categoria;
    _carregar();
  }

  @override
  void didUpdateWidget(covariant TelaCatalogo antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.categoria != widget.categoria) {
      _categoriaAtiva = widget.categoria;
    }
    if (antigo.repositorio != widget.repositorio ||
        antigo.consultaAplicativos != widget.consultaAplicativos) {
      _carregar();
    }
  }

  Future<void> _carregar() async {
    try {
      final List<ServicoDoCatalogo> todos = await widget.repositorio.catalogo();
      final Map<String, bool> instalacoes = await _consultarInstalacoes(todos);
      if (!mounted) return;
      setState(() {
        _todosServicos = todos;
        _instalacaoPorChave = instalacoes;
        _falhou = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() => _falhou = true);
    }
  }

  Future<Map<String, bool>> _consultarInstalacoes(
    List<ServicoDoCatalogo> todos,
  ) async {
    final ConsultaDeAplicativos? consulta = widget.consultaAplicativos;
    if (consulta == null) return const <String, bool>{};

    final Map<String, bool> resultado = <String, bool>{};
    await Future.wait(<Future<void>>[
      for (final ServicoDoCatalogo servico in todos)
        if (servico.categoria == CategoriaDoServico.cotidiano &&
            servico.memoraPodeAbrir &&
            (servico.identificadorAndroid?.trim().isNotEmpty ?? false))
          () async {
            try {
              resultado[servico.chave] = await consulta.estaInstalado(
                servico.identificadorAndroid!.trim(),
              );
            } catch (_) {
              resultado[servico.chave] = false;
            }
          }(),
    ]);
    return resultado;
  }

  String get _titulo => switch (_categoriaAtiva) {
        CategoriaDoServico.sensivel => TextosAssistente.portaServicos,
        CategoriaDoServico.cotidiano => TextosAssistente.portaAplicativos,
      };

  List<ServicoDoCatalogo> get _servicosDaCategoria {
    final List<ServicoDoCatalogo>? todos = _todosServicos;
    if (todos == null) return const <ServicoDoCatalogo>[];
    return todos
        .where((ServicoDoCatalogo s) => s.categoria == _categoriaAtiva)
        .toList();
  }

  void _acionarPadrao(ServicoDoCatalogo servico) {
    final Guia? guia = guiaDe(servico.chave);
    if (guia != null && widget.aoAbrirGuia != null) {
      widget.aoAbrirGuia!(guia, servico);
    } else if (widget.aoEscolher != null) {
      widget.aoEscolher!(servico);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    // Estados de tela — FR-006
    if (widget.estadoDeTeste == 'carregando' ||
        (_todosServicos == null && !_falhou)) {
      return Scaffold(
        backgroundColor: cores.fundo,
        appBar: BarraSuperior(titulo: _titulo, aoVoltar: widget.aoVoltar),
        body: const Center(
          child: Carregando(mensagem: TextosAssistente.carregandoCatalogo),
        ),
      );
    }

    if (widget.estadoDeTeste == 'erro' || _falhou) {
      return Scaffold(
        backgroundColor: cores.fundo,
        appBar: BarraSuperior(titulo: _titulo, aoVoltar: widget.aoVoltar),
        body: Center(
          child: MensagemErro(
            mensagem: TextosAssistente.semConexao,
            aoTentarNovamente: _carregar,
          ),
        ),
      );
    }

    final List<ServicoDoCatalogo> servicos = _servicosDaCategoria;
    if (widget.estadoDeTeste == 'vazio' || servicos.isEmpty) {
      return Scaffold(
        backgroundColor: cores.fundo,
        appBar: BarraSuperior(titulo: _titulo, aoVoltar: widget.aoVoltar),
        body: const Center(
          child: EstadoVazio(
            titulo: TextosAssistente.catalogoVazioTitulo,
            explicacao: TextosAssistente.catalogoVazioExplicacao,
            icone: Icons.apps_rounded,
          ),
        ),
      );
    }

    final List<ServicoDoCatalogo> exibidos = buscarServicos(servicos, _busca);

    return Scaffold(
      backgroundColor: cores.fundo,
      appBar: BarraSuperior(titulo: _titulo, aoVoltar: widget.aoVoltar),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          key: TelaCatalogo.chaveLista,
          padding: const EdgeInsets.all(MemoraEspacamento.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Busca limpa no topo (FR-023)
              CampoTexto(
                key: TelaCatalogo.chaveBusca,
                rotulo: TextosAssistente.rotuloBuscaAplicativos,
                textoAjuda: TextosAssistente.ajudaBuscaAplicativos,
                aoMudar: (String valor) => setState(() => _busca = valor),
              ),
              const SizedBox(height: MemoraEspacamento.md),

              // Filtro segmentado por tipo de serviço
              Wrap(
                spacing: MemoraEspacamento.sm,
                runSpacing: MemoraEspacamento.sm,
                children: <Widget>[
                  ChipFiltro(
                    rotulo: 'Apps do celular',
                    icone: Icons.apps_rounded,
                    selecionado: _categoriaAtiva == CategoriaDoServico.cotidiano,
                    aoTocar: () => setState(
                      () => _categoriaAtiva = CategoriaDoServico.cotidiano,
                    ),
                  ),
                  ChipFiltro(
                    rotulo: 'Serviços sociais',
                    icone: Icons.shield_rounded,
                    selecionado: _categoriaAtiva == CategoriaDoServico.sensivel,
                    aoTocar: () => setState(
                      () => _categoriaAtiva = CategoriaDoServico.sensivel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MemoraEspacamento.lg),

              if (_categoriaAtiva == CategoriaDoServico.cotidiano &&
                  widget.aoAbrirAtalhosDiretos != null) ...<Widget>[
                BotaoSecundario(
                  key: TelaCatalogo.chaveAtalhosDiretos,
                  rotulo: TextosAtalhosAplicativos.botaoVerAtalhosDiretos,
                  icone: Icons.apps_rounded,
                  aoTocar: widget.aoAbrirAtalhosDiretos,
                ),
                const SizedBox(height: MemoraEspacamento.lg),
              ],

              // Para os serviços sensíveis, a explicação vem ANTES da lista (FR-042).
              if (_categoriaAtiva == CategoriaDoServico.sensivel) ...<Widget>[
                Cartao(
                  padding: const EdgeInsets.all(MemoraEspacamento.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const <Widget>[
                      MemoraPersonagem(
                        expressao: ExpressaoDaMemora.dica,
                        tamanho: MemoraDimensoes.alvoMinimo,
                      ),
                      SizedBox(width: MemoraEspacamento.md),
                      Expanded(
                        child: TextoMemora(
                          TextosAssistente.porqueNaoAbroServicoSensivel,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MemoraEspacamento.lg),
              ],

              if (exibidos.isEmpty)
                const EstadoVazio(
                  titulo: 'Nenhum aplicativo encontrado',
                  explicacao:
                      'Tente buscar com outras palavras ou apague a busca.',
                  icone: Icons.search_off_rounded,
                )
              else
                for (final ServicoDoCatalogo servico in exibidos) ...<Widget>[
                  _ItemDoCatalogo(
                    servico: servico,
                    temGuia: guiaDe(servico.chave) != null,
                    instalado: _instalacaoPorChave[servico.chave] ?? true,
                    habilitado:
                        widget.aoEscolher != null || widget.aoAbrirGuia != null,
                    aoAcionarPadrao: () => _acionarPadrao(servico),
                    aoPedirAbrir: widget.aoPedirParaAbrir != null
                        ? () => widget.aoPedirParaAbrir!(servico)
                        : null,
                  ),
                  const SizedBox(height: MemoraEspacamento.md),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Cartão horizontal informativo com ações explícitas de ensinar ou abrir.
class _ItemDoCatalogo extends StatelessWidget {
  final ServicoDoCatalogo servico;
  final bool temGuia;
  final bool instalado;
  final bool habilitado;
  final VoidCallback aoAcionarPadrao;
  final VoidCallback? aoPedirAbrir;

  const _ItemDoCatalogo({
    required this.servico,
    required this.temGuia,
    required this.instalado,
    required this.habilitado,
    required this.aoAcionarPadrao,
    this.aoPedirAbrir,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final bool podeAbrir = instalado &&
        servico.categoria == CategoriaDoServico.cotidiano &&
        servico.memoraPodeAbrir &&
        aoPedirAbrir != null;
    final bool marcadoComoNaoInstalado = !instalado &&
        servico.categoria == CategoriaDoServico.cotidiano &&
        servico.memoraPodeAbrir;

    return Cartao(
      padding: const EdgeInsets.all(MemoraEspacamento.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(MemoraEspacamento.xs),
                decoration: BoxDecoration(
                  color: cores.superficieSutil,
                  borderRadius: BorderRadius.circular(MemoraRaio.cartaoMedio),
                  border: ehAltoContraste
                      ? Border.all(
                          color: cores.borda,
                        )
                      : null,
                ),
                child: IconeDoAplicativo(
                  chave: servico.chave,
                  nome: servico.nomeExibido,
                ),
              ),
              const SizedBox(width: MemoraEspacamento.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextoMemora(
                      servico.nomeExibido,
                      estilo: EstiloTexto.tituloSecao,
                    ),
                    const SizedBox(height: MemoraEspacamento.xs),
                    TextoMemora.apoio(servico.descricaoCurta),
                    const SizedBox(height: MemoraEspacamento.sm),
                    BadgeDeStatus(
                      rotulo: marcadoComoNaoInstalado
                          ? TextosAssistente.soEnsinaNaoInstalado
                          : servico.categoria.oQueAMemoraFaz,
                      icone: (servico.memoraPodeAbrir && !marcadoComoNaoInstalado)
                          ? Icons.check_circle_outline_rounded
                          : Icons.school_rounded,
                      tom: (servico.memoraPodeAbrir && !marcadoComoNaoInstalado)
                          ? TomBadgeStatus.positivo
                          : TomBadgeStatus.informativo,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MemoraEspacamento.md),
          if (temGuia) ...<Widget>[
            BotaoSecundario(
              key: TelaCatalogo.chaveDoItem(servico.nomeExibido),
              rotulo: 'Ensinar passo a passo',
              icone: Icons.menu_book_rounded,
              aoTocar: habilitado ? aoAcionarPadrao : null,
            ),
            if (podeAbrir) ...<Widget>[
              const SizedBox(height: MemoraEspacamento.sm),
              BotaoPrimario(
                rotulo: 'Pedir para a Memora abrir',
                icone: Icons.open_in_new_rounded,
                aoTocar: aoPedirAbrir,
              ),
            ],
          ] else
            BotaoSecundario(
              key: TelaCatalogo.chaveDoItem(servico.nomeExibido),
              rotulo: 'Perguntar na conversa',
              icone: Icons.chat_bubble_outline_rounded,
              aoTocar: habilitado ? aoAcionarPadrao : null,
            ),
        ],
      ),
    );
  }
}
