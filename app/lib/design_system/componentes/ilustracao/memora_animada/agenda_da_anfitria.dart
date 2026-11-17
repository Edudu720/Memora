import 'dart:math' as math;

import 'package:flutter/foundation.dart' show immutable;

/// O que a anfitriã faz sozinha, além de flutuar (feature 013, T088, FR-049).
enum ComportamentoDaAnfitria {
  /// Fica quieta, só flutuando e respirando. É a pausa entre os outros.
  descansar,

  /// Vira a cabeça e os olhos de um lado e depois do outro.
  olharEmVolta,

  /// Acena de vez em quando.
  acenar,

  /// Inclina a cabeça, curiosa.
  inclinarACabeca,

  /// Dá um pulinho.
  pular,
}

/// Um passo da agenda: o que fazer, por quanto tempo e para que lado.
@immutable
class PassoDaAgenda {
  /// O comportamento.
  final ComportamentoDaAnfitria comportamento;

  /// Quanto dura, em segundos.
  final double duracao;

  /// Para que lado vai (+1 ou -1): olhar primeiro à direita ou à esquerda,
  /// inclinar para um lado ou para o outro. É sorteado a cada vez.
  final double sinal;

  /// Cria um passo.
  const PassoDaAgenda(this.comportamento, this.duracao, this.sinal);
}

/// A agenda de comportamentos da anfitriã: **o que ela faz a seguir**.
///
/// ## Por que não é um ciclo
///
/// Uma sequência fixa (olha, acena, pula, olha, acena, pula...) vira relógio:
/// em dois minutos a pessoa já sabe o que vem, e a companhia vira mecanismo.
/// Aqui cada passo é sorteado, com três regras:
///
/// - **o mesmo comportamento nunca vem duas vezes seguidas**;
/// - **depois de um comportamento "forte" (acenar, pular) ela descansa**, e o
///   descanso tem duração sorteada — é o intervalo que desfaz o ritmo;
/// - os pesos fazem olhar em volta ser o mais comum e pular o mais raro: a
///   anfitriã é calma, e o pulinho é a surpresa.
///
/// A fonte do sorteio é injetável ([semente]), para o teste reproduzir uma
/// sequência e provar essas regras.
class AgendaDaAnfitria {
  final math.Random _sorteio;
  ComportamentoDaAnfitria? _anterior;

  /// Cria a agenda. Sem [semente], cada anfitriã tem a sua sequência.
  AgendaDaAnfitria({int? semente}) : _sorteio = math.Random(semente);

  /// O quanto ela fica quieta antes do primeiro comportamento, para o Início
  /// não começar já em movimento.
  static const double primeiraPausa = 2.2;

  static const Map<ComportamentoDaAnfitria, int> _pesos =
      <ComportamentoDaAnfitria, int>{
        ComportamentoDaAnfitria.olharEmVolta: 5,
        ComportamentoDaAnfitria.inclinarACabeca: 3,
        ComportamentoDaAnfitria.acenar: 2,
        ComportamentoDaAnfitria.pular: 1,
      };

  /// O próximo passo.
  PassoDaAgenda proximo() {
    final ComportamentoDaAnfitria? anterior = _anterior;

    // Depois de um comportamento (e não de uma pausa), uma pausa curta e de
    // duração variável. Depois da pausa, um comportamento.
    if (anterior != null && anterior != ComportamentoDaAnfitria.descansar) {
      _anterior = ComportamentoDaAnfitria.descansar;
      return PassoDaAgenda(
        ComportamentoDaAnfitria.descansar,
        1.2 + _sorteio.nextDouble() * 3.3,
        1,
      );
    }

    final ComportamentoDaAnfitria escolhido = _sortear(
      excluindo: _ultimoComportamento,
    );
    _ultimoComportamento = escolhido;
    _anterior = escolhido;

    final double duracao = switch (escolhido) {
      ComportamentoDaAnfitria.olharEmVolta => 3.2 + _sorteio.nextDouble() * 1.4,
      ComportamentoDaAnfitria.inclinarACabeca =>
        2.0 + _sorteio.nextDouble() * 1.2,
      // Um aceno e um pulo duram o que o gesto dura, com uma folga.
      ComportamentoDaAnfitria.acenar => 1.4,
      ComportamentoDaAnfitria.pular => 1.1,
      ComportamentoDaAnfitria.descansar => 1.5,
    };
    return PassoDaAgenda(escolhido, duracao, _sorteio.nextBool() ? 1 : -1);
  }

  ComportamentoDaAnfitria? _ultimoComportamento;

  ComportamentoDaAnfitria _sortear({ComportamentoDaAnfitria? excluindo}) {
    final List<MapEntry<ComportamentoDaAnfitria, int>> candidatos = _pesos
        .entries
        .where((MapEntry<ComportamentoDaAnfitria, int> e) => e.key != excluindo)
        .toList();
    final int total = candidatos.fold<int>(
      0,
      (int soma, MapEntry<ComportamentoDaAnfitria, int> e) => soma + e.value,
    );
    int ponto = _sorteio.nextInt(total);
    for (final MapEntry<ComportamentoDaAnfitria, int> e in candidatos) {
      if (ponto < e.value) return e.key;
      ponto -= e.value;
    }
    return candidatos.last.key;
  }
}
