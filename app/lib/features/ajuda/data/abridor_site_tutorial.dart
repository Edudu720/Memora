import 'package:url_launcher/url_launcher.dart';

import '../../../services/ambiente/ambiente.dart';

/// Abre o site oficial de tutoriais da Memora no navegador externo do aparelho
/// (Issue #106 Item 11, feature 016).
///
/// ## Proteção contra phishing (Princípio II)
///
/// [abrir] não recebe endereço nenhum: quem cria o abridor fixa uma única vez
/// o [endereco] já validado por [Ambiente.enderecoOficial] (protocolo estrito
/// `https://`, servidor obrigatório, sem credenciais embutidas nem espaços).
/// Enquanto o endereço oficial não for configurado no build, [doAmbiente]
/// retorna `null` e a tela de Ajuda não exibe botão quebrado nem enganoso.
abstract interface class AbridorDeSiteTutorial {
  /// Endereço oficial `https://` exibido no diálogo antes de sair do Memora.
  String get endereco;

  /// Solicita a abertura do navegador externo no [endereco] oficial.
  ///
  /// Retorna `false` caso o aparelho não consiga abrir o endereço — a tela de
  /// Ajuda transforma isso em aviso calmo na voz da Memora.
  Future<bool> abrir();

  /// Cria o abridor a partir do [ambiente], ou retorna `null` quando não há
  /// endereço oficial `https://` válido configurado.
  static AbridorDeSiteTutorial? doAmbiente(Ambiente ambiente) {
    final String? endereco = Ambiente.enderecoOficial(ambiente.urlSiteTutorial);
    if (endereco == null) return null;
    return AbridorDeSiteTutorialUrlLauncher(endereco);
  }
}

/// Implementação real utilizando `url_launcher` em navegador externo.
class AbridorDeSiteTutorialUrlLauncher implements AbridorDeSiteTutorial {
  @override
  final String endereco;

  /// Cria o abridor para [endereco], revalidado antes de qualquer abertura.
  const AbridorDeSiteTutorialUrlLauncher(this.endereco);

  @override
  Future<bool> abrir() async {
    final String? seguro = Ambiente.enderecoOficial(endereco);
    if (seguro == null) return false;
    final Uri? uri = Uri.tryParse(seguro);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return false;
    }
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }
}

/// Implementação controlada para testes sem abrir o navegador do sistema.
class AbridorDeSiteTutorialSimulado implements AbridorDeSiteTutorial {
  @override
  final String endereco;

  /// Histórico de chamadas bem-sucedidas a [abrir].
  final List<String> abertos = <String>[];

  /// Faz a próxima tentativa de abertura retornar `false`.
  bool falharNoProximo = false;

  /// Cria o abridor simulado com [endereco] fixo.
  AbridorDeSiteTutorialSimulado(this.endereco);

  @override
  Future<bool> abrir() async {
    if (falharNoProximo) {
      falharNoProximo = false;
      return false;
    }
    abertos.add(endereco);
    return true;
  }
}
