/// Textos da feature 003 — Hub e assistente — na voz da Memora.
///
/// Mesma escolha da `TextosAutenticacao`: arquivo Dart em `l10n/`, e não
/// `flutter_localizations`. É a "estrutura preparada" da decisão D3 da feature
/// 002 — quando houver um segundo idioma, estas constantes viram `.arb` sem
/// ninguém caçar frase dentro de widget.
class TextosAssistente {
  const TextosAssistente._();

  // ---------------------------------------------------------------------------
  // Hub — US1
  // ---------------------------------------------------------------------------

  /// Saudação do Hub, com o nome de tratamento.
  ///
  /// Usa o nome porque esta é a tela que a pessoa mais verá na vida do
  /// aplicativo, e ser chamada pelo nome é o que separa "um sistema" de "a
  /// Memora".
  static String saudacao(String nome) => 'Oi, $nome! O que vamos fazer hoje?';

  /// Nome da porta que leva à conversa.
  static const String portaConversa = 'Conversar com a Memora';

  /// O que essa porta faz.
  static const String descricaoConversa =
      'Me pergunte qualquer coisa sobre o celular';

  /// Nome da porta dos serviços que a Memora só ensina.
  static const String portaServicos = 'Serviços do dia a dia';

  /// O que essa porta faz.
  static const String descricaoServicos =
      'Banco, INSS e governo — eu te ensino o caminho';

  /// Nome da porta dos aplicativos que a Memora pode abrir.
  static const String portaAplicativos = 'Meus aplicativos';

  /// O que essa porta faz.
  static const String descricaoAplicativos =
      'WhatsApp, fotos, vídeos — eu te ensino e posso abrir';

  /// Nome da porta de ajuda.
  static const String portaAjuda = 'Preciso de ajuda';

  /// O que essa porta faz.
  static const String descricaoAjuda = 'Dúvidas sobre o próprio Memora';

  /// Nome da porta do registro.
  static const String portaRegistro = 'O que eu fiz por você';

  /// O que essa porta faz.
  static const String descricaoRegistro =
      'Tudo que eu abri no seu lugar fica anotado aqui';

  // ---------------------------------------------------------------------------
  // Conversa — US2
  // ---------------------------------------------------------------------------

  /// Título da tela de conversa.
  static const String tituloConversa = 'Conversar com a Memora';

  /// Convite da primeira mensagem.
  static const String convite =
      'Pode me perguntar do jeito que você fala. Não precisa escrever bonito, '
      'e não tem pergunta boba 😊';

  /// Rótulo do campo de mensagem.
  static const String rotuloMensagem = 'Escreva aqui sua pergunta';

  /// Ajuda do campo de mensagem.
  static const String ajudaMensagem =
      'Por exemplo: como vejo as fotos do meu neto';

  /// Rótulo do botão de enviar.
  static const String botaoEnviar = 'Perguntar';

  /// Mensagem enquanto a Memora responde.
  ///
  /// Existe porque tela parada é o que faz este público concluir que o aparelho
  /// travou (SC-007).
  static const String pensando = 'Estou pensando...';

  /// Título do aviso permanente contra golpe (FR-033).
  static const String tituloAvisoAntigolpe = 'Eu nunca peço sua senha';

  /// O aviso, no mesmo idioma da tela de recuperação da feature 001.
  static const String avisoAntigolpe =
      'Nem eu, nem ninguém que diga trabalhar no Memora, vai te pedir sua '
      'senha ou um número de confirmação — nem por telefone, nem por mensagem, '
      'nem por e-mail. Se alguém pedir, é golpe: pode desligar sem responder.';

  // ---------------------------------------------------------------------------
  // A oferta de executar — US3
  // ---------------------------------------------------------------------------

  /// Título da confirmação antes de abrir (FR-015).
  static const String tituloConfirmarAbertura = 'Posso abrir para você?';

  /// O que exatamente vai acontecer.
  ///
  /// Diz o nome do aplicativo **e** que a pessoa vai sair do Memora, porque o
  /// Princípio II exige avisar antes de sair (FR-021). Descobrir isso depois,
  /// já noutra tela, é onde alguém se perde.
  static String pedidoDeAbertura(String aplicativo) =>
      'Vou abrir o $aplicativo para você. Você vai sair do Memora e entrar '
      'nele — quando quiser voltar, é só me chamar de novo.';

  /// Rótulo do botão que confirma.
  static String botaoAbrir(String aplicativo) => 'Sim, abra o $aplicativo';

  /// Rótulo do botão que recusa.
  ///
  /// *"Prefiro tentar"*, e não *"cancelar"*: quem recusa aqui está escolhendo
  /// aprender, e o texto reconhece isso em vez de tratar a recusa como
  /// desistência.
  static const String botaoPrefiroTentar = 'Prefiro tentar sozinha';

  /// Reconhecimento depois de a pessoa fazer sozinha.
  static const String vocePodeFazerSozinha =
      'Viu? Foi você quem fez 😊 Da próxima vez vai ser mais fácil.';

  // ---------------------------------------------------------------------------
  // Catálogo — US5
  // ---------------------------------------------------------------------------

  /// Explicação de por que a Memora não abre serviço sensível (FR-042).
  ///
  /// Diz o que a recusa **compra para a pessoa**, e não o que ela proíbe. A
  /// FR-041 é uma proteção, e precisa ser lida como tal — senão soa como
  /// limitação do produto.
  static const String porqueNaoAbroServicoSensivel =
      'Esse eu te ensino, mas não abro. É de propósito: se eu abrisse banco e '
      'governo, alguém poderia ligar dizendo ser do suporte e pedir a mesma '
      'coisa. Assim você fica mais segura 😊';

  // ---------------------------------------------------------------------------
  // Falhas
  // ---------------------------------------------------------------------------

  /// Sem conexão.
  static const String semConexao =
      'Não consegui falar com a internet agora. O que você escreveu continua '
      'aqui, é só tentar de novo.';

  /// A cota diária acabou (R7).
  ///
  /// Não sugere que a pessoa fez algo errado — ela só conversou bastante.
  static const String limiteDeConversas =
      'Conversamos bastante hoje 😊 Vamos continuar amanhã? Eu estarei aqui.';

  /// A sessão caiu.
  static const String sessaoExpirada =
      'Faz um tempinho que você não usa o Memora. Vamos entrar de novo?';

  /// Qualquer outra falha.
  static const String inesperada =
      'Algo não saiu como eu esperava. Vamos tentar mais uma vez?';
}
