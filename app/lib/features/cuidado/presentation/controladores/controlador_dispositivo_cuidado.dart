import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/provedores/provedor_telemetria_mqtt.dart';
import '../../data/provedores/provedor_telemetria_simulado.dart';
import '../../domain/entidades/contato_emergencia.dart';
import '../../domain/entidades/dispositivo_cuidado.dart';
import '../../domain/entidades/enums_cuidado.dart';
import '../../domain/entidades/evento_queda.dart';
import '../../domain/entidades/telemetria_iot.dart';
import '../../domain/repositorios/provedor_telemetria.dart';
import '../../domain/repositorios/repositorio_contato_emergencia.dart';

/// Controlador da tela do Dispositivo de Cuidado.
class ControladorDispositivoCuidado extends ChangeNotifier {
  ControladorDispositivoCuidado({
    required this.repositorioContato,
    ProvedorDeTelemetria? provedorInicial,
  }) {
    _provedorAtual = provedorInicial ?? ProvedorDeTelemetriaMqtt();
    _dispositivo = DispositivoCuidado(
      id: 'pulseira-01',
      nome: 'Dispositivo de Cuidado',
      modoOperacao: (_provedorAtual is ProvedorDeTelemetriaMqtt)
          ? ModoOperacaoIot.mqtt
          : ModoOperacaoIot.simulado,
    );
    _iniciarOuvintes();
    _carregarContato();
  }

  final RepositorioContatoEmergencia repositorioContato;
  late ProvedorDeTelemetria _provedorAtual;

  late DispositivoCuidado _dispositivo;

  ContatoEmergencia? _contatoEmergencia;
  EventoQueda? _quedaAtiva;

  StreamSubscription<TelemetriaIot>? _subTelemetria;
  StreamSubscription<StatusConexaoIot>? _subStatus;
  StreamSubscription<EventoQueda>? _subQueda;

  DispositivoCuidado get dispositivo => _dispositivo;
  ContatoEmergencia? get contatoEmergencia => _contatoEmergencia;
  EventoQueda? get quedaAtiva => _quedaAtiva;
  ProvedorDeTelemetria get provedor => _provedorAtual;

  Future<void> _carregarContato() async {
    _contatoEmergencia = await repositorioContato.obterContato();
    notifyListeners();
  }

  void _iniciarOuvintes() {
    _subTelemetria?.cancel();
    _subStatus?.cancel();
    _subQueda?.cancel();

    _subTelemetria = _provedorAtual.streamTelemetria.listen((TelemetriaIot telemetria) {
      _dispositivo = _dispositivo.copyWith(ultimaTelemetria: telemetria);
      notifyListeners();
    });

    _subStatus = _provedorAtual.streamStatusConexao.listen((StatusConexaoIot status) {
      _dispositivo = _dispositivo.copyWith(statusConexao: status);
      notifyListeners();
    });

    _subQueda = _provedorAtual.streamQueda.listen((EventoQueda queda) {
      _quedaAtiva = queda;
      notifyListeners();
    });
  }

  Future<void> conectar() async {
    await _provedorAtual.conectar();
  }

  Future<void> desconectar() async {
    await _provedorAtual.desconectar();
  }

  Future<void> alternarModo(ModoOperacaoIot novoModo, {String? broker, String? topico}) async {
    final String brokerFinal = (broker != null && broker.trim().isNotEmpty)
        ? broker.trim()
        : _dispositivo.brokerHost;
    final String topicoFinal = (topico != null && topico.trim().isNotEmpty)
        ? topico.trim()
        : _dispositivo.topicoBase;

    await _provedorAtual.desconectar();
    _provedorAtual.descartar();

    if (novoModo == ModoOperacaoIot.mqtt) {
      _provedorAtual = ProvedorDeTelemetriaMqtt(
        broker: brokerFinal,
        topicoBase: topicoFinal,
      );
    } else {
      _provedorAtual = ProvedorDeTelemetriaSimulado();
    }

    _dispositivo = _dispositivo.copyWith(
      modoOperacao: novoModo,
      brokerHost: brokerFinal,
      topicoBase: topicoFinal,
    );

    _iniciarOuvintes();
    await _provedorAtual.conectar();
    notifyListeners();
  }

  Future<void> salvarContato(ContatoEmergencia contato) async {
    await repositorioContato.salvarContato(contato);
    _contatoEmergencia = contato;
    notifyListeners();
  }

  void simularQuedaTeste() {
    if (_provedorAtual is ProvedorDeTelemetriaSimulado) {
      (_provedorAtual as ProvedorDeTelemetriaSimulado).simularQueda();
    }
  }

  void limparQuedaAtiva() {
    _quedaAtiva = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subTelemetria?.cancel();
    _subStatus?.cancel();
    _subQueda?.cancel();
    _provedorAtual.descartar();
    super.dispose();
  }
}

