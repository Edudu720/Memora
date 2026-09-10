import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/conversa_local.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/assistente/presentation/controladores/controlador_conversa.dart';
import 'package:memora/features/assistente/presentation/telas/tela_conversa.dart';
import 'package:memora/l10n/textos_assistente.dart';

/// Acessibilidade da conversa — T070, FR-026 a FR-030.
///
/// A funcionalidade (FR-014, FR-016, FR-033) já tem teste próprio em
/// `tela_conversa_test.dart`. Este arquivo cobre os cinco requisitos de
/// acessibilidade, com atenção especial a FR-028 e FR-029, que só fazem
/// sentido nesta tela.
///
/// ## As mesmas duas armadilhas do teste funcional
///
/// `pumpAndSettle` trava com o `Carregando` na tela — ele anima sem parar — e
/// I/O de arquivo de verdade não completa dentro de `testWidgets`. Por isso o
/// dublê de `ConversaLocal` em memória, e o bombeio manual de quadros.
class _ConversaEmMemoria implements ConversaLocal {
  List<MensagemDaConversa> _guardadas = <MensagemDaConversa>[];

  @override
  Future<List<MensagemDaConversa>> ler() async => _guardadas;

  @override
  Future<void> guardar(List<MensagemDaConversa> mensagens) async {
    _guardadas = List<MensagemDaConversa>.from(mensagens);
  }

  @override
  Future<void> apagar() async => _guardadas = <MensagemDaConversa>[];
}

void main() {
  late _ConversaEmMemoria local;

  setUp(() {
    local = _ConversaEmMemoria();
  });

  ControladorConversa controladorCom({Duration demora = Duration.zero}) {
    return ControladorConversa(
      RepositorioAssistenteSimulado(demora: demora),
      local,
    );
  }

  Future<void> avancar(WidgetTester t, {int quadros = 6}) async {
    for (int i = 0; i < quadros; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> montar(
    WidgetTester t,
    ControladorConversa c, {
    double escala = 1.0,
  }) async {
    // `MediaQuery(data: MediaQueryData(size: ...))` NÃO muda o tamanho real
    // usado no layout — só o valor que widgets leem via `MediaQuery.of`. As
    // restrições de verdade vêm da janela do teste, que por padrão é bem
    // maior que qualquer Android (foi assim que um overflow real ficou
    // escondido ao escrever este arquivo). Isto aqui muda a janela de fato.
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(escala)),
          child: TelaConversa(controlador: c),
        ),
      ),
    );
    await avancar(t);
  }

  Future<void> perguntar(WidgetTester t, String texto) async {
    await t.enterText(find.byKey(TelaConversa.chaveCampo), texto);
    await avancar(t);
    final Finder enviar = find.byKey(TelaConversa.chaveEnviar);
    await t.ensureVisible(enviar);
    await t.tap(enviar);
    await avancar(t);
  }

  group('Alvo de toque — FR-026', () {
    testWidgets('campo e botao de enviar atendem a diretriz de 48 dp',
        (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      final ControladorConversa c = controladorCom();
      addTearDown(c.dispose);
      await montar(t, c);

      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      h.dispose();
    });
  });

  group('Texto ampliado — FR-027', () {
    for (final double escala in <double>[1.0, 1.5, 2.0]) {
      testWidgets('a conversa nao quebra em escala $escala',
          (WidgetTester t) async {
        final ControladorConversa c = controladorCom();
        addTearDown(c.dispose);
        await montar(t, c, escala: escala);

        expect(t.takeException(), isNull);
        expect(find.byKey(TelaConversa.chaveCampo), findsOneWidget);
      });
    }
  });

  group('Mensagens alcancaveis na ordem — FR-028', () {
    testWidgets('cada mensagem enviada e respondida chega ao leitor de tela, '
        'na ordem em que foi dita', (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      final ControladorConversa c = controladorCom();
      addTearDown(c.dispose);
      await montar(t, c);

      // Duas perguntas com textos que o simulado responde de formas
      // DIFERENTES entre si (a segunda declara dificuldade e recebe uma
      // oferta) — de propósito, para as quatro falas terem texto distinto.
      // Repetir a mesma resposta genérica montaria dois balões com o mesmo
      // texto ao mesmo tempo, e `find.text` não saberia dizer qual é qual.
      await perguntar(t, 'como vejo as fotos do meu neto');
      await perguntar(t, 'nao consegui achar');
      expect(c.mensagens, hasLength(4));
      expect(
        c.mensagens.map((MensagemDaConversa m) => m.texto).toSet(),
        hasLength(4),
        reason: 'o cenario pressupoe quatro textos distintos',
      );

      // A `ListView` é preguiçosa: item que rolou para fora do cache deixa de
      // existir na árvore, e é assim mesmo que o TalkBack funciona — ele
      // aciona a rolagem para alcançar o que ainda não apareceu. O teste
      // reproduz isso: parte do topo e vai revelando uma fala de cada vez,
      // SEMPRE para frente. Se a ordem real estivesse trocada, a busca pela
      // fala fora de ordem falharia, porque `dragUntilVisible` nunca rola
      // para trás.
      final Finder lista = find.byType(ListView);
      final ScrollableState rolagem = t.state<ScrollableState>(
        find.descendant(of: lista, matching: find.byType(Scrollable)).first,
      );
      rolagem.position.jumpTo(0);
      await t.pump();

      for (final MensagemDaConversa m in c.mensagens) {
        await t.dragUntilVisible(find.text(m.texto), lista, const Offset(0, -80));
        expect(
          find.text(m.texto),
          findsOneWidget,
          reason: 'a fala "${m.texto}" precisa estar acessivel ao leitor de '
              'tela, na posicao em que foi dita',
        );
      }
      h.dispose();
    });
  });

  group('Estado "respondendo" e perceptivel — FR-029', () {
    testWidgets(
        'enquanto a Memora responde, o texto "Estou pensando..." aparece — '
        'nao so o circulo girando', (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      // Demora real, para o teste capturar o instante EM que ela responde,
      // sem esperar a resposta terminar.
      final ControladorConversa c =
          controladorCom(demora: const Duration(milliseconds: 300));
      addTearDown(c.dispose);
      await montar(t, c);

      await t.enterText(find.byKey(TelaConversa.chaveCampo), 'oi');
      await avancar(t);
      unawaited(c.enviar());
      await t.pump();

      expect(c.respondendo, isTrue);

      // O `Carregando` do Design System anuncia por Semantics(liveRegion:
      // true, label: mensagem) — texto, nao so animacao ou cor isolada. Um
      // circulo sozinho nao diz nada a quem nao ve.
      expect(find.byType(Carregando), findsOneWidget);
      expect(
        t.getSemantics(find.byType(Carregando)),
        isSemantics(label: TextosAssistente.pensando),
      );
      expect(find.text(TextosAssistente.pensando), findsWidgets);

      // Drena o timer da demora simulada — senao "A Timer is still pending"
      // reprova o teste, mesmo com o corpo ja verificado.
      await t.pump(const Duration(milliseconds: 350));
      await avancar(t);
      h.dispose();
    });
  });

  group('Nenhum gesto alem de toque e rolagem — FR-030', () {
    testWidgets('a tela nao usa arrastar nem pressionar e segurar',
        (WidgetTester t) async {
      final ControladorConversa c = controladorCom();
      addTearDown(c.dispose);
      await montar(t, c);
      await perguntar(t, 'como mando mensagem');

      final Iterable<GestureDetector> gestos =
          t.widgetList<GestureDetector>(find.byType(GestureDetector));

      for (final GestureDetector g in gestos) {
        expect(g.onLongPress, isNull);
        expect(g.onHorizontalDragStart, isNull);
        // A rolagem vertical da lista de mensagens e a excecao permitida pela
        // FR-030 — ela usa `ListView`/`Scrollable`, nao `GestureDetector` com
        // `onVerticalDragStart` proprio, entao nenhum widget aqui deveria ter
        // esse callback preenchido.
        expect(g.onVerticalDragStart, isNull);
      }
    });
  });
}
