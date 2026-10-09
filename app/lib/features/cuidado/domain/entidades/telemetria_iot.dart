import 'package:flutter/foundation.dart';

/// Amostra instantânea de telemetria emitida pelo ESP32 ou simulador.
@immutable
class TelemetriaIot {
  const TelemetriaIot({
    required this.timestamp,
    required this.bpm,
    required this.aceleracaoG,
    required this.nivelMovimento,
    required this.emMovimento,
    required this.estadoSensor,
  });

  factory TelemetriaIot.fromJson(Map<String, dynamic> json) {
    final int bpmLido = (json['bpm'] as num?)?.toInt() ?? 0;
    final double aceleracaoLida = (json['aceleracao'] as num?)?.toDouble() ?? 1.0;
    final double movimentoLido = (json['movimento'] as num?)?.toDouble() ?? 0.0;
    final bool movimentoBool = json['em_movimento'] as bool? ?? (movimentoLido >= 5.0);
    final String estado = json['estado'] as String? ?? 'INERTE';
    
    DateTime dataHora;
    if (json['timestamp'] is int) {
      dataHora = DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int);
    } else {
      dataHora = DateTime.now();
    }

    return TelemetriaIot(
      timestamp: dataHora,
      bpm: bpmLido,
      aceleracaoG: aceleracaoLida,
      nivelMovimento: movimentoLido,
      emMovimento: movimentoBool,
      estadoSensor: estado,
    );
  }

  final DateTime timestamp;
  final int bpm;
  final double aceleracaoG;
  final double nivelMovimento;
  final bool emMovimento;
  final String estadoSensor;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'timestamp': timestamp.millisecondsSinceEpoch,
      'bpm': bpm,
      'aceleracao': aceleracaoG,
      'movimento': nivelMovimento,
      'em_movimento': emMovimento,
      'estado': estadoSensor,
    };
  }

  TelemetriaIot copyWith({
    DateTime? timestamp,
    int? bpm,
    double? aceleracaoG,
    double? nivelMovimento,
    bool? emMovimento,
    String? estadoSensor,
  }) {
    return TelemetriaIot(
      timestamp: timestamp ?? this.timestamp,
      bpm: bpm ?? this.bpm,
      aceleracaoG: aceleracaoG ?? this.aceleracaoG,
      nivelMovimento: nivelMovimento ?? this.nivelMovimento,
      emMovimento: emMovimento ?? this.emMovimento,
      estadoSensor: estadoSensor ?? this.estadoSensor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TelemetriaIot &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          bpm == other.bpm &&
          aceleracaoG == other.aceleracaoG &&
          nivelMovimento == other.nivelMovimento &&
          emMovimento == other.emMovimento &&
          estadoSensor == other.estadoSensor;

  @override
  int get hashCode => Object.hash(
        timestamp,
        bpm,
        aceleracaoG,
        nivelMovimento,
        emMovimento,
        estadoSensor,
      );
}

