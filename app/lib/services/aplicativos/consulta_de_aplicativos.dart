import 'package:flutter/services.dart';

/// A forma que um nome de pacote Android precisa ter para ser consultado.
///
/// É a mesma expressão do lado Kotlin (`CanalDeAplicativos.kt`) e a do
/// contrato `canal-aplicativos.md`. O que não casa **nem chega ao canal**:
/// quem controla o argumento não ganha uma pergunta ao sistema.
final RegExp formaDePacote = RegExp(
  r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$',
);

/// Este texto parece um nome de pacote?
bool pareceUmPacote(String texto) => formaDePacote.hasMatch(texto);

/// O que o aparelho sabe dos aplicativos que a Memora conhece (T059, R7).
///
/// **Só lê.** Abrir continua sendo do `AbridorDeAplicativo`, que passa pela
/// confirmação e pelo registro. Esta porta não ganha `abrir`.
///
/// Nenhum método lança: quem chama recebe `false` ou `null` e desenha a
/// ilustração genérica.
abstract interface class ConsultaDeAplicativos {
  /// O aplicativo [pacote] está instalado e visível ao Memora?
  ///
  /// Só enxerga o que está em `<queries>` no manifesto (Android 11+); o resto
  /// aparece como `false`.
  Future<bool> estaInstalado(String pacote);

  /// O ícone de [pacote], em PNG de 192x192, ou `null`.
  Future<Uint8List?> iconeDe(String pacote);
}

/// A consulta sobre o canal de plataforma `memora/aplicativos`.
///
/// ## O cache
///
/// A grade de "Meus aplicativos" pede vários ícones de uma vez, e cada pedido
/// atravessa o canal. O ícone **encontrado** fica em memória, por pacote,
/// durante a execução; pedidos simultâneos do mesmo pacote dividem a mesma
/// ida ao canal.
///
/// **Resposta ausente não fica guardada.** O motivo é o próprio uso: quem é
/// mandado "baixar na loja oficial" volta ao Memora com o aplicativo recém
/// instalado, e um `null` guardado esconderia o ícone até reabrir o app.
/// [estaInstalado] também nunca é cacheado, pelo mesmo motivo.
class ConsultaDeAplicativosPorCanal implements ConsultaDeAplicativos {
  /// O nome do canal, igual ao registrado em `MainActivity.kt`.
  static const String nomeDoCanal = 'memora/aplicativos';

  final MethodChannel _canal;
  final Map<String, Future<Uint8List?>> _icones =
      <String, Future<Uint8List?>>{};

  /// Cria a consulta. [canal] só muda no teste.
  ConsultaDeAplicativosPorCanal({MethodChannel? canal})
    : _canal = canal ?? const MethodChannel(nomeDoCanal);

  @override
  Future<bool> estaInstalado(String pacote) async {
    if (!pareceUmPacote(pacote)) return false;
    try {
      return await _canal.invokeMethod<bool>('estaInstalado', pacote) ?? false;
    } catch (_) {
      // PlatformException, MissingPluginException, tipo inesperado: tudo é
      // "não sei", e "não sei" é "não instalado" para a tela.
      return false;
    }
  }

  @override
  Future<Uint8List?> iconeDe(String pacote) {
    if (!pareceUmPacote(pacote)) return Future<Uint8List?>.value();

    final Future<Uint8List?>? emAndamento = _icones[pacote];
    if (emAndamento != null) return emAndamento;

    final Future<Uint8List?> pedido = _pedirIcone(pacote).then((
      Uint8List? icone,
    ) {
      // Só o que veio fica. Ver o cabeçalho.
      if (icone == null) _icones.remove(pacote);
      return icone;
    });
    _icones[pacote] = pedido;
    return pedido;
  }

  Future<Uint8List?> _pedirIcone(String pacote) async {
    try {
      final Uint8List? bytes = await _canal.invokeMethod<Uint8List>(
        'iconeDe',
        pacote,
      );
      return (bytes == null || bytes.isEmpty) ? null : bytes;
    } catch (_) {
      return null;
    }
  }
}

/// A consulta que roda em todo teste de widget.
///
/// Canal de plataforma não existe em `flutter test`; aqui o teste escolhe o
/// que está instalado e quais ícones existem. Respeita a mesma regra de forma
/// do pacote que o canal de verdade.
class ConsultaDeAplicativosSimulada implements ConsultaDeAplicativos {
  /// Os pacotes que o aparelho "tem".
  final Set<String> instalados;

  /// Os ícones que o aparelho "tem", por pacote.
  final Map<String, Uint8List> icones;

  /// Cria a consulta simulada. Sem argumentos, nada está instalado.
  ConsultaDeAplicativosSimulada({
    Set<String> instalados = const <String>{},
    Map<String, Uint8List> icones = const <String, Uint8List>{},
  }) : instalados = Set<String>.of(instalados),
       icones = Map<String, Uint8List>.of(icones);

  @override
  Future<bool> estaInstalado(String pacote) async =>
      pareceUmPacote(pacote) && instalados.contains(pacote);

  @override
  Future<Uint8List?> iconeDe(String pacote) async {
    if (!pareceUmPacote(pacote) || !instalados.contains(pacote)) return null;
    return icones[pacote];
  }
}
