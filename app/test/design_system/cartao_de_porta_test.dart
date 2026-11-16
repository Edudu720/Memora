import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

import '../suporte/aparelhos.dart';
import 'contraste_test.dart' show contraste;

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
    home: Builder(
      builder: (BuildContext context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(escala)),
        child: Scaffold(body: Center(child: filho)),
      ),
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

    testWidgets('pressionado encolhe e a sombra encolhe junto — além da cor', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(porta(aoAbrir: () {})));
      expect(t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      final BoxShadow repouso =
          (superficie(t).decoration! as BoxDecoration).boxShadow!.single;

      final TestGesture dedo = await t.startGesture(
        t.getCenter(find.byType(CartaoDePorta)),
      );
      await t.pump(kPressTimeout);

      expect(
        t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        MemoraMovimento.escalaPressionado,
      );
      // T113: a sombra ENCOLHE, e não some — a porta "desce" até a superfície.
      final BoxShadow pressionada =
          (superficie(t).decoration! as BoxDecoration).boxShadow!.single;
      expect(pressionada.blurRadius, lessThan(repouso.blurRadius));
      expect(pressionada.offset.dy, lessThan(repouso.offset.dy));
      expect(pressionada.blurRadius, greaterThan(0));

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
    testWidgets('o anel de foco fica POR FORA, e aparece também na principal', (
      WidgetTester t,
    ) async {
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

    testWidgets(
      'superfície transparente ganha preenchimento ao ser pressionada',
      (WidgetTester t) async {
        // A barra inferior e o "Voltar" são transparentes e sem sombra: encolher
        // uma caixa sem fundo em 3% não se vê. O segundo sinal precisa existir.
        await t.pumpWidget(
          app(
            NavegacaoInferior(
              indiceAtivo: 0,
              aoSelecionar: (_) {},
              itens: const <ItemNavegacao>[
                ItemNavegacao(
                  icone: IconeDeNavegacao.ajustes,
                  rotulo: 'Ajustes',
                ),
                ItemNavegacao(icone: IconeDeNavegacao.inicio, rotulo: 'Início'),
              ],
            ),
          ),
        );
        final Finder item = find
            .ancestor(
              of: find.text('Início'),
              matching: find.byType(AnimatedContainer),
            )
            .first;
        Color? fundo() =>
            (t.widget<AnimatedContainer>(item).decoration! as BoxDecoration)
                .color;
        expect(fundo(), Colors.transparent);

        final TestGesture dedo = await t.startGesture(t.getCenter(item));
        await t.pump(kPressTimeout);
        expect(fundo(), MemoraCores.claro.destaque);
        await dedo.up();
        await t.pump();
        expect(fundo(), Colors.transparent);
      },
    );
  });

  group('Acabamento de botão — T113, FR-016, R2 regra 3', () {
    testWidgets('em repouso a sombra é a da porta, maior que a do cartão', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(porta(aoAbrir: () {})));
      final BoxShadow sombra =
          (superficie(t).decoration! as BoxDecoration).boxShadow!.single;
      expect(sombra.blurRadius, MemoraElevacao.porta * 4);
      expect(sombra.offset.dy, MemoraElevacao.porta);
      expect(sombra.color, MemoraElevacao.sombraDaPorta);
      expect(MemoraElevacao.porta, greaterThan(MemoraElevacao.cartao));
    });

    testWidgets('desabilitada não tem sombra: não parece que se aperta', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(porta()));
      expect((superficie(t).decoration! as BoxDecoration).boxShadow, isNull);
    });

    for (final MemoraTemaId tema in MemoraTemaId.values) {
      testWidgets(
        'o medalhão da secundária se destaca da pílula no tema ${tema.name}',
        (WidgetTester t) async {
          // No tema claro o `medalhao` e o `destaque` são o MESMO azul-claro:
          // sem contorno o desenho some dentro da porta (aviso da #38). O
          // contorno em primária tem de separar as duas formas por 3:1.
          await t.pumpWidget(
            MaterialApp(
              theme: TemasMemora.porId(tema),
              home: Scaffold(
                body: Center(child: porta(aoAbrir: () {})),
              ),
            ),
          );
          final MemoraCores cores = TemasMemora.porId(
            tema,
          ).extension<MemoraTheme>()!.cores;
          final BoxDecoration medalhao =
              t
                      .widget<DecoratedBox>(
                        find.descendant(
                          of: find.byType(MedalhaoDeIlustracao),
                          matching: find.byType(DecoratedBox),
                        ),
                      )
                      .decoration
                  as BoxDecoration;

          final Border? contorno = medalhao.border as Border?;
          expect(contorno, isNotNull, reason: 'o medalhão está sem contorno');
          expect(contorno!.top.color, cores.primaria);
          expect(contorno.top.width, MemoraDimensoes.bordaEnfase);
          // A forma se separa da pílula: ou pelo preenchimento, ou pelo
          // contorno — e o contorno, quando o preenchimento é igual, tem de
          // medir 3:1 contra a pílula.
          if (medalhao.color == cores.destaque) {
            expect(
              contraste(cores.primaria, cores.destaque),
              greaterThanOrEqualTo(3),
            );
          }
        },
      );
    }

    testWidgets('na principal o medalhão não leva contorno', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(porta(aoAbrir: () {}, principal: true)));
      final BoxDecoration medalhao =
          t
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: find.byType(MedalhaoDeIlustracao),
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      expect(medalhao.border, isNull);
    });

    group('o respiro cresce com a altura, e é fração — nunca pixel', () {
      /// A altura do `Padding` de cima da porta: o respiro vertical.
      Future<double> respiroEm(
        WidgetTester t, {
        required double altura,
        double escala = 1.0,
      }) async {
        t.view.physicalSize = Size(360, altura);
        t.view.devicePixelRatio = 1.0;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(360, altura),
                textScaler: TextScaler.linear(escala),
              ),
              child: Scaffold(
                body: Center(child: porta(aoAbrir: () {})),
              ),
            ),
          ),
        );
        return t
            .widget<Padding>(
              find.descendant(
                of: find.byType(CartaoDePorta),
                matching: find.byWidgetPredicate(
                  (Widget w) =>
                      w is Padding &&
                      w.padding is EdgeInsets &&
                      (w.padding as EdgeInsets).right == MemoraEspacamento.lg,
                ),
              ),
            )
            .padding
            .resolve(TextDirection.ltr)
            .top;
      }

      testWidgets('num aparelho baixo o respiro é o piso', (
        WidgetTester t,
      ) async {
        expect(await respiroEm(t, altura: 300), MemoraEspacamento.sm);
      });

      testWidgets('num aparelho alto o respiro é maior, e tem teto', (
        WidgetTester t,
      ) async {
        final double alto = await respiroEm(t, altura: 800);
        expect(alto, greaterThan(MemoraEspacamento.sm));
        expect(await respiroEm(t, altura: 4000), MemoraEspacamento.lg);
      });

      testWidgets('cresce de forma monotônica com a altura', (
        WidgetTester t,
      ) async {
        double? anterior;
        for (final double altura in <double>[300, 568, 640, 800, 844, 1000]) {
          final double r = await respiroEm(t, altura: altura);
          if (anterior != null) {
            expect(r, greaterThanOrEqualTo(anterior), reason: '$altura');
          }
          anterior = r;
        }
      });

      testWidgets('com o texto ampliado o respiro volta a diminuir', (
        WidgetTester t,
      ) async {
        // Texto maior toma mais altura do mesmo aparelho: o respiro cede.
        final double normal = await respiroEm(t, altura: 800);
        final double ampliado = await respiroEm(t, altura: 800, escala: 2.0);
        expect(ampliado, lessThan(normal));
      });

      testWidgets('o afastamento entre portas também cresce com a altura', (
        WidgetTester t,
      ) async {
        late double baixo;
        late double alto;
        for (final double altura in <double>[300, 900]) {
          t.view.physicalSize = Size(360, altura);
          t.view.devicePixelRatio = 1.0;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          await t.pumpWidget(
            MaterialApp(
              theme: TemasMemora.claro,
              home: Builder(
                builder: (BuildContext c) {
                  final double a = CartaoDePorta.afastamentoEntrePortas(c);
                  if (altura < 600) {
                    baixo = a;
                  } else {
                    alto = a;
                  }
                  return const SizedBox();
                },
              ),
            ),
          );
        }
        expect(baixo, MemoraEspacamento.md);
        expect(alto, greaterThan(baixo));
        expect(alto, lessThanOrEqualTo(MemoraEspacamento.xl));
      });
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
                    .borderRadius!
                as BorderRadius;
        final RRect forma = raio.toRRect(t.getRect(caixa)).scaleRadii();

        for (final Element texto
            in find
                .descendant(
                  of: find.byType(CartaoDePorta),
                  matching: find.byType(Text),
                )
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
              reason:
                  '${nomeDa(c)}: o canto $canto do texto '
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
