import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

class _RepositorioFalso implements RepositorioPreferenciaAparencia {
  PreferenciaAparencia? salva;
  int gravacoes = 0;

  @override
  Future<PreferenciaAparencia> carregar() async =>
      salva ?? PreferenciaAparencia.padrao;

  @override
  Future<void> salvar(PreferenciaAparencia preferencia) async {
    salva = preferencia;
    gravacoes++;
  }
}

Widget _app(ControladorAparencia controlador) {
  return EscopoAparencia(
    controlador: controlador,
    child: ListenableBuilder(
      listenable: controlador,
      builder: (BuildContext context, _) {
        final AparenciaResolvida a = AparenciaResolvida.de(controlador.atual);
        return MaterialApp(
          theme: a.temaClaro,
          darkTheme: a.temaEscuro,
          themeMode: a.modo,
          builder: (BuildContext context, Widget? child) => AmpliacaoDeTexto(
            fatorDoAplicativo: controlador.atual.escalaTexto,
            child: child!,
          ),
          home: const TelaAparencia(),
        );
      },
    ),
  );
}

/// Rola até o elemento e toca nele.
///
/// A tela de aparência é mais alta que a janela de teste; sem rolar, o toque
/// cai fora da área visível e não registra.
Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

void main() {
  group('Tela de aparência — fluxo de pré-visualização', () {
    testWidgets('não oferece salvar enquanto nada foi mudado',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(ControladorAparencia(_RepositorioFalso())));

      expect(find.text('Salvar deste jeito'), findsNothing);
      expect(find.text('Deixar como estava'), findsNothing);
    });

    testWidgets('escolher um tema pré-visualiza e oferece salvar ou desfazer',
        (WidgetTester tester) async {
      final _RepositorioFalso repo = _RepositorioFalso();
      final ControladorAparencia c = ControladorAparencia(repo);
      await tester.pumpWidget(_app(c));

      await _tocar(tester, find.text('Mais contraste'));

      expect(c.atual.tema, EscolhaDeTema.altoContraste);
      expect(repo.gravacoes, 0, reason: 'Experimentar não grava.');
      expect(find.text('Salvar deste jeito'), findsOneWidget);
      expect(find.text('Deixar como estava'), findsOneWidget);
    });

    testWidgets('salvar persiste e some com os botões de decisão',
        (WidgetTester tester) async {
      final _RepositorioFalso repo = _RepositorioFalso();
      final ControladorAparencia c = ControladorAparencia(repo);
      await tester.pumpWidget(_app(c));

      await _tocar(tester, find.text('Escuro'));
      await _tocar(tester, find.text('Salvar deste jeito'));

      expect(repo.salva?.tema, EscolhaDeTema.escuro);
      expect(find.text('Salvar deste jeito'), findsNothing);
    });

    testWidgets('desfazer volta ao estado anterior',
        (WidgetTester tester) async {
      final _RepositorioFalso repo = _RepositorioFalso();
      final ControladorAparencia c = ControladorAparencia(repo);
      await tester.pumpWidget(_app(c));

      await _tocar(tester, find.text('Mais contraste'));
      await _tocar(tester, find.text('Deixar como estava'));

      expect(c.atual.tema, EscolhaDeTema.seguirSistema);
      expect(repo.gravacoes, 0);
    });

    testWidgets('voltar ao padrão aparece só quando há personalização',
        (WidgetTester tester) async {
      final _RepositorioFalso repo = _RepositorioFalso();
      final ControladorAparencia c = ControladorAparencia(repo);
      await tester.pumpWidget(_app(c));

      expect(find.text('Voltar ao jeito original'), findsNothing);

      await _tocar(tester, find.text('Bem grande'));

      expect(find.text('Voltar ao jeito original'), findsOneWidget);
    });

    testWidgets('voltar ao padrão restaura em um único toque',
        (WidgetTester tester) async {
      final _RepositorioFalso repo = _RepositorioFalso();
      final ControladorAparencia c = ControladorAparencia(repo);
      await tester.pumpWidget(_app(c));

      await _tocar(tester, find.text('Bem grande'));
      await _tocar(tester, find.text('Voltar ao jeito original'));

      expect(c.atual, PreferenciaAparencia.padrao);
      expect(repo.salva, PreferenciaAparencia.padrao);
    });
  });

  group('Tela de aparência — acessibilidade', () {
    testWidgets('opções atendem à diretriz de alvo de toque',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(ControladorAparencia(_RepositorioFalso())));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('opção selecionada é anunciada como escolha exclusiva',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(ControladorAparencia(_RepositorioFalso())));

      expect(
        tester.getSemantics(find.byType(OpcaoSelecionavel).first),
        isSemantics(
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          isChecked: true,
        ),
        reason: 'Sem isso o leitor de tela não informa qual opção está ativa '
            'nem que se trata de escolha única.',
      );
      handle.dispose();
    });

    testWidgets('tela continua utilizável na ampliação máxima',
        (WidgetTester tester) async {
      final ControladorAparencia c = ControladorAparencia(_RepositorioFalso());
      c.preVisualizarEscalaTexto(MemoraDimensoes.escalaTextoMax);
      await tester.pumpWidget(_app(c));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
