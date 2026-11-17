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
import '../../suporte/movimento.dart';

/// A abertura com a anfitriã segurando a barra de carregamento (feature 013,
/// US7, T035 e T092; FR-036 a FR-039, FR-048, SC-009).
///
/// ## O que mais importa aqui
///
/// A abertura **não prolonga o carregamento de propósito** (FR-038): sai
/// quando o carregamento terminou **e** a passada da barra em curso
/// completou. As duas pontas se provam: "nunca antes de carregar" (o portão:
/// sair antes é entregar ao aplicativo um resultado que não existe) e "nunca
/// mais que uma passada depois".
///
/// ## O relógio
///
/// Dentro de `testWidgets` o relógio é falso: o tempo só anda com `pump`. Uma
/// passada dura `MemoraAbertura.passadaDaBarra` (1,5 s), e a seguinte emenda
/// nela, sem pausa.
void main() {
  // A barra correndo é o que este arquivo prova: liga o movimento que o
  // flutter_test_config.dart desliga por padrão. Os testes de "reduzir
  // movimento" ligam a preferência do sistema eles mesmos.
  movimentoLiberado();

  const Duration passada = MemoraAbertura.passadaDaBarra;

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

  group('T092: a anfitriã segurando a barra de carregamento', () {
    testWidgets('é a anfitriã (o desenho de mais detalhe), com a barra entre '
        'as mãos, e uma Memora só', (WidgetTester t) async {
      final Completer<int> carga = Completer<int>();
      await montar(t, carregar: () => carga.future, aoConcluir: (int _) {});
      await t.pump();
      expect(memora, findsOneWidget, reason: 'uma Memora só na tela (FR-006)');
      final MemoraAnimada m = t.widget<MemoraAnimada>(memora);
      expect(m.anfitria, isTrue, reason: 'o desenho da anfitriã (FR-048)');
      expect(m.expressao, PoseDaMemora.carregando);
      expect(m.reageAoToque, isFalse);
      final ContextoDePintura q = quadro(t);
      expect(q.detalhada, isTrue);
      expect(q.pose.barra, 1, reason: 'a barra está nas mãos');
    });

    testWidgets('a barra corre sem parar enquanto carrega, uma passada atrás '
        'da outra, e ela não larga a barra para acenar', (
      WidgetTester t,
    ) async {
      final Completer<int> carga = Completer<int>();
      await montar(t, carregar: () => carga.future, aoConcluir: (int _) {});
      await t.pump();

      double menor = 1;
      double maior = 0;
      int voltas = 0;
      double anterior = quadro(t).cicloDaBarra!;
      // Três passadas inteiras.
      for (int ms = 0; ms < 3 * passada.inMilliseconds; ms += 50) {
        await t.pump(const Duration(milliseconds: 50));
        final ContextoDePintura q = quadro(t);
        final double c = q.cicloDaBarra!;
        if (c < menor) menor = c;
        if (c > maior) maior = c;
        if (c < anterior) voltas++;
        anterior = c;
        expect(q.aceno, 0, reason: 'as mãos estão na barra');
        expect(q.pose.barra, 1);
      }
      expect(menor, lessThan(0.05), reason: 'o trecho entra pela esquerda');
      expect(maior, greaterThan(0.95), reason: 'e sai pela direita');
      expect(
        voltas,
        inInclusiveRange(2, 3),
        reason: 'no mesmo ritmo, sem acelerar: uma passada a cada 1,5 s',
      );
    });

    testWidgets('nada de número nem de porcentagem na tela', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      final Completer<int> carga = Completer<int>();
      await montar(t, carregar: () => carga.future, aoConcluir: (int _) {});
      await t.pump(const Duration(seconds: 5));
      expect(find.textContaining(RegExp(r'[0-9%]')), findsNothing);
      expect(find.bySemanticsLabel(RegExp(r'[0-9%]')), findsNothing);
      h.dispose();
    });
  });

  group('V12: a abertura sai só quando carregou e a passada completou', () {
    testWidgets('carregamento rápido: sai depois de uma passada completa, '
        'nunca antes', (WidgetTester t) async {
      int? saiu;
      await montar(t, carregar: () async => 7, aoConcluir: (int r) => saiu = r);
      // O carregamento já terminou no primeiro quadro; a barra mal começou.
      await t.pump();
      expect(saiu, isNull, reason: 'carregou, mas a passada mal começou');
      expect(memora, findsOneWidget);

      const Duration jaPassado = Duration(milliseconds: 1300);
      await t.pump(jaPassado);
      expect(saiu, isNull, reason: 'a passada ainda não completou');

      final Duration depois = await esperarAte(
        t,
        () => saiu != null,
        passo: const Duration(milliseconds: 16),
      );
      expect(saiu, 7, reason: 'entrega o resultado do carregamento');
      final Duration total = jaPassado + depois;
      expect(
        total,
        greaterThanOrEqualTo(passada),
        reason: 'nunca antes de a passada completar',
      );
      // Uma passada completa e o esmaecer: ~1,7 s no total (SC-009).
      expect(
        total,
        lessThanOrEqualTo(
          passada + MemoraMovimento.padrao + const Duration(milliseconds: 100),
        ),
        reason: 'a abertura não pode prolongar além de uma passada',
      );
    });

    testWidgets('carregamento lento: não sai antes de terminar, e sai no fim '
        'da passada em curso', (WidgetTester t) async {
      final Completer<int> carga = Completer<int>();
      int? saiu;
      await montar(
        t,
        carregar: () => carga.future,
        aoConcluir: (int r) => saiu = r,
      );
      await t.pump();

      // Passam várias passadas completas e o carregamento segue de pé: a
      // abertura espera, não sai por conta própria. (É o portão: sair antes
      // do carregamento terminar entregaria um resultado que não existe.)
      await t.pump(const Duration(seconds: 3));
      await t.pump(const Duration(seconds: 3));
      expect(saiu, isNull);
      expect(memora, findsOneWidget);

      // A 5ª passada começou aos 6 s e acaba aos 7,5 s: aos 6,7 s faltam
      // 0,8 s dela.
      await t.pump(const Duration(milliseconds: 700));
      carga.complete(9);
      await t.pump();
      final Duration depois = await esperarAte(
        t,
        () => saiu != null,
        passo: const Duration(milliseconds: 16),
      );
      expect(saiu, 9);
      expect(
        depois,
        greaterThanOrEqualTo(const Duration(milliseconds: 700)),
        reason: 'espera o resto da passada',
      );
      expect(
        depois,
        lessThanOrEqualTo(
          const Duration(milliseconds: 800) +
              MemoraMovimento.padrao +
              const Duration(milliseconds: 100),
        ),
        reason: 'o resto da passada e o esmaecer, e nada mais',
      );
    });

    testWidgets('carregamento que termina no meio de uma passada espera a '
        'passada acabar', (WidgetTester t) async {
      final Completer<int> carga = Completer<int>();
      int? saiu;
      await montar(
        t,
        carregar: () => carga.future,
        aoConcluir: (int r) => saiu = r,
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 500)); // 1/3 da 1ª passada
      carga.complete(1);
      await t.pump();
      expect(saiu, isNull);
      await t.pump(const Duration(milliseconds: 800));
      expect(saiu, isNull, reason: 'a passada só completa aos 1500 ms');
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
      // Parada, segurando a barra: a barra não corre, e nem aceno, nem
      // respiração, nem piscada, nem flutuação.
      final ContextoDePintura q = quadro(t);
      expect(q.pose.barra, 1, reason: 'a barra continua nas mãos');
      expect(q.cicloDaBarra, isNull, reason: 'a barra parada');
      expect(q.detalhada, isTrue, reason: 'a anfitriã, mesmo parada');
      expect(q.aceno, 0);
      expect(q.respira, 0);
      expect(q.piscar, 0);
      expect(q.flutua, 0);
    });

    testWidgets('sai assim que carrega, sem passada nenhuma para esperar', (
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
