import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/assistente/data/catalogo_guardado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/services/ambiente/ambiente.dart';
import 'package:memora/services/ambiente/composicao.dart';
import 'package:memora/services/seguranca/cofre_de_credenciais.dart';
import 'package:memora/services/seguranca/limpeza_de_sessao.dart';

import '../autenticacao/dubles_autenticacao.dart';

/// O catálogo guardado no aparelho (T069b, FR-024a).
///
/// `test` puro, com disco de verdade: I/O de arquivo real não completa dentro
/// de `testWidgets`.
void main() {
  // A Composicao monta a ConversaLocal, que pergunta o diretorio a plataforma.
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory pasta;
  late _RepositorioDoServidor servidor;
  late CatalogoGuardado catalogo;

  setUp(() {
    pasta = Directory.systemTemp.createTempSync('memora_catalogo_');
    servidor = _RepositorioDoServidor();
    catalogo = CatalogoGuardado(servidor, diretorio: () async => pasta);
  });

  tearDown(() {
    if (pasta.existsSync()) pasta.deleteSync(recursive: true);
  });

  File arquivo() => File('${pasta.path}/${CatalogoGuardado.nomeDoArquivo}');

  List<String> chaves(List<ServicoDoCatalogo> lista) =>
      lista.map((ServicoDoCatalogo s) => s.chave).toList();

  group('com conexão', () {
    test('devolve o que o servidor mandou, como veio', () async {
      servidor.resposta = <ServicoDoCatalogo>[
        _item('whatsapp'),
        _item('gov-br', sensivel: true),
      ];

      final List<ServicoDoCatalogo> recebido = await catalogo.catalogo();

      expect(chaves(recebido), <String>['whatsapp', 'gov-br']);
    });

    test('o que foi recebido fica guardado, inteiro', () async {
      servidor.resposta = <ServicoDoCatalogo>[
        _item('whatsapp', nome: 'WhatsApp', descricao: 'Mandar mensagem'),
        _item('gov-br', sensivel: true),
      ];
      await catalogo.catalogo();

      final CatalogoRecebido? guardado = await catalogo.lerGuardado();

      expect(guardado, isNotNull);
      expect(chaves(guardado!.servicos), <String>['whatsapp', 'gov-br']);
      final ServicoDoCatalogo zap = guardado.servicos.first;
      expect(zap.id, 'id-whatsapp');
      expect(zap.nomeExibido, 'WhatsApp');
      expect(zap.descricaoCurta, 'Mandar mensagem');
      expect(zap.categoria, CategoriaDoServico.cotidiano);
      expect(zap.memoraPodeAbrir, isTrue);
      expect(guardado.servicos.last.categoria, CategoriaDoServico.sensivel);
      expect(guardado.servicos.last.memoraPodeAbrir, isFalse);
    });

    test('guarda quando a resposta chegou', () async {
      final DateTime hoje = DateTime.utc(2026, 10, 2, 9, 30);
      catalogo = CatalogoGuardado(
        servidor,
        diretorio: () async => pasta,
        agora: () => hoje,
      );
      servidor.resposta = <ServicoDoCatalogo>[_item('whatsapp')];

      await catalogo.catalogo();

      expect((await catalogo.lerGuardado())!.recebidoEm.toUtc(), hoje);
    });

    test('item retirado do servidor SOME na primeira resposta nova', () async {
      servidor.resposta = <ServicoDoCatalogo>[
        _item('whatsapp'),
        _item('telegram'),
        _item('instagram'),
      ];
      await catalogo.catalogo();

      // O servidor tirou o telegram do ar. Substituir, nunca mesclar.
      servidor.resposta = <ServicoDoCatalogo>[
        _item('whatsapp'),
        _item('instagram'),
      ];
      expect(chaves(await catalogo.catalogo()), <String>[
        'whatsapp',
        'instagram',
      ]);
      expect(
        chaves((await catalogo.lerGuardado())!.servicos),
        <String>['whatsapp', 'instagram'],
        reason: 'o item retirado nao pode sobreviver no arquivo',
      );

      // E sem conexão, o que volta é o catálogo novo, sem o telegram.
      servidor.falha = const _SemConexao();
      expect(chaves(await catalogo.catalogo()), <String>[
        'whatsapp',
        'instagram',
      ]);
    });
  });

  group('sem conexão', () {
    test('devolve o último recebido', () async {
      servidor.resposta = <ServicoDoCatalogo>[
        _item('whatsapp'),
        _item('youtube'),
      ];
      await catalogo.catalogo();

      servidor.falha = const _SemConexao();
      final List<ServicoDoCatalogo> offline = await catalogo.catalogo();

      expect(chaves(offline), <String>['whatsapp', 'youtube']);
    });

    test('um catálogo guardado numa execução vale na seguinte', () async {
      servidor.resposta = <ServicoDoCatalogo>[_item('whatsapp')];
      await catalogo.catalogo();

      // O aplicativo foi fechado e aberto sem internet: outra instância.
      final CatalogoGuardado depois = CatalogoGuardado(
        _RepositorioDoServidor()..falha = const _SemConexao(),
        diretorio: () async => pasta,
      );

      expect(chaves(await depois.catalogo()), <String>['whatsapp']);
    });

    test('primeira abertura sem conexão e sem nada guardado: a falha chega a '
        'tela, que diz que precisa de internet', () async {
      servidor.falha = const _SemConexao();

      await expectLater(catalogo.catalogo(), throwsA(isA<_SemConexao>()));
      expect(arquivo().existsSync(), isFalse);
    });
  });

  group('resposta malformada', () {
    late List<ServicoDoCatalogo> boa;

    setUp(() async {
      boa = <ServicoDoCatalogo>[_item('whatsapp'), _item('youtube')];
      servidor.resposta = boa;
      await catalogo.catalogo();
    });

    Future<void> naoApagaOGuardado(List<ServicoDoCatalogo> ruim) async {
      servidor.resposta = ruim;

      final List<ServicoDoCatalogo> devolvido = await catalogo.catalogo();

      expect(chaves(devolvido), <String>[
        'whatsapp',
        'youtube',
      ], reason: 'a tela fica com o ultimo catalogo bom');
      expect(
        chaves((await catalogo.lerGuardado())!.servicos),
        <String>['whatsapp', 'youtube'],
        reason: 'e o arquivo tambem',
      );
    }

    test('resposta vazia não apaga o guardado', () async {
      await naoApagaOGuardado(<ServicoDoCatalogo>[]);
    });

    test('chave fora do formato do banco não apaga o guardado', () async {
      await naoApagaOGuardado(<ServicoDoCatalogo>[_item('Chave Errada')]);
      await naoApagaOGuardado(<ServicoDoCatalogo>[_item('a' * 41)]);
    });

    test('chave ou id repetido não apaga o guardado', () async {
      await naoApagaOGuardado(<ServicoDoCatalogo>[
        _item('tiktok'),
        _item('tiktok'),
      ]);
      await naoApagaOGuardado(<ServicoDoCatalogo>[
        _item('tiktok', id: 'mesmo'),
        _item('kwai', id: 'mesmo'),
      ]);
    });

    test(
      'serviço sensível marcado como abrível não apaga o guardado (FR-041)',
      () async {
        await naoApagaOGuardado(<ServicoDoCatalogo>[
          _item('banco', sensivel: true, podeAbrir: true),
        ]);
      },
    );

    test(
      'malformada com nada guardado: falha, em vez de mostrar o malformado',
      () async {
        pasta.deleteSync(recursive: true);
        pasta.createSync();
        servidor.resposta = <ServicoDoCatalogo>[];

        await expectLater(catalogo.catalogo(), throwsFormatException);
      },
    );
  });

  group('arquivo estragado', () {
    test('conteúdo ilegível vale como nada guardado, e o próximo recebido o '
        'conserta', () async {
      arquivo().writeAsStringSync('{ isto nao e json');
      expect(await catalogo.lerGuardado(), isNull);

      servidor.falha = const _SemConexao();
      await expectLater(catalogo.catalogo(), throwsA(isA<_SemConexao>()));

      servidor.falha = null;
      servidor.resposta = <ServicoDoCatalogo>[_item('whatsapp')];
      await catalogo.catalogo();
      expect(chaves((await catalogo.lerGuardado())!.servicos), <String>[
        'whatsapp',
      ]);
    });

    test(
      'um item ilegível invalida o arquivo: nunca "metade" do catálogo',
      () async {
        arquivo().writeAsStringSync(
          '{"recebidoEm":"2026-10-02T00:00:00Z","servicos":['
          '{"id":"a","chave":"whatsapp","nomeExibido":"W","descricaoCurta":"",'
          '"categoria":"cotidiano","memoraPodeAbrir":true},'
          '{"id":"b","chave":"youtube"}]}',
        );

        expect(await catalogo.lerGuardado(), isNull);
      },
    );
  });

  group('sair da conta NÃO apaga o catálogo (não é dado da pessoa)', () {
    test('não é um DadoLocalDaPessoa: não cabe na lista da limpeza', () {
      expect(catalogo, isNot(isA<DadoLocalDaPessoa>()));
      expect(catalogo, isNot(isA<DadoLocalDoAparelho>()));
    });

    test(
      'a LimpezaDeSessao, inclusive com esquecerTudo, deixa o catálogo',
      () async {
        servidor.resposta = <ServicoDoCatalogo>[_item('whatsapp')];
        await catalogo.catalogo();
        final LimpezaDeSessao limpeza = LimpezaDeSessao(
          cofre: _Cofre(),
          ultimoAcesso: UltimoAcessoEmMemoria(),
        );

        await limpeza.executar();
        await limpeza.executar(esquecerTudo: true);

        expect(arquivo().existsSync(), isTrue);
        servidor.falha = const _SemConexao();
        expect(chaves(await catalogo.catalogo()), <String>['whatsapp']);
      },
    );
  });

  group('a Composicao', () {
    const Ambiente simulado = Ambiente(
      urlBase: 'http://10.0.2.2:8080/v1',
      usaServidorReal: false,
    );

    test('com guardarCatalogo, a consulta do catálogo vem envolvida', () {
      final Composicao composicao = Composicao.resolver(
        ambiente: simulado,
        cofre: _Cofre(),
        ultimoAcesso: UltimoAcessoEmMemoria(),
        guardarCatalogo: true,
      );

      expect(composicao.assistente, isA<CatalogoGuardado>());
    });

    test('por padrão não, para o teste de widget não tocar o disco', () {
      final Composicao composicao = Composicao.resolver(
        ambiente: simulado,
        cofre: _Cofre(),
        ultimoAcesso: UltimoAcessoEmMemoria(),
      );

      expect(composicao.assistente, isNot(isA<CatalogoGuardado>()));
    });
  });

  group('o resto passa direto', () {
    test(
      'conversar, registrarAcao e registro vão ao repositório de dentro',
      () async {
        await catalogo.conversar(mensagem: 'oi', historico: const []);
        await catalogo.registrarAcao(servicoId: 'x', pedidoResumido: 'y');
        await catalogo.registro();

        expect(servidor.chamadas, <String>[
          'conversar',
          'registrarAcao',
          'registro',
        ]);
      },
    );
  });
}

ServicoDoCatalogo _item(
  String chave, {
  String? id,
  String? nome,
  String descricao = 'descricao',
  bool sensivel = false,
  bool? podeAbrir,
}) => ServicoDoCatalogo(
  id: id ?? 'id-$chave',
  chave: chave,
  nomeExibido: nome ?? chave,
  descricaoCurta: descricao,
  categoria: sensivel
      ? CategoriaDoServico.sensivel
      : CategoriaDoServico.cotidiano,
  memoraPodeAbrir: podeAbrir ?? !sensivel,
);

class _SemConexao implements Exception {
  const _SemConexao();
}

class _RepositorioDoServidor implements RepositorioAssistente {
  List<ServicoDoCatalogo> resposta = <ServicoDoCatalogo>[];
  Exception? falha;
  final List<String> chamadas = <String>[];

  @override
  Future<List<ServicoDoCatalogo>> catalogo() async {
    final Exception? f = falha;
    if (f != null) throw f;
    return resposta;
  }

  @override
  Future<RespostaDaAssistente> conversar({
    required String mensagem,
    required List<MensagemDaConversa> historico,
    void Function(String trecho)? aoReceberTrecho,
  }) async {
    chamadas.add('conversar');
    return const AssistenteRespondeu('ok');
  }

  @override
  Future<void> registrarAcao({
    required String servicoId,
    required String pedidoResumido,
  }) async {
    chamadas.add('registrarAcao');
  }

  @override
  Future<List<AcaoRegistrada>> registro() async {
    chamadas.add('registro');
    return const <AcaoRegistrada>[];
  }
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
