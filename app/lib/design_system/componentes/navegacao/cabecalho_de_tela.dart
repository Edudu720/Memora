import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../ilustracao/ilustracao_memora.dart';
import '../ilustracao/medalhao_de_ilustracao.dart';
import '../ilustracao/memora_personagem.dart';
import '../texto/texto_memora.dart';
import '../toque/superficie_tocavel.dart';

/// O topo de toda tela interna (feature 004, FR-001).
///
/// ## O que é sempre igual
///
/// - **"Voltar" no mesmo canto, com seta e palavra** (US2, cenário 5). Seta
///   sozinha é ambígua para quem tem pouca familiaridade — mesma regra da
///   `BarraSuperior` da 002.
/// - **O título nunca é cortado.** A primeira versão o limitava a duas linhas,
///   com reticências: "Como eu vejo o Memora" saía cortado a 150% nos
///   aparelhos estreitos, e quem amplia o texto perdia justamente o que pediu
///   para ver maior (WCAG 1.4.4, revisão da #38). O leitor de tela recebia o
///   título inteiro — a pessoa que enxerga pouco, não.
///
/// ## A figura cede espaço primeiro
///
/// A ilustração ou o rosto da Memora, à direita, ocupa no máximo uma fração da
/// altura da tela e some abaixo de [MemoraDimensoes.pisoDeIlustracao] — e some
/// também com o texto a partir de 175%, quando o título precisa da largura
/// inteira (regra 7 da R2). O título e o "Voltar", nunca.
///
/// ## Diferença da `BarraSuperior`
///
/// A `BarraSuperior` é a faixa fina da 002, que vai no `appBar`. Este é o
/// cabeçalho da linguagem nova: título grande, figura, e respiro.
class CabecalhoDeTela extends StatelessWidget {
  /// Fração da altura da tela que a figura pode ocupar.
  static const double fracaoDaFigura = 0.11;

  /// A partir desta ampliação de texto a figura sai, e o título fica com a
  /// largura toda.
  static const double ampliacaoQueTiraAFigura = 1.75;

  /// Título da tela.
  final String titulo;

  /// Acionada ao voltar. Nula, o "Voltar" não aparece — é a raiz de um
  /// destino, onde a barra inferior basta.
  final VoidCallback? aoVoltar;

  /// Ilustração à direita do título.
  final Ilustracao? ilustracao;

  /// Ou o rosto da Memora, no lugar da ilustração.
  final ExpressaoDaMemora? memora;

  /// Cria o cabeçalho.
  const CabecalhoDeTela({
    required this.titulo,
    this.aoVoltar,
    this.ilustracao,
    this.memora,
    super.key,
  }) : assert(
         ilustracao == null || memora == null,
         'Ou ilustração, ou a Memora: as duas disputariam o mesmo canto.',
       );

  /// Chave do "Voltar", para os testes.
  static const Key chaveVoltar = Key('cabecalho.voltar');

  /// Chave da figura, para os testes.
  static const Key chaveFigura = Key('cabecalho.figura');

  double? _tamanhoDaFigura(BuildContext context) {
    if (ilustracao == null && memora == null) return null;
    if (MediaQuery.textScalerOf(context).scale(1) >= ampliacaoQueTiraAFigura) {
      return null;
    }
    final double cabe = MediaQuery.sizeOf(context).height * fracaoDaFigura;
    final double tamanho = cabe < MemoraDimensoes.ilustracaoCabecalho
        ? cabe
        : MemoraDimensoes.ilustracaoCabecalho;
    return tamanho < MemoraDimensoes.pisoDeIlustracao ? null : tamanho;
  }

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final double? figura = _tamanhoDaFigura(context);

    return DecoratedBox(
      decoration: BoxDecoration(color: cores.fundo),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            MemoraEspacamento.lg,
            MemoraEspacamento.sm,
            MemoraEspacamento.lg,
            MemoraEspacamento.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (aoVoltar != null) ...<Widget>[
                _Voltar(aoVoltar: aoVoltar!),
                const SizedBox(height: MemoraEspacamento.sm),
              ],
              Row(
                children: <Widget>[
                  Expanded(child: TextoMemora.tituloTela(titulo)),
                  if (figura != null) ...<Widget>[
                    const SizedBox(width: MemoraEspacamento.md),
                    KeyedSubtree(
                      key: chaveFigura,
                      child: memora != null
                          ? MemoraPersonagem(expressao: memora!, tamanho: figura)
                          : MedalhaoDeIlustracao(
                              ilustracao!,
                              tamanho: figura,
                            ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Voltar extends StatelessWidget {
  final VoidCallback aoVoltar;

  const _Voltar({required this.aoVoltar});

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;

    return SuperficieTocavel(
      key: CabecalhoDeTela.chaveVoltar,
      rotulo: 'Voltar',
      aoTocar: aoVoltar,
      fundo: cores.superficieSutil,
      borda: ehAltoContraste ? cores.borda : cores.bordaSutil,
      larguraBorda: ehAltoContraste
          ? MemoraDimensoes.bordaEnfase
          : MemoraDimensoes.espessuraBordaSutil,
      raio: BorderRadius.circular(MemoraRaio.pilula),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: MemoraDimensoes.alvoMinimo,
          minHeight: MemoraDimensoes.alvoMinimo,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: MemoraEspacamento.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.arrow_back_rounded,
                color: cores.primaria,
                size: MemoraDimensoes.iconePadrao,
              ),
              const SizedBox(width: MemoraEspacamento.xs),
              // Palavra escrita: seta sozinha é ambígua.
              Flexible(
                child: TextoMemora(
                  'Voltar',
                  estilo: EstiloTexto.corpoForte,
                  cor: cores.primaria,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
