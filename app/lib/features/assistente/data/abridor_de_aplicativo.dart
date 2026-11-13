import 'package:flutter/services.dart';

import '../../../services/aplicativos/consulta_de_aplicativos.dart'
    show pareceUmPacote;

/// Abre outro aplicativo no aparelho (T054).
///
/// ## Quem abre é o aplicativo, nunca o servidor
///
/// O backend diz *"esta ação está autorizada"* e para aí — ele não tem como
/// abrir aplicativo no aparelho de ninguém, e não deve ter. A confirmação da
/// FR-015 acontece onde a pessoa está, e a abertura também.
///
/// ## O que este código NÃO decide
///
/// Se aquele aplicativo pode ser aberto. Isso já foi decidido pelo
/// `AutorizadorDeAcao`, no servidor, consultando o catálogo. Aqui só se executa
/// o que já foi autorizado — acrescentar uma verificação própria criaria uma
/// segunda regra que pode divergir da primeira.
///
/// ## O limite que o Android impõe
///
/// Desde o Android 11, um aplicativo só enxerga os pacotes declarados em
/// `<queries>` no manifesto. Isso significa que **acrescentar um aplicativo
/// abrível exige publicar versão nova** — mesmo com o catálogo no banco.
///
/// Tirar do ar continua sendo mudança de banco, que era o objetivo da R6. O
/// limite vale só para o sentido de entrada.
abstract interface class AbridorDeAplicativo {
  /// Tenta abrir o aplicativo pelo pacote.
  ///
  /// Devolve `false` quando não deu — aplicativo não instalado, pacote fora do
  /// `<queries>`, ou qualquer falha do sistema. Quem chama transforma isso em
  /// uma frase da Memora; nunca num erro técnico.
  Future<bool> abrir(String identificadorAndroid);
}

/// Implementação sobre o canal de plataforma `memora/abridor` (T136).
///
/// Quem abre é o Android, por `getLaunchIntentForPackage`, em Kotlin. O
/// `android_intent_plus` não serve: ele não traduz `action_main`, e a atividade
/// de entrada dos aplicativos não declara `CATEGORY_DEFAULT`, então a conferência
/// dele recusava tudo — a Memora confirmava com a pessoa e depois não abria
/// nada. É um canal separado do `memora/aplicativos` porque aquele é só leitura
/// por contrato.
///
/// Nenhum erro chega à tela: tudo que não for um `true` do canal é `false`.
class AbridorDeAplicativoPorCanal implements AbridorDeAplicativo {
  /// O nome do canal, igual ao registrado em `MainActivity.kt`.
  static const String nomeDoCanal = 'memora/abridor';

  final MethodChannel _canal;

  /// Cria o abridor. [canal] só muda no teste.
  const AbridorDeAplicativoPorCanal({
    MethodChannel canal = const MethodChannel(nomeDoCanal),
  }) : _canal = canal;

  @override
  Future<bool> abrir(String identificadorAndroid) async {
    // O que não parece pacote nem chega ao canal.
    if (!pareceUmPacote(identificadorAndroid)) return false;
    try {
      return await _canal.invokeMethod<bool>('abrir', identificadorAndroid) ??
          false;
    } catch (_) {
      // PlatformException, MissingPluginException ou tipo inesperado: para a
      // pessoa é só "não consegui abrir".
      return false;
    }
  }
}

/// Abridor que não abre nada, para teste e demonstração.
///
/// Guarda o que teria aberto, para o teste conferir sem depender de haver
/// WhatsApp instalado no emulador.
class AbridorDeAplicativoSimulado implements AbridorDeAplicativo {
  /// O que foi pedido para abrir, na ordem.
  final List<String> abertos = <String>[];

  /// Faz a próxima abertura falhar, como um aplicativo não instalado faria.
  bool falharNaProxima = false;

  /// Cria o abridor simulado.
  AbridorDeAplicativoSimulado();

  @override
  Future<bool> abrir(String identificadorAndroid) async {
    if (falharNaProxima) {
      falharNaProxima = false;
      return false;
    }
    abertos.add(identificadorAndroid);
    return true;
  }
}
