import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/seguranca/limpeza_de_sessao.dart';
import '../domain/data_de_nascimento.dart';

/// Onde a data de nascimento fica guardada, por conta (FR-042c).
///
/// A interface existe porque teste de widget não tem `shared_preferences`.
abstract interface class ArmazenamentoDaDataDeNascimento {
  /// A data guardada para [idDaConta], ou `null`.
  Future<DataDeNascimento?> ler(String idDaConta);

  /// Guarda a data de [idDaConta], trocando a que houver.
  Future<void> guardar(String idDaConta, DataDeNascimento data);

  /// Tira a data de [idDaConta] do aparelho.
  Future<void> apagar(String idDaConta);
}

/// O armazenamento da data **e** o que o `esquecerTudo` leva dele.
///
/// Um tipo só para os dois papéis, para a `Composicao` entregar a mesma
/// instância ao Perfil (que lê e grava) e à `LimpezaDeSessao` (que esquece).
abstract interface class DataDeNascimentoDoAparelho
    implements ArmazenamentoDaDataDeNascimento, DadoLocalDoAparelho {}

/// Guarda a data em `shared_preferences`, uma chave por conta.
///
/// **Não é credencial** e não vai ao servidor. **Não é [DadoLocalDaPessoa]**:
/// a saída comum a mantém, para a pessoa não digitá-la de novo a cada entrada.
/// É [DadoLocalDoAparelho]: só o `esquecerTudo` a leva, e leva a de todas as
/// contas guardadas.
class DataDeNascimentoLocal implements DataDeNascimentoDoAparelho {
  /// Prefixo das chaves; o resto da chave é o id da conta.
  static const String prefixo = 'memora.data_de_nascimento.';

  final SharedPreferences _preferencias;

  /// Cria o armazenamento a partir de uma instância já aberta.
  const DataDeNascimentoLocal(this._preferencias);

  /// Abre o armazenamento do aparelho.
  static Future<DataDeNascimentoLocal> abrir() async =>
      DataDeNascimentoLocal(await SharedPreferences.getInstance());

  /// Id vazio ou só de espaços não identifica ninguém: todas as contas sem id
  /// cairiam na mesma chave, e uma veria a data da outra.
  static bool _semConta(String idDaConta) => idDaConta.trim().isEmpty;

  @override
  Future<DataDeNascimento?> ler(String idDaConta) async {
    if (_semConta(idDaConta)) return null;
    return DataDeNascimento.deArmazenado(
      _preferencias.getString('$prefixo$idDaConta'),
    );
  }

  @override
  Future<void> guardar(String idDaConta, DataDeNascimento data) async {
    if (_semConta(idDaConta)) {
      throw ArgumentError.value(
        idDaConta,
        'idDaConta',
        'sem id da conta a data não tem de quem ser',
      );
    }
    await _preferencias.setString('$prefixo$idDaConta', data.paraArmazenar());
  }

  @override
  Future<void> apagar(String idDaConta) async {
    if (_semConta(idDaConta)) return;
    await _preferencias.remove('$prefixo$idDaConta');
  }

  @override
  Future<void> esquecerDoAparelho() async {
    final List<String> chaves = _preferencias
        .getKeys()
        .where((String chave) => chave.startsWith(prefixo))
        .toList();
    for (final String chave in chaves) {
      await _preferencias.remove(chave);
    }
  }
}

/// A mesma coisa em memória: o padrão dos testes de widget e do fluxo.
class DataDeNascimentoEmMemoria implements DataDeNascimentoDoAparelho {
  final Map<String, DataDeNascimento> _datas = <String, DataDeNascimento>{};

  @override
  Future<DataDeNascimento?> ler(String idDaConta) async => _datas[idDaConta];

  @override
  Future<void> guardar(String idDaConta, DataDeNascimento data) async {
    _datas[idDaConta] = data;
  }

  @override
  Future<void> apagar(String idDaConta) async {
    _datas.remove(idDaConta);
  }

  @override
  Future<void> esquecerDoAparelho() async {
    _datas.clear();
  }
}
