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

  /// Rótulo quando o aplicativo cotidiano não está instalado no aparelho (T089).
  static const String soEnsinaNaoInstalado =
      'Eu te ensino (não instalado no celular)';

  /// Aviso calmo na conversa quando a ação autorizada aponta para app ausente (T089).
  static String naoInstaladoAntesDeAbrir(String nome) =>
      'Olhei aqui e o $nome não está instalado neste celular, então não dá '
      'para abrir para você agora. Posso continuar te explicando passo a passo '
      'ou mostrar onde baixar na loja oficial!';

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

  /// Convite da primeira mensagem (FR-013, T084).
  ///
  /// Deixa claro que a Memora é um programa de computador, sem repetir o aviso.
  static const String convite =
      'Eu sou a Memora, um programa de computador para te ajudar. '
      'Pode me perguntar do jeito que você fala — não tem pergunta boba.';

  /// Rótulo da ação de recomeçar a conversa (T085, FR-050).
  static const String rotuloRecomecar = 'Recomeçar conversa';

  /// Título do diálogo que confirma o recomeço (T085, FR-050).
  static const String tituloRecomecar = 'Apagar e recomeçar?';

  /// Explicação do que acontece ao recomeçar a conversa.
  static const String explicacaoRecomecar =
      'As mensagens desta conversa serão apagadas deste aparelho e '
      'começaremos uma nova conversa do início.';

  /// Botão de confirmação de recomeço.
  static const String botaoConfirmarRecomeco = 'Sim, recomeçar';

  /// Botão que cancela o recomeço.
  static const String botaoCancelarRecomeco = 'Continuar conversa';

  /// Rótulo do campo de mensagem.
  static const String rotuloMensagem = 'Escreva aqui sua pergunta';

  /// Ajuda do campo de mensagem.
  static const String ajudaMensagem =
      'Por exemplo: como vejo as fotos do meu neto';

  /// Rótulo do botão de enviar.
  static const String botaoEnviar = 'Perguntar';

  /// Rótulo do botão para iniciar o ditado por voz no rascunho (FR-013).
  static const String botaoFalar = 'Falar';

  /// Rótulo do botão para encerrar o ditado por voz em andamento (FR-013).
  static const String botaoPararDitado = 'Parar';

  /// Rótulo semântico completo do botão de microfone parado.
  static const String dicaFalar = 'Ditar pergunta usando a voz';

  /// Rótulo semântico completo do botão de microfone ouvindo.
  static const String dicaPararDitado = 'Parar ditado por voz';

  /// Indicação visível e falada enquanto o microfone está capturando fala.
  static const String avisoOuvindoVoz =
      'Estou te ouvindo… fale a sua pergunta e toque em Parar quando terminar.';

  /// Título do diálogo prévio que explica a permissão de microfone.
  static const String tituloPermissaoVoz = 'Usar o microfone para escrever';

  /// Explicação em português simples antes de pedir a permissão ao sistema.
  static const String explicacaoPermissaoVoz =
      'Para transformar o que você fala em texto aqui na caixa de pergunta, '
      'precisamos ligar o microfone. Nada fica gravado e nada é enviado '
      'sozinho: você confere o texto e só envia quando tocar em Perguntar.';

  /// Botão que confirma a explicação e autoriza o pedido ao aparelho.
  static const String botaoConfirmarPermissaoVoz = 'Entendi, usar microfone';

  /// Botão que fecha a explicação sem ligar o microfone.
  static const String botaoRecusarPermissaoVoz = 'Prefiro digitar';

  /// Fallback amigável quando o ditado é negado ou não suportado.
  static const String vozIndisponivel =
      'O microfone não pôde ser usado agora, mas você pode digitar sua '
      'pergunta pelo teclado.';

  /// Orientação acolhedora quando o pacote de voz offline em português falta
  /// ou o aparelho recusa o reconhecimento estritamente local (FR-005).
  static const String vozOfflineIndisponivel =
      'O ditado por voz neste celular não está disponível agora, mas você pode '
      'digitar sua pergunta pelo teclado.';

  /// Mensagem amigável quando o reconhecimento falha momentaneamente.
  static const String vozErro =
      'Não consegui entender o que foi falado desta vez. Tente novamente ou '
      'escreva pelo teclado.';

  /// Título da grade 2x2 de sugestões na recepção da conversa.
  static const String tituloSugestoesConversa = 'Exemplos do que perguntar';

  /// Primeira sugestão rápida na recepção da conversa.
  static const String sugestaoLetraMaior = 'Como aumento a letra?';

  /// Segunda sugestão rápida na recepção da conversa.
  static const String sugestaoFotos = 'Como ver fotos da família?';

  /// Terceira sugestão rápida na recepção da conversa.
  static const String sugestaoGolpe = 'Este aviso no celular é golpe?';

  /// Quarta sugestão rápida na recepção da conversa.
  static const String sugestaoWhatsapp = 'Como mandar áudio no WhatsApp?';

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

  /// Título do aviso de privacidade (FR-051), junto ao antigolpe.
  static const String tituloAvisoPrivacidade = 'Não escreva dados pessoais aqui';

  /// O aviso de privacidade.
  ///
  /// Diz **para onde** o texto vai e **o que não escrever**: os quatro tipos
  /// (senha, documento, endereço, saúde e dinheiro) são o que a FR-051 lista, e
  /// há teste que reprova se algum sumir. Ele não promete sigilo — o serviço de
  /// fora é do nível gratuito, e a ADR-002 registra por quê.
  static const String avisoPrivacidade =
      'Para eu te responder, o que você escreve vai para um serviço de fora do '
      'Memora, e pessoas de lá podem ler. Não escreva senha, documento, '
      'endereço, nem nada sobre sua saúde ou seu dinheiro.';

  /// O que o **escudo** diz ao leitor de tela, depois da primeira pergunta
  /// (FR-022 e FR-049 da 004, T130; FR-033 e FR-051 da 003).
  ///
  /// Não está escrito na tela — fechado, o aviso é só o escudo —, é o rótulo
  /// dele. Carrega o núcleo dos dois avisos inteiros: **senha** e **código**,
  /// do golpe, e **dados pessoais**, da privacidade — e contém o
  /// [tituloAvisoAntigolpe] por inteiro, como o portão da T118 exige.
  ///
  /// Para onde o texto vai ("um serviço de fora") fica no aviso aberto e na
  /// explicação do aceite, que a pessoa lê antes da primeira pergunta.
  static const String resumoDosAvisos =
      '$resumoAvisoAntigolpe Não escreva dados pessoais.';

  /// Os dois avisos inteiros, na mesma caixa: o do golpe e o de privacidade.
  static const String avisosInteiros =
      '$avisoAntigolpe\n\n$tituloAvisoPrivacidade. $avisoPrivacidade';

  // ---------------------------------------------------------------------------
  // O consentimento antes da primeira mensagem — FR-051
  // ---------------------------------------------------------------------------

  /// Título da explicação que antecede a primeira mensagem.
  static const String tituloAceite = 'Antes de conversarmos';

  /// A explicação, em linguagem comum.
  ///
  /// Diz as quatro coisas que a FR-051 exige que a pessoa saiba antes de
  /// escrever: o texto sai do Memora, vai para o Google, pode ser usado para
  /// melhorar os programas dele e pode ser lido por gente. E o que não
  /// escrever.
  static const String corpoDoAceite =
      'O que você escrever aqui vai para um serviço do Google, fora do Memora, '
      'que pode usar a conversa para melhorar e pessoas de lá podem lê-la. '
      'Por isso, nunca escreva senha, documento, endereço, nem nada sobre '
      'sua saúde ou seu dinheiro.';

  /// Aceita. Diz o que acontece, e não "OK".
  static const String botaoAceitar = 'Entendi, vamos conversar';

  /// Recusa. Quem recusa segue com o resto do Memora, só sem a conversa.
  static const String botaoRecusarAceite = 'Agora não';

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
      'Viu? Foi você quem fez, e da próxima vez vai ser mais fácil.';

  // ---------------------------------------------------------------------------
  // Catálogo — US5
  // ---------------------------------------------------------------------------

  /// Explicação de por que a Memora não abre serviço sensível (FR-042).
  ///
  /// Diz o que a recusa **compra para a pessoa**, e não o que ela proíbe. A
  /// FR-041 é uma proteção, e precisa ser lida como tal — senão soa como
  /// limitação do produto.
  static const String porqueNaoAbroServicoSensivel =
      'Esse eu te ensino, mas não abro: se eu abrisse banco e governo, '
      'alguém poderia ligar fingindo ser do suporte e pedir a mesma coisa. '
      'Assim você fica mais segura.';

  /// A pergunta que já vem escrita ao tocar num serviço do catálogo (T077).
  ///
  /// Pede para **ensinar**, e não para abrir, nas duas categorias: a Memora
  /// ensina antes de oferecer qualquer coisa (FR-014). Sem artigo antes do
  /// nome, para não errar o gênero de um serviço que ainda vai entrar.
  static String perguntaSobre(String servico) =>
      'Você me ensina a usar $servico?';

  /// Título do catálogo sem itens.
  static const String catalogoVazioTitulo = 'Ainda não tem nada aqui';

  /// Mensagem de carregamento do catálogo (FR-006).
  static const String carregandoCatalogo = 'Carregando opções...';

  /// Rótulo do campo de busca de aplicativos (FR-023).
  static const String rotuloBuscaAplicativos = 'Buscar aplicativo';

  /// Ajuda do campo de busca de aplicativos (FR-023).
  static const String ajudaBuscaAplicativos =
      'Digite o nome do aplicativo para filtrar a lista';

  /// Explicação do catálogo sem itens.
  ///
  /// Não promete "em breve" (H1): promessa sem data, para quem já tem medo de
  /// ter quebrado o aparelho, é o mesmo que porta que não abre. Aponta o que
  /// funciona hoje.
  static const String catalogoVazioExplicacao =
      'Mas você pode me perguntar sobre qualquer aplicativo na conversa.';

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
      'Conversamos bastante hoje — vamos continuar amanhã? Eu estarei aqui.';

  /// O serviço que gera as respostas está fora do ar, sem cota ou não
  /// respondeu no prazo (FR-057).
  ///
  /// Mesma frase que o servidor usa. A dificuldade é **da Memora**, e o texto
  /// diz isso; e promete só "daqui a pouco", que é verdade para falha passageira
  /// — o limite do dia, que volta amanhã, tem texto próprio.
  static const String assistenteIndisponivel =
      'Estou com um pouquinho de dificuldade para pensar agora — não foi nada '
      'que você fez. Vamos tentar de novo daqui a pouco?';

  /// A sessão caiu — a renovação em silêncio foi recusada (T108, T111).
  ///
  /// Quem chega aqui estava **usando** o Memora, então a frase de antes ("faz
  /// um tempinho que você não usa") era errada. E ela é breve de propósito: o
  /// fluxo já está levando a pessoa à entrada.
  static const String sessaoExpirada =
      'Por segurança, preciso que você entre de novo.';

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
      'Pronto, abri o $aplicativo, tocando no ícone dele na sua tela inicial '
      'para você reconhecer da próxima vez. Quando quiser tentar sozinha, eu '
      'fico aqui do lado.';

  /// O aplicativo não estava instalado, ou não abriu.
  ///
  /// Não culpa a pessoa e não usa palavra técnica. "Não encontrei no seu
  /// celular" é o que aconteceu, dito do jeito que ela entende.
  static String naoConsegiAbrir(String aplicativo) =>
      'Não encontrei o $aplicativo no seu celular. Pode ser que ele não esteja '
      'instalado ainda — quer que eu te mostre como procurar na loja?';

  /// O aplicativo abriu, mas o registro da ação não chegou ao servidor (T112).
  ///
  /// Conta a verdade sem culpar a pessoa e sem palavra técnica: o que ela fez
  /// funcionou, e o que não funcionou foi a anotação da Memora.
  static String naoAnoteiNoRegistro(String aplicativo) =>
      'Abri o $aplicativo, mas não consegui anotar isso no seu Registro. '
      'Não foi nada que você fez — pode usar o aplicativo com calma.';

  // ---------------------------------------------------------------------------
  // Registro — US4
  // ---------------------------------------------------------------------------

  /// O que esta tela é, dito antes da lista.
  ///
  /// Explica o **propósito** do registro, e não o seu funcionamento: a pessoa
  /// precisa saber que pode conferir, não que existe uma tabela imutável.
  static const String explicacaoDoRegistro =
      'Sempre que eu abrir alguma coisa no seu lugar, eu anoto aqui. Assim '
      'você pode conferir quando quiser.';

  /// Quando não há nada registrado.
  ///
  /// Lista vazia aqui é **boa notícia**, e o texto diz isso. Um "nada
  /// encontrado" faria a pessoa achar que perdeu alguma coisa.
  static const String registroVazio =
      'Ainda não precisei fazer nada no seu lugar. Continue assim que logo '
      'você não vai mais precisar de mim para isso.';

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
