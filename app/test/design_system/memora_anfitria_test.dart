import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/componentes/ilustracao/memora_animada/pintores/contexto_de_pintura.dart';
import 'package:memora/design_system/componentes/ilustracao/memora_animada/pintores/pintor_da_memora.dart';
import 'package:memora/design_system/design_system.dart';

/// A `MemoraAnfitria` (feature 013, T084; FR-051 a FR-057).
///
/// ## Como se observa
///
/// - O **texto** do balão: `find.text` dentro do `AnimatedSwitcher`. O balão
///   tem, escondidas, todas as dicas (para medir a altura), então procurar o
///   texto no balão inteiro acha cópias que a pessoa não vê.
/// - A **boca**: o `ContextoDePintura` que o pintor recebe a cada quadro
///   (`fala` e a pose), o mesmo número que a pessoa vê.
/// - Os **relógios**: `transientCallbackCount`, que conta os `Ticker` ativos.
void main() {
  const List<String> dicas = <String>[
    'Primeira dica: toque no cartão grande para começar a conversar comigo.',
    'Segunda dica: a letra pode ficar maior, é só pedir em Ajustes.',
    'Terceira dica: eu nunca peço a sua senha nem o código que chega.',
  ];

  Finder textoDaDica(String dica) => find.descendant(
    of: find.byType(AnimatedSwitcher),
    matching: find.text(dica),
  );

  /// Monta a anfitriã. Os dois bichos do `MediaQuery` são dados pelo teste:
  /// copiar o `MediaQuery` do aplicativo, e não criar um do zero, mantém o
  /// tamanho da tela (um `MediaQueryData()` novo tem tamanho zero).
  Future<void> montar(
    WidgetTester t, {
    bool reduzir = false,
    bool leitor = false,
    NavigatorObserver? observador,
    double tamanho = 160,
    List<String> lista = dicas,
  }) async {
    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        navigatorObservers: <NavigatorObserver>[?observador],
        home: Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reduzir,
              accessibleNavigation: leitor,
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Center(
                  child: MemoraAnfitria(
                    dicas: lista,
                    tamanho: tamanho,
                    sementeDaAgenda: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// O que a Memora está pintando agora.
  ContextoDePintura quadro(WidgetTester t) {
    final CustomPaint pintura = t.widget<CustomPaint>(
      find.descendant(
        of: find.byType(MemoraAnimada),
        matching: find.byType(CustomPaint),
      ),
    );
    return (pintura.painter! as PintorDaMemora).criarContexto(160);
  }

  /// Toca na Memora e dá o quadro seguinte.
  Future<void> tocarNaMemora(WidgetTester t) async {
    await t.tap(find.byKey(MemoraAnfitria.chaveDaAcao));
    await t.pump();
  }

  /// Deixa o balão acabar de trocar (a transição é de 200 ms).
  Future<void> acomodar(WidgetTester t) =>
      t.pump(const Duration(milliseconds: 600));

  group('FR-050 e FR-051: a dica e a boca', () {
    testWidgets('mostra a primeira dica, vinda da lista que recebeu', (
      WidgetTester t,
    ) async {
      await montar(t);
      await t.pump(const Duration(seconds: 3));
      expect(textoDaDica(dicas[0]), findsOneWidget);
      expect(textoDaDica(dicas[1]), findsNothing);
    });

    testWidgets('a boca mexe enquanto o texto aparece e para quando ele acaba', (
      WidgetTester t,
    ) async {
      await montar(t);
      await t.pump(const Duration(milliseconds: 100));

      // O texto tem ~70 letras a 18 ms cada: ainda está aparecendo.
      await t.pump(const Duration(milliseconds: 200));
      final List<double> falas = <double>[];
      for (int i = 0; i < 8; i++) {
        await t.pump(const Duration(milliseconds: 90));
        falas.add(quadro(t).fala);
      }
      expect(
        falas.any((double f) => f > 0.1),
        isTrue,
        reason: 'a boca devia estar mexendo com o texto aparecendo: $falas',
      );
      expect(quadro(t).pose.bocaAbertura, greaterThan(0.1));

      // Depois do último caractere, a boca para: nada de fala, boca de repouso.
      await t.pump(const Duration(seconds: 3));
      await t.pump(
        const Duration(seconds: 1),
      ); // a volta ao repouso leva 360 ms
      expect(textoDaDica(dicas[0]), findsOneWidget);
      expect(quadro(t).fala, 0, reason: 'o texto acabou, a boca para');
      expect(quadro(t).pose.bocaAbertura, 0);
    });

    testWidgets('a dica nova também é falada, e a boca para de novo', (
      WidgetTester t,
    ) async {
      await montar(t);
      await t.pump(const Duration(seconds: 3));
      await tocarNaMemora(t);
      await t.pump(const Duration(milliseconds: 400));
      bool mexeu = false;
      for (int i = 0; i < 8 && !mexeu; i++) {
        await t.pump(const Duration(milliseconds: 90));
        mexeu = quadro(t).fala > 0.1;
      }
      expect(mexeu, isTrue, reason: 'a dica nova aparece falando');
      await t.pump(const Duration(seconds: 3));
      expect(quadro(t).fala, 0);
    });
  });

  group('FR-052: a troca sozinha', () {
    testWidgets('troca aos 20 s, e não antes', (WidgetTester t) async {
      await montar(t);
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(seconds: 18));
      expect(textoDaDica(dicas[0]), findsOneWidget, reason: 'aos 19 s ainda');

      await t.pump(const Duration(seconds: 2));
      await acomodar(t);
      await t.pump(const Duration(seconds: 3));
      expect(textoDaDica(dicas[1]), findsOneWidget, reason: 'passou dos 20 s');
      expect(textoDaDica(dicas[0]), findsNothing);
    });

    testWidgets('continua trocando, e volta à primeira depois da última', (
      WidgetTester t,
    ) async {
      await montar(t);
      await t.pump(const Duration(seconds: 1));
      for (int i = 1; i <= 3; i++) {
        await t.pump(const Duration(seconds: 20));
        await acomodar(t);
        await t.pump(const Duration(seconds: 3));
        expect(
          textoDaDica(dicas[i % dicas.length]),
          findsOneWidget,
          reason: 'troca $i',
        );
      }
    });
  });

  group('FR-053: quando a troca sozinha PARA', () {
    testWidgets('com o leitor de tela ligado, nada troca sozinho', (
      WidgetTester t,
    ) async {
      await montar(t, leitor: true);
      await t.pump(const Duration(seconds: 1));
      for (int i = 0; i < 6; i++) {
        await t.pump(const Duration(seconds: 20));
      }
      await acomodar(t);
      await t.pump(const Duration(seconds: 3));
      expect(
        textoDaDica(dicas[0]),
        findsOneWidget,
        reason:
            'com o leitor de tela a dica NAO pode trocar sozinha (WCAG 2.2.2)',
      );
      expect(textoDaDica(dicas[1]), findsNothing);
    });

    testWidgets('com "reduzir movimento", nada troca sozinho', (
      WidgetTester t,
    ) async {
      await montar(t, reduzir: true);
      await t.pump(const Duration(seconds: 1));
      for (int i = 0; i < 6; i++) {
        await t.pump(const Duration(seconds: 20));
      }
      expect(textoDaDica(dicas[0]), findsOneWidget);
      expect(textoDaDica(dicas[1]), findsNothing);
    });

    testWidgets('depois de um toque, só troca quando a pessoa pedir', (
      WidgetTester t,
    ) async {
      await montar(t);
      await t.pump(const Duration(seconds: 1));
      await tocarNaMemora(t);
      await acomodar(t);
      await t.pump(const Duration(seconds: 3));
      expect(textoDaDica(dicas[1]), findsOneWidget);

      for (int i = 0; i < 6; i++) {
        await t.pump(const Duration(seconds: 20));
      }
      await acomodar(t);
      expect(
        textoDaDica(dicas[1]),
        findsOneWidget,
        reason: 'depois do toque a troca sozinha acabou',
      );

      await tocarNaMemora(t);
      await acomodar(t);
      await t.pump(const Duration(seconds: 3));
      expect(textoDaDica(dicas[2]), findsOneWidget, reason: 'pediu de novo');
    });

    testWidgets(
      'controle: sem nenhuma das três, ela troca (o teste prova algo)',
      (WidgetTester t) async {
        // Sem este caso, os três acima passariam com a anfitriã quebrada e
        // sem nunca trocar de dica.
        await montar(t);
        await t.pump(const Duration(seconds: 1));
        await t.pump(const Duration(seconds: 21));
        await acomodar(t);
        await t.pump(const Duration(seconds: 3));
        expect(textoDaDica(dicas[1]), findsOneWidget);
      },
    );
  });

  group('FR-054 e FR-056: o toque', () {
    testWidgets('tocar na Memora mostra a próxima dica e ela faz um gesto', (
      WidgetTester t,
    ) async {
      await montar(t);
      await t.pump(const Duration(seconds: 3));
      await tocarNaMemora(t);
      await t.pump(const Duration(milliseconds: 150));
      expect(
        quadro(t).aceno.abs() > 0.1 ||
            quadro(t).pulo > 0.1 ||
            quadro(t).piscar > 0.1,
        isTrue,
        reason: 'ao tocar ela faz um gesto',
      );
      await acomodar(t);
      await t.pump(const Duration(seconds: 3));
      expect(textoDaDica(dicas[1]), findsOneWidget);
    });

    testWidgets('tocar no balão também mostra a próxima', (
      WidgetTester t,
    ) async {
      await montar(t);
      await t.pump(const Duration(seconds: 3));
      await t.tap(find.byKey(MemoraAnfitria.chaveDoBalao));
      await t.pump();
      await acomodar(t);
      await t.pump(const Duration(seconds: 3));
      expect(textoDaDica(dicas[1]), findsOneWidget);
    });

    testWidgets('com "reduzir movimento" o toque ainda mostra a próxima', (
      WidgetTester t,
    ) async {
      await montar(t, reduzir: true);
      await t.pump();
      await tocarNaMemora(t);
      await t.pump();
      expect(textoDaDica(dicas[1]), findsOneWidget);
      expect(
        t.binding.transientCallbackCount,
        0,
        reason: 'o toque nao liga nenhum relogio com movimento reduzido',
      );
    });

    testWidgets('tocar nunca abre tela, aplicativo nem link (FR-056)', (
      WidgetTester t,
    ) async {
      final _ContaRotas rotas = _ContaRotas();
      await montar(t, observador: rotas);
      await t.pump(const Duration(seconds: 1));
      final int antes = rotas.empilhadas;

      await tocarNaMemora(t);
      await t.tap(find.byKey(MemoraAnfitria.chaveDoBalao));
      await t.pump();
      await t.tap(find.byKey(MemoraAnfitria.chaveDaAcao));
      await acomodar(t);
      await t.pump(const Duration(seconds: 3));

      expect(rotas.empilhadas, antes, reason: 'nenhuma rota foi empilhada');
      expect(find.byType(MemoraAnfitria), findsOneWidget);
    });
  });

  group('FR-055: a ação acessível', () {
    List<SemanticsNode> comToque(WidgetTester t) {
      final List<SemanticsNode> achados = <SemanticsNode>[];
      void visitar(SemanticsNode n) {
        if (n.getSemanticsData().hasAction(SemanticsAction.tap)) {
          achados.add(n);
        }
        n.visitChildren((SemanticsNode filho) {
          visitar(filho);
          return true;
        });
      }

      visitar(t.getSemantics(find.byType(Scaffold)));
      return achados;
    }

    testWidgets('é um botão "Outra dica da Memora", e o único com toque', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      await montar(t);
      await t.pump(const Duration(seconds: 3));

      final List<SemanticsNode> botoes = comToque(t);
      expect(
        botoes,
        hasLength(1),
        reason: 'o balao e texto, nao e outro botao',
      );
      final SemanticsData d = botoes.single.getSemanticsData();
      expect(d.label, 'Outra dica da Memora');
      expect(d.flagsCollection.isButton, isTrue);
      h.dispose();
    });

    testWidgets('a área é de pelo menos 48 dp, mesmo com a Memora pequena', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      await montar(t, tamanho: 32);
      await t.pump(const Duration(seconds: 1));

      final SemanticsNode botao = comToque(t).single;
      expect(botao.rect.width, greaterThanOrEqualTo(48));
      expect(botao.rect.height, greaterThanOrEqualTo(48));
      final Size alvo = t.getSize(find.byKey(MemoraAnfitria.chaveDaAcao));
      expect(alvo.width, greaterThanOrEqualTo(48));
      expect(alvo.height, greaterThanOrEqualTo(48));
      h.dispose();
    });

    testWidgets('o balão é lido como texto, com a dica inteira', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      await montar(t, leitor: true);
      // O texto ainda está sendo escrito, e o leitor já recebe a dica inteira.
      await t.pump(const Duration(milliseconds: 150));
      expect(find.bySemanticsLabel(dicas[0]), findsOneWidget);
      h.dispose();
    });

    testWidgets('ativar a ação pelo leitor de tela mostra a próxima dica', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      await montar(t, leitor: true);
      await t.pump(const Duration(seconds: 3));
      await t.tap(find.bySemanticsLabel('Outra dica da Memora'));
      await t.pump();
      await acomodar(t);
      await t.pump(const Duration(seconds: 3));
      expect(textoDaDica(dicas[1]), findsOneWidget);
      expect(find.bySemanticsLabel(dicas[1]), findsOneWidget);
      h.dispose();
    });

    testWidgets('anuncia a dica nova ao leitor só quando a pessoa pediu', (
      WidgetTester t,
    ) async {
      final List<String> anuncios = <String>[];
      t.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
        SystemChannels.accessibility,
        (dynamic mensagem) async {
          final Map<dynamic, dynamic> m = mensagem as Map<dynamic, dynamic>;
          if (m['type'] == 'announce') {
            anuncios.add(
              (m['data'] as Map<dynamic, dynamic>)['message'] as String,
            );
          }
          return null;
        },
      );
      addTearDown(
        () => t.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<dynamic>(
              SystemChannels.accessibility,
              null,
            ),
      );

      final SemanticsHandle h = t.ensureSemantics();
      await montar(t, leitor: true);
      await t.pump(const Duration(seconds: 1));
      for (int i = 0; i < 4; i++) {
        await t.pump(const Duration(seconds: 20));
      }
      expect(anuncios, isEmpty, reason: 'nada pedido, nada anunciado');

      await t.tap(find.bySemanticsLabel('Outra dica da Memora'));
      await t.pump();
      expect(anuncios, <String>[dicas[1]], reason: 'pediu: anuncia a nova');
      await acomodar(t);
      h.dispose();
    });

    testWidgets('a troca automática (sem leitor) nunca anuncia nada', (
      WidgetTester t,
    ) async {
      final List<String> anuncios = <String>[];
      t.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
        SystemChannels.accessibility,
        (dynamic mensagem) async {
          anuncios.add('${(mensagem as Map<dynamic, dynamic>)['type']}');
          return null;
        },
      );
      addTearDown(
        () => t.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<dynamic>(
              SystemChannels.accessibility,
              null,
            ),
      );
      await montar(t);
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(seconds: 21));
      await acomodar(t);
      expect(anuncios.where((String s) => s == 'announce'), isEmpty);
    });
  });

  group('FR-057 e FR-058: parada e barata', () {
    testWidgets('com "reduzir movimento", nenhum Ticker e a Memora parada', (
      WidgetTester t,
    ) async {
      await montar(t, reduzir: true);
      await t.pump(const Duration(seconds: 1));
      expect(
        t.binding.transientCallbackCount,
        0,
        reason:
            'com "reduzir movimento" nenhum Ticker pode estar ativo (FR-057)',
      );
      final ContextoDePintura c = quadro(t);
      expect(c.respira, 0);
      expect(c.flutua, 0);
      expect(c.fala, 0);
      expect(c.giro, 0);
      // O texto aparece inteiro, de uma vez.
      expect(textoDaDica(dicas[0]), findsOneWidget);
      // E a pose é a de repouso.
      expect(c.pose.bocaAbertura, 0);
    });

    testWidgets('controle: sem a preferência há relógios rodando', (
      WidgetTester t,
    ) async {
      await montar(t);
      await t.pump(const Duration(seconds: 1));
      expect(t.binding.transientCallbackCount, greaterThan(0));
    });

    testWidgets('com leitor de tela e sem reduzir, o relógio da dica não roda', (
      WidgetTester t,
    ) async {
      // A Memora anima (ela é decorativa), mas o intervalo das dicas não conta.
      await montar(t, leitor: true);
      await t.pump(const Duration(seconds: 5));
      // Se o relógio da dica estivesse ligado, depois de 60 s ele teria
      // trocado; o teste de FR-053 já prova isso. Aqui só se garante que o
      // componente continua montado e sem erro.
      expect(t.takeException(), isNull);
      expect(find.byType(MemoraAnfitria), findsOneWidget);
    });

    testWidgets('fora da tela, o intervalo das dicas não corre', (
      WidgetTester t,
    ) async {
      // Uma rota por cima (TickerMode desligado na de baixo): o tempo em que
      // ela ficou escondida não é tempo de leitura.
      final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          theme: TemasMemora.claro,
          home: Scaffold(
            body: SingleChildScrollView(child: MemoraAnfitria(dicas: dicas)),
          ),
        ),
      );
      await t.pump(const Duration(seconds: 3));
      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (BuildContext _) => const Scaffold(body: SizedBox()),
        ),
      );
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      // 60 s escondida.
      for (int i = 0; i < 3; i++) {
        await t.pump(const Duration(seconds: 20));
      }
      nav.currentState!.pop();
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      await acomodar(t);
      expect(
        textoDaDica(dicas[0]),
        findsOneWidget,
        reason: 'escondida, a anfitria nao conta o tempo (FR-058)',
      );
    });
  });
}

class _ContaRotas extends NavigatorObserver {
  int empilhadas = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    empilhadas++;
  }
}
