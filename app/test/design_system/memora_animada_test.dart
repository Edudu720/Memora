import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/componentes/ilustracao/memora_animada/pintores/contexto_de_pintura.dart';
import 'package:memora/design_system/componentes/ilustracao/memora_animada/pintores/pintor_da_memora.dart';
import 'package:memora/design_system/design_system.dart';

/// A `MemoraAnimada` (feature 010, V1 a V4): monta, é decorativa, respeita
/// "reduzir movimento" e reage ao toque do jeito certo.
///
/// ## Como se observa um gesto
///
/// O relógio de teste não deixa olhar o `AnimationController` por dentro, e
/// expor o estado só para testar sujaria a API. O que dá para ler é o que
/// vai para o pincel: cada quadro entrega ao pintor um [ContextoDePintura], e
/// nele `aceno` e `piscar` são zero em repouso e diferentes de zero durante o
/// gesto. É o mesmo número que a pessoa vê.
void main() {
  final Finder memora = find.byType(MemoraAnimada);

  Future<void> montar(
    WidgetTester t,
    PoseDaMemora pose, {
    MemoraTemaId tema = MemoraTemaId.claro,
    double tamanho = 96,
    bool reduzir = false,
    GestoDaMemora? gesto,
    bool reageAoToque = true,
    NavigatorObserver? observador,
    bool falando = false,
  }) async {
    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.porId(tema),
        navigatorObservers: <NavigatorObserver>[?observador],
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduzir),
          child: Scaffold(
            body: Center(
              child: MemoraAnimada(
                expressao: pose,
                tamanho: tamanho,
                gesto: gesto,
                reageAoToque: reageAoToque,
                falando: falando,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Toca na Memora e dá o quadro zero, em que o relógio do gesto começa a
  /// contar (um `Ticker` só conta a partir do primeiro quadro depois de criado).
  Future<void> tocar(WidgetTester t) async {
    await t.tap(memora);
    await t.pump();
  }

  /// O que a Memora está pintando agora.
  ContextoDePintura quadro(WidgetTester t, [double lado = 96]) {
    final CustomPaint pintura = t.widget<CustomPaint>(
      find.descendant(of: memora, matching: find.byType(CustomPaint)),
    );
    return (pintura.painter! as PintorDaMemora).criarContexto(lado);
  }

  group('V1: monta em todo tema e tamanho', () {
    for (final MemoraTemaId tema in MemoraTemaId.values) {
      for (final double tamanho in <double>[32, 96, 240]) {
        testWidgets('toda pose, tema ${tema.name}, ${tamanho.toInt()} dp',
            (WidgetTester t) async {
          for (final PoseDaMemora pose in PoseDaMemora.values) {
            await montar(t, pose, tema: tema, tamanho: tamanho);
            await t.pump(const Duration(milliseconds: 120));
            expect(t.takeException(), isNull, reason: pose.name);
            expect(memora, findsOneWidget);
            expect(t.getSize(memora), Size.square(tamanho));
          }
        });
      }
    }

    testWidgets('trocar de pose interpola até a nova e não quebra',
        (WidgetTester t) async {
      await montar(t, PoseDaMemora.neutra);
      expect(quadro(t).pose.escudo, 0);
      await montar(t, PoseDaMemora.preocupada);
      await t.pump();
      // No meio da troca o escudo está entre as duas poses...
      await t.pump(const Duration(milliseconds: 150));
      final double meio = quadro(t).pose.escudo;
      expect(meio, inExclusiveRange(0.01, 0.99));
      // ...e no fim está inteiro.
      await t.pump(const Duration(milliseconds: 600));
      expect(quadro(t).pose.escudo, closeTo(1, 0.001));
    });
  });

  group('V3: decorativa para o leitor de tela', () {
    /// Todos os nós da árvore de semântica com ação de toque.
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

    testWidgets('não aparece na semântica, nem depois de tocar',
        (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      await montar(t, PoseDaMemora.neutra);
      await t.pump();

      expect(comToque(t), isEmpty,
          reason: 'a Memora responde ao toque, mas o leitor de tela nao pode '
              've-la como botao (FR-005b)');

      await tocar(t);
      await t.pump(const Duration(milliseconds: 100));
      expect(comToque(t), isEmpty);
      // E a Memora também não tem rótulo nem imagem para anunciar.
      expect(find.bySemanticsLabel(RegExp('.+')), findsNothing);
      await t.pump(const Duration(seconds: 2));
      h.dispose();
    });
  });

  group('V2: reduzir movimento', () {
    testWidgets('sem relógio rodando e com o toque sem efeito',
        (WidgetTester t) async {
      await montar(t, PoseDaMemora.acenando, reduzir: true, falando: true);
      await t.pump(const Duration(milliseconds: 100));

      expect(t.binding.transientCallbackCount, 0,
          reason: 'com "reduzir movimento" nenhum Ticker pode estar ativo '
              '(FR-004)');

      await tocar(t);
      await t.pump(const Duration(milliseconds: 100));
      expect(t.binding.transientCallbackCount, 0,
          reason: 'o toque nao gera gesto (FR-005d)');
      final ContextoDePintura c = quadro(t);
      expect(c.aceno, 0);
      expect(c.piscar, 0);
      expect(c.fala, 0, reason: 'a fala nao mexe a boca com movimento reduzido');
      expect(c.respira, 0);
    });

    testWidgets('a pose parada é a pose da expressão (nada some)',
        (WidgetTester t) async {
      await montar(t, PoseDaMemora.preocupada, reduzir: true);
      await t.pump();
      expect(quadro(t).pose.escudo, 1);
      expect(quadro(t).pose.sobrancelha, 1);
    });

    testWidgets('controle: sem a preferência, há relógio e o toque anima',
        (WidgetTester t) async {
      // Sem este caso, um teste que olha "nenhum Ticker" passaria com o
      // componente quebrado e parado.
      await montar(t, PoseDaMemora.neutra);
      await t.pump(const Duration(milliseconds: 100));
      expect(t.binding.transientCallbackCount, greaterThan(0));
      await tocar(t);
      await t.pump(const Duration(milliseconds: 100));
      expect(quadro(t).aceno.abs(), greaterThan(0.1));
    });
  });

  group('V4: o toque', () {
    testWidgets('alterna aceno e piscada; nada navega',
        (WidgetTester t) async {
      final _ContaRotas rotas = _ContaRotas();
      await montar(t, PoseDaMemora.neutra, observador: rotas);
      await t.pump(const Duration(milliseconds: 50));
      final int rotasAntes = rotas.empilhadas;

      // 1º toque: aceno.
      await tocar(t);
      await t.pump(const Duration(milliseconds: 100));
      expect(quadro(t).aceno.abs(), greaterThan(0.1));
      expect(quadro(t).piscar, 0);
      await t.pump(const Duration(milliseconds: 1300));
      expect(quadro(t).aceno, 0, reason: 'o gesto acabou e voltou ao repouso');

      // 2º toque: piscada.
      await tocar(t);
      await t.pump(const Duration(milliseconds: 100));
      expect(quadro(t).piscar, greaterThan(0.3));
      expect(quadro(t).aceno, 0);
      await t.pump(const Duration(milliseconds: 400));
      expect(quadro(t).piscar, 0);

      // 3º toque: volta ao aceno.
      await tocar(t);
      await t.pump(const Duration(milliseconds: 100));
      expect(quadro(t).aceno.abs(), greaterThan(0.1));
      await t.pump(const Duration(milliseconds: 1300));

      expect(rotas.empilhadas, rotasAntes,
          reason: 'tocar na Memora nao abre nada (FR-005a)');
    });

    testWidgets('toque durante um gesto é ignorado e não acumula',
        (WidgetTester t) async {
      await montar(t, PoseDaMemora.neutra);
      await t.pump(const Duration(milliseconds: 50));

      await tocar(t); // aceno: 1200 ms
      await t.pump(const Duration(milliseconds: 600));
      await tocar(t); // no meio do aceno: tem de ser ignorado
      await tocar(t);
      // O aceno original termina em 1200 ms. Se o toque tivesse reiniciado ou
      // empilhado um gesto, ainda haveria movimento aqui.
      await t.pump(const Duration(milliseconds: 700));

      final ContextoDePintura c = quadro(t);
      expect(c.aceno, 0, reason: 'o gesto de verdade terminou');
      expect(c.piscar, 0, reason: 'nenhuma piscada ficou na fila');
    });

    testWidgets('reageAoToque falso: tocar não faz nada',
        (WidgetTester t) async {
      await montar(t, PoseDaMemora.neutra, reageAoToque: false);
      await t.pump(const Duration(milliseconds: 50));
      await tocar(t);
      await t.pump(const Duration(milliseconds: 100));
      expect(quadro(t).aceno, 0);
      expect(quadro(t).piscar, 0);
    });

    testWidgets('o gesto comemoração dispara por fora, uma vez',
        (WidgetTester t) async {
      await montar(t, PoseDaMemora.neutra);
      await t.pump(const Duration(milliseconds: 50));
      await montar(t, PoseDaMemora.neutra, gesto: GestoDaMemora.comemoracao);
      await t.pump(const Duration(milliseconds: 500));
      final ContextoDePintura meio = quadro(t);
      expect(meio.pulo, greaterThan(0.5));
      expect(meio.pose.olhoFeliz, greaterThan(0.5),
          reason: 'comemorar vira a pose comemorando');
      await t.pump(const Duration(milliseconds: 800));
      expect(quadro(t).pulo, 0);
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
