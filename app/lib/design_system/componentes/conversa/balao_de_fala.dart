import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/elevacao.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../botoes/botao_secundario.dart';
import '../ilustracao/memora_personagem.dart';
import '../texto/texto_memora.dart';
import 'texto_com_negrito.dart';
import 'texto_da_fala.dart';

/// Quem fala.
enum AutorDoBalao {
  /// A Memora.
  memora,

  /// A pessoa.
  pessoa,
}

/// Uma opção de resposta oferecida dentro do balão da Memora.
@immutable
class OpcaoDoBalao {
  /// A frase completa — "Sim, pode abrir o WhatsApp", nunca "SIM".
  final String rotulo;

  /// Ao escolher. Nula depois de escolhida, e a opção fica desabilitada.
  final VoidCallback? aoEscolher;

  /// Cria a opção.
  const OpcaoDoBalao({required this.rotulo, required this.aoEscolher});
}

/// Uma fala — na conversa, na apresentação e na ajuda guiada (feature 004).
///
/// ## Quem disse é dito de três formas, nunca só pela cor (FR-020)
///
/// **Posição** (a Memora à esquerda, a pessoa à direita), **desenho** (o
/// rosto da Memora; o desenho de pessoa do outro lado) e **nome escrito**
/// ("Memora", "Você"). O leitor de tela anuncia "Memora disse: …" e "Você
/// disse: …" — sem isso, a conversa lida em voz alta seria um texto corrido
/// sem dono.
///
/// Na **conversa** o desenho sai ([comRosto] falso): a Memora é uma só, no topo
/// da tela (FR-042), e quem fala segue dito pela posição e pelo nome escrito.
///
/// ## O canto que aponta
///
/// O canto do lado de quem fala é menos arredondado: é o "rabinho" do balão
/// do wireframe, sem desenho a mais.
///
/// ## As opções
///
/// Frases completas, empilhadas, cada uma com 56 dp de altura e
/// [MemoraEspacamento.lg] entre elas (FR-021). Lado a lado, como os SIM/NÃO
/// de 24 px do protótipo, o toque errado era questão de tempo. São botões
/// secundários de verdade, com os estados que eles já têm.
///
/// ## Informação, não ação
///
/// O balão em si não aceita toque: só as opções. Fundo neutro e borda, como
/// sempre foi (FR-012 da 002).
///
/// ## A fala da Memora tem negrito e pode ir aparecendo aos poucos
///
/// Na fala da **Memora**, o que está entre `**` vira negrito e os asteriscos
/// não aparecem (FR-020a). A fala da **pessoa** é mostrada como foi digitada:
/// nada nela é interpretado.
///
/// Com [escreverAosPoucos], a fala vai aparecendo letra a letra (FR-020b). O
/// leitor de tela recebe sempre a fala **inteira**, sem marcas — nunca a parte
/// que já apareceu.
class BalaoDeFala extends StatelessWidget {
  /// Quem fala.
  final AutorDoBalao autor;

  /// O que foi dito. Nulo enquanto a Memora escreve.
  final String? texto;

  /// Opções de resposta. **Só o balão da Memora as mostra**: no da pessoa,
  /// elas são ignoradas — quem oferece escolha é a Memora, nunca a fala de
  /// quem está do outro lado.
  final List<OpcaoDoBalao> opcoes;

  /// A fala da Memora vai aparecendo aos poucos, como quem escreve (FR-020b)?
  ///
  /// Só vale para a Memora. Quem usa liga isto apenas na **última** fala dela;
  /// as antigas aparecem inteiras.
  final bool escreverAosPoucos;

  /// O texto ainda está chegando? Faz o `**` ainda aberto valer como negrito
  /// até o fim do que chegou, em vez de mostrar os asteriscos.
  final bool emAndamento;

  /// Chamado a cada letra que entra na tela — para a lista rolar atrás.
  final VoidCallback? aoEscrever;

  /// Avisa quando a escrita aos poucos começa (verdadeiro) e quando para
  /// (falso) — é o que mexe a boca da Memora do topo da conversa (FR-025).
  final ValueChanged<bool>? aoMudarEscrita;

  /// Mostra o rosto de quem fala ao lado do balão? Verdadeiro por padrão.
  ///
  /// A **conversa** desliga (FR-042, FR-043): lá a Memora é uma só, pequena, no
  /// topo, e o balão fica limpo — quem fala continua dito pela posição e pelo
  /// nome escrito ("Memora", "Você"), e pelo leitor de tela.
  final bool comRosto;

  /// Cria uma fala.
  const BalaoDeFala({
    required this.autor,
    required String this.texto,
    this.opcoes = const <OpcaoDoBalao>[],
    this.escreverAosPoucos = false,
    this.emAndamento = false,
    this.aoEscrever,
    this.aoMudarEscrita,
    this.comRosto = true,
    super.key,
  });

  /// A Memora escrevendo a resposta.
  ///
  /// É estado, e precisa ser visto por mais de um sinal: o rosto falando, o
  /// texto "escrevendo" e os três pontos — nenhum deles depende de animação,
  /// para valer com "reduzir movimento" ligado (FR-028 da 002).
  const BalaoDeFala.escrevendo({this.comRosto = true, super.key})
    : autor = AutorDoBalao.memora,
      texto = null,
      opcoes = const <OpcaoDoBalao>[],
      escreverAosPoucos = false,
      emAndamento = false,
      aoEscrever = null,
      aoMudarEscrita = null;

  /// Nome escrito de quem fala.
  static String nomeDe(AutorDoBalao autor) =>
      autor == AutorDoBalao.memora ? 'Memora' : 'Você';

  /// O texto que aparece enquanto a Memora escreve.
  static const String textoEscrevendo = 'escrevendo…';

  /// Separação entre as opções.
  static const double separacaoDasOpcoes = MemoraEspacamento.lg;

  bool get _daMemora => autor == AutorDoBalao.memora;

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    const Radius curvo = Radius.circular(MemoraRaio.balao);
    const Radius ponta = Radius.circular(MemoraRaio.balaoPonta);

    final Color corDeFundo = _daMemora
        ? cores.superficie
        : cores.superficieSutil;

    final Border borda = Border.all(
      color: ehAltoContraste ? cores.borda : cores.bordaSutil,
      width: ehAltoContraste
          ? MemoraDimensoes.bordaEnfase
          : MemoraDimensoes.espessuraBordaSutil,
    );

    final Widget balao = Flexible(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: MemoraDimensoes.larguraMaximaDeLeitura,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: MemoraEspacamento.lg,
          vertical: MemoraEspacamento.md,
        ),
        decoration: BoxDecoration(
          color: corDeFundo,
          border: borda,
          borderRadius: BorderRadius.only(
            topLeft: _daMemora ? ponta : curvo,
            topRight: _daMemora ? curvo : ponta,
            bottomLeft: curvo,
            bottomRight: curvo,
          ),
          boxShadow: MemoraElevacao.listaSombrasCartao(cores),
        ),
        child: Semantics(
          // A fala inteira e sem marcas, nunca a parte que já apareceu: o
          // TalkBack não pode reanunciar a cada letra (FR-020b, FR-020a).
          label: texto == null
              ? 'Memora está $textoEscrevendo'
              : '${nomeDe(autor)} disse: '
                    '${_daMemora ? textoSemMarcas(texto!, emAndamento: emAndamento) : texto}',
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextoMemora.apoio(
                  nomeDe(autor),
                  cor: _daMemora ? cores.primaria : cores.textoSuave,
                ),
                const SizedBox(height: MemoraEspacamento.xs),
                if (texto != null && _daMemora)
                  TextoDaFala(
                    texto!,
                    aosPoucos: escreverAosPoucos,
                    emAndamento: emAndamento,
                    aoAvancar: aoEscrever,
                    aoMudarEscrita: aoMudarEscrita,
                  )
                else if (texto != null)
                  TextoMemora(texto!)
                else
                  TextoMemora('• • •  $textoEscrevendo', cor: cores.textoSuave),
              ],
            ),
          ),
        ),
      ),
    );

    final Widget rosto = _daMemora
        ? MemoraPersonagem(
            expressao: ExpressaoDaMemora.mini,
            tamanho: MemoraDimensoes.pisoDeIlustracao,
          )
        : _RostoDaPessoa(cores: cores);

    return Column(
      crossAxisAlignment: _daMemora
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: _daMemora
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: !comRosto
              ? <Widget>[balao]
              : _daMemora
              ? <Widget>[
                  rosto,
                  const SizedBox(width: MemoraEspacamento.sm),
                  balao,
                ]
              : <Widget>[
                  balao,
                  const SizedBox(width: MemoraEspacamento.sm),
                  rosto,
                ],
        ),
        for (final OpcaoDoBalao opcao
            in _daMemora ? opcoes : const <OpcaoDoBalao>[]) ...<Widget>[
          const SizedBox(height: separacaoDasOpcoes),
          BotaoSecundario(rotulo: opcao.rotulo, aoTocar: opcao.aoEscolher),
        ],
      ],
    );
  }
}

/// O desenho da pessoa no balão dela: um círculo no `destaque` com o ícone.
///
/// Decorativo — o nome escrito e a posição já dizem quem fala.
class _RostoDaPessoa extends StatelessWidget {
  final MemoraCores cores;

  const _RostoDaPessoa({required this.cores});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: MemoraDimensoes.pisoDeIlustracao,
        height: MemoraDimensoes.pisoDeIlustracao,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cores.destaque,
        ),
        child: Icon(
          Icons.person,
          color: cores.primaria,
          size: MemoraDimensoes.iconePadrao,
        ),
      ),
    );
  }
}
