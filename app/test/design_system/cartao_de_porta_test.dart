import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

import '../suporte/aparelhos.dart';

/// `CartaoDePorta` — T016, FR-002, FR-043 da feature 004.
///
/// ## Os estados são provados um a um
///
/// A constituição pede feedback visual para **todo** estado, e por mais de um
/// sinal além da cor (FR-043). Os componentes da 002 mostram foco e toque só
/// pela camada de cor do `InkWell`; estes testes exigem o segundo sinal, e é a
/// `SuperficieTocavel` que o dá.
void main() {
  Widget porta({VoidCallback? aoAbrir, bool principal = false}) =>
      CartaoDePorta(
        nome: 'Conversar com a Memora',
        explicacao: 'Pergunte do seu jeito, que eu te mostro o caminho',
        ilustracao: Ilustracao.portaConversa,
        aoAbrir: aoAbrir,
        principal: principal,
      );

  Widget app(Widget filho, {double escala = 1.0}) => MaterialApp(
    theme: TemasMemora.claro,
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(escala)),
      child: Scaffold(body: Center(child: filho)),
    ),
  );

  AnimatedContainer superficie(WidgetTester t) => t.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(CartaoDePorta),
      matching: find.byType(AnimatedContainer),
    ),
  );

  group('O cartão inteiro é o alvo', () {
    testWidgets('tocar no texto da explicação abre a porta', (
      WidgetTester t,
    ) async {
      int abriu = 0;
      await t.pumpWidget(app(porta(aoAbrir: () => abriu++)));
      await t.tap(
        find.text('Pergunte do seu jeito, que eu te mostro o caminho'),
      );
      expect(abriu, 1);
    });

    testWidgets('o leitor anuncia nome, explicação e que é botão', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      await t.pumpWidget(app(porta(aoAbrir: () {})));
      expect(
        t.getSemantics(find.byType(CartaoDePorta)),
        isSemantics(
          label: 'Conversar com a Memora',
          hint: 'Pergunte do seu jeito, que eu te mostro o caminho',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
        ),
      );
      h.dispose();
    });

    testWidgets('a altura nunca fica abaixo do alvo de decisão', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(porta(aoAbrir: () {})));
      expect(
        t.getSize(find.byType(CartaoDePorta)).height,
        greaterThanOrEqualTo(MemoraDimensoes.alvoDecisao),
      );
    });
  });

  group('Estados — FR-043', () {
    testWidgets('foco desenha o anel de seleção em primária', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(porta(aoAbrir: () {})));
      expect(superficie(t).foregroundDecoration, isNull);

      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();

      final BoxDecoration anel =
          superficie(t).foregroundDecoration! as BoxDecoration;
      final Border borda = anel.border! as Border;
      expect(borda.top.width, MemoraDimensoes.bordaSelecao);
      expect(borda.top.color, MemoraCores.claro.primaria);
    });

    testWidgets('pressionado encolhe e perde a sombra — além da cor', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(porta(aoAbrir: () {})));
      expect(t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      expect((superficie(t).decoration! as BoxDecoration).boxShadow, isNotNull);

      final TestGesture dedo = await t.startGesture(
        t.getCenter(find.byType(CartaoDePorta)),
      );
      await t.pump(kPressTimeout);

      expect(
        t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        MemoraMovimento.escalaPressionado,
      );
      expect((superficie(t).decoration! as BoxDecoration).boxShadow, isNull);

      await dedo.up();
      await t.pump();
      expect(t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    });

    testWidgets('desabilitada é anunciada como desabilitada e não responde', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      await t.pumpWidget(app(porta()));
      expect(
        t.getSemantics(find.byType(CartaoDePorta)),
        isSemantics(isButton: true, isEnabled: false, hasTapAction: false),
      );
      h.dispose();
    });

    testWidgets('a principal vai em primária, e as outras no destaque', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(porta(aoAbrir: () {}, principal: true)));
      expect(
        (superficie(t).decoration! as BoxDecoration).color,
        MemoraCores.claro.primaria,
      );

      await t.pumpWidget(app(porta(aoAbrir: () {})));
      await t.pump();
      expect(
        (superficie(t).decoration! as BoxDecoration).color,
        MemoraCores.claro.destaque,
      );
    });
  });

  group('Achados da revisão da #38', () {
    testWidgets('o anel de foco fica POR FORA, e aparece também na principal',
        (WidgetTester t) async {
      // Por dentro, o anel primária caía sobre o preenchimento primária da
      // porta principal: focada e sem foco ficavam iguais, salvo a camada do
      // InkWell — o "só cor" que a FR-043 recusa.
      await t.pumpWidget(app(porta(aoAbrir: () {}, principal: true)));
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      final BoxDecoration anel =
          superficie(t).foregroundDecoration! as BoxDecoration;
      final BorderSide lado = (anel.border! as Border).top;
      expect(lado.strokeAlign, BorderSide.strokeAlignOutside);
      expect(lado.width, greaterThanOrEqualTo(3));
    });

    testWidgets('superfície transparente ganha preenchimento ao ser pressionada',
        (WidgetTester t) async {
      // A barra inferior e o "Voltar" são transparentes e sem sombra: encolher
      // uma caixa sem fundo em 3% não se vê. O segundo sinal precisa existir.
      await t.pumpWidget(
        app(
          NavegacaoInferior(
            indiceAtivo: 0,
            aoSelecionar: (_) {},
            itens: const <ItemNavegacao>[
              ItemNavegacao(icone: IconeDeNavegacao.ajustes, rotulo: 'Ajustes'),
              ItemNavegacao(icone: IconeDeNavegacao.inicio, rotulo: 'Início'),
            ],
          ),
        ),
      );
      final Finder item = find.ancestor(
        of: find.text('Início'),
        matching: find.byType(AnimatedContainer),
      ).first;
      Color? fundo() =>
          (t.widget<AnimatedContainer>(item).decoration! as BoxDecoration).color;
      expect(fundo(), Colors.transparent);

      final TestGesture dedo = await t.startGesture(t.getCenter(item));
      await t.pump(kPressTimeout);
      expect(fundo(), MemoraCores.claro.destaque);
      await dedo.up();
      await t.pump();
      expect(fundo(), Colors.transparent);
    });
  });

  group('A ilustração cede primeiro — regra 7 da R2', () {
    testWidgets('com o texto a 175% ou mais, o desenho sai', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(porta(aoAbrir: () {}), escala: 1.5));
      expect(find.byType(MedalhaoDeIlustracao), findsOneWidget);

      await t.pumpWidget(app(porta(aoAbrir: () {}), escala: 2.0));
      expect(find.byType(MedalhaoDeIlustracao), findsNothing);
      expect(find.text('Conversar com a Memora'), findsOneWidget);
    });
  });

  group('O texto fica dentro da forma — achado da revisão da #38', () {
    // O Flutter reduz o raio de um RRect à metade do menor lado. Com o raio de
    // pílula (999), a porta que fica alta com o texto ampliado virava quase um
    // círculo, e os cantos do nome e da explicação saíam do preenchimento —
    // na principal, texto branco sobre o fundo claro, invisível. `takeException`
    // não pega isso: não é estouro, é texto fora da forma.
    for (final Combinacao c in matriz(em: const <double>[1.5, 2.0])) {
      testWidgets('em ${nomeDa(c)}', (WidgetTester t) async {
        vestir(t, c.aparelho);
        await t.pumpWidget(
          naCombinacao(
            c,
            Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(MemoraEspacamento.lg),
                children: <Widget>[porta(aoAbrir: () {}, principal: true)],
              ),
            ),
          ),
        );
        final Finder caixa = find.descendant(
          of: find.byType(CartaoDePorta),
          matching: find.byType(AnimatedContainer),
        );
        final BorderRadius raio =
            (t.widget<AnimatedContainer>(caixa).decoration! as BoxDecoration)
                .borderRadius! as BorderRadius;
        final RRect forma = raio.toRRect(t.getRect(caixa)).scaleRadii();

        for (final Element texto in find
            .descendant(of: find.byType(CartaoDePorta), matching: find.byType(Text))
            .evaluate()) {
          final Rect r = t.getRect(find.byWidget(texto.widget));
          for (final Offset canto in <Offset>[
            r.topLeft,
            r.topRight,
            r.bottomLeft,
            r.bottomRight,
          ]) {
            expect(
              forma.contains(canto),
              isTrue,
              reason: '${nomeDa(c)}: o canto $canto do texto '
                  '"${(texto.widget as Text).data}" fica fora da porta',
            );
          }
        }
      });
    }
  });

  group('Matriz — FR-044', () {
    for (final Combinacao c in matriz()) {
      testWidgets('não estoura em ${nomeDa(c)}', (WidgetTester t) async {
        vestir(t, c.aparelho);
        await t.pumpWidget(
          naCombinacao(
            c,
            Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(MemoraEspacamento.lg),
                children: <Widget>[
                  porta(aoAbrir: () {}, principal: true),
                  const SizedBox(height: MemoraEspacamento.md),
                  porta(aoAbrir: () {}),
                ],
              ),
            ),
          ),
        );
        expect(t.takeException(), isNull, reason: nomeDa(c));
      });
    }
  });
}
