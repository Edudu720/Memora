import 'dart:async';
import 'dart:math';
import '../../domain/entidades/enums_cuidado.dart';
import '../../domain/entidades/evento_queda.dart';
import '../../domain/entidades/telemetria_iot.dart';
import '../../domain/repositorios/provedor_telemetria.dart';

/// Implementação simulada em memória para desenvolvimento, testes e apresentações.
class ProvedorDeTelemetriaSimulado implements ProvedorDeTelemetria {
  /// Cria um provedor simulado com o [intervaloEnvio] configurado.
  ProvedorDeTelemetriaSimulado({
    this.intervaloEnvio = const Duration(milliseconds: 500),
  });

  /// Intervalo entre emissões periódicas de telemetria.
  final Duration intervaloEnvio;
  final Random _random = Random();

  final StreamController<TelemetriaIot> _controladorTelemetria =
      StreamController<TelemetriaIot>.broadcast();
  final StreamController<EventoQueda> _controladorQueda =
      StreamController<EventoQueda>.broadcast();
  final StreamController<StatusConexaoIot> _controladorStatus =
      StreamController<StatusConexaoIot>.broadcast();

  Timer? _temporizador;
  StatusConexaoIot _statusAtual = StatusConexaoIot.desconectado;

  // Estados ajustáveis para teste
  int _bpmAtual = 72;
  double _nivelMovimento = 12.0;
  bool _emMovimento = true;

  @override
  Stream<TelemetriaIot> get streamTelemetria => _controladorTelemetria.stream;

  @override
  Stream<EventoQueda> get streamQueda => _controladorQueda.stream;

  @override
  Stream<StatusConexaoIot> get streamStatusConexao => _controladorStatus.stream;

  /// Retorna o estado atual da conexão simulada.
  StatusConexaoIot get statusAtual => _statusAtual;

  @override
  Future<void> conectar() async {
    _statusAtual = StatusConexaoIot.conectando;
    _controladorStatus.add(_statusAtual);

    await Future<void>.delayed(const Duration(milliseconds: 300));
    _statusAtual = StatusConexaoIot.conectado;
    _controladorStatus.add(_statusAtual);

    _iniciarGeracao();
  }

  @override
  Future<void> desconectar() async {
    _temporizador?.cancel();
    _temporizador = null;
    _statusAtual = StatusConexaoIot.desconectado;
    _controladorStatus.add(_statusAtual);
  }

  void _iniciarGeracao() {
    _temporizador?.cancel();
    _temporizador = Timer.periodic(intervaloEnvio, (_) {
      if (_statusAtual != StatusConexaoIot.conectado) return;

      // Pequena flutuação realista nos batimentos
      final int deltaBpm = _random.nextInt(3) - 1; // -1, 0, ou +1
      final int bpmGerado = (_bpmAtual + deltaBpm).clamp(40, 180);

      final TelemetriaIot telemetria = TelemetriaIot(
        timestamp: DateTime.now(),
        bpm: bpmGerado,
        aceleracaoG: _emMovimento ? 1.0 + (_random.nextDouble() * 0.1) : 1.0,
        nivelMovimento: _emMovimento ? _nivelMovimento : 1.0,
        emMovimento: _emMovimento,
        estadoSensor: _emMovimento ? 'MOVIMENTO' : 'INERTE',
      );

      _controladorTelemetria.add(telemetria);
    });
  }

  /// Permite ao testador ou UI alterar a leitura simulada de BPM.
  void definirBpm(int novoBpm) {
    _bpmAtual = novoBpm.clamp(40, 180);
  }

  /// Permite alternar o estado de movimento.
  void alternarMovimento(bool emMovimento) {
    _emMovimento = emMovimento;
    _nivelMovimento = emMovimento ? 18.0 : 0.5;
  }

  /// Dispara manualmente um evento de queda no stream.
  void simularQueda({int? bpmNoImpacto}) {
    final EventoQueda evento = EventoQueda.novo(
      bpm: bpmNoImpacto ?? _bpmAtual,
      aceleracao: 2.8,
    );
    _controladorQueda.add(evento);
  }

  @override
  Future<void> enviarComandoCessarAlarme() async {
    // No simulador, o buzzer virtual é cessado imediatamente.
    _emMovimento = false;
  }

  @override
  void descartar() {
    _temporizador?.cancel();
    _controladorTelemetria.close();
    _controladorQueda.close();
    _controladorStatus.close();
  }
}
