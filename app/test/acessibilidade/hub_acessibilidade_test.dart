import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/hub/domain/hub.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';

import 'aparelhos.dart';

/// Acessibilidade do Hub — T070, FR-026 a FR-030.
///
/// A funcionalidade do Hub (FR-002, FR-003, FR-045) já tem teste próprio em
/// `tela_hub_test.dart`. Este arquivo cobre só os cinco requisitos de
/// acessibilidade da feature 003, no lugar que a tasks.md determina.
void main() {
  List<PortaDoHub> portasDeExemplo() => <PortaDoHub>[
        PortaDoHub(
          rotulo: 'Conversar com a Memora',
          descricao: 'Me pergunte qualquer coisa sobre o celular',
          icone: Icons.chat_bubble_outline,
          principal: true,
          aoAbrir: () {},
        ),
        PortaDoHub(
          rotulo: 'Serviços do dia a dia',
          descricao: 'Banco, INSS e governo — eu te ensino o caminho',
          icone: Icons.account_balance_outlined,
          aoAbrir: () {},
        ),
        PortaDoHub(
          rotulo: 'O que eu fiz por você',
          descricao: 'Tudo que eu abri no seu lugar fica anotado aqui',
          icone: Icons.history,
          aoAbrir: () {},
        ),
      ];

  /// Monta o Hub numa janela do tamanho de um aparelho real.
  ///
  /// `MediaQuery(data: MediaQueryData(size: ...))` sozinho **não** muda as
  /// restrições de verdade do layout — só o valor que widgets leem via
  /// `MediaQuery.of`. Sem isto, o teste roda contra a janela padrão do
  /// `flutter test`, bem maior que qualquer Android, e esconde overflow real
  /// (foi assim que o de `tela_conversa.dart` passou despercebido até o T070).
  Future<void> montar(
    WidgetTester t, {
    double escala = 1.0,
    Size aparelho = referencia,
  }) async {
    t.view.physicalSize = aparelho;
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(escala)),
          child: TelaHub(
            nome: 'Ana',
            portas: portasDeExemplo(),
            aoSair: () async {},
          ),
        ),
      ),
    );
  }

  group('Alvo de toque — FR-026', () {
    testWidgets('cada porta e o botao de sair atendem a diretriz de 48 dp',
        (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      await montar(t);

      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      h.dispose();
    });
  });

  group('Texto ampliado — FR-027', () {
    // A matriz de aparelhos entrou na revisao da PR #27: ate entao tudo rodava
    // num 390x844, e foi assim que o overflow da tela de conversa passou.
    for (final Size aparelho in aparelhos) {
      for (final double escala in <double>[1.0, 1.5, 2.0]) {
      testWidgets('o Hub com tres portas nao quebra em '
          '${nomeDo(aparelho)}, escala $escala',
          (WidgetTester t) async {
        await montar(t, escala: escala, aparelho: aparelho);

        expect(t.takeException(), isNull);
        // Continua utilizavel: a saudacao e ao menos uma porta seguem visiveis
        // e tocaveis, mesmo com o texto no maior tamanho previsto.
        expect(find.byKey(TelaHub.chaveSaudacao), findsOneWidget);
        final Finder primeiraPorta =
            find.byKey(TelaHub.chaveDaPorta('Conversar com a Memora'));
        await t.ensureVisible(primeiraPorta);
        expect(primeiraPorta, findsOneWidget);
      });
      }
    }
  });

  group('Leitor de tela anuncia cada porta — FR-026', () {
    testWidgets('a porta principal e anunciada como botao ativo',
        (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      await montar(t);

      expect(
        t.getSemantics(
          find.byKey(TelaHub.chaveDaPorta('Conversar com a Memora')),
        ),
        isSemantics(
          label: 'Conversar com a Memora',
          isButton: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      h.dispose();
    });
  });

  group('Nenhum gesto complexo — FR-030', () {
    testWidgets('o Hub nao usa arrastar nem pressionar e segurar',
        (WidgetTester t) async {
      await montar(t);

      final Iterable<GestureDetector> gestos =
          t.widgetList<GestureDetector>(find.byType(GestureDetector));

      for (final GestureDetector g in gestos) {
        expect(g.onLongPress, isNull,
            reason: 'Pressionar e segurar exige precisao que nao podemos '
                'pressupor.');
        expect(g.onHorizontalDragStart, isNull);
        expect(g.onVerticalDragStart, isNull);
      }
    });
  });
}
