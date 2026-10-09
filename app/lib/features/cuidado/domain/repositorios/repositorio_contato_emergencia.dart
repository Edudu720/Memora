import '../entidades/contato_emergencia.dart';

/// Contrato para persistência segura do contato de emergência no aparelho.
abstract class RepositorioContatoEmergencia {
  /// Obtém o contato de emergência cadastrado atualmente, se houver.
  Future<ContatoEmergencia?> obterContato();

  /// Salva ou atualiza os dados do contato de emergência.
  Future<void> salvarContato(ContatoEmergencia contato);

  /// Remove o contato de emergência cadastrado.
  Future<void> removerContato();
}

