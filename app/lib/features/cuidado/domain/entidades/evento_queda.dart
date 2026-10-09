import 'package:flutter/foundation.dart';
import 'enums_cuidado.dart';

/// Registro de um evento de queda detectado pelos sensores.
@immutable
class EventoQueda {
  const EventoQueda({
    required this.id,
    required this.timestamp,
    required this.bpmNoImpacto,
    required this.aceleracaoNoImpacto,
    this.status = StatusConfirmacaoQueda.aguardandoConfirmacao,
    this.tempoRestanteSegundos = 45,
    this.encerradoEm,
  });

  factory EventoQueda.novo({
    required int bpm,
    required double aceleracao,
  }) {
    return EventoQueda(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      bpmNoImpacto: bpm,
      aceleracaoNoImpacto: aceleracao,
      status: StatusConfirmacaoQueda.aguardandoConfirmacao,
      tempoRestanteSegundos: 45,
    );
  }

  factory EventoQueda.fromJson(Map<String, dynamic> json) {
    return EventoQueda(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: json['timestamp'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.now(),
      bpmNoImpacto: (json['bpm'] as num?)?.toInt() ?? 0,
      aceleracaoNoImpacto: (json['aceleracao'] as num?)?.toDouble() ?? 2.5,
      status: StatusConfirmacaoQueda.aguardandoConfirmacao,
      tempoRestanteSegundos: (json['tempo_restante'] as num?)?.toInt() ?? 45,
    );
  }

  final String id;
  final DateTime timestamp;
  final int bpmNoImpacto;
  final double aceleracaoNoImpacto;
  final StatusConfirmacaoQueda status;
  final int tempoRestanteSegundos;
  final DateTime? encerradoEm;

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

