import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../botoes/botao_secundario.dart';
import '../ilustracao/memora_personagem.dart';
import '../texto/texto_memora.dart';

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
class BalaoDeFala extends StatelessWidget {
  /// Quem fala.
  final AutorDoBalao autor;

  /// O que foi dito. Nulo enquanto a Memora escreve.
  final String? texto;

  /// Opções de resposta. **Só o balão da Memora as mostra**: no da pessoa,
  /// elas são ignoradas — quem oferece escolha é a Memora, nunca a fala de
  /// quem está do outro lado.
  final List<OpcaoDoBalao> opcoes;

  /// Cria uma fala.
  const BalaoDeFala({
    required this.autor,
    required String this.texto,
    this.opcoes = const <OpcaoDoBalao>[],
    super.key,
  });

  /// A Memora escrevendo a resposta.
  ///
  /// É estado, e precisa ser visto por mais de um sinal: o rosto falando, o
  /// texto "escrevendo" e os três pontos — nenhum deles depende de animação,
  /// para valer com "reduzir movimento" ligado (FR-028 da 002).
  const BalaoDeFala.escrevendo({super.key})
    : autor = AutorDoBalao.memora,
      texto = null,
      opcoes = const <OpcaoDoBalao>[];

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
    final MemoraCores cores = context.memora.cores;
    const Radius curvo = Radius.circular(MemoraRaio.cartao);
    const Radius ponta = Radius.circular(MemoraRaio.padrao / 3);

    final Widget balao = Flexible(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: MemoraDimensoes.larguraMaximaDeLeitura,
        ),
        padding: const EdgeInsets.all(MemoraEspacamento.md),
        decoration: BoxDecoration(
          color: _daMemora ? cores.superficie : cores.superficieAlt,
          border: Border.all(color: cores.borda),
          borderRadius: BorderRadius.only(
            topLeft: _daMemora ? ponta : curvo,
            topRight: _daMemora ? curvo : ponta,
            bottomLeft: curvo,
            bottomRight: curvo,
          ),
        ),
        child: Semantics(
          label: texto == null
              ? 'Memora está $textoEscrevendo'
              : '${nomeDe(autor)} disse: $texto',
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextoMemora.apoio(nomeDe(autor)),
                const SizedBox(height: MemoraEspacamento.xs),
                if (texto != null)
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
            expressao: ExpressaoDaMemora.falando,
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
          children: _daMemora
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
