/// Textos da autenticação, na voz da Memora (T054).
///
/// ## Por que as frases moram fora das telas
///
/// A persona é requisito, não enfeite. A FR-015 pede que a mensagem de bloqueio
/// seja **acolhedora**, **explique o motivo**, **diga quando** será possível
/// tentar de novo e **ofereça o caminho de recuperação** — quatro exigências que
/// não sobrevivem a serem reescritas tela a tela. O bloqueio é o momento de
/// maior frustração de todo o produto: é exatamente ali que um texto ríspido faz
/// a pessoa fechar o aplicativo e não voltar.
///
/// O teste `BloqueioProgressivoNoLoginTest`, no backend, provou que isso precisa
/// ser verificado à parte: com a mensagem trocada por *"Conta bloqueada: você
/// excedeu o número de tentativas"*, a escada de bloqueio **continuou passando**
/// e só os testes de texto reprovaram.
///
/// ## Por que não é `flutter_localizations`
///
/// A decisão D3 da feature 002 deixou idiomas fora de escopo, com a estrutura
/// preparada. Isto é a estrutura preparada: no dia em que houver um segundo
/// idioma, estas constantes viram entradas de `.arb` sem ninguém precisar caçar
/// frase solta dentro de widget.
///
/// ## O servidor manda o número, não a frase
///
/// O `429` traz `tentar_novamente_em_segundos`. A frase com o número dentro é
/// responsabilidade daqui — o servidor não conhece a voz da Memora.
abstract final class TextosAutenticacao {
  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------

  /// Título da tela de login.
  static const String tituloLogin = 'Entrar na minha conta';

  /// Convite no topo da tela.
  static const String conviteLogin =
      'Que bom te ver de novo! Preciso só de duas coisas.';

  /// Rótulo do campo de identificador.
  ///
  /// Não pergunta *qual dos dois* — quem decide pela presença do `@` é o
  /// servidor. Perguntar aqui devolveria à pessoa a dúvida que a FR-051 evita.
  static const String rotuloIdentificador = 'Seu e-mail ou telefone';

  /// Ajuda do campo de identificador.
  static const String ajudaIdentificador =
      'O e-mail ou telefone da sua conta';

  /// Rótulo do campo de senha.
  static const String rotuloSenha = 'Sua senha';

  /// Ajuda do campo de senha.
  static const String ajudaSenha = 'Sua frase ou senha cadastrada';

  /// Rótulo do botão que entra.
  static const String botaoEntrar = 'Entrar';

  /// Mensagem exibida enquanto o servidor responde.
  static const String entrando = 'Estou te reconhecendo...';

  /// Caminho para quem esqueceu a senha.
  static const String botaoRecuperar = 'Esqueci minha senha';

  /// Caminho para quem ainda não tem conta (FR-010, FR-011).
  static const String botaoPrimeiroAcesso = 'Primeiro acesso';

  /// Instrução da caixa de etapa de login (FR-002a, FR-010).
  static const String instrucaoEtapaLogin = 'Informe seus dados para entrar';

  /// Aviso de que o identificador veio preenchido do último acesso (FR-012).
  static const String identificadorLembrado =
      'Deixei preenchido do seu último acesso. Se não for você, é só apagar.';

  // ---------------------------------------------------------------------------
  // Recusas
  // ---------------------------------------------------------------------------

  /// Recusa de login.
  ///
  /// **Deliberadamente genérica** (FR-013): não diz se o problema foi o
  /// identificador ou a senha. Dizer "essa conta não existe" entregaria a um
  /// golpista a lista de quem tem conta no Memora, que é o insumo do ataque
  /// direcionado descrito na tabela de ameaças da spec.
  static const String credenciaisInvalidas =
      'Esses dados não conferem. Pode ser o e-mail ou a senha — vamos tentar '
      'de novo com calma?';

  /// Falha de rede.
  static const String semConexao =
      'Não consegui falar com a internet agora. O que você digitou continua '
      'aqui, é só tentar de novo.';

  /// Recusa por dados malformados.
  static const String dadosInvalidos =
      'Alguma informação não foi aceita. Pode conferir comigo?';

  /// Qualquer falha não prevista.
  static const String inesperada =
      'Algo não saiu como eu esperava. Vamos tentar mais uma vez?';

  // ---------------------------------------------------------------------------
  // Bloqueio — FR-015
  // ---------------------------------------------------------------------------

  /// A mensagem de bloqueio, com o motivo e o tempo de espera.
  ///
  /// As quatro exigências da FR-015, nesta ordem: acolhe sem culpar ("acontece
  /// com todo mundo"), explica **por que** existe a espera (não é castigo, é o
  /// que impede alguém de ficar adivinhando), diz **quanto** falta, e aponta a
  /// saída para quem simplesmente não lembra a senha.
  static String bloqueio(int segundos) =>
      'Acontece com todo mundo, fica tranquila. Como foram várias tentativas '
      'seguidas, vou dar uma pausa de ${esperaHumana(segundos)} — é isso que '
      'impede outra pessoa de ficar tentando adivinhar sua senha. '
      'Se você não lembra qual é, eu posso criar uma nova com você.';

  /// Contagem regressiva exibida durante a espera.
  ///
  /// Existe porque *"tente mais tarde"* obriga a pessoa a adivinhar quando. Ver
  /// o número diminuir é a diferença entre esperar e desistir.
  static String contagem(int segundos) {
    final int minutos = segundos ~/ 60;
    final String resto = (segundos % 60).toString().padLeft(2, '0');
    return 'Posso tentar de novo em $minutos:$resto';
  }

  /// Aviso de que a espera acabou.
  static const String bloqueioTerminou =
      'Pronto, já pode tentar de novo. Sem pressa.';

  /// Traduz segundos para o jeito que uma pessoa fala.
  ///
  /// A escada do servidor é 1, 5, 15 e 60 minutos. Escrever "3600 segundos"
  /// obrigaria a pessoa a fazer conta no pior momento possível.
  static String esperaHumana(int segundos) {
    if (segundos < 60) return 'alguns segundos';
    if (segundos < 120) return 'um minutinho';
    if (segundos < 3600) return '${segundos ~/ 60} minutos';
    if (segundos < 7200) return 'uma hora';
    return '${segundos ~/ 3600} horas';
  }

  // ---------------------------------------------------------------------------
  // Sessão — FR-017
  // ---------------------------------------------------------------------------

  /// Título do aviso de inatividade.
  static const String tituloAvisoInatividade = 'Você ainda está aí?';

  /// Corpo do aviso, com o tempo restante.
  ///
  /// Diz **por que** vai sair, para não parecer defeito: o celular esquecido em
  /// cima da mesa é a ameaça que a FR-017 existe para conter.
  static String avisoInatividade(int segundos) =>
      'Faz um tempinho que não vejo movimento. Daqui a ${esperaHumana(segundos)} '
      'eu vou fechar sua conta neste aparelho, para o caso de ele não estar '
      'mais com você. É só tocar aqui que eu continuo.';

  /// Rótulo do botão que mantém a sessão viva.
  static const String botaoContinuar = 'Estou aqui, pode continuar';

  /// Mensagem exibida quando a sessão já expirou.
  static const String sessaoExpirada =
      'Faz um tempinho que você não usa o Memora. Vamos entrar de novo?';

  // ---------------------------------------------------------------------------
  // Modo assistido — FR-058 a FR-064
  // ---------------------------------------------------------------------------

  /// Título da tela que devolve o aparelho (FR-059).
  static const String tituloEntregaDoAparelho = 'Agora é com você';

  /// O pedido em si.
  ///
  /// Fala com **quem está ajudando**, não com a pessoa dona da conta, porque é
  /// quem está com o aparelho na mão neste instante. Pedir de forma indireta
  /// — "a senha deve ser criada pelo titular" — seria lido como formalidade e
  /// ignorado.
  static const String pedidoEntregaDoAparelho =
      'A senha é a chave da conta, e ela precisa ser só de quem vai usar o '
      'Memora. Por favor, devolva o celular agora, antes deste próximo passo.';

  /// Explicação de por que isto não é desconfiança de quem ajuda.
  ///
  /// A FR-059 interrompe um gesto de cuidado, e sem explicação a interrupção
  /// soa como acusação. O texto agradece antes de pedir.
  static const String motivoEntregaDoAparelho =
      'Você ajudou até aqui, e isso fez toda a diferença. Só que ninguém além '
      'dela deve saber essa senha — nem eu sei, nem consigo mostrar depois.';

  /// Rótulo do botão que segue para a senha.
  static const String botaoAparelhoEntregue = 'Pronto, o celular está comigo';

  /// Rótulo do botão que interrompe o cadastro antes da senha.
  static const String botaoPrecisoDeAjudaComASenha = 'Prefiro fazer depois';

  /// Título da tela que confirma a posse do canal (FR-062).
  static const String tituloConfirmarCanal = 'Vamos confirmar que é você';

  /// Explicação do porquê da confirmação.
  ///
  /// Diz o que a confirmação **compra para a pessoa** — poder recuperar a
  /// conta —, e não o que ela protege contra, para não acusar quem ajudou.
  static String pedidoConfirmarCanal(String canal) =>
      'Enviei um número de 6 dígitos para $canal. Digite ele aqui para eu ter '
      'certeza de que esse contato é seu — é por ele que você vai recuperar '
      'sua conta se um dia esquecer a senha.';

  /// Rótulo do campo de código.
  static const String rotuloCodigo = 'O número que eu enviei';

  /// Rótulo do botão que confirma o código.
  static const String botaoConfirmarCodigo = 'Confirmar';

  /// Rótulo do botão que pede outro código.
  static const String botaoReenviarCodigo = 'Não recebi, envie outro';

  /// Mensagem de código recusado.
  ///
  /// Não distingue errado de vencido: é uma recusa só, como no servidor.
  static const String codigoNaoConfere =
      'Esse número não conferiu. Ele vale por 10 minutinhos — se já passou, eu '
      'posso te enviar outro.';

  /// Confirmação de que outro código foi enviado.
  static const String codigoReenviado =
      'Pronto, enviei um número novo. O anterior não vale mais.';

  /// Título da tela que conduz à primeira entrada sozinha (FR-063).
  static const String tituloPrimeiraEntrada = 'Sua conta está pronta';

  /// O convite para entrar sozinha.
  ///
  /// O objetivo da FR-063 é **autonomia demonstrada**: a pessoa precisa ver que
  /// consegue, uma vez, com o acompanhante ainda por perto para o caso de algo
  /// dar errado. Por isso o texto trata a entrada como um teste tranquilo, e
  /// não como uma última burocracia.
  static const String convitePrimeiraEntrada =
      'Agora vamos fazer juntos uma coisa importante: você vai entrar sozinha, '
      'uma vez, para ver que consegue. Se travar, quem está aí do lado pode '
      'ajudar — mas quem digita a senha é você.';

  /// Rótulo do botão que leva ao login.
  static const String botaoEntrarSozinha = 'Quero entrar sozinha';

  // ---------------------------------------------------------------------------
  // Recuperação de acesso — FR-018 a FR-023
  // ---------------------------------------------------------------------------

  /// Título da tela de recuperação.
  ///
  /// Fala do **resultado** — uma senha nova —, e não do problema. "Recuperação
  /// de acesso" é vocabulário de sistema; quem chega aqui só sabe que não
  /// consegue entrar.
  static const String tituloRecuperacao = 'Vamos criar uma senha nova';

  /// Convite da primeira etapa.
  static const String conviteRecuperacao =
      'Esquecer senha acontece com todo mundo, e tem conserto. Me diga o '
      'e-mail ou telefone da sua conta que eu envio um número para você.';

  /// Rótulo do botão que pede o código.
  static const String botaoPedirCodigo = 'Me envie o número';

  /// Mensagem exibida enquanto o pedido é enviado.
  static const String pedindoCodigo = 'Estou enviando...';

  /// Confirmação do pedido — **idêntica exista a conta ou não** (FR-019).
  ///
  /// Este texto é o portão de segurança desta tela. A FR-019 manda confirmar
  /// com mensagem idêntica independentemente de a conta existir, e é aqui que
  /// isso vive: o servidor responde `202` sempre justamente para o aplicativo
  /// poder dizer uma coisa só.
  ///
  /// O **"se"** não é hesitação, é a frase inteira. Trocá-lo por *"enviei um
  /// número para você"* transformaria esta tela num oráculo de quais e-mails
  /// têm conta no Memora — que é o insumo do ataque direcionado descrito na
  /// tabela de ameaças da spec.
  ///
  /// Repetir o identificador digitado é seguro: quem o lê é quem acabou de
  /// escrevê-lo, e ver o próprio e-mail na tela é o que denuncia o erro de
  /// digitação antes de a pessoa ficar dez minutos esperando um número que foi
  /// para o lugar errado.
  static String recuperacaoSolicitada(String identificador) =>
      'Se existir uma conta com $identificador, acabei de enviar um número de '
      '6 dígitos para lá. Ele vale por 10 minutinhos.';

  /// Rótulo do campo da senha nova.
  static const String rotuloSenhaNova = 'Sua senha nova';

  /// Ajuda do campo da senha nova.
  static const String ajudaSenhaNova =
      'Escolha uma que você lembre. Se quiser conferir, toque no olhinho';

  /// Rótulo do botão que conclui a troca.
  static const String botaoTrocarSenha = 'Salvar minha senha nova';

  /// Mensagem exibida enquanto a troca acontece.
  static const String trocandoSenha = 'Estou guardando sua senha nova...';

  /// Rótulo do botão que volta para pedir outro número.
  static const String botaoPedirOutroCodigo = 'Pedir outro número';

  /// Aviso de que a troca derruba as outras sessões (FR-021).
  ///
  /// A revogação é boa notícia contada na hora certa: quem chega aqui pode
  /// estar recuperando a conta **porque** alguém entrou nela. Dizer que os
  /// outros aparelhos saíram é o que transforma um efeito técnico em segurança
  /// percebida.
  static const String avisoSessoesEncerradas =
      'Sua senha nova já está valendo. Se o Memora estivesse aberto em outro '
      'aparelho, ele saiu da conta agora — só esta senha entra daqui em diante.';

  /// Título do aviso permanente contra golpe (FR-023).
  static const String tituloAvisoAntigolpe = 'Eu nunca peço sua senha';

  /// O aviso em si.
  ///
  /// A FR-023 exige aviso **permanente** de que o Memora nunca solicita senha
  /// por telefone, mensagem ou e-mail. O texto vai além e inclui o **número de
  /// 6 dígitos**, porque é ele que o golpe desta tela pede: o golpista dispara
  /// a recuperação com o e-mail da vítima, liga dizendo ser o suporte e pede
  /// "o código que acabou de chegar". Avisar só sobre a senha deixaria de fora
  /// exatamente o dado que está na tela.
  static const String avisoAntigolpe =
      'Nem eu, nem ninguém que diga trabalhar no Memora, vai te pedir sua '
      'senha ou esse número de 6 dígitos — nem por telefone, nem por mensagem, '
      'nem por e-mail. Se alguém pedir, é golpe: pode desligar sem responder.';

  /// Espera por excesso de tentativas **dentro da recuperação**.
  ///
  /// Não reaproveita [bloqueio] de propósito: aquele texto termina oferecendo
  /// criar uma senha nova, e quem lê este já está exatamente nisso. Mandar a
  /// pessoa para o caminho em que ela se encontra é o tipo de frase que faz
  /// alguém concluir que o aparelho travou.
  static String esperaNaRecuperacao(int segundos) =>
      'Foram várias tentativas seguidas, então preciso dar uma pausa de '
      '${esperaHumana(segundos)}. Não é nada que você fez de errado — é o que '
      'impede outra pessoa de ficar tentando adivinhar esse número.';

  /// Rótulo do botão que conclui a recuperação e entra na conta.
  ///
  /// Não reaproveita [botaoContinuar], que pertence ao aviso de inatividade e
  /// diz *"estou aqui, pode continuar"* — resposta a uma pergunta que ninguém
  /// fez nesta tela.
  static const String botaoEntrarComSenhaNova = 'Entrar na minha conta';

  // ---------------------------------------------------------------------------
  // Boas-vindas
  // ---------------------------------------------------------------------------

  /// Apresentação, ao lado do casal.
  ///
  /// Diz **o que o Memora é** antes de dizer o que ele faz. A tela anterior a
  /// esta é a loja de aplicativos, e quem chega aqui muitas vezes não escolheu
  /// instalar — foi um filho que instalou.
  ///
  /// Os asteriscos marcam os trechos realçados (ver `TextoComDestaque`).
  static const String apresentacao =
      '*Memora* — eu te ensino a usar o celular, no seu ritmo.';

  /// O que a pessoa vai aprender.
  ///
  /// Coisas concretas, e não "integração no mundo digital". Quem tem
  /// dificuldade com o aparelho não sabe o que essa expressão promete; sabe
  /// muito bem o que é *ver as fotos dos netos*.
  static const String oQueVouEnsinar =
      'Aqui você aprende a *mandar mensagem*, *ver as fotos* de quem você ama '
      'e *fazer chamada de vídeo* — uma coisa de cada vez, sem pressa nenhuma.';

  /// A promessa que separa o Memora de um assistente.
  ///
  /// O Princípio VII da Constituição é **ensinar, nunca substituir**, e é isto
  /// que a pessoa precisa entender antes de qualquer cadastro: o aplicativo
  /// mostra o caminho para que da próxima vez ela consiga sozinha.
  static const String promessa =
      'Eu mostro o caminho e *você faz*. E não faço nada sem te avisar '
      'antes.';

  /// Rótulo da única ação principal da tela.
  static const String botaoComecar = 'Começar minha jornada';

  /// Caminho discreto para quem já tem conta.
  static const String botaoJaTenhoConta = 'Já tenho uma conta';

  // --- Boas-vindas de volta (FR-009a, T117) --------------------------------

  /// Título na tela de volta para quem já usou o aplicativo neste aparelho.
  static const String tituloBoasVindasDeVolta =
      'Que bom te ver por aqui de novo!';

  /// Mensagem de boas-vindas de volta.
  static const String mensagemBoasVindasDeVolta =
      'Seu espaço continua pronto para você continuar aprendendo no seu ritmo.';

  /// Caminho secundário na tela de volta para começar com outra conta.
  static const String botaoCriarOutraConta = 'Criar outra conta';

  // --- Instruções das caixas de etapa do cadastro (FR-002a, FR-010) --------

  /// Instrução da caixa de ajuda/modo assistido.
  static const String instrucaoEtapaCadastroAjuda =
      'Tem alguém te ajudando agora?';

  /// Instrução da caixa de identificação.
  static const String instrucaoEtapaCadastroIdentificacao = 'Seu nome';

  /// Instrução da caixa de canal.
  static const String instrucaoEtapaCadastroCanal = 'Como você quer entrar?';

  /// Instrução da caixa de senha.
  static const String instrucaoEtapaCadastroSenha = 'Crie sua senha';

  /// Instrução antes de pedir o aparelho de volta.
  static const String instrucaoEtapaCadastroPedirAparelho =
      'Agora vamos criar a senha';

  // --- Sair da conta (US4, T075 e T076) ------------------------------------

  /// Título da tela de perfil.
  static const String tituloPerfil = 'Minha conta';

  /// Rótulo do botão que inicia a saída.
  ///
  /// "Sair da minha conta", e não "Sair" nem "Logout". Um "Sair" sozinho, numa
  /// tela cheia de opções, pode ser lido como *sair desta tela* — e a pessoa
  /// que quer voltar para o Hub tocaria nele achando que é um botão de voltar.
  static const String botaoSair = 'Sair da minha conta';

  /// A pergunta da confirmação (FR-025).
  static const String perguntaSair = 'Quer mesmo sair da sua conta?';

  /// O que a pessoa precisa saber antes de confirmar.
  ///
  /// Diz **o que vai acontecer depois**, e não o que ela está perdendo. "Você
  /// vai precisar da sua senha" é uma informação prática; "você perderá o
  /// acesso" soa como punição para quem só quer emprestar o telefone.
  static const String avisoSair =
      'Para entrar de novo, você vai precisar da sua senha. Seus dados '
      'continuam guardados, viu?';

  /// Confirmação da saída.
  static const String botaoConfirmarSaida = 'Sim, quero sair';

  /// Recusa da saída.
  ///
  /// "Não, quero ficar" em vez de "Cancelar": quem hesita diante de "Cancelar"
  /// precisa decidir o que exatamente está sendo cancelado — a saída ou a
  /// pergunta.
  static const String botaoFicar = 'Não, quero ficar';

  /// Enquanto a saída acontece.
  static const String saindo = 'Estou te desconectando...';
}
