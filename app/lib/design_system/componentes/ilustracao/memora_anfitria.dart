import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';

import '../../../l10n/textos_anfitria.dart';
import '../../preferencias/reducao_de_movimento.dart';
import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/elevacao.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/movimento.dart';
import '../../tokens/raio.dart';
import '../conversa/texto_com_negrito.dart';
import '../conversa/texto_da_fala.dart';
import 'memora_animada/gesto_da_memora.dart';
import 'memora_animada/memora_animada.dart';
import 'memora_animada/poses.dart';

/// A anfitriã do Início: a Memora com um balão de dicas (feature 013, T089;
/// FR-048 a FR-058).
///
/// ## O que ela faz
///
/// Flutua, olha em volta, acena de vez em quando e conta uma dica num balão,
/// **mexendo a boca enquanto o texto aparece**. A dica troca sozinha a cada
/// [MemoraMovimento.trocaDeDica]. Tocar nela, ou no balão, faz um gesto e
/// mostra a próxima. É a Memora mais animada do aplicativo.
///
/// ## Quando a dica NÃO troca sozinha (WCAG 2.2.2, FR-053)
///
/// Texto que muda sem a pessoa pedir é um problema para quem lê devagar ou usa
/// leitor de tela. A troca automática **para** quando:
///
/// - o **leitor de tela** está ligado;
/// - "**reduzir movimento**" está ligado (no aplicativo ou no sistema);
/// - a pessoa **tocou** na anfitriã ou no balão: dali em diante só troca
///   quando ela pedir.
///
/// Em qualquer dos três, as dicas continuam ao alcance do toque (FR-054).
///
/// ## O toque é uma ação, e por isso é a exceção da FR-005b
///
/// As outras Memoras são decorativas. A anfitriã tem o toque que **faz algo**
/// (mostra outra dica), então ela é um botão para o leitor de tela: rótulo
/// "Outra dica da Memora", área de pelo menos 48 dp. O balão é lido como
/// texto, e a dica nova só é anunciada quando a pessoa a pediu — a troca
/// automática, quando existe, é silenciosa para o leitor.
///
/// ## O que ela nunca faz
///
/// **Não leva a lugar nenhum** (FR-056): tocar não abre tela, aplicativo nem
/// link. O caminho para conversar com a Memora é o cartão principal do Início.
/// E as dicas vêm de uma lista fixa **dentro do aplicativo** (FR-050): nunca
/// da IA nem do servidor.
///
/// ## Barata
///
/// Um relógio para o intervalo das dicas e o da própria Memora, ambos parados
/// fora da tela (`TickerMode`) e **nenhum** com "reduzir movimento" (FR-057,
/// FR-058).
class MemoraAnfitria extends StatefulWidget {
  /// As dicas, na ordem em que aparecem. Dê sempre uma lista fixa do
  /// aplicativo (`TextosAnfitria.dicas`), nunca texto vindo de fora (FR-050).
  final List<String> dicas;

  /// Por qual dica começa (módulo o tamanho da lista).
  final int indiceInicial;

  /// O lado do quadrado da Memora. A área tocável tem ao menos 48 dp.
  final double tamanho;

  /// A semente do sorteio dos comportamentos. Só para teste.
  final int? sementeDaAgenda;

  /// A chave da área tocável da Memora.
  static const Key chaveDaAcao = ValueKey<String>('anfitria.acao');

  /// A chave do balão.
  static const Key chaveDoBalao = ValueKey<String>('anfitria.balao');

  /// Cria a anfitriã.
  MemoraAnfitria({
    this.dicas = TextosAnfitria.dicas,
    this.indiceInicial = 0,
    this.tamanho = MemoraDimensoes.ilustracaoHeroi,
    this.sementeDaAgenda,
    super.key,
  }) : assert(dicas.isNotEmpty, 'a anfitria precisa de ao menos uma dica');

  @override
  State<MemoraAnfitria> createState() => _MemoraAnfitriaState();
}

class _MemoraAnfitriaState extends State<MemoraAnfitria>
    with SingleTickerProviderStateMixin {
  /// O relógio do intervalo das dicas. Só roda quando a troca automática é
  /// permitida, e para sozinho fora da tela.
  late final Ticker _relogio = createTicker(_aCadaQuadro);

  late int _indice = widget.indiceInicial % widget.dicas.length;

  /// A pessoa já pediu uma dica: a troca automática acabou (FR-053).
  bool _tocou = false;

  bool _reduzir = true;
  bool _leuPreferencia = false;
  bool _leitorDeTela = false;
  bool _telaAtiva = true;

  /// O texto ainda está aparecendo: é o que mexe a boca (FR-051).
  bool _escrevendo = true;

  /// O gesto que a Memora faz agora, ao toque; volta a nulo no quadro seguinte
  /// para o mesmo gesto poder repetir.
  GestoDaMemora? _gesto;
  int _vezes = 0;

  Duration _ultimoQuadro = Duration.zero;
  bool _descartarProximoQuadro = false;
  double _segundos = 0;

  /// A troca automática é permitida agora?
  bool get _trocaSozinha => !_reduzir && !_leitorDeTela && !_tocou;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduzir = context.reduzirMovimento;
    // Mudar a preferência no meio da escrita não deixa a boca presa: o que
    // estava aparecendo aparece inteiro, e a Memora para de falar.
    if (_leuPreferencia && reduzir != _reduzir) _escrevendo = false;
    _leuPreferencia = true;
    _reduzir = reduzir;
    _leitorDeTela = MediaQuery.accessibleNavigationOf(context);

    // O relógio volta de uma parada (a rota de trás reapareceu): o tempo em
    // que esteve parado não é tempo de leitura, e a dica não troca de uma vez.
    final bool ativa = TickerMode.valuesOf(context).enabled;
    if (ativa && !_telaAtiva) _descartarProximoQuadro = true;
    _telaAtiva = ativa;

    _ajustarRelogio();
  }

  @override
  void dispose() {
    _relogio.dispose();
    super.dispose();
  }

  void _ajustarRelogio() {
    if (_trocaSozinha) {
      if (!_relogio.isActive) {
        _ultimoQuadro = Duration.zero;
        _descartarProximoQuadro = false;
        _relogio.start();
      }
    } else if (_relogio.isActive) {
      _relogio.stop();
    }
  }

  void _aCadaQuadro(Duration decorrido) {
    if (_descartarProximoQuadro) {
      _descartarProximoQuadro = false;
      _ultimoQuadro = decorrido;
      return;
    }
    _segundos +=
        (decorrido - _ultimoQuadro).inMicroseconds /
        Duration.microsecondsPerSecond;
    _ultimoQuadro = decorrido;
    if (_segundos * Duration.microsecondsPerSecond >=
        MemoraMovimento.trocaDeDica.inMicroseconds) {
      _mostrarOutra();
    }
  }

  /// Passa para a dica seguinte e recomeça a contagem.
  void _mostrarOutra() {
    setState(() {
      _indice = (_indice + 1) % widget.dicas.length;
      _segundos = 0;
      _escrevendo = true;
    });
  }

  /// A pessoa pediu outra dica: toque na Memora, no balão ou a ação do leitor
  /// de tela (FR-054, FR-055). Nunca navega (FR-056).
  void _pedirOutra() {
    _tocou = true;
    _ajustarRelogio();
    final GestoDaMemora gesto = switch (_vezes % 3) {
      0 => GestoDaMemora.aceno,
      1 => GestoDaMemora.pulinho,
      _ => GestoDaMemora.piscada,
    };
    _vezes++;
    _mostrarOutra();
    setState(() => _gesto = gesto);
    // O gesto volta a nulo no quadro seguinte, para o mesmo poder repetir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _gesto = null);
    });
    if (_leitorDeTela) {
      // Só quando a pessoa pediu: a troca automática nunca chega aqui.
      SemanticsService.sendAnnouncement(
        View.of(context),
        widget.dicas[_indice],
        Directionality.of(context),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool altoContraste = tema.id == MemoraTemaId.altoContraste;
    final String dica = widget.dicas[_indice];
    final int indiceAgora = _indice;

    final Widget memora = Semantics(
      button: true,
      label: TextosAnfitria.rotuloDaAcao,
      onTap: _pedirOutra,
      excludeSemantics: true,
      child: GestureDetector(
        key: MemoraAnfitria.chaveDaAcao,
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: _pedirOutra,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: MemoraDimensoes.alvoMinimo,
            minHeight: MemoraDimensoes.alvoMinimo,
          ),
          // Folga em cima para o pulo e a flutuação não saírem do quadrado.
          child: SizedBox(
            width: widget.tamanho,
            height: widget.tamanho * 1.12,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: MemoraAnimada(
                expressao: _escrevendo && !_reduzir
                    ? PoseDaMemora.falando
                    : PoseDaMemora.neutra,
                tamanho: widget.tamanho,
                falando: _escrevendo,
                reageAoToque: false,
                anfitria: true,
                gesto: _gesto,
                sementeDaAgenda: widget.sementeDaAgenda,
              ),
            ),
          ),
        ),
      ),
    );

    // O balão tem sempre a altura da maior dica (as outras ficam invisíveis,
    // só para medir): o que está embaixo do Início não pula a cada troca.
    final Widget texto = Stack(
      children: <Widget>[
        for (final String d in widget.dicas)
          Visibility(
            visible: false,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: TextoComNegrito(d),
          ),
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: MemoraMovimento.efetiva(
              MemoraMovimento.padrao,
              reduzirMovimento: _reduzir,
            ),
            child: Align(
              key: ValueKey<int>(indiceAgora),
              alignment: Alignment.topLeft,
              child: TextoDaFala(
                dica,
                aosPoucos: !_reduzir,
                aoTerminar: () {
                  if (mounted && _indice == indiceAgora) {
                    setState(() => _escrevendo = false);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );

    final Widget balao = Semantics(
      container: true,
      label: dica,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: _pedirOutra,
        child: Container(
          key: MemoraAnfitria.chaveDoBalao,
          width: double.infinity,
          constraints: const BoxConstraints(
            maxWidth: MemoraDimensoes.larguraMaximaDeLeitura,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraEspacamento.lg,
            vertical: MemoraEspacamento.md,
          ),
          decoration: BoxDecoration(
            color: cores.superficie,
            border: Border.all(
              color: altoContraste ? cores.borda : cores.bordaSutil,
              width: altoContraste
                  ? MemoraDimensoes.bordaEnfase
                  : MemoraDimensoes.espessuraBordaSutil,
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(MemoraRaio.balao),
            ),
            boxShadow: MemoraElevacao.listaSombrasCartao(cores),
          ),
          child: texto,
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        memora,
        const SizedBox(height: MemoraEspacamento.sm),
        balao,
      ],
    );
  }
}
