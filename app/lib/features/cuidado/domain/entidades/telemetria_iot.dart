import 'package:flutter/foundation.dart';

/// Amostra instantânea de telemetria emitida pelo ESP32 físico ou simulador.
@immutable
class TelemetriaIot {
  /// Cria uma leitura de [TelemetriaIot].
  const TelemetriaIot({
    required this.timestamp,
    required this.bpm,
    required this.aceleracaoG,
    required this.nivelMovimento,
    required this.emMovimento,
    required this.estadoSensor,
    this.bpmValido = true,
  });

  /// Reconstrói uma leitura [TelemetriaIot] a partir de um mapa JSON.
  factory TelemetriaIot.fromJson(Map<String, dynamic> json) {
    final int bpmLido = (json['bpm'] as num?)?.toInt() ?? 0;
    final bool bpmValidoLido =
        json['bpm_valido'] as bool? ?? (bpmLido > 0);
    final double aceleracaoLida =
        (json['aceleracao'] as num?)?.toDouble() ?? 1.0;
    final double movimentoLido =
        (json['movimento'] as num?)?.toDouble() ?? 0.0;
    final String estado = json['estado'] as String? ?? 'INERTE';
    final bool movimentoBool = json['em_movimento'] as bool? ??
        (estado == 'EM_MOVIMENTO' ||
            estado == 'MOVIMENTO' ||
            movimentoLido >= 3.0);

    DateTime dataHora;
    if (json['timestamp'] is int) {
      final int ts = json['timestamp'] as int;
      // Valores >= 1000000000000 representam epoch Unix em ms;
      // valores menores representam millis() desde o boot do ESP32.
      dataHora = ts >= 1000000000000
          ? DateTime.fromMillisecondsSinceEpoch(ts)
          : DateTime.now();
    } else {
      dataHora = DateTime.now();
    }

    return TelemetriaIot(
      timestamp: dataHora,
      bpm: bpmLido,
      bpmValido: bpmValidoLido,
      aceleracaoG: aceleracaoLida,
      nivelMovimento: movimentoLido,
      emMovimento: movimentoBool,
      estadoSensor: estado,
    );
  }

  /// Instante da leitura.
  final DateTime timestamp;

  /// Frequência cardíaca em batimentos por minuto.
  final int bpm;

  /// Indica se o sensor óptico PPG possui leitura válida recente.
  final bool bpmValido;

  /// Aceleração resultante em múltiplos de G.
  final double aceleracaoG;

  /// Índice numérico de movimentação (0 a 100).
  final double nivelMovimento;

  /// Indica se a pessoa está em movimento ativo.
  final bool emMovimento;

  /// Estado reportado pela máquina de estados do firmware.
  final String estadoSensor;

  /// Converte esta leitura para mapa JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'timestamp': timestamp.millisecondsSinceEpoch,
      'bpm': bpm,
      'bpm_valido': bpmValido,
      'aceleracao': aceleracaoG,
      'movimento': nivelMovimento,
      'em_movimento': emMovimento,
      'estado': estadoSensor,
    };
  }

  /// Cria uma cópia desta leitura com os campos informados alterados.
  TelemetriaIot copyWith({
    DateTime? timestamp,
    int? bpm,
    bool? bpmValido,
    double? aceleracaoG,
    double? nivelMovimento,
    bool? emMovimento,
    String? estadoSensor,
  }) {
    return TelemetriaIot(
      timestamp: timestamp ?? this.timestamp,
      bpm: bpm ?? this.bpm,
      bpmValido: bpmValido ?? this.bpmValido,
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
          bpmValido == other.bpmValido &&
          aceleracaoG == other.aceleracaoG &&
          nivelMovimento == other.nivelMovimento &&
          emMovimento == other.emMovimento &&
          estadoSensor == other.estadoSensor;

  @override
  int get hashCode => Object.hash(
        timestamp,
        bpm,
        bpmValido,
        aceleracaoG,
        nivelMovimento,
        emMovimento,
        estadoSensor,
      );
}
