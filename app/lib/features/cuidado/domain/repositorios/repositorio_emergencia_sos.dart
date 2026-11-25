import '../entidades/contato_emergencia.dart';
import '../entidades/evento_emergencia_sos.dart';

/// Erro específico de transporte/rede ao tentar acionar o SOS remoto.
class FalhaDeConexaoSosException implements Exception {
  /// Descrição técnica resumida para depuração.
  final String mensagem;

  /// Indica ausência de internet ou indisponibilidade de conexão.
  const FalhaDeConexaoSosException([this.mensagem = 'Sem conexão com a rede']);

  @override
  String toString() => 'FalhaDeConexaoSosException: $mensagem';
}

/// Contrato de envio de pedidos de emergência SOS ao servidor ou simulador.
abstract class RepositorioEmergenciaSos {
  /// Registra e solicita o encaminhamento idempotente do evento [eventoId].
  Future<EventoEmergenciaSos> solicitarSos({
    required String eventoId,
    required TipoEventoEmergencia tipo,
    LocalizacaoSos? localizacao,
    ContatoEmergencia? contato,
  });
}
