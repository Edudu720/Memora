import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/autenticacao/data/ultimo_acesso_local.dart';
import 'package:memora/features/perfil/data/data_de_nascimento_local.dart';
import 'package:memora/features/perfil/domain/data_de_nascimento.dart';
import 'package:memora/services/ambiente/ambiente.dart';
import 'package:memora/services/ambiente/composicao.dart';
import 'package:memora/services/seguranca/cofre_de_credenciais.dart';
import 'package:memora/services/seguranca/limpeza_de_sessao.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// O ciclo de vida da data de nascimento (T123, FR-042c): **fica** na saída
/// comum, para a pessoa não digitá-la de novo a cada entrada, e **sai** com o
/// `esquecerTudo`, de todas as contas do aparelho.
///
/// É o ponto de segurança da tarefa. A data não é [DadoLocalDaPessoa], que sai
/// em toda saída; e como a lista dos dois tipos é separada, o compilador
/// impede de pô-la na errada.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DataDeNascimentoLocal datas;
  late _Cofre cofre;
  late _UltimoAcesso ultimoAcesso;
  late LimpezaDeSessao limpeza;

  final DataDeNascimento ana = DataDeNascimento.deArmazenado('1952-03-15')!;
  final DataDeNascimento bia = DataDeNascimento.deArmazenado('1980-07-01')!;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    datas = DataDeNascimentoLocal(await SharedPreferences.getInstance());
    cofre = _Cofre();
    ultimoAcesso = _UltimoAcesso('ana@email.com');
    limpeza = LimpezaDeSessao(
      cofre: cofre,
      ultimoAcesso: ultimoAcesso,
      dadosDoAparelho: <DadoLocalDoAparelho>[datas],
    );
    await datas.guardar('conta-a', ana);
    await datas.guardar('conta-b', bia);
  });

  test('a saída comum MANTÉM a data', () async {
    await limpeza.executar();

    expect(cofre.limpezas, 1, reason: 'a credencial sai sempre');
    expect(await datas.ler('conta-a'), ana);
    expect(await datas.ler('conta-b'), bia);
  });

  test('o esquecerTudo APAGA a data, de todas as contas', () async {
    await limpeza.executar(esquecerTudo: true);

    expect(await datas.ler('conta-a'), isNull);
    expect(await datas.ler('conta-b'), isNull);
    expect(await ultimoAcesso.identificador(), isNull);
  });

  test('um item que lança não impede os outros nem o último acesso', () async {
    final _Registra depois = _Registra();
    final LimpezaDeSessao comFalha = LimpezaDeSessao(
      cofre: cofre,
      ultimoAcesso: ultimoAcesso,
      dadosDoAparelho: <DadoLocalDoAparelho>[_QueFalha(), depois, datas],
    );

    await comFalha.executar(esquecerTudo: true);

    expect(depois.esquecimentos, 1, reason: 'o item seguinte ao que falhou');
    expect(
      await datas.ler('conta-a'),
      isNull,
      reason: 'a data, que vem depois do que falhou',
    );
    expect(
      await ultimoAcesso.identificador(),
      isNull,
      reason: 'o esquecer() do último acesso roda mesmo assim',
    );
  });

  test('a Composicao liga a mesma guarda ao Perfil e ao esquecerTudo', () async {
    // O que a pessoa vê no Perfil e o que a saída esquece precisam ser a mesma
    // instância: lista errada na composição deixaria a data no aparelho.
    final Composicao composicao = Composicao.resolver(
      ambiente: const Ambiente(
        urlBase: 'http://10.0.2.2:8080/v1',
        usaServidorReal: false,
      ),
      cofre: cofre,
      ultimoAcesso: ultimoAcesso,
      dataDeNascimento: datas,
    );
    expect(composicao.dataDeNascimento, same(datas));

    await composicao.limpeza.executar();
    expect(await datas.ler('conta-a'), ana, reason: 'saída comum mantém');

    await composicao.limpeza.executar(esquecerTudo: true);
    expect(await datas.ler('conta-a'), isNull);
    expect(await datas.ler('conta-b'), isNull);
  });

  test('sem esquecerTudo, os itens do aparelho nem são chamados', () async {
    final _Registra item = _Registra();
    await LimpezaDeSessao(
      cofre: cofre,
      ultimoAcesso: ultimoAcesso,
      dadosDoAparelho: <DadoLocalDoAparelho>[item],
    ).executar();

    expect(item.esquecimentos, 0);
    expect(await ultimoAcesso.identificador(), 'ana@email.com');
  });
}

class _Registra implements DadoLocalDoAparelho {
  int esquecimentos = 0;

  @override
  Future<void> esquecerDoAparelho() async => esquecimentos++;
}

class _QueFalha implements DadoLocalDoAparelho {
  @override
  Future<void> esquecerDoAparelho() async => throw StateError('falhou');
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
