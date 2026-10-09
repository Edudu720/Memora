import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/casos_de_uso/disparar_socorro_emergencia.dart';
import '../../domain/entidades/contato_emergencia.dart';
import '../../domain/entidades/enums_cuidado.dart';
import '../../domain/entidades/evento_queda.dart';
import '../../domain/repositorios/provedor_telemetria.dart';

/// Controlador da tela "Você está bem?" com temporizador regressivo de 45 segundos.
class ControladorVerificacaoQueda extends ChangeNotifier {
  ControladorVerificacaoQueda({
    required this.evento,
    required this.provedor,
    required this.casoDeUsoSocorro,
    required this.nomePessoaIdosa,
    this.contatoEmergencia,
    this.segundosIniciais = 45,
    this.aoEncerrar,
  }) : _segundosRestantes = segundosIniciais {
    _iniciarTemporizador();
  }

  final EventoQueda evento;
  final ProvedorDeTelemetria provedor;
  final DispararSocorroEmergencia casoDeUsoSocorro;
  final String nomePessoaIdosa;
  final ContatoEmergencia? contatoEmergencia;
  final int segundosIniciais;
  final VoidCallback? aoEncerrar;

  Timer? _temporizador;
  int _segundosRestantes;
  StatusConfirmacaoQueda _status = StatusConfirmacaoQueda.aguardandoConfirmacao;

  int get segundosRestantes => _segundosRestantes;
  StatusConfirmacaoQueda get status => _status;
  bool get estaAtivo => _status == StatusConfirmacaoQueda.aguardandoConfirmacao;

  void _iniciarTemporizador() {
    _temporizador?.cancel();
    _temporizador = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_segundosRestantes > 1) {
        _segundosRestantes--;
        notifyListeners();
      } else {
        _segundosRestantes = 0;
        _temporizador?.cancel();
        _aoExpirarTempo();
      }
    });
  }

  /// Chamado quando o idoso toca em "Estou bem".
  Future<void> responderEstouBem() async {
    if (!estaAtivo) return;

    _temporizador?.cancel();
    _status = StatusConfirmacaoQueda.canceladoPeloUsuario;
    notifyListeners();

    // Notifica o ESP32 para silenciar o buzzer e apagar o LED de alerta
    await provedor.enviarComandoCessarAlarme();

    aoEncerrar?.call();
  }

  /// Chamado quando o idoso toca em "Preciso de ajuda".
  Future<void> responderPrecisoDeAjuda() async {
    if (!estaAtivo) return;

    _temporizador?.cancel();
    _status = StatusConfirmacaoQueda.socorroAcionado;
    notifyListeners();

    await _acionarSocorro();
    aoEncerrar?.call();
  }

  /// Chamado quando o cronômetro atinge 0 segundos sem resposta.
  Future<void> _aoExpirarTempo() async {
    _status = StatusConfirmacaoQueda.tempoExpirado;
    notifyListeners();

    await _acionarSocorro();
    aoEncerrar?.call();
  }

  Future<void> _acionarSocorro() async {
    if (contatoEmergencia != null && contatoEmergencia!.ehValido) {
      await casoDeUsoSocorro.executar(
        contato: contatoEmergencia!,
        nomeIdoso: nomePessoaIdosa,
        horarioOcorrencia: evento.timestamp,
      );
    }
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }
}

