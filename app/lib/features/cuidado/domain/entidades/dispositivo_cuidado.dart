import 'package:flutter/foundation.dart';
import 'enums_cuidado.dart';
import 'telemetria_iot.dart';

/// Entidade que representa o dispositivo de monitoramento vestível do idoso.
@immutable
class DispositivoCuidado {
  /// Cria uma instância de [DispositivoCuidado].
  const DispositivoCuidado({
    required this.id,
    required this.nome,
    this.statusConexao = StatusConexaoIot.desconectado,
    this.ultimaTelemetria,
    this.modoOperacao = ModoOperacaoIot.simulado,
    this.brokerHost = 'broker.hivemq.com',
    this.topicoBase = 'memora/iot/demonstracao-01',
  });

  /// Identificador do dispositivo.
  final String id;

  /// Nome amigável do dispositivo.
  final String nome;

  /// Estado atual da conexão.
  final StatusConexaoIot statusConexao;

  /// Última leitura de telemetria recebida.
  final TelemetriaIot? ultimaTelemetria;

  /// Modo de operação ativo (simulado ou MQTT).
  final ModoOperacaoIot modoOperacao;

  /// Endereço do broker MQTT.
  final String brokerHost;

  /// Prefixo base dos tópicos MQTT.
  final String topicoBase;

  /// Indica se o dispositivo está conectado no momento.
  bool get estaConectado => statusConexao == StatusConexaoIot.conectado;

  /// Cria uma cópia deste dispositivo com os campos informados alterados.
  DispositivoCuidado copyWith({
    String? id,
    String? nome,
    StatusConexaoIot? statusConexao,
    TelemetriaIot? ultimaTelemetria,
    ModoOperacaoIot? modoOperacao,
    String? brokerHost,
    String? topicoBase,
  }) {
    return DispositivoCuidado(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      statusConexao: statusConexao ?? this.statusConexao,
      ultimaTelemetria: ultimaTelemetria ?? this.ultimaTelemetria,
      modoOperacao: modoOperacao ?? this.modoOperacao,
      brokerHost: brokerHost ?? this.brokerHost,
      topicoBase: topicoBase ?? this.topicoBase,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DispositivoCuidado &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nome == other.nome &&
          statusConexao == other.statusConexao &&
          ultimaTelemetria == other.ultimaTelemetria &&
          modoOperacao == other.modoOperacao &&
          brokerHost == other.brokerHost &&
          topicoBase == other.topicoBase;

  @override
  int get hashCode => Object.hash(
        id,
        nome,
        statusConexao,
        ultimaTelemetria,
        modoOperacao,
        brokerHost,
        topicoBase,
      );
}
