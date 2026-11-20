import 'dart:async';
import '../entidades/enums_cuidado.dart';
import '../entidades/evento_queda.dart';
import '../entidades/telemetria_iot.dart';

/// Contrato para recepção de dados em tempo real do dispositivo IoT (ESP32 físico via MQTT ou simulador local).
abstract class ProvedorDeTelemetria {
  /// Fluxo de telemetria contínua (BPM, movimentação, aceleração).
  Stream<TelemetriaIot> get streamTelemetria;

  /// Fluxo de eventos críticos de queda disparados pelos sensores.
  Stream<EventoQueda> get streamQueda;

  /// Fluxo do estado da conexão com o dispositivo ou broker.
  Stream<StatusConexaoIot> get streamStatusConexao;

  /// Conecta ao broker MQTT ou inicia o gerador simulado.
  Future<void> conectar();

  /// Desconecta e libera recursos de rede.
  Future<void> desconectar();

  /// Envia comando ao ESP32 para desligar o buzzer e cessar o alarme.
  Future<void> enviarComandoCessarAlarme();

  /// Encerra os streams.
  void descartar();
}

