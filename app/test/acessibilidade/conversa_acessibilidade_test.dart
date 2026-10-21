import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/conversa_local.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/assistente/presentation/controladores/controlador_conversa.dart';
import 'package:memora/features/assistente/presentation/telas/tela_conversa.dart';
import 'package:memora/l10n/textos_assistente.dart';
import '../suporte/aceite_em_memoria.dart';
import '../suporte/escrita_da_resposta.dart';

import '../suporte/aparelhos.dart';

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

  ControladorConversa controladorCom({
    Duration demora = Duration.zero,
    bool aceito = true,
  }) {
    return ControladorConversa(
      RepositorioAssistenteSimulado(demora: demora),
      local,
      aceite: AceiteEmMemoria(aceito: aceito),
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
    Size aparelho = referencia,
  }) async {
    // `MediaQuery(data: MediaQueryData(size: ...))` NÃO muda o tamanho real
    // usado no layout — só o valor que widgets leem via `MediaQuery.of`. As
    // restrições de verdade vêm da janela do teste, que por padrão é bem
    // maior que qualquer Android (foi assim que um overflow real ficou
    // escondido ao escrever este arquivo). Isto aqui muda a janela de fato.
    t.view.physicalSize = aparelho;
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        // `copyWith` sobre o `MediaQuery` real, e nao um `MediaQueryData` novo:
        // este nasce com `size: Size.zero`, e o `AvisoCompacto` calcula o teto
        // dele a partir do tamanho da tela — o aviso aberto media 0 px e os
        // portoes abaixo passavam sem medir nada.
        home: Builder(
          builder: (BuildContext contexto) => MediaQuery(
            data: MediaQuery.of(contexto).copyWith(
              textScaler: TextScaler.linear(escala),
            ),
            child: TelaConversa(controlador: c),
          ),
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
    await esperarAEscrita(t);
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
    for (final Size aparelho in aparelhos) {
      final String nome = nomeDo(aparelho);

      for (final double escala in <double>[1.0, 1.5, 2.0]) {
        testWidgets('a conversa continua utilizavel em $nome, escala $escala',
            (WidgetTester t) async {
          final ControladorConversa c = controladorCom();
          addTearDown(c.dispose);
          await montar(t, c, escala: escala, aparelho: aparelho);

          expect(t.takeException(), isNull,
              reason: 'nada pode estourar a tela em $nome a $escala');

          // ⚠️ As três asserções abaixo existem porque a versão anterior
          // deste teste — `takeException()` mais "o campo existe" — passava
          // com a conversa reduzida a **4 px** de altura em 200%. Não
          // estourar não é o mesmo que continuar utilizável, e a FR-027 pede
          // a segunda coisa.
          expect(find.byKey(TelaConversa.chaveCampo), findsOneWidget);

          final double alturaDaLista =
              t.getSize(find.byType(ListView).first).height;
          expect(alturaDaLista, greaterThanOrEqualTo(48),
              reason: 'a conversa precisa sobrar com pelo menos uma linha '
                  'legivel; em $nome a $escala sobraram '
                  '${alturaDaLista.toStringAsFixed(0)} px');

          // Alcançável: rolar a faixa de baixo tem que trazer o botão de
          // enviar para dentro da tela. Sem isto, uma tela em que o botão
          // ficou fora e é inalcançável passaria pelas duas asserções acima.
          final Finder enviar = find.byKey(TelaConversa.chaveEnviar);
          await t.ensureVisible(enviar);
          final Rect botao = t.getRect(enviar);
          expect(botao.top, greaterThanOrEqualTo(0));
          expect(botao.bottom, lessThanOrEqualTo(aparelho.height),
              reason: 'o botao de enviar precisa caber na tela depois de '
                  'rolada a faixa que o contem');
        });
      }
    }
  });

  group('O aviso compacto — FR-022 e FR-049', () {
    // "Altura disponivel" = a que sobra abaixo da barra superior, que e o que
    // a tela de conversa reparte entre aviso, lista e campo.
    double disponivel(WidgetTester t, Size aparelho) =>
        aparelho.height - t.getSize(find.byType(BarraSuperior)).height;

    // Depois da primeira pergunta o aviso e SO o escudo (T130): o nucleo
    // ("senha" e "codigo") nao esta mais escrito na tela, esta no rotulo que o
    // leitor de tela le. E por isso que os portoes abaixo leem a semantica, e
    // nao o texto visivel.
    String rotuloDoEscudo(WidgetTester t) => t
        .getSemantics(find.byKey(AvisoCompacto.chaveAlternar))
        .getSemanticsData()
        .label
        .toLowerCase();

    String textoVisivelDoAviso(WidgetTester t) => t
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(TelaConversa.chaveAviso),
            matching: find.byType(Text),
          ),
        )
        .map((Text x) => x.data ?? x.textSpan?.toPlainText() ?? '')
        .join(' ');

    // ⚠️ Os tres portoes abaixo existem porque a FR-022 nao e a FR-027: nao
    // estourar e a lista ter 48 px nao significa que a conversa ocupa metade
    // da tela. Aviso sempre expandido passa na FR-027 e reprova aqui.
    for (final Size aparelho in aparelhos) {
      for (final double escala in <double>[1.0, 1.5]) {
        final String nome = '${nomeDo(aparelho)}, escala $escala';

        testWidgets('antes da primeira mensagem o aviso esta aberto e cabe '
            'em metade da tela, em $nome', (WidgetTester t) async {
          final ControladorConversa c = controladorCom();
          addTearDown(c.dispose);
          await montar(t, c, escala: escala, aparelho: aparelho);
          expect(t.takeException(), isNull);

          final double total = disponivel(t, aparelho);
          final Rect aviso = t.getRect(find.byKey(TelaConversa.chaveAviso));

          expect(find.text(TextosAssistente.tituloAvisoAntigolpe),
              findsOneWidget,
              reason: 'o titulo do aviso esta sempre presente');
          expect(find.byKey(AvisoCompacto.chaveTextoCompleto), findsOneWidget,
              reason: 'ate a primeira mensagem o aviso fica aberto');
          expect(aviso.height, greaterThan(MemoraDimensoes.alvoMinimo),
              reason: 'sanidade: um aviso de altura zero passaria em tudo');
          expect(aviso.height, lessThanOrEqualTo(total * 0.5),
              reason: 'aberto, o aviso ocupa no maximo metade da altura '
                  'disponivel ($nome)');
          expect(aparelho.height - aviso.bottom,
              greaterThanOrEqualTo(total * 0.5),
              reason: 'lista + campo de escrever precisam de pelo menos '
                  'metade da altura disponivel ($nome)');
        });

        testWidgets('depois da primeira pergunta o aviso vira so o escudo, que '
            'ainda diz "senha" e "codigo" ao leitor de tela, em $nome',
            (WidgetTester t) async {
          final SemanticsHandle h = t.ensureSemantics();
          final ControladorConversa c = controladorCom();
          addTearDown(c.dispose);
          await montar(t, c, escala: escala, aparelho: aparelho);
          await perguntar(t, 'como vejo as fotos do meu neto');
          expect(t.takeException(), isNull);

          expect(find.byKey(TelaConversa.chaveAviso), findsOneWidget);
          expect(find.byKey(AvisoCompacto.chaveTextoCompleto), findsNothing,
              reason: 'depois da primeira mensagem o aviso encolhe');

          // So o escudo: nenhum texto na tela, e o nucleo no rotulo.
          expect(textoVisivelDoAviso(t), isEmpty,
              reason: 'fechado, o aviso nao escreve nada: e so o escudo');
          expect(
            find.descendant(
              of: find.byKey(TelaConversa.chaveAviso),
              matching: find.byIcon(Icons.shield_outlined),
            ),
            findsOneWidget,
          );
          final String lido = rotuloDoEscudo(t);
          expect(lido, contains('senha'), reason: 'o rotulo do escudo (FR-049)');
          expect(lido, contains('código'), reason: 'o rotulo do escudo (FR-049)');

          final double total = disponivel(t, aparelho);
          final Rect aviso = t.getRect(find.byKey(TelaConversa.chaveAviso));
          expect(aviso.height, lessThanOrEqualTo(MemoraDimensoes.alvoMinimo),
              reason: 'o escudo devolve o espaco a conversa: so o alvo de '
                  'toque, sem moldura nem respiro ($nome)');
          expect(aparelho.height - aviso.bottom,
              greaterThanOrEqualTo(total * 0.5),
              reason: 'lista + campo de escrever com pelo menos metade da '
                  'altura disponivel ($nome)');
          h.dispose();
        });
      }
    }

    // O resumo fechado e o que a maioria le: precisa valer tambem em 200%.
    for (final Size aparelho in aparelhos) {
      testWidgets('fechado, o escudo nao estoura nem espreme a lista em '
          '${nomeDo(aparelho)}, escala 2.0', (WidgetTester t) async {
        final SemanticsHandle h = t.ensureSemantics();
        final ControladorConversa c = controladorCom();
        addTearDown(c.dispose);
        await montar(t, c, escala: 2.0, aparelho: aparelho);
        await perguntar(t, 'como vejo as fotos do meu neto');

        expect(t.takeException(), isNull);
        expect(rotuloDoEscudo(t), contains('código'));
        expect(t.getSize(find.byType(ListView).first).height,
            greaterThanOrEqualTo(48));
        h.dispose();
      });
    }

    testWidgets('nunca some: nem depois de varias mensagens, nem por gesto', (
      WidgetTester t,
    ) async {
      final ControladorConversa c = controladorCom();
      addTearDown(c.dispose);
      await montar(t, c);
      await perguntar(t, 'como vejo as fotos do meu neto');
      await perguntar(t, 'nao consegui achar');
      await perguntar(t, 'como mando mensagem');

      expect(find.byKey(TelaConversa.chaveAviso), findsOneWidget);
      expect(find.byType(Dismissible), findsNothing,
          reason: 'ninguem manda o aviso embora arrastando');

      // Tocar abre; tocar de novo encolhe. Em nenhum momento o aviso sai.
      await t.tap(find.byKey(AvisoCompacto.chaveAlternar));
      await avancar(t);
      expect(find.byKey(AvisoCompacto.chaveTextoCompleto), findsOneWidget);
      expect(
        find.textContaining(TextosAssistente.avisoAntigolpe),
        findsOneWidget,
      );
      // Os dois avisos inteiros, na mesma caixa: o do golpe e o de privacidade.
      expect(
        find.textContaining(TextosAssistente.avisoPrivacidade),
        findsOneWidget,
      );
      expect(find.text(AvisoCompacto.rotuloFechar), findsOneWidget);
      await t.tap(find.byKey(AvisoCompacto.chaveAlternar));
      await avancar(t);
      // De volta ao escudo — e so ele.
      expect(find.byKey(TelaConversa.chaveAviso), findsOneWidget);
      expect(find.byKey(AvisoCompacto.chaveTextoCompleto), findsNothing);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });

    testWidgets('o escudo tem alvo de toque de 48 dp, em qualquer escala', (
      WidgetTester t,
    ) async {
      for (final double escala in <double>[1.0, 2.0]) {
        final ControladorConversa c = controladorCom();
        addTearDown(c.dispose);
        await montar(t, c, escala: escala);
        await perguntar(t, 'como vejo as fotos do meu neto');

        final Size escudo = t.getSize(find.byKey(AvisoCompacto.chaveAlternar));
        expect(escudo.width, greaterThanOrEqualTo(MemoraDimensoes.alvoMinimo));
        expect(escudo.height, greaterThanOrEqualTo(MemoraDimensoes.alvoMinimo));
        // No canto: encostado no lado direito, e nao no meio da faixa.
        final Rect aviso = t.getRect(find.byKey(TelaConversa.chaveAviso));
        expect(t.getRect(find.byKey(AvisoCompacto.chaveAlternar)).right,
            closeTo(aviso.right, 0.5),
            reason: 'o escudo fica no canto direito');
        // Desmonta a tela antes da proxima rodada.
        await t.pumpWidget(const SizedBox());
      }
    });

    testWidgets('o aviso fechado e um botao de verdade para o leitor de tela',
        (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      final ControladorConversa c = controladorCom();
      addTearDown(c.dispose);
      await montar(t, c);
      await perguntar(t, 'como vejo as fotos do meu neto');

      final SemanticsData dados =
          t.getSemantics(find.byKey(AvisoCompacto.chaveAlternar))
              .getSemanticsData();
      expect(dados.flagsCollection.isButton, isTrue);
      expect(dados.hasAction(SemanticsAction.tap), isTrue,
          reason: 'sem onTap o TalkBack anuncia o botao e nao ativa nada');
      expect(dados.label, contains('código'));
      expect(dados.label, contains('senha'));
      expect(dados.hint, AvisoCompacto.rotuloAbrir);
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      h.dispose();
    });
  });

  group('A explicacao do aceite — FR-051 com FR-026 e FR-027', () {
    testWidgets('os dois botoes atendem a diretriz de 48 dp',
        (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      final ControladorConversa c = controladorCom(aceito: false);
      addTearDown(c.dispose);
      await montar(t, c);

      expect(find.byKey(TelaConversa.chaveAceite), findsOneWidget);
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      h.dispose();
    });

    for (final Size aparelho in aparelhos) {
      final String nome = nomeDo(aparelho);

      for (final double escala in <double>[1.0, 1.5, 2.0]) {
        testWidgets('segue utilizavel em $nome, escala $escala',
            (WidgetTester t) async {
          final ControladorConversa c = controladorCom(aceito: false);
          addTearDown(c.dispose);
          await montar(t, c, escala: escala, aparelho: aparelho);

          expect(t.takeException(), isNull,
              reason: 'nada pode estourar a tela em $nome a $escala');

          final double alturaDaLista =
              t.getSize(find.byType(ListView).first).height;
          expect(alturaDaLista, greaterThanOrEqualTo(48),
              reason: 'a explicacao precisa de espaco para ser lida; em '
                  '$nome a $escala sobraram '
                  '${alturaDaLista.toStringAsFixed(0)} px');

          // A explicacao e lida do comeco: o titulo esta a vista, sem a
          // pessoa precisar rolar. A lista nao desce ao fim sozinha, como faz
          // com as mensagens — levaria direto aos botoes, sem o texto.
          final Finder titulo = find.text(TextosAssistente.tituloAceite);
          expect(titulo, findsOneWidget);
          expect(t.getRect(titulo).top, greaterThanOrEqualTo(0));
          expect(t.getRect(titulo).bottom, lessThanOrEqualTo(aparelho.height));

          // Os dois botoes alcancaveis: sem isso a pessoa nao consegue nem
          // aceitar nem recusar, e fica presa na explicacao.
          for (final Key chave in <Key>[
            TelaConversa.chaveAceitar,
            TelaConversa.chaveRecusarAceite,
          ]) {
            final Finder botao = find.byKey(chave);
            await t.ensureVisible(botao);
            await t.pump();
            final Rect r = t.getRect(botao);
            expect(r.top, greaterThanOrEqualTo(0));
            expect(r.bottom, lessThanOrEqualTo(aparelho.height),
                reason: 'o botao $chave ficou fora da tela em $nome a '
                    '$escala');
          }
        });
      }
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

  group('Estado "respondendo" e perceptivel — FR-029 e FR-020b', () {
    testWidgets(
        'enquanto a Memora responde, a espera e so o balao dela se formando — '
        'escrita e anunciada, nao so o movimento', (WidgetTester t) async {
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

      // Nenhuma frase de espera embaixo do campo (FR-020b): a espera e o balao.
      expect(find.byType(Carregando), findsNothing);
      expect(find.textContaining('Estou pensando'), findsNothing);

      // O balao escrevendo diz o estado por escrito e para o leitor de tela,
      // sem depender de animacao nem de cor (FR-029).
      expect(find.text('• • •  ${BalaoDeFala.textoEscrevendo}'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Memora está ${BalaoDeFala.textoEscrevendo}'),
        findsOneWidget,
      );

      // O campo e o botao ficam NO LUGAR, desabilitados: a faixa de baixo nao
      // muda de altura nem de conteudo enquanto a Memora responde.
      expect(
        t.widget<TextField>(
          find.descendant(
            of: find.byKey(TelaConversa.chaveCampo),
            matching: find.byType(TextField),
          ),
        ).enabled,
        isFalse,
      );
      expect(find.byKey(TelaConversa.chaveEnviar), findsOneWidget);
      expect(
        t.widget<BotaoPrimario>(find.byKey(TelaConversa.chaveEnviar)).aoTocar,
        isNull,
      );

      // Drena o timer da demora simulada — senao "A Timer is still pending"
      // reprova o teste, mesmo com o corpo ja verificado.
      await t.pump(const Duration(milliseconds: 350));
      await avancar(t);
      await esperarAEscrita(t);
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
