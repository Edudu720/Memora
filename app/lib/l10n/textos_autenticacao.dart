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
      'O mesmo que você usou para criar a conta';

  /// Rótulo do campo de senha.
  static const String rotuloSenha = 'Sua senha';

  /// Ajuda do campo de senha.
  static const String ajudaSenha = 'Se quiser conferir, toque no olhinho';

  /// Rótulo do botão que entra.
  static const String botaoEntrar = 'Entrar';

  /// Mensagem exibida enquanto o servidor responde.
  static const String entrando = 'Estou te reconhecendo...';

  /// Caminho para quem esqueceu a senha.
  static const String botaoRecuperar = 'Esqueci minha senha';

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
}
