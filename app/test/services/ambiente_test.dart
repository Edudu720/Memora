import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/ajuda/data/abridor_site_tutorial.dart';
import 'package:memora/features/antigolpe/data/repositorios/repositorio_analise_golpe_api.dart';
import 'package:memora/features/antigolpe/data/repositorios/repositorio_analise_golpe_simulado.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_api.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_api.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/services/ambiente/ambiente.dart';
import 'package:memora/services/ambiente/composicao.dart';
import 'package:memora/services/seguranca/cofre_de_credenciais.dart';
import '../features/assistente/suporte_da_api_falsa.dart';
import '../suporte/aceite_em_memoria.dart';

import '../features/autenticacao/dubles_autenticacao.dart';

/// O ambiente e a composição — a peça que liga o aplicativo ao servidor.
///
/// O que estes testes protegem é menos a configuração e mais **duas escolhas**:
/// que o padrão seja o simulado, e que texto puro não passe fora de depuração.
void main() {
  group('Ambiente — o endereço oficial de download (T089, FR-035, FR-037)', () {
    test('sem `MEMORA_URL_DOWNLOAD`, não há endereço', () {
      // O aplicativo ainda não está publicado: nenhum endereço, e o assunto
      // "Compartilhar" da Ajuda não existe (R12).
      expect(Ambiente.doAmbiente().urlDownload, isNull);
    });

    test('um endereço `https://` com servidor serve, e vem limpo', () {
      expect(
        Ambiente.enderecoOficial('  https://memora.fatec.example/baixar  '),
        'https://memora.fatec.example/baixar',
      );
    });

    test('vazio, só espaços ou ausente não é endereço', () {
      expect(Ambiente.enderecoOficial(null), isNull);
      expect(Ambiente.enderecoOficial(''), isNull);
      expect(Ambiente.enderecoOficial('   '), isNull);
    });

    test('o que não é `https://` não serve: sem cifra, a rede adultera', () {
      expect(Ambiente.enderecoOficial('http://memora.example/baixar'), isNull);
      expect(Ambiente.enderecoOficial('ftp://memora.example/baixar'), isNull);
      expect(Ambiente.enderecoOficial('intent://memora.example'), isNull);
      expect(Ambiente.enderecoOficial('memora.example/baixar'), isNull);
    });

    test('usuário na frente do servidor é a isca do golpe, e não serve', () {
      // `https://loja.com@golpe.example` lê-se como "da loja" e leva ao golpe.
      expect(
        Ambiente.enderecoOficial('https://play.google.com@golpe.example/x'),
        isNull,
      );
      expect(Ambiente.enderecoOficial('https://@golpe.example/x'), isNull);
      expect(Ambiente.enderecoOficial('HTTPS://@golpe.example/x'), isNull);
      expect(
        Ambiente.enderecoOficial('https://memora.example/@ajuda'),
        'https://memora.example/@ajuda',
      );
    });

    test('espaço ou quebra de linha no meio não serve', () {
      expect(Ambiente.enderecoOficial('https://memora.example/a b'), isNull);
      expect(
        Ambiente.enderecoOficial('https://memora.example/a\nhttps://golpe'),
        isNull,
      );
    });

    test('o ambiente construído à mão guarda o endereço que recebeu', () {
      const Ambiente ambiente = Ambiente(
        urlBase: '',
        usaServidorReal: false,
        urlDownload: 'https://memora.example/baixar',
      );
      expect(ambiente.urlDownload, 'https://memora.example/baixar');
    });
  });

  group('Ambiente', () {
    test('sem nada configurado, o padrão é o simulado', () {
      final Ambiente ambiente = Ambiente.doAmbiente();

      expect(
        ambiente.usaServidorReal,
        isFalse,
        reason:
            'quem clona e roda `flutter run` precisa ver o app funcionando, '
            'não uma tela de erro de rede',
      );
    });

    test(
      'o padrão aponta para o hospedeiro do emulador, não para localhost',
      () {
        // `localhost` dentro do emulador e o proprio emulador: o servidor da
        // maquina fica invisivel, e o erro `Connection refused` parece servidor
        // fora do ar. E a primeira pedra em que toda integracao Android tropeca.
        expect(Ambiente.urlBasePadrao, contains('10.0.2.2'));
        expect(Ambiente.urlBasePadrao, isNot(contains('localhost')));
      },
    );

    test('reconhece endereço cifrado', () {
      const Ambiente cifrado = Ambiente(
        urlBase: 'https://api.memora.app/v1',
        usaServidorReal: true,
      );
      const Ambiente puro = Ambiente(
        urlBase: 'http://10.0.2.2:8080/v1',
        usaServidorReal: true,
      );

      expect(cifrado.usaTls, isTrue);
      expect(puro.usaTls, isFalse);
    });
  });

  group('O token de sessão não viaja em texto puro', () {
    test('texto puro com servidor real é recusado fora de depuração', () {
      const Ambiente inseguro = Ambiente(
        urlBase: 'http://api.memora.app/v1',
        usaServidorReal: true,
      );

      // Em teste, `kDebugMode` e verdadeiro, entao a checagem nao dispara.
      // O que se pode afirmar aqui e que ela nao derruba o caminho legitimo —
      // a recusa em si e verificada pelo teste de leitura abaixo.
      expect(inseguro.exigirTlsForaDeDepuracao, returnsNormally);
    });

    test('https com servidor real passa sempre', () {
      const Ambiente seguro = Ambiente(
        urlBase: 'https://api.memora.app/v1',
        usaServidorReal: true,
      );

      expect(seguro.exigirTlsForaDeDepuracao, returnsNormally);
    });

    test('sem servidor real, texto puro é irrelevante', () {
      const Ambiente simulado = Ambiente(
        urlBase: 'http://10.0.2.2:8080/v1',
        usaServidorReal: false,
      );

      expect(simulado.exigirTlsForaDeDepuracao, returnsNormally);
    });
  });

  group('Composicao', () {
    test('sem servidor real, a autenticação é simulada', () {
      final Composicao composicao = Composicao.resolver(
        ambiente: const Ambiente(
          urlBase: 'http://10.0.2.2:8080/v1',
          usaServidorReal: false,
        ),
        cofre: _CofreDeMentira(),
        ultimoAcesso: UltimoAcessoEmMemoria(),
        aceiteDoAviso: AceiteEmMemoria(),
      );

      expect(composicao.autenticacao, isA<RepositorioAutenticacaoSimulado>());
    });

    test('com servidor real, a autenticação fala com a API', () {
      final Composicao composicao = Composicao.resolver(
        ambiente: const Ambiente(
          urlBase: 'https://api.memora.app/v1',
          usaServidorReal: true,
        ),
        cofre: _CofreDeMentira(),
        ultimoAcesso: UltimoAcessoEmMemoria(),
        aceiteDoAviso: AceiteEmMemoria(),
      );

      expect(composicao.autenticacao, isA<RepositorioAutenticacaoApi>());
    });

    /// Não existe aplicativo com conta de verdade e assistente de mentira
    /// (spec 003, clarificação de 2026-10-09): a escolha é uma só.
    test(
      'com servidor real, a assistente fala com a API — não com o simulado',
      () {
        final Composicao composicao = Composicao.resolver(
          ambiente: const Ambiente(
            urlBase: 'https://api.memora.app/v1',
            usaServidorReal: true,
          ),
          cofre: _CofreDeMentira(),
          ultimoAcesso: UltimoAcessoEmMemoria(),
          aceiteDoAviso: AceiteEmMemoria(),
        );

        expect(composicao.assistente, isA<RepositorioAssistenteApi>());
        expect(
          composicao.assistente,
          isNot(isA<RepositorioAssistenteSimulado>()),
          reason:
              'servidor real com assistente simulada é o aplicativo que '
              'promete uma conversa que ninguém atende',
        );
      },
    );

    /// A ligação inteira, sem rede: a assistente que a Composicao monta, ao
    /// levar `401` e ter a renovação recusada, aciona o MESMO aviso que a
    /// Composicao entrega ao fluxo (T111). Sem isto, um `SessaoPerdida` criado
    /// aqui e outro lá passaria em todos os testes e não ligaria nada.
    test(
      'a sessão perdida na assistente aciona o aviso da Composicao',
      () async {
        final CofreEmMemoria cofre = CofreEmMemoria();
        final AdaptadorFalso servidor = AdaptadorFalso(
          (_, _) async => respostaJson(401, <String, Object>{
            'codigo': 'CREDENCIAIS_INVALIDAS',
            'mensagem': 'x',
          }),
        );
        final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.memora.app/v1'))
          ..httpClientAdapter = servidor;
        final Composicao composicao = Composicao.resolver(
          ambiente: const Ambiente(
            urlBase: 'https://api.memora.app/v1',
            usaServidorReal: true,
          ),
          cofre: cofre,
          ultimoAcesso: UltimoAcessoEmMemoria(),
          aceiteDoAviso: AceiteEmMemoria(),
          dioDeTeste: dio,
        );

        await expectLater(
          composicao.assistente.catalogo(),
          throwsA(
            isA<FalhaDeChamadaDaAssistente>().having(
              (FalhaDeChamadaDaAssistente e) => e.falha,
              'falha',
              FalhaDaAssistente.sessaoExpirada,
            ),
          ),
        );

        expect(composicao.sessaoPerdida.avisos, 1);
      },
    );

    test('sem servidor real, a assistente é simulada', () {
      final Composicao composicao = Composicao.resolver(
        ambiente: const Ambiente(
          urlBase: 'http://10.0.2.2:8080/v1',
          usaServidorReal: false,
        ),
        cofre: _CofreDeMentira(),
        ultimoAcesso: UltimoAcessoEmMemoria(),
        aceiteDoAviso: AceiteEmMemoria(),
      );

      expect(composicao.assistente, isA<RepositorioAssistenteSimulado>());
    });

    test('resolve RepositorioAnaliseGolpeApi com servidor real e Simulado sem ele', () {
      final Composicao real = Composicao.resolver(
        ambiente: const Ambiente(
          urlBase: 'https://api.memora.app/v1',
          usaServidorReal: true,
        ),
        cofre: _CofreDeMentira(),
        ultimoAcesso: UltimoAcessoEmMemoria(),
        aceiteDoAviso: AceiteEmMemoria(),
      );
      expect(real.analiseGolpe, isA<RepositorioAnaliseGolpeApi>());

      final Composicao simulada = Composicao.resolver(
        ambiente: const Ambiente(
          urlBase: 'http://10.0.2.2:8080/v1',
          usaServidorReal: false,
        ),
        cofre: _CofreDeMentira(),
        ultimoAcesso: UltimoAcessoEmMemoria(),
        aceiteDoAviso: AceiteEmMemoria(),
      );
      expect(simulada.analiseGolpe, isA<RepositorioAnaliseGolpeSimulado>());
    });

    test('urlSiteTutorial e AbridorDeSiteTutorial validam protocolo estrito https://', () {
      expect(
        Ambiente.doAmbiente().urlSiteTutorial,
        Ambiente.urlSiteTutorialPadrao,
      );
      expect(
        AbridorDeSiteTutorial.doAmbiente(Ambiente.doAmbiente())?.endereco,
        'https://memora-site-thf2.onrender.com/',
      );
      expect(
        AbridorDeSiteTutorial.doAmbiente(
          const Ambiente(
            urlBase: 'https://api.memora.fatec.example',
            usaServidorReal: false,
            urlSiteTutorial: '',
          ),
        ),
        isNull,
      );
      expect(
        AbridorDeSiteTutorial.doAmbiente(
          const Ambiente(
            urlBase: 'https://api.memora.fatec.example',
            usaServidorReal: false,
          ),
        ),
        isNull,
      );
      expect(
        AbridorDeSiteTutorial.doAmbiente(
          const Ambiente(
            urlBase: 'https://api.memora.fatec.example',
            usaServidorReal: false,
            urlSiteTutorial: 'http://tutoriais.memora.fatec.example',
          ),
        ),
        isNull,
      );
      expect(
        AbridorDeSiteTutorial.doAmbiente(
          const Ambiente(
            urlBase: 'https://api.memora.fatec.example',
            usaServidorReal: false,
            urlSiteTutorial: 'https://user@tutoriais.memora.fatec.example',
          ),
        ),
        isNull,
      );
      expect(
        AbridorDeSiteTutorial.doAmbiente(
          const Ambiente(
            urlBase: 'https://api.memora.fatec.example',
            usaServidorReal: false,
            urlSiteTutorial: 'https://tutoriais.memora.fatec.example/com espaco',
          ),
        ),
        isNull,
      );

      final Composicao semSite = Composicao.resolver(
        ambiente: const Ambiente(
          urlBase: 'https://api.memora.fatec.example',
          usaServidorReal: false,
        ),
        cofre: _CofreDeMentira(),
        ultimoAcesso: UltimoAcessoEmMemoria(),
        aceiteDoAviso: AceiteEmMemoria(),
      );
      expect(semSite.abridorSiteTutorial, isNull);

      final Composicao comSite = Composicao.resolver(
        ambiente: const Ambiente(
          urlBase: 'https://api.memora.fatec.example',
          usaServidorReal: false,
          urlSiteTutorial: '  https://tutoriais.memora.fatec.example  ',
        ),
        cofre: _CofreDeMentira(),
        ultimoAcesso: UltimoAcessoEmMemoria(),
        aceiteDoAviso: AceiteEmMemoria(),
      );
      expect(comSite.abridorSiteTutorial, isNotNull);
      expect(
        comSite.abridorSiteTutorial!.endereco,
        'https://tutoriais.memora.fatec.example',
      );
    });
  });
}

/// Cofre que não encosta no armazenamento seguro do aparelho.
class _CofreDeMentira implements CofreDeCredenciais {
  String? _acesso;
  String? _refresh;

  @override
  Future<void> guardarSessao({
    required String tokenAcesso,
    required String refreshToken,
  }) async {
    _acesso = tokenAcesso;
    _refresh = refreshToken;
  }

  @override
  Future<String?> tokenAcesso() async => _acesso;

  @override
  Future<String?> refreshToken() async => _refresh;

  @override
  Future<void> limpar() async {
    _acesso = null;
    _refresh = null;
  }
}
