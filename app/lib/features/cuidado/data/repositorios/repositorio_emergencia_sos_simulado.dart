import '../../../../l10n/textos_sos.dart';
import '../../domain/entidades/contato_emergencia.dart';
import '../../domain/entidades/evento_emergencia_sos.dart';
import '../../domain/repositorios/repositorio_emergencia_sos.dart';

/// Registro da chamada efetuada no repositório simulado para inspeção em testes.
class RegistroChamadaSosSimulada {
  /// Identificador de idempotência enviado.
  final String eventoId;

  /// Tipo de origem (`SOS_MANUAL` ou `QUEDA_AUTOMATICA`).
  final TipoEventoEmergencia tipo;

  /// Coordenadas anexadas, se autorizadas.
  final LocalizacaoSos? localizacao;

  /// Contato utilizado no envio.
  final ContatoEmergencia? contato;

  /// Cria um registro de chamada SOS em memória.
  const RegistroChamadaSosSimulada({
    required this.eventoId,
    required this.tipo,
    this.localizacao,
    this.contato,
  });
}

/// Implementação simulada em memória para uso offline/demonstração e testes.
class RepositorioEmergenciaSosSimulado implements RepositorioEmergenciaSos {
  final Map<String, EventoEmergenciaSos> _eventosPorId =
      <String, EventoEmergenciaSos>{};
  final List<RegistroChamadaSosSimulada> _requisicoes =
      <RegistroChamadaSosSimulada>[];

  /// Quando verdadeiro, lança [FalhaDeConexaoSosException] antes de registrar.
  bool simularErroConexao;

  /// Quando verdadeiro, devolve estado [EstadoEventoSos.falha].
  bool simularFalhaEntrega;

  /// Atraso opcional útil para testar duplo clique ou estado em andamento.
  Duration atraso;

  /// Cria o repositório simulado de emergência SOS.
  RepositorioEmergenciaSosSimulado({
    this.simularErroConexao = false,
    this.simularFalhaEntrega = false,
    this.atraso = Duration.zero,
  });

  /// Eventos únicos já processados em memória (chaveados por `eventoId`).
  List<EventoEmergenciaSos> get historico =>
      List<EventoEmergenciaSos>.unmodifiable(_eventosPorId.values);

  /// Todas as chamadas recebidas (incluindo tentativas repetidas com mesmo ID).
  List<RegistroChamadaSosSimulada> get requisicoes =>
      List<RegistroChamadaSosSimulada>.unmodifiable(_requisicoes);

  @override
  Future<EventoEmergenciaSos> solicitarSos({
    required String eventoId,
    required TipoEventoEmergencia tipo,
    LocalizacaoSos? localizacao,
    ContatoEmergencia? contato,
  }) async {
    _requisicoes.add(
      RegistroChamadaSosSimulada(
        eventoId: eventoId,
        tipo: tipo,
        localizacao: localizacao,
        contato: contato,
      ),
    );

    if (atraso > Duration.zero) {
      await Future<void>.delayed(atraso);
    }

    if (simularErroConexao) {
      throw const FalhaDeConexaoSosException();
    }

    final EventoEmergenciaSos? existente = _eventosPorId[eventoId];
    if (existente != null) {
      return existente;
    }

    final bool temContatoValido = contato != null && contato.ehValido;
    final EventoEmergenciaSos evento;
    if (!temContatoValido || simularFalhaEntrega) {
      evento = EventoEmergenciaSos(
        eventoId: eventoId,
        tipo: tipo,
        estado: EstadoEventoSos.falha,
        mensagem: temContatoValido
            ? TextosSos.mensagemFalhaEntrega
            : TextosSos.mensagemSemContatoConfirmacao,
        ocorridoEm: DateTime.now(),
        localizacao: localizacao,
        contatoNotificado: contato?.nome,
      );
    } else {
      evento = EventoEmergenciaSos(
        eventoId: eventoId,
        tipo: tipo,
        estado: EstadoEventoSos.enviado,
        mensagem: TextosSos.mensagemEnviado,
        ocorridoEm: DateTime.now(),
        localizacao: localizacao,
        contatoNotificado: contato.nome,
      );
    }

    _eventosPorId[eventoId] = evento;
    return evento;
  }
}
