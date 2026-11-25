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

  /// O endereço oficial de download do Memora, ou nulo quando não há (T089).
  ///
  /// Vem de `--dart-define=MEMORA_URL_DOWNLOAD`, **no build** — nada que a
  /// pessoa digite chega aqui, e é por isso que o "Compartilhar" da Ajuda
  /// pode mandá-lo para fora do aplicativo (FR-035, FR-037). Hoje o aplicativo
  /// não está publicado e não há endereço: nulo, e o assunto "Compartilhar"
  /// não existe (R12).
  ///
  /// Só entra aqui um endereço que passou por [enderecoOficial]; o construtor
  /// não o confere, porque quem constrói à mão é teste.
  final String? urlDownload;

  /// Endereço oficial `https://` do site de tutoriais exibido na Ajuda
  /// (Issue #106 Item 11, features 016 e 017), ou nulo quando explicitamente
  /// desabilitado.
  ///
  /// Usa [urlSiteTutorialPadrao] por padrão e pode ser sobrescrito ou limpo
  /// via `--dart-define=MEMORA_URL_SITE_TUTORIAL=...`, passando sempre por
  /// [enderecoOficial]: nunca aceita `http://`, usuário em URL nem texto
  /// digitado pela pessoa usuária.
  final String? urlSiteTutorial;

  /// Cria uma configuração de ambiente.
  const Ambiente({
    required this.urlBase,
    required this.usaServidorReal,
    this.urlDownload,
    this.urlSiteTutorial,
  });

  /// Confere o endereço de download informado no build.
  ///
  /// Devolve o endereço limpo, ou nulo quando não serve — e nulo é "o
  /// Compartilhar não existe", nunca "o Compartilhar manda qualquer coisa".
  /// Serve só `https://`, com nome de servidor, **sem usuário e senha** na
  /// frente (`https://loja.com@golpe.com` parece um e-mail da loja e leva ao
  /// golpe), sem espaço nem quebra de linha. Endereço sem cifra levaria a
  /// pessoa a baixar o aplicativo por um caminho que qualquer rede adultera.
  static String? enderecoOficial(String? bruto) {
    final String? texto = bruto?.trim();
    if (texto == null || texto.isEmpty) return null;
    if (texto.contains(RegExp(r'\s'))) return null;
    final Uri? uri = Uri.tryParse(texto);
    if (uri == null) return null;
    if (uri.scheme != 'https') return null;
    final int inicioAutoridade = texto.indexOf('://');
    if (inicioAutoridade == -1) return null;
    final String autoridadeBruta = texto
        .substring(inicioAutoridade + 3)
        .split(RegExp(r'[/?#]'))
        .first;
    if (autoridadeBruta.contains('@')) return null;
    if (uri.host.isEmpty) return null;
    if (uri.userInfo.isNotEmpty) return null;
    return texto;
  }

  /// Padrão de desenvolvimento: o hospedeiro do emulador Android.
  static const String urlBasePadrao = 'http://10.0.2.2:8080/v1';

  /// Endereço oficial publicado do site de tutoriais no Render (Issue #106).
  static const String urlSiteTutorialPadrao =
      'https://memora-site-thf2.onrender.com/';

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

    const String download = String.fromEnvironment('MEMORA_URL_DOWNLOAD');
    const String siteTutorial = String.fromEnvironment(
      'MEMORA_URL_SITE_TUTORIAL',
      defaultValue: urlSiteTutorialPadrao,
    );

    return Ambiente(
      urlBase: url,
      usaServidorReal: real,
      urlDownload: enderecoOficial(download),
      urlSiteTutorial: enderecoOficial(siteTutorial),
    );
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
