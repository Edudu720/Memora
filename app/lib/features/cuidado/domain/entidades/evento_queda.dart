import 'package:flutter/foundation.dart';
import 'enums_cuidado.dart';

/// Registro de um evento de queda detectado pelos sensores.
@immutable
class EventoQueda {
  /// Cria um registro de [EventoQueda].
  const EventoQueda({
    required this.id,
    required this.timestamp,
    required this.bpmNoImpacto,
    required this.aceleracaoNoImpacto,
    this.status = StatusConfirmacaoQueda.aguardandoConfirmacao,
    this.tempoRestanteSegundos = 45,
    this.encerradoEm,
  });

  /// Cria um novo evento de queda com janela padrão de 45 segundos.
  factory EventoQueda.novo({
    required int bpm,
    required double aceleracao,
  }) {
    return EventoQueda(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      bpmNoImpacto: bpm,
      aceleracaoNoImpacto: aceleracao,
    );
  }

  /// Reconstrói um [EventoQueda] a partir de um payload JSON.
  factory EventoQueda.fromJson(Map<String, dynamic> json) {
    return EventoQueda(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: json['timestamp'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.now(),
      bpmNoImpacto: (json['bpm'] as num?)?.toInt() ?? 0,
      aceleracaoNoImpacto: (json['aceleracao'] as num?)?.toDouble() ?? 2.5,
      tempoRestanteSegundos: (json['tempo_restante'] as num?)?.toInt() ?? 45,
    );
  }

  /// Identificador único do evento.
  final String id;

  /// Data e hora em que o impacto foi detectado.
  final DateTime timestamp;

  /// Batimentos por minuto registrados no instante do impacto.
  final int bpmNoImpacto;

  /// Magnitude de aceleração (em G) no instante do impacto.
  final double aceleracaoNoImpacto;

  /// Estado atual da confirmação de bem-estar.
  final StatusConfirmacaoQueda status;

  /// Segundos restantes antes do acionamento automático de socorro.
  final int tempoRestanteSegundos;

  /// Momento em que o evento foi encerrado.
  final DateTime? encerradoEm;

  /// Cria uma cópia deste evento com os campos informados alterados.
  EventoQueda copyWith({
    String? id,
    DateTime? timestamp,
    int? bpmNoImpacto,
    double? aceleracaoNoImpacto,
    StatusConfirmacaoQueda? status,
    int? tempoRestanteSegundos,
    DateTime? encerradoEm,
  }) {
    return EventoQueda(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      bpmNoImpacto: bpmNoImpacto ?? this.bpmNoImpacto,
      aceleracaoNoImpacto: aceleracaoNoImpacto ?? this.aceleracaoNoImpacto,
      status: status ?? this.status,
      tempoRestanteSegundos: tempoRestanteSegundos ?? this.tempoRestanteSegundos,
      encerradoEm: encerradoEm ?? this.encerradoEm,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventoQueda &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          timestamp == other.timestamp &&
          bpmNoImpacto == other.bpmNoImpacto &&
          aceleracaoNoImpacto == other.aceleracaoNoImpacto &&
          status == other.status &&
          tempoRestanteSegundos == other.tempoRestanteSegundos &&
          encerradoEm == other.encerradoEm;

  @override
  int get hashCode => Object.hash(
        id,
        timestamp,
        bpmNoImpacto,
        aceleracaoNoImpacto,
        status,
        tempoRestanteSegundos,
        encerradoEm,
      );
}
