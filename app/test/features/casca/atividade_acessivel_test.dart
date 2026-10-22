import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_login.dart';
import 'package:memora/features/inicio/presentation/tela_inicio.dart';

import '../autenticacao/fluxo_dentro_da_conta.dart';

/// Testes de atividade acessível (T109 e T110, FR-017).
///
/// - T109: Ações de leitores de tela (TalkBack) e teclado contam como atividade;
/// - T110: Toque dentro de diálogos modais conta como atividade.
void main() {
  group('Atividade acessível — FR-017 da 001 (T109 e T110)', () {
    testWidgets('ação do leitor de tela (TalkBack) conta como atividade (T109)', (
      WidgetTester t,
    ) async {
      final SemanticsHandle handle = t.ensureSemantics();
      final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
      const Duration inatividade = Duration(seconds: 6);
      const Duration aviso = Duration(seconds: 1);

      await fluxo.montar(t, inatividade: inatividade, aviso: aviso);

      expect(find.byKey(TelaInicio.chaveSaudacao), findsOneWidget);

      // Avança 3 segundos
      await t.pump(const Duration(seconds: 3));

      // Simula ação do leitor de tela (TalkBack / VoiceOver)
      final SemanticsNode node = t.getSemantics(find.byKey(TelaInicio.chaveConversar));
      t.platformDispatcher.onSemanticsActionEvent?.call(ui.SemanticsActionEvent(
        type: SemanticsAction.tap,
        nodeId: node.id,
        viewId: t.view.viewId,
      ));
      await FluxoDentroDaConta.avancar(t, 2);

      // Passam mais 3 segundos desde a ação (6s no total desde o início).
      // Se a ação não tivesse contado como atividade, a sessão teria expirado aos 6s.
      await t.pump(const Duration(seconds: 3));
      await FluxoDentroDaConta.avancar(t, 2);

      expect(find.byKey(TelaLogin.chaveEntrar), findsNothing);

      // Agora aguarda o tempo total de inatividade sem nenhuma interação
      await t.pump(inatividade);
      await FluxoDentroDaConta.avancar(t, 6);

      // Sessão expirou
      expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);

      handle.dispose();
    });

    testWidgets('digitação e teclas de teclado contam como atividade (T109)', (
      WidgetTester t,
    ) async {
      final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
      const Duration inatividade = Duration(seconds: 6);
      const Duration aviso = Duration(seconds: 1);

      await fluxo.montar(t, inatividade: inatividade, aviso: aviso);

      // Avança 3 segundos
      await t.pump(const Duration(seconds: 3));

      // Pressiona tecla
      await t.sendKeyEvent(LogicalKeyboardKey.keyA);
      await FluxoDentroDaConta.avancar(t, 2);

      // Passam mais 3 segundos (6s total desde o início; teria expirado se a tecla não contasse)
      await t.pump(const Duration(seconds: 3));
      await FluxoDentroDaConta.avancar(t, 2);

      expect(find.byKey(TelaLogin.chaveEntrar), findsNothing);

      // Aguarda expiração completa
      await t.pump(inatividade);
      await FluxoDentroDaConta.avancar(t, 6);

      expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
    });

    testWidgets('toque dentro de um diálogo modal conta como atividade (T110)', (
      WidgetTester t,
    ) async {
      final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
      const Duration inatividade = Duration(seconds: 6);
      const Duration aviso = Duration(seconds: 1);

      await fluxo.montar(t, inatividade: inatividade, aviso: aviso);

      // Abre um diálogo no Navigator de fora (root navigator)
      showDialog<void>(
        context: t.element(find.byKey(TelaInicio.chaveSaudacao)),
        builder: (BuildContext ctx) => AlertDialog(
          title: const Text('Diálogo de teste'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Ok'),
            ),
          ],
        ),
      );
      await t.pumpAndSettle();

      expect(find.text('Diálogo de teste'), findsOneWidget);

      // Avança 3 segundos com o diálogo aberto
      await t.pump(const Duration(seconds: 3));

      // Toca dentro do diálogo no botão "Ok"
      await FluxoDentroDaConta.tocar(t, find.text('Ok'));
      await t.pumpAndSettle();

      expect(find.text('Diálogo de teste'), findsNothing);

      // Passam mais 3 segundos (6s total desde o início; teria expirado se o toque não contasse)
      await t.pump(const Duration(seconds: 3));
      await FluxoDentroDaConta.avancar(t, 2);

      // Como o toque no diálogo contou atividade, a sessão NÃO caiu
      expect(find.byKey(TelaLogin.chaveEntrar), findsNothing);

      // Aguarda expiração completa
      await t.pump(inatividade);
      await FluxoDentroDaConta.avancar(t, 6);

      expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
    });
  });
}
