import '../entidades/atalho_aplicativo.dart';

/// Contrato do repositório responsável por fornecer os atalhos de aplicativos
/// com o estado atual de instalação no dispositivo.
abstract interface class IRepositorioAtalhos {
  /// Consulta a lista de aplicativos comuns e atualiza o estado de instalação.
  Future<List<AtalhoAplicativo>> obterAtalhos();
}
