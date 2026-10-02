import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

import '../suporte/aparelhos.dart';

/// `AvisoCompacto` — T018, R5 e FR-049 da feature 004.
///
/// O portão central é o teto: aberto, o aviso **não passa de metade da altura
/// da tela**, em nenhuma combinação. Foi um teto em pixel, medido num
/// aparelho só, que deixou a conversa espremida no 360×640 (PR #28).
void main() {
  const String titulo = 'O Memora nunca pede a sua senha';
  const String resumo = 'Nem por mensagem, nem por ligação.';
  final String completo = List<String>.filled(
    30,
    'Se alguém pedir a sua senha ou o número que chegou, desligue. ',
  ).join();

  Widget aviso() =>
      AvisoCompacto(titulo: titulo, resumo: resumo, textoCompleto: completo);

  Widget app(Widget filho) => MaterialApp(
    theme: TemasMemora.claro,
    home: Scaffold(body: SingleChildScrollView(child: filho)),
  );

  testWidgets('fechado: título e resumo, e o texto inteiro fora da árvore', (
    WidgetTester t,
  ) async {
    await t.pumpWidget(app(aviso()));
    expect(find.text(titulo), findsOneWidget);
    expect(find.text(resumo), findsOneWidget);
    expect(find.byKey(AvisoCompacto.chaveTextoCompleto), findsNothing);
    expect(find.text(AvisoCompacto.rotuloAbrir), findsOneWidget);
  });

  testWidgets('aberto: o título continua, e o texto inteiro aparece', (
    WidgetTester t,
  ) async {
    await t.pumpWidget(app(aviso()));
    await t.tap(find.byKey(AvisoCompacto.chaveAlternar));
    await t.pump();
    expect(find.text(titulo), findsOneWidget);
    expect(find.text(completo), findsOneWidget);
    expect(find.text(AvisoCompacto.rotuloFechar), findsOneWidget);
  });

  testWidgets('o título é cabeçalho para o leitor de tela', (
    WidgetTester t,
  ) async {
    final SemanticsHandle h = t.ensureSemantics();
    await t.pumpWidget(app(aviso()));
    expect(
      t.getSemantics(find.bySemanticsLabel(titulo)),
      isSemantics(isHeader: true),
    );
    h.dispose();
  });

  testWidgets('começa fechado a cada montagem', (WidgetTester t) async {
    await t.pumpWidget(app(aviso()));
    await t.tap(find.byKey(AvisoCompacto.chaveAlternar));
    await t.pump();
    expect(find.byKey(AvisoCompacto.chaveTextoCompleto), findsOneWidget);

    await t.pumpWidget(app(const SizedBox()));
    await t.pumpWidget(app(aviso()));
    expect(find.byKey(AvisoCompacto.chaveTextoCompleto), findsNothing);
  });

  testWidgets('não aceita toque fora do controle — é informação', (
    WidgetTester t,
  ) async {
    await t.pumpWidget(app(aviso()));
    // Um InkWell só: o do botão terciário. O bloco em si não é ação.
    expect(find.byType(InkWell), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(AvisoCompacto.chaveAlternar),
        matching: find.byType(InkWell),
      ),
      findsOneWidget,
    );
  });

  testWidgets('com o teclado aberto, o teto é metade do que SOBRA da tela',
      (WidgetTester t) async {
    // A altura da tela não diminui com o teclado: num 360x640 com 300 px de
    // teclado, metade da tela (320) é quase toda a área que sobra (340) — a
    // lição da PR #28 de novo (revisão da #38).
    // O teclado na JANELA, como no aparelho: um `MediaQuery` por fora seria
    // apagado pelo `Scaffold`, e o teste não provaria nada.
    vestir(t, const Size(360, 640));
    t.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(t.view.resetViewInsets);
    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        home: Scaffold(body: SingleChildScrollView(child: aviso())),
      ),
    );
    await t.tap(find.byKey(AvisoCompacto.chaveAlternar));
    await t.pump();
    expect(find.text(AvisoCompacto.rotuloFechar), findsOneWidget);
    expect(
      t.getSize(find.byType(AvisoCompacto)).height,
      lessThanOrEqualTo((640 - 300) * 0.5),
    );
  });

  group('Aberto, não passa de metade da tela — R5', () {
    for (final Combinacao c in matriz()) {
      testWidgets('em ${nomeDa(c)}', (WidgetTester t) async {
        vestir(t, c.aparelho);
        await t.pumpWidget(
          naCombinacao(
            c,
            Scaffold(body: SingleChildScrollView(child: aviso())),
          ),
        );
        // Role antes de tocar: com o resumo inteiro, a 200% o botão fica
        // abaixo da dobra no 320x568, e o toque fora da tela não abre nada.
        await t.ensureVisible(find.byKey(AvisoCompacto.chaveAlternar));
        await t.pump();
        await t.tap(find.byKey(AvisoCompacto.chaveAlternar));
        await t.pump();
        expect(find.text(AvisoCompacto.rotuloFechar), findsOneWidget,
            reason: '${nomeDa(c)}: o aviso precisa estar aberto para medir');

        expect(t.takeException(), isNull, reason: nomeDa(c));
        final double altura = t.getSize(find.byType(AvisoCompacto)).height;
        expect(
          altura,
          // 0,5 escrito aqui, e não o token: comparar com o token passaria
          // mesmo com `tetoDoAvisoAberto = 0.9` (revisão da #38).
          lessThanOrEqualTo(c.aparelho.height * 0.5),
          reason:
              '${nomeDa(c)}: o aviso aberto mede ${altura.round()} px, '
              'mais que metade dos ${c.aparelho.height.round()} da tela',
        );
      });
    }
  });
}
