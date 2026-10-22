import 'textos_apresentacao.dart';

/// Textos da Ajuda — os assuntos, as dicas de segurança e a ajuda guiada da conversa (US6, T086).
///
/// Criado na fundação da feature 004 (T005), vazio de propósito: a estrutura
/// existe antes das telas para nenhuma frase nascer solta dentro de um widget.
/// Mesmo formato de `textos_autenticacao.dart` — a "estrutura preparada" da
/// D3 da 002, que vira `.arb` no dia em que houver um segundo idioma.
///
/// ## A voz
///
/// A Memora fala em primeira pessoa, com calma, e **cada tela tem uma ideia
/// só** (data-model da 004). O que a apresentação já diz sobre o que ela nunca
/// faz (FR-036a) **não é copiado para cá**: a lista do assunto "Segurança" sai
/// de [TextosApresentacao.nuncaFaco]. Duas listas das mesmas quatro frases é
/// como elas começam a divergir — e uma que ficasse mais branda que a outra
/// seria exatamente a que o golpista cita.
abstract final class TextosAjuda {
  // ---------------------------------------------------------------------------
  // A tela de Ajuda
  // ---------------------------------------------------------------------------

  /// Título da tela.
  static const String titulo = 'Preciso de ajuda';

  /// A Memora convida a escolher (wireframe, Figura 14).
  static const String convite =
      'Estou aqui para ajudar. Escolha o assunto que mais se parece com a sua '
      'dúvida.';

  /// Porta que leva a rever a apresentação (FR-013).
  static const String reverApresentacao = 'Ver a apresentação de novo';

  /// O que há do outro lado dessa porta.
  static const String reverApresentacaoExplicacao =
      'Eu me apresento outra vez, em três telas';

  // ---------------------------------------------------------------------------
  // Navegação dentro de um assunto
  // ---------------------------------------------------------------------------

  /// Avança para a ideia seguinte.
  static const String continuar = 'Continuar';

  /// Avança para a dica seguinte, no assunto "Segurança".
  static const String proximaDica = 'Próxima dica';

  /// Volta uma ideia dentro do assunto. Não é o "Voltar" do cabeçalho, que sai
  /// do assunto: dois "Voltar" na mesma tela seriam uma pergunta.
  static const String anterior = 'Anterior';

  /// Sai do assunto, na última ideia.
  static const String voltarParaAjuda = 'Voltar à Ajuda';

  /// "Passo 2 de 3": a pessoa sabe quanto falta, e que são poucas.
  static String passo(int atual, int total) => 'Passo $atual de $total';

  /// "Dica 2 de 8".
  static String dica(int atual, int total) => 'Dica $atual de $total';

  /// Aviso de leitor de tela do contador de passos e de dicas.
  static String passoDescrito(String assunto, int atual, int total) =>
      '$assunto, parte $atual de $total';

  // ---------------------------------------------------------------------------
  // Os assuntos (FR-033)
  // ---------------------------------------------------------------------------

  /// O aplicativo.
  static const String tituloAplicativo = 'O aplicativo';

  /// Uma linha do que há no assunto.
  static const String explicacaoAplicativo = 'Para que serve o Memora';

  /// As ideias do assunto, uma por tela.
  static const List<String> telasDoAplicativo = <String>[
    'O Memora é um aplicativo que ensina você a usar o celular, no seu ritmo. '
        'Aqui ninguém tem pressa.',
    'Embaixo da tela ficam três lugares: Ajustes, Início e Meu perfil. É só '
        'tocar no que você quer.',
    'Se você se perder, toque em "Início", na barra de baixo. É como voltar '
        'para a porta de casa.',
  ];

  /// A Memora.
  static const String tituloMemora = 'A Memora';

  /// Uma linha do que há no assunto.
  static const String explicacaoMemora = 'Quem sou eu e o que faço';

  /// As ideias do assunto, uma por tela.
  static const List<String> telasDaMemora = <String>[
    'Eu sou a Memora. Estou aqui para te mostrar o caminho, passo a passo, '
        'para que da próxima vez você consiga sozinha.',
    TextosApresentacao.ensinoNaoSubstituo,
    'Se eu não souber, eu digo. E, se uma dúvida for séria, vale perguntar '
        'também a alguém de confiança.',
  ];

  /// A conversa. O conteúdo é a ajuda guiada (T088), não uma lista de textos.
  static const String tituloConversa = 'A conversa';

  /// Uma linha do que há no assunto.
  static const String explicacaoConversa =
      'Como pedir ajuda a mim, passo a passo';

  /// Os serviços.
  static const String tituloServicos = 'Os serviços';

  /// Uma linha do que há no assunto.
  static const String explicacaoServicos = 'Gov.br, Meu INSS e outros';

  /// As ideias do assunto, uma por tela.
  ///
  /// D2 da 003: quanto mais sensível o serviço, menos a Memora toca nele.
  static const List<String> telasDosServicos = <String>[
    'Serviços sociais são coisas como o Gov.br e o Meu INSS. Neles ficam seus '
        'documentos e seus benefícios.',
    'Nesses serviços eu só te ensino o caminho. Eu nunca abro por você, e '
        'quem digita a senha é você, no aplicativo oficial.',
  ];

  /// Como baixar um aplicativo (FR-036).
  static const String tituloBaixarAplicativo = 'Como baixar um aplicativo';

  /// Uma linha do que há no assunto.
  static const String explicacaoBaixarAplicativo =
      'Só pela loja oficial do celular';

  /// As ideias do assunto, uma por tela.
  ///
  /// A primeira diz **qual** é a loja e a segunda **por quê** (FR-036); a
  /// terceira é a conferência do desenvolvedor, que é o que separa o
  /// aplicativo de verdade da cópia com nome parecido. A última é o pedido do
  /// golpista, dito com as palavras da FR-036a.
  static const List<String> telasDeBaixarAplicativo = <String>[
    'Aplicativo só se baixa na loja oficial do celular. No Android, ela se '
        'chama Play Store.',
    'Por quê: é fora da loja oficial que ficam as cópias falsas, feitas para '
        'roubar sua senha e seus dados.',
    'Antes de instalar, confira o desenvolvedor: o nome da empresa que fez o '
        'aplicativo aparece logo abaixo do nome dele, na loja. Tem de ser a '
        'empresa de verdade — o WhatsApp, por exemplo, é de "WhatsApp LLC". '
        'Cópia falsa costuma ter um nome parecido, com letra trocada.',
    'Se alguém pedir para você instalar um aplicativo "para o Memora '
        'funcionar", é golpe.',
  ];

  /// Compartilhar (FR-035). Só existe com endereço de download (R12).
  static const String tituloCompartilhar = 'Compartilhar o Memora';

  /// Uma linha do que há no assunto.
  static const String explicacaoCompartilhar =
      'Mandar o Memora para alguém de confiança';

  /// A ideia do assunto.
  static const List<String> telasDeCompartilhar = <String>[
    'Você pode mandar para alguém o endereço para baixar o Memora. Vai só o '
        'endereço oficial. Nada seu vai junto: nem seu nome, nem sua conta, '
        'nem sua conversa.',
  ];

  /// O botão que começa o compartilhamento.
  static const String botaoCompartilhar = 'Compartilhar o Memora';

  /// A pergunta antes de abrir a folha do sistema (FR-035, FR-037).
  static const String perguntaCompartilhar =
      'Posso abrir a folha de compartilhar?';

  /// O aviso de que a pessoa vai mandar algo para fora do Memora, **com o
  /// endereço escrito**: ela vê para onde leva (FR-037).
  static String avisoCompartilhar(String endereco) =>
      'Você vai mandar uma mensagem para fora do Memora. Vai só este '
      'endereço:\n$endereco\nNada seu vai junto.';

  /// Confirma o envio.
  static const String simCompartilhar = 'Sim, compartilhar';

  /// Desiste do envio.
  static const String naoCompartilhar = 'Agora não';

  /// A folha do sistema não abriu.
  static const String erroAoCompartilhar =
      'Não consegui abrir a folha de compartilhar. Você pode tentar de novo, '
      'se quiser.';

  /// Título da folha do sistema.
  static const String tituloDaFolha = 'Compartilhar o Memora';

  /// Segurança (FR-036a).
  static const String tituloSeguranca = 'Segurança contra golpes';

  /// Uma linha do que há no assunto.
  static const String explicacaoSeguranca = 'Como não cair em golpe';

  /// As dicas gerais, sobre golpe por telefone, que vêm **antes** do que o
  /// Memora nunca faz. Quem procura "como me proteger de um golpe por telefone"
  /// (US6) as encontra nas primeiras telas.
  static const List<String> dicasGeraisDeSeguranca = <String>[
    'Golpe por telefone: alguém liga dizendo ser do banco, do INSS ou do '
        'suporte e pede um código ou uma senha. Desligue. Nenhum deles pede '
        'isso por telefone.',
    'Quem apressa quer que você erre. "É urgente", "sua conta vai ser '
        'bloqueada": pare, respire e desligue.',
    'Depois, ligue você para o número que está no seu cartão ou no site '
        'oficial, ou converse com alguém de confiança.',
  ];

  /// O assunto inteiro, uma dica por tela: as gerais e, depois, o que **ninguém
  /// do Memora** faz — lido de [TextosApresentacao], de onde vem também a
  /// apresentação (FR-036a).
  static const List<String> dicasDeSeguranca = <String>[
    ...dicasGeraisDeSeguranca,
    ...TextosApresentacao.nuncaFaco,
    TextosApresentacao.seAlguemPedir,
  ];

  // ---------------------------------------------------------------------------
  // A ajuda guiada da conversa (T088, FR-034; Figuras 15 a 19 do wireframe)
  // ---------------------------------------------------------------------------

  /// Quantas telas tem a ajuda guiada.
  static const int totalDeTelasDaConversa = 5;

  /// Primeira tela: o convite (Figura 15).
  static const String guiadaConvite =
      'Vamos ver, passo a passo, como conversar comigo? É bem simples! Para '
      'continuar, toque no botão azul.';

  /// Segunda tela: o que é a conversa (Figura 19).
  static const String guiadaOQueE =
      'Na conversa, você pergunta e eu respondo. Minha função é tirar suas '
      'dúvidas sobre o celular e sobre os aplicativos. Veja um exemplo.';

  /// A pergunta de exemplo, no balão da pessoa.
  static const String guiadaPergunta = 'Como eu mando uma foto no WhatsApp?';

  /// A resposta de exemplo, no balão da Memora.
  static const String guiadaResposta =
      'Claro! Abra o WhatsApp e entre na conversa de quem vai receber a foto. '
      'Quando chegar lá, me avise, e eu mostro o próximo passo.';

  /// Terceira tela: como escrever (Figura 18).
  static const String guiadaComoEscrever =
      'Para escrever, toque na barra que fica embaixo da conversa. Escreva do '
      'seu jeito, como se falasse com uma pessoa. Se eu não entender, eu '
      'pergunto de novo.';

  /// Quarta tela: abrir aplicativo, sempre com pergunta (Figura 17).
  static const String guiadaAbrir =
      'Se você pedir, eu posso abrir um aplicativo para você. Mas antes eu '
      'sempre pergunto, e você responde sim ou não. Eu quero que você aprenda, '
      'e não que fique dependendo de mim.';

  /// A pergunta da Memora no exemplo de abrir aplicativo.
  static const String guiadaPerguntaDeAbrir =
      'Quer que eu abra o WhatsApp para você?';

  /// Quinta tela: a saída (Figura 16).
  static const String guiadaSaida =
      'Agora é a sua vez! Você pode ir direto para a conversa, ou voltar para '
      'a Ajuda e ver outro assunto.';

  /// Avança na ajuda guiada.
  static const String guiadaContinuar = 'Continuar';

  /// Sai da ajuda guiada direto para a conversa de verdade (FR-034).
  static const String guiadaConversar = 'Conversar com a Memora';

  /// Volta à Ajuda, na última tela.
  static const String guiadaVoltar = 'Voltar à Ajuda';

  /// Aviso de que o que vem a seguir é só exemplo, e não há o que digitar.
  static const String guiadaSoExemplo =
      'É só um exemplo. Aqui você não precisa escrever nada.';
}
