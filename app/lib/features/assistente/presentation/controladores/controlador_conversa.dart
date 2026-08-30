import 'package:flutter/foundation.dart';

import '../../../../l10n/textos_assistente.dart';
import '../../data/conversa_local.dart';
import '../../domain/assistente.dart';

/// Estado da tela de conversa.
enum EstadoConversa {
  /// Lendo a conversa guardada, antes de mostrar qualquer coisa.
  abrindo,

  /// Esperando a pessoa escrever.
  aguardando,

  /// A Memora está respondendo.
  respondendo,

  /// Algo deu errado.
  comErro,
}

/// Controla a conversa com a assistente (T037, T039).
///
/// ## A oferta de executar nunca parte daqui
///
/// Este controlador **não decide** oferecer abrir aplicativo. Ele exibe a
/// [acaoOferecida] que o servidor mandou — e o servidor só manda depois de a
/// sugestão passar pelo catálogo (FR-022).
///
/// A consequência é que não existe caminho, neste arquivo, que produza uma
/// oferta por conta própria. Se um dia alguém quiser criar um, vai ter que
/// inventar de onde veio a autorização — e é aí que percebe que inventá-la é a
/// falha.
///
/// ## A oferta some quando a pessoa recusa
///
/// A FR-016 diz que a recusa encerra o assunto, e que a Memora não insiste na
/// mesma conversa. Aqui isso é literal: [recusarAcao] limpa a oferta, e nada a
/// traz de volta a não ser uma nova resposta do servidor.
class ControladorConversa extends ChangeNotifier {
  final RepositorioAssistente _repositorio;
  final ConversaLocal _local;

  /// Cria o controlador.
  ControladorConversa(this._repositorio, this._local);

  final List<MensagemDaConversa> _mensagens = <MensagemDaConversa>[];

  EstadoConversa _estado = EstadoConversa.abrindo;
  FalhaDaAssistente? _falha;
  AcaoAutorizada? _acaoOferecida;
  String _rascunho = '';
  String _trechoEmCurso = '';
  String _ultimoPedido = '';

  /// As mensagens da conversa, da mais antiga para a mais nova.
  List<MensagemDaConversa> get mensagens =>
      List<MensagemDaConversa>.unmodifiable(_mensagens);

  /// Estado atual.
  EstadoConversa get estado => _estado;

  /// Verdadeiro enquanto a Memora responde.
  bool get respondendo => _estado == EstadoConversa.respondendo;

  /// O texto que está chegando, enquanto chega.
  ///
  /// Existe para a tela mostrar a resposta aparecendo. Tela parada é o que faz
  /// este público concluir que o aparelho travou (SC-007).
  String get trechoEmCurso => _trechoEmCurso;

  /// O que a pessoa está escrevendo.
  String get rascunho => _rascunho;

  /// O aplicativo que a Memora ofereceu abrir, se ofereceu.
  ///
  /// **Já autorizado pelo servidor.** A tela ainda precisa pedir confirmação
  /// (FR-015) — autorizado não é o mesmo que consentido.
  AcaoAutorizada? get acaoOferecida => _acaoOferecida;

  /// O que a pessoa pediu por último, para o registro da ação.
  String get ultimoPedido => _ultimoPedido;

  /// Pode enviar o que está escrito.
  bool get podeEnviar => _rascunho.trim().isNotEmpty && !respondendo;

  /// Texto do erro atual, na voz da Memora.
  String? get mensagemDeErro => switch (_falha) {
        null => null,
        FalhaDaAssistente.semConexao => TextosAssistente.semConexao,
        FalhaDaAssistente.limiteDeConversas => TextosAssistente.limiteDeConversas,
        FalhaDaAssistente.sessaoExpirada => TextosAssistente.sessaoExpirada,
        FalhaDaAssistente.inesperada => TextosAssistente.inesperada,
      };

  /// Lê a conversa guardada e prepara a tela (FR-049).
  Future<void> iniciar() async {
    _mensagens
      ..clear()
      ..addAll(await _local.ler());
    _estado = EstadoConversa.aguardando;
    notifyListeners();
  }

  /// Atualiza o que está sendo escrito.
  void escrever(String valor) {
    _rascunho = valor;
    notifyListeners();
  }

  /// Envia a mensagem.
  Future<void> enviar() async {
    if (!podeEnviar) return;

    final String pergunta = _rascunho.trim();
    _ultimoPedido = pergunta;
    _rascunho = '';
    _falha = null;
    _acaoOferecida = null;
    _trechoEmCurso = '';
    _estado = EstadoConversa.respondendo;

    _mensagens.add(
      MensagemDaConversa(
        autor: AutorDaMensagem.pessoa,
        texto: pergunta,
        momento: DateTime.now(),
      ),
    );
    notifyListeners();

    final RespostaDaAssistente resposta = await _repositorio.conversar(
      mensagem: pergunta,
      // O histórico viaja porque o servidor não o guarda (FR-047).
      historico: List<MensagemDaConversa>.unmodifiable(_mensagens),
      aoReceberTrecho: (String trecho) {
        _trechoEmCurso += trecho;
        notifyListeners();
      },
    );

    _trechoEmCurso = '';

    switch (resposta) {
      case AssistenteRespondeu(:final String texto, :final AcaoAutorizada? acao):
        _mensagens.add(
          MensagemDaConversa(
            autor: AutorDaMensagem.memora,
            texto: texto,
            momento: DateTime.now(),
          ),
        );
        // Vem do servidor, ou não vem. Este controlador nunca a cria.
        _acaoOferecida = acao;
        _estado = EstadoConversa.aguardando;
        await _local.guardar(_mensagens);

      case AssistenteFalhou(:final FalhaDaAssistente falha):
        _falha = falha;
        _estado = EstadoConversa.comErro;
    }
    notifyListeners();
  }

  /// A pessoa recusou a oferta de abrir (FR-016).
  ///
  /// A oferta some e não volta. A Memora não insiste — insistir depois de um
  /// "não" é o comportamento que a spec proíbe, e o que faria alguém aceitar
  /// só para a pergunta parar.
  void recusarAcao() {
    _acaoOferecida = null;
    notifyListeners();
  }

  /// A pessoa confirmou, e o aplicativo já foi aberto.
  ///
  /// Registra a ação (FR-020) e limpa a oferta.
  Future<void> confirmarAcao() async {
    final AcaoAutorizada? acao = _acaoOferecida;
    if (acao == null) return;

    _acaoOferecida = null;
    notifyListeners();

    await _repositorio.registrarAcao(
      servicoId: acao.servicoId,
      pedidoResumido: _ultimoPedido,
    );
  }

  /// Volta ao estado de espera depois de um erro.
  void tentarNovamente() {
    _falha = null;
    _estado = EstadoConversa.aguardando;
    notifyListeners();
  }

  /// Apaga a conversa (FR-050).
  Future<void> apagarConversa() async {
    _mensagens.clear();
    _acaoOferecida = null;
    _falha = null;
    _estado = EstadoConversa.aguardando;
    await _local.apagar();
    notifyListeners();
  }
}
