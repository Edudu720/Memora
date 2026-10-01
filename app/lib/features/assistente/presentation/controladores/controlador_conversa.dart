import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../l10n/textos_assistente.dart';
import '../../data/abridor_de_aplicativo.dart';
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
  final AbridorDeAplicativo? _abridor;

  /// Cria o controlador.
  ///
  /// [abridor] é opcional: sem ele a Memora conversa e ensina, mas não abre
  /// nada. É o mesmo raciocínio da porta do Hub — funcionalidade que não existe
  /// não deve ser oferecida.
  ///
  /// [rascunhoInicial] abre a conversa com uma pergunta já escrita — é como o
  /// catálogo leva a pessoa até aqui (T077). Fica no campo, e **não** é
  /// enviada: quem envia é a pessoa.
  ControladorConversa(
    this._repositorio,
    this._local, {
    AbridorDeAplicativo? abridor,
    String rascunhoInicial = '',
  })  : _abridor = abridor,
        _rascunho = rascunhoInicial;

  /// Quanto tempo esperar pela **primeira** palavra da resposta (FR-052).
  ///
  /// Conta até o primeiro trecho, e não até o fim: uma resposta longa que já
  /// está aparecendo não é cortada no meio. Bem abaixo dos 120 s do servidor,
  /// que é o teto da conexão inteira.
  static const Duration esperaMaxima = Duration(seconds: 30);

  final List<MensagemDaConversa> _mensagens = <MensagemDaConversa>[];

  /// Conta os envios. Uma resposta que chega com número velho — depois de a
  /// espera acabar, ou de um tentar de novo — é descartada, senão a pessoa
  /// recebe duas respostas para uma pergunta.
  int _envio = 0;
  Timer? _cronometro;

  EstadoConversa _estado = EstadoConversa.abrindo;
  FalhaDaAssistente? _falha;
  AcaoAutorizada? _acaoOferecida;
  String _rascunho;
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
        FalhaDaAssistente.semConexao => TextosAssistente.semRespostaDaConversa,
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

    final int esteEnvio = ++_envio;
    final MensagemDaConversa fala = MensagemDaConversa(
      autor: AutorDaMensagem.pessoa,
      texto: pergunta,
      momento: DateTime.now(),
    );
    _mensagens.add(fala);
    notifyListeners();

    _cronometro?.cancel();
    _cronometro = Timer(esperaMaxima, () {
      if (esteEnvio != _envio) return;
      _envio++;
      _trechoEmCurso = '';
      _devolverPergunta(fala);
      _falha = FalhaDaAssistente.semConexao;
      _estado = EstadoConversa.comErro;
      notifyListeners();
    });

    final RespostaDaAssistente resposta = await _repositorio.conversar(
      mensagem: pergunta,
      // O histórico viaja porque o servidor não o guarda (FR-047).
      historico: List<MensagemDaConversa>.unmodifiable(_mensagens),
      aoReceberTrecho: (String trecho) {
        if (esteEnvio != _envio) return;
        // A primeira palavra chegou: a espera da FR-052 acabou bem.
        _cronometro?.cancel();
        _trechoEmCurso += trecho;
        notifyListeners();
      },
    );

    if (esteEnvio != _envio) return; // chegou depois do corte
    _cronometro?.cancel();
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
        _devolverPergunta(fala);
        _falha = falha;
        _estado = EstadoConversa.comErro;
    }
    notifyListeners();
  }

  /// Tira da conversa a fala que ficou sem resposta, e a devolve ao campo.
  ///
  /// É o que torna verdade o "o que você escreveu continua aqui" (FR-052), e o
  /// que impede a pergunta de aparecer duas vezes quando for reenviada.
  void _devolverPergunta(MensagemDaConversa fala) {
    _mensagens.remove(fala);
    _rascunho = fala.texto;
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

  /// A pessoa confirmou: abre o aplicativo, registra e mostra o caminho.
  ///
  /// ## A ordem importa
  ///
  /// Abre **primeiro**, registra depois. Registrar antes gravaria na trilha
  /// imutável uma ação que talvez não aconteça — e a FR-023 mostra esse
  /// registro à pessoa, que veria "abri o WhatsApp" numa tarde em que ele nunca
  /// abriu.
  ///
  /// ## O caminho percorrido não é gentileza
  ///
  /// A FR-019 manda mostrá-lo, e o motivo é o Princípio VII: se a pessoa só vê
  /// o resultado, ela aprendeu que a Memora resolve. Vendo o caminho, ela tem
  /// chance de reconhecê-lo sozinha da próxima vez.
  Future<void> confirmarAcao() async {
    final AcaoAutorizada? acao = _acaoOferecida;
    if (acao == null) return;

    _acaoOferecida = null;
    notifyListeners();

    final bool abriu =
        await _abridor?.abrir(acao.identificadorAndroid) ?? false;

    if (!abriu) {
      // Aplicativo não instalado, ou fora do `<queries>` do manifesto. A
      // pessoa recebe uma frase, nunca um erro técnico — e a ação NÃO é
      // registrada, porque ela não aconteceu.
      _dizer(TextosAssistente.naoConsegiAbrir(acao.nomeExibido));
      return;
    }

    _dizer(TextosAssistente.caminhoPercorrido(acao.nomeExibido));

    await _repositorio.registrarAcao(
      servicoId: acao.servicoId,
      pedidoResumido: _ultimoPedido,
    );
  }

  /// Acrescenta uma fala da Memora à conversa, e guarda.
  void _dizer(String texto) {
    _mensagens.add(
      MensagemDaConversa(
        autor: AutorDaMensagem.memora,
        texto: texto,
        momento: DateTime.now(),
      ),
    );
    unawaited(_local.guardar(_mensagens));
    notifyListeners();
  }

  /// Depois de um erro: sem internet, **reenvia** a pergunta (FR-052).
  ///
  /// A pessoa não precisa reescrever — ela já está no campo. Nas demais falhas
  /// (o limite do dia, a sessão que caiu), reenviar não resolveria nada, e o
  /// botão só devolve a tela à espera.
  void tentarNovamente() {
    final bool reenviar =
        _falha == FalhaDaAssistente.semConexao && _rascunho.trim().isNotEmpty;
    _falha = null;
    _estado = EstadoConversa.aguardando;
    notifyListeners();
    if (reenviar) unawaited(enviar());
  }

  @override
  void dispose() {
    _cronometro?.cancel();
    super.dispose();
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
