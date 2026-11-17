import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../features/assistente/domain/limitar_emoji.dart';
import '../../tokens/movimento.dart';
import 'texto_com_negrito.dart';

/// O texto da fala da Memora, que pode ir aparecendo aos poucos (FR-020b).
///
/// ## Como a escrita anda
///
/// Uma letra a cada [MemoraMovimento.escritaPorLetra] — e mais depressa se o
/// que já chegou estiver mais de [MemoraMovimento.escritaAtrasoMaximo] à
/// frente do que está na tela. A resposta chega aos pedaços, e o ritmo se
/// ajusta a ela: nunca para esperar o que já está pronto, nunca atropela o que
/// ainda não chegou.
///
/// ## Reduzir movimento
///
/// O tempo por letra passa por [MemoraMovimento.efetiva], como toda animação.
/// Com "reduzir movimento" ele vira zero, e o texto aparece inteiro de uma vez
/// — o mesmo texto, sem movimento nenhum (FR-028 da 002).
///
/// ## O estado sobrevive à troca de balão
///
/// Quem usa dá a mesma `key` ao texto que está chegando e à mensagem final em
/// que ele se transforma: a escrita **continua de onde estava**, em vez de
/// recomeçar. Quando [aosPoucos] é falso — mensagem antiga, lida do disco —,
/// o texto aparece inteiro e nenhum relógio é ligado.
///
/// Este widget não diz nada ao leitor de tela. Quem o usa dá a fala inteira, e
/// só ela (ver `BalaoDeFala`): o TalkBack não pode reanunciar a cada letra.
class TextoDaFala extends StatefulWidget {
  /// O texto inteiro **que já chegou**, com as marcas de negrito.
  final String texto;

  /// Vai aparecendo aos poucos? Falso: aparece inteiro.
  final bool aosPoucos;

  /// O texto ainda está chegando? Ver [analisarNegrito].
  final bool emAndamento;

  /// Chamado a cada letra nova, depois de ela entrar na tela — para a lista
  /// rolar atrás do texto que cresce.
  final VoidCallback? aoAvancar;

  /// Cria o texto.
  const TextoDaFala(
    this.texto, {
    this.aosPoucos = false,
    this.emAndamento = false,
    this.aoAvancar,
    super.key,
  });

  @override
  State<TextoDaFala> createState() => _TextoDaFalaState();
}

class _TextoDaFalaState extends State<TextoDaFala>
    with SingleTickerProviderStateMixin {
  late final Ticker _relogio = createTicker(_aCadaQuadro);

  /// Quantas letras já estão na tela (fracionário: o quadro raramente cai
  /// numa letra exata).
  double _reveladas = 0;
  int _total = 0;
  Duration _ultimoQuadro = Duration.zero;
  late String _textoExibido;

  @override
  void initState() {
    super.initState();
    _textoExibido = limitarEmoji(widget.texto);
    _total = _contar();
    if (!widget.aosPoucos) _reveladas = _total.toDouble();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ajustar();
  }

  @override
  void didUpdateWidget(TextoDaFala antigo) {
    super.didUpdateWidget(antigo);
    _textoExibido = limitarEmoji(widget.texto);
    _total = _contar();
    _ajustar();
  }

  @override
  void dispose() {
    _relogio.dispose();
    super.dispose();
  }

  int _contar() => TextoComNegrito.quantasLetras(
    _textoExibido,
    emAndamento: widget.emAndamento,
  );

  bool get _semMovimento => MemoraMovimento.efetiva(
    MemoraMovimento.escritaPorLetra,
    reduzirMovimento: MediaQuery.disableAnimationsOf(context),
  ) == Duration.zero;

  /// Põe o relógio de acordo com o que falta escrever.
  void _ajustar() {
    if (!widget.aosPoucos || _semMovimento) {
      _reveladas = _total.toDouble();
    }
    // O texto só cresce; se encolher (o `**` que fechou), não passa do total.
    _reveladas = math.min(_reveladas, _total.toDouble());

    if (_reveladas < _total) {
      if (!_relogio.isActive) {
        _ultimoQuadro = Duration.zero;
        _relogio.start();
      }
    } else if (_relogio.isActive) {
      _relogio.stop();
    }
  }

  void _aCadaQuadro(Duration decorrido) {
    final double segundos =
        (decorrido - _ultimoQuadro).inMicroseconds / Duration.microsecondsPerSecond;
    _ultimoQuadro = decorrido;

    final double porLetra =
        MemoraMovimento.efetiva(
          MemoraMovimento.escritaPorLetra,
          reduzirMovimento: MediaQuery.disableAnimationsOf(context),
        ).inMicroseconds /
        Duration.microsecondsPerSecond;
    if (porLetra <= 0) {
      setState(() => _reveladas = _total.toDouble());
      _relogio.stop();
      return;
    }

    final double atrasoMaximo =
        MemoraMovimento.escritaAtrasoMaximo.inMicroseconds /
        Duration.microsecondsPerSecond;
    final double acumulado = _total - _reveladas;
    final double ritmo = math.max(1 / porLetra, acumulado / atrasoMaximo);

    setState(() {
      _reveladas = math.min(_total.toDouble(), _reveladas + segundos * ritmo);
    });
    if (_reveladas >= _total) _relogio.stop();
    widget.aoAvancar?.call();
  }

  @override
  Widget build(BuildContext context) {
    return TextoComNegrito(
      _textoExibido,
      emAndamento: widget.emAndamento,
      caracteresVisiveis: _reveladas >= _total ? null : _reveladas.floor(),
    );
  }
}
