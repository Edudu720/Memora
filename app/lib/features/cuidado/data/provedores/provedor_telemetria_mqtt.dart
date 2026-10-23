import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../../domain/entidades/enums_cuidado.dart';
import '../../domain/entidades/evento_queda.dart';
import '../../domain/entidades/telemetria_iot.dart';
import '../../domain/repositorios/provedor_telemetria.dart';

/// Implementação do Provedor de Telemetria com conexão real MQTT via broker.
class ProvedorDeTelemetriaMqtt implements ProvedorDeTelemetria {
  /// Cria um provedor MQTT apontando para o [broker], [porta] e [topicoBase].
  ProvedorDeTelemetriaMqtt({
    this.broker = 'broker.hivemq.com',
    this.porta = 1883,
    this.topicoBase = 'memora/iot/demonstracao-01',
  });

  /// Endereço do broker MQTT.
  final String broker;

  /// Porta TCP do broker MQTT.
  final int porta;

  /// Prefixo base dos tópicos MQTT.
  final String topicoBase;

  MqttServerClient? _cliente;

  final StreamController<TelemetriaIot> _controladorTelemetria =
      StreamController<TelemetriaIot>.broadcast();
  final StreamController<EventoQueda> _controladorQueda =
      StreamController<EventoQueda>.broadcast();
  final StreamController<StatusConexaoIot> _controladorStatus =
      StreamController<StatusConexaoIot>.broadcast();

  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _inscricaoMensagens;
  StatusConexaoIot _statusAtual = StatusConexaoIot.desconectado;

  @override
  Stream<TelemetriaIot> get streamTelemetria => _controladorTelemetria.stream;

  @override
  Stream<EventoQueda> get streamQueda => _controladorQueda.stream;

  @override
  Stream<StatusConexaoIot> get streamStatusConexao => _controladorStatus.stream;

  String get _topicoTelemetria => '$topicoBase/telemetria';
  String get _topicoAlerta => '$topicoBase/alerta';
  String get _topicoComando => '$topicoBase/comando';

  @override
  Future<void> conectar() async {
    if (_statusAtual == StatusConexaoIot.conectado) return;

    _statusAtual = StatusConexaoIot.conectando;
    if (!_controladorStatus.isClosed) {
      _controladorStatus.add(_statusAtual);
    }

    final String brokerAlvo = broker.trim().isEmpty ? 'broker.hivemq.com' : broker.trim();
    String hostFinal = brokerAlvo;
    try {
      final List<InternetAddress> addresses = await InternetAddress.lookup(
        brokerAlvo,
        type: InternetAddressType.IPv4,
      );
      if (addresses.isNotEmpty) {
        hostFinal = addresses.first.address;
      }
    } catch (_) {
      // Mantém o broker original caso a resolução falhe
    }

    final String clientId = 'MemoraApp_${DateTime.now().millisecondsSinceEpoch}';
    final MqttServerClient cliente = MqttServerClient(hostFinal, clientId)
      ..port = porta
      ..keepAlivePeriod = 30
      ..setProtocolV311()
      ..logging(on: false)
      ..onConnected = _aoConectar
      ..onDisconnected = _aoDesconectar;

    cliente.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean();

    _cliente = cliente;

    try {
      final MqttClientConnectionStatus? status = await cliente.connect();
      if (status?.state == MqttConnectionState.connected) {
        _aoConectar();
      } else {
        _aoDesconectar();
      }
    } catch (e) {
      _aoDesconectar();
    }
  }

  void _aoConectar() {
    _statusAtual = StatusConexaoIot.conectado;
    if (!_controladorStatus.isClosed) {
      _controladorStatus.add(_statusAtual);
    }

    _cliente?.subscribe(_topicoTelemetria, MqttQos.atMostOnce);
    _cliente?.subscribe(_topicoAlerta, MqttQos.atLeastOnce);

    _inscricaoMensagens?.cancel();
    _inscricaoMensagens = _cliente?.updates?.listen(_processarMensagensMqtt);
  }

  void _aoDesconectar() {
    _statusAtual = StatusConexaoIot.desconectado;
    if (!_controladorStatus.isClosed) {
      _controladorStatus.add(_statusAtual);
    }
  }

  void _processarMensagensMqtt(List<MqttReceivedMessage<MqttMessage>> mensagens) {
    for (final MqttReceivedMessage<MqttMessage> recebida in mensagens) {
      final String topico = recebida.topic;
      final MqttPublishMessage publicacao = recebida.payload as MqttPublishMessage;
      final String payloadTexto =
          MqttPublishPayload.bytesToStringAsString(publicacao.payload.message);

      try {
        final dynamic jsonDecodificado = jsonDecode(payloadTexto);
        if (jsonDecodificado is! Map<String, dynamic>) continue;

        if (topico == _topicoTelemetria) {
          final TelemetriaIot telemetria = TelemetriaIot.fromJson(jsonDecodificado);
          _controladorTelemetria.add(telemetria);
        } else if (topico == _topicoAlerta) {
          final EventoQueda queda = EventoQueda.fromJson(jsonDecodificado);
          _controladorQueda.add(queda);
        }
      } catch (_) {
        // Ignora payload malformado para resiliência
      }
    }
  }

  @override
  Future<void> enviarComandoCessarAlarme() async {
    if (_cliente?.connectionStatus?.state != MqttConnectionState.connected) {
      return;
    }

    const String payload = '{"comando":"CESSAR_ALARME"}';
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder()
      ..addString(payload);

    _cliente?.publishMessage(
      _topicoComando,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }

  @override
  Future<void> desconectar() async {
    _inscricaoMensagens?.cancel();
    _inscricaoMensagens = null;
    _cliente?.disconnect();
    _cliente = null;
    _aoDesconectar();
  }

  @override
  void descartar() {
    _cliente?.onDisconnected = null;
    _cliente?.onConnected = null;
    desconectar();
    if (!_controladorTelemetria.isClosed) _controladorTelemetria.close();
    if (!_controladorQueda.isClosed) _controladorQueda.close();
    if (!_controladorStatus.isClosed) _controladorStatus.close();
  }
}
