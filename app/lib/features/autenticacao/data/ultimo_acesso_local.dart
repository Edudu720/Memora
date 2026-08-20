import 'package:shared_preferences/shared_preferences.dart';

/// Lembra qual identificador entrou por último **neste aparelho** (FR-012).
///
/// ## Por que existe
///
/// O cenário 2 da US2 é literal: *"minha sessão expirou, reabro o aplicativo,
/// meu identificador já vem preenchido e só preciso da senha"*. Digitar um
/// e-mail inteiro num teclado de celular é a barreira que devolve a pessoa
/// idosa à dependência de um filho ou neto — que é exatamente o que o Memora
/// existe para desfazer.
///
/// ## Por que a interface
///
/// Teste de widget não tem `shared_preferences`. Sem esta interface, todo teste
/// do login precisaria de canal simulado de plataforma, e o resultado prático
/// seria ninguém testar o pré-preenchimento.
abstract interface class UltimoAcesso {
  /// O identificador do último acesso bem-sucedido, ou `null` se não houver.
  Future<String?> identificador();

  /// Guarda o identificador. Chamado **apenas depois** de um login que deu
  /// certo — gravar na tentativa transformaria um erro de digitação em
  /// pré-preenchimento errado para sempre.
  Future<void> lembrar(String identificador);

  /// Esquece o identificador guardado.
  Future<void> esquecer();
}

/// Implementação sobre o armazenamento comum do aparelho.
///
/// ## Por que aqui e não no cofre — decisão de 2026-08-20
///
/// O `flutter_secure_storage` é obrigatório para **credencial** (FR-036, V8).
/// Identificador não é credencial, e guardá-lo cifrado não protegeria nada: o
/// propósito inteiro da FR-012 é **exibi-lo na tela**, já preenchido. Quem tem
/// o aparelho na mão lê o e-mail no campo antes de pensar em abrir o
/// `shared_prefs`.
///
/// Há um motivo a mais, e ele é o que decidiu a questão: o cenário V8 reprova
/// se sobrar **qualquer coisa** no cofre depois de sair da conta. Misturar aqui
/// um dado que deve sobreviver à saída obrigaria a afrouxar esse teste — trocar
/// um portão que funciona por uma proteção que não protege.
class UltimoAcessoLocal implements UltimoAcesso {
  /// Chave usada no armazenamento.
  static const String chave = 'memora.ultimo_identificador';

  final SharedPreferences _preferencias;

  /// Cria o repositório a partir de uma instância já aberta.
  const UltimoAcessoLocal(this._preferencias);

  /// Abre o armazenamento e devolve o repositório pronto para uso.
  static Future<UltimoAcessoLocal> abrir() async {
    return UltimoAcessoLocal(await SharedPreferences.getInstance());
  }

  @override
  Future<String?> identificador() async {
    final String? valor = _preferencias.getString(chave);
    if (valor == null || valor.isEmpty) return null;
    return valor;
  }

  @override
  Future<void> lembrar(String identificador) async {
    final String limpo = identificador.trim();
    if (limpo.isEmpty) return;
    await _preferencias.setString(chave, limpo);
  }

  @override
  Future<void> esquecer() async {
    await _preferencias.remove(chave);
  }
}
