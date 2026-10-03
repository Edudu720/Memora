import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/inicio/presentation/tela_inicio.dart';

import '../../suporte/aparelhos.dart';
import '../../suporte/fonte.dart';

/// O Início usa a altura da tela (T115, FR-009 e a revisão da T044: "vazio
/// embaixo").
///
/// ## O que mede
///
/// A sobra **abaixo da última caixa**, em fração da altura da área útil. Com o
/// conteúdo empilhado no topo, num celular alto ela passa de 20%: metade da
/// tela em branco, que foi exatamente o que o Henrique viu no aparelho. Com o
/// conteúdo repartido, o que sobra é o último dos três respiros iguais.
///
/// ## Por que com a Atkinson, e em aparelhos altos
///
/// A fonte quadrada do `flutter test` desenha texto duas vezes mais largo:
/// com ela o Início já enche a janela de qualquer aparelho e a sobra nunca
/// existe, de modo que o portão **passaria com o defeito presente**. Com a
/// Atkinson a medida é a que a pessoa vê. E os aparelhos são os altos
/// (390x844, 412x915, 430x932) porque é neles que o vazio aparece.
void main() {
  setUpAll(carregarAtkinson);

  /// A parte da altura da tela que pode sobrar abaixo da última caixa. Medido:
  /// repartido sobra 6% a 9%; empilhado no topo, 14% a 24% — 11% separa os dois.
  /// Acima disso, a tela está com um vazio que o redesenho existe para tirar.
  const double sobraMaxima = 0.11;

  const List<Size> aparelhosAltos = <Size>[
    referencia,
    Size(412, 915),
    Size(430, 932),
  ];

  for (final Size aparelho in aparelhosAltos) {
    testWidgets('em ${nomeDo(aparelho)} a sobra abaixo da última caixa é '
        'menor que ${(sobraMaxima * 100).round()}% da altura', (
      WidgetTester t,
    ) async {
      vestir(t, aparelho);
      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: TelaInicio(nome: 'Ana', aoConversar: () {}, aoVerTudo: () {}),
        ),
      );
      expect(t.takeException(), isNull);

      // A área é a do `Scaffold`, e não a do `SingleChildScrollView`: o
      // `Scaffold` dá ao corpo restrição solta, e a rolagem **encolhe até o
      // conteúdo** — medida por ela, a sobra seria sempre zero, com ou sem o
      // defeito (achado ao provar este portão quebrando).
      final Rect area = t.getRect(find.byType(Scaffold));
      final Rect ultima = t.getRect(find.byKey(TelaInicio.chaveCaixaVerTudo));
      final double sobra = area.bottom - ultima.bottom;

      expect(
        sobra,
        lessThan(area.height * sobraMaxima),
        reason:
            '${nomeDo(aparelho)}: sobraram $sobra dp abaixo da última caixa '
            '(${(sobra / area.height * 100).toStringAsFixed(1)}% da altura) — '
            'o conteúdo está empilhado no topo',
      );
      // E o conteúdo não passou da área: cabe sem rolar nestes aparelhos.
      expect(sobra, greaterThanOrEqualTo(0), reason: nomeDo(aparelho));
    });
  }
}
