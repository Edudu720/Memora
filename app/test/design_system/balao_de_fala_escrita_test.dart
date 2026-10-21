import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

/// A fala da Memora: negrito e escrita aos poucos — T131 e T132, FR-020a e
/// FR-020b.
void main() {
  Widget app(Widget filho, {bool reduzirMovimento = false}) => MaterialApp(
    theme: TemasMemora.claro,
    home: Builder(
      builder: (BuildContext contexto) => MediaQuery(
        data: MediaQuery.of(
          contexto,
        ).copyWith(disableAnimations: reduzirMovimento),
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(MemoraEspacamento.lg),
            child: filho,
          ),
        ),
      ),
    ),
  );

  /// Os trechos do texto da fala, com o peso que cada um tem de fato.
  List<(String, FontWeight?)> trechos(WidgetTester t) {
    final RichText rico = t.widget<RichText>(
      find
          .descendant(
            of: find.byType(BalaoDeFala),
            matching: find.byType(RichText),
          )
          .last,
    );
    final List<(String, FontWeight?)> saida = <(String, FontWeight?)>[];
    rico.text.visitChildren((InlineSpan s) {
      if (s is TextSpan && s.text != null) {
        saida.add((s.text!, s.style?.fontWeight));
      }
      return true;
    });
    return saida;
  }

  String visivel(WidgetTester t) =>
      trechos(t).map(((String, FontWeight?) x) => x.$1).join();

  String todoTextoNaTela(WidgetTester t) => t
      .widgetList<RichText>(find.byType(RichText))
      .map((RichText r) => r.text.toPlainText())
      .join('|');

  group('Negrito na fala da Memora — FR-020a', () {
    testWidgets('o trecho entre ** fica em negrito e nenhum asterisco '
        'aparece', (WidgetTester t) async {
      await t.pumpWidget(
        app(
          const BalaoDeFala(
            autor: AutorDoBalao.memora,
            texto: 'Abra o **WhatsApp** e toque em **Conversas**.',
          ),
        ),
      );

      expect(todoTextoNaTela(t), isNot(contains('*')));
      expect(visivel(t), 'Abra o WhatsApp e toque em Conversas.');

      final Map<String, FontWeight?> pesos = <String, FontWeight?>{
        for (final (String, FontWeight?) x in trechos(t)) x.$1: x.$2,
      };
      expect(pesos['WhatsApp'], MemoraTipografia.pesoDoNegrito);
      expect(pesos['Conversas'], MemoraTipografia.pesoDoNegrito);
      expect(pesos['Abra o '], isNull, reason: 'o resto não é negrito');
      expect(
        MemoraTipografia.pesoDoNegrito.value,
        greaterThanOrEqualTo(FontWeight.w700.value),
        reason: 'negrito precisa se destacar do corpo (w400) de relance',
      );
    });

    testWidgets('o leitor de tela recebe a fala sem marca nenhuma', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      await t.pumpWidget(
        app(
          const BalaoDeFala(
            autor: AutorDoBalao.memora,
            texto: 'Abra o **WhatsApp** agora.',
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Memora disse: Abra o WhatsApp agora.'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp(r'\*')), findsNothing);
      h.dispose();
    });

    testWidgets('marca sem par fica como texto', (WidgetTester t) async {
      await t.pumpWidget(
        app(
          const BalaoDeFala(
            autor: AutorDoBalao.memora,
            texto: 'Toque em **Fotos',
          ),
        ),
      );
      expect(visivel(t), 'Toque em **Fotos');
    });

    testWidgets('a fala da PESSOA não é interpretada: mostra o que ela '
        'digitou', (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      await t.pumpWidget(
        app(
          const BalaoDeFala(
            autor: AutorDoBalao.pessoa,
            texto: 'quero **fotos**',
          ),
        ),
      );
      expect(find.text('quero **fotos**'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Você disse: quero **fotos**'),
        findsOneWidget,
      );
      h.dispose();
    });
  });

  group('A fala vai aparecendo aos poucos — FR-020b', () {
    const String fala =
        'Para ver as fotos do seu neto, abra o **WhatsApp** e toque na '
        'conversa dele. As fotos estão lá, uma abaixo da outra.';
    const String falaLimpa =
        'Para ver as fotos do seu neto, abra o WhatsApp e toque na '
        'conversa dele. As fotos estão lá, uma abaixo da outra.';

    Widget balao({bool aosPoucos = true, VoidCallback? aoEscrever}) =>
        BalaoDeFala(
          autor: AutorDoBalao.memora,
          texto: fala,
          escreverAosPoucos: aosPoucos,
          aoEscrever: aoEscrever,
        );

    testWidgets('no meio da escrita só há parte do texto, que cresce até o '
        'fim', (WidgetTester t) async {
      await t.pumpWidget(app(balao()));
      await t.pump(const Duration(milliseconds: 400));

      final String noMeio = visivel(t);
      expect(noMeio, isNotEmpty);
      expect(noMeio.length, lessThan(falaLimpa.length));
      expect(
        falaLimpa,
        startsWith(noMeio),
        reason: 'o que aparece é sempre o começo, na ordem',
      );

      await t.pump(const Duration(milliseconds: 400));
      expect(visivel(t).length, greaterThan(noMeio.length));

      await t.pump(const Duration(seconds: 10));
      expect(visivel(t), falaLimpa);
      expect(todoTextoNaTela(t), isNot(contains('*')));
    });

    testWidgets('o corte nunca deixa um asterisco aparecer', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(balao()));
      for (int i = 0; i < 40; i++) {
        await t.pump(const Duration(milliseconds: 60));
        expect(
          todoTextoNaTela(t),
          isNot(contains('*')),
          reason: 'quadro $i: ${visivel(t)}',
        );
      }
    });

    testWidgets('quando termina, não sobra relógio agendado', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(balao()));
      await t.pump(const Duration(seconds: 10));
      await t.pump();
      expect(visivel(t), falaLimpa);
      expect(
        t.binding.transientCallbackCount,
        0,
        reason: 'terminada a escrita, o relógio para: nada de Ticker vivo',
      );
    });

    testWidgets('o leitor de tela recebe a fala INTEIRA desde o primeiro '
        'quadro, e não letra a letra', (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      await t.pumpWidget(app(balao()));
      await t.pump(const Duration(milliseconds: 100));

      expect(
        visivel(t).length,
        lessThan(falaLimpa.length),
        reason: 'sanidade: ainda está escrevendo',
      );
      expect(
        find.bySemanticsLabel('Memora disse: $falaLimpa'),
        findsOneWidget,
        reason: 'o nó semântico leva a fala inteira, não a parte que já '
            'apareceu',
      );

      // E o rótulo não muda enquanto a escrita anda: nada a reanunciar.
      final Finder no = find.bySemanticsLabel(RegExp('^Memora disse: '));
      final String antes = t.getSemantics(no).label;
      await t.pump(const Duration(milliseconds: 300));
      expect(t.getSemantics(no).label, antes);
      await t.pump(const Duration(seconds: 10));
      h.dispose();
    });

    testWidgets('com "reduzir movimento", a fala aparece inteira, de uma vez', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(balao(), reduzirMovimento: true));
      expect(visivel(t), falaLimpa, reason: 'já no primeiro quadro');
      expect(
        t.binding.transientCallbackCount,
        0,
        reason: 'sem movimento, nenhum relógio é ligado',
      );
    });

    testWidgets('sem escreverAosPoucos (fala antiga), aparece inteira e sem '
        'relógio', (WidgetTester t) async {
      await t.pumpWidget(app(balao(aosPoucos: false)));
      expect(visivel(t), falaLimpa);
      expect(t.binding.transientCallbackCount, 0);
    });

    testWidgets('a fala da pessoa nunca é escrita aos poucos', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(
        app(
          const BalaoDeFala(
            autor: AutorDoBalao.pessoa,
            texto: 'como vejo as fotos do meu neto',
            escreverAosPoucos: true,
          ),
        ),
      );
      expect(find.text('como vejo as fotos do meu neto'), findsOneWidget);
      expect(t.binding.transientCallbackCount, 0);
    });

    testWidgets('avisa a cada letra nova, para a lista rolar atrás', (
      WidgetTester t,
    ) async {
      int avisos = 0;
      await t.pumpWidget(app(balao(aoEscrever: () => avisos++)));
      await t.pump(const Duration(milliseconds: 200));
      await t.pump(const Duration(milliseconds: 200));
      expect(avisos, greaterThanOrEqualTo(2));
      await t.pump(const Duration(seconds: 10));
      final int fim = avisos;
      await t.pump(const Duration(seconds: 1));
      expect(avisos, fim, reason: 'terminada a escrita, ninguém é avisado');
    });

    testWidgets('o texto que cresce (chegando aos pedaços) continua de onde '
        'estava, sem recomeçar', (WidgetTester t) async {
      const Key chave = ValueKey<String>('fala');
      Widget com(String texto, {required bool andamento}) => app(
        BalaoDeFala(
          key: chave,
          autor: AutorDoBalao.memora,
          texto: texto,
          escreverAosPoucos: true,
          emAndamento: andamento,
        ),
      );

      await t.pumpWidget(
        com('Para ver as fotos, abra o **What', andamento: true),
      );
      await t.pump(const Duration(milliseconds: 300));
      final int jaEscrito = visivel(t).length;
      expect(jaEscrito, greaterThan(0));

      // Chega mais texto — e depois a mensagem final, com a mesma chave.
      await t.pumpWidget(
        com('Para ver as fotos, abra o **WhatsApp** e toque.', andamento: true),
      );
      expect(
        visivel(t).length,
        greaterThanOrEqualTo(jaEscrito),
        reason: 'mais texto não zera o que já apareceu',
      );
      await t.pump(const Duration(milliseconds: 100));
      final int antesDoFinal = visivel(t).length;

      await t.pumpWidget(
        com(
          'Para ver as fotos, abra o **WhatsApp** e toque.',
          andamento: false,
        ),
      );
      expect(
        visivel(t).length,
        greaterThanOrEqualTo(antesDoFinal),
        reason: 'a mensagem final continua a escrita, não recomeça',
      );

      await t.pump(const Duration(seconds: 10));
      expect(visivel(t), 'Para ver as fotos, abra o WhatsApp e toque.');
    });

    testWidgets('enquanto o `**` ainda não fechou, nenhum asterisco aparece '
        '(texto chegando)', (WidgetTester t) async {
      await t.pumpWidget(
        app(
          const BalaoDeFala(
            autor: AutorDoBalao.memora,
            texto: 'Abra o **WhatsA',
            escreverAosPoucos: true,
            emAndamento: true,
          ),
        ),
      );
      await t.pump(const Duration(seconds: 10));
      expect(visivel(t), 'Abra o WhatsA');
      expect(todoTextoNaTela(t), isNot(contains('*')));
    });
  });
}
