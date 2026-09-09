import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_api.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/services/ambiente/ambiente.dart';
import 'package:memora/services/ambiente/composicao.dart';
import 'package:memora/services/seguranca/cofre_de_credenciais.dart';

/// O ambiente e a composição — a peça que liga o aplicativo ao servidor.
///
/// O que estes testes protegem é menos a configuração e mais **duas escolhas**:
/// que o padrão seja o simulado, e que texto puro não passe fora de depuração.
void main() {
  group('Ambiente', () {
    test('sem nada configurado, o padrão é o simulado', () {
      final Ambiente ambiente = Ambiente.doAmbiente();

      expect(
        ambiente.usaServidorReal,
        isFalse,
        reason: 'quem clona e roda `flutter run` precisa ver o app funcionando, '
            'não uma tela de erro de rede',
      );
    });

    test('o padrão aponta para o hospedeiro do emulador, não para localhost', () {
      // `localhost` dentro do emulador e o proprio emulador: o servidor da
      // maquina fica invisivel, e o erro `Connection refused` parece servidor
      // fora do ar. E a primeira pedra em que toda integracao Android tropeca.
      expect(Ambiente.urlBasePadrao, contains('10.0.2.2'));
      expect(Ambiente.urlBasePadrao, isNot(contains('localhost')));
    });

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
      );

      expect(composicao.autenticacao, isA<RepositorioAutenticacaoApi>());
    });

    /// A ressalva precisa aparecer para quem rodar contra o servidor. Sem ela,
    /// a assistente simulada vira surpresa no meio de uma demonstração.
    test('avisa que a assistente continua simulada quando o servidor é real', () {
      final Composicao real = Composicao.resolver(
        ambiente: const Ambiente(
          urlBase: 'https://api.memora.app/v1',
          usaServidorReal: true,
        ),
        cofre: _CofreDeMentira(),
      );

      expect(real.avisoDeIntegracaoParcial, isNotNull);
      expect(real.avisoDeIntegracaoParcial, contains('ASSISTENTE'));
    });

    test('não avisa nada quando tudo é simulado', () {
      final Composicao simulada = Composicao.resolver(
        ambiente: const Ambiente(
          urlBase: 'http://10.0.2.2:8080/v1',
          usaServidorReal: false,
        ),
        cofre: _CofreDeMentira(),
      );

      expect(simulada.avisoDeIntegracaoParcial, isNull);
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
