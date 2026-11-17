import 'dart:math';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/textos_sos.dart';
import '../../domain/casos_de_uso/disparar_socorro_emergencia.dart';
import '../../domain/entidades/contato_emergencia.dart';
import '../../domain/entidades/evento_emergencia_sos.dart';
import '../../domain/repositorios/repositorio_contato_emergencia.dart';
import '../../domain/repositorios/repositorio_emergencia_sos.dart';

/// Etapas do fluxo guiado do Botão SOS Persistente.
enum EtapaFluxoSos {
  /// Aguardando confirmação explícita do usuário antes de qualquer envio (FR-004).
  confirmacao,

  /// Envio em andamento no servidor; novos toques duplicados são ignorados (FR-012).
  processando,

  /// Encaminhamento aceito pelo servidor, com aviso honesto sem confirmar leitura (BR-007).
  enviado,

  /// Falha de rede local: oferece acionamento direto pelo aparelho ou 192 (FR-011, FR-016).
  falhaConexao,

  /// Contato ausente/inválido ou falha remota de entrega: oferece 192 / aparelho (FR-016).
  falhaEntrega,
}

/// Coordena o ciclo completo do pedido de ajuda manual via Botão SOS Persistente.
class ControladorSosEmergencia extends ChangeNotifier {
  final RepositorioEmergenciaSos _repositorioSos;
  final RepositorioContatoEmergencia _repositorioContato;
  final DispararSocorroEmergencia _dispararSocorroLocal;
  final Future<LocalizacaoSos?> Function()? _obterLocalizacaoAutorizada;
  final Future<void> Function()? _aoLigar192;
  final String Function() _gerarEventoId;
  final String _nomePessoa;

  EtapaFluxoSos _etapa = EtapaFluxoSos.confirmacao;
  ContatoEmergencia? _contato;
  LocalizacaoSos? _localizacaoDisponivel;
  bool _compartilharLocalizacao = true;
  bool _contatoCarregado = false;
  bool _preparacaoConcluida = false;
  bool _descartado = false;
  String? _eventoIdAtual;
  EventoEmergenciaSos? _ultimoEvento;
  String _mensagemResultado = '';

  /// Cria o controlador do diálogo SOS.
  ControladorSosEmergencia({
    required RepositorioEmergenciaSos repositorioSos,
    required RepositorioContatoEmergencia repositorioContato,
    DispararSocorroEmergencia? dispararSocorroLocal,
    Future<LocalizacaoSos?> Function()? obterLocalizacaoAutorizada,
    Future<void> Function()? aoLigar192,
    String Function()? geradorEventoId,
    String nomePessoa = 'Usuário',
  })  : _repositorioSos = repositorioSos,
        _repositorioContato = repositorioContato,
        _dispararSocorroLocal =
            dispararSocorroLocal ?? const DispararSocorroEmergencia(),
        _obterLocalizacaoAutorizada = obterLocalizacaoAutorizada,
        _aoLigar192 = aoLigar192,
        _gerarEventoId = geradorEventoId ?? _uuidV4,
        _nomePessoa = nomePessoa {
    _eventoIdAtual = _gerarEventoId();
  }

  /// Etapa visível neste momento no diálogo SOS.
  EtapaFluxoSos get etapa => _etapa;

  /// Contato de emergência cadastrado no aparelho, se existir.
  ContatoEmergencia? get contato => _contato;

  /// Indica se existe contato válido pronto para receber a notificação.
  bool get temContatoValido => _contato != null && _contato!.ehValido;

  /// Coordenadas disponíveis no aparelho mediante autorização prévia.
  bool get temLocalizacaoDisponivel => _localizacaoDisponivel != null;

  /// Se a pessoa optou por enviar a localização junto com este pedido.
  bool get compartilharLocalizacao => _compartilharLocalizacao;

  /// Localização que será efetivamente anexada ao pedido (respeitando autorização e escolha).
  LocalizacaoSos? get localizacaoAtual =>
      _compartilharLocalizacao ? _localizacaoDisponivel : null;

  /// Indica se a leitura inicial de contato e permissão terminou.
  bool get preparacaoConcluida => _preparacaoConcluida;

  /// Mensagem honesta sobre o desfecho técnico da solicitação.
  String get mensagemResultado => _mensagemResultado;

  /// Último evento registrado ou devolvido pelo backend.
  EventoEmergenciaSos? get ultimoEvento => _ultimoEvento;

  /// Carrega contato e localização opcional já autorizada antes da confirmação.
  Future<void> prepararConfirmacao() async {
    _etapa = EtapaFluxoSos.confirmacao;
    _eventoIdAtual ??= _gerarEventoId();
    _ultimoEvento = null;
    _mensagemResultado = '';
    await _garantirContatoCarregado();
    _notificar();
    await _carregarLocalizacaoSeAutorizada();
    _preparacaoConcluida = true;
    _notificar();
  }

  /// Permite ligar ou desligar o anexo pontual de localização quando disponível.
  void definirCompartilharLocalizacao(bool valor) {
    if (_etapa != EtapaFluxoSos.confirmacao) return;
    _compartilharLocalizacao = valor;
    _notificar();
  }

  /// Confirma e envia o pedido manual `SOS_MANUAL` com idempotência por evento.
  Future<void> confirmarEnvioSos() async {
    if (_etapa == EtapaFluxoSos.processando) {
      return;
    }

    _etapa = EtapaFluxoSos.processando;
    _notificar();

    try {
      if (!_contatoCarregado) {
        await _garantirContatoCarregado();
      }

      final String eventoId = _eventoIdAtual ??= _gerarEventoId();
      final EventoEmergenciaSos resultado = await _repositorioSos.solicitarSos(
        eventoId: eventoId,
        tipo: TipoEventoEmergencia.sosManual,
        localizacao: localizacaoAtual,
        contato: _contato,
      );

      _ultimoEvento = resultado;
      if (resultado.estado == EstadoEventoSos.enviado ||
          resultado.estado ==
              EstadoEventoSos.confirmadoPeloDestinatario) {
        _mensagemResultado = resultado.mensagem.trim().isNotEmpty
            ? resultado.mensagem
            : TextosSos.mensagemEnviado;
        _etapa = EtapaFluxoSos.enviado;
      } else {
        _mensagemResultado = resultado.mensagem.trim().isNotEmpty
            ? resultado.mensagem
            : (temContatoValido
                  ? TextosSos.mensagemFalhaEntrega
                  : TextosSos.mensagemSemContatoConfirmacao);
        _etapa = EtapaFluxoSos.falhaEntrega;
      }
    } on FalhaDeConexaoSosException {
      _mensagemResultado = TextosSos.mensagemFalhaConexao;
      _etapa = EtapaFluxoSos.falhaConexao;
    } catch (_) {
      _mensagemResultado = temContatoValido
          ? TextosSos.mensagemFalhaEntrega
          : TextosSos.mensagemSemContatoConfirmacao;
      _etapa = EtapaFluxoSos.falhaEntrega;
    }

    _notificar();
  }

  /// Aciona o contato diretamente pelo celular (WhatsApp, SMS ou discador local).
  Future<void> acionarContatoPeloAparelho() async {
    final ContatoEmergencia? contatoAtual = _contato;
    if (contatoAtual == null || !contatoAtual.ehValido) return;
    await _dispararSocorroLocal.executar(
      contato: contatoAtual,
      nomeIdoso: _nomePessoa,
      horarioOcorrencia: DateTime.now(),
    );
  }

  /// Abre o discador preenchido com 192 (SAMU) mediante ação explícita do usuário.
  Future<void> ligarEmergencia192() async {
    if (_aoLigar192 != null) {
      await _aoLigar192();
      return;
    }

    try {
      const AndroidIntent intentDiscador = AndroidIntent(
        action: 'android.intent.action.DIAL',
        data: 'tel:192',
      );
      await intentDiscador.launch();
      return;
    } catch (_) {
      // Fallback multiplataforma caso o AndroidIntent não esteja disponível.
    }

    try {
      final Uri uri = Uri.parse('tel:192');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {
      // Não derruba o aplicativo em ambientes sem discador (ex.: desktop/testes).
    }
  }

  Future<void> _garantirContatoCarregado() async {
    try {
      _contato = await _repositorioContato.obterContato();
    } catch (_) {
      _contato = null;
    }
    _contatoCarregado = true;
  }

  Future<void> _carregarLocalizacaoSeAutorizada() async {
    if (_obterLocalizacaoAutorizada != null) {
      try {
        _localizacaoDisponivel = await _obterLocalizacaoAutorizada();
      } catch (_) {
        _localizacaoDisponivel = null;
      }
    } else {
      _localizacaoDisponivel = null;
    }
  }

  void _notificar() {
    if (!_descartado) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_descartado) return;
    _descartado = true;
    super.dispose();
  }

  static String _uuidV4() {
    final Random aleatorio = Random.secure();
    final List<int> bytes = List<int>.generate(
      16,
      (_) => aleatorio.nextInt(256),
    );
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int valor) => valor.toRadixString(16).padLeft(2, '0');
    final StringBuffer b = StringBuffer();
    for (int i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        b.write('-');
      }
      b.write(hex(bytes[i]));
    }
    return b.toString();
  }
}
