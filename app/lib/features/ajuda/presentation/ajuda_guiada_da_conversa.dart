import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/textos_ajuda.dart';

/// A ajuda guiada da conversa: a Memora mostra, passo a passo, como pedir ajuda
/// a ela (T088, FR-034; Figuras 15 a 19 do wireframe).
///
/// ## Cinco telas, uma ideia em cada
///
/// O convite, o que é a conversa (com um exemplo), como escrever, como ela
/// abre um aplicativo — sempre perguntando antes, que é a D1 da 003 dita à
/// pessoa — e a saída. Cada tela é um balão da Memora, e "Continuar" é o único
/// botão em destaque, como no wireframe.
///
/// ## É exemplo, e parece exemplo
///
/// Nada aqui responde ao toque além de "Continuar" e das saídas: a pergunta de
/// abrir o WhatsApp é **texto**, sem botões de Sim e Não. Um "Sim" desabilitado
/// seria a porta pintada na parede (FR-018), e um habilitado abriria um
/// aplicativo numa tela que só ensina. Há um aviso, na tela do exemplo, de que
/// não é preciso escrever nada.
///
/// ## A saída vai direto para a conversa de verdade (FR-034)
///
/// Na última tela, "Conversar com a Memora" chama [aoConversar] **sem tela no
/// meio**. Quem monta o fluxo troca esta tela pela conversa real.
class AjudaGuiadaDaConversa extends StatefulWidget {
  /// Chave do botão que avança, para os testes.
  static const Key chaveContinuar = Key('guiada.continuar');

  /// Chave da saída direta para a conversa.
  static const Key chaveConversar = Key('guiada.conversar');

  /// Chave do botão que volta à Ajuda, na última tela.
  static const Key chaveVoltar = Key('guiada.voltar');

  /// Chave de uma das telas, pelo índice a partir de zero.
  static Key chaveDaTela(int indice) => Key('guiada.tela.$indice');

  /// Abre a conversa de verdade.
  final VoidCallback aoConversar;

  /// Volta à lista de assuntos.
  final VoidCallback aoVoltar;

  /// Cria a ajuda guiada.
  const AjudaGuiadaDaConversa({
    required this.aoConversar,
    required this.aoVoltar,
    super.key,
  });

  @override
  State<AjudaGuiadaDaConversa> createState() => _AjudaGuiadaDaConversaState();
}

class _AjudaGuiadaDaConversaState extends State<AjudaGuiadaDaConversa> {
  int _indice = 0;

  static const int _total = TextosAjuda.totalDeTelasDaConversa;

  bool get _naUltima => _indice == _total - 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.memora.cores.fundo,
      body: SingleChildScrollView(
        // Tela nova começa no topo.
        key: AjudaGuiadaDaConversa.chaveDaTela(_indice),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CabecalhoDeTela(
              titulo: TextosAjuda.tituloConversa,
              aoVoltar: widget.aoVoltar,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MemoraEspacamento.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Semantics(
                    label: TextosAjuda.passoDescrito(
                      TextosAjuda.tituloConversa,
                      _indice + 1,
                      _total,
                    ),
                    child: ExcludeSemantics(
                      child: TextoMemora.apoio(
                        TextosAjuda.passo(_indice + 1, _total),
                      ),
                    ),
                  ),
                  const SizedBox(height: MemoraEspacamento.md),
                  ..._conteudo(),
                  const SizedBox(height: MemoraEspacamento.xl),
                  CaixaDeEtapa(
                    instrucao: TextosAjuda.instrucaoNavegacao,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (_naUltima) ...<Widget>[
                          BotaoPrimario(
                            key: AjudaGuiadaDaConversa.chaveConversar,
                            rotulo: TextosAjuda.guiadaConversar,
                            aoTocar: widget.aoConversar,
                          ),
                          const SizedBox(height: MemoraEspacamento.md),
                          BotaoSecundario(
                            key: AjudaGuiadaDaConversa.chaveVoltar,
                            rotulo: TextosAjuda.guiadaVoltar,
                            aoTocar: widget.aoVoltar,
                          ),
                        ] else
                          BotaoPrimario(
                            key: AjudaGuiadaDaConversa.chaveContinuar,
                            rotulo: TextosAjuda.guiadaContinuar,
                            aoTocar: () => setState(() => _indice++),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: MemoraEspacamento.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// O que cada tela mostra.
  List<Widget> _conteudo() {
    const SizedBox espaco = SizedBox(height: MemoraEspacamento.lg);
    return switch (_indice) {
      0 => const <Widget>[
        BalaoDeFala(
          autor: AutorDoBalao.memora,
          texto: TextosAjuda.guiadaConvite,
        ),
      ],
      1 => const <Widget>[
        BalaoDeFala(autor: AutorDoBalao.memora, texto: TextosAjuda.guiadaOQueE),
        espaco,
        TextoMemora.apoio(TextosAjuda.guiadaSoExemplo),
        espaco,
        BalaoDeFala(
          autor: AutorDoBalao.pessoa,
          texto: TextosAjuda.guiadaPergunta,
        ),
        espaco,
        BalaoDeFala(
          autor: AutorDoBalao.memora,
          texto: TextosAjuda.guiadaResposta,
        ),
      ],
      2 => const <Widget>[
        BalaoDeFala(
          autor: AutorDoBalao.memora,
          texto: TextosAjuda.guiadaComoEscrever,
        ),
      ],
      3 => const <Widget>[
        BalaoDeFala(autor: AutorDoBalao.memora, texto: TextosAjuda.guiadaAbrir),
        espaco,
        TextoMemora.apoio(TextosAjuda.guiadaSoExemplo),
        espaco,
        BalaoDeFala(
          autor: AutorDoBalao.memora,
          texto: TextosAjuda.guiadaPerguntaDeAbrir,
        ),
      ],
      _ => const <Widget>[
        BalaoDeFala(autor: AutorDoBalao.memora, texto: TextosAjuda.guiadaSaida),
      ],
    };
  }
}
