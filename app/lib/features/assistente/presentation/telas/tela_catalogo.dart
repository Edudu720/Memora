import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_assistente.dart';
import '../../domain/assistente.dart';

/// As duas portas de serviços do Hub, numa tela só (T045).
///
/// ## Por que uma tela, e não duas
///
/// *Serviços do dia a dia* e *Meus aplicativos* mostram a mesma coisa com uma
/// regra diferente. Duas telas quase iguais divergem na primeira melhoria feita
/// em uma delas — e a melhoria que a outra não recebe costuma ser exatamente a
/// que importa.
///
/// É a mesma decisão que a `TelaRecuperacao` tomou ao juntar três etapas.
///
/// ## Cada item diz o que esperar, antes do toque
///
/// A FR-045 exige que a pessoa saiba se a Memora **ensina** ou **ensina e
/// abre** antes de entrar. Aqui isso não é letra miúda: é a linha embaixo do
/// nome, na mesma cor do texto comum.
///
/// Descobrir a diferença só ao chegar lá seria uma promessa quebrada — e essa
/// promessa em particular é uma proteção, não um recurso.
class TelaCatalogo extends StatefulWidget {
  /// Chave da lista.
  static const Key chaveLista = Key('catalogo.lista');

  /// Chave de um item, pelo nome do serviço.
  static Key chaveDoItem(String nome) => Key('catalogo.item.$nome');

  /// De onde vêm os serviços.
  final RepositorioAssistente repositorio;

  /// Qual categoria exibir.
  final CategoriaDoServico categoria;

  /// Abre a conversa já perguntando sobre um serviço.
  final void Function(ServicoDoCatalogo servico)? aoEscolher;

  /// Volta ao Hub.
  final VoidCallback? aoVoltar;

  /// Cria a tela de catálogo.
  const TelaCatalogo({
    required this.repositorio,
    required this.categoria,
    this.aoEscolher,
    this.aoVoltar,
    super.key,
  });

  @override
  State<TelaCatalogo> createState() => _TelaCatalogoState();
}

class _TelaCatalogoState extends State<TelaCatalogo> {
  List<ServicoDoCatalogo>? _servicos;
  bool _falhou = false;

  @override
  void initState() {
    super.initState();
    _carregar();
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

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final List<ServicoDoCatalogo>? servicos = _servicos;

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
            // Quem chega aqui procurando o banco precisa entender a regra
            // antes de tocar e se frustrar — e a explicação é o que transforma
            // a recusa em proteção percebida (FR-042).
            if (widget.categoria == CategoriaDoServico.sensivel) ...<Widget>[
              const TextoMemora(
                TextosAssistente.porqueNaoAbroServicoSensivel,
              ),
              const SizedBox(height: MemoraEspacamento.xl),
            ],

            if (_falhou)
              MensagemErro(
                mensagem: TextosAssistente.semConexao,
                aoTentarNovamente: _carregar,
              )
            else if (servicos == null)
              const Carregando()
            else if (servicos.isEmpty)
              const EstadoVazio(
                titulo: TextosAssistente.catalogoVazioTitulo,
                explicacao: TextosAssistente.catalogoVazioExplicacao,
                icone: Icons.apps_outlined,
              )
            else
              for (final ServicoDoCatalogo servico in servicos) ...<Widget>[
                _ItemDoCatalogo(
                  servico: servico,
                  aoEscolher: widget.aoEscolher,
                ),
                const SizedBox(height: MemoraEspacamento.md),
              ],
          ],
        ),
      ),
    );
  }
}

/// Um serviço na lista.
///
/// Usa [BotaoSecundario] porque é ação — abre a conversa sobre aquele serviço.
/// Um serviço na lista, apresentado em cartão com ícone reconhecível do aplicativo (R7).
class _ItemDoCatalogo extends StatelessWidget {
  final ServicoDoCatalogo servico;
  final void Function(ServicoDoCatalogo servico)? aoEscolher;

  const _ItemDoCatalogo({required this.servico, this.aoEscolher});

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final bool habilitado = aoEscolher != null;

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
          onTap: habilitado ? () => aoEscolher!.call(servico) : null,
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
