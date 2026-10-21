import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/conversa_local.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/assistente/presentation/controladores/controlador_conversa.dart';
import 'package:memora/features/assistente/presentation/telas/tela_conversa.dart';
import 'package:memora/features/casca/casca_interna.dart';
import 'package:memora/l10n/textos_assistente.dart';
import '../../suporte/aceite_em_memoria.dart';

import '../../suporte/aparelhos.dart';
import '../../suporte/estados_de_tela.dart';

/// Cenario H2 do quickstart — a assistente ensina antes de oferecer fazer.
///
/// ## O portao que este arquivo protege
///
/// A FR-014 e o Principio VII virando codigo: a oferta de executar so aparece
/// depois de a pessoa declarar dificuldade. Uma assistente que oferece de cara
/// entrega o resultado de hoje e nenhuma autonomia amanha — e o produto perde a
/// razao de existir.
///
/// ## Duas armadilhas que este arquivo evita, e que ja morderam o projeto
///
/// 1. `pumpAndSettle` **trava** com o `Carregando` na tela: ele anima sem
///    parar, e o metodo espera uma quietude que nunca chega.
/// 2. I/O de arquivo **de verdade** nao completa dentro de `testWidgets`, onde
///    o relogio e falso — o caso morre em "did not complete" depois de minutos,
///    sem apontar a causa. Por isso o disco e testado em `test` puro, e o teste
///    de widget usa um dublê em memoria.
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

  ControladorConversa controladorCom({FalhaDaAssistente? falha}) {
    return ControladorConversa(
      RepositorioAssistenteSimulado(demora: Duration.zero, falhaForcada: falha),
      local,
      aceite: AceiteEmMemoria(),
    );
  }

  /// Bombeia alguns quadros SEM esperar a arvore assentar. Ver a nota acima.
  Future<void> avancar(WidgetTester t) async {
    for (int quadro = 0; quadro < 6; quadro++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> montar(WidgetTester t, ControladorConversa c) async {
    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        home: TelaConversa(controlador: c),
      ),
    );
    await avancar(t);
  }

  /// Volta a lista ao topo: ela e preguicosa, e depois de uma pergunta so o
  /// fim esta construido.
  Future<void> irAoTopo(WidgetTester t) async {
    t.state<ScrollableState>(
      find.descendant(
        of: find.byType(ListView).first,
        matching: find.byType(Scrollable),
      ).first,
    ).position.jumpTo(0);
    await t.pump();
  }

  Future<void> perguntar(WidgetTester t, String texto) async {
    await t.enterText(find.byKey(TelaConversa.chaveCampo), texto);
    await avancar(t);
    final Finder enviar = find.byKey(TelaConversa.chaveEnviar);
    await t.ensureVisible(enviar);
    await t.tap(enviar);
    await avancar(t);
  }

  group('H2 — ensinar vem antes de fazer (FR-014)', () {
    testWidgets('a primeira resposta ensina e NAO oferece abrir nada', (
      WidgetTester t,
    ) async {
      final ControladorConversa c = controladorCom();
      addTearDown(c.dispose);
      await montar(t, c);

      await perguntar(t, 'como vejo as fotos do meu neto');

      // Este e o portao. Uma oferta aqui significaria que a Memora resolve em
      // vez de ensinar.
      expect(c.acaoOferecida, isNull);
      expect(find.byKey(TelaConversa.chaveConfirmarAbrir), findsNothing);
    });

    testWidgets('a oferta aparece quando a pessoa declara dificuldade', (
      WidgetTester t,
    ) async {
      final ControladorConversa c = controladorCom();
      addTearDown(c.dispose);
      await montar(t, c);

      await perguntar(t, 'nao consegui achar');

      // Sem este caso, um controlador que nunca oferecesse nada passaria no
      // teste acima — e a US3 ficaria sem saida para quem nao consegue.
      expect(c.acaoOferecida, isNotNull);
      expect(find.byKey(TelaConversa.chaveConfirmarAbrir), findsOneWidget);
    });

    testWidgets('recusar encerra o assunto, e a oferta nao volta (FR-016)', (
      WidgetTester t,
    ) async {
      final ControladorConversa c = controladorCom();
      addTearDown(c.dispose);
      await montar(t, c);
      await perguntar(t, 'nao consegui achar');

      c.recusarAcao();
      await avancar(t);

      expect(c.acaoOferecida, isNull);
      expect(find.byKey(TelaConversa.chaveConfirmarAbrir), findsNothing);
    });

    testWidgets('servico sensivel nunca vira oferta (FR-041)', (
      WidgetTester t,
    ) async {
      final ControladorConversa c = controladorCom();
      addTearDown(c.dispose);
      await montar(t, c);

      await perguntar(t, 'abre o banco pra mim');

      expect(c.acaoOferecida, isNull);
    });
  });

  group('FR-033 — o aviso antigolpe e permanente', () {
    testWidgets('esta na tela desde antes da primeira pergunta', (
      WidgetTester t,
    ) async {
      final ControladorConversa c = controladorCom();
      addTearDown(c.dispose);
      await montar(t, c);

      expect(find.byKey(TelaConversa.chaveAviso), findsOneWidget);
    });

    testWidgets('continua la depois de a conversa acontecer', (
      WidgetTester t,
    ) async {
      final ControladorConversa c = controladorCom();
      addTearDown(c.dispose);
      await montar(t, c);

      await perguntar(t, 'como mando mensagem');

      // Quem esta sendo enganado ao telefone chega ao campo de escrever. Um
      // aviso que some depois da primeira resposta nao estaria la no momento em
      // que a pergunta e feita.
      expect(find.byKey(TelaConversa.chaveAviso), findsOneWidget);
    });

    test('avisa sobre a senha E sobre o numero', () {
      expect(TextosAssistente.avisoAntigolpe.toLowerCase(), contains('senha'));
      expect(TextosAssistente.avisoAntigolpe.toLowerCase(), contains('número'));
    });
  });

  group('Quem disse o que — FR-020', () {
    testWidgets('cada fala e um balao com posicao, rosto e nome', (
      WidgetTester t,
    ) async {
      final ControladorConversa c = controladorCom();
      addTearDown(c.dispose);
      await montar(t, c);
      await perguntar(t, 'como vejo as fotos do meu neto');
      await irAoTopo(t);

      // O convite da Memora vem antes de tudo: o resto e a conversa.
      final Finder baloes = find.byType(BalaoDeFala);
      expect(baloes, findsNWidgets(2));
      // A ordem na lista e a ordem da conversa: a pessoa perguntou primeiro.
      final Finder daPessoa = baloes.at(0);
      final Finder dela = baloes.at(1);
      expect(t.widget<BalaoDeFala>(daPessoa).autor, AutorDoBalao.pessoa);
      expect(t.widget<BalaoDeFala>(dela).autor, AutorDoBalao.memora);

      // Nome escrito, nunca so a cor.
      final Finder nomeDela = find.descendant(
        of: dela,
        matching: find.text('Memora'),
      );
      final Finder nomeDaPessoa = find.descendant(
        of: daPessoa,
        matching: find.text('Você'),
      );
      expect(nomeDela, findsOneWidget);
      expect(nomeDaPessoa, findsOneWidget);

      // Desenho: o rosto da Memora de um lado, o da pessoa do outro.
      expect(
        find.descendant(of: dela, matching: find.byType(MemoraPersonagem)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: daPessoa, matching: find.byType(MemoraPersonagem)),
        findsNothing,
      );
      expect(
        find.descendant(of: daPessoa, matching: find.byIcon(Icons.person)),
        findsOneWidget,
      );

      // Posicao: a Memora a esquerda, a pessoa a direita.
      expect(t.getCenter(nomeDaPessoa).dx, greaterThan(t.getCenter(nomeDela).dx));
    });

    testWidgets('o leitor de tela ouve "Memora disse" e "Você disse"', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      final ControladorConversa c = controladorCom();
      addTearDown(c.dispose);
      await montar(t, c);
      await perguntar(t, 'como vejo as fotos do meu neto');
      await irAoTopo(t);

      expect(find.bySemanticsLabel(RegExp(r'^Você disse: ')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Memora disse: ')), findsOneWidget);
      h.dispose();
    });
  });

  group('A oferta e as opcoes — FR-021', () {
    testWidgets('as opcoes tem 56 dp, ocupam a largura e ficam afastadas', (
      WidgetTester t,
    ) async {
      final ControladorConversa c = controladorCom();
      addTearDown(c.dispose);
      await montar(t, c);
      await perguntar(t, 'nao consegui achar');

      final Finder confirmar = find.descendant(
        of: find.byKey(TelaConversa.chaveConfirmarAbrir),
        matching: find.byType(BotaoPrimario),
      );
      final Finder recusar = find.descendant(
        of: find.byKey(TelaConversa.chaveConfirmarAbrir),
        matching: find.byType(BotaoSecundario),
      );
      await t.ensureVisible(recusar);
      await t.pump();

      final Rect a = t.getRect(confirmar);
      final Rect b = t.getRect(recusar);
      expect(a.height, greaterThanOrEqualTo(MemoraDimensoes.alvoDecisao));
      expect(b.height, greaterThanOrEqualTo(MemoraDimensoes.alvoDecisao));
      expect(
        b.top - a.bottom,
        greaterThanOrEqualTo(MemoraEspacamento.md),
        reason: 'empilhadas e afastadas: o toque errado e questao de tempo',
      );
      expect(a.width, closeTo(b.width, 0.5), reason: 'largura inteira');
    });
  });

  group('Os estados da FR-006', () {
    testWidgets('carregando, vazio e erro tem desenho e frase', (
      WidgetTester t,
    ) async {
      // Os controladores ficam prontos ANTES: o `montar` do portao e sincrono.
      final ControladorConversa vazio = controladorCom();
      addTearDown(vazio.dispose);

      final ControladorConversa comErro = controladorCom(
        falha: FalhaDaAssistente.semConexao,
      );
      addTearDown(comErro.dispose);
      await comErro.iniciar();
      comErro.escrever('oi');
      await comErro.enviar();
      expect(comErro.mensagemDeErro, isNotNull);

      final ControladorConversa esperando = ControladorConversa(
        aceite: AceiteEmMemoria(),
        RepositorioAssistenteSimulado(demora: const Duration(seconds: 1)),
        local,
      );
      addTearDown(esperando.dispose);
      await esperando.iniciar();
      esperando.escrever('oi');
      // Sem await: a resposta so chega com o tempo que o teste vai drenar.
      final Future<void> resposta = esperando.enviar();
      expect(esperando.respondendo, isTrue);

      Widget tela(ControladorConversa c) => MaterialApp(
        theme: TemasMemora.claro,
        home: TelaConversa(controlador: c),
      );

      await exigirOsEstadosDaFr006(
        t,
        tela: 'TelaConversa',
        montar: (EstadoDaTela estado) => switch (estado) {
          EstadoDaTela.carregando => tela(esperando),
          EstadoDaTela.vazio => tela(vazio),
          EstadoDaTela.erro => tela(comErro),
        },
      );

      await t.pump(const Duration(seconds: 2));
      await resposta;
    });

    testWidgets('o vazio e a Memora convidando, e nao uma area em branco', (
      WidgetTester t,
    ) async {
      final ControladorConversa c = controladorCom();
      addTearDown(c.dispose);
      await montar(t, c);

      expect(find.text(TextosAssistente.convite), findsOneWidget);
      expect(find.byType(MemoraPersonagem), findsWidgets);
    });
  });

  group('Teclado aberto — FR-015, T056', () {
    // A conversa DENTRO da casca, como no aplicativo: o `Scaffold` tira o
    // teclado do `MediaQuery` do corpo, e testar a tela sozinha nao provaria
    // a barra que sai nem o campo que sobe.
    Future<void> montarNaCasca(
      WidgetTester t,
      ControladorConversa c,
      Size aparelho,
    ) async {
      vestir(t, aparelho);
      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: CascaInterna(
            aoRegistrarAtividade: () {},
            raizes: <DestinoDaCasca, WidgetBuilder>{
              DestinoDaCasca.ajustes: (_) => const SizedBox(),
              DestinoDaCasca.inicio: (_) => TelaConversa(controlador: c),
              DestinoDaCasca.perfil: (_) => const SizedBox(),
            },
          ),
        ),
      );
      await avancar(t);
    }

    /// O campo de digitar (o `TextField` de dentro do `CampoTexto`) e a faixa
    /// que o contem, que rola quando passa do teto.
    Finder entrada() => find.descendant(
      of: find.byKey(TelaConversa.chaveCampo),
      matching: find.byType(TextField),
    );
    Finder faixa() => find
        .ancestor(
          of: find.byKey(TelaConversa.chaveCampo),
          matching: find.byType(SingleChildScrollView),
        )
        .first;

    /// O teclado sobe e o campo e trazido para dentro da faixa — o que o
    /// framework faz sozinho quando a pessoa toca nele para escrever.
    Future<void> abrirOTeclado(WidgetTester t) async {
      t.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(t.view.resetViewInsets);
      await avancar(t);
      await t.ensureVisible(entrada());
      await avancar(t);
    }

    void exigirOCampoVisivel(WidgetTester t, Size aparelho) {
      final double topoDoTeclado = aparelho.height - 300;
      final Rect digitar = t.getRect(entrada());
      final Rect area = t.getRect(faixa());
      expect(
        digitar.bottom,
        lessThanOrEqualTo(topoDoTeclado),
        reason: 'o campo nao pode ficar atras do teclado',
      );
      expect(
        digitar.top,
        greaterThanOrEqualTo(area.top),
        reason: 'nem rolado para fora da faixa que o contem',
      );
      expect(digitar.bottom, lessThanOrEqualTo(area.bottom));
    }

    // O teclado de um Android ocupa cerca de 300 dp. Os dois aparelhos mais
    // comuns da matriz: o 360x800 (Galaxy A/M) e o 390x844.
    for (final Size aparelho in const <Size>[Size(360, 800), referencia]) {
      testWidgets(
        'a barra sai, e a ultima mensagem e o campo seguem visiveis em '
        '${nomeDo(aparelho)}',
        (WidgetTester t) async {
          final ControladorConversa c = controladorCom();
          addTearDown(c.dispose);
          await montarNaCasca(t, c, aparelho);
          await perguntar(t, 'como vejo as fotos do meu neto');
          await perguntar(t, 'como mando mensagem');
          await perguntar(t, 'como faco uma ligacao');
          // Sem oferta no fim: a ultima fala e um balao.
          expect(c.acaoOferecida, isNull);
          expect(find.byKey(CascaInterna.chaveDaBarra), findsOneWidget);

          await abrirOTeclado(t);

          expect(t.takeException(), isNull);
          expect(
            find.byKey(CascaInterna.chaveDaBarra),
            findsNothing,
            reason: 'com o teclado aberto, a barra libera a altura',
          );
          exigirOCampoVisivel(t, aparelho);

          // O FIM da ultima fala continua a vista, dentro da lista: sem rolar
          // de novo quando o teclado sobe, ela ficava atras do campo. So o
          // fim, de proposito: a lista encolhe com o teclado, e uma resposta
          // longa nao cabe inteira num pedaco de tela — o que importa e que
          // as ultimas palavras estejam la, e nao escondidas.
          final Rect lista = t.getRect(find.byType(ListView).first);
          final Rect ultima = t.getRect(find.byType(BalaoDeFala).last);
          expect(ultima.bottom, lessThanOrEqualTo(lista.bottom));
          expect(ultima.bottom, greaterThan(lista.top + 24));
          expect(lista.bottom, lessThanOrEqualTo(t.getRect(faixa()).top));
        },
      );
    }

    testWidgets(
      'em 360x640 com o aviso aberto, o teclado nao estoura a tela',
      (WidgetTester t) async {
        final ControladorConversa c = controladorCom();
        addTearDown(c.dispose);
        await montarNaCasca(t, c, const Size(360, 640));
        t.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(t.view.resetViewInsets);
        await avancar(t);

        expect(t.takeException(), isNull);
        expect(find.byKey(CascaInterna.chaveDaBarra), findsNothing);
        expect(find.byKey(TelaConversa.chaveAviso), findsOneWidget);
      },
    );
  });

  group('A conversa e retomada — FR-049 e FR-050', () {
    testWidgets('reabrir o aplicativo traz a conversa de volta', (
      WidgetTester t,
    ) async {
      final ControladorConversa primeira = controladorCom();
      addTearDown(primeira.dispose);
      await montar(t, primeira);
      await perguntar(t, 'como mando mensagem');

      final int quantas = primeira.mensagens.length;
      expect(quantas, greaterThan(0));

      // Outro controlador, mesmo armazenamento — como reabrir o aplicativo.
      final ControladorConversa segunda = controladorCom();
      addTearDown(segunda.dispose);
      await segunda.iniciar();

      expect(segunda.mensagens, hasLength(quantas));
    });

    testWidgets('apagar a conversa apaga mesmo', (WidgetTester t) async {
      final ControladorConversa c = controladorCom();
      addTearDown(c.dispose);
      await montar(t, c);
      await perguntar(t, 'como mando mensagem');

      await c.apagarConversa();
      await avancar(t);

      expect(c.mensagens, isEmpty);
      expect(await local.ler(), isEmpty);
    });
  });

  group('Falhas', () {
    testWidgets('o limite diario aparece sem culpar a pessoa', (
      WidgetTester t,
    ) async {
      final ControladorConversa c = controladorCom(
        falha: FalhaDaAssistente.limiteDeConversas,
      );
      addTearDown(c.dispose);
      await montar(t, c);

      await perguntar(t, 'oi');

      expect(c.mensagemDeErro, TextosAssistente.limiteDeConversas);
      // Quem esbarra no teto nao errou nada — so conversou bastante.
      expect(c.mensagemDeErro!.toLowerCase(), isNot(contains('erro')));
      expect(c.mensagemDeErro!.toLowerCase(), isNot(contains('excedeu')));
    });
  });

  // ---------------------------------------------------------------------------
  // Estes usam DISCO DE VERDADE, e por isso sao `test` e nao `testWidgets`.
  // ---------------------------------------------------------------------------
  group('ConversaLocal — o arquivo no aparelho (FR-047)', () {
    late Directory temporario;
    late ConversaLocal disco;

    setUp(() async {
      temporario = await Directory.systemTemp.createTemp('memora_conversa');
      disco = ConversaLocal(diretorio: () async => temporario);
    });

    tearDown(() async {
      try {
        await temporario.delete(recursive: true);
      } on FileSystemException {
        // No Windows o arquivo as vezes ainda esta preso por outro processo.
        // Diretorio temporario que nao apaga nao invalida teste nenhum.
      }
    });

    test('apagar sem conversa guardada não é falha', () async {
      await disco.apagar();
    });

    test(
      'apagar que o aparelho recusa SOBE, em vez de fingir que apagou',
      () async {
        // Um diretório no lugar do arquivo: `delete` falha por outro motivo que
        // não "não existe".
        await Directory(
          '${temporario.path}/${ConversaLocal.nomeDoArquivo}',
        ).create();

        await expectLater(disco.apagar(), throwsA(isA<FileSystemException>()));
      },
    );

    test('conversa vazia quando nunca houve arquivo', () async {
      expect(await disco.ler(), isEmpty);
    });

    test('o que foi guardado volta igual', () async {
      await disco.guardar(<MensagemDaConversa>[
        MensagemDaConversa(
          autor: AutorDaMensagem.pessoa,
          texto: 'como vejo as fotos',
          momento: DateTime(2026, 8, 29, 10, 30),
        ),
        MensagemDaConversa(
          autor: AutorDaMensagem.memora,
          texto: 'vamos juntas, um passo de cada vez',
          momento: DateTime(2026, 8, 29, 10, 31),
        ),
      ]);

      final List<MensagemDaConversa> lida = await disco.ler();

      expect(lida, hasLength(2));
      expect(lida.first.autor, AutorDaMensagem.pessoa);
      expect(lida.last.texto, 'vamos juntas, um passo de cada vez');
    });

    test('apagar remove o arquivo (FR-048)', () async {
      await disco.guardar(<MensagemDaConversa>[
        MensagemDaConversa(
          autor: AutorDaMensagem.pessoa,
          texto: 'oi',
          momento: DateTime(2026, 8, 29),
        ),
      ]);

      await disco.apagar();

      expect(await disco.ler(), isEmpty);
      expect(
        File('${temporario.path}/${ConversaLocal.nomeDoArquivo}').existsSync(),
        isFalse,
      );
    });

    test('arquivo corrompido nao impede conversar de novo', () async {
      await File(
        '${temporario.path}/${ConversaLocal.nomeDoArquivo}',
      ).writeAsString('isto nao e json');

      // Perder a conversa e aceitavel; ficar sem assistente nao e.
      expect(await disco.ler(), isEmpty);
    });

    test('guarda apenas os turnos mais recentes', () async {
      await disco.guardar(<MensagemDaConversa>[
        for (int i = 0; i < ConversaLocal.turnosGuardados + 10; i++)
          MensagemDaConversa(
            autor: AutorDaMensagem.pessoa,
            texto: 'mensagem $i',
            momento: DateTime(2026, 8, 29).add(Duration(minutes: i)),
          ),
      ]);

      final List<MensagemDaConversa> lida = await disco.ler();

      expect(lida, hasLength(ConversaLocal.turnosGuardados));
      // Corta pelo comeco: numa conversa longa, o que importa e o fim.
      expect(lida.last.texto, endsWith('${ConversaLocal.turnosGuardados + 9}'));
    });
  });
}
