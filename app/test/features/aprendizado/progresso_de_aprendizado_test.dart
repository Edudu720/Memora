import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/aprendizado/data/progresso_de_aprendizado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/autenticacao/domain/autenticacao.dart';
import 'package:memora/services/ambiente/ambiente.dart';
import 'package:memora/services/ambiente/composicao.dart';
import '../autenticacao/dubles_autenticacao.dart';
import 'package:memora/services/seguranca/cofre_de_credenciais.dart';
import 'package:memora/services/seguranca/limpeza_de_sessao.dart';

/// O progresso de aprendizado (T062, T064; FR-042a, FR-042b).
///
/// É `test` puro, com disco de verdade: I/O de arquivo real não completa dentro
/// de `testWidgets`, onde o relógio é falso (CLAUDE.md, seção 8).
void main() {
  // A Composicao monta a ConversaLocal, que pergunta o diretório à plataforma.
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory pasta;
  late ProgressoDeAprendizado progresso;

  setUp(() {
    pasta = Directory.systemTemp.createTempSync('memora_progresso_');
    progresso = ProgressoDeAprendizado(diretorio: () async => pasta);
  });

  tearDown(() {
    if (pasta.existsSync()) pasta.deleteSync(recursive: true);
  });

  File arquivo() =>
      File('${pasta.path}/${ProgressoDeAprendizado.nomeDoArquivo}');

  Future<void> concluir(String conta, String chave, [int vezes = 1]) async {
    for (int i = 0; i < vezes; i++) {
      await progresso.registrarConclusao(idDaConta: conta, chave: chave);
    }
  }

  group('o que conta', () {
    test('só a chegada ao ÚLTIMO passo conta', () async {
      for (int passo = 1; passo <= 4; passo++) {
        final bool contou = await progresso.registrarChegadaAoPasso(
          idDaConta: 'ana',
          chave: 'tiktok',
          numeroDoPasso: passo,
          totalDePassos: 5,
        );
        expect(contou, isFalse, reason: 'o passo $passo de 5 não é o último');
      }
      expect(await progresso.concluidos('ana'), isEmpty);

      final bool contou = await progresso.registrarChegadaAoPasso(
        idDaConta: 'ana',
        chave: 'tiktok',
        numeroDoPasso: 5,
        totalDePassos: 5,
      );

      expect(contou, isTrue);
      expect(await progresso.concluidos('ana'), <String, int>{'tiktok': 1});
    });

    test('refazer o guia soma de novo', () async {
      await concluir('ana', 'tiktok', 3);

      expect(await progresso.concluidos('ana'), <String, int>{'tiktok': 3});
    });

    test('cada conta tem o seu', () async {
      await concluir('ana', 'tiktok');
      await concluir('bia', 'youtube', 2);

      expect(await progresso.concluidos('ana'), <String, int>{'tiktok': 1});
      expect(await progresso.concluidos('bia'), <String, int>{'youtube': 2});
      expect(await progresso.concluidos('carla'), isEmpty);
    });

    test('id de conta vazio não identifica ninguém', () async {
      await expectLater(
        progresso.registrarConclusao(idDaConta: '  ', chave: 'tiktok'),
        throwsArgumentError,
      );
      expect(await progresso.concluidos(' '), isEmpty);
      expect(await progresso.aplicativoMaisAprendido(' '), isNull);
    });

    test('conclusões em rajada não se atropelam', () async {
      await Future.wait(<Future<void>>[
        for (int i = 0; i < 20; i++)
          progresso.registrarConclusao(idDaConta: 'ana', chave: 'tiktok'),
      ]);

      expect(await progresso.concluidos('ana'), <String, int>{'tiktok': 20});
    });

    test('sobrevive a uma nova instância: está no disco', () async {
      await concluir('ana', 'tiktok', 2);

      final ProgressoDeAprendizado outra = ProgressoDeAprendizado(
        diretorio: () async => pasta,
      );

      expect(await outra.concluidos('ana'), <String, int>{'tiktok': 2});
    });
  });

  group('o aplicativo mais aprendido', () {
    test('é o de maior contagem', () async {
      await concluir('ana', 'tiktok');
      await concluir('ana', 'whatsapp', 3);
      await concluir('ana', 'youtube', 2);

      expect(await progresso.aplicativoMaisAprendido('ana'), 'whatsapp');
    });

    test('em empate, fica o mais recente', () async {
      await concluir('ana', 'tiktok', 2);
      await concluir('ana', 'whatsapp', 2);
      expect(await progresso.aplicativoMaisAprendido('ana'), 'whatsapp');

      await concluir('ana', 'tiktok');
      expect(
        await progresso.aplicativoMaisAprendido('ana'),
        'tiktok',
        reason: '3 contra 2: a contagem vence a recência',
      );

      await concluir('ana', 'whatsapp');
      expect(
        await progresso.aplicativoMaisAprendido('ana'),
        'whatsapp',
        reason: '3 contra 3: empate, vence o concluído por último',
      );
    });

    test('o empate se decide pela ordem, não pela ordem alfabética', () async {
      // "whatsapp" > "tiktok" alfabeticamente; concluir o tiktok por último
      // precisa dar a ele.
      await concluir('ana', 'whatsapp');
      await concluir('ana', 'tiktok');

      expect(await progresso.aplicativoMaisAprendido('ana'), 'tiktok');
    });

    test('ausente quando a pessoa ainda não concluiu nada', () async {
      expect(await progresso.aplicativoMaisAprendido('ana'), isNull);

      await concluir('bia', 'tiktok');
      expect(
        await progresso.aplicativoMaisAprendido('ana'),
        isNull,
        reason: 'o progresso da bia não é o da ana',
      );
    });
  });

  group('arquivo estragado', () {
    test(
      'conteúdo ilegível vira progresso vazio, e a pessoa recomeça',
      () async {
        arquivo().writeAsStringSync('isto não é JSON');

        expect(await progresso.concluidos('ana'), isEmpty);
        await concluir('ana', 'tiktok');
        expect(await progresso.concluidos('ana'), <String, int>{'tiktok': 1});
      },
    );

    test('JSON de forma inesperada também', () async {
      arquivo().writeAsStringSync('[1, 2, 3]');
      expect(await progresso.aplicativoMaisAprendido('ana'), isNull);

      arquivo().writeAsStringSync('{"contas": {"ana": {"tiktok": "muitas"}}}');
      expect(await progresso.concluidos('ana'), isEmpty);
    });
  });

  group('FR-042b: sai do aparelho', () {
    test('apagar leva o progresso de todas as contas e o arquivo', () async {
      await concluir('ana', 'tiktok');
      await concluir('bia', 'youtube');
      expect(arquivo().existsSync(), isTrue);

      await progresso.apagar();

      expect(arquivo().existsSync(), isFalse);
      expect(await progresso.concluidos('ana'), isEmpty);
      expect(await progresso.concluidos('bia'), isEmpty);
    });

    test('apagar sem nada guardado não falha', () async {
      await progresso.apagar();
      await progresso.apagar();
    });

    test('não sobra rastro: nem arquivo temporário', () async {
      await concluir('ana', 'tiktok');
      await progresso.apagar();

      expect(pasta.listSync(), isEmpty);
    });

    test('a LimpezaDeSessao o apaga em toda saída, sem esquecerTudo', () async {
      await concluir('ana', 'tiktok');
      final LimpezaDeSessao limpeza = LimpezaDeSessao(
        cofre: _Cofre(),
        ultimoAcesso: UltimoAcessoEmMemoria(),
        dadosLocais: <DadoLocalDaPessoa>[progresso],
      );

      await limpeza.executar();

      expect(await progresso.concluidos('ana'), isEmpty);
      expect(arquivo().existsSync(), isFalse);
    });

    test('mesmo quando outro dado local falha antes dele', () async {
      await concluir('ana', 'tiktok');
      final LimpezaDeSessao limpeza = LimpezaDeSessao(
        cofre: _Cofre(),
        ultimoAcesso: UltimoAcessoEmMemoria(),
        dadosLocais: <DadoLocalDaPessoa>[_QueFalha(), progresso],
      );

      await limpeza.executar();

      expect(
        await progresso.concluidos('ana'),
        isEmpty,
        reason: 'a falha de um dado não pode poupar o progresso',
      );
    });
  });

  group('a Composicao', () {
    const Ambiente simulado = Ambiente(
      urlBase: 'http://10.0.2.2:8080/v1',
      usaServidorReal: false,
    );

    test(
      'liga o progresso a dadosLocais: a saída comum o leva (FR-042b)',
      () async {
        await concluir('ana', 'tiktok', 2);

        final Composicao composicao = Composicao.resolver(
          ambiente: simulado,
          cofre: _Cofre(),
          ultimoAcesso: UltimoAcessoEmMemoria(),
          progresso: progresso,
        );
        expect(
          composicao.progresso,
          same(progresso),
          reason: 'o Perfil e a saída precisam falar da mesma instância',
        );

        await composicao.limpeza.executar();

        expect(await progresso.concluidos('ana'), isEmpty);
        expect(arquivo().existsSync(), isFalse);
      },
    );

    test('concluir um guia não faz chamada alguma a repositório nem à rede '
        '(FR-042a)', () async {
      final _EspiaDeRepositorio assistente = _EspiaDeRepositorio();
      final _EspiaDeAutenticacao autenticacao = _EspiaDeAutenticacao();
      final Composicao composicao = Composicao(
        ambiente: simulado,
        autenticacao: autenticacao,
        assistente: assistente,
        limpeza: LimpezaDeSessao(
          cofre: _Cofre(),
          ultimoAcesso: UltimoAcessoEmMemoria(),
        ),
        progresso: progresso,
      );

      int clientesHttp = 0;
      await HttpOverrides.runZoned(
        () async {
          final ProgressoDeAprendizado dele = composicao.progresso!;
          await dele.registrarChegadaAoPasso(
            idDaConta: 'ana',
            chave: 'tiktok',
            numeroDoPasso: 4,
            totalDePassos: 4,
          );
          expect(await dele.aplicativoMaisAprendido('ana'), 'tiktok');
          await dele.concluidos('ana');
        },
        createHttpClient: (SecurityContext? contexto) {
          clientesHttp++;
          throw StateError('o progresso não pode abrir conexão');
        },
      );

      expect(
        assistente.chamadas,
        isEmpty,
        reason: 'nenhuma chamada ao repositório da assistente',
      );
      expect(
        autenticacao.chamadas,
        isEmpty,
        reason: 'nenhuma chamada ao repositório de autenticação',
      );
      expect(clientesHttp, 0, reason: 'nenhum cliente HTTP criado');
    });
  });
}

/// Registra qualquer chamada, sem implementar nada: o que interessa é o que
/// NÃO foi chamado.
class _EspiaDeRepositorio implements RepositorioAssistente {
  final List<String> chamadas = <String>[];

  @override
  dynamic noSuchMethod(Invocation invocacao) {
    chamadas.add(invocacao.memberName.toString());
    return super.noSuchMethod(invocacao);
  }
}

class _EspiaDeAutenticacao implements RepositorioAutenticacao {
  final List<String> chamadas = <String>[];

  @override
  dynamic noSuchMethod(Invocation invocacao) {
    chamadas.add(invocacao.memberName.toString());
    return super.noSuchMethod(invocacao);
  }
}

class _QueFalha implements DadoLocalDaPessoa {
  @override
  Future<void> apagar() async => throw StateError('disco cheio');
}

class _Cofre implements CofreDeCredenciais {
  @override
  Future<void> guardarSessao({
    required String tokenAcesso,
    required String refreshToken,
  }) async {}

  @override
  Future<String?> tokenAcesso() async => null;

  @override
  Future<String?> refreshToken() async => null;

  @override
  Future<void> limpar() async {}
}
