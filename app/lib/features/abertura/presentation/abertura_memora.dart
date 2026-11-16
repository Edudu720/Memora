import 'dart:async';

import 'package:flutter/material.dart';

import '../../../design_system/componentes/botoes/botao_primario.dart';
import '../../../design_system/componentes/ilustracao/memora_animada/gesto_da_memora.dart';
import '../../../design_system/componentes/ilustracao/memora_animada/memora_animada.dart';
import '../../../design_system/componentes/ilustracao/memora_animada/poses.dart';
import '../../../design_system/componentes/texto/texto_memora.dart';
import '../../../design_system/preferencias/reducao_de_movimento.dart';
import '../../../design_system/temas/memora_theme_extension.dart';
import '../../../design_system/tokens/abertura.dart';
import '../../../design_system/tokens/espacamento.dart';
import '../../../design_system/tokens/movimento.dart';
import '../../../l10n/textos_abertura.dart';

/// Em que ponto está a abertura (feature 013, data-model.md).
///
/// `carregando` → (`pronto` **e** aceno concluído) → `saindo`. Dois ramos:
/// `demorando` (passou de 4 s: aparece a frase) e `falhou` (vai à tela de
/// erro).
enum EstadoDaAbertura {
  /// A Memora acena e o aplicativo carrega por baixo.
  carregando,

  /// Passou de 4 s: a frase "Estou quase pronta." aparece.
  demorando,

  /// Carregou e o aceno completou: a abertura esmaece e entrega o resultado.
  saindo,

  /// O carregamento falhou: a tela de erro, com a Memora e uma saída.
  falhou,
}

/// A tela de carregamento: a Memora acenando enquanto o aplicativo termina de
/// carregar (feature 013, US7; FR-036 a FR-039, R9).
///
/// ## Por que existe
///
/// A abertura nativa do Android não roda animação do aplicativo (ele ainda não
/// existe nesse instante). A única forma de a Memora acenar é o aplicativo
/// subir primeiro e carregar depois: o `main.dart` chama o `runApp` com esta
/// tela **antes** de ler as preferências, e o que antes era feito antes do
/// `runApp` passa a ser o [carregar] daqui.
///
/// ## O que garante
///
/// - **Sai quando carregou e o aceno em curso completou** — nunca antes de
///   carregar, e nunca mais que um aceno depois (FR-038, SC-009). A abertura
///   não é prolongada de propósito.
/// - **Demora calma**: se o carregamento se estende, a Memora segue acenando
///   com um descanso entre um aceno e outro, sem acelerar nem piscar. Passados
///   [MemoraAbertura.limiteDaDemora], uma frase curta diz que está quase
///   pronto.
/// - **Falha não prende**: a tela de erro, com a Memora e "Tentar de novo".
/// - **Reduzir movimento** (aqui, o do **sistema**: as preferências do
///   aplicativo ainda não existem): a Memora fica parada em pose de aceno,
///   nenhum relógio roda, e a abertura sai assim que carrega (FR-039).
/// - **Decorativa para o leitor de tela**: a Memora não é anunciada; a frase
///   de espera é um aviso.
///
/// Fica **sob** um `MaterialApp` que dê o tema (claro ou escuro do sistema) e
/// o `MediaQuery` do aparelho.
class AberturaMemora<T> extends StatefulWidget {
  /// O trabalho que antes rodava antes do `runApp`.
  final Future<T> Function() carregar;

  /// Entrega o resultado do carregamento e sai.
  final void Function(T resultado) aoConcluir;

  /// Avisa que o carregamento falhou (a tela de erro já está na tela). Serve a
  /// quem quiser registrar a falha; a pessoa nunca vê o [Object].
  final void Function(Object erro)? aoFalhar;

  /// Cria a abertura.
  const AberturaMemora({
    required this.carregar,
    required this.aoConcluir,
    this.aoFalhar,
    super.key,
  });

  @override
  State<AberturaMemora<T>> createState() => _AberturaMemoraState<T>();
}

class _AberturaMemoraState<T> extends State<AberturaMemora<T>>
    with SingleTickerProviderStateMixin {
  EstadoDaAbertura _estado = EstadoDaAbertura.carregando;

  /// O carregamento terminou, e [_resultado] vale.
  bool _pronto = false;
  T? _resultado;

  /// Há um aceno em curso (ou prestes a começar). Verdadeiro de saída: a
  /// Memora começa acenando ao entrar.
  bool _acenoEmCurso = true;

  /// Se o sistema pediu menos movimento. Lido uma vez de saída e de novo se
  /// mudar.
  bool _reduzir = true;
  bool _leuOMovimento = false;

  /// Cada carregamento tem a sua geração: a resposta de um carregamento
  /// antigo (antes de "Tentar de novo") não vale mais.
  int _geracao = 0;

  /// O relógio dos acenos: um aceno e o descanso até o seguinte. Só existe
  /// quando há movimento permitido.
  AnimationController? _ciclo;

  /// Quanto do ciclo é aceno, de 0 a 1.
  late final double _fracaoDoAceno =
      MemoraMovimento.aceno.inMicroseconds /
      (MemoraMovimento.aceno + MemoraAbertura.pausaEntreAcenos).inMicroseconds;

  /// O gesto que se repete a cada ciclo. O primeiro aceno é o da própria
  /// chegada da pose; os seguintes são pedidos por aqui.
  GestoDaMemora? _gesto;

  Timer? _relogioDaDemora;
  bool _saiu = false;

  @override
  void initState() {
    super.initState();
    // O primeiro quadro (a Memora acenando) vai para a tela **antes** de o
    // carregamento começar: o trabalho pesado não atrasa o que a pessoa vê.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _comecarACarregar();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduzir = context.reduzirMovimento;
    if (_leuOMovimento && reduzir == _reduzir) return;
    _leuOMovimento = true;
    _reduzir = reduzir;
    if (_reduzir) {
      // Sem movimento: nenhum relógio, e nenhum aceno a esperar.
      _ciclo?.stop();
      _acenoEmCurso = false;
      _tentarSair();
    } else {
      _acenoEmCurso = true;
      _iniciarOCiclo();
    }
  }

  void _iniciarOCiclo() {
    final AnimationController ciclo = _ciclo ??=
        AnimationController(
            vsync: this,
            duration: MemoraMovimento.efetiva(
              MemoraMovimento.aceno + MemoraAbertura.pausaEntreAcenos,
              reduzirMovimento: _reduzir,
            ),
          )
          ..addListener(_aoAndarOCiclo)
          ..addStatusListener(_aoMudarOStatusDoCiclo);
    ciclo.forward(from: 0);
  }

  /// O aceno em curso termina quando o ciclo passa da fração dele.
  void _aoAndarOCiclo() {
    if (_acenoEmCurso && _ciclo!.value >= _fracaoDoAceno) {
      _acenoEmCurso = false;
      _tentarSair();
    }
  }

  /// Acabou o descanso: outro aceno, se ainda estamos esperando.
  void _aoMudarOStatusDoCiclo(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_saiu ||
        _estado == EstadoDaAbertura.saindo ||
        _estado == EstadoDaAbertura.falhou) {
      return;
    }
    _acenoEmCurso = true;
    // O gesto precisa voltar a `null` por um quadro para o mesmo aceno poder
    // ser pedido de novo (ver `MemoraAnimada.gesto`).
    setState(() => _gesto = null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _estado != EstadoDaAbertura.falhou) {
        setState(() => _gesto = GestoDaMemora.aceno);
      }
    });
    _ciclo!.forward(from: 0);
  }

  void _comecarACarregar() {
    final int geracao = ++_geracao;
    _relogioDaDemora?.cancel();
    _relogioDaDemora = Timer(MemoraAbertura.limiteDaDemora, () {
      if (mounted && _estado == EstadoDaAbertura.carregando) {
        setState(() => _estado = EstadoDaAbertura.demorando);
      }
    });
    widget.carregar().then<void>(
      (T resultado) {
        if (!mounted || geracao != _geracao) return;
        _pronto = true;
        _resultado = resultado;
        _tentarSair();
      },
      onError: (Object erro, StackTrace _) {
        if (!mounted || geracao != _geracao) return;
        _falhou(erro);
      },
    );
  }

  /// Sai quando as duas coisas são verdade: carregou **e** não há aceno em
  /// curso. É o único lugar que decide sair.
  void _tentarSair() {
    if (!_pronto || _acenoEmCurso || _saiu) return;
    if (_estado == EstadoDaAbertura.saindo ||
        _estado == EstadoDaAbertura.falhou) {
      return;
    }
    _relogioDaDemora?.cancel();
    _ciclo?.stop();
    if (_reduzir) {
      // Sem movimento não há esmaecer: sai já.
      _entregar();
      return;
    }
    setState(() => _estado = EstadoDaAbertura.saindo);
  }

  void _entregar() {
    if (_saiu) return;
    _saiu = true;
    _estado = EstadoDaAbertura.saindo;
    widget.aoConcluir(_resultado as T);
  }

  void _falhou(Object erro) {
    _relogioDaDemora?.cancel();
    _ciclo?.stop();
    setState(() => _estado = EstadoDaAbertura.falhou);
    widget.aoFalhar?.call(erro);
  }

  void _tentarDeNovo() {
    setState(() {
      _estado = EstadoDaAbertura.carregando;
      _pronto = false;
      _resultado = null;
      _gesto = null;
      _acenoEmCurso = !_reduzir;
    });
    if (!_reduzir) _iniciarOCiclo();
    _comecarACarregar();
  }

  @override
  void dispose() {
    _geracao++;
    _relogioDaDemora?.cancel();
    _ciclo?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color fundo = context.memora.cores.fundo;
    if (_estado == EstadoDaAbertura.falhou) {
      return _TelaDeErro(fundo: fundo, aoTentarDeNovo: _tentarDeNovo);
    }

    final bool saindo = _estado == EstadoDaAbertura.saindo;
    return Scaffold(
      backgroundColor: fundo,
      resizeToAvoidBottomInset: false,
      body: AnimatedOpacity(
        opacity: saindo ? 0 : 1,
        duration: MemoraMovimento.efetiva(
          MemoraMovimento.padrao,
          reduzirMovimento: _reduzir,
        ),
        onEnd: saindo ? _entregar : null,
        child: Column(
          children: <Widget>[
            const Expanded(child: SizedBox.shrink()),
            // A Memora no centro exato da tela, do mesmo tamanho e no mesmo
            // lugar da abertura nativa (FR-037): este bloco é centrado entre
            // duas metades iguais.
            SizedBox(
              height:
                  MemoraAbertura.tamanhoDaMemora +
                  2 * MemoraAbertura.folgaDaFrase,
              child: Center(
                child: Semantics(
                  label: TextosAbertura.abrindo,
                  child: MemoraAnimada(
                    expressao: PoseDaMemora.acenando,
                    tamanho: MemoraAbertura.tamanhoDaMemora,
                    reageAoToque: false,
                    gesto: _gesto,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: _estado == EstadoDaAbertura.demorando
                    ? const _FraseDeEspera()
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Estou quase pronta.", lida pelo leitor de tela como aviso.
class _FraseDeEspera extends StatelessWidget {
  const _FraseDeEspera();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: MemoraEspacamento.lg),
        child: TextoMemora(
          TextosAbertura.quasePronta,
          alinhamento: TextAlign.center,
        ),
      ),
    );
  }
}

/// A tela de erro da abertura: a Memora preocupada, uma frase sem culpa e o
/// caminho de volta (FR-032 da 004: nunca culpar a pessoa).
class _TelaDeErro extends StatelessWidget {
  final Color fundo;
  final VoidCallback aoTentarDeNovo;

  const _TelaDeErro({required this.fundo, required this.aoTentarDeNovo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(MemoraEspacamento.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const MemoraAnimada(
                  expressao: PoseDaMemora.preocupada,
                  tamanho: MemoraAbertura.tamanhoNoErro,
                  reageAoToque: false,
                ),
                const SizedBox(height: MemoraEspacamento.lg),
                Semantics(
                  liveRegion: true,
                  child: const TextoMemora(
                    TextosAbertura.falhou,
                    alinhamento: TextAlign.center,
                  ),
                ),
                const SizedBox(height: MemoraEspacamento.xl),
                BotaoPrimario(
                  rotulo: TextosAbertura.tentarDeNovo,
                  aoTocar: aoTentarDeNovo,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
