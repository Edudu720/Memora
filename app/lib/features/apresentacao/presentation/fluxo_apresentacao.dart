import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/textos_apresentacao.dart';
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

  /// Cria a apresentação.
  const FluxoApresentacao({
    required this.nome,
    required this.idDaConta,
    required this.vista,
    required this.aoConcluir,
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
    setState(() => _indice++);
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

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    const int total = FluxoApresentacao.totalDeTelas;

    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          // Uma tela nova começa no topo: sem a chave, a rolagem da anterior
          // seguia valendo e a pessoa chegava no meio da seguinte.
          key: FluxoApresentacao.chaveDaTela(_indice),
          padding: const EdgeInsets.all(MemoraEspacamento.xl),
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
              const SizedBox(height: MemoraEspacamento.lg),
              ...switch (_indice) {
                0 => _telaOla(),
                1 => _telaConversa(),
                _ => _telaExemplo(),
              },
              const SizedBox(height: MemoraEspacamento.xl),
              BotaoPrimario(
                key: FluxoApresentacao.chaveContinuar,
                rotulo: TextosApresentacao.continuar,
                aoTocar: _continuar,
              ),
              const SizedBox(height: MemoraEspacamento.lg),
            ],
          ),
        ),
      ),
    );
  }

  /// Tela 1: quem ela é e o que ninguém do Memora faz (FR-036a).
  List<Widget> _telaOla() {
    return <Widget>[
      TextoMemora.tituloTela(TextosApresentacao.tituloOla),
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
  List<Widget> _telaExemplo() {
    return <Widget>[
      TextoMemora.tituloTela(TextosApresentacao.tituloExemplo),
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
      const TextoMemora(TextosApresentacao.fechamento),
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
