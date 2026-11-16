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
    // Espelha o catálogo real (migrations V5, V6 e V8). Um simulado que
    // mostrasse serviços que o banco não tem faria a demonstração prometer o
    // que o produto não entrega — apareceu ao rodar no emulador. Agora há teste
    // que pega a divergência de chaves (catalogo_e_guias_test.dart); a
    // descrição e a categoria continuam por conta de quem mexe no catálogo.
    ServicoDoCatalogo(
      id: 'whatsapp',
      chave: 'whatsapp',
      nomeExibido: 'WhatsApp',
      descricaoCurta: 'Mandar mensagem e fazer chamada de vídeo',
      categoria: CategoriaDoServico.cotidiano,
      memoraPodeAbrir: true,
      identificadorAndroid: 'com.whatsapp',
    ),
    ServicoDoCatalogo(
      id: 'facebook',
      chave: 'facebook',
      nomeExibido: 'Facebook',
      descricaoCurta: 'Ver o que a família e os amigos postaram',
      categoria: CategoriaDoServico.cotidiano,
      memoraPodeAbrir: true,
      identificadorAndroid: 'com.facebook.katana',
    ),
    ServicoDoCatalogo(
      id: 'instagram',
      chave: 'instagram',
      nomeExibido: 'Instagram',
      descricaoCurta: 'Ver fotos e vídeos de quem você segue',
      categoria: CategoriaDoServico.cotidiano,
      memoraPodeAbrir: true,
      identificadorAndroid: 'com.instagram.android',
    ),
    ServicoDoCatalogo(
      id: 'youtube',
      chave: 'youtube',
      nomeExibido: 'YouTube',
      descricaoCurta: 'Ver vídeos',
      categoria: CategoriaDoServico.cotidiano,
      memoraPodeAbrir: true,
      identificadorAndroid: 'com.google.android.youtube',
    ),
    ServicoDoCatalogo(
      id: 'google-fotos',
      chave: 'google-fotos',
      nomeExibido: 'Google Fotos',
      descricaoCurta: 'Ver as fotos que você tirou e as que te enviaram',
      categoria: CategoriaDoServico.cotidiano,
      memoraPodeAbrir: true,
      identificadorAndroid: 'com.google.android.apps.photos',
    ),
    ServicoDoCatalogo(
      id: 'telegram',
      chave: 'telegram',
      nomeExibido: 'Telegram',
      descricaoCurta: 'Outro jeito de mandar mensagem',
      categoria: CategoriaDoServico.cotidiano,
      memoraPodeAbrir: true,
      identificadorAndroid: 'org.telegram.messenger',
    ),
    ServicoDoCatalogo(
      id: 'tiktok',
      chave: 'tiktok',
      nomeExibido: 'TikTok',
      descricaoCurta: 'Assistir a vídeos e seguir criadores de conteúdo',
      categoria: CategoriaDoServico.cotidiano,
      memoraPodeAbrir: true,
      identificadorAndroid: 'com.zhiliaoapp.musically',
    ),
    ServicoDoCatalogo(
      id: 'gov-br',
      chave: 'gov-br',
      nomeExibido: 'Gov.br',
      descricaoCurta: 'Documentos, benefícios e agendamentos do governo',
      categoria: CategoriaDoServico.sensivel,
      memoraPodeAbrir: false,
    ),
    ServicoDoCatalogo(
      id: 'meu-inss',
      chave: 'meu-inss',
      nomeExibido: 'Meu INSS',
      descricaoCurta: 'Ver seu benefício, extrato e agendar atendimento',
      categoria: CategoriaDoServico.sensivel,
      memoraPodeAbrir: false,
    ),
    ServicoDoCatalogo(
      id: 'e-titulo',
      chave: 'e-titulo',
      nomeExibido: 'e-Título',
      descricaoCurta: 'Consultar situação eleitoral, local de votação e justificativa',
      categoria: CategoriaDoServico.sensivel,
      memoraPodeAbrir: false,
    ),
    ServicoDoCatalogo(
      id: 'serasa',
      chave: 'serasa',
      nomeExibido: 'Serasa',
      descricaoCurta: 'Consultar CPF, score e renegociação de dívidas',
      categoria: CategoriaDoServico.sensivel,
      memoraPodeAbrir: false,
    ),
    ServicoDoCatalogo(
      id: 'fgts',
      chave: 'fgts',
      nomeExibido: 'FGTS',
      descricaoCurta: 'Consultar saldo do FGTS, extrato e saque-aniversário',
      categoria: CategoriaDoServico.sensivel,
      memoraPodeAbrir: false,
    ),
    ServicoDoCatalogo(
      id: 'poupatempo',
      chave: 'poupatempo',
      nomeExibido: 'Poupatempo',
      descricaoCurta: 'Agendar atendimentos e serviços públicos do estado',
      categoria: CategoriaDoServico.sensivel,
      memoraPodeAbrir: false,
    ),
    ServicoDoCatalogo(
      id: 'carteira-digital',
      chave: 'carteira-digital',
      nomeExibido: 'Carteira Digital',
      descricaoCurta: 'Documentos pessoais e carteira de identificação oficial',
      categoria: CategoriaDoServico.sensivel,
      memoraPodeAbrir: false,
    ),
    ServicoDoCatalogo(
      id: 'correios',
      chave: 'correios',
      nomeExibido: 'Correios',
      descricaoCurta: 'Rastrear encomendas e gerenciar entregas',
      categoria: CategoriaDoServico.sensivel,
      memoraPodeAbrir: false,
    ),
    ServicoDoCatalogo(
      id: 'carteira-de-trabalho',
      chave: 'carteira-de-trabalho',
      nomeExibido: 'Carteira de Trabalho Digital',
      descricaoCurta: 'Acessar contratos de trabalho, férias e seguro-desemprego',
      categoria: CategoriaDoServico.sensivel,
      memoraPodeAbrir: false,
    ),
  ];

  /// Espera a demora simulada, **sem criar timer quando ela é zero**.
  ///
  /// ## Por que isto não é micro-otimização
  ///
  /// `Future.delayed(Duration.zero)` ainda agenda um timer. Dentro de
  /// `testWidgets` o relógio é falso, e um `await` no corpo do teste — sem
  /// ninguém bombeando quadros — **nunca completa**: o caso morre em "did not
  /// complete" depois de minutos, sem apontar a causa.
  ///
  /// Já custou duas rodadas nesta feature. Com o atalho, `demora: Duration.zero`
  /// significa de verdade "não espere", e o teste pode chamar o repositório
  /// direto, sem `runAsync`.
  Future<void> _esperar() async {
    if (demora == Duration.zero) return;
    await Future<void>.delayed(demora);
  }

  /// Ações registradas nesta execução. Só para teste.
  final List<AcaoRegistrada> acoesRegistradas = <AcaoRegistrada>[];

  @override
  Future<RespostaDaAssistente> conversar({
    required String mensagem,
    required List<MensagemDaConversa> historico,
    void Function(String trecho)? aoReceberTrecho,
    void Function(void Function() cancelar)? aoCriarCancelamento,
  }) async {
    bool cancelado = false;
    aoCriarCancelamento?.call(() => cancelado = true);
    await _esperar();
    if (cancelado) {
      return const AssistenteFalhou(FalhaDaAssistente.semConexao);
    }

    // Qualquer uma das cinco falhas, sob comando — inclusive
    // `assistenteIndisponivel` (FR-057), que o servidor real entrega como
    // evento `erro` com `ASSISTENTE_INDISPONIVEL`.
    if (falhaForcada != null) {
      return AssistenteFalhou(falhaForcada!);
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

    // Aplicativo mudou de visual / pessoa não achou o botão (T090):
    // acolhe sem culpar e orienta outras pistas visuais sem oferecer abrir.
    if (_naoAchouBotaoNaTela(pedido)) {
      return _emPedacos(
        'Sem problemas! Os aplicativos mudam os desenhos e cores de lugar '
        'quando atualizam — não foi erro seu 😊 Me conta o que aparece na sua '
        'tela agora (algum símbolo, três pontinhos no alto ou palavra escrita '
        'perto) que a gente procura juntos o novo botão.',
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
    await _esperar();
    return catalogoDaDemonstracao;
  }

  @override
  Future<void> registrarAcao({
    required String servicoId,
    required String pedidoResumido,
  }) async {
    await _esperar();
    final ServicoDoCatalogo servico = catalogoDaDemonstracao.firstWhere(
      (ServicoDoCatalogo s) => s.id == servicoId,
      orElse: () => catalogoDaDemonstracao.first,
    );
    // Sanitiza segredos e dígitos longos no simulado também (T079, FR-036).
    final String sanitizado = pedidoResumido
        .replaceAll(
          RegExp(
            r'\b(senha|c[oó]digo|codigo|pin|token)\s*(?:[:=]|é|e)?\s*\S+',
            caseSensitive: false,
          ),
          r' ***',
        )
        .replaceAll(RegExp(r'\b\d{4,}\b'), '***');

    acoesRegistradas.insert(
      0,
      AcaoRegistrada(
        nomeExibido: servico.nomeExibido,
        pedidoResumido: sanitizado,
        ocorridoEm: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<AcaoRegistrada>> registro() async {
    await _esperar();
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

  bool _naoAchouBotaoNaTela(String pedido) => <String>[
        'não achei o botão',
        'nao achei o botao',
        'não achei esse botão',
        'nao achei esse botao',
        'não encontrei o botão',
        'nao encontrei o botao',
        'botão sumiu',
        'botao sumiu',
        'botão mudou',
        'botao mudou',
        'tela mudou',
        'botão diferente',
        'botao diferente',
        'não achei o ícone',
        'nao achei o icone',
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
