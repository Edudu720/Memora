import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/seguranca/limpeza_de_sessao.dart';

/// Quais contas já viram a apresentação inicial (FR-013, R11 da feature 004).
///
/// A interface existe porque teste de widget não tem `shared_preferences`.
abstract interface class ApresentacaoVista {
  /// A conta [idDaConta] já viu a apresentação, até o fim ou pulando?
  Future<bool> jaViu(String idDaConta);

  /// Registra que [idDaConta] viu a apresentação.
  ///
  /// Só se chama ao chegar ao fim **ou** ao pular (FR-013). Interrompida no
  /// meio, a apresentação não deixa rastro: o aplicativo recomeça do início.
  Future<void> marcarComoVista(String idDaConta);
}

/// A guarda da apresentação **e** o que o `esquecerTudo` leva dela.
///
/// Um tipo só para os dois papéis, para a `Composicao` entregar a mesma
/// instância ao fluxo (que lê e grava) e à `LimpezaDeSessao` (que esquece).
abstract interface class ApresentacaoVistaDoAparelho
    implements ApresentacaoVista, DadoLocalDoAparelho {}

/// Guarda em `shared_preferences`, uma chave por conta.
///
/// **Não é credencial** e não vai ao servidor. **Não é [DadoLocalDaPessoa]**:
/// a saída comum a mantém, senão sair e voltar repetiria a apresentação — que
/// a FR-013 manda mostrar uma vez. É [DadoLocalDoAparelho]: só o `esquecerTudo`
/// a leva, e leva a de **todas** as contas, porque a lista de ids que passaram
/// pelo aparelho não deve ficar num aparelho que vai ser vendido (R11, revisão
/// da #36).
class ApresentacaoVistaLocal implements ApresentacaoVistaDoAparelho {
  /// Prefixo das chaves; o resto da chave é o id da conta.
  static const String prefixo = 'memora.apresentacao_vista.';

  final SharedPreferences _preferencias;
  final DateTime Function() _agora;

  /// Cria a guarda a partir de uma instância já aberta.
  ///
  /// [agora] existe para o teste fixar o `vistaEm`.
  ApresentacaoVistaLocal(
    this._preferencias, {
    DateTime Function() agora = DateTime.now,
  }) : _agora = agora;

  /// Abre a guarda do aparelho.
  static Future<ApresentacaoVistaLocal> abrir() async =>
      ApresentacaoVistaLocal(await SharedPreferences.getInstance());

  /// Id vazio ou só de espaços não identifica ninguém: todas as contas sem id
  /// cairiam na mesma chave, e uma herdaria a apresentação vista da outra.
  static bool _semConta(String idDaConta) => idDaConta.trim().isEmpty;

  @override
  Future<bool> jaViu(String idDaConta) async {
    if (_semConta(idDaConta)) return false;
    return _preferencias.containsKey('$prefixo$idDaConta');
  }

  @override
  Future<void> marcarComoVista(String idDaConta) async {
    if (_semConta(idDaConta)) {
      throw ArgumentError.value(
        idDaConta,
        'idDaConta',
        'sem id da conta a apresentação não tem de quem ser',
      );
    }
    // O valor é o `vistaEm` (data-model). A presença da chave é o que vale.
    await _preferencias.setString(
      '$prefixo$idDaConta',
      _agora().toUtc().toIso8601String(),
    );
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
class ApresentacaoVistaEmMemoria implements ApresentacaoVistaDoAparelho {
  final Set<String> _contas = <String>{};

  @override
  Future<bool> jaViu(String idDaConta) async =>
      !ApresentacaoVistaLocal._semConta(idDaConta) &&
      _contas.contains(idDaConta);

  @override
  Future<void> marcarComoVista(String idDaConta) async {
    // Mesmo contrato da versão real: o dublê não pode aceitar o que ela recusa.
    if (ApresentacaoVistaLocal._semConta(idDaConta)) {
      throw ArgumentError.value(
        idDaConta,
        'idDaConta',
        'sem id da conta a apresentação não tem de quem ser',
      );
    }
    _contas.add(idDaConta);
  }

  @override
  Future<void> esquecerDoAparelho() async {
    _contas.clear();
  }
}
