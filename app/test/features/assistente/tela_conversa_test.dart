import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/conversa_local.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/assistente/presentation/controladores/controlador_conversa.dart';
import 'package:memora/features/assistente/presentation/telas/tela_conversa.dart';
import 'package:memora/l10n/textos_assistente.dart';

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

  Future<void> perguntar(WidgetTester t, String texto) async {
    await t.enterText(find.byKey(TelaConversa.chaveCampo), texto);
    await avancar(t);
    final Finder enviar = find.byKey(TelaConversa.chaveEnviar);
    await t.ensureVisible(enviar);
    await t.tap(enviar);
    await avancar(t);
  }

  group('H2 — ensinar vem antes de fazer (FR-014)', () {
    testWidgets('a primeira resposta ensina e NAO oferece abrir nada',
        (WidgetTester t) async {
      final ControladorConversa c = controladorCom();
      addTearDown(c.dispose);
      await montar(t, c);

      await perguntar(t, 'como vejo as fotos do meu neto');

      // Este e o portao. Uma oferta aqui significaria que a Memora resolve em
      // vez de ensinar.
      expect(c.acaoOferecida, isNull);
      expect(find.byKey(TelaConversa.chaveConfirmarAbrir), findsNothing);
    });

    testWidgets('a oferta aparece quando a pessoa declara dificuldade',
        (WidgetTester t) async {
      final ControladorConversa c = controladorCom();
      addTearDown(c.dispose);
      await montar(t, c);

      await perguntar(t, 'nao consegui achar');

      // Sem este caso, um controlador que nunca oferecesse nada passaria no
      // teste acima — e a US3 ficaria sem saida para quem nao consegue.
      expect(c.acaoOferecida, isNotNull);
      expect(find.byKey(TelaConversa.chaveConfirmarAbrir), findsOneWidget);
    });

    testWidgets('recusar encerra o assunto, e a oferta nao volta (FR-016)',
        (WidgetTester t) async {
      final ControladorConversa c = controladorCom();
      addTearDown(c.dispose);
      await montar(t, c);
      await perguntar(t, 'nao consegui achar');

      c.recusarAcao();
      await avancar(t);

      expect(c.acaoOferecida, isNull);
      expect(find.byKey(TelaConversa.chaveConfirmarAbrir), findsNothing);
    });

    testWidgets('servico sensivel nunca vira oferta (FR-041)',
        (WidgetTester t) async {
      final ControladorConversa c = controladorCom();
      addTearDown(c.dispose);
      await montar(t, c);

      await perguntar(t, 'abre o banco pra mim');

      expect(c.acaoOferecida, isNull);
    });
  });

  group('FR-033 — o aviso antigolpe e permanente', () {
    testWidgets('esta na tela desde antes da primeira pergunta',
        (WidgetTester t) async {
      final ControladorConversa c = controladorCom();
      addTearDown(c.dispose);
      await montar(t, c);

      expect(find.byKey(TelaConversa.chaveAviso), findsOneWidget);
    });

    testWidgets('continua la depois de a conversa acontecer',
        (WidgetTester t) async {
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

  group('A conversa e retomada — FR-049 e FR-050', () {
    testWidgets('reabrir o aplicativo traz a conversa de volta',
        (WidgetTester t) async {
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
    testWidgets('o limite diario aparece sem culpar a pessoa',
        (WidgetTester t) async {
      final ControladorConversa c =
          controladorCom(falha: FalhaDaAssistente.limiteDeConversas);
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
      await File('${temporario.path}/${ConversaLocal.nomeDoArquivo}')
          .writeAsString('isto nao e json');

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
