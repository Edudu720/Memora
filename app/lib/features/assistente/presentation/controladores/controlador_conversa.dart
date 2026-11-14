import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../l10n/textos_assistente.dart';
import '../../data/abridor_de_aplicativo.dart';
import '../../data/aceite_do_aviso.dart';
import '../../data/conversa_local.dart';
import '../../domain/assistente.dart';
import '../../domain/leitor_de_voz.dart';

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
///
/// ## Nada sai do aparelho antes do aceite (FR-051)
///
/// O serviço que gera as respostas é de fora do Memora, e pode usar e deixar
/// pessoas lerem o que recebe. Por isso [podeEnviar] é falso, e [enviar] não faz
/// nada, até a pessoa dizer que entendeu ([aceitar]). A guarda mora **aqui**, e
/// não só na tela: esconder o botão não impede um envio por outro caminho.
class ControladorConversa extends ChangeNotifier {
  final RepositorioAssistente _repositorio;
  final ConversaLocal _local;
  final AceiteDoAviso _aceite;
  final AbridorDeAplicativo? _abridor;
  final LeitorDeVoz? _leitorDeVoz;

  /// Cria o controlador.
  ///
  /// [aceite] é obrigatório, de propósito: um controlador sem ele não teria
  /// como saber se já pode falar com o serviço de fora, e o padrão seguro é
  /// **não** poder.
  ///
  /// [abridor] é opcional: sem ele a Memora conversa e ensina, mas não abre
  /// nada. É o mesmo raciocínio da porta do Hub — funcionalidade que não existe
  /// não deve ser oferecida.
  ///
  /// [leitorDeVoz] é opcional: quando informado, habilita o ditado por voz que
  /// preenche exclusivamente o [rascunho] antes do envio manual (FR-013).
  ///
  /// [rascunhoInicial] abre a conversa com uma pergunta já escrita — é como o
  /// catálogo leva a pessoa até aqui (T077). Fica no campo, e **não** é
  /// enviada: quem envia é a pessoa.
  ControladorConversa(
    this._repositorio,
    this._local, {
    required AceiteDoAviso aceite,
    AbridorDeAplicativo? abridor,
    LeitorDeVoz? leitorDeVoz,
    String rascunhoInicial = '',
  }) : _aceite = aceite,
       _abridor = abridor,
       _leitorDeVoz = leitorDeVoz,
       _rascunho = rascunhoInicial;

  /// Quantas mensagens viajam ao serviço a cada turno (FR-056).
  ///
  /// São **20 turnos** — uma troca é a pergunta da pessoa e a resposta da
  /// Memora —, ou seja, 40 mensagens, o `maxItems` do contrato. O servidor
  /// recusa mais que isso com `400` e corta de novo nas mesmas 40, por defesa
  /// (`data-model.md`, "Turno — a unidade de conta"). A conversa nunca é
  /// encerrada por ficar longa: o aparelho guarda e mostra tudo, e só o que
  /// viaja é limitado.
  static const int mensagensQueViajam = 40;

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
  bool _descartado = false;

  /// A pessoa já aceitou o aviso de privacidade (FR-051)? Falso até lido.
  bool _aceitou = false;

  EstadoConversa _estado = EstadoConversa.abrindo;
  FalhaDaAssistente? _falha;
  AcaoAutorizada? _acaoOferecida;
  bool _recusouExecucao = false;
  String _rascunho;
  String _trechoEmCurso = '';
  String _ultimoPedido = '';
  EstadoDitado _estadoDitado = EstadoDitado.ocioso;
  String? _avisoVoz;
  bool _jaExplicouPermissaoVoz = false;
  String _baseRascunhoDitado = '';

  /// Estado atual do ditado por voz no campo de mensagem (FR-013).
  EstadoDitado get estadoDitado => _estadoDitado;

  /// Verdadeiro enquanto o microfone estiver aberto ouvindo a fala.
  bool get ouvindoVoz => _estadoDitado == EstadoDitado.ouvindo;

  /// Verdadeiro durante a explicação/solicitação da permissão do microfone.
  bool get aguardandoPermissaoVoz =>
      _estadoDitado == EstadoDitado.aguardandoPermissao;

  /// Mensagem amigável para indisponibilidade ou erro momentâneo de voz.
  String? get avisoVoz => _avisoVoz;

  /// Se ainda é necessário explicar a permissão antes de pedir acesso ao SO.
  bool get precisaExplicarPermissaoVoz => !_jaExplicouPermissaoVoz;

  /// Se a pessoa já recusou a execução de uma ação nesta conversa (T083, FR-016).
  bool get recusouExecucao => _recusouExecucao;

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

  /// A pessoa já enviou alguma pergunta por este controlador?
  ///
  /// **Não volta a falso**, nem quando a falha devolve a pergunta ao campo e a
  /// conversa fica vazia de novo: é o que mantém o aviso recolhido depois da
  /// primeira pergunta (FR-022 da 004).
  bool get jaPerguntou => _envio > 0;

  /// O que a pessoa pediu por último, para o registro da ação.
  String get ultimoPedido => _ultimoPedido;

  /// Pode enviar o que está escrito.
  ///
  /// Exige o aceite do aviso de privacidade (FR-051): sem ele, nada vai ao
  /// serviço de fora.
  bool get podeEnviar =>
      _aceitou && _rascunho.trim().isNotEmpty && !respondendo;

  /// A pessoa já aceitou o aviso de privacidade?
  bool get aceitou => _aceitou;

  /// A tela deve mostrar a explicação, no lugar de deixar escrever?
  ///
  /// Falso enquanto a leitura inicial não terminou: piscar a explicação para
  /// quem já aceitou seria pedir de novo o que ela já deu.
  bool get precisaDoAceite => _estado != EstadoConversa.abrindo && !_aceitou;

  /// Oferecer "tentar de novo" para a falha atual? (FR-052, FR-057)
  ///
  /// Só as falhas passageiras — ver [FalhaDaAssistente.passageira].
  bool get podeTentarDeNovo => _falha?.passageira ?? false;

  /// Texto do erro atual, na voz da Memora.
  String? get mensagemDeErro => switch (_falha) {
    null => null,
    FalhaDaAssistente.semConexao => TextosAssistente.semRespostaDaConversa,
    FalhaDaAssistente.limiteDeConversas => TextosAssistente.limiteDeConversas,
    FalhaDaAssistente.assistenteIndisponivel =>
      TextosAssistente.assistenteIndisponivel,
    FalhaDaAssistente.sessaoExpirada => TextosAssistente.sessaoExpirada,
    FalhaDaAssistente.inesperada => TextosAssistente.inesperada,
  };

  /// Lê a conversa guardada e o aceite, e prepara a tela (FR-049).
  Future<void> iniciar() async {
    final List<MensagemDaConversa> guardadas = await _local.ler();
    bool jaAceitou = false;
    try {
      jaAceitou = await _aceite.aceitou();
    } on Exception {
      // Sem conseguir ler, vale "não aceitou": pedir de novo é o lado seguro.
    }
    if (_descartado) return;
    _mensagens
      ..clear()
      ..addAll(guardadas);
    _recusouExecucao = _mensagens.any(
      (MensagemDaConversa m) => m.texto == TextosAssistente.botaoPrefiroTentar,
    );
    _aceitou = jaAceitou;
    _estado = EstadoConversa.aguardando;
    notifyListeners();
  }

  /// A pessoa leu o aviso e disse que entendeu (FR-051).
  ///
  /// Só depois disto o envio é liberado. Se guardar o aceite falhar, a pessoa
  /// segue na conversa — ela tocou no botão — e será perguntada de novo na
  /// próxima vez: errar para o lado de avisar demais, nunca de menos.
  Future<void> aceitar() async {
    try {
      await _aceite.registrar();
    } on Exception {
      // Ver acima.
    }
    if (_descartado) return;
    _aceitou = true;
    notifyListeners();
  }

  /// Atualiza o que está sendo escrito.
  void escrever(String valor) {
    _rascunho = valor;
    notifyListeners();
  }

  /// Sinaliza a exibição do diálogo explicativo antes do pedido de permissão.
  void prepararPedidoPermissaoVoz() {
    if (!_aceitou || respondendo) return;
    _estadoDitado = EstadoDitado.aguardandoPermissao;
    _avisoVoz = null;
    notifyListeners();
  }

  /// Cancela o diálogo explicativo de permissão sem acionar o microfone.
  void cancelarPedidoPermissaoVoz() {
    if (_estadoDitado == EstadoDitado.aguardandoPermissao) {
      _estadoDitado = EstadoDitado.ocioso;
      notifyListeners();
    }
  }

  /// Inicia o ditado por voz preenchendo somente o [rascunho] (FR-013).
  Future<void> iniciarDitado() async {
    if (!_aceitou || respondendo) return;

    _jaExplicouPermissaoVoz = true;
    final LeitorDeVoz? leitor = _leitorDeVoz;
    if (leitor == null) {
      _estadoDitado = EstadoDitado.indisponivel;
      _avisoVoz = TextosAssistente.vozIndisponivel;
      notifyListeners();
      return;
    }

    _baseRascunhoDitado = _rascunho.trim();
    _estadoDitado = EstadoDitado.aguardandoPermissao;
    _avisoVoz = null;
    notifyListeners();

    final ResultadoDitado resultado = await leitor.iniciarEscuta(
      aoReconhecer: (String parcial) {
        if (_descartado || !_aceitou || respondendo) return;
        final String limpo = parcial.trim();
        final String combinado = _baseRascunhoDitado.isEmpty
            ? limpo
            : (limpo.isEmpty
                  ? _baseRascunhoDitado
                  : '$_baseRascunhoDitado $limpo');
        escrever(combinado);
      },
    );

    if (_descartado) return;
    _estadoDitado = resultado.estado;
    if (resultado.estado == EstadoDitado.indisponivel) {
      _avisoVoz = resultado.mensagem ?? TextosAssistente.vozIndisponivel;
    } else if (resultado.estado == EstadoDitado.erro) {
      _avisoVoz = resultado.mensagem ?? TextosAssistente.vozErro;
    } else {
      _avisoVoz = null;
    }
    notifyListeners();
  }

  /// Encerra a escuta em andamento mantendo o texto já preenchido no campo.
  Future<void> pararDitado() async {
    await _leitorDeVoz?.pararEscuta();
    if (_descartado) return;
    _estadoDitado = EstadoDitado.ocioso;
    notifyListeners();
  }

  /// Alterna entre iniciar e encerrar o ditado por voz.
  Future<void> alternarDitado() async {
    if (!_aceitou || respondendo) return;
    if (ouvindoVoz) {
      await pararDitado();
    } else {
      await iniciarDitado();
    }
  }

  /// Envia a mensagem.
  Future<void> enviar() async {
    if (!podeEnviar) return;

    if (ouvindoVoz) {
      unawaited(_leitorDeVoz?.pararEscuta());
    }
    _estadoDitado = EstadoDitado.ocioso;
    _avisoVoz = null;

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
      // O histórico viaja porque o servidor não o guarda (FR-047), mas só as
      // mais recentes: o resto fica no aparelho (FR-056).
      historico: List<MensagemDaConversa>.unmodifiable(_maisRecentes()),
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
      case AssistenteRespondeu(
        :final String texto,
        :final AcaoAutorizada? acao,
      ):
        _mensagens.add(
          MensagemDaConversa(
            autor: AutorDaMensagem.memora,
            texto: texto,
            momento: DateTime.now(),
          ),
        );
        // Vem do servidor, ou não vem. Este controlador nunca a cria.
        // Se a pessoa já recusou a execução nesta conversa, a oferta não se repete (FR-016, T083).
        _acaoOferecida = _recusouExecucao ? null : acao;
        _estado = EstadoConversa.aguardando;
        await _local.guardar(_mensagens);

      case AssistenteFalhou(:final FalhaDaAssistente falha):
        _devolverPergunta(fala);
        _falha = falha;
        _estado = EstadoConversa.comErro;
    }
    notifyListeners();
  }

  /// As [mensagensQueViajam] mais recentes, na ordem em que foram ditas.
  List<MensagemDaConversa> _maisRecentes() => _mensagens.length <=
          mensagensQueViajam
      ? _mensagens
      : _mensagens.sublist(_mensagens.length - mensagensQueViajam);

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
    _recusouExecucao = true;
    _acaoOferecida = null;
    _mensagens.add(
      MensagemDaConversa(
        autor: AutorDaMensagem.pessoa,
        texto: TextosAssistente.botaoPrefiroTentar,
        momento: DateTime.now(),
      ),
    );
    unawaited(_local.guardar(_mensagens));
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

    await _registrar(acao);
  }

  /// Anota a ação no Registro, e **nunca** deixa a falha subir (T112).
  ///
  /// ## O gesto da pessoa não depende da rede
  ///
  /// O aplicativo já abriu — e continua aberto. A rede pode ter caído entre a
  /// confirmação e o registro, e desfazer ou esconder o que a pessoa fez seria
  /// pior que a falha. O registro é tentado **mais uma vez** (além do reenvio
  /// por `401` que a camada de dados já faz), porque uma queda de rede costuma
  /// durar menos que uma frase.
  ///
  /// ## Falhar de novo: a Memora conta a verdade
  ///
  /// Sem o registro, a trilha da FR-020 fica com um buraco, e a FR-023 diz que
  /// a pessoa vê o que a Memora fez. Calar deixaria o Registro dizer que nada
  /// aconteceu num dia em que o aplicativo abriu. Por isso ela diz, na conversa
  /// e em linguagem comum, que abriu mas não conseguiu anotar — sem erro
  /// técnico e sem culpar a pessoa.
  ///
  /// ## Sessão perdida não se repete nem se explica aqui
  ///
  /// Se a falha é [FalhaDaAssistente.sessaoExpirada], a renovação já foi
  /// recusada: tentar de novo é inútil, e a camada de dados já avisou que a
  /// sessão caiu (T111) — quem leva a pessoa à entrada é o fluxo, e a conversa
  /// sai da tela junto.
  Future<void> _registrar(AcaoAutorizada acao) async {
    for (int tentativa = 1; tentativa <= 2; tentativa++) {
      try {
        // Mesmo com o controlador já descartado o registro segue: é trilha de
        // auditoria, e a pessoa ter saído da tela não desfaz o que aconteceu.
        await _repositorio.registrarAcao(
          servicoId: acao.servicoId,
          pedidoResumido: _ultimoPedido,
        );
        return;
      } on FalhaDeChamadaDaAssistente catch (falha) {
        if (falha.falha == FalhaDaAssistente.sessaoExpirada) return;
      } on Exception {
        // Rede, tempo esgotado, resposta fora do contrato: tenta de novo.
      }
    }
    _dizer(TextosAssistente.naoAnoteiNoRegistro(acao.nomeExibido));
  }

  /// Acrescenta uma fala da Memora à conversa, e guarda.
  void _dizer(String texto) {
    if (_descartado) return;
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

  /// Depois de uma falha passageira, **reenvia** a pergunta (FR-052, FR-057).
  ///
  /// A pessoa não precisa reescrever — ela já está no campo. São passageiras a
  /// conexão, o serviço de fora fora do ar e a falha inesperada
  /// ([FalhaDaAssistente.passageira]). Nas demais (o limite do dia, a sessão que
  /// caiu), reenviar não resolveria nada, e a tela nem oferece o botão
  /// ([podeTentarDeNovo]); se alguém o chamar mesmo assim, só devolve a tela à
  /// espera.
  void tentarNovamente() {
    final bool reenviar =
        podeTentarDeNovo && _rascunho.trim().isNotEmpty;
    _falha = null;
    _estado = EstadoConversa.aguardando;
    notifyListeners();
    if (reenviar) unawaited(enviar());
  }

  @override
  void dispose() {
    // Invalida o que está em voo. Sem isto, uma resposta que chegue depois de
    // a pessoa sair da tela — ou da conta, quando a `LimpezaDeSessao` já
    // apagou a conversa — chamaria `_local.guardar` e a REGRAVARIA no
    // aparelho (FR-048).
    _descartado = true;
    _envio++;
    _cronometro?.cancel();
    _leitorDeVoz?.dispose();
    super.dispose();
  }

  /// Apaga a conversa (FR-050).
  Future<void> apagarConversa() async {
    // Invalida o que está em voo, como o `dispose`: quem apaga quer que a
    // conversa SUMA, e uma resposta que chegasse depois a regravaria no
    // aparelho (FR-040, FR-048).
    _envio++;
    _cronometro?.cancel();
    if (ouvindoVoz) {
      unawaited(_leitorDeVoz?.pararEscuta());
    }
    _estadoDitado = EstadoDitado.ocioso;
    _avisoVoz = null;
    _trechoEmCurso = '';
    _mensagens.clear();
    _acaoOferecida = null;
    _falha = null;
    _recusouExecucao = false;
    _estado = EstadoConversa.aguardando;
    try {
      await _local.apagar();
    } catch (_) {
      // A conversa da TELA já foi esvaziada acima. Quem pediu o apagar (a
      // tela de Privacidade) apaga o arquivo por conta própria e é ela quem
      // conta a falha à pessoa; aqui a falha não pode derrubar a conversa.
    } finally {
      notifyListeners();
    }
  }
}
