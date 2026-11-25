import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/ajuda/domain/assunto_de_ajuda.dart';
import 'package:memora/features/ajuda/presentation/tela_ajuda.dart';
import 'package:memora/features/assistente/data/conversa_local.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/assistente/presentation/controladores/controlador_conversa.dart';
import 'package:memora/features/assistente/presentation/telas/tela_conversa.dart';
import 'package:memora/features/inicio/presentation/tela_inicio.dart';

import '../suporte/aceite_em_memoria.dart';
import '../suporte/movimento.dart';

class _ConversaVazia implements ConversaLocal {
  @override
  Future<void> apagar() async {}

  @override
  Future<void> guardar(List<MensagemDaConversa> mensagens) async {}

  @override
  Future<List<MensagemDaConversa>> ler() async => <MensagemDaConversa>[];
}

void main() {
  movimentoLiberado();

  group('Ícones arredondados e ilustrações (T063, T064)', () {
    test('todo Icons.<nome> em lib/ usa a família _rounded', () {
      final RegExp padrao = RegExp(r'Icons\.([A-Za-z0-9_]+)\b');
      final List<String> fora = <String>[];

      for (final FileSystemEntity entidade
          in Directory('lib').listSync(recursive: true)) {
        if (entidade is! File || !entidade.path.endsWith('.dart')) continue;
        final List<String> linhas = entidade.readAsLinesSync();
        for (int i = 0; i < linhas.length; i++) {
          final String codigo = linhas[i].split('//').first;
          for (final RegExpMatch m in padrao.allMatches(codigo)) {
            final String nome = m.group(1)!;
            if (!nome.endsWith('_rounded')) {
              fora.add('${entidade.path}:${i + 1}: Icons.$nome');
            }
          }
        }
      }

      expect(
        fora,
        isEmpty,
        reason: 'Ícones fora do estilo arredondado encontrados em lib/: $fora',
      );
    });

    test('nenhum Image.asset fora dos logos de app e dos retratos de T081', () {
      final RegExp padrao = RegExp(r'\bImage\.asset\(');
      final List<String> fora = <String>[];

      const Set<String> permitidos = <String>{
        'icone_do_aplicativo.dart',
        // TODO(T081): remover esta exceção temporária quando T081 migrar os
        // retratos da tela de perfil para o visual da 013.
        'retrato_do_perfil.dart',
        'secao_foto_perfil.dart',
      };

      for (final FileSystemEntity entidade
          in Directory('lib').listSync(recursive: true)) {
        if (entidade is! File || !entidade.path.endsWith('.dart')) continue;
        final String arquivo = entidade.path.replaceAll('\\', '/').split('/').last;
        if (permitidos.contains(arquivo)) continue;

        final List<String> linhas = entidade.readAsLinesSync();
        for (int i = 0; i < linhas.length; i++) {
          final String codigo = linhas[i].split('//').first;
          if (padrao.hasMatch(codigo)) {
            fora.add('${entidade.path}:${i + 1}');
          }
        }
      }

      expect(
        fora,
        isEmpty,
        reason: 'Image.asset proibido fora da lista permitida: $fora',
      );
    });

    testWidgets('TelaAjuda tem no máximo uma MemoraAnimada (FR-006)', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: TelaAjuda(
            assuntos: AssuntoDeAjuda.disponiveis(podeCompartilhar: true),
            aoAbrirAssunto: (AssuntoDeAjuda _) {},
            aoVoltar: () {},
            aoVerApresentacao: () {},
          ),
        ),
      );
      await t.pump();

      expect(
        find.byType(MemoraAnimada).evaluate().length,
        lessThanOrEqualTo(1),
      );
    });

    testWidgets('TelaInicio tem no máximo uma MemoraAnimada (FR-006)', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: const Scaffold(body: TelaInicio(nome: 'Dona Maria')),
        ),
      );
      await t.pump();

      expect(
        find.byType(MemoraAnimada).evaluate().length,
        lessThanOrEqualTo(1),
      );
    });

    testWidgets('TelaConversa tem no máximo uma MemoraAnimada (FR-006)', (
      WidgetTester t,
    ) async {
      final ControladorConversa controlador = ControladorConversa(
        RepositorioAssistenteSimulado(demora: Duration.zero),
        _ConversaVazia(),
        aceite: AceiteEmMemoria(),
      );
      addTearDown(controlador.dispose);

      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: TelaConversa(controlador: controlador),
        ),
      );
      for (int i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }

      // Nos balões da conversa (inclusive no convite), qualquer MemoraAnimada
      // permanece estática e sem toque (022-avatares-no-chat); fora de
      // BalaoDeFala há no máximo uma (na BarraSuperior).
      final Finder nosBaloes = find.descendant(
        of: find.byType(BalaoDeFala),
        matching: find.byType(MemoraAnimada),
      );
      for (final Element el in nosBaloes.evaluate()) {
        expect((el.widget as MemoraAnimada).reageAoToque, isFalse);
        expect(MediaQuery.disableAnimationsOf(el), isTrue);
      }
      expect(
        find.byType(MemoraAnimada).evaluate().length -
            nosBaloes.evaluate().length,
        lessThanOrEqualTo(1),
      );
    });
  });

  group('Toque com redução de movimento (T065, FR-028)', () {
    Widget emMediaQueryReduzida(Widget filho) => MaterialApp(
      theme: TemasMemora.claro,
      home: Builder(
        builder: (BuildContext context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: Scaffold(body: Center(child: filho)),
        ),
      ),
    );

    BoxDecoration bordaDe(WidgetTester t, Finder alvo) {
      final DecoratedBox caixa = t.widget<DecoratedBox>(
        find.descendant(
          of: alvo,
          matching: find.byWidgetPredicate(
            (Widget w) =>
                w is DecoratedBox &&
                w.position == DecorationPosition.foreground,
          ),
        ),
      );
      return caixa.decoration as BoxDecoration;
    }

    testWidgets(
      'BotaoPrimario mostra anel imediato em foregroundDecoration ao pressionar',
      (WidgetTester t) async {
        int toques = 0;
        await t.pumpWidget(
          emMediaQueryReduzida(
            BotaoPrimario(rotulo: 'Continuar', aoTocar: () => toques++),
          ),
        );

        final Finder botao = find.byType(BotaoPrimario);
        expect(bordaDe(t, botao).border, isNull);

        final TestGesture gesto = await t.startGesture(t.getCenter(botao));
        await t.pump(kPressTimeout);

        final BoxDecoration decoracaoPressionado = bordaDe(t, botao);
        expect(decoracaoPressionado.border, isNotNull);
        final Border borda = decoracaoPressionado.border! as Border;
        expect(borda.top.width, MemoraDimensoes.bordaSelecao);

        await gesto.up();
        await t.pumpAndSettle();
        expect(toques, 1);
        expect(bordaDe(t, botao).border, isNull);
      },
    );

    testWidgets(
      'CartaoDePorta mostra anel imediato em foregroundDecoration ao pressionar',
      (WidgetTester t) async {
        int toques = 0;
        await t.pumpWidget(
          emMediaQueryReduzida(
            CartaoDePorta(
              nome: 'Ajuda',
              explicacao: 'Tire dúvidas',
              ilustracao: Ilustracao.portaAjuda,
              aoAbrir: () => toques++,
            ),
          ),
        );

        final Finder porta = find.byType(CartaoDePorta);
        expect(bordaDe(t, porta).border, isNull);

        final TestGesture gesto = await t.startGesture(t.getCenter(porta));
        await t.pump(kPressTimeout);

        final BoxDecoration decoracaoPressionado = bordaDe(t, porta);
        expect(decoracaoPressionado.border, isNotNull);
        final Border borda = decoracaoPressionado.border! as Border;
        expect(borda.top.width, MemoraDimensoes.bordaSelecao);

        await gesto.up();
        await t.pumpAndSettle();
        expect(toques, 1);
        expect(bordaDe(t, porta).border, isNull);
      },
    );
  });
}
