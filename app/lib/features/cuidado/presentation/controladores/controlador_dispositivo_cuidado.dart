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
  /// Cria o controlador do dispositivo de cuidado.
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

  /// Repositório responsável por persistir o contato de emergência.
  final RepositorioContatoEmergencia repositorioContato;
  late ProvedorDeTelemetria _provedorAtual;

  late DispositivoCuidado _dispositivo;

  ContatoEmergencia? _contatoEmergencia;
  EventoQueda? _quedaAtiva;

  StreamSubscription<TelemetriaIot>? _subTelemetria;
  StreamSubscription<StatusConexaoIot>? _subStatus;
  StreamSubscription<EventoQueda>? _subQueda;

  /// Estado atual do dispositivo.
  DispositivoCuidado get dispositivo => _dispositivo;

  /// Contato de emergência cadastrado, se houver.
  ContatoEmergencia? get contatoEmergencia => _contatoEmergencia;

  /// Evento de queda ativo aguardando verificação.
  EventoQueda? get quedaAtiva => _quedaAtiva;

  /// Provedor de telemetria ativo no momento.
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

  /// Inicia a conexão com o provedor de telemetria atual.
  Future<void> conectar() async {
    await _provedorAtual.conectar();
  }

  /// Encerra a conexão com o provedor de telemetria atual.
  Future<void> desconectar() async {
    await _provedorAtual.desconectar();
  }

  /// Alterna entre o modo simulado local e o modo MQTT do ESP32 físico.
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

  /// Salva o [contato] de emergência no repositório local.
  Future<void> salvarContato(ContatoEmergencia contato) async {
    await repositorioContato.salvarContato(contato);
    _contatoEmergencia = contato;
    notifyListeners();
  }

  /// Dispara localmente um evento de queda para validar a tela de verificação,
  /// tanto no modo simulado quanto no modo ESP32 físico (MQTT).
  void simularQuedaTeste() {
    if (_quedaAtiva != null) return;
    final ProvedorDeTelemetria provedor = _provedorAtual;
    if (provedor is ProvedorDeTelemetriaSimulado) {
      provedor.simularQueda();
      return;
    }
    _quedaAtiva = EventoQueda.novo(
      bpm: _dispositivo.ultimaTelemetria?.bpm ?? 72,
      aceleracao: 2.8,
    );
    notifyListeners();
  }

  /// Limpa o evento de queda ativo após abrir a tela de verificação.
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
