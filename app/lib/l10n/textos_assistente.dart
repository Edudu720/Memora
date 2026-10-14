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
  static const String descricaoConversa = 'Me pergunte o que quiser';

  /// Nome da porta dos serviços que a Memora só ensina.
  ///
  /// "Serviços sociais", como no wireframe (FR-008 da feature 004): era
  /// "Serviços do dia a dia", que não dizia de quais serviços se trata.
  static const String portaServicos = 'Serviços sociais';

  /// O que essa porta faz.
  static const String descricaoServicos = 'Eu só te ensino o caminho';

  /// Nome da porta dos aplicativos que a Memora pode abrir.
  static const String portaAplicativos = 'Meus aplicativos';

  /// O que essa porta faz.
  static const String descricaoAplicativos = 'Eu te ensino e posso abrir';

  /// Nome da porta de ajuda.
  static const String portaAjuda = 'Preciso de ajuda';

  /// O que essa porta faz.
  static const String descricaoAjuda = 'Dúvidas sobre o próprio Memora';

  /// Nome da porta do registro.
  static const String portaRegistro = 'O que eu fiz por você';

  /// O que essa porta faz.
  static const String descricaoRegistro = 'O que eu abri para você';

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

  /// O que o aviso diz **fechado**, numa linha (FR-022, FR-049, T118).
  ///
  /// É o que a maioria lê, então carrega o núcleo — "senha" e "código" — e
  /// contém o [tituloAvisoAntigolpe] por inteiro. Um portão confere os dois.
  static const String resumoAvisoAntigolpe =
      'Eu nunca peço sua senha nem código.';

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

  /// A pergunta que já vem escrita ao tocar num serviço do catálogo (T077).
  ///
  /// Pede para **ensinar**, e não para abrir, nas duas categorias: a Memora
  /// ensina antes de oferecer qualquer coisa (FR-014). Sem artigo antes do
  /// nome, para não errar o gênero de um serviço que ainda vai entrar.
  static String perguntaSobre(String servico) =>
      'Você me ensina a usar $servico?';

  /// Título do catálogo sem itens.
  static const String catalogoVazioTitulo = 'Ainda não tem nada aqui';

  /// Explicação do catálogo sem itens.
  ///
  /// Não promete "em breve" (H1): promessa sem data, para quem já tem medo de
  /// ter quebrado o aparelho, é o mesmo que porta que não abre. Aponta o que
  /// funciona hoje.
  static const String catalogoVazioExplicacao =
      'Mas você pode me perguntar sobre qualquer aplicativo na conversa 😊';

  // ---------------------------------------------------------------------------
  // Falhas
  // ---------------------------------------------------------------------------

  /// Sem conexão, nas telas em que a pessoa não escreveu nada.
  static const String semConexao =
      'Não consegui falar com a internet agora. Vamos tentar de novo?';

  /// A resposta não veio — sem internet, ou 30 s sem nenhuma palavra (FR-052).
  ///
  /// Diz que o problema é a conexão **e não a pessoa**: quem já tem medo de ter
  /// quebrado o aparelho conclui isso sozinho, se ninguém disser o contrário. E
  /// "o que você escreveu continua aqui" é verdade — o controlador devolve a
  /// pergunta ao campo, e o tentar de novo a reenvia.
  static const String semRespostaDaConversa =
      'A internet não me deixou responder agora — não foi nada que você fez. '
      'O que você escreveu continua aqui, é só tentar de novo.';

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

  /// O caminho que a Memora percorreu, mostrado depois de abrir (FR-019).
  ///
  /// A ação executada não pode terminar em silêncio. A FR-019 manda mostrar o
  /// caminho **depois**, e o motivo é o Princípio VII: se a pessoa só vê o
  /// resultado, ela aprendeu que a Memora resolve. Vendo o caminho, ela tem
  /// chance de reconhecê-lo da próxima vez.
  static String caminhoPercorrido(String aplicativo) =>
      'Pronto, abri o $aplicativo 😊 Olha o caminho que eu fiz, para você '
      'reconhecer da próxima vez: toquei no ícone dele na sua tela inicial. '
      'É só isso — quando quiser tentar, eu fico aqui do lado.';

  /// O aplicativo não estava instalado, ou não abriu.
  ///
  /// Não culpa a pessoa e não usa palavra técnica. "Não encontrei no seu
  /// celular" é o que aconteceu, dito do jeito que ela entende.
  static String naoConsegiAbrir(String aplicativo) =>
      'Não encontrei o $aplicativo no seu celular. Pode ser que ele não esteja '
      'instalado ainda — quer que eu te mostre como procurar na loja?';

  // ---------------------------------------------------------------------------
  // Registro — US4
  // ---------------------------------------------------------------------------

  /// O que esta tela é, dito antes da lista.
  ///
  /// Explica o **propósito** do registro, e não o seu funcionamento: a pessoa
  /// precisa saber que pode conferir, não que existe uma tabela imutável.
  static const String explicacaoDoRegistro =
      'Sempre que eu abrir alguma coisa no seu lugar, eu anoto aqui. Assim '
      'você pode conferir quando quiser 😊';

  /// Quando não há nada registrado.
  ///
  /// Lista vazia aqui é **boa notícia**, e o texto diz isso. Um "nada
  /// encontrado" faria a pessoa achar que perdeu alguma coisa.
  static const String registroVazio =
      'Ainda não precisei fazer nada no seu lugar. Continue assim que logo '
      'você não vai mais precisar de mim para isso 😊';

  /// O que foi feito, numa frase.
  static String oQueFoiFeito(String aplicativo, String pedido) =>
      pedido.isEmpty
          ? 'Abri o $aplicativo para você'
          : 'Abri o $aplicativo, porque você me pediu: "$pedido"';

  /// Quando aconteceu, do jeito que uma pessoa fala.
  ///
  /// Data por extenso, e não `dd/MM/yyyy HH:mm`: quem lê isto não está
  /// auditando um sistema, está lembrando de um dia.
  static String quandoAconteceu(DateTime momento) {
    const List<String> meses = <String>[
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
    ];
    final String hora = momento.hour.toString().padLeft(2, '0');
    final String minuto = momento.minute.toString().padLeft(2, '0');
    return '${momento.day} de ${meses[momento.month - 1]}, às ${hora}h$minuto';
  }
}
