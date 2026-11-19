import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/inicio/presentation/tela_inicio.dart';

import '../../suporte/aparelhos.dart';
import '../../suporte/fonte.dart';

/// O Início usa a altura da tela (T115, FR-009 e a revisão da T044: "vazio
/// embaixo") — e, desde a 013, a anfitriã ocupa o terço de cima e é a primeira
/// a ceder quando falta altura (T053 e T054; FR-040 e FR-041).
///
/// ## O que mede
///
/// 1. **O vazio**: a sobra **abaixo da última caixa**, em fração da altura da
///    área útil. Com o conteúdo empilhado no topo, num celular alto ela passa
///    de 20%: metade da tela em branco, que foi o que o Henrique viu no
///    aparelho. Com a anfitriã e os quatro atalhos o conteúdo **já passa da
///    altura** nos aparelhos medidos e a tela rola — não há vazio possível —;
///    o portão vale para o dia em que ele couber, e então a sobra precisa
///    continuar pequena.
/// 2. **O terço**: a anfitriã (desenho e balão) ocupa cerca de um terço da
///    altura com a letra a 100% (FR-040).
/// 3. **Quem cede primeiro**: o desenho dela é a fração da altura dividida
///    pela ampliação do texto, e **nunca cresce** quando a letra aumenta
///    (FR-041). Texto e ação nunca encolhem por causa dela.
///
/// ## Por que com a Atkinson, e em aparelhos altos
///
/// A fonte quadrada do `flutter test` desenha texto duas vezes mais largo:
/// com ela o Início já enche a janela de qualquer aparelho e a sobra nunca
/// existe, de modo que o portão **passaria com o defeito presente**. Com a
/// Atkinson a medida é a que a pessoa vê. E os aparelhos do vazio são os altos
/// (390x844, 412x915, 430x932) porque é neles que ele aparece.
void main() {
  setUpAll(carregarAtkinson);

  /// A parte da altura da tela que pode sobrar abaixo da última caixa quando o
  /// conteúdo cabe. Medido antes da anfitriã: repartido sobra 6% a 9%;
  /// empilhado no topo, 14% a 24% — 11% separa os dois.
  const double sobraMaxima = 0.11;

  const List<Size> aparelhosAltos = <Size>[
    referencia,
    Size(412, 915),
    Size(430, 932),
  ];

  Widget inicio() => TelaInicio(
    nome: 'Ana',
    aoConversar: () {},
    aoVerTudo: () {},
    aoAbrirAplicativos: () {},
    aoAbrirServicos: () {},
    aoAbrirAjuda: () {},
  );

  /// O Início na combinação [c], do jeito que a pessoa o vê: a Atkinson já
  /// está carregada, e o movimento parado (a matriz mede layout).
  Future<void> montar(WidgetTester t, Combinacao c) async {
    vestir(t, c.aparelho);
    await t.pumpWidget(naCombinacao(c, inicio()));
    expect(t.takeException(), isNull, reason: nomeDa(c));
  }

  /// O lado do desenho da anfitriã, que é a largura da área de toque dela.
  double ladoDaAnfitria(WidgetTester t) =>
      t.getSize(find.byKey(MemoraAnfitria.chaveDaAcao)).width;

  Combinacao cem(Size aparelho) =>
      (aparelho: aparelho, escala: 1.0, tema: MemoraTemaId.claro);

  for (final Size aparelho in aparelhosAltos) {
    testWidgets('em ${nomeDo(aparelho)} não sobra vazio embaixo: ou o '
        'conteúdo rola, ou a sobra é menor que '
        '${(sobraMaxima * 100).round()}% da altura', (WidgetTester t) async {
      await montar(t, cem(aparelho));

      // A área é a do `Scaffold`, e não a do `SingleChildScrollView`: o
      // `Scaffold` dá ao corpo restrição solta, e a rolagem **encolhe até o
      // conteúdo** — medida por ela, a sobra seria sempre zero, com ou sem o
      // defeito (achado ao provar este portão quebrando).
      final Rect area = t.getRect(find.byType(Scaffold));
      final Rect ultima = t.getRect(find.byKey(TelaInicio.chaveCaixaVerTudo));
      final double sobra = area.bottom - ultima.bottom;
      final bool rola =
          t
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position
              .maxScrollExtent >
          0;

      if (!rola) {
        expect(
          sobra,
          lessThan(area.height * sobraMaxima),
          reason:
              '${nomeDo(aparelho)}: sobraram $sobra dp abaixo da última caixa '
              '(${(sobra / area.height * 100).toStringAsFixed(1)}% da altura) '
              '— o conteúdo está empilhado no topo',
        );
      }
      // E o que não cabe rola para dentro do alcance: a última caixa chega a
      // ficar inteira na janela (a matriz da casca confere o mesmo com a
      // barra inferior).
      await exigirAlcancavel(
        t,
        find.byKey(TelaInicio.chaveCaixaVerTudo),
        aparelho: aparelho,
        contexto: 'Início em ${nomeDo(aparelho)}',
      );
    });

    testWidgets('em ${nomeDo(aparelho)} a anfitriã ocupa cerca de um terço '
        'da altura (FR-040)', (WidgetTester t) async {
      await montar(t, cem(aparelho));

      final Rect area = t.getRect(find.byType(Scaffold));
      final Rect anfitria = t.getRect(find.byKey(TelaInicio.chaveMemora));
      final double fracao = anfitria.height / area.height;

      expect(
        fracao,
        inInclusiveRange(0.27, 0.38),
        reason:
            '${nomeDo(aparelho)}: a anfitriã tem ${anfitria.height} dp de '
            '${area.height} (${(fracao * 100).toStringAsFixed(1)}%)',
      );
      // E fica em cima, junto da saudação.
      final Rect saudacao = t.getRect(find.byKey(TelaInicio.chaveSaudacao));
      expect(anfitria.top, lessThan(saudacao.bottom + 16));
    });
  }

  group('A anfitriã é a primeira a ceder — FR-041, T054', () {
    for (final Size aparelho in aparelhos) {
      for (final MemoraTemaId tema in MemoraTemaId.values) {
        testWidgets('em ${nomeDo(aparelho)} no tema ${tema.name}, o desenho '
            'dela nunca cresce com a letra e encolhe quando há de onde '
            'encolher', (WidgetTester t) async {
          final List<double> lados = <double>[];
          for (final double escala in escalas) {
            await montar(t, (aparelho: aparelho, escala: escala, tema: tema));
            lados.add(ladoDaAnfitria(t));

            // O desenho é a fração da altura dividida pela ampliação, entre o
            // piso do alvo de toque e o teto da ilustração principal.
            expect(
              lados.last,
              closeTo(
                (aparelho.height *
                        MemoraDimensoes.fracaoDaAnfitriaDoInicio /
                        escala)
                    .clamp(
                      MemoraDimensoes.alvoMinimo,
                      MemoraDimensoes.ilustracaoHeroi,
                    ),
                0.5,
              ),
              reason:
                  '${nomeDo(aparelho)} a ${(escala * 100).round()}%: o '
                  'desenho dela não é a fração da altura',
            );
          }

          expect(lados[1], lessThanOrEqualTo(lados[0]), reason: '$lados');
          expect(lados[2], lessThanOrEqualTo(lados[1]), reason: '$lados');
          // Onde há de onde encolher (o piso ela nunca atravessa), a 200% ela
          // é menor que a 100%.
          if (lados[0] > MemoraDimensoes.alvoMinimo * 2) {
            expect(
              lados[2],
              lessThan(lados[0]),
              reason: '${nomeDo(aparelho)}: a anfitriã não cedeu: $lados',
            );
          }
          expect(
            lados[2],
            greaterThanOrEqualTo(MemoraDimensoes.alvoMinimo),
            reason: 'o toque nela continua com 48 dp',
          );
        });
      }
    }

    testWidgets('com a letra a 200% a saudação e a ação principal seguem '
        'inteiras e alcançáveis', (WidgetTester t) async {
      const Combinacao c = (
        aparelho: Size(320, 568),
        escala: 2.0,
        tema: MemoraTemaId.claro,
      );
      await montar(t, c);

      expect(find.byKey(TelaInicio.chaveSaudacao), findsOneWidget);
      await exigirAlcancavel(
        t,
        find.byKey(TelaInicio.chaveConversar),
        aparelho: c.aparelho,
        contexto: 'Início 320x568 a 200%',
      );
      await exigirAlcancavel(
        t,
        find.byKey(TelaInicio.chaveVerTudo),
        aparelho: c.aparelho,
        contexto: 'Início 320x568 a 200%',
      );
    });
  });
}
