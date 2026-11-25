import 'dart:async';

import 'package:flutter/material.dart';

import '../../../design_system/componentes/botoes/botao_primario.dart';
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
/// `carregando` → (`pronto` **e** passada da barra concluída) → `saindo`.
/// Dois ramos: `demorando` (passou de 4 s: aparece a frase) e `falhou` (vai à
/// tela de erro).
enum EstadoDaAbertura {
  /// A Memora segura a barra e o aplicativo carrega por baixo.
  carregando,

  /// Passou de 4 s: a frase "Estou quase pronta." aparece.
  demorando,

  /// Carregou e a passada da barra completou: a abertura esmaece e entrega o
  /// resultado.
  saindo,

  /// O carregamento falhou: a tela de erro, com a Memora e uma saída.
  falhou,
}

/// A tela de carregamento: a **anfitriã** (o desenho de mais detalhe, FR-048)
/// segurando a barra de carregamento enquanto o aplicativo termina de carregar
/// (feature 013, US7; FR-036 a FR-039, R9; T092).
///
/// ## Por que existe
///
/// A abertura nativa do Android não roda animação do aplicativo (ele ainda não
/// existe nesse instante). A única forma de a Memora se mexer é o aplicativo
/// subir primeiro e carregar depois: o `main.dart` chama o `runApp` com esta
/// tela **antes** de ler as preferências, e o que antes era feito antes do
/// `runApp` passa a ser o [carregar] daqui.
///
/// ## O que garante
///
/// - **Sai quando carregou e a passada da barra em curso completou** — nunca
///   antes de carregar, e nunca mais que uma passada
///   ([MemoraAbertura.passadaDaBarra]) depois (FR-038, SC-009). A abertura
///   não é prolongada de propósito.
/// - **Barra sem número**: indeterminada, ela não diz quanto falta (US7).
/// - **Demora calma**: se o carregamento se estende, as passadas seguem no
///   mesmo ritmo, sem acelerar nem piscar. Passados
///   [MemoraAbertura.limiteDaDemora], uma frase curta diz que está quase
///   pronto.
/// - **Falha não prende**: a tela de erro, com a Memora e "Tentar de novo".
/// - **Reduzir movimento** (aqui, o do **sistema**: as preferências do
///   aplicativo ainda não existem): a Memora e a barra ficam paradas, nenhum
///   relógio roda, e a abertura sai assim que carrega (FR-039).
/// - **Decorativa para o leitor de tela**: a Memora e a barra não são
///   anunciadas; quem usa o leitor ouve "Abrindo o Memora.", e a frase de
///   espera é um aviso.
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

  /// Há uma passada da barra em curso. Verdadeiro de saída: a barra começa a
  /// correr ao entrar.
  bool _passadaEmCurso = true;

  /// Se o sistema pediu menos movimento. Lido uma vez de saída e de novo se
  /// mudar.
  bool _reduzir = true;
  bool _leuOMovimento = false;

  /// Cada carregamento tem a sua geração: a resposta de um carregamento
  /// antigo (antes de "Tentar de novo") não vale mais.
  int _geracao = 0;

  /// O relógio da barra: de 0 a 1 é uma passada. É ele que a Memora pinta
  /// ([MemoraAnimada.cicloDaBarra]), e é por ele que a abertura sabe quando a
  /// passada terminou. Só existe quando há movimento permitido.
  AnimationController? _passada;

  /// Se a próxima passada é a primeira desta abertura: ela parte do meio,
  /// onde o desenho do Android deixou o trecho (T094).
  bool _primeiraPassada = true;

  Timer? _relogioDaDemora;
  bool _saiu = false;

  @override
  void initState() {
    super.initState();
    // O primeiro quadro (a Memora com a barra) vai para a tela **antes** de o
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
      // Sem movimento: nenhum relógio, e nenhuma passada a esperar.
      _passada?.stop();
      _passadaEmCurso = false;
      _tentarSair();
    } else {
      _iniciarAPassada();
    }
  }

  void _iniciarAPassada() {
    final AnimationController passada = _passada ??= AnimationController(
      vsync: this,
      duration: MemoraMovimento.efetiva(
        MemoraAbertura.passadaDaBarra,
        reduzirMovimento: _reduzir,
      ),
    )..addStatusListener(_aoMudarOStatusDaPassada);
    _passadaEmCurso = true;
    passada.forward(
      from: _primeiraPassada ? MemoraAbertura.inicioDaPrimeiraPassada : 0,
    );
    _primeiraPassada = false;
  }

  /// Acabou uma passada: sai, se já carregou; senão, a próxima emenda nesta.
  void _aoMudarOStatusDaPassada(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _passadaEmCurso = false;
    _tentarSair();
    if (_saiu ||
        _estado == EstadoDaAbertura.saindo ||
        _estado == EstadoDaAbertura.falhou) {
      return;
    }
    _passadaEmCurso = true;
    _passada!.forward(from: 0);
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

  /// Sai quando as duas coisas são verdade: carregou **e** não há passada em
  /// curso. É o único lugar que decide sair.
  void _tentarSair() {
    if (!_pronto || _passadaEmCurso || _saiu) return;
    if (_estado == EstadoDaAbertura.saindo ||
        _estado == EstadoDaAbertura.falhou) {
      return;
    }
    _relogioDaDemora?.cancel();
    _passada?.stop();
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
    _passada?.stop();
    setState(() => _estado = EstadoDaAbertura.falhou);
    widget.aoFalhar?.call(erro);
  }

  void _tentarDeNovo() {
    setState(() {
      _estado = EstadoDaAbertura.carregando;
      _pronto = false;
      _resultado = null;
      _passadaEmCurso = !_reduzir;
    });
    if (!_reduzir) _iniciarAPassada();
    _comecarACarregar();
  }

  @override
  void dispose() {
    _geracao++;
    _relogioDaDemora?.cancel();
    _passada?.dispose();
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
                    expressao: PoseDaMemora.carregando,
                    tamanho: MemoraAbertura.tamanhoDaMemora,
                    reageAoToque: false,
                    anfitria: true,
                    // Ela já estava na tela, no desenho do Android: sem o
                    // crescer da chegada (T094, FR-037).
                    chega: false,
                    cicloDaBarra: _reduzir ? null : _passada,
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
