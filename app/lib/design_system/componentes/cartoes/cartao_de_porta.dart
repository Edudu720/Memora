import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/elevacao.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../ilustracao/ilustracao_memora.dart';
import '../ilustracao/medalhao_de_ilustracao.dart';
import '../texto/texto_memora.dart';
import '../toque/superficie_tocavel.dart';

/// Uma porta: do Hub, da Ajuda, das Configurações (feature 004).
///
/// ## É ação, e por isso é pílula preenchida — não cartão
///
/// "Ação usa pílula e preenchimento; informação nunca usa nenhum dos dois"
/// (FR-012 da 002). O `Cartao` do Design System **não é clicável** de
/// propósito, e um cartão tocável seria a terceira linguagem que essa regra
/// proíbe. Esta é a pílula azul do Hub do wireframe, crescida para caber um
/// desenho e uma linha de explicação.
///
/// A porta [principal] vai em primária; as outras no `destaque`, **com a borda
/// em primária** do `BotaoSecundario`: só o `destaque` mede 1,13:1 contra o
/// fundo claro, e a porta quase sumia (revisão da #38). No máximo uma
/// principal por tela (FR-002) — duas ações de mesmo peso dividem a atenção de
/// quem precisa de um caminho só.
///
/// ## Acabamento de botão, e não de faixa chapada (T113, FR-016, R2 regra 3)
///
/// A revisão de design da T044 achou o Hub "simples demais". O que a porta
/// ganhou, cada coisa **além** da cor:
///
/// - **profundidade**: sombra de [MemoraElevacao.porta] em repouso, que
///   *encolhe* a [MemoraElevacao.portaPressionada] enquanto o dedo está nela,
///   junto com o encolher da própria superfície. É reforço, nunca o sinal
///   (R5): quem não vê sombra tem a pílula e o contorno;
/// - **contorno**: a porta secundária traz a borda em primária; a principal,
///   por ser da cor da própria borda, vale-se da profundidade;
/// - **medalhão que se destaca**: no tema claro o `medalhao` e o `destaque`
///   são o mesmo azul-claro, e o desenho sumia dentro da porta secundária
///   (aviso da #38). O medalhão ganha contorno em primária lá, onde a cor não
///   o separa.
///
/// ## O respiro cresce com a altura, e a seta continua de fora
///
/// A primeira versão do emagrecimento (`d5a5031`) fixou o respiro vertical em
/// 8 dp e tirou a seta, para o Hub caber a 100% no 320×568 (FR-017 antiga). A
/// FR-017 foi reescrita em 2026-10-02: a porta principal precisa aparecer sem
/// rolar em qualquer aparelho, o Hub avisa quando há mais, e o Hub **inteiro**
/// só precisa caber no 360×800 a 100% e 150%. Apertar tudo para o menor
/// aparelho era justamente o "junto demais" da revisão.
///
/// Hoje o respiro é uma **fração da altura da tela**, dividida pela ampliação
/// do texto — ver [respiroVertical] e [afastamentoEntrePortas]. Num aparelho
/// alto ele sobe até o teto; num baixo, ou com texto ampliado, desce até o
/// piso antigo de 8 dp. Teto fixo em pixel só cabe no aparelho em que foi
/// medido (a lição da conversa, PR #28).
///
/// A **seta** ("›") continua fora: custava 44 dp de largura, e o cartão
/// inteiro, sendo pílula preenchida, já diz "toque aqui". O recuo da direita é
/// **geométrico**, e não de gosto — ver o comentário no `build`.
///
/// ## A ilustração cede primeiro
///
/// Com texto ampliado, o nome e a explicação precisam da largura. A partir de
/// [ampliacaoQueTiraAIlustracao] o desenho sai, e o cartão inteiro continua
/// sendo o alvo de toque (regra 7 da R2).
class CartaoDePorta extends StatelessWidget {
  /// A partir desta ampliação de texto o desenho sai.
  static const double ampliacaoQueTiraAIlustracao = 1.75;

  /// O respiro vertical **de dentro** de uma porta, no aparelho e na
  /// ampliação de [context]: entre [MemoraEspacamento.sm] e
  /// [MemoraEspacamento.lg], proporcional à altura da tela.
  static double respiroVertical(BuildContext context) => _crescendo(
    context,
    MemoraDimensoes.fracaoDeRespiroDaPorta,
    MemoraEspacamento.sm,
    MemoraEspacamento.lg,
  );

  /// O afastamento **entre** duas portas empilhadas: entre
  /// [MemoraEspacamento.md] e [MemoraEspacamento.xl], proporcional à altura
  /// da tela.
  static double afastamentoEntrePortas(BuildContext context) => _crescendo(
    context,
    MemoraDimensoes.fracaoDeAfastamentoEntrePortas,
    MemoraEspacamento.md,
    MemoraEspacamento.xl,
  );

  /// Fração da altura da tela, dividida pela ampliação, limitada ao intervalo.
  ///
  /// Divide pela ampliação porque texto maior toma mais altura do mesmo
  /// aparelho: o espaço "livre" em linhas de texto é o que encolhe. A altura é
  /// a da **janela** (`sizeOf`), que não muda com o teclado, e por isso o
  /// respiro não pula quando ele abre.
  static double _crescendo(
    BuildContext context,
    double fracao,
    double piso,
    double teto,
  ) {
    final double altura = MediaQuery.sizeOf(context).height;
    final double ampliacao = math.max(
      1,
      MediaQuery.textScalerOf(context).scale(1),
    );
    return (altura / ampliacao * fracao).clamp(piso, teto);
  }

  /// Nome da porta.
  final String nome;

  /// Uma linha dizendo o que há atrás dela. Quebra em vez de estourar.
  final String explicacao;

  /// O desenho.
  final Ilustracao ilustracao;

  /// Ao abrir. Nula, a porta aparece desabilitada — mas a FR-018 manda não
  /// mostrar porta que não funciona, então isso só existe para a galeria.
  final VoidCallback? aoAbrir;

  /// A ação principal da tela.
  final bool principal;

  /// Cria a porta.
  const CartaoDePorta({
    required this.nome,
    required this.explicacao,
    required this.ilustracao,
    required this.aoAbrir,
    this.principal = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final bool habilitada = aoAbrir != null;
    final Color fundo = !habilitada
        ? cores.superficieAlt
        : (principal ? cores.primaria : cores.destaque);
    final Color texto = !habilitada
        ? cores.textoSuave
        : (principal ? cores.sobrePrimaria : cores.texto);
    final bool comDesenho =
        MediaQuery.textScalerOf(context).scale(1) < ampliacaoQueTiraAIlustracao;
    final double respiro = respiroVertical(context);

    return SuperficieTocavel(
      rotulo: nome,
      dica: explicacao,
      aoTocar: aoAbrir,
      fundo: fundo,
      sombra: habilitada,
      elevacao: MemoraElevacao.porta,
      elevacaoPressionada: MemoraElevacao.portaPressionada,
      corDaSombra: MemoraElevacao.sombraDaPorta,
      raio: BorderRadius.circular(MemoraRaio.porta),
      borda: habilitada && !principal ? cores.primaria : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: MemoraDimensoes.alvoDecisao,
        ),
        child: Padding(
          // O respiro da direita é **geométrico**, e não de gosto: com o raio de
          // 40 da forma, um texto a 8 dp do topo precisa estar a 16 dp da
          // borda direita para a primeira linha não sair da curva (o teste
          // "O texto fica dentro da forma" prova). Sem a seta, a coluna de
          // texto vai até a borda, e é este recuo que a mantém dentro. Com o
          // respiro vertical maior a curva cede mais, e 16 sobra.
          padding: EdgeInsets.fromLTRB(
            MemoraEspacamento.sm,
            respiro,
            MemoraEspacamento.lg,
            respiro,
          ),
          child: Row(
            children: <Widget>[
              if (comDesenho) ...<Widget>[
                MedalhaoDeIlustracao(
                  ilustracao,
                  tamanho: MemoraDimensoes.ilustracaoCartao,
                  // Só onde a cor não separa o medalhão da porta: na
                  // secundária (mesmo azul-claro no tema claro). Na principal
                  // ele já se destaca do preenchimento em primária.
                  contorno: habilitada && !principal ? cores.primaria : null,
                ),
                const SizedBox(width: MemoraEspacamento.md),
              ] else
                // Sem o desenho, o texto encosta na curva da esquerda: o
                // mesmo cálculo do recuo da direita.
                const SizedBox(width: MemoraEspacamento.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextoMemora(
                      nome,
                      estilo: EstiloTexto.corpoForte,
                      cor: texto,
                    ),
                    TextoMemora.apoio(explicacao, cor: texto),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
