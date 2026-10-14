import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

import '../../suporte/aparelhos.dart';

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

Widget _app(
  ControladorAparencia controlador, {
  GrupoDeAjusteVisual grupo = GrupoDeAjusteVisual.aparencia,
  VoidCallback? aoVoltar,
}) {
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
            reduzirMovimento: controlador.atual.reduzirMovimento,
            child: child!,
          ),
          home: TelaAparencia(grupo: grupo, aoVoltar: aoVoltar),
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

      await _tocar(tester, find.text('Escuro'));

      expect(c.atual.tema, EscolhaDeTema.escuro);
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

      await _tocar(tester, find.text('Escuro'));
      await _tocar(tester, find.text('Deixar como estava'));

      expect(c.atual.tema, EscolhaDeTema.seguirSistema);
      expect(repo.gravacoes, 0);
    });

    testWidgets('voltar ao padrão aparece só quando há personalização',
        (WidgetTester tester) async {
      final _RepositorioFalso repo = _RepositorioFalso();
      final ControladorAparencia c = ControladorAparencia(repo);
      await tester.pumpWidget(
        _app(c, grupo: GrupoDeAjusteVisual.acessibilidade),
      );

      expect(find.text('Voltar ao jeito original'), findsNothing);

      await _tocar(tester, find.text('Bem grande'));

      expect(find.text('Voltar ao jeito original'), findsOneWidget);
    });

    testWidgets('voltar ao padrão restaura em um único toque',
        (WidgetTester tester) async {
      final _RepositorioFalso repo = _RepositorioFalso();
      final ControladorAparencia c = ControladorAparencia(repo);
      await tester.pumpWidget(
        _app(c, grupo: GrupoDeAjusteVisual.acessibilidade),
      );

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

  group('Aparência: só as cores comuns — FR-038, FR-039a', () {
    testWidgets('oferece igual ao celular, claro e escuro, e NÃO o alto '
        'contraste, que mora em Acessibilidade', (WidgetTester tester) async {
      await tester.pumpWidget(_app(ControladorAparencia(_RepositorioFalso())));

      expect(find.text('Igual ao meu celular'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Escuro'), findsOneWidget);
      expect(find.text('Mais contraste'), findsNothing);
      // Nem o tamanho da letra nem o movimento: são de Acessibilidade.
      expect(find.text('Bem grande'), findsNothing);
      expect(find.text('Menos movimento'), findsNothing);
    });

    testWidgets('com o alto contraste ligado, diz onde mudar', (
      WidgetTester tester,
    ) async {
      final _RepositorioFalso repo = _RepositorioFalso()
        ..salva = const PreferenciaAparencia(tema: EscolhaDeTema.altoContraste);
      final ControladorAparencia c = ControladorAparencia(repo);
      await c.carregar();
      await tester.pumpWidget(_app(c));

      expect(find.textContaining('Enxergar e usar melhor'), findsOneWidget);
    });
  });

  group('Acessibilidade — FR-039a', () {
    Widget acessibilidade(ControladorAparencia c) =>
        _app(c, grupo: GrupoDeAjusteVisual.acessibilidade);

    testWidgets('reúne tamanho da letra, movimento e contraste', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        acessibilidade(ControladorAparencia(_RepositorioFalso())),
      );

      expect(find.text('Tamanho da letra'), findsOneWidget);
      expect(find.text('Movimento'), findsOneWidget);
      expect(find.text('Contraste'), findsOneWidget);
      expect(find.text('Mais contraste'), findsOneWidget);
      expect(find.text('Menos movimento'), findsOneWidget);
    });

    testWidgets('cada opção diz para quem serve', (WidgetTester tester) async {
      await tester.pumpWidget(
        acessibilidade(ControladorAparencia(_RepositorioFalso())),
      );

      expect(
        find.textContaining('Se as letras parecem pequenas'),
        findsOneWidget,
      );
      expect(find.textContaining('Se o que se mexe na tela'), findsOneWidget);
      expect(
        find.textContaining('Se é difícil separar a letra do fundo'),
        findsOneWidget,
      );
    });

    testWidgets('menos movimento: pré-visualiza, não grava, e só salva ao '
        'confirmar', (WidgetTester tester) async {
      final _RepositorioFalso repo = _RepositorioFalso();
      final ControladorAparencia c = ControladorAparencia(repo);
      await tester.pumpWidget(acessibilidade(c));

      await _tocar(tester, find.text('Menos movimento'));

      expect(c.atual.reduzirMovimento, isTrue);
      expect(repo.gravacoes, 0, reason: 'Experimentar não grava.');
      expect(find.byKey(TelaAparencia.chaveSalvar), findsOneWidget);
      expect(find.byKey(TelaAparencia.chaveDesfazer), findsOneWidget);

      await _tocar(tester, find.byKey(TelaAparencia.chaveSalvar));

      expect(repo.salva?.reduzirMovimento, isTrue);
      expect(find.byKey(TelaAparencia.chaveSalvar), findsNothing);
    });

    testWidgets('menos movimento: desfazer volta, e nada foi gravado', (
      WidgetTester tester,
    ) async {
      final _RepositorioFalso repo = _RepositorioFalso();
      final ControladorAparencia c = ControladorAparencia(repo);
      await tester.pumpWidget(acessibilidade(c));

      await _tocar(tester, find.text('Menos movimento'));
      await _tocar(tester, find.byKey(TelaAparencia.chaveDesfazer));

      expect(c.atual.reduzirMovimento, isFalse);
      expect(repo.gravacoes, 0);
    });

    testWidgets('menos movimento pré-visualizado chega ao MediaQuery da '
        'tela, na hora', (WidgetTester tester) async {
      final ControladorAparencia c = ControladorAparencia(_RepositorioFalso());
      await tester.pumpWidget(acessibilidade(c));
      bool reduz() => MediaQuery.disableAnimationsOf(
        tester.element(find.byType(TelaAparencia)),
      );
      expect(reduz(), isFalse);

      await _tocar(tester, find.text('Menos movimento'));

      expect(
        reduz(),
        isTrue,
        reason: 'pré-visualizar precisa mudar a tela antes de salvar',
      );

      await _tocar(tester, find.byKey(TelaAparencia.chaveDesfazer));
      expect(reduz(), isFalse);
    });

    testWidgets('mais contraste: pré-visualiza o tema, e "cores do jeito '
        'normal" volta a seguir o celular', (WidgetTester tester) async {
      final _RepositorioFalso repo = _RepositorioFalso();
      final ControladorAparencia c = ControladorAparencia(repo);
      await tester.pumpWidget(acessibilidade(c));

      await _tocar(tester, find.text('Mais contraste'));
      expect(c.atual.tema, EscolhaDeTema.altoContraste);
      expect(repo.gravacoes, 0);

      await _tocar(tester, find.text('Cores do jeito normal'));
      expect(c.atual.tema, EscolhaDeTema.seguirSistema);
    });

    testWidgets('o tamanho da letra pré-visualiza e salva', (
      WidgetTester tester,
    ) async {
      final _RepositorioFalso repo = _RepositorioFalso();
      final ControladorAparencia c = ControladorAparencia(repo);
      await tester.pumpWidget(acessibilidade(c));

      await _tocar(tester, find.text('Grande'));
      expect(c.atual.escalaTexto, TamanhoDeLetra.grande.fator);
      expect(repo.gravacoes, 0);

      await _tocar(tester, find.byKey(TelaAparencia.chaveSalvar));
      expect(repo.salva?.escalaTexto, TamanhoDeLetra.grande.fator);
    });

    testWidgets('as opções atendem à diretriz de alvo de toque', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        acessibilidade(ControladorAparencia(_RepositorioFalso())),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });

  group('Matriz — FR-044', () {
    for (final GrupoDeAjusteVisual grupo in GrupoDeAjusteVisual.values) {
      for (final Combinacao c in matriz()) {
        testWidgets('${grupo.name}: não estoura e salvar é alcançável em '
            '${nomeDa(c)}', (WidgetTester tester) async {
          vestir(tester, c.aparelho);
          final _RepositorioFalso repo = _RepositorioFalso();
          final ControladorAparencia controlador = ControladorAparencia(repo);
          await tester.pumpWidget(
            EscopoAparencia(
              controlador: controlador,
              child: naCombinacao(
                c,
                TelaAparencia(grupo: grupo, aoVoltar: () {}),
              ),
            ),
          );
          expect(tester.takeException(), isNull, reason: nomeDa(c));

          final String opcao = grupo == GrupoDeAjusteVisual.aparencia
              ? 'Escuro'
              : 'Menos movimento';
          await tester.ensureVisible(find.text(opcao));
          await tester.pump();
          await tester.tap(find.text(opcao));
          await tester.pump();
          expect(tester.takeException(), isNull, reason: nomeDa(c));

          await exigirAlcancavel(
            tester,
            find.byKey(TelaAparencia.chaveSalvar),
            aparelho: c.aparelho,
            contexto: '${grupo.name} / ${nomeDa(c)}',
          );
          await tester.tap(find.byKey(TelaAparencia.chaveSalvar));
          await tester.pump();
          expect(repo.gravacoes, 1, reason: nomeDa(c));
        });
      }
    }
  });
}
