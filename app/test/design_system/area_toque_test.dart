import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

/// Envolve o widget num aplicativo com o tema informado.
Widget _comTema(Widget filho, {MemoraTemaId id = MemoraTemaId.claro}) {
  return MaterialApp(
    theme: TemasMemora.porId(id),
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(MemoraEspacamento.lg),
          child: filho,
        ),
      ),
    ),
  );
}

void main() {
  group('Área de toque — FR-009 e SC-002', () {
    testWidgets('BotaoPrimario atende à diretriz de alvo do Android', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _comTema(BotaoPrimario(rotulo: 'Começar jornada', aoTocar: () {})),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('BotaoSecundario atende à diretriz de alvo', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _comTema(BotaoSecundario(rotulo: 'Entrar com Google', aoTocar: () {})),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('BotaoTerciario atende à diretriz de alvo', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _comTema(BotaoTerciario(rotulo: 'Esqueci minha senha', aoTocar: () {})),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('BotaoPerigo atende à diretriz de alvo', (
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

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('botões de decisão têm no mínimo 56 dp de altura', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _comTema(BotaoPrimario(rotulo: 'Continuar', aoTocar: () {})),
      );

      final Size tamanho = tester.getSize(find.byType(BotaoPrimario));
      expect(
        tamanho.height,
        greaterThanOrEqualTo(MemoraDimensoes.alvoDecisao),
        reason:
            'Ponto de decisão exige alvo maior que o mínimo. Os botões '
            'SIM/NÃO do protótipo mediam 24 px — metade dos 48 dp exigidos.',
      );
    });

    testWidgets('botão desabilitado preserva a área de toque', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const _TemaConst(BotaoPrimario(rotulo: 'Continuar')),
      );

      final Size tamanho = tester.getSize(find.byType(BotaoPrimario));
      expect(
        tamanho.height,
        greaterThanOrEqualTo(MemoraDimensoes.alvoDecisao),
        reason:
            'Desabilitar não pode encolher o alvo: a pessoa ainda tenta '
            'tocar, e precisa acertar para receber o retorno.',
      );
    });
  });

  group('Redução de movimento — FR-027', () {
    testWidgets('animação é suprimida quando o sistema pede menos movimento', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Center(
                child: BotaoPrimario(rotulo: 'Continuar', aoTocar: () {}),
              ),
            ),
          ),
        ),
      );

      final AnimatedContainer container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(BotaoPrimario),
          matching: find.byType(AnimatedContainer),
        ),
      );

      expect(
        container.duration,
        Duration.zero,
        reason:
            'Com "reduzir movimento" ativo, nenhuma animação deve ocorrer. '
            'MemoraMovimento.efetiva existe justamente para isso.',
      );
    });
  });

  group('Crescimento com texto ampliado — FR-026', () {
    testWidgets('botão cresce em vez de cortar o texto em escala 2.0', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(MemoraDimensoes.escalaTextoMax),
            ),
            child: Scaffold(
              body: Center(
                child: BotaoPrimario(
                  rotulo: 'Quero aprender a usar o WhatsApp',
                  aoTocar: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      final Size tamanho = tester.getSize(find.byType(BotaoPrimario));
      expect(
        tamanho.height,
        greaterThan(MemoraDimensoes.alvoDecisao),
        reason:
            'Com o texto a 200% o botão precisa crescer. Altura fixa '
            'cortaria o rótulo justamente para quem depende da ampliação.',
      );
    });
  });
}

/// Variante const de [_comTema], para testar o botão desabilitado.
class _TemaConst extends StatelessWidget {
  final Widget filho;
  const _TemaConst(this.filho);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: TemasMemora.claro,
      home: Scaffold(body: Center(child: filho)),
    );
  }
}
