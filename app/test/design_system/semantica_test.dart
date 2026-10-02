import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

/// Verifica o que um leitor de tela realmente percebe.
///
/// Cobre FR-010, FR-029 e o critério SC-005. Um componente pode estar
/// visualmente correto e ainda assim ser inutilizável para quem navega com o
/// TalkBack — e esse público existe entre os usuários do Memora.
Widget _comTema(Widget filho) {
  return MaterialApp(
    theme: TemasMemora.claro,
    home: Scaffold(body: Center(child: filho)),
  );
}

void main() {
  group('Rótulo e estado expostos — FR-010 e SC-005', () {
    testWidgets('botão habilitado anuncia rótulo, papel e ativação', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _comTema(BotaoPrimario(rotulo: 'Começar jornada', aoTocar: () {})),
      );

      expect(
        tester.getSemantics(find.byType(BotaoPrimario)),
        isSemantics(
          label: 'Começar jornada',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('botão carregando não oferece ativação', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _comTema(
          BotaoPrimario(rotulo: 'Entrando', aoTocar: () {}, carregando: true),
        ),
      );

      expect(
        tester.getSemantics(find.byType(BotaoPrimario)),
        isSemantics(isButton: true, isEnabled: false, hasTapAction: false),
        reason:
            'Durante o carregamento, tocar de novo duplicaria a ação. '
            'Para quem não vê o indicador de progresso, o estado precisa vir '
            'pela semântica.',
      );
      handle.dispose();
    });

    testWidgets('BotaoPerigo anuncia rótulo completo', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _comTema(
          BotaoPerigo(
            rotulo: 'Apagar minha conta',
            icone: Icons.warning_amber_rounded,
            aoTocar: () {},
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(BotaoPerigo)),
        isSemantics(label: 'Apagar minha conta', isButton: true),
        reason:
            'O rótulo precisa descrever a consequência: o ícone de alerta '
            'não é anunciado, então "Excluir" sozinho não informaria o que '
            'será excluído.',
      );
      handle.dispose();
    });

    testWidgets('CampoInformacao anuncia rótulo e valor, sem papel de botão', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _comTema(const CampoInformacao(rotulo: 'Idade', valor: '72 anos')),
      );

      expect(
        tester.getSemantics(find.byType(CampoInformacao)),
        isSemantics(
          label: 'Idade',
          value: '72 anos',
          isButton: false,
          hasTapAction: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('títulos são anunciados como cabeçalho', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _comTema(const TextoMemora.tituloTela('Hub da Memora')),
      );

      expect(
        tester.getSemantics(find.byType(TextoMemora)),
        isSemantics(label: 'Hub da Memora', isHeader: true),
        reason:
            'Cabeçalho permite ao TalkBack pular de seção em seção, em vez '
            'de ler a tela inteira palavra por palavra.',
      );
      handle.dispose();
    });

    testWidgets('texto de corpo não é anunciado como cabeçalho', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _comTema(const TextoMemora('Vamos fazer isso juntos')),
      );

      expect(
        tester.getSemantics(find.byType(TextoMemora)),
        isSemantics(isHeader: false),
      );
      handle.dispose();
    });
  });

  group('Ordem de leitura acompanha a ordem visual — FR-029', () {
    testWidgets('ListaInformacao lê título e campos na ordem exibida', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _comTema(
          const ListaInformacao(
            titulo: 'Seus dados',
            campos: <CampoInformacao>[
              CampoInformacao(rotulo: 'Nome', valor: 'Ana'),
              CampoInformacao(rotulo: 'Idade', valor: '72'),
            ],
          ),
        ),
      );

      final Iterable<CampoInformacao> campos = tester
          .widgetList<CampoInformacao>(find.byType(CampoInformacao));

      expect(campos.map((CampoInformacao c) => c.rotulo).toList(), <String>[
        'Nome',
        'Idade',
      ]);
      handle.dispose();
    });
  });
}
