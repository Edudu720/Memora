import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/textos_apresentacao.dart';
import '../../../l10n/textos_casca.dart';
import '../../casca/casca_interna.dart';
import '../data/apresentacao_vista.dart';

/// A apresentação inicial da Memora, em três telas curtas (US1, FR-012).
///
/// Olá (quem ela é, e o que ninguém do Memora faz — FR-036a), Apresentação
/// (para que serve a conversa) e Exemplo (a conversa por dentro). Cada uma tem
/// "Continuar" e "Pular", sempre nos mesmos lugares.
///
/// ## Quando conta como vista (FR-013)
///
/// Só **ao chegar ao fim ou ao pular**: é aí, e em nenhum outro ponto, que a
/// conta vai para a [ApresentacaoVista]. Fechar o aplicativo no meio não grava
/// nada, e a apresentação recomeça do início — gravar a cada tela faria quem
/// foi interrompida na primeira nunca mais vê-la.
///
/// ## Gravar nunca prende a pessoa
///
/// Se o aparelho recusar a gravação, a pessoa segue para o Início do mesmo
/// jeito. O preço é ver a apresentação outra vez na próxima entrada; o preço
/// do contrário seria uma tela da qual não se sai.
///
/// ## O "voltar" do aparelho
///
/// Na tela 2 ou 3, volta uma tela, **sem gravar nada** (FR-013). Na 1, faz a
/// mesma pergunta da casca ("Fechar o Memora?"): fechar em silêncio é o
/// Memora sumir (Princípio II).
class FluxoApresentacao extends StatefulWidget {
  /// Quantas telas tem a apresentação (FR-012: no máximo três).
  static const int totalDeTelas = 3;

  /// Chave do botão que avança.
  static const Key chaveContinuar = Key('apresentacao.continuar');

  /// Chave do botão que pula.
  static const Key chavePular = Key('apresentacao.pular');

  /// Chave do quadro do que a Memora nunca faz (FR-036a).
  static const Key chaveNuncaFaco = Key('apresentacao.nunca_faco');

  /// Chave da tela de número [indice], de 0 a 2.
  static Key chaveDaTela(int indice) => Key('apresentacao.tela.$indice');

  /// Como a pessoa quer ser chamada.
  final String nome;

  /// A conta que vê a apresentação.
  final String idDaConta;

  /// Onde registrar que ela viu.
  final ApresentacaoVista vista;

  /// Chamada quando a apresentação termina, **por qualquer dos dois
  /// caminhos** — o fim ou o pulo — e depois de tentar gravar.
  final VoidCallback aoConcluir;

  /// Fecha o aplicativo, depois de a pessoa confirmar. O teste troca por um
  /// contador.
  final Future<void> Function() aoFecharOMemora;

  /// Cria a apresentação.
  const FluxoApresentacao({
    required this.nome,
    required this.idDaConta,
    required this.vista,
    required this.aoConcluir,
    this.aoFecharOMemora = CascaInterna.fecharOAplicativo,
    super.key,
  });

  @override
  State<FluxoApresentacao> createState() => _FluxoApresentacaoState();
}

class _FluxoApresentacaoState extends State<FluxoApresentacao> {
  int _indice = 0;

  /// Dois toques seguidos em "Pular" não podem concluir duas vezes.
  bool _concluindo = false;

  bool get _naUltima => _indice == FluxoApresentacao.totalDeTelas - 1;

  void _continuar() {
    if (_naUltima) {
      _concluir();
      return;
    }
    _irParaTela(_indice + 1);
  }

  /// Os títulos das telas, na ordem — o que o leitor de tela anuncia.
  static const List<String> _titulos = <String>[
    TextosApresentacao.tituloOla,
    TextosApresentacao.tituloConversa,
    TextosApresentacao.tituloExemplo,
  ];

  /// Troca de tela e **anuncia** a nova.
  ///
  /// Trocar a `key` recria a subárvore, e o leitor de tela não percebe que a
  /// tela mudou: quem não enxerga ficaria ouvindo o silêncio depois do toque em
  /// "Continuar". O título é lido; a posição ("passo 2 de 3") já está no
  /// começo da tela.
  void _irParaTela(int indice) {
    setState(() => _indice = indice);
    SemanticsService.sendAnnouncement(
      View.of(context),
      _titulos[indice],
      Directionality.of(context),
    );
  }

  Future<void> _concluir() async {
    if (_concluindo) return;
    _concluindo = true;
    try {
      await widget.vista.marcarComoVista(widget.idDaConta);
    } catch (erro) {
      debugPrint(
        'Apresentacao: nao foi possivel gravar que foi vista ($erro).',
      );
    }
    if (!mounted) return;
    widget.aoConcluir();
  }

  Future<void> _voltarDoAparelho() async {
    if (_indice > 0) {
      _irParaTela(_indice - 1);
      return;
    }
    bool fechar = false;
    await DialogoMemora.mostrar(
      context,
      dialogo: DialogoMemora(
        key: CascaInterna.chavePerguntaDeFechar,
        titulo: TextosCasca.tituloSairDoMemora,
        mensagem: TextosCasca.perguntaSairDoMemora,
        rotuloConfirmar: TextosCasca.botaoFecharMemora,
        aoConfirmar: () {
          fechar = true;
          Navigator.of(context).pop();
        },
        rotuloFechar: TextosCasca.botaoFicar,
        aoFechar: () => Navigator.of(context).pop(),
      ),
    );
    if (fechar) await widget.aoFecharOMemora();
  }

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final double escala = MediaQuery.textScalerOf(context).scale(1);
    final bool compacto = escala >= MemoraDimensoes.escalaColapsoGrade;
    final bool ocultarVisuais = escala >= MemoraDimensoes.escalaTextoAlta;
    const int total = FluxoApresentacao.totalDeTelas;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool saiu, Object? _) {
        if (!saiu) _voltarDoAparelho();
      },
      child: Scaffold(
        backgroundColor: cores.fundo,
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: cores.superficieBarra,
            border: Border(
              top: BorderSide(
                color: ehAltoContraste ? cores.borda : cores.bordaSutil,
                width: ehAltoContraste
                    ? MemoraDimensoes.bordaEnfase
                    : MemoraDimensoes.espessuraBordaSutil,
              ),
            ),
            boxShadow: MemoraElevacao.listaSombrasBarra(cores),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MemoraEspacamento.lg,
                vertical: compacto ? MemoraEspacamento.sm : MemoraEspacamento.md,
              ),
              child: BotaoPrimario(
                key: FluxoApresentacao.chaveContinuar,
                rotulo: TextosApresentacao.continuar,
                icone: Icons.arrow_forward,
                aoTocar: _continuar,
              ),
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            // Uma tela nova começa no topo: sem a chave, a rolagem da anterior
            // seguia valendo e a pessoa chegava no meio da seguinte.
            key: FluxoApresentacao.chaveDaTela(_indice),
            padding: EdgeInsets.all(
              compacto ? MemoraEspacamento.lg : MemoraEspacamento.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Semantics(
                        label: TextosApresentacao.passoDescrito(
                          _indice + 1,
                          total,
                        ),
                        child: ExcludeSemantics(
                          child: TextoMemora.apoio(
                            TextosApresentacao.passo(_indice + 1, total),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: MemoraEspacamento.sm),
                    BotaoTerciario(
                      key: FluxoApresentacao.chavePular,
                      rotulo: TextosApresentacao.pular,
                      aoTocar: _concluir,
                    ),
                  ],
                ),
                const SizedBox(height: MemoraEspacamento.sm),
                // Indicadores editoriais de página em pílula.
                Row(
                  children: <Widget>[
                    for (int i = 0; i < total; i++) ...<Widget>[
                      Expanded(
                        flex: i == _indice ? 2 : 1,
                        child: Container(
                          height: MemoraDimensoes.alturaIndicadorDePasso,
                          decoration: BoxDecoration(
                            color: i <= _indice
                                ? cores.primaria
                                : cores.destaque,
                            borderRadius: BorderRadius.circular(
                              MemoraRaio.pilula,
                            ),
                            border: ehAltoContraste && i > _indice
                                ? Border.all(
                                    color: cores.borda,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      if (i < total - 1)
                        const SizedBox(width: MemoraEspacamento.xs),
                    ],
                  ],
                ),
                const SizedBox(height: MemoraEspacamento.lg),
                ...switch (_indice) {
                  0 => _telaOla(ocultarVisuais),
                  1 => _telaConversa(),
                  _ => _telaExemplo(ocultarVisuais),
                },
                const SizedBox(height: MemoraEspacamento.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tela 1: quem ela é e o que ninguém do Memora faz (FR-036a).
  List<Widget> _telaOla(bool ocultarVisuais) {
    return <Widget>[
      Row(
        children: <Widget>[
          Expanded(
            child: TextoMemora.tituloTela(TextosApresentacao.tituloOla),
          ),
          if (!ocultarVisuais) ...<Widget>[
            const SizedBox(width: MemoraEspacamento.md),
            const MemoraPersonagem(
              tamanho: MemoraDimensoes.alvoDecisao,
            ),
          ],
        ],
      ),
      const SizedBox(height: MemoraEspacamento.lg),
      BalaoDeFala(
        autor: AutorDoBalao.memora,
        texto: TextosApresentacao.ola(widget.nome),
      ),
      const SizedBox(height: MemoraEspacamento.xl),
      Cartao(
        key: FluxoApresentacao.chaveNuncaFaco,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextoMemora.tituloSecao(TextosApresentacao.tituloNunca),
            const SizedBox(height: MemoraEspacamento.md),
            for (final String frase
                in TextosApresentacao.nuncaFaco) ...<Widget>[
              TextoMemora(frase),
              const SizedBox(height: MemoraEspacamento.md),
            ],
            TextoMemora(
              TextosApresentacao.seAlguemPedir,
              estilo: EstiloTexto.apoio,
            ),
          ],
        ),
      ),
    ];
  }

  /// Tela 2: para que serve a conversa.
  List<Widget> _telaConversa() {
    return <Widget>[
      TextoMemora.tituloTela(TextosApresentacao.tituloConversa),
      const SizedBox(height: MemoraEspacamento.lg),
      const BalaoDeFala(
        autor: AutorDoBalao.memora,
        texto: TextosApresentacao.conversa,
      ),
      const SizedBox(height: MemoraEspacamento.lg),
      const BalaoDeFala(
        autor: AutorDoBalao.memora,
        texto: TextosApresentacao.ensinoNaoSubstituo,
      ),
    ];
  }

  /// Tela 3: a conversa por dentro, só de demonstração.
  List<Widget> _telaExemplo(bool ocultarVisuais) {
    return <Widget>[
      Row(
        children: <Widget>[
          Expanded(
            child: TextoMemora.tituloTela(TextosApresentacao.tituloExemplo),
          ),
          if (!ocultarVisuais) ...<Widget>[
            const SizedBox(width: MemoraEspacamento.md),
            const MemoraPersonagem(
              expressao: ExpressaoDaMemora.dica,
              tamanho: MemoraDimensoes.alvoDecisao,
            ),
          ],
        ],
      ),
      const SizedBox(height: MemoraEspacamento.sm),
      TextoMemora.apoio(TextosApresentacao.avisoDoExemplo),
      const SizedBox(height: MemoraEspacamento.lg),
      const BalaoDeFala(
        autor: AutorDoBalao.pessoa,
        texto: TextosApresentacao.exemploPergunta,
      ),
      const SizedBox(height: MemoraEspacamento.lg),
      const BalaoDeFala(
        autor: AutorDoBalao.memora,
        texto: TextosApresentacao.exemploResposta,
      ),
      const SizedBox(height: MemoraEspacamento.lg),
      const Cartao(
        padding: EdgeInsets.all(MemoraEspacamento.md),
        child: TextoMemora(TextosApresentacao.fechamento),
      ),
    ];
  }
}

/// O instante entre entrar e saber se a pessoa já viu a apresentação.
///
/// Dura quase nada, mas existe: tela em branco, por um quadro que seja, é o
/// que faz este público achar que o aparelho travou (FR-006).
class TelaPreparandoApresentacao extends StatelessWidget {
  /// Cria a tela de espera.
  const TelaPreparandoApresentacao({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.memora.cores.fundo,
      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(MemoraEspacamento.xl),
            child: Carregando(mensagem: TextosApresentacao.preparando),
          ),
        ),
      ),
    );
  }
}
