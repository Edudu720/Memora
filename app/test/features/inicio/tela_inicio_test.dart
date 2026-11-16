import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/inicio/presentation/tela_inicio.dart';
import 'package:memora/l10n/textos_anfitria.dart';
import 'package:memora/l10n/textos_casca.dart';

import '../../suporte/aparelhos.dart';
import '../../suporte/movimento.dart';

/// O Início — T034, FR-014, FR-019 e FR-044 da feature 004.
void main() {
  Widget inicio({
    String nome = 'Ana',
    VoidCallback? aoConversar,
    VoidCallback? aoVerTudo,
  }) => TelaInicio(nome: nome, aoConversar: aoConversar, aoVerTudo: aoVerTudo);

  /// A dica que a pessoa VÊ no balão: o balão guarda, escondidas, todas as
  /// dicas (para medir a altura), e procurar o texto solto acharia duas.
  Finder dicaVisivel(String dica) => find.descendant(
    of: find.byType(AnimatedSwitcher),
    matching: find.text(dica),
  );

  Widget app(Widget filho) =>
      MaterialApp(theme: TemasMemora.claro, home: filho);

  group('O que o Início oferece — FR-014', () {
    testWidgets('cumprimenta pelo nome de tratamento', (WidgetTester t) async {
      await t.pumpWidget(app(inicio(nome: 'Dona Ana')));
      expect(find.text(TextosCasca.inicioSaudacao('Dona Ana')), findsOneWidget);
      expect(find.byKey(TelaInicio.chaveSaudacao), findsOneWidget);
    });

    testWidgets(
      'um atalho para conversar e um para ver tudo, e os dois abrem',
      (WidgetTester t) async {
        int conversou = 0;
        int viuTudo = 0;
        await t.pumpWidget(
          app(
            inicio(aoConversar: () => conversou++, aoVerTudo: () => viuTudo++),
          ),
        );

        // Com as caixas e a frase da Memora o Início passou da janela de
        // 800x600 do teste: rola antes de tocar.
        await t.ensureVisible(find.byKey(TelaInicio.chaveConversar));
        await t.tap(find.byKey(TelaInicio.chaveConversar));
        await t.ensureVisible(find.byKey(TelaInicio.chaveVerTudo));
        await t.tap(find.byKey(TelaInicio.chaveVerTudo));

        expect(conversou, 1);
        expect(viuTudo, 1);
      },
    );

    testWidgets('a conversa é a ação principal, e só ela (FR-002)', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(inicio(aoConversar: () {}, aoVerTudo: () {})));

      // Dois botões preenchidos dividiriam a atenção de quem precisa de um
      // caminho só.
      expect(find.byType(CartaoHeroi), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(TelaInicio.chaveConversar),
          matching: find.text(TextosCasca.inicioConversar),
        ),
        findsOneWidget,
      );
      expect(find.byType(LinhaDeLista), findsOneWidget);
    });

    testWidgets('sem assistente, não há atalho para conversa, e o que sobra '
        'é a ação principal', (WidgetTester t) async {
      await t.pumpWidget(app(inicio(aoVerTudo: () {})));

      expect(find.byKey(TelaInicio.chaveConversar), findsNothing);
      expect(find.byType(CartaoHeroi), findsNothing);
      expect(find.byKey(TelaInicio.chaveVerTudo), findsOneWidget);
    });

    testWidgets('sem nada a oferecer, só cumprimenta — botão sem destino não '
        'existe (FR-018)', (WidgetTester t) async {
      await t.pumpWidget(app(inicio()));

      expect(find.byType(CartaoHeroi), findsNothing);
      expect(find.byType(LinhaDeLista), findsNothing);
      expect(find.byKey(TelaInicio.chaveSaudacao), findsOneWidget);
    });
  });

  group('A Memora ensina a tela — R2, regra 9, e é a anfitriã (T053)', () {
    testWidgets('a primeira dica da anfitriã é a frase que ensina a tela e '
        'concorda com o número de caixas', (WidgetTester t) async {
      await t.pumpWidget(app(inicio(aoConversar: () {}, aoVerTudo: () {})));
      expect(find.byKey(TelaInicio.chaveMemora), findsOneWidget);
      expect(find.byType(MemoraAnfitria), findsOneWidget);
      expect(dicaVisivel(TextosCasca.inicioTutorial(2)), findsOneWidget);
      expect(TextosCasca.inicioTutorial(2), contains('caixas'));

      await t.pumpWidget(app(inicio(aoVerTudo: () {})));
      expect(dicaVisivel(TextosCasca.inicioTutorial(1)), findsOneWidget);
      expect(TextosCasca.inicioTutorial(1), contains('caixa abaixo'));
    });

    testWidgets('o leitor de tela lê a frase do balão dela', (
      WidgetTester t,
    ) async {
      final SemanticsHandle semantica = t.ensureSemantics();
      await t.pumpWidget(app(inicio(aoConversar: () {}, aoVerTudo: () {})));

      expect(
        find.bySemanticsLabel(TextosCasca.inicioTutorial(2)),
        findsOneWidget,
      );
      semantica.dispose();
    });

    testWidgets('sem atalho nenhum não há frase de tutorial: ela apontaria '
        'para o nada, e a anfitriã começa pelas dicas de sempre', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(inicio()));
      expect(dicaVisivel(TextosCasca.inicioTutorial(1)), findsNothing);
      expect(dicaVisivel(TextosCasca.inicioTutorial(2)), findsNothing);
      expect(dicaVisivel(TextosAnfitria.dicas.first), findsOneWidget);
      expect(find.byType(BalaoDeFala), findsNothing);
    });

    testWidgets('a Memora aparece uma vez só na tela (FR-006)', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(inicio(aoConversar: () {}, aoVerTudo: () {})));
      expect(find.byType(MemoraAnimada), findsOneWidget);
      expect(find.byType(MemoraPersonagem), findsNothing);
    });

    testWidgets('a saudação pelo nome continua (FR-014)', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(inicio(nome: 'Dona Ana', aoVerTudo: () {})));
      expect(find.text(TextosCasca.inicioSaudacao('Dona Ana')), findsOneWidget);
    });
  });

  group('Cada atalho numa caixa que diz para que serve — FR-002a', () {
    Finder caixaDe(Key atalho) => find.ancestor(
      of: find.byKey(atalho),
      matching: find.byType(KeyedSubtree),
    );

    testWidgets('conversar e ver tudo moram cada um na sua caixa, com a '
        'instrução escrita nela', (WidgetTester t) async {
      await t.pumpWidget(app(inicio(aoConversar: () {}, aoVerTudo: () {})));

      expect(caixaDe(TelaInicio.chaveConversar), findsWidgets);
      expect(caixaDe(TelaInicio.chaveVerTudo), findsWidgets);
      expect(find.byType(CartaoHeroi), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(TelaInicio.chaveCaixaConversar),
          matching: find.byKey(TelaInicio.chaveConversar),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(TelaInicio.chaveCaixaVerTudo),
          matching: find.byKey(TelaInicio.chaveVerTudo),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: find.byKey(TelaInicio.chaveCaixaConversar),
          matching: find.text(TextosCasca.inicioInstrucaoConversar),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(TelaInicio.chaveCaixaVerTudo),
          matching: find.text(TextosCasca.inicioInstrucaoVerTudo),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sem assistente, a caixa de conversar some junto com o '
        'atalho (FR-018)', (WidgetTester t) async {
      await t.pumpWidget(app(inicio(aoVerTudo: () {})));

      expect(find.byKey(TelaInicio.chaveCaixaConversar), findsNothing);
      expect(
        find.text(TextosCasca.inicioInstrucaoConversar),
        findsNothing,
        reason: 'instrução sem o que tocar é porta pintada na parede',
      );
      expect(find.byKey(TelaInicio.chaveCaixaVerTudo), findsOneWidget);
    });

    testWidgets('sem "ver tudo", a caixa dele some e só a conversa fica', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(inicio(aoConversar: () {})));

      expect(find.byKey(TelaInicio.chaveCaixaVerTudo), findsNothing);
      expect(find.text(TextosCasca.inicioInstrucaoVerTudo), findsNothing);
      expect(find.byKey(TelaInicio.chaveCaixaConversar), findsOneWidget);
    });

    testWidgets('sem atalho nenhum, nenhuma caixa (FR-018)', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(inicio()));
      expect(find.byKey(TelaInicio.chaveCaixaConversar), findsNothing);
      expect(find.byKey(TelaInicio.chaveCaixaVerTudo), findsNothing);
    });

    testWidgets('tocar na anfitriã ou no balão dela não leva a lugar nenhum '
        '(FR-056)', (WidgetTester t) async {
      int toques = 0;
      await t.pumpWidget(
        app(inicio(aoConversar: () => toques++, aoVerTudo: () => toques++)),
      );
      await t.tap(find.byKey(MemoraAnfitria.chaveDoBalao));
      await t.pump();
      await t.tap(find.byKey(MemoraAnfitria.chaveDaAcao));
      await t.pump();
      expect(toques, 0, reason: 'a anfitriã mostra dica, nunca navega');
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

  group('A Memora cede espaço, o texto e a ação não — FR-041', () {
    testWidgets('com pouca altura a anfitriã fica no piso e a ação principal '
        'continua', (WidgetTester t) async {
      vestir(t, const Size(320, 120));
      await t.pumpWidget(app(inicio(aoConversar: () {}, aoVerTudo: () {})));

      expect(
        t.getSize(find.byKey(MemoraAnfitria.chaveDaAcao)).width,
        MemoraDimensoes.alvoMinimo,
      );
      expect(find.byKey(TelaInicio.chaveSaudacao), findsOneWidget);
      expect(find.byKey(TelaInicio.chaveConversar), findsOneWidget);
    });

    testWidgets('com a letra ampliada o desenho dela encolhe, e quanto mais '
        'ampliada menor', (WidgetTester t) async {
      vestir(t, referencia);
      double lado() => t.getSize(find.byKey(MemoraAnfitria.chaveDaAcao)).width;

      final List<double> lados = <double>[];
      for (final double escala in escalas) {
        await t.pumpWidget(
          naCombinacao((
            aparelho: referencia,
            escala: escala,
            tema: MemoraTemaId.claro,
          ), inicio(aoConversar: () {}, aoVerTudo: () {})),
        );
        lados.add(lado());
      }
      expect(lados[1], lessThan(lados[0]), reason: '150% encolhe: $lados');
      expect(lados[2], lessThan(lados[1]), reason: '200% encolhe mais: $lados');
      expect(lados[2], greaterThanOrEqualTo(MemoraDimensoes.alvoMinimo));
    });
  });

  group('O sinal de atividade — FR-052 (T053)', () {
    testWidgets('um toque em QUALQUER lugar do Início adia a troca da dica', (
      WidgetTester t,
    ) async {
      liberarMovimento(t);
      await t.pumpWidget(app(inicio(aoConversar: () {}, aoVerTudo: () {})));
      final String primeira = TextosCasca.inicioTutorial(2);
      final String segunda = TextosAnfitria.dicas.first;
      // Com movimento, a dica é escrita aos poucos: deixa terminar.
      await t.pump(const Duration(seconds: 5));
      expect(dicaVisivel(primeira), findsOneWidget);

      await t.pump(const Duration(seconds: 10));
      // Aos 15 s a pessoa toca na saudação, que não é botão nem é a anfitriã.
      await t.tap(find.byKey(TelaInicio.chaveSaudacao));
      await t.pump(const Duration(seconds: 10));
      await t.pump(const Duration(seconds: 3));
      expect(
        dicaVisivel(primeira),
        findsOneWidget,
        reason: 'aos 28 s, 13 s depois do toque: ainda é a primeira dica',
      );

      await t.pump(const Duration(seconds: 10));
      await t.pump(const Duration(seconds: 5));
      expect(dicaVisivel(segunda), findsOneWidget, reason: 'passou dos 20 s');
      expect(dicaVisivel(primeira), findsNothing);
    });

    testWidgets('o toque na saudação não é consumido: o botão ao lado segue '
        'tocável', (WidgetTester t) async {
      int conversou = 0;
      await t.pumpWidget(
        app(inicio(aoConversar: () => conversou++, aoVerTudo: () {})),
      );
      await t.ensureVisible(find.byKey(TelaInicio.chaveConversar));
      await t.tap(find.byKey(TelaInicio.chaveConversar));
      expect(conversou, 1);
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

        // O desenho dela é fração da altura dividida pela ampliação, nunca
        // pixel (regra 3, FR-041), entre o piso do alvo de toque e o teto.
        final double lado = t
            .getSize(find.byKey(MemoraAnfitria.chaveDaAcao))
            .width;
        expect(
          lado,
          closeTo(
            (c.aparelho.height *
                    MemoraDimensoes.fracaoDaAnfitriaDoInicio /
                    c.escala)
                .clamp(
                  MemoraDimensoes.alvoMinimo,
                  MemoraDimensoes.ilustracaoHeroi,
                ),
            0.5,
          ),
          reason: '${nomeDa(c)}: o desenho dela não segue a fração da altura',
        );

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

        // O segundo atalho também precisa poder ser tocado: a frase da Memora
        // e as duas caixas não empurram nada para fora. (A frase em si pode
        // ser mais alta que a janela a 200% com a fonte quadrada — texto
        // longo rola, e isso não é defeito —, por isso só a ação é exigida
        // inteira à vista.)
        await exigirAlcancavel(
          t,
          find.byKey(TelaInicio.chaveVerTudo),
          aparelho: c.aparelho,
          contexto: nomeDa(c),
        );
        expect(find.byKey(TelaInicio.chaveMemora), findsOneWidget);
      });
    }
  });
}
