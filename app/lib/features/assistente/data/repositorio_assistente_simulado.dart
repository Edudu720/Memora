import '../domain/assistente.dart';

/// Assistente de mentira, para construir as telas sem servidor.
///
/// **Não vai para produção.** A troca é de uma linha, porque as telas dependem
/// apenas de [RepositorioAssistente].
///
/// ## Ele reproduz a regra que separa as duas categorias
///
/// Um simulado que respondesse sempre a mesma coisa deixaria sem exercício
/// justamente os caminhos difíceis: a recusa de serviço sensível (FR-041) e a
/// oferta de abrir que só aparece depois de ensinar (FR-014). São esses os
/// caminhos em que a feature acerta ou falha.
///
/// ## A oferta só aparece quando a pessoa diz que não conseguiu
///
/// É a FR-014, e é o Princípio VII: ensinar vem antes de fazer. O simulado
/// detecta a dificuldade por palavras comuns — *"não consegui"*, *"não to
/// achando"* — porque é assim que a pessoa escreve.
class RepositorioAssistenteSimulado implements RepositorioAssistente {
  /// Demora simulada, para a tela exercitar o estado de espera.
  final Duration demora;

  /// Força uma falha específica, para testar os caminhos de erro.
  final FalhaDaAssistente? falhaForcada;

  /// Cria o repositório simulado.
  RepositorioAssistenteSimulado({
    this.demora = const Duration(milliseconds: 600),
    this.falhaForcada,
  });

  /// O catálogo de demonstração.
  ///
  /// Os sensíveis não têm identificador de aplicativo — nem aqui. Deixá-los
  /// abríveis no simulado faria a tela ser construída contra uma realidade que
  /// o servidor recusa.
  static const List<ServicoDoCatalogo> catalogoDaDemonstracao =
      <ServicoDoCatalogo>[
    ServicoDoCatalogo(
      id: 'whatsapp',
      nomeExibido: 'WhatsApp',
      descricaoCurta: 'Mandar mensagem e fazer chamada de vídeo',
      categoria: CategoriaDoServico.cotidiano,
      memoraPodeAbrir: true,
    ),
    ServicoDoCatalogo(
      id: 'youtube',
      nomeExibido: 'YouTube',
      descricaoCurta: 'Ver vídeos',
      categoria: CategoriaDoServico.cotidiano,
      memoraPodeAbrir: true,
    ),
    ServicoDoCatalogo(
      id: 'meu-inss',
      nomeExibido: 'Meu INSS',
      descricaoCurta: 'Ver seu benefício e agendar atendimento',
      categoria: CategoriaDoServico.sensivel,
      memoraPodeAbrir: false,
    ),
    ServicoDoCatalogo(
      id: 'gov-br',
      nomeExibido: 'Gov.br',
      descricaoCurta: 'Serviços do governo',
      categoria: CategoriaDoServico.sensivel,
      memoraPodeAbrir: false,
    ),
  ];

  /// Ações registradas nesta execução. Só para teste.
  final List<AcaoRegistrada> acoesRegistradas = <AcaoRegistrada>[];

  @override
  Future<RespostaDaAssistente> conversar({
    required String mensagem,
    required List<MensagemDaConversa> historico,
    void Function(String trecho)? aoReceberTrecho,
  }) async {
    await Future<void>.delayed(demora);

    if (falhaForcada != null) {
      return AssistenteFalhou(
        falhaForcada!,
        tentarNovamenteEmSegundos:
            falhaForcada == FalhaDaAssistente.limiteDeConversas ? 3600 : null,
      );
    }

    final String pedido = mensagem.toLowerCase();

    // Serviço sensível: ensina e NUNCA oferece abrir, nem sob pedido direto.
    if (_mencionaSensivel(pedido)) {
      return _emPedacos(
        'Esse eu te ensino, mas não abro — e vou te contar por quê: se eu '
        'abrisse aplicativo de banco para você, alguém poderia ligar dizendo '
        'ser do suporte e pedir a mesma coisa. Assim fica mais seguro 😊 '
        'Vamos com calma: procure na sua tela o desenho azul e branco.',
        aoReceberTrecho,
      );
    }

    // Dificuldade declarada: aí sim a oferta aparece (FR-014).
    if (_declarouDificuldade(pedido)) {
      final ServicoDoCatalogo alvo = catalogoDaDemonstracao.first;
      return _emPedacos(
        'Tudo bem, acontece! Quer que eu abra o ${alvo.nomeExibido} para '
        'você desta vez? Depois eu te mostro de novo o caminho, com calma.',
        aoReceberTrecho,
        acao: AcaoAutorizada(
          servicoId: alvo.id,
          nomeExibido: alvo.nomeExibido,
          identificadorAndroid: 'com.whatsapp',
        ),
      );
    }

    // O caso comum: ensinar, um passo por vez (FR-008).
    return _emPedacos(
      'Vamos juntos, um passo de cada vez. Primeiro, procure na sua tela um '
      'quadradinho verde com um telefone branco dentro. Me diga quando achar 😊',
      aoReceberTrecho,
    );
  }

  @override
  Future<List<ServicoDoCatalogo>> catalogo() async {
    await Future<void>.delayed(demora);
    return catalogoDaDemonstracao;
  }

  @override
  Future<void> registrarAcao({
    required String servicoId,
    required String pedidoResumido,
  }) async {
    await Future<void>.delayed(demora);
    final ServicoDoCatalogo servico = catalogoDaDemonstracao.firstWhere(
      (ServicoDoCatalogo s) => s.id == servicoId,
      orElse: () => catalogoDaDemonstracao.first,
    );
    acoesRegistradas.insert(
      0,
      AcaoRegistrada(
        nomeExibido: servico.nomeExibido,
        pedidoResumido: pedidoResumido,
        ocorridoEm: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<AcaoRegistrada>> registro() async {
    await Future<void>.delayed(demora);
    return List<AcaoRegistrada>.unmodifiable(acoesRegistradas);
  }

  /// Entrega a resposta em pedaços, como o servidor entregaria.
  ///
  /// A tela precisa ser exercitada no modo em que vai funcionar, e não num
  /// caminho especial que só existe no simulado.
  Future<RespostaDaAssistente> _emPedacos(
    String texto,
    void Function(String trecho)? aoReceberTrecho, {
    AcaoAutorizada? acao,
  }) async {
    if (aoReceberTrecho != null) {
      for (final String palavra in texto.split(' ')) {
        aoReceberTrecho('$palavra ');
      }
    }
    return AssistenteRespondeu(texto, acao: acao);
  }

  bool _mencionaSensivel(String pedido) => <String>[
        'banco',
        'inss',
        'gov',
        'benefício',
        'beneficio',
        'aposentadoria',
        'pix',
      ].any(pedido.contains);

  bool _declarouDificuldade(String pedido) => <String>[
        'não consegui',
        'nao consegui',
        'não estou conseguindo',
        'nao estou conseguindo',
        'não achei',
        'nao achei',
        'não to achando',
        'nao to achando',
        'me ajuda',
        'faz pra mim',
        'abre pra mim',
      ].any(pedido.contains);
}
