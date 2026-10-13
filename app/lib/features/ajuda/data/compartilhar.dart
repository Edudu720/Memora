import 'package:android_intent_plus/android_intent.dart';

import '../../../l10n/textos_ajuda.dart';
import '../../../services/ambiente/ambiente.dart';

/// Manda o endereço oficial de download do Memora para fora do aplicativo
/// (T089, FR-035, FR-037).
///
/// ## O que esta porta **não** tem
///
/// Nenhum parâmetro de texto. [compartilhar] não recebe o que enviar: o que
/// vai é o [endereco], que quem constrói passou **uma vez**, e ele vem do
/// `--dart-define=MEMORA_URL_DOWNLOAD` do build. Não há caminho por onde
/// aquilo que a pessoa digitou, o nome dela, a conta ou a conversa cheguem à
/// folha de compartilhar — e uma porta com `compartilhar(String texto)` seria
/// o ponto exato onde, um dia, alguém passaria um deles "só dessa vez".
///
/// ## Como um golpista exploraria isto
///
/// Trocando o link: um endereço de download falso, distribuído como "o Memora
/// oficial". Por isso o endereço só entra pelo build ([Ambiente.enderecoOficial]
/// recusa o que não é `https://`, o que tem usuário na frente do servidor e o
/// que tem espaço) e nunca por campo de tela nem por servidor.
abstract interface class Compartilhador {
  /// O endereço oficial que será enviado. É mostrado à pessoa **antes** de
  /// abrir a folha (FR-037: dizer para onde leva).
  String get endereco;

  /// Abre a folha de compartilhar do sistema com [endereco], e só ele.
  ///
  /// Devolve `false` quando não deu; quem chama transforma isso numa frase da
  /// Memora, nunca num erro técnico.
  Future<bool> compartilhar();

  /// O compartilhador do ambiente, ou **nulo** quando não há endereço oficial
  /// de download.
  ///
  /// Nulo é "o assunto Compartilhar não existe" (R12, FR-018). Esta é a única
  /// porta de entrada de um endereço no aplicativo.
  static Compartilhador? doAmbiente(Ambiente ambiente) {
    final String? endereco = Ambiente.enderecoOficial(ambiente.urlDownload);
    if (endereco == null) return null;
    return CompartilhadorAndroid(endereco);
  }
}

/// `Intent.ACTION_SEND`, escrita por inteiro (ver [intencaoDeCompartilhamento]).
const String acaoDeEnviar = 'android.intent.action.SEND';

/// A intenção que o Android recebe: um `ACTION_SEND` de texto, com o endereço e
/// mais nada.
///
/// Função à parte para o teste conferir **tudo** o que viaja — ação, tipo e
/// extras — sem depender de um aparelho. Qualquer campo a mais aqui é dado
/// saindo do aplicativo.
AndroidIntent intencaoDeCompartilhamento(String endereco) {
  return AndroidIntent(
    // A constante inteira, e nao o apelido 'action_send': o android_intent_plus
    // so traduz 'action_view' e alguns de configuracoes, e repassa o resto ao
    // Android como esta. Nenhum aplicativo atende 'action_send', e a folha
    // abriria vazia.
    action: acaoDeEnviar,
    type: 'text/plain',
    arguments: <String, dynamic>{'android.intent.extra.TEXT': endereco},
  );
}

/// Implementação sobre `android_intent_plus` (R12).
class CompartilhadorAndroid implements Compartilhador {
  @override
  final String endereco;

  /// Cria o compartilhador de [endereco], que já deve ter passado por
  /// [Ambiente.enderecoOficial].
  const CompartilhadorAndroid(this.endereco);

  @override
  Future<bool> compartilhar() async {
    try {
      // A folha do sistema (`ACTION_CHOOSER`): quem escolhe para onde vai é a
      // pessoa, e o Memora não sabe nem precisa saber o destino.
      await intencaoDeCompartilhamento(
        endereco,
      ).launchChooser(TextosAjuda.tituloDaFolha);
      return true;
    } on Exception {
      return false;
    }
  }
}

/// Compartilhador que não abre nada, para teste e demonstração.
///
/// Guarda **tudo** o que teria enviado, para o teste conferir que só o endereço
/// oficial saiu.
class CompartilhadorSimulado implements Compartilhador {
  @override
  final String endereco;

  /// O que foi enviado, na ordem.
  final List<String> enviados = <String>[];

  /// Faz o próximo envio falhar, como uma folha que não abre.
  bool falharNoProximo = false;

  /// Cria o compartilhador simulado.
  CompartilhadorSimulado(this.endereco);

  @override
  Future<bool> compartilhar() async {
    if (falharNoProximo) {
      falharNoProximo = false;
      return false;
    }
    enviados.add(endereco);
    return true;
  }
}
