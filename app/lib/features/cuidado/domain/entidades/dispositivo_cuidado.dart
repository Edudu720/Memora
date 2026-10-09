import 'package:flutter/foundation.dart';
import 'enums_cuidado.dart';
import 'telemetria_iot.dart';

/// Entidade que representa o dispositivo de monitoramento vestível do idoso.
@immutable
class DispositivoCuidado {
  const DispositivoCuidado({
    required this.id,
    required this.nome,
    this.statusConexao = StatusConexaoIot.desconectado,
    this.ultimaTelemetria,
    this.modoOperacao = ModoOperacaoIot.simulado,
    this.brokerHost = 'broker.hivemq.com',
    this.topicoBase = 'memora/iot/demonstracao-01',
  });

  final String id;
  final String nome;
  final StatusConexaoIot statusConexao;
  final TelemetriaIot? ultimaTelemetria;
  final ModoOperacaoIot modoOperacao;
  final String brokerHost;
  final String topicoBase;

  bool get estaConectado => statusConexao == StatusConexaoIot.conectado;

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

