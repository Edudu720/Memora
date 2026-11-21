import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/antigolpe/data/repositorios/repositorio_analise_golpe_simulado.dart';
import 'package:memora/features/antigolpe/domain/entidades/analise_golpe.dart';
import 'package:memora/features/antigolpe/domain/repositorios/repositorio_analise_golpe.dart';
import 'package:memora/features/antigolpe/presentation/controladores/controlador_analise_golpe.dart';
import 'package:memora/features/antigolpe/presentation/telas/tela_analise_golpe.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/l10n/textos_antigolpe.dart';

import '../../suporte/aparelhos.dart';
import '../../suporte/estados_de_tela.dart';

class _RepositorioDeTeste implements RepositorioAnaliseGolpe {
  final Future<AnaliseGolpe> Function(String conteudo) _aoAnalisar;

  _RepositorioDeTeste(this._aoAnalisar);

  @override
  Future<AnaliseGolpe> analisar(String conteudo) => _aoAnalisar(conteudo);
}

void main() {
  group('TelaAnaliseGolpe — fluxos online, offline, colar e segurança', () {
    testWidgets('configura CampoTexto multilinha (minLines: 3, maxLines: 6) e colar/limpar funciona', (
      WidgetTester t,
    ) async {
      const String textoCopiado = 'Acesse https://bit.ly/golpe urgente';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (
            MethodCall call,
          ) async {
            if (call.method == 'Clipboard.getData') {
              return <String, dynamic>{'text': textoCopiado};
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );

      final ControladorAnaliseGolpe c = ControladorAnaliseGolpe(
        repositorio: const RepositorioAnaliseGolpeSimulado(),
      );
      addTearDown(c.dispose);

      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: TelaAnaliseGolpe(controlador: c, aoVoltar: () {}),
        ),
      );

      await t.tap(find.byKey(TelaAnaliseGolpe.chaveBotaoColar));
      await t.pump();

      final TextField campo = t.widget<TextField>(
        find.descendant(
          of: find.byKey(TelaAnaliseGolpe.chaveCampo),
          matching: find.byType(TextField),
        ),
      );
      expect(campo.minLines, 3);
      expect(campo.maxLines, 6);
      expect(campo.controller?.text, textoCopiado);

      await t.tap(find.byKey(TelaAnaliseGolpe.chaveBotaoLimpar));
      await t.pump();
      expect(campo.controller?.text, isEmpty);
    });

    testWidgets('diferencia origemServidorIa, origemServidorRegras e TomBadgeStatus.aviso vs informativo', (
      WidgetTester t,
    ) async {
      bool usarIa = true;
      NivelRisco risco = NivelRisco.atencao;

      final ControladorAnaliseGolpe c = ControladorAnaliseGolpe(
        repositorio: _RepositorioDeTeste(
          (_) async => AnaliseGolpe(
            risco: risco,
            origem: usarIa
                ? OrigemAnalise.servidorIa
                : OrigemAnalise.servidorRegras,
            titulo: 'Verifique com atenção',
            explicacao: 'Há um sinal que merece cautela.',
            orientacoes: const <String>['Confirme no canal oficial.'],
            sinaisDetectados: const <String>['Sinal de atenção.'],
            analisadoPorIa: usarIa,
          ),
        ),
      );
      addTearDown(c.dispose);

      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: TelaAnaliseGolpe(controlador: c, aoVoltar: () {}),
        ),
      );

      final Finder campo = find.descendant(
        of: find.byKey(TelaAnaliseGolpe.chaveCampo),
        matching: find.byType(TextField),
      );

      await t.enterText(campo, 'Você ganhou um brinde no sorteio');
      await t.pump();
      await t.ensureVisible(find.byKey(TelaAnaliseGolpe.chaveBotaoAnalisar));
      await t.tap(find.byKey(TelaAnaliseGolpe.chaveBotaoAnalisar));
      await t.pump();

      expect(find.byKey(TelaAnaliseGolpe.chaveCartaoResultado), findsOneWidget);
      expect(find.text(TextosAntigolpe.riscoAtencao), findsOneWidget);
      expect(find.text(TextosAntigolpe.origemServidorIa), findsOneWidget);

      final BadgeDeStatus badgeRisco = t.widget<BadgeDeStatus>(
        find.byKey(TelaAnaliseGolpe.chaveBadgeRisco),
      );
      final BadgeDeStatus badgeOrigem = t.widget<BadgeDeStatus>(
        find.byKey(TelaAnaliseGolpe.chaveBadgeOrigem),
      );
      expect(badgeRisco.tom, TomBadgeStatus.aviso);
      expect(badgeOrigem.tom, TomBadgeStatus.informativo);
      expect(badgeRisco.tom, isNot(equals(badgeOrigem.tom)));

      // Editar o texto limpa imediatamente o resultado anterior da tela
      await t.enterText(campo, 'Outro texto para analisar');
      await t.pump();
      expect(find.byKey(TelaAnaliseGolpe.chaveCartaoResultado), findsNothing);

      // Quando analisadoPorIa == false (servidorRegras), mostra origemServidorRegras
      usarIa = false;
      risco = NivelRisco.altoRisco;
      await c.analisar('Outro texto para analisar');
      await t.pump();

      expect(find.text(TextosAntigolpe.riscoAlto), findsOneWidget);
      expect(find.text(TextosAntigolpe.origemServidorRegras), findsOneWidget);
      expect(find.text(TextosAntigolpe.origemServidorIa), findsNothing);
    });

    testWidgets('oculta "Tentar de novo" em sessaoExpirada e exibe erroLimiteAnalises no HTTP 429', (
      WidgetTester t,
    ) async {
      bool erro429 = false;
      final ControladorAnaliseGolpe c = ControladorAnaliseGolpe(
        repositorio: _RepositorioDeTeste((_) async {
          if (erro429) {
            throw const FalhaAnaliseGolpe(
              FalhaAnaliseGolpeTipo.limiteExcedido,
              mensagem: TextosAntigolpe.erroLimiteAnalises,
              esperaEmSegundos: 60,
              statusCode: 429,
            );
          }
          throw const FalhaDeChamadaDaAssistente(
            FalhaDaAssistente.sessaoExpirada,
          );
        }),
      );
      addTearDown(c.dispose);

      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: TelaAnaliseGolpe(controlador: c, aoVoltar: () {}),
        ),
      );

      final Finder campo = find.descendant(
        of: find.byKey(TelaAnaliseGolpe.chaveCampo),
        matching: find.byType(TextField),
      );
      await t.enterText(campo, 'Mensagem suspeita');
      await t.pump();
      await t.ensureVisible(find.byKey(TelaAnaliseGolpe.chaveBotaoAnalisar));
      await t.tap(find.byKey(TelaAnaliseGolpe.chaveBotaoAnalisar));
      await t.pump();

      // Em sessaoExpirada, não há callback aoTentarNovamente
      final MensagemErro msgSessao = t.widget<MensagemErro>(
        find.byKey(TelaAnaliseGolpe.chaveErro),
      );
      expect(msgSessao.mensagem, TextosAntigolpe.sessaoExpirada);
      expect(msgSessao.aoTentarNovamente, isNull);

      // Em HTTP 429, mostra erroLimiteAnalises (sem falar que está sem internet) e permite tentar novamente
      erro429 = true;
      await c.analisar('Mensagem suspeita 2');
      await t.pump();

      final MensagemErro msg429 = t.widget<MensagemErro>(
        find.byKey(TelaAnaliseGolpe.chaveErro),
      );
      expect(msg429.mensagem, TextosAntigolpe.erroLimiteAnalises);
      expect(msg429.aoTentarNovamente, isNotNull);
      expect(find.byKey(TelaAnaliseGolpe.chaveAvisoOffline), findsNothing);
    });

    testWidgets('exibe selo e aviso honesto quando resultado vem do fallback offline', (
      WidgetTester t,
    ) async {
      final ControladorAnaliseGolpe c = ControladorAnaliseGolpe(
        repositorio: const RepositorioAnaliseGolpeSimulado(modoOffline: true),
      );
      addTearDown(c.dispose);

      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.altoContraste,
          home: TelaAnaliseGolpe(controlador: c, aoVoltar: () {}),
        ),
      );

      final Finder campo = find.descendant(
        of: find.byKey(TelaAnaliseGolpe.chaveCampo),
        matching: find.byType(TextField),
      );

      await t.enterText(
        campo,
        'Correios: taxa pendente, acesse http://192.168.1.50/pagar',
      );
      await t.pump();
      await t.ensureVisible(find.byKey(TelaAnaliseGolpe.chaveBotaoAnalisar));
      await t.tap(find.byKey(TelaAnaliseGolpe.chaveBotaoAnalisar));
      await t.pump();

      expect(find.text(TextosAntigolpe.riscoAlto), findsOneWidget);
      expect(find.text(TextosAntigolpe.origemLocalOffline), findsOneWidget);
      expect(find.byKey(TelaAnaliseGolpe.chaveAvisoOffline), findsOneWidget);
      expect(find.text(TextosAntigolpe.avisoOffline), findsOneWidget);

      final Container avisoContainer = t.widget<Container>(
        find.byKey(TelaAnaliseGolpe.chaveAvisoOffline),
      );
      final BoxDecoration decoracao =
          avisoContainer.decoration! as BoxDecoration;
      final Border borda = decoracao.border! as Border;
      expect(borda.top.width, MemoraDimensoes.bordaEnfase);
    });

    testWidgets('NUNCA renderiza links clicáveis no resultado mesmo com URLs no texto', (
      WidgetTester t,
    ) async {
      final ControladorAnaliseGolpe c = ControladorAnaliseGolpe(
        repositorio: _RepositorioDeTeste(
          (_) async => const AnaliseGolpe(
            risco: NivelRisco.altoRisco,
            origem: OrigemAnalise.servidorIa,
            titulo: 'Cuidado com https://golpe.xyz',
            explicacao: 'O link https://golpe.xyz/roubo não é oficial.',
            orientacoes: <String>[
              'Não toque em https://golpe.xyz nem responda.',
            ],
            sinaisDetectados: <String>[
              'Domínio suspeito: http://192.168.0.1/login',
            ],
            analisadoPorIa: true,
          ),
        ),
      );
      addTearDown(c.dispose);

      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: TelaAnaliseGolpe(controlador: c, aoVoltar: () {}),
        ),
      );

      final Finder campo = find.descendant(
        of: find.byKey(TelaAnaliseGolpe.chaveCampo),
        matching: find.byType(TextField),
      );
      await t.enterText(campo, 'https://golpe.xyz/roubo');
      await t.pump();
      await t.ensureVisible(find.byKey(TelaAnaliseGolpe.chaveBotaoAnalisar));
      await t.tap(find.byKey(TelaAnaliseGolpe.chaveBotaoAnalisar));
      await t.pump();

      // Nenhum SelectableText clicável ou TextSpan com recognizer dentro do cartão.
      final Finder dentroResultado = find.descendant(
        of: find.byKey(TelaAnaliseGolpe.chaveCartaoResultado),
        matching: find.byType(SelectableText),
      );
      expect(dentroResultado, findsNothing);

      for (final Text texto in t.widgetList<Text>(
        find.descendant(
          of: find.byKey(TelaAnaliseGolpe.chaveCartaoResultado),
          matching: find.byType(Text),
        ),
      )) {
        final InlineSpan? span = texto.textSpan;
        if (span is TextSpan) {
          expect(_temRecognizer(span), isFalse);
        }
      }
    });

    testWidgets('FR-006 e Memora única por tela em todos os estados', (
      WidgetTester t,
    ) async {
      final Completer<AnaliseGolpe> portao = Completer<AnaliseGolpe>();
      final ControladorAnaliseGolpe cCarregando = ControladorAnaliseGolpe(
        repositorio: _RepositorioDeTeste((_) => portao.future),
      );
      addTearDown(cCarregando.dispose);

      final ControladorAnaliseGolpe cVazio = ControladorAnaliseGolpe(
        repositorio: const RepositorioAnaliseGolpeSimulado(),
      );
      addTearDown(cVazio.dispose);

      final ControladorAnaliseGolpe cErro = ControladorAnaliseGolpe(
        repositorio: _RepositorioDeTeste(
          (_) async => throw const FalhaDeChamadaDaAssistente(
            FalhaDaAssistente.sessaoExpirada,
          ),
        ),
      );
      addTearDown(cErro.dispose);

      await exigirOsEstadosDaFr006(
        t,
        tela: 'TelaAnaliseGolpe',
        montar: (EstadoDaTela estado) {
          switch (estado) {
            case EstadoDaTela.carregando:
              unawaited(cCarregando.analisar('Mensagem qualquer'));
              return MaterialApp(
                theme: TemasMemora.claro,
                home: TelaAnaliseGolpe(controlador: cCarregando, aoVoltar: () {}),
              );
            case EstadoDaTela.vazio:
              return MaterialApp(
                theme: TemasMemora.claro,
                home: TelaAnaliseGolpe(controlador: cVazio, aoVoltar: () {}),
              );
            case EstadoDaTela.erro:
              unawaited(cErro.analisar('Mensagem qualquer'));
              return MaterialApp(
                theme: TemasMemora.claro,
                home: TelaAnaliseGolpe(controlador: cErro, aoVoltar: () {}),
              );
          }
        },
      );

      // No estado carregando e no estado erro, há no máximo 1 MemoraAnimada.
      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: TelaAnaliseGolpe(controlador: cCarregando, aoVoltar: () {}),
        ),
      );
      await t.pump(const Duration(milliseconds: 50));
      expect(find.byType(MemoraAnimada), findsOneWidget);

      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: TelaAnaliseGolpe(controlador: cErro, aoVoltar: () {}),
        ),
      );
      await t.pump(const Duration(milliseconds: 50));
      expect(find.byType(MemoraAnimada), findsOneWidget);

      portao.complete(
        const AnaliseGolpe(
          risco: NivelRisco.seguro,
          origem: OrigemAnalise.servidorIa,
          titulo: 'Sem sinais',
          explicacao: 'Mensagem comum.',
          orientacoes: <String>[],
          sinaisDetectados: <String>[],
          analisadoPorIa: true,
        ),
      );
    });
  });

  group('TelaAnaliseGolpe — acessibilidade e diretrizes WCAG / TalkBack', () {
    testWidgets('atende alvos de toque, rótulos, liveRegion com label explícito e sem gestos complexos', (
      WidgetTester t,
    ) async {
      final SemanticsHandle handle = t.ensureSemantics();

      final ControladorAnaliseGolpe c = ControladorAnaliseGolpe(
        repositorio: const RepositorioAnaliseGolpeSimulado(),
      );
      addTearDown(c.dispose);

      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: TelaAnaliseGolpe(controlador: c, aoVoltar: () {}),
        ),
      );
      await t.pump();

      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));

      await c.analisar('Urgente: envie seu código em https://bit.ly/golpe');
      await t.pump();

      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));

      final Semantics semanticaResultado = t.widget<Semantics>(
        find.descendant(
          of: find.byKey(TelaAnaliseGolpe.chaveCartaoResultado),
          matching: find.byWidgetPredicate(
            (Widget w) => w is Semantics && (w.properties.liveRegion ?? false),
          ),
        ),
      );
      expect(
        semanticaResultado.properties.label,
        '${c.resultado!.titulo} ${c.resultado!.explicacao}',
      );

      for (final GestureDetector gd in t.widgetList<GestureDetector>(
        find.byType(GestureDetector),
      )) {
        expect(gd.onLongPress, isNull);
        expect(gd.onHorizontalDragStart, isNull);
        expect(gd.onVerticalDragStart, isNull);
      }

      handle.dispose();
    });
  });

  group('TelaAnaliseGolpe — matriz 4 aparelhos × 3 escalas × 3 temas', () {
    for (final Combinacao c in matriz()) {
      testWidgets('sem estouro e alcançável em ${nomeDa(c)}', (
        WidgetTester t,
      ) async {
        vestir(t, c.aparelho);
        final ControladorAnaliseGolpe controlador = ControladorAnaliseGolpe(
          repositorio: const RepositorioAnaliseGolpeSimulado(modoOffline: true),
        );
        addTearDown(controlador.dispose);

        await t.pumpWidget(
          naCombinacao(
            c,
            TelaAnaliseGolpe(controlador: controlador, aoVoltar: () {}),
          ),
        );
        await t.pump();

        expect(t.takeException(), isNull, reason: nomeDa(c));

        await exigirAlcancavel(
          t,
          find.byKey(TelaAnaliseGolpe.chaveBotaoAnalisar),
          aparelho: c.aparelho,
          contexto: 'botão Analisar em ${nomeDa(c)}',
        );

        await controlador.analisar(
          'Urgente: envie seu código de 6 dígitos em https://bit.ly/golpe',
        );
        await t.pump();

        expect(t.takeException(), isNull, reason: '${nomeDa(c)} (com resultado)');
        expect(
          find.byKey(TelaAnaliseGolpe.chaveCartaoResultado),
          findsOneWidget,
        );
        expect(find.byType(MemoraAnimada), findsOneWidget);
      });
    }
  });
}

bool _temRecognizer(InlineSpan span) {
  if (span is TextSpan) {
    if (span.recognizer != null) return true;
    for (final InlineSpan filho in span.children ?? const <InlineSpan>[]) {
      if (_temRecognizer(filho)) return true;
    }
  }
  return false;
}
