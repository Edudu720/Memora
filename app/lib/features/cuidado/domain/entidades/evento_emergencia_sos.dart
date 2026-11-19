import 'package:flutter/foundation.dart';

/// Origem do pedido de emergência registrado pelo aplicativo ou dispositivo.
enum TipoEventoEmergencia {
  /// Acionado explicitamente pela pessoa através do botão SOS persistente.
  sosManual('SOS_MANUAL'),

  /// Disparado automaticamente após detecção de queda sem resposta.
  quedaAutomatica('QUEDA_AUTOMATICA');

  /// Código serializado no contrato HTTP com o servidor.
  final String codigoApi;

  const TipoEventoEmergencia(this.codigoApi);

  /// Converte o código textual recebido da API para [TipoEventoEmergencia].
  static TipoEventoEmergencia deApi(String? valor) {
    final String normalizado = (valor ?? '').trim().toUpperCase();
    for (final TipoEventoEmergencia tipo in TipoEventoEmergencia.values) {
      if (tipo.codigoApi == normalizado) {
        return tipo;
      }
    }
    return TipoEventoEmergencia.sosManual;
  }
}

/// Estado real do encaminhamento de uma solicitação SOS.
enum EstadoEventoSos {
  /// Solicitação criada e aguardando início do despacho.
  pendente('PENDENTE'),

  /// Encaminhamento em processamento.
  processando('PROCESSANDO'),

  /// Pedido aceito e despachado pelo canal técnico, sem garantia de leitura.
  enviado('ENVIADO'),

  /// Falha ao encaminhar o pedido ao destinatário.
  falha('FALHA'),

  /// Confirmação explícita de recebimento pelo contato (reservado para futuro).
  confirmadoPeloDestinatario('CONFIRMADO_PELO_DESTINATARIO');

  /// Código serializado no contrato HTTP com o servidor.
  final String codigoApi;

  const EstadoEventoSos(this.codigoApi);

  /// Converte o status recebido da API para [EstadoEventoSos].
  static EstadoEventoSos deApi(String? valor) {
    final String normalizado = (valor ?? '').trim().toUpperCase();
    for (final EstadoEventoSos estado in EstadoEventoSos.values) {
      if (estado.codigoApi == normalizado) {
        return estado;
      }
    }
    return EstadoEventoSos.falha;
  }
}

/// Coordenadas geográficas pontuais anexadas ao SOS somente quando autorizadas.
@immutable
class LocalizacaoSos {
  /// Latitude em graus decimais (`-90` a `90`).
  final double latitude;

  /// Longitude em graus decimais (`-180` a `180`).
  final double longitude;

  /// Cria coordenadas para acompanhar uma solicitação SOS.
  const LocalizacaoSos({
    required this.latitude,
    required this.longitude,
  });

  /// Reconstrói [LocalizacaoSos] a partir de JSON.
  factory LocalizacaoSos.fromJson(Map<String, dynamic> json) {
    return LocalizacaoSos(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  /// Converte para o formato esperado pela API.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalizacaoSos &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

/// Resultado registrado para um evento de emergência SOS.
@immutable
class EventoEmergenciaSos {
  /// Identificador único de idempotência deste pedido (UUID).
  final String eventoId;

  /// Classificação da origem (`SOS_MANUAL` ou `QUEDA_AUTOMATICA`).
  final TipoEventoEmergencia tipo;

  /// Estado verdadeiro do processamento retornado pelo servidor/fluxo.
  final EstadoEventoSos estado;

  /// Mensagem honesta ao usuário sobre o encaminhamento do pedido.
  final String mensagem;

  /// Momento em que o evento foi registrado.
  final DateTime ocorridoEm;

  /// Coordenadas pontuais enviadas com o pedido, quando autorizadas.
  final LocalizacaoSos? localizacao;

  /// Nome ou identificação resumida do contato notificado, quando aplicável.
  final String? contatoNotificado;

  /// Cria um [EventoEmergenciaSos].
  const EventoEmergenciaSos({
    required this.eventoId,
    required this.tipo,
    required this.estado,
    required this.mensagem,
    required this.ocorridoEm,
    this.localizacao,
    this.contatoNotificado,
  });

  /// Reconstrói a resposta devolvida pelo endpoint `/v1/emergencias/sos`.
  factory EventoEmergenciaSos.fromJson(
    Map<String, dynamic> json, {
    LocalizacaoSos? localizacaoEnviada,
    String? contatoNotificado,
  }) {
    final Object? ocorridoBruto = json['ocorridoEm'];
    final DateTime ocorridoEm = ocorridoBruto is String
        ? (DateTime.tryParse(ocorridoBruto)?.toLocal() ?? DateTime.now())
        : DateTime.now();

    return EventoEmergenciaSos(
      eventoId: json['eventoId'] as String? ?? '',
      tipo: TipoEventoEmergencia.deApi(json['tipo'] as String?),
      estado: EstadoEventoSos.deApi(json['status'] as String?),
      mensagem: json['mensagem'] as String? ?? '',
      ocorridoEm: ocorridoEm,
      localizacao: json['localizacao'] is Map<String, dynamic>
          ? LocalizacaoSos.fromJson(
              json['localizacao'] as Map<String, dynamic>,
            )
          : localizacaoEnviada,
      contatoNotificado: contatoNotificado,
    );
  }
}
