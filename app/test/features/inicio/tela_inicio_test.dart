import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/inicio/presentation/tela_inicio.dart';
import 'package:memora/l10n/textos_casca.dart';

import '../../suporte/aparelhos.dart';

/// O Início — T034, FR-014, FR-019 e FR-044 da feature 004.
void main() {
  Widget inicio({
    String nome = 'Ana',
    VoidCallback? aoConversar,
    VoidCallback? aoVerTudo,
  }) => TelaInicio(nome: nome, aoConversar: aoConversar, aoVerTudo: aoVerTudo);

  Widget app(Widget filho) =>
      MaterialApp(theme: TemasMemora.claro, home: filho);

  group('O que o Início oferece — FR-014', () {
    testWidgets('cumprimenta pelo nome de tratamento', (WidgetTester t) async {
      await t.pumpWidget(app(inicio(nome: 'Dona Ana')));
      expect(find.text(TextosCasca.inicioSaudacao('Dona Ana')), findsOneWidget);
      expect(find.byKey(TelaInicio.chaveSaudacao), findsOneWidget);
    });

    testWidgets('um atalho para conversar e um para ver tudo, e os dois abrem', (
      WidgetTester t,
    ) async {
      int conversou = 0;
      int viuTudo = 0;
      await t.pumpWidget(
        app(inicio(aoConversar: () => conversou++, aoVerTudo: () => viuTudo++)),
      );

      await t.tap(find.byKey(TelaInicio.chaveConversar));
      await t.tap(find.byKey(TelaInicio.chaveVerTudo));

      expect(conversou, 1);
      expect(viuTudo, 1);
    });

    testWidgets('a conversa é a ação principal, e só ela (FR-002)', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(inicio(aoConversar: () {}, aoVerTudo: () {})));

      // Dois botões preenchidos dividiriam a atenção de quem precisa de um
      // caminho só.
      expect(find.byType(BotaoPrimario), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(TelaInicio.chaveConversar),
          matching: find.text(TextosCasca.inicioConversar),
        ),
        findsOneWidget,
      );
      expect(find.byType(BotaoSecundario), findsOneWidget);
    });

    testWidgets('sem assistente, não há atalho para conversa, e o que sobra '
        'é a ação principal', (WidgetTester t) async {
      await t.pumpWidget(app(inicio(aoVerTudo: () {})));

      expect(find.byKey(TelaInicio.chaveConversar), findsNothing);
      expect(find.byType(BotaoPrimario), findsOneWidget);
      expect(find.byKey(TelaInicio.chaveVerTudo), findsOneWidget);
    });

    testWidgets('sem nada a oferecer, só cumprimenta — botão sem destino não '
        'existe (FR-018)', (WidgetTester t) async {
      await t.pumpWidget(app(inicio()));

      expect(find.byType(BotaoPrimario), findsNothing);
      expect(find.byType(BotaoSecundario), findsNothing);
      expect(find.byKey(TelaInicio.chaveSaudacao), findsOneWidget);
    });
  });

  group('O que o Início NÃO tem', () {
    testWidgets('nenhum "Sair" — a saída fica em Ajustes (FR-019)', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(inicio(aoConversar: () {}, aoVerTudo: () {})));
      expect(find.textContaining('Sair'), findsNothing);
      expect(find.textContaining('sair'), findsNothing);
      expect(find.byType(BotaoPerigo), findsNothing);
    });

    testWidgets('nenhum termo técnico: "Hub" é nome de trabalho (FR-008)', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(inicio(aoConversar: () {}, aoVerTudo: () {})));
      expect(find.textContaining('Hub'), findsNothing);
      expect(find.textContaining('Chatbot'), findsNothing);
    });
  });

  group('Estados — FR-006', () {
    testWidgets('o Início não carrega nada, então não tem o que desenhar '
        'enquanto espera', (WidgetTester t) async {
      // O nome vem da sessão e os atalhos são dados prontos: não há
      // "carregando", "vazio" nem "erro" nesta tela. Se um dia houver, é aqui
      // que o `exigirOsEstadosDaFr006` passa a ser chamado.
      await t.pumpWidget(app(inicio(aoConversar: () {}, aoVerTudo: () {})));
      expect(find.byType(Carregando), findsNothing);
      expect(find.byType(MensagemErro), findsNothing);
    });
  });

  group('A Memora cede espaço, o texto e a ação não', () {
    testWidgets('com pouca altura a figura some e a ação principal fica', (
      WidgetTester t,
    ) async {
      vestir(t, const Size(320, 120));
      await t.pumpWidget(app(inicio(aoConversar: () {}, aoVerTudo: () {})));

      expect(find.byKey(TelaInicio.chaveMemora), findsNothing);
      expect(find.byKey(TelaInicio.chaveSaudacao), findsOneWidget);
      expect(find.byKey(TelaInicio.chaveConversar), findsOneWidget);
    });
  });

  group('Matriz — FR-044', () {
    for (final Combinacao c in matriz()) {
      testWidgets('o Início não estoura e a conversa é alcançável em '
          '${nomeDa(c)}', (WidgetTester t) async {
        vestir(t, c.aparelho);
        int conversou = 0;
        await t.pumpWidget(
          naCombinacao(
            c,
            inicio(aoConversar: () => conversou++, aoVerTudo: () {}),
          ),
        );

        expect(t.takeException(), isNull, reason: nomeDa(c));

        // A figura é fração da altura, nunca pixel (regra 3).
        final Finder memora = find.byKey(TelaInicio.chaveMemora);
        if (memora.evaluate().isNotEmpty) {
          expect(
            t.getSize(memora).height,
            lessThanOrEqualTo(
              c.aparelho.height * MemoraDimensoes.fracaoDaIlustracaoHeroi,
            ),
            reason: '${nomeDa(c)}: a Memora passou da fração da altura',
          );
        }

        await exigirAlcancavel(
          t,
          find.byKey(TelaInicio.chaveConversar),
          aparelho: c.aparelho,
          contexto: nomeDa(c),
        );
        await t.tap(find.byKey(TelaInicio.chaveConversar));
        expect(
          conversou,
          1,
          reason: '${nomeDa(c)}: a ação principal não respondeu ao toque',
        );
      });
    }
  });
}
