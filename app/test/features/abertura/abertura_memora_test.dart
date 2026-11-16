import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/componentes/ilustracao/memora_animada/pintores/contexto_de_pintura.dart';
import 'package:memora/design_system/componentes/ilustracao/memora_animada/pintores/pintor_da_memora.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/design_system/tokens/abertura.dart';
import 'package:memora/features/abertura/presentation/abertura_memora.dart';
import 'package:memora/l10n/textos_abertura.dart';

import '../../suporte/aparelhos.dart';

/// A abertura com a Memora acenando (feature 013, US7, T035; FR-036 a FR-039,
/// SC-009).
///
/// ## O que mais importa aqui
///
/// A abertura **não prolonga o carregamento de propósito** (FR-038): sai
/// quando o carregamento terminou **e** o aceno em curso completou. As duas
/// pontas se provam: "nunca antes de carregar" (o portão: sair antes é
/// entregar ao aplicativo um resultado que não existe) e "nunca mais que um
/// aceno depois".
///
/// ## O relógio
///
/// Dentro de `testWidgets` o relógio é falso: o tempo só anda com `pump`. O
/// aceno dura `MemoraMovimento.aceno` (1,2 s), e depois dele há uma pausa de
/// `MemoraAbertura.pausaEntreAcenos` antes do aceno seguinte.
void main() {
  /// Monta só a abertura, sob um tema e um "reduzir movimento" do **sistema**
  /// (ainda não há preferência do aplicativo nessa hora).
  Future<void> montar(
    WidgetTester t, {
    required Future<int> Function() carregar,
    required void Function(int) aoConcluir,
    void Function(Object)? aoFalhar,
    bool reduzir = false,
    MemoraTemaId tema = MemoraTemaId.claro,
    double escala = 1.0,
  }) async {
    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.porId(tema),
        builder: (BuildContext context, Widget? filho) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduzir,
            textScaler: TextScaler.linear(escala),
          ),
          child: filho!,
        ),
        home: AberturaMemora<int>(
          carregar: carregar,
          aoConcluir: aoConcluir,
          aoFalhar: aoFalhar,
        ),
      ),
    );
  }

  /// Anda o relógio de [passo] em [passo] até [condicao] ser verdadeira, e
  /// devolve quanto tempo passou. Reprova se passar de [ate].
  Future<Duration> esperarAte(
    WidgetTester t,
    bool Function() condicao, {
    Duration passo = const Duration(milliseconds: 50),
    Duration ate = const Duration(seconds: 12),
  }) async {
    Duration passado = Duration.zero;
    while (!condicao()) {
      if (passado > ate) fail('não aconteceu em ${ate.inMilliseconds} ms');
      await t.pump(passo);
      passado += passo;
    }
    return passado;
  }

  final Finder memora = find.byType(MemoraAnimada);

  /// O que a Memora está pintando agora (o mesmo número que a pessoa vê).
  ContextoDePintura quadro(WidgetTester t) {
    final CustomPaint pintura = t.widget<CustomPaint>(
      find.descendant(of: memora, matching: find.byType(CustomPaint)),
    );
    return (pintura.painter! as PintorDaMemora).criarContexto(
      MemoraAbertura.tamanhoDaMemora,
    );
  }

  final Finder frase = find.text(TextosAbertura.quasePronta);

  group('V12: a abertura sai só quando carregou e o aceno completou', () {
    testWidgets('carregamento rápido: sai depois de um aceno completo, '
        'nunca antes', (WidgetTester t) async {
      int? saiu;
      await montar(t, carregar: () async => 7, aoConcluir: (int r) => saiu = r);
      // O carregamento já terminou no primeiro quadro; a Memora ainda acena.
      await t.pump();
      expect(saiu, isNull, reason: 'carregou, mas o aceno mal começou');
      expect(memora, findsOneWidget);

      const Duration jaPassado = Duration(milliseconds: 1000);
      await t.pump(jaPassado);
      expect(saiu, isNull, reason: 'o aceno ainda não completou');

      final Duration depois = await esperarAte(
        t,
        () => saiu != null,
        passo: const Duration(milliseconds: 16),
      );
      expect(saiu, 7, reason: 'entrega o resultado do carregamento');
      final Duration total = jaPassado + depois;
      expect(
        total,
        greaterThanOrEqualTo(MemoraMovimento.aceno),
        reason: 'nunca antes de o aceno completar',
      );
      // Um aceno completo e o esmaecer: ~1,5 s no total (SC-009).
      expect(
        total,
        lessThanOrEqualTo(const Duration(milliseconds: 1600)),
        reason: 'a abertura não pode prolongar além de um aceno',
      );
    });

    testWidgets('carregamento lento: não sai antes de terminar, e sai assim '
        'que termina', (WidgetTester t) async {
      final Completer<int> carga = Completer<int>();
      int? saiu;
      await montar(
        t,
        carregar: () => carga.future,
        aoConcluir: (int r) => saiu = r,
      );
      await t.pump();

      // Passam vários acenos completos e o carregamento segue de pé: a
      // abertura espera, não sai por conta própria. (É o portão: sair antes
      // do carregamento terminar entregaria um resultado que não existe.)
      await t.pump(const Duration(seconds: 3));
      await t.pump(const Duration(seconds: 3));
      expect(saiu, isNull);
      expect(memora, findsOneWidget);

      // O 3º aceno começou aos 6 s e acabou aos 7,2 s: aos 7,4 s a Memora
      // está no descanso entre dois acenos, sem aceno nenhum a esperar.
      await t.pump(const Duration(milliseconds: 1400));
      carga.complete(9);
      await t.pump();
      final Duration depois = await esperarAte(t, () => saiu != null);
      expect(saiu, 9);
      expect(
        depois,
        lessThanOrEqualTo(
          MemoraMovimento.padrao + const Duration(milliseconds: 100),
        ),
        reason:
            'no descanso entre acenos não há aceno a esperar: só o esmaecer',
      );
    });

    testWidgets('enquanto demora, a Memora volta a acenar, com descanso entre '
        'um aceno e outro', (WidgetTester t) async {
      final Completer<int> carga = Completer<int>();
      await montar(t, carregar: () => carga.future, aoConcluir: (int _) {});
      await t.pump();

      /// Se ela acena (a mão se mexe) em algum quadro do trecho.
      Future<bool> acenaEntre(int deMs, int ateMs, int agoraMs) async {
        bool acenou = false;
        for (int ms = agoraMs; ms < ateMs; ms += 40) {
          await t.pump(const Duration(milliseconds: 40));
          if (ms >= deMs && quadro(t).aceno.abs() > 0.01) acenou = true;
        }
        return acenou;
      }

      expect(await acenaEntre(100, 1200, 0), isTrue, reason: '1º aceno');
      expect(
        await acenaEntre(1400, 1900, 1200),
        isFalse,
        reason: 'descanso: calma, sem acelerar',
      );
      expect(await acenaEntre(2100, 3100, 1900), isTrue, reason: '2º aceno');
    });

    testWidgets('carregamento que termina no meio de um aceno espera o aceno '
        'acabar', (WidgetTester t) async {
      final Completer<int> carga = Completer<int>();
      int? saiu;
      await montar(
        t,
        carregar: () => carga.future,
        aoConcluir: (int r) => saiu = r,
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 500)); // meio do 1º aceno
      carga.complete(1);
      await t.pump();
      expect(saiu, isNull);
      await t.pump(const Duration(milliseconds: 500));
      expect(saiu, isNull, reason: 'o aceno só completa aos 1200 ms');
      await esperarAte(t, () => saiu != null);
      expect(saiu, 1);
    });

    testWidgets('sai uma vez só', (WidgetTester t) async {
      int saidas = 0;
      await montar(t, carregar: () async => 1, aoConcluir: (int _) => saidas++);
      await esperarAte(t, () => saidas > 0);
      await t.pump(const Duration(seconds: 5));
      expect(saidas, 1);
    });
  });

  group('FR-038: a frase de "quase pronta" aos 4 segundos', () {
    testWidgets('aparece quando passa de 4 s sem terminar, e não antes', (
      WidgetTester t,
    ) async {
      final Completer<int> carga = Completer<int>();
      await montar(t, carregar: () => carga.future, aoConcluir: (int _) {});
      await t.pump();
      await t.pump(const Duration(milliseconds: 3900));
      expect(frase, findsNothing, reason: 'ainda não deu 4 s');
      await t.pump(const Duration(milliseconds: 200));
      expect(frase, findsOneWidget);
      // E a Memora não saiu do lugar com a chegada da frase.
      expect(memora, findsOneWidget);
    });

    testWidgets('não aparece quando termina antes dos 4 s', (
      WidgetTester t,
    ) async {
      await montar(t, carregar: () async => 1, aoConcluir: (int _) {});
      await t.pump(const Duration(seconds: 6));
      expect(frase, findsNothing);
    });

    testWidgets('a Memora fica no mesmo lugar antes e depois da frase', (
      WidgetTester t,
    ) async {
      final Completer<int> carga = Completer<int>();
      await montar(t, carregar: () => carga.future, aoConcluir: (int _) {});
      await t.pump();
      final Offset antes = t.getCenter(memora);
      await t.pump(const Duration(seconds: 5));
      expect(frase, findsOneWidget);
      expect(t.getCenter(memora), antes);
      // E é o centro da tela, onde a abertura nativa a deixou (FR-037).
      final Size tela = t.view.physicalSize / t.view.devicePixelRatio;
      expect(antes.dx, closeTo(tela.width / 2, 0.5));
      expect(antes.dy, closeTo(tela.height / 2, 0.5));
    });
  });

  group('Falha ao carregar: não prende a pessoa', () {
    testWidgets('vai à tela de erro com a Memora e deixa tentar de novo', (
      WidgetTester t,
    ) async {
      int chamadas = 0;
      final List<Object> falhas = <Object>[];
      int? saiu;
      await montar(
        t,
        carregar: () async {
          chamadas++;
          if (chamadas == 1) throw StateError('disco cheio');
          return 5;
        },
        aoConcluir: (int r) => saiu = r,
        aoFalhar: falhas.add,
      );
      await t.pump();
      await t.pump();

      expect(falhas, hasLength(1));
      expect(falhas.single, isA<StateError>());
      expect(find.text(TextosAbertura.falhou), findsOneWidget);
      expect(memora, findsOneWidget, reason: 'a tela de erro tem a Memora');
      expect(
        find.textContaining('disco cheio'),
        findsNothing,
        reason: 'nada técnico na tela',
      );
      // Mesmo passado muito tempo, não sai sozinha para o aplicativo.
      await t.pump(const Duration(seconds: 10));
      expect(saiu, isNull);

      await t.tap(find.text(TextosAbertura.tentarDeNovo));
      await t.pump();
      expect(chamadas, 2);
      await t.pump(const Duration(milliseconds: 100));
      await esperarAte(t, () => saiu != null);
      expect(saiu, 5);
      expect(find.text(TextosAbertura.falhou), findsNothing);
    });

    testWidgets('a falha que chega durante a espera de 4 s também leva ao '
        'erro, e a frase some', (WidgetTester t) async {
      final Completer<int> carga = Completer<int>();
      await montar(t, carregar: () => carga.future, aoConcluir: (int _) {});
      await t.pump(const Duration(seconds: 5));
      expect(frase, findsOneWidget);
      carga.completeError(Exception('rede'));
      await t.pump();
      expect(frase, findsNothing);
      expect(find.text(TextosAbertura.falhou), findsOneWidget);
    });

    testWidgets('a tela de erro cabe nos aparelhos baixos a 200%', (
      WidgetTester t,
    ) async {
      for (final Size aparelho in aparelhos) {
        vestir(t, aparelho);
        await montar(
          t,
          carregar: () async => throw StateError('x'),
          aoConcluir: (int _) {},
          escala: 2.0,
        );
        await t.pump();
        await t.pump();
        expect(t.takeException(), isNull, reason: nomeDo(aparelho));
        await exigirAlcancavel(
          t,
          find.text(TextosAbertura.tentarDeNovo),
          aparelho: aparelho,
          contexto: 'tentar de novo em ${nomeDo(aparelho)} a 200%',
        );
      }
    });
  });

  group('FR-039: com "reduzir movimento" do sistema', () {
    testWidgets('a Memora fica parada, sem nenhum quadro agendado', (
      WidgetTester t,
    ) async {
      final Completer<int> carga = Completer<int>();
      await montar(
        t,
        carregar: () => carga.future,
        aoConcluir: (int _) {},
        reduzir: true,
      );
      await t.pump();
      await t.pump(const Duration(seconds: 2));

      expect(memora, findsOneWidget);
      expect(
        t.binding.transientCallbackCount,
        0,
        reason: 'nenhum Ticker rodando: nem o da abertura, nem o da Memora',
      );
      // Parada, em pose de aceno: nem aceno, nem respiração, nem piscada.
      final ContextoDePintura q = quadro(t);
      expect(q.aceno, 0);
      expect(q.respira, 0);
      expect(q.piscar, 0);
    });

    testWidgets('sai assim que carrega, sem aceno nenhum para esperar', (
      WidgetTester t,
    ) async {
      int? saiu;
      await montar(
        t,
        carregar: () async => 3,
        aoConcluir: (int r) => saiu = r,
        reduzir: true,
      );
      await t.pump();
      await t.pump();
      expect(saiu, 3);
    });

    testWidgets('a frase de 4 s aparece do mesmo jeito', (
      WidgetTester t,
    ) async {
      final Completer<int> carga = Completer<int>();
      await montar(
        t,
        carregar: () => carga.future,
        aoConcluir: (int _) {},
        reduzir: true,
      );
      await t.pump(const Duration(seconds: 4, milliseconds: 100));
      expect(frase, findsOneWidget);
    });
  });

  group('Leitor de tela', () {
    testWidgets('a Memora não aparece, mas a frase sim', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      final Completer<int> carga = Completer<int>();
      await montar(t, carregar: () => carga.future, aoConcluir: (int _) {});
      await t.pump(const Duration(seconds: 5));

      // A Memora é decorativa: tudo dentro dela fica de fora da semântica.
      expect(
        t
            .widget<ExcludeSemantics>(
              find.descendant(
                of: memora,
                matching: find.byType(ExcludeSemantics),
              ),
            )
            .excluding,
        isTrue,
      );
      // A frase é lida, e como aviso: quem não vê a tela fica sabendo.
      expect(find.bySemanticsLabel(TextosAbertura.quasePronta), findsOneWidget);
      final SemanticsNode no = t.getSemantics(
        find.bySemanticsLabel(TextosAbertura.quasePronta),
      );
      expect(no.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      // E há o que dizer antes da frase: que o aplicativo está abrindo.
      expect(find.bySemanticsLabel(TextosAbertura.abrindo), findsOneWidget);
      h.dispose();
    });
  });

  group('Não deixa nada pendente', () {
    testWidgets('sair da árvore antes de carregar cancela tudo e não entrega '
        'resultado depois', (WidgetTester t) async {
      final Completer<int> carga = Completer<int>();
      int saidas = 0;
      await montar(
        t,
        carregar: () => carga.future,
        aoConcluir: (int _) => saidas++,
      );
      await t.pump(const Duration(seconds: 1));
      await t.pumpWidget(const SizedBox.shrink());
      carga.complete(1);
      await t.pump(const Duration(seconds: 10));
      expect(saidas, 0);
      expect(t.takeException(), isNull);
    });
  });

  group('Em todo tema e aparelho', () {
    testWidgets('monta a abertura e a frase sem estourar', (
      WidgetTester t,
    ) async {
      for (final Combinacao c in matriz(
        temas: <MemoraTemaId>[MemoraTemaId.claro, MemoraTemaId.escuro],
      )) {
        vestir(t, c.aparelho);
        final Completer<int> carga = Completer<int>();
        await montar(
          t,
          carregar: () => carga.future,
          aoConcluir: (int _) {},
          tema: c.tema,
          escala: c.escala,
        );
        await t.pump(const Duration(seconds: 5));
        expect(t.takeException(), isNull, reason: nomeDa(c));
        expect(frase, findsOneWidget, reason: nomeDa(c));
        // A frase cabe na janela e fica embaixo da Memora.
        final Rect r = t.getRect(frase);
        expect(
          r.bottom,
          lessThanOrEqualTo(c.aparelho.height),
          reason: nomeDa(c),
        );
        expect(
          r.top,
          greaterThan(t.getRect(memora).bottom - 1),
          reason: nomeDa(c),
        );
        await t.pumpWidget(const SizedBox.shrink());
      }
    });
  });
}
