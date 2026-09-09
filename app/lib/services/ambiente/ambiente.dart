import 'package:flutter/foundation.dart';

/// De onde o aplicativo fala com o servidor, e se ele fala com um de verdade.
///
/// ## A pendência que isto resolve sem decidir nada
///
/// O `CLAUDE.md` listava "de onde vem a URL base do servidor" como pendência
/// bloqueante à espera de uma decisão de spec. Ela travava a integração inteira,
/// e travava por um motivo frágil: a spec não precisa escolher **uma** URL, ela
/// precisa que exista **um lugar** onde a URL seja escolhida. Isto é esse lugar.
///
/// A URL vem de `--dart-define`, com um padrão que serve ao caso mais comum de
/// desenvolvimento. Nada fica escrito em widget nenhum, e a mudança de servidor
/// não recompila regra de negócio.
///
/// ## Por que `10.0.2.2` e não `localhost`
///
/// Dentro do emulador Android, `localhost` é o **próprio emulador** — o Spring
/// Boot rodando na máquina do desenvolvedor é invisível dali. `10.0.2.2` é o
/// alias que o emulador dá ao hospedeiro. Esta é a primeira pedra em que toda
/// integração Flutter/Android tropeça, e ela custa uma tarde a quem não sabe:
/// o erro é `Connection refused`, que parece servidor fora do ar.
///
/// Em aparelho físico nem um nem outro serve — é preciso o IP da máquina na
/// rede local, e daí a URL ser configurável e não constante.
///
/// ## Texto puro em desenvolvimento, e só nele
///
/// [exigeTls] recusa `http://` fora de depuração. Trafegar token de sessão em
/// texto puro é entregar a conta a quem estiver na mesma rede — e a FR-036
/// guarda esse token em armazenamento seguro justamente porque ele vale a
/// conta. Proteger o token em repouso e expô-lo em trânsito seria trancar a
/// porta e deixar a janela aberta.
@immutable
class Ambiente {
  /// Endereço base do servidor, incluindo o `/v1`.
  final String urlBase;

  /// O aplicativo fala com um servidor de verdade?
  ///
  /// Quando `false`, os repositórios simulados assumem — é o que permite
  /// exercitar as telas sem backend, sem provedor de IA e sem banco.
  final bool usaServidorReal;

  /// Cria uma configuração de ambiente.
  const Ambiente({required this.urlBase, required this.usaServidorReal});

  /// Padrão de desenvolvimento: o hospedeiro do emulador Android.
  static const String urlBasePadrao = 'http://10.0.2.2:8080/v1';

  /// Lê a configuração passada na linha de comando.
  ///
  /// ```powershell
  /// flutter run --dart-define=MEMORA_URL_BASE=http://10.0.2.2:8080/v1 --dart-define=MEMORA_SERVIDOR_REAL=true
  /// ```
  ///
  /// **O padrão é o simulado**, e isso é deliberado: quem clona o repositório e
  /// roda `flutter run` sem argumento nenhum vê o aplicativo funcionando, em vez
  /// de uma tela de erro de rede. Falar com servidor é o caso que se pede, não o
  /// que se recebe por descuido.
  factory Ambiente.doAmbiente() {
    const String url = String.fromEnvironment(
      'MEMORA_URL_BASE',
      defaultValue: urlBasePadrao,
    );
    const bool real = bool.fromEnvironment('MEMORA_SERVIDOR_REAL');

    return Ambiente(urlBase: url, usaServidorReal: real);
  }

  /// O endereço trafega cifrado?
  bool get usaTls => urlBase.startsWith('https://');

  /// Recusa texto puro fora de depuração.
  ///
  /// Chamado na subida do aplicativo. Falhar aqui é ruidoso e cedo; deixar
  /// passar seria silencioso e tarde — o tipo de descuido que só aparece quando
  /// alguém já capturou uma sessão.
  void exigirTlsForaDeDepuracao() {
    if (usaServidorReal && !usaTls && !kDebugMode) {
      throw StateError(
        'O Memora recusa falar com $urlBase fora de depuração: o token de '
        'sessão viajaria em texto puro. Use https://.',
      );
    }
  }

  @override
  String toString() =>
      'Ambiente(urlBase: $urlBase, usaServidorReal: $usaServidorReal)';
}
