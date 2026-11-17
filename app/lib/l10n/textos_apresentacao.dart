/// Textos da apresentação inicial — Olá, Apresentação e Exemplo (US1, T049).
///
/// Criado na fundação da feature 004 (T005), vazio de propósito: a estrutura
/// existe antes das telas para nenhuma frase nascer solta dentro de um widget.
/// Mesmo formato de `textos_autenticacao.dart` — a "estrutura preparada" da
/// D3 da 002, que vira `.arb` no dia em que houver um segundo idioma.
abstract final class TextosApresentacao {
  /// Rótulo de quem avança. Igual nas três telas (FR-012).
  static const String continuar = 'Continuar';

  /// Rótulo de quem quer pular. Visível nas três telas (FR-012).
  static const String pular = 'Pular';

  /// "Passo 2 de 3": a pessoa sabe quanto falta, e que são poucas.
  static String passo(int atual, int total) => 'Passo $atual de $total';

  /// Aviso de leitor de tela da barra de passos.
  static String passoDescrito(int atual, int total) =>
      'Apresentação, passo $atual de $total';

  /// Frase enquanto o aplicativo confere se a pessoa já viu a apresentação
  /// (FR-006: nenhuma tela em branco).
  static const String preparando = 'A Memora está chegando...';

  // ---------------------------------------------------------------------------
  // Olá — quem ela é, e o que ela nunca faz (FR-036a)
  // ---------------------------------------------------------------------------

  /// Título da primeira tela.
  static const String tituloOla = 'Prazer em te conhecer';

  /// A saudação, com o nome de tratamento quando existe.
  static String ola(String nome) {
    final String chamada = nome.trim().isEmpty
        ? 'Olá!'
        : 'Olá, ${nome.trim()}!';
    return '$chamada Eu sou a Memora. Estou aqui para te mostrar, com calma e '
        'passo a passo, como usar o seu celular.';
  }

  /// Título do quadro do que a Memora nunca faz.
  static const String tituloNunca = 'O que eu nunca faço';

  /// O que **ninguém do Memora** faz (FR-036a).
  ///
  /// Literal de propósito: a versão "o Memora nunca pede senha" seria falsa,
  /// porque ele pede a senha no login, na recuperação e na confirmação do
  /// canal. O que ninguém faz é pedir **por telefone, mensagem ou e-mail**.
  /// São quatro frases curtas, e não um parágrafo: quem lê devagar acha cada
  /// uma sem reler as outras.
  static const List<String> nuncaFaco = <String>[
    'Eu nunca peço sua senha ou um código por telefone, mensagem ou e-mail.',
    'Ninguém do Memora liga para você.',
    'Eu nunca peço para instalar um aplicativo fora da loja oficial, nem '
        '"para o Memora funcionar".',
    'Eu nunca cobro nada.',
  ];

  /// O que fazer se alguém pedir.
  static const String seAlguemPedir =
      'Se alguém disser que é do Memora e pedir qualquer uma dessas coisas, é '
      'golpe: pode desligar sem responder.';

  // ---------------------------------------------------------------------------
  // Apresentação — para que serve a conversa
  // ---------------------------------------------------------------------------

  /// Título da segunda tela.
  static const String tituloConversa = 'Para que serve a conversa';

  /// A Memora explica a conversa.
  static const String conversa =
      'Quando você tiver uma dúvida, é só me perguntar, do seu jeito. Eu '
      'mostro o caminho, para que da próxima vez você consiga sozinha.';

  /// Ela ensina, não faz por ela (Princípio VII).
  static const String ensinoNaoSubstituo =
      'Eu ensino, e não faço por você. E, antes de abrir qualquer aplicativo, '
      'eu sempre pergunto.';

  // ---------------------------------------------------------------------------
  // Exemplo — a conversa por dentro
  // ---------------------------------------------------------------------------

  /// Título da terceira tela.
  static const String tituloExemplo = 'Um exemplo de conversa';

  /// Diz que o que vem a seguir é só demonstração, e que não há nada a digitar.
  static const String avisoDoExemplo =
      'É só um exemplo. Aqui você não precisa escrever nada.';

  /// A pergunta de exemplo, no balão da pessoa.
  static const String exemploPergunta = 'Como eu mando uma foto no WhatsApp?';

  /// A resposta de exemplo, no balão da Memora.
  static const String exemploResposta =
      'Claro, primeiro abra o WhatsApp e entre na conversa com quem vai '
      'receber a foto. Quando estiver lá, me avise que eu mostro o próximo '
      'passo.';

  /// Fecha a apresentação e leva ao Início.
  static const String fechamento =
      'Quando você quiser, é só abrir a conversa. Eu estarei lá.';
}
