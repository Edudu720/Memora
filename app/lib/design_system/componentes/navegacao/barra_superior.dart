import 'package:flutter/material.dart';

import '../../preferencias/reducao_de_movimento.dart';
import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../../tokens/tipografia.dart';
import '../ilustracao/memora_personagem.dart';
import '../texto/texto_memora.dart';
import '../toque/superficie_tocavel.dart';
import 'cabecalho_de_tela.dart';
import 'vaga_do_sos.dart';

/// Barra superior do Memora.
///
/// O botão de voltar **sempre traz a palavra "Voltar"** ao lado da seta. Seta
/// isolada é ambígua para quem tem pouca familiaridade digital, e a FR-016
/// proíbe ícone sem rótulo.
class BarraSuperior extends StatelessWidget implements PreferredSizeWidget {
  /// Título da tela.
  final String titulo;

  /// Acionada ao voltar. Quando nula, o botão não aparece.
  final VoidCallback? aoVoltar;

  /// Ação opcional à direita da barra.
  final Widget? acao;

  /// Expressão opcional da Memora exibida no canto direito (ex.: `mini`).
  final ExpressaoDaMemora? memora;

  /// A Memora do canto está falando: um texto está aparecendo aos poucos.
  /// Troca a expressão por `falando` e liga a boca. Sem [memora], não faz nada;
  /// com "reduzir movimento" ligado a Memora fica em repouso, como a anfitriã.
  final bool memoraFalando;

  /// Cria a barra superior.
  const BarraSuperior({
    required this.titulo,
    this.aoVoltar,
    this.acao,
    this.memora,
    this.memoraFalando = false,
    super.key,
  });

  /// A altura que a barra **pode** ter, não a que ela tem.
  ///
  /// O `Scaffold` usa este valor como teto do `appBar`, e a barra mede o
  /// próprio conteúdo: com a letra normal ela tem [MemoraDimensoes.alvoDecisao],
  /// e, dentro da casca, com a letra ampliada cresce o que o título e a
  /// bolinha do SOS pedirem, em vez de cortá-los (feature 014, 2026-11-18).
  /// Fora da casca ela fica nos [MemoraDimensoes.alvoDecisao] de sempre.
  @override
  Size get preferredSize =>
      const Size.fromHeight(MemoraDimensoes.tetoDaBarraSuperior);

  double _larguraDoVoltar(BuildContext context, {required bool altoContraste}) {
    if (aoVoltar == null) return 0;
    final TextPainter medida = TextPainter(
      text: const TextSpan(text: 'Voltar', style: MemoraTipografia.corpoForte),
      textDirection: TextDirection.ltr,
      textScaler: escalaTextoLimitada(context),
      maxLines: 1,
    )..layout();
    final double texto = medida.width;
    medida.dispose();
    final double bordas =
        (altoContraste
            ? MemoraDimensoes.bordaEnfase
            : MemoraDimensoes.espessuraBordaSutil) *
        2;
    return (MemoraEspacamento.md * 2) +
        MemoraDimensoes.iconePadrao +
        MemoraEspacamento.xs +
        texto +
        bordas +
        MemoraEspacamento.sm;
  }

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final bool falando = memoraFalando && !context.reduzirMovimento;
    final bool mostrarFigura =
        memora != null &&
        MediaQuery.textScalerOf(context).scale(1) <
            CabecalhoDeTela.ampliacaoQueTiraAFigura;
    final bool comSos = EscopoSosNaCasca.talvezDe(context) != null;

    // Rígido na linha única (já medido, cabe); com o texto flexível só na
    // linha de cima das duas, onde a largura é limitada pela bolinha.
    Widget? voltar({required bool flexivel}) => aoVoltar == null
        ? null
        : SuperficieTocavel(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: MemoraEspacamento.md,
                ),
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
                    if (flexivel)
                      Flexible(
                        child: TextoMemora(
                          'Voltar',
                          estilo: EstiloTexto.corpoForte,
                          cor: cores.primaria,
                        ),
                      )
                    else
                      TextoMemora(
                        'Voltar',
                        estilo: EstiloTexto.corpoForte,
                        cor: cores.primaria,
                      ),
                  ],
                ),
              ),
            ),
          );

    final Widget titulo = Padding(
      padding: const EdgeInsets.symmetric(horizontal: MemoraEspacamento.xs),
      child: TextoMemora(
        this.titulo,
        estilo: EstiloTexto.corpoForte,
        cabecalho: true,
        maxLinhas: 2,
      ),
    );

    final List<Widget> direita = <Widget>[
      if (mostrarFigura) ...<Widget>[
        const SizedBox(width: MemoraEspacamento.sm),
        MemoraPersonagem(
          expressao: falando ? ExpressaoDaMemora.falando : memora!,
          tamanho: MemoraDimensoes.alvoMinimo,
          falando: falando,
        ),
      ],
      ?acao,
      if (comSos) const VagaDoSos(),
    ];

    Widget linhas(BuildContext contexto, BoxConstraints restricoes) {
      // A ação de fora (o mapa do Localizador) não se mede antes do layout:
      // conta como um alvo mínimo, que é o que ela é hoje.
      double ocupado() =>
          _larguraDoVoltar(contexto, altoContraste: ehAltoContraste) +
          (mostrarFigura
              ? MemoraEspacamento.sm + MemoraDimensoes.alvoMinimo
              : 0) +
          (acao != null ? MemoraDimensoes.alvoMinimo : 0) +
          VagaDoSos.larguraOcupada(contexto) +
          (MemoraEspacamento.xs * 2);
      final bool numaLinha =
          !comSos ||
          VagaDoSos.palavrasCabem(
            contexto,
            texto: this.titulo,
            estilo: MemoraTipografia.corpoForte,
            largura: restricoes.maxWidth - ocupado(),
          );

      if (numaLinha) {
        return Row(
          children: <Widget>[
            if (aoVoltar != null) ...<Widget>[
              voltar(flexivel: false)!,
              const SizedBox(width: MemoraEspacamento.sm),
            ],
            Expanded(child: titulo),
            ...direita,
          ],
        );
      }

      // O título não cabe ao lado do SOS: "Voltar" e SOS ficam na primeira
      // linha, e o título ganha a largura inteira logo abaixo. Nunca se corta
      // palavra do título para caber a bolinha.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            // Sem `Spacer`: ele dividiria a sobra com o "Voltar", que ficaria
            // com metade da linha e quebraria a palavra letra a letra.
            mainAxisAlignment: aoVoltar == null
                ? MainAxisAlignment.end
                : MainAxisAlignment.spaceBetween,
            children: <Widget>[
              if (aoVoltar != null) Flexible(child: voltar(flexivel: true)!),
              Row(mainAxisSize: MainAxisSize.min, children: direita),
            ],
          ),
          const SizedBox(height: MemoraEspacamento.xs),
          titulo,
        ],
      );
    }

    final Widget barra = Material(
      color: cores.fundo,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraEspacamento.md,
            vertical: MemoraEspacamento.xs,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: MemoraDimensoes.alvoMinimo,
            ),
            child: comSos
                ? LayoutBuilder(builder: linhas)
                : linhas(context, const BoxConstraints()),
          ),
        ),
      ),
    );

    // Fora da casca (sem SOS) a barra continua com a altura fixa de antes:
    // o crescimento só existe para caber a bolinha e o título em duas linhas.
    if (comSos) return barra;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight:
            MemoraDimensoes.alvoDecisao + MediaQuery.paddingOf(context).top,
      ),
      child: barra,
    );
  }
}
