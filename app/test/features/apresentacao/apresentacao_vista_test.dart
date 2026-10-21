import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/apresentacao/data/apresentacao_vista.dart';
import 'package:memora/features/autenticacao/data/ultimo_acesso_local.dart';
import 'package:memora/services/ambiente/ambiente.dart';
import 'package:memora/services/ambiente/composicao.dart';
import 'package:memora/services/seguranca/cofre_de_credenciais.dart';
import 'package:memora/services/seguranca/limpeza_de_sessao.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../suporte/aceite_em_memoria.dart';

/// A guarda da apresentação vista (T046, T048, FR-013, R11): grava por conta,
/// **sobrevive** à saída comum e **só** o `esquecerTudo` a leva — de todas as
/// contas. Teste puro: nada de `testWidgets`, que não completa I/O de disco.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApresentacaoVistaLocal vistas;
  late _Cofre cofre;
  late _UltimoAcesso ultimoAcesso;
  late LimpezaDeSessao limpeza;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    vistas = ApresentacaoVistaLocal(
      await SharedPreferences.getInstance(),
      agora: () => DateTime.utc(2026, 10, 2, 12),
    );
    cofre = _Cofre();
    ultimoAcesso = _UltimoAcesso('ana@email.com');
    limpeza = LimpezaDeSessao(
      cofre: cofre,
      ultimoAcesso: ultimoAcesso,
      dadosDoAparelho: <DadoLocalDoAparelho>[vistas],
    );
  });

  group('Gravar', () {
    test('uma conta nova ainda não viu', () async {
      expect(await vistas.jaViu('conta-a'), isFalse);
    });

    test('marcar como vista grava, e a leitura confirma', () async {
      await vistas.marcarComoVista('conta-a');

      expect(await vistas.jaViu('conta-a'), isTrue);
    });

    test('guarda o instante, para o data-model (vistaEm)', () async {
      await vistas.marcarComoVista('conta-a');

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString('${ApresentacaoVistaLocal.prefixo}conta-a'),
        '2026-10-02T12:00:00.000Z',
      );
    });

    test('marcar duas vezes continua sendo uma vista', () async {
      await vistas.marcarComoVista('conta-a');
      await vistas.marcarComoVista('conta-a');

      expect(await vistas.jaViu('conta-a'), isTrue);
    });

    test(
      'sobrevive a reabrir o aplicativo (outra instância, mesmo disco)',
      () async {
        await vistas.marcarComoVista('conta-a');

        final ApresentacaoVistaLocal reaberta = ApresentacaoVistaLocal(
          await SharedPreferences.getInstance(),
        );
        expect(await reaberta.jaViu('conta-a'), isTrue);
      },
    );
  });

  group('Por conta', () {
    test('outra conta no mesmo aparelho ainda não viu', () async {
      await vistas.marcarComoVista('conta-a');

      expect(await vistas.jaViu('conta-a'), isTrue);
      expect(
        await vistas.jaViu('conta-b'),
        isFalse,
        reason: 'a apresentação é por conta (FR-013): a Bia nunca a viu',
      );
    });

    test('cada conta fica com a sua marca', () async {
      await vistas.marcarComoVista('conta-a');
      await vistas.marcarComoVista('conta-b');

      expect(await vistas.jaViu('conta-a'), isTrue);
      expect(await vistas.jaViu('conta-b'), isTrue);
      expect(await vistas.jaViu('conta-c'), isFalse);
    });

    test('id vazio ou só de espaços não é de ninguém', () async {
      expect(await vistas.jaViu(''), isFalse);
      expect(await vistas.jaViu('   '), isFalse);
      expect(() => vistas.marcarComoVista(''), throwsArgumentError);
      expect(() => vistas.marcarComoVista('  '), throwsArgumentError);

      // E nada vazou: uma conta de verdade continua sem ter visto.
      expect(await vistas.jaViu('conta-a'), isFalse);
    });
  });

  group('A saída da conta (R11)', () {
    setUp(() async {
      await vistas.marcarComoVista('conta-a');
      await vistas.marcarComoVista('conta-b');
    });

    test('a saída comum MANTÉM a apresentação vista', () async {
      await limpeza.executar();

      expect(cofre.limpezas, 1, reason: 'a credencial sai sempre');
      expect(await vistas.jaViu('conta-a'), isTrue);
      expect(await vistas.jaViu('conta-b'), isTrue);
    });

    test('o esquecerTudo APAGA a apresentação, de todas as contas', () async {
      await limpeza.executar(esquecerTudo: true);

      expect(await vistas.jaViu('conta-a'), isFalse);
      expect(await vistas.jaViu('conta-b'), isFalse);
    });

    test('esquecer o aparelho não leva o que não é da apresentação', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        '${ApresentacaoVistaLocal.prefixo}conta-a': 'x',
        'memora.data_de_nascimento.conta-a': '1952-03-15',
        'outra.coisa': 'fica',
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await ApresentacaoVistaLocal(prefs).esquecerDoAparelho();

      expect(prefs.getKeys(), <String>{
        'memora.data_de_nascimento.conta-a',
        'outra.coisa',
      });
    });

    test(
      'a Composicao liga a mesma guarda ao fluxo e ao esquecerTudo',
      () async {
        // O fluxo lê e grava na instância da composição; a saída esquece a
        // instância da lista. Se forem duas, ou se a lista estiver sem ela, o
        // `esquecerTudo` deixa as contas do aparelho para trás.
        final Composicao composicao = Composicao.resolver(
          aceiteDoAviso: AceiteEmMemoria(),
          ambiente: const Ambiente(
            urlBase: 'http://10.0.2.2:8080/v1',
            usaServidorReal: false,
          ),
          cofre: cofre,
          ultimoAcesso: ultimoAcesso,
          apresentacaoVista: vistas,
        );
        expect(composicao.apresentacaoVista, same(vistas));

        await composicao.limpeza.executar();
        expect(await vistas.jaViu('conta-a'), isTrue, reason: 'saída comum');

        await composicao.limpeza.executar(esquecerTudo: true);
        expect(await vistas.jaViu('conta-a'), isFalse);
        expect(await vistas.jaViu('conta-b'), isFalse);
      },
    );
  });

  group('A versão em memória obedece ao mesmo contrato', () {
    test('por conta, e o esquecerTudo leva todas', () async {
      final ApresentacaoVistaEmMemoria memoria = ApresentacaoVistaEmMemoria();
      await memoria.marcarComoVista('conta-a');

      expect(await memoria.jaViu('conta-a'), isTrue);
      expect(await memoria.jaViu('conta-b'), isFalse);

      await memoria.marcarComoVista('conta-b');
      await memoria.esquecerDoAparelho();
      expect(await memoria.jaViu('conta-a'), isFalse);
      expect(await memoria.jaViu('conta-b'), isFalse);
    });

    test('id vazio ou só de espaços também não é de ninguém', () async {
      final ApresentacaoVistaEmMemoria memoria = ApresentacaoVistaEmMemoria();

      expect(await memoria.jaViu(''), isFalse);
      expect(await memoria.jaViu('   '), isFalse);
      expect(() => memoria.marcarComoVista(''), throwsArgumentError);
      expect(() => memoria.marcarComoVista('  '), throwsArgumentError);
      expect(await memoria.jaViu(''), isFalse, reason: 'nada foi gravado');
    });
  });
}

class _Cofre implements CofreDeCredenciais {
  int limpezas = 0;

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
  Future<void> limpar() async => limpezas++;
}

class _UltimoAcesso implements UltimoAcesso {
  String? valor;

  _UltimoAcesso(this.valor);

  @override
  Future<String?> identificador() async => valor;

  @override
  Future<void> lembrar(String identificador) async => valor = identificador;

  @override
  Future<void> esquecer() async => valor = null;
}
