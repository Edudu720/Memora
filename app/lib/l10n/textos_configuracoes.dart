/// Textos de Ajustes e das telas que saem dele (feature 004, US7).
///
/// Mesma estrutura de `textos_casca.dart`: as frases moram fora das telas, na
/// voz da Memora. O que a Conta diz sobre o que **ninguém do Memora** faz
/// (FR-036a) **não** está aqui: vem de `TextosApresentacao`, para a mesma frase
/// não existir em dois arquivos e divergir na primeira melhoria feita em um.
abstract final class TextosConfiguracoes {
  // ---------------------------------------------------------------------------
  // Ajustes — as portas dos quatro grupos (FR-038)
  // ---------------------------------------------------------------------------

  /// Título de Ajustes.
  static const String tituloAjustes = 'Ajustes';

  /// Instrução da caixa de portas em Ajustes (FR-002a).
  static const String instrucaoAjustes =
      'Escolha o que você quer ajustar no Memora.';

  /// Porta de Aparência.
  static const String portaAparencia = 'Como o Memora fica';

  /// O que há atrás da porta de Aparência.
  static const String descricaoAparencia = 'Escolher as cores';

  /// Porta de Acessibilidade.
  static const String portaAcessibilidade = 'Enxergar e usar melhor';

  /// O que há atrás da porta de Acessibilidade.
  static const String descricaoAcessibilidade = 'Letra, movimento e contraste';

  /// Porta de Privacidade.
  static const String portaPrivacidade = 'O que fica guardado';

  /// O que há atrás da porta de Privacidade.
  static const String descricaoPrivacidade = 'O que fica neste celular';

  /// Porta de Conta.
  static const String portaConta = 'Minha conta';

  /// O que há atrás da porta de Conta.
  static const String descricaoConta = 'Seu contato e a saída';

  /// A galeria, que só existe no modo de desenvolvimento (R9 da 002).
  static const String galeria = 'Galeria de componentes (desenvolvimento)';

  // ---------------------------------------------------------------------------
  // Privacidade (FR-040)
  // ---------------------------------------------------------------------------

  /// Título da tela.
  static const String tituloPrivacidade = 'O que fica guardado';

  /// Abre a tela dizendo para onde vai o que ela vai listar.
  static const String privacidadeIntro =
      'Estas coisas ficam guardadas neste celular.';

  /// Rótulo da conversa.
  static const String guardadoConversa = 'A conversa com a Memora';

  /// O que é a conversa guardada, e quando sai.
  static const String guardadoConversaValor =
      'O que conversamos fica guardado só aqui e sai quando você sai da '
      'conta. Para eu responder, a conversa viaja a cada pergunta, mas o '
      'Memora não guarda cópia.';

  /// Rótulo da data de nascimento.
  static const String guardadoIdade = 'Sua data de nascimento';

  /// Quando a data de nascimento sai.
  static const String guardadoIdadeValor =
      'Só se você contou no seu perfil. Você pode tirá-la de lá quando '
      'quiser, e ela também sai com "Sair e esquecer este aparelho".';

  /// Rótulo da apresentação vista.
  static const String guardadoApresentacao = 'Que você já viu a apresentação';

  /// Quando a marca da apresentação sai.
  static const String guardadoApresentacaoValor =
      'Para eu não mostrar a apresentação de novo. Sai com "Sair e esquecer '
      'este aparelho".';

  /// Rótulo do identificador do último acesso.
  static const String guardadoContato = 'O seu e-mail ou telefone';

  /// Quando o identificador sai.
  static const String guardadoContatoValor =
      'Fica aqui para você não digitar tudo de novo, e o Memora também o '
      'conhece porque é o contato da sua conta. Sai deste celular com '
      '"Sair e esquecer este aparelho".';

  /// O que **nunca** fica depois de sair.
  static const String guardadoNuncaFica =
      'A sua senha e o acesso à sua conta não ficam guardados depois que '
      'você sai.';

  /// Título da parte que apaga.
  static const String tituloApagarConversa = 'Apagar a conversa';

  /// Explica o que apagar faz, antes do botão.
  static const String explicacaoApagarConversa =
      'Se quiser, eu apago agora a nossa conversa deste celular. Você pode '
      'começar outra quando quiser.';

  /// O botão que abre a pergunta.
  static const String botaoApagarConversa = 'Apagar a conversa';

  /// A pergunta (primeira etapa).
  static const String perguntaApagarConversa =
      'Apagar a conversa com a Memora?';

  /// O que acontece ao apagar.
  static const String avisoApagarConversa =
      'A conversa some deste celular e não dá para trazê-la de volta.';

  /// Recusa, frase completa.
  static const String botaoManterConversa = 'Não, quero manter a conversa';

  /// Enquanto apaga.
  static const String apagandoConversa = 'Estou apagando a conversa...';

  /// Depois de apagar.
  static const String conversaApagada =
      'Pronto. A conversa foi apagada deste celular.';

  /// Quando não deu para apagar.
  static const String conversaNaoApagada =
      'Não consegui apagar a conversa agora, e ela continua no celular. '
      'Tente de novo daqui a pouco.';

  // ---------------------------------------------------------------------------
  // Conta (FR-041, FR-036a)
  // ---------------------------------------------------------------------------

  /// Título da tela.
  static const String tituloConta = 'Minha conta';

  /// Enquanto o contato é lido.
  static const String carregandoContato = 'Procurando o contato da conta...';

  /// O contato não está neste celular.
  static const String semContatoTitulo = 'Não achei o contato aqui';

  /// Explica por quê, e o que fazer.
  static const String semContatoExplicacao =
      'Este celular não guardou o e-mail ou telefone da conta. Ele volta a '
      'aparecer da próxima vez que você entrar.';

  /// Não deu para ler o contato.
  static const String erroDoContato =
      'Não consegui ler o contato da conta agora.';

  /// Título da parte de sair.
  static const String tituloSair = 'Sair';

  /// Título da parte que esquece o aparelho.
  static const String tituloEsquecer = 'Se este celular não é só seu';

  /// Para que serve "Sair e esquecer" (FR-041).
  static const String paraQueServeEsquecer =
      'Use se o celular é de mais gente, ou se vai ser vendido ou dado. Além '
      'de sair, eu apago conversa, idade, apresentação e contato — só os '
      'ajustes de aparência ficam.';

  /// O botão que abre a pergunta.
  static const String botaoEsquecer = 'Sair e esquecer este aparelho';

  /// A pergunta (primeira etapa).
  static const String perguntaEsquecer =
      'Sair e apagar tudo o que o Memora guardou neste celular?';

  /// O que acontece.
  static const String avisoEsquecer =
      'Para entrar de novo, você vai precisar do seu e-mail ou telefone e da '
      'sua senha.';

  /// Recusa, frase completa.
  static const String botaoNaoEsquecer = 'Não, quero ficar';
}
