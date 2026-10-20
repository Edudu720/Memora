import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_assistente.dart';
import '../../../../services/aplicativos/consulta_de_aplicativos.dart';
import '../../../aprendizado/data/guias/guias.dart';
import '../../../aprendizado/domain/busca.dart';
import '../../../aprendizado/domain/guia.dart';
import '../../domain/assistente.dart';

/// As duas portas de serviços do Hub, numa tela só (T045, T069, FR-023).
///
/// ## Por que uma tela, e não duas
///
/// *Serviços do dia a dia* e *Meus aplicativos* mostram a mesma coisa com uma
/// regra diferente. Duas telas quase iguais divergem na primeira melhoria feita
/// em uma delas — e a melhoria que a outra não recebe costuma ser exatamente a
/// que importa.
///
/// ## Busca no topo (FR-023)
///
/// O catálogo inclui uma busca tolerante por trecho, sem acento e sem caixa alta
/// (T068), permitindo localizar o aplicativo ou serviço de forma ágil.
///
/// ## Cada item diz o que esperar, antes do toque
///
/// A FR-045 exige que a pessoa saiba se a Memora **ensina** ou **ensina e
/// abre** antes de entrar. Se o item tiver guia de aprendizado embarcado, o toque
/// abre o passo a passo; caso contrário, abre a conversa com a pergunta inicial
/// (contracts/catalogo.md).
class TelaCatalogo extends StatefulWidget {
  /// Chave da lista.
  static const Key chaveLista = Key('catalogo.lista');

  /// Chave do campo de busca.
  static const Key chaveBusca = Key('catalogo.busca');

  /// Chave de um item, pelo nome do serviço.
  static Key chaveDoItem(String nome) => Key('catalogo.item.$nome');

  /// De onde vêm os serviços.
  final RepositorioAssistente repositorio;

  /// Qual categoria exibir.
  final CategoriaDoServico categoria;

  /// Abre a conversa já perguntando sobre um serviço.
  final void Function(ServicoDoCatalogo servico)? aoEscolher;

  /// Abre o guia passo a passo quando disponível.
  final void Function(Guia guia, ServicoDoCatalogo servico)? aoAbrirGuia;

  /// Consulta de plataforma dos aplicativos instalados (se disponível).
  final ConsultaDeAplicativos? consultaAplicativos;

  /// Volta ao Hub.
  final VoidCallback? aoVoltar;

  /// Estado de teste forçado (FR-006).
  final String? estadoDeTeste;

  /// Cria a tela de catálogo.
  const TelaCatalogo({
    required this.repositorio,
    required this.categoria,
    this.aoEscolher,
    this.aoAbrirGuia,
    this.consultaAplicativos,
    this.aoVoltar,
    this.estadoDeTeste,
    super.key,
  });

  @override
  State<TelaCatalogo> createState() => _TelaCatalogoState();
}

class _TelaCatalogoState extends State<TelaCatalogo> {
  List<ServicoDoCatalogo>? _servicos;
  bool _falhou = false;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void didUpdateWidget(covariant TelaCatalogo antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.categoria != widget.categoria ||
        antigo.repositorio != widget.repositorio) {
      _carregar();
    }
  }

  Future<void> _carregar() async {
    try {
      final List<ServicoDoCatalogo> todos = await widget.repositorio.catalogo();
      if (!mounted) return;
      setState(() {
        _servicos = todos
            .where((ServicoDoCatalogo s) => s.categoria == widget.categoria)
            .toList();
        _falhou = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() => _falhou = true);
    }
  }

  String get _titulo => switch (widget.categoria) {
        CategoriaDoServico.sensivel => TextosAssistente.portaServicos,
        CategoriaDoServico.cotidiano => TextosAssistente.portaAplicativos,
      };

  void _aoTocar(ServicoDoCatalogo servico) {
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
    if (widget.estadoDeTeste == 'carregando' || (_servicos == null && !_falhou)) {
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

    final List<ServicoDoCatalogo> servicos = _servicos!;
    if (widget.estadoDeTeste == 'vazio' || servicos.isEmpty) {
      return Scaffold(
        backgroundColor: cores.fundo,
        appBar: BarraSuperior(titulo: _titulo, aoVoltar: widget.aoVoltar),
        body: const Center(
          child: EstadoVazio(
            titulo: TextosAssistente.catalogoVazioTitulo,
            explicacao: TextosAssistente.catalogoVazioExplicacao,
            icone: Icons.apps_outlined,
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
        child: ListView(
          key: TelaCatalogo.chaveLista,
          padding: const EdgeInsets.all(MemoraEspacamento.lg),
          children: <Widget>[
            // Para os serviços sensíveis, a explicação vem ANTES da lista.
            if (widget.categoria == CategoriaDoServico.sensivel) ...<Widget>[
              const TextoMemora(
                TextosAssistente.porqueNaoAbroServicoSensivel,
              ),
              const SizedBox(height: MemoraEspacamento.xl),
            ],

            // Busca no topo (FR-023)
            CampoTexto(
              key: TelaCatalogo.chaveBusca,
              rotulo: TextosAssistente.rotuloBuscaAplicativos,
              textoAjuda: TextosAssistente.ajudaBuscaAplicativos,
              aoMudar: (String valor) => setState(() => _busca = valor),
            ),
            const SizedBox(height: MemoraEspacamento.lg),

            if (exibidos.isEmpty)
              const EstadoVazio(
                titulo: 'Nenhum aplicativo encontrado',
                explicacao: 'Tente buscar com outras palavras ou apague a busca.',
                icone: Icons.search_off,
              )
            else
              for (final ServicoDoCatalogo servico in exibidos) ...<Widget>[
                _ItemDoCatalogo(
                  servico: servico,
                  aoTocar: () => _aoTocar(servico),
                  habilitado: widget.aoEscolher != null || widget.aoAbrirGuia != null,
                ),
                const SizedBox(height: MemoraEspacamento.md),
              ],
          ],
        ),
      ),
    );
  }
}

/// Um serviço na lista, apresentado em cartão com ícone reconhecível do aplicativo (R7).
class _ItemDoCatalogo extends StatelessWidget {
  final ServicoDoCatalogo servico;
  final VoidCallback aoTocar;
  final bool habilitado;

  const _ItemDoCatalogo({
    required this.servico,
    required this.aoTocar,
    required this.habilitado,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Semantics(
      button: true,
      enabled: habilitado,
      label: '${servico.nomeExibido}. ${servico.descricaoCurta}. ${servico.categoria.oQueAMemoraFaz}',
      child: Material(
        key: TelaCatalogo.chaveDoItem(servico.nomeExibido),
        color: cores.superficie,
        elevation: MemoraElevacao.cartao,
        shadowColor: MemoraElevacao.sombra,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MemoraRaio.cartao),
          side: BorderSide(
            color: cores.borda.withValues(alpha: 0.35),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(MemoraRaio.cartao),
          onTap: habilitado ? aoTocar : null,
          child: Padding(
            padding: const EdgeInsets.all(MemoraEspacamento.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Ícone reconhecível do aplicativo (WhatsApp, Facebook, etc.)
                IconeDoAplicativo(
                  chave: servico.chave,
                  nome: servico.nomeExibido,
                ),
                const SizedBox(width: MemoraEspacamento.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextoMemora(
                              servico.nomeExibido,
                              estilo: EstiloTexto.destaque,
                            ),
                          ),
                          Icon(
                            servico.memoraPodeAbrir
                                ? Icons.open_in_new_rounded
                                : Icons.arrow_forward_ios_rounded,
                            size: MemoraDimensoes.iconePequeno,
                            color: cores.primaria,
                          ),
                        ],
                      ),
                      const SizedBox(height: MemoraEspacamento.xs),
                      TextoMemora.apoio(servico.descricaoCurta),
                      const SizedBox(height: MemoraEspacamento.sm),
                      // Rótulo de permissão e aprendizado (FR-045)
                      Row(
                        children: <Widget>[
                          Icon(
                            servico.memoraPodeAbrir
                                ? Icons.check_circle_outline
                                : Icons.school_outlined,
                            size: MemoraDimensoes.iconePequeno,
                            color: servico.memoraPodeAbrir
                                ? cores.sucesso
                                : cores.textoSuave,
                          ),
                          const SizedBox(width: MemoraEspacamento.xs),
                          Expanded(
                            child: TextoMemora.apoio(
                              servico.categoria.oQueAMemoraFaz,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
