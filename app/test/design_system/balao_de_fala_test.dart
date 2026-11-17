import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

import '../suporte/aparelhos.dart';

/// `BalaoDeFala` — T020, FR-020 e FR-021 da feature 004.
void main() {
  Widget app(Widget filho) => MaterialApp(
    theme: TemasMemora.claro,
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(MemoraEspacamento.lg),
        child: filho,
      ),
    ),
  );

  group('Quem disse — posição, desenho e nome, nunca só cor (FR-020)', () {
    testWidgets('a Memora fala da esquerda, com o rosto dela', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(
        app(const BalaoDeFala(autor: AutorDoBalao.memora, texto: 'Olá!')),
      );
      expect(find.byType(MemoraPersonagem), findsOneWidget);
      expect(find.text('Memora'), findsOneWidget);
      expect(
        t.getTopLeft(find.byType(MemoraPersonagem)).dx,
        lessThan(t.getTopLeft(find.text('Olá!')).dx),
      );
    });

    testWidgets('a pessoa fala da direita, com o desenho dela e "Você"', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(
        app(const BalaoDeFala(autor: AutorDoBalao.pessoa, texto: 'Oi')),
      );
      expect(find.byType(MemoraPersonagem), findsNothing);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.text('Você'), findsOneWidget);
      expect(
        t.getTopLeft(find.byIcon(Icons.person)).dx,
        greaterThan(t.getTopLeft(find.text('Oi')).dx),
      );
    });

    testWidgets('sem rosto (a conversa, FR-042): so posicao e nome escrito', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(
        app(
          const Column(
            children: <Widget>[
              BalaoDeFala(
                autor: AutorDoBalao.memora,
                texto: 'Olá!',
                comRosto: false,
              ),
              BalaoDeFala(
                autor: AutorDoBalao.pessoa,
                texto: 'Oi',
                comRosto: false,
              ),
              BalaoDeFala.escrevendo(comRosto: false),
            ],
          ),
        ),
      );
      expect(find.byType(MemoraPersonagem), findsNothing);
      expect(find.byType(MemoraAnimada), findsNothing);
      expect(find.byIcon(Icons.person), findsNothing);
      expect(find.text('Memora'), findsNWidgets(2));
      expect(find.text('Você'), findsOneWidget);
      // O balão da pessoa continua à direita da Memora.
      expect(
        t.getTopLeft(find.text('Você')).dx,
        greaterThan(t.getTopLeft(find.text('Memora').first).dx - 1),
      );
    });

    testWidgets('o leitor anuncia quem disse', (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      await t.pumpWidget(
        app(
          const Column(
            children: <Widget>[
              BalaoDeFala(autor: AutorDoBalao.memora, texto: 'Olá!'),
              BalaoDeFala(autor: AutorDoBalao.pessoa, texto: 'Oi'),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Memora disse: Olá!'), findsOneWidget);
      expect(find.bySemanticsLabel('Você disse: Oi'), findsOneWidget);
      h.dispose();
    });

    testWidgets('escrevendo é estado visível sem animação', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      await t.pumpWidget(app(const BalaoDeFala.escrevendo()));
      expect(find.textContaining(BalaoDeFala.textoEscrevendo), findsOneWidget);
      expect(find.byType(MemoraPersonagem), findsOneWidget);
      expect(
        find.bySemanticsLabel('Memora está ${BalaoDeFala.textoEscrevendo}'),
        findsOneWidget,
      );
      h.dispose();
    });

    testWidgets('o balão em si não aceita toque', (WidgetTester t) async {
      await t.pumpWidget(
        app(const BalaoDeFala(autor: AutorDoBalao.memora, texto: 'Olá!')),
      );
      expect(find.byType(InkWell), findsNothing);
    });
  });

  group('Opções — FR-021', () {
    Widget comOpcoes({VoidCallback? sim, VoidCallback? nao}) => app(
      BalaoDeFala(
        autor: AutorDoBalao.memora,
        texto: 'Quer que eu abra o WhatsApp?',
        opcoes: <OpcaoDoBalao>[
          OpcaoDoBalao(rotulo: 'Sim, pode abrir', aoEscolher: sim),
          OpcaoDoBalao(rotulo: 'Não, quero aprender', aoEscolher: nao),
        ],
      ),
    );

    testWidgets('frases completas, empilhadas, com 56 dp', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(comOpcoes(sim: () {}, nao: () {}));
      final Rect sim = t.getRect(
        find.widgetWithText(BotaoSecundario, 'Sim, pode abrir'),
      );
      final Rect nao = t.getRect(
        find.widgetWithText(BotaoSecundario, 'Não, quero aprender'),
      );
      expect(sim.height, greaterThanOrEqualTo(MemoraDimensoes.alvoDecisao));
      expect(nao.height, greaterThanOrEqualTo(MemoraDimensoes.alvoDecisao));
      expect(nao.top, greaterThan(sim.bottom), reason: 'lado a lado');
    });

    testWidgets('afastadas o bastante para não serem tocadas por engano', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(comOpcoes(sim: () {}, nao: () {}));
      final Rect sim = t.getRect(
        find.widgetWithText(BotaoSecundario, 'Sim, pode abrir'),
      );
      final Rect nao = t.getRect(
        find.widgetWithText(BotaoSecundario, 'Não, quero aprender'),
      );
      // O piso vem do contrato (16 dp), e não da constante do componente:
      // comparar com ela passaria mesmo com a separação reduzida a zero.
      expect(nao.top - sim.bottom, greaterThanOrEqualTo(MemoraEspacamento.lg));
    });

    testWidgets('depois de escolhida, a opção fica desabilitada', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      await t.pumpWidget(comOpcoes());
      expect(
        t.getSemantics(find.widgetWithText(BotaoSecundario, 'Sim, pode abrir')),
        isSemantics(isButton: true, isEnabled: false),
      );
      h.dispose();
    });
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
                  BalaoDeFala(
                    autor: AutorDoBalao.memora,
                    texto:
                        'O Instagram é o aplicativo com uma câmera no meio, '
                        'roxo e rosa. Quer que eu te mostre onde ele fica?',
                    opcoes: <OpcaoDoBalao>[
                      OpcaoDoBalao(rotulo: 'Sim, me mostre', aoEscolher: () {}),
                      OpcaoDoBalao(rotulo: 'Agora não', aoEscolher: () {}),
                    ],
                  ),
                  const BalaoDeFala(
                    autor: AutorDoBalao.pessoa,
                    texto: 'Meu neto postou uma foto e eu não consigo abrir.',
                  ),
                  const BalaoDeFala.escrevendo(),
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
