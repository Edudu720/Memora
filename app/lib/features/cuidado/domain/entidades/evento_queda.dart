import 'package:flutter/foundation.dart';
import 'enums_cuidado.dart';

/// Registro de um evento de queda detectado pelos sensores do ESP32 ou simulador.
@immutable
class EventoQueda {
  /// Cria um registro de [EventoQueda].
  const EventoQueda({
    required this.id,
    required this.timestamp,
    required this.bpmNoImpacto,
    required this.aceleracaoNoImpacto,
    this.bpmValido = true,
    this.bpmAntesDaQueda = -1,
    this.movimentoPosImpacto = 0.0,
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
      bpmValido: bpm > 0,
      bpmAntesDaQueda: bpm > 0 ? bpm : -1,
    );
  }

  /// Reconstrói um [EventoQueda] a partir de um payload JSON emitido pelo ESP32.
  factory EventoQueda.fromJson(Map<String, dynamic> json) {
    final int bpmLido = (json['bpm'] as num?)?.toInt() ?? 0;
    final int bpmAntesLido =
        (json['bpm_antes_da_queda'] as num?)?.toInt() ?? -1;
    final bool bpmValidoLido =
        json['bpm_valido'] as bool? ?? (bpmLido > 0);
    final int bpmFinal =
        (bpmLido <= 0 && bpmAntesLido > 0) ? bpmAntesLido : bpmLido;

    DateTime dataHora;
    if (json['timestamp'] is int) {
      final int ts = json['timestamp'] as int;
      dataHora = ts >= 1000000000000
          ? DateTime.fromMillisecondsSinceEpoch(ts)
          : DateTime.now();
    } else {
      dataHora = DateTime.now();
    }

    return EventoQueda(
      id: json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: dataHora,
      bpmNoImpacto: bpmFinal,
      bpmValido: bpmValidoLido,
      bpmAntesDaQueda: bpmAntesLido,
      aceleracaoNoImpacto:
          (json['aceleracao'] as num?)?.toDouble() ?? 2.5,
      movimentoPosImpacto:
          (json['movimento_pos_impacto'] as num?)?.toDouble() ?? 0.0,
      tempoRestanteSegundos:
          (json['tempo_restante'] as num?)?.toInt() ?? 45,
    );
  }

  /// Identificador único do evento.
  final String id;

  /// Data e hora em que o impacto foi detectado.
  final DateTime timestamp;

  /// Batimentos por minuto registrados no instante do impacto (ou pré-queda se o dedo soltou).
  final int bpmNoImpacto;

  /// Indica se o sensor óptico possuía leitura válida no exato instante da confirmação.
  final bool bpmValido;

  /// BPM registrado pelo ESP32 no início da queda livre (-1 quando indisponível).
  final int bpmAntesDaQueda;

  /// Magnitude de aceleração (em G) no instante do impacto.
  final double aceleracaoNoImpacto;

  /// Movimento médio (0 a 100) medido nos 3 segundos de pós-impacto.
  final double movimentoPosImpacto;

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
    bool? bpmValido,
    int? bpmAntesDaQueda,
    double? aceleracaoNoImpacto,
    double? movimentoPosImpacto,
    StatusConfirmacaoQueda? status,
    int? tempoRestanteSegundos,
    DateTime? encerradoEm,
  }) {
    return EventoQueda(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      bpmNoImpacto: bpmNoImpacto ?? this.bpmNoImpacto,
      bpmValido: bpmValido ?? this.bpmValido,
      bpmAntesDaQueda: bpmAntesDaQueda ?? this.bpmAntesDaQueda,
      aceleracaoNoImpacto: aceleracaoNoImpacto ?? this.aceleracaoNoImpacto,
      movimentoPosImpacto: movimentoPosImpacto ?? this.movimentoPosImpacto,
      status: status ?? this.status,
      tempoRestanteSegundos:
          tempoRestanteSegundos ?? this.tempoRestanteSegundos,
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
          bpmValido == other.bpmValido &&
          bpmAntesDaQueda == other.bpmAntesDaQueda &&
          aceleracaoNoImpacto == other.aceleracaoNoImpacto &&
          movimentoPosImpacto == other.movimentoPosImpacto &&
          status == other.status &&
          tempoRestanteSegundos == other.tempoRestanteSegundos &&
          encerradoEm == other.encerradoEm;

  @override
  int get hashCode => Object.hash(
        id,
        timestamp,
        bpmNoImpacto,
        bpmValido,
        bpmAntesDaQueda,
        aceleracaoNoImpacto,
        movimentoPosImpacto,
        status,
        tempoRestanteSegundos,
        encerradoEm,
      );
}
