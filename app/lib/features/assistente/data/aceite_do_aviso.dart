import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/seguranca/limpeza_de_sessao.dart';

/// Se a pessoa já leu e aceitou o aviso de privacidade da conversa (FR-051).
///
/// ## O que este aceite protege
///
/// O serviço que gera as respostas é de fora do Memora e do nível gratuito: pode
/// usar o que recebe para melhorar os programas dele, e pessoas de lá podem ler
/// (ADR-002, Emenda 1 da constituição). A pessoa tem o direito de saber disso
/// **antes** de escrever a primeira frase — e a Memora não envia nada até ela
/// dizer que entendeu.
///
/// ## Onde mora, e por que ali
///
/// Um booleano em `SharedPreferences`. **Não é credencial** e não é conteúdo de
/// conversa: diz só que a pessoa leu um aviso. Por isso não vai no cofre — o V8
/// reprova se sobrar qualquer coisa lá depois de sair —, e não precisa do
/// arquivo privado da conversa (`data-model.md`, "Aceite do aviso de
/// privacidade").
///
/// ## É apagado ao sair da conta
///
/// Implementa [DadoLocalDaPessoa], então a `LimpezaDeSessao` o leva junto. Num
/// celular compartilhado, quem entra depois com outra conta precisa ler o aviso
/// de novo: o aceite é de uma pessoa, e não do aparelho. O preço é perguntar
/// outra vez a quem sai e volta, e sair é raro.
///
/// ## Por que a interface
///
/// Teste de widget não tem `shared_preferences`, e I/O real não completa dentro
/// de `testWidgets`. Os testes passam um dublê em memória.
abstract interface class AceiteDoAviso implements DadoLocalDaPessoa {
  /// A pessoa já aceitou, neste aparelho e nesta conta?
  Future<bool> aceitou();

  /// Guarda que a pessoa aceitou.
  Future<void> registrar();
}

/// O aceite sobre o armazenamento comum do aparelho.
class AceiteDoAvisoLocal implements AceiteDoAviso {
  /// Chave usada no armazenamento.
  static const String chave = 'memora.aceite_do_aviso_da_conversa';

  final SharedPreferences _preferencias;

  /// Cria o aceite a partir de uma instância já aberta.
  const AceiteDoAvisoLocal(this._preferencias);

  /// Abre o armazenamento e devolve o aceite pronto para uso.
  static Future<AceiteDoAvisoLocal> abrir() async {
    return AceiteDoAvisoLocal(await SharedPreferences.getInstance());
  }

  @override
  Future<bool> aceitou() async => _preferencias.getBool(chave) ?? false;

  @override
  Future<void> registrar() async {
    await _preferencias.setBool(chave, true);
  }

  @override
  Future<void> apagar() async {
    await _preferencias.remove(chave);
  }
}
