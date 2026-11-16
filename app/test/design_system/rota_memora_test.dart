import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

/// A rota do Memora — T019 e T020 da feature 013 (V6 e V9), FR-009, FR-013,
/// FR-014 e FR-015.
///
/// ## Como se mede o deslizamento
///
/// Pela posição **na tela** de uma chave que cobre a página inteira
/// (`getTopLeft` aplica as transformações dos ancestrais). Assim o teste não
/// depende de qual widget faz o deslize — só de onde a página está.
void main() {
  const Key chaveA = Key('a.pagina');
  const Key chaveB = Key('b.pagina');
  const Key abrirB = Key('a.abrir');
  const Key abrirComTema = Key('a.abrirComTema');
  const Key contarEmA = Key('a.contar');
  const Key voltarDeB = Key('b.voltar');

  late int toquesEmA;
  late List<Route<dynamic>> rotas;

  setUp(() {
    toquesEmA = 0;
    rotas = <Route<dynamic>>[];
  });

  Widget paginaB(BuildContext context) => Scaffold(
    key: chaveB,
    body: Align(
      alignment: Alignment.topLeft,
      child: TextButton(
        key: voltarDeB,
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('voltar'),
      ),
    ),
  );

  Widget paginaA(BuildContext context) => Scaffold(
    key: chaveA,
    body: Column(
      children: <Widget>[
        TextButton(
          key: abrirB,
          onPressed: () {
            final RotaMemora<void> rota = RotaMemora<void>(builder: paginaB);
            rotas.add(rota);
            Navigator.of(context).push(rota);
          },
          child: const Text('abrir'),
        ),
        TextButton(
          key: abrirComTema,
          onPressed: () => Navigator.of(context).push(
            // Uma rota comum do Material: quem a veste é o tema (T049).
            MaterialPageRoute<void>(builder: paginaB),
          ),
          child: const Text('abrir com o tema'),
        ),
        TextButton(
          key: contarEmA,
          onPressed: () => toquesEmA++,
          child: const Text('contar'),
        ),
      ],
    ),
  );

  Widget app({bool reduzir = false}) => MaterialApp(
    theme: TemasMemora.claro,
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduzir),
      child: child!,
    ),
    home: Builder(builder: paginaA),
  );

  double largura(WidgetTester t) =>
      t.view.physicalSize.width / t.view.devicePixelRatio;

  double esquerdaDe(WidgetTester t, Key chave) =>
      t.getTopLeft(find.byKey(chave, skipOffstage: false)).dx;

  group('Avançar — FR-009', () {
    testWidgets(
      'a tela nova entra pela direita e a de trás sai pela esquerda',
      (WidgetTester t) async {
        await t.pumpWidget(app());
        final double w = largura(t);

        await t.tap(find.byKey(abrirB));
        await t.pump();
        await t.pump(const Duration(milliseconds: 100));

        expect(
          esquerdaDe(t, chaveB),
          greaterThan(0),
          reason: 'entra da direita',
        );
        expect(esquerdaDe(t, chaveB), lessThan(w), reason: 'já está entrando');
        expect(esquerdaDe(t, chaveA), lessThan(0), reason: 'a de trás sai');

        await t.pumpAndSettle();
        expect(esquerdaDe(t, chaveB), 0);
      },
    );

    testWidgets('a tela de trás anda menos que a nova (paralaxe)', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app());
      final double w = largura(t);

      await t.tap(find.byKey(abrirB));
      await t.pump();
      await t.pump(const Duration(milliseconds: 150));

      final double andouNova = w - esquerdaDe(t, chaveB);
      final double andouDeTras = -esquerdaDe(t, chaveA);
      expect(andouDeTras, greaterThan(0));
      expect(andouDeTras, lessThan(andouNova));
    });

    testWidgets('termina em no máximo 500 ms (SC-004)', (WidgetTester t) async {
      await t.pumpWidget(app());
      await t.tap(find.byKey(abrirB));
      await t.pump();
      expect(
        (rotas.single as RotaMemora<void>).transitionDuration,
        lessThanOrEqualTo(const Duration(milliseconds: 500)),
      );
      await t.pump(const Duration(milliseconds: 500));
      expect(esquerdaDe(t, chaveB), 0, reason: 'no fim dos 500 ms já chegou');
      expect(t.binding.transientCallbackCount, 0);
    });
  });

  group('Voltar — FR-009 e FR-015', () {
    testWidgets('a tela de cima sai pela direita e a de trás volta pela '
        'esquerda', (WidgetTester t) async {
      await t.pumpWidget(app());
      final double w = largura(t);
      await t.tap(find.byKey(abrirB));
      await t.pumpAndSettle();

      await t.tap(find.byKey(voltarDeB));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      expect(esquerdaDe(t, chaveB), greaterThan(0), reason: 'sai pela direita');
      expect(esquerdaDe(t, chaveB), lessThan(w));
      expect(esquerdaDe(t, chaveA), lessThan(0), reason: 'volta da esquerda');

      await t.pumpAndSettle();
      expect(esquerdaDe(t, chaveA), 0);
      expect(find.byKey(chaveB), findsNothing);
    });

    testWidgets('o gesto de voltar do aparelho faz a mesma animação do botão', (
      WidgetTester t,
    ) async {
      Future<List<double>> medir(Future<void> Function() voltar) async {
        await t.pumpWidget(app());
        await t.tap(find.byKey(abrirB));
        await t.pumpAndSettle();
        await voltar();
        await t.pump();
        final List<double> amostras = <double>[];
        for (int i = 0; i < 3; i++) {
          await t.pump(const Duration(milliseconds: 80));
          amostras
            ..add(esquerdaDe(t, chaveB))
            ..add(esquerdaDe(t, chaveA));
        }
        await t.pumpAndSettle();
        // Desmonta para o próximo `pumpWidget` começar do zero.
        await t.pumpWidget(const SizedBox.shrink());
        return amostras;
      }

      final List<double> pelaTela = await medir(
        () => t.tap(find.byKey(voltarDeB)),
      );
      final List<double> peloAparelho = await medir(
        () => t.binding.handlePopRoute(),
      );

      expect(pelaTela.first, greaterThan(0), reason: 'a tela mediu algo');
      expect(peloAparelho, pelaTela);
    });
  });

  group('Toque durante a transição — FR-014', () {
    testWidgets('a tela que está saindo não recebe toque', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app());
      await t.tap(find.byKey(contarEmA));
      expect(toquesEmA, 1, reason: 'sem transição, o botão responde');

      await t.tap(find.byKey(abrirB));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      // O botão de A continua à vista (a tela nova ainda está chegando), no
      // lugar em que a paralaxe o deixou. O dedo cai nele.
      final Offset ondeEsta = t.getCenter(find.byKey(contarEmA));
      expect(ondeEsta.dx, lessThan(esquerdaDe(t, chaveB)));
      await t.tapAt(ondeEsta);
      await t.pump();

      expect(toquesEmA, 1, reason: 'a tela que sai engoliu um toque');
      await t.pumpAndSettle();
    });

    testWidgets('a tela que está entrando já recebe o toque', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app());
      await t.tap(find.byKey(abrirB));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      // "Voltar" está no canto da tela nova, que ainda está chegando.
      await t.tap(find.byKey(voltarDeB));
      await t.pumpAndSettle();

      expect(find.byKey(chaveB), findsNothing, reason: 'o toque se perdeu');
      expect(esquerdaDe(t, chaveA), 0);
    });
  });

  group('Reduzir movimento — FR-013 (V9)', () {
    testWidgets('avançar e voltar são instantâneos', (WidgetTester t) async {
      await t.pumpWidget(app(reduzir: true));

      await t.tap(find.byKey(abrirB));
      await t.pump();
      await t.pump();
      expect(esquerdaDe(t, chaveB), 0, reason: 'chegou sem deslizar');
      expect(t.binding.transientCallbackCount, 0);
      expect(
        (rotas.single as RotaMemora<void>).transitionDuration,
        Duration.zero,
      );

      await t.tap(find.byKey(voltarDeB));
      await t.pump();
      await t.pump();
      expect(find.byKey(chaveB), findsNothing);
      expect(esquerdaDe(t, chaveA), 0);
      expect(t.binding.transientCallbackCount, 0);
    });
  });

  group('O tema — T049', () {
    testWidgets('uma rota comum do Material também desliza, pela direita', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app());
      final double w = largura(t);

      await t.tap(find.byKey(abrirComTema));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      expect(esquerdaDe(t, chaveB), greaterThan(0));
      expect(esquerdaDe(t, chaveB), lessThan(w));
      expect(esquerdaDe(t, chaveA), lessThan(0));
      await t.pumpAndSettle();
    });

    testWidgets('os três temas registram a transição do Memora no Android', (
      WidgetTester t,
    ) async {
      for (final MemoraTemaId id in MemoraTemaId.values) {
        final PageTransitionsBuilder? b = TemasMemora.porId(
          id,
        ).pageTransitionsTheme.builders[TargetPlatform.android];
        expect(b, isA<TransicaoMemora>(), reason: id.name);
      }
    });

    testWidgets('com reduzir movimento, a rota do tema não desliza', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(reduzir: true));
      await t.tap(find.byKey(abrirComTema));
      await t.pump();
      await t.pump(const Duration(milliseconds: 20));
      expect(esquerdaDe(t, chaveB), 0);
      await t.pumpAndSettle();
    });
  });
}
