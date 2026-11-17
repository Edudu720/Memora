import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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

/// Escopo herdado da casca autenticada para que barras superiores empurradas
/// possam incorporar o botão SOS persistente no cabeçalho sem empilhar duas
/// faixas fixas no topo da tela.
class EscopoSosNaCasca extends InheritedWidget {
  /// Rótulo textual exibido no botão SOS (usado para medir se cabe na barra).
  final String rotuloBotao;

  /// Constrói o botão SOS persistente já com a ação configurada pela casca.
  final WidgetBuilder construirBotao;

  /// Notifica a casca quando uma [BarraSuperior] ativa assume (`true`) ou
  /// libera (`false`) a exibição do botão SOS.
  final ValueChanged<bool> aoAlterarBarraAtiva;

  /// Cria o escopo herdado.
  const EscopoSosNaCasca({
    required this.rotuloBotao,
    required this.construirBotao,
    required this.aoAlterarBarraAtiva,
    required super.child,
    super.key,
  });

  /// Retorna o escopo mais próximo, quando a tela está dentro da `CascaInterna`.
  static EscopoSosNaCasca? talvezDe(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EscopoSosNaCasca>();

  @override
  bool updateShouldNotify(EscopoSosNaCasca oldWidget) =>
      rotuloBotao != oldWidget.rotuloBotao ||
      construirBotao != oldWidget.construirBotao ||
      aoAlterarBarraAtiva != oldWidget.aoAlterarBarraAtiva;
}

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

  /// Cria a barra superior.
  const BarraSuperior({
    required this.titulo,
    this.aoVoltar,
    this.acao,
    this.memora,
    super.key,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(MemoraDimensoes.alvoDecisao);

  bool _sosCabeNaLinha(
    BuildContext context, {
    required String rotuloSos,
    required bool ehAltoContraste,
  }) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double escala = scaler.scale(1);
    if (escala >= MemoraDimensoes.escalaColapsoGrade) return false;

    final double larguraBarra =
        MediaQuery.sizeOf(context).width - (MemoraEspacamento.md * 2);
    final double bordaExtra = ehAltoContraste
        ? MemoraDimensoes.bordaEnfase * 2
        : MemoraDimensoes.espessuraBordaSutil * 2;

    double medirLarguraTexto(String texto) {
      final TextPainter tp = TextPainter(
        text: TextSpan(text: texto, style: MemoraTipografia.corpoForte),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      return tp.width;
    }

    final double larguraVoltar = aoVoltar == null
        ? 0
        : (MemoraEspacamento.md * 2) +
              MemoraDimensoes.iconePadrao +
              MemoraEspacamento.xs +
              medirLarguraTexto('Voltar') +
              bordaExtra +
              MemoraEspacamento.sm;
    final double larguraSos =
        (MemoraEspacamento.md * 2) +
        MemoraDimensoes.iconePadrao +
        MemoraEspacamento.xs +
        medirLarguraTexto(rotuloSos) +
        bordaExtra +
        MemoraEspacamento.sm;
    final double larguraDisponivelTitulo =
        larguraBarra -
        larguraVoltar -
        larguraSos -
        (MemoraEspacamento.xs * 2);
    return larguraDisponivelTitulo >= MemoraDimensoes.alvoMinimo;
  }

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final bool mostrarFigura =
        memora != null &&
        MediaQuery.textScalerOf(context).scale(1) <
            CabecalhoDeTela.ampliacaoQueTiraAFigura;
    final EscopoSosNaCasca? escopoSos = EscopoSosNaCasca.talvezDe(context);
    final bool podeAssumirSos =
        escopoSos != null &&
        acao == null &&
        !mostrarFigura &&
        _sosCabeNaLinha(
          context,
          rotuloSos: escopoSos.rotuloBotao,
          ehAltoContraste: ehAltoContraste,
        );

    final Widget? acaoEfetiva = podeAssumirSos
        ? Padding(
            padding: const EdgeInsets.only(left: MemoraEspacamento.sm),
            child: escopoSos.construirBotao(context),
          )
        : acao;

    final Widget conteudo = Material(
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
              minHeight: MemoraDimensoes.alvoDecisao,
            ),
            child: Row(
              children: <Widget>[
                if (aoVoltar != null) ...<Widget>[
                  SuperficieTocavel(
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
                              Icons.arrow_back,
                              color: cores.primaria,
                              size: MemoraDimensoes.iconePadrao,
                            ),
                            const SizedBox(width: MemoraEspacamento.xs),
                            // Palavra escrita: seta sozinha é ambígua.
                            TextoMemora(
                              'Voltar',
                              estilo: EstiloTexto.corpoForte,
                              cor: cores.primaria,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: MemoraEspacamento.sm),
                ],
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MemoraEspacamento.xs,
                    ),
                    child: TextoMemora(
                      titulo,
                      estilo: EstiloTexto.corpoForte,
                      cabecalho: true,
                      maxLinhas: 2,
                    ),
                  ),
                ),
                if (mostrarFigura) ...<Widget>[
                  const SizedBox(width: MemoraEspacamento.sm),
                  MemoraPersonagem(
                    expressao: memora!,
                    tamanho: MemoraDimensoes.alvoMinimo,
                  ),
                ],
                ?acaoEfetiva,
              ],
            ),
          ),
        ),
      ),
    );

    if (escopoSos == null) {
      return conteudo;
    }

    return _MarcadorSosNaBarra(
      escopo: escopoSos,
      assumindo: podeAssumirSos,
      child: conteudo,
    );
  }
}

class _MarcadorSosNaBarra extends StatefulWidget {
  final EscopoSosNaCasca escopo;
  final bool assumindo;
  final Widget child;

  const _MarcadorSosNaBarra({
    required this.escopo,
    required this.assumindo,
    required this.child,
  });

  @override
  State<_MarcadorSosNaBarra> createState() => _MarcadorSosNaBarraState();
}

class _MarcadorSosNaBarraState extends State<_MarcadorSosNaBarra> {
  bool _registrado = false;

  void _atualizarRegistro(bool proximo) {
    if (_registrado == proximo) return;
    _registrado = proximo;
    final ValueChanged<bool> callback = widget.escopo.aoAlterarBarraAtiva;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      callback(proximo);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _atualizarRegistro(widget.assumindo && TickerMode.valuesOf(context).enabled);
  }

  @override
  void didUpdateWidget(covariant _MarcadorSosNaBarra oldWidget) {
    super.didUpdateWidget(oldWidget);
    _atualizarRegistro(widget.assumindo && TickerMode.valuesOf(context).enabled);
  }

  @override
  void dispose() {
    if (_registrado) {
      _registrado = false;
      final ValueChanged<bool> callback = widget.escopo.aoAlterarBarraAtiva;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        callback(false);
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
