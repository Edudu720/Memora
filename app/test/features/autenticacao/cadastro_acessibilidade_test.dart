import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/presentation/controladores/controlador_cadastro.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_boas_vindas.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_cadastro.dart';

import '../../suporte/aparelhos.dart';

/// Verificação de acessibilidade das telas da User Story 1.
///
/// Cobre FR-027 a FR-034 e os critérios SC-005 a SC-007. Estas telas são a
/// porta de entrada do produto: se elas falharem, a pessoa nunca chega ao
/// resto do aplicativo.

/// ⚠️ **Este `size:` foi embora, e a razão importa.**
///
/// Ele dizia `size: const Size(390, 844)` e **não fazia nada** para o layout:
/// `MediaQueryData(size:)` muda só o valor que widgets leem via
/// `MediaQuery.of`, nunca as restrições reais. Quem manda é a janela do teste,
/// que por padrão é 800×600 — mais larga que qualquer telefone.
///
/// O teste parecia validar um aparelho e validava uma tela que ninguém tem.
/// Foi o que escondeu um estouro horizontal de `CampoSenha` em **todas** as
/// escalas acima de 1.0, e em 100% num 320×568. Quem muda a janela de verdade
/// é o `setUp` abaixo, e o `t.view.physicalSize` dos testes de ampliação.
Widget _app(Widget filho, {double escala = 1.0, MemoraTemaId? tema}) {
  return MaterialApp(
    theme: TemasMemora.porId(tema ?? MemoraTemaId.claro),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(escala)),
      child: filho,
    ),
  );
}

ControladorCadastro _controlador() =>
    ControladorCadastro(RepositorioAutenticacaoSimulado(demora: Duration.zero));

void main() {
  // A janela do teste passa a ser a de um telefone, para todos os casos deste
  // arquivo. Sem isto, tudo aqui roda em 800x600 — ver a nota do `_app`.
  setUp(() {
    final TestWidgetsFlutterBinding b =
        TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.implicitView!.physicalSize = referencia;
    b.platformDispatcher.implicitView!.devicePixelRatio = 1.0;
  });

  tearDown(() {
    final TestWidgetsFlutterBinding b =
        TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.implicitView!.resetPhysicalSize();
    b.platformDispatcher.implicitView!.resetDevicePixelRatio();
  });

  group('Alvo de toque — FR-027', () {
    testWidgets('boas-vindas atende à diretriz do Android',
        (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      await t.pumpWidget(
        _app(TelaBoasVindas(aoComecar: () {}, aoJaTerConta: () {})),
      );

      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      h.dispose();
    });

    testWidgets('cadastro atende à diretriz do Android',
        (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      await t.pumpWidget(
        _app(TelaCadastro(controlador: _controlador(), aoConcluir: (_) {})),
      );

      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      h.dispose();
    });
  });

  group('Texto ampliado — FR-029 e SC-003', () {
    for (final Size aparelho in aparelhos) {
      for (final double escala in <double>[1.0, 1.5, 2.0]) {
        testWidgets(
            'boas-vindas nao quebra em ${nomeDo(aparelho)}, escala $escala',
            (WidgetTester t) async {
          t.view.physicalSize = aparelho;
          await t.pumpWidget(
            _app(TelaBoasVindas(aoComecar: () {}), escala: escala),
          );
          expect(t.takeException(), isNull);
        });

        testWidgets(
            'cadastro nao quebra em ${nomeDo(aparelho)}, escala $escala',
            (WidgetTester t) async {
          t.view.physicalSize = aparelho;
          await t.pumpWidget(
            _app(
              TelaCadastro(controlador: _controlador(), aoConcluir: (_) {}),
              escala: escala,
            ),
          );
          expect(t.takeException(), isNull);
        });
      }
    }
  });

  group('Leitor de tela — FR-031 e SC-005', () {
    testWidgets('a ação principal anuncia rótulo, papel e ativação',
        (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      await t.pumpWidget(_app(TelaBoasVindas(aoComecar: () {})));

      expect(
        t.getSemantics(find.byType(BotaoPrimario)),
        isSemantics(
          label: 'Começar minha jornada',
          isButton: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      h.dispose();
    });

    testWidgets('cada campo anuncia rótulo e a explicação de uso',
        (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      await t.pumpWidget(
        _app(TelaCadastro(controlador: _controlador(), aoConcluir: (_) {})),
      );

      final Semantics campo = t
          .widgetList<Semantics>(
            find.descendant(
              of: find.byKey(TelaCadastro.chaveNome),
              matching: find.byType(Semantics),
            ),
          )
          .firstWhere((Semantics s) => s.properties.textField ?? false);

      expect(campo.properties.label, 'Como posso te chamar?');
      expect(
        campo.properties.hint,
        'É assim que eu vou falar com você',
        reason: 'Sem a explicação no hint, quem usa leitor de tela não '
            'descobre para que serve o dado (FR-004).',
      );
      h.dispose();
    });

    testWidgets('o botão de enviar começa desabilitado e é anunciado assim',
        (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      await t.pumpWidget(
        _app(TelaCadastro(controlador: _controlador(), aoConcluir: (_) {})),
      );

      expect(
        t.getSemantics(find.byKey(TelaCadastro.chaveEnviar)),
        isSemantics(isButton: true, isEnabled: false, hasTapAction: false),
        reason: 'Anunciar como ativo algo que não faz nada frustra quem não '
            'vê o estado visual.',
      );
      h.dispose();
    });
  });

  group('Funciona nos três temas — FR-004 do Design System', () {
    for (final MemoraTemaId tema in MemoraTemaId.values) {
      testWidgets('cadastro renderiza no tema ${tema.name}',
          (WidgetTester t) async {
        await t.pumpWidget(
          _app(
            TelaCadastro(controlador: _controlador(), aoConcluir: (_) {}),
            tema: tema,
          ),
        );
        expect(t.takeException(), isNull);
      });
    }
  });

  group('Nenhum gesto complexo — FR-034', () {
    testWidgets('a tela não usa arrastar nem pressionar e segurar',
        (WidgetTester t) async {
      await t.pumpWidget(
        _app(TelaCadastro(controlador: _controlador(), aoConcluir: (_) {})),
      );

      final Iterable<GestureDetector> gestos =
          t.widgetList<GestureDetector>(find.byType(GestureDetector));

      for (final GestureDetector g in gestos) {
        expect(g.onLongPress, isNull,
            reason: 'Pressionar e segurar exige precisão que não podemos '
                'pressupor.');
        expect(g.onHorizontalDragStart, isNull);
        expect(g.onVerticalDragStart, isNull);
      }
    });
  });
}
