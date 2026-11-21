/// Textos em português comum da tela e do analisador antigolpes.
///
/// Regras da `memora-ux` verificadas por `texto_da_interface_test.dart` e
/// `sem_planos_test.dart`:
/// - no máximo duas frases curtas por constante;
/// - nenhum emoji;
/// - nenhuma palavra proibida, jargão técnico ou menção a planos/assinaturas.
abstract final class TextosAntigolpe {
  /// Título da porta no Hub.
  static const String portaTitulo = 'Verificar golpe';

  /// Descrição curta da porta no Hub.
  static const String portaDescricao = 'Confira se um link ou mensagem é seguro';

  /// Título exibido na barra superior da tela.
  static const String titulo = 'Verificar golpe';

  /// Título do cartão de boas-vindas inicial.
  static const String conviteTitulo = 'Vamos conferir juntos';

  /// Explicação do cartão inicial.
  static const String conviteDescricao =
      'Cole aqui uma mensagem ou um link estranho. Eu olho os sinais com você.';

  /// Instrução da caixa de entrada.
  static const String etapaEntrada = 'Cole ou escreva o texto para analisar';

  /// Rótulo visível acima do campo de texto.
  static const String rotuloCampo = 'Mensagem ou link recebido';

  /// Texto de ajuda obrigatório do campo de texto.
  static const String ajudaCampo =
      'Toque em Colar ou digite o texto que você recebeu.';

  /// Rótulo do botão que lê a área de transferência.
  static const String botaoColar = 'Colar';

  /// Rótulo do botão que limpa o campo e o resultado.
  static const String botaoLimpar = 'Limpar';

  /// Rótulo do botão principal da tela.
  static const String botaoAnalisar = 'Analisar';

  /// Mensagem exibida durante a análise.
  static const String carregando = 'Analisando a mensagem com você...';

  /// Mensagem de validação quando o campo está vazio.
  static const String erroVazio =
      'Cole ou escreva uma mensagem ou link antes de analisar.';

  /// Mensagem de validação quando o texto passa do limite.
  static const String erroMuitoLongo =
      'Esse texto ficou longo demais. Cole só a parte principal.';

  /// Mensagem quando não há texto copiado para colar.
  static const String erroAreaTransferenciaVazia =
      'Não encontrei nenhum texto copiado no aparelho.';

  /// Mensagem genérica de erro inesperado.
  static const String erroInesperado =
      'Não consegui concluir a análise agora. Tente de novo em instantes.';

  /// Mensagem quando a sessão expirou durante uma chamada autenticada.
  static const String sessaoExpirada =
      'Por segurança, preciso que você entre de novo.';

  /// Botão de tentar novamente em caso de erro.
  static const String tentarNovamente = 'Tentar de novo';

  /// Badge exibido quando o resultado veio da IA no servidor.
  static const String origemServidorIa = 'Análise com inteligência artificial';

  /// Badge exibido quando o resultado veio do analisador local offline.
  static const String origemLocalOffline = 'Análise local sem internet';

  /// Aviso honesto quando o fallback offline foi acionado.
  static const String avisoOffline =
      'Sem conexão com o servidor agora. Fiz uma verificação local para te orientar.';

  /// Selo de risco baixo.
  static const String riscoSeguro = 'Sem sinais claros de golpe';

  /// Selo de risco médio.
  static const String riscoAtencao = 'Atenção: sinal suspeito';

  /// Selo de risco alto.
  static const String riscoAlto = 'Risco alto de golpe';

  /// Título da seção de sinais detectados.
  static const String tituloSinais = 'O que chamou atenção';

  /// Título da seção de orientações práticas.
  static const String tituloOrientacoes = 'O que fazer agora';

  /// Título do lembrete fixo de segurança.
  static const String dicaFixaTitulo = 'Lembrete de segurança';

  /// Texto do lembrete fixo de segurança.
  static const String dicaFixaTexto =
      'Eu nunca peço sua senha nem código de SMS. Na dúvida, confirme com alguém de confiança.';

  /// Título local quando nenhum sinal de golpe foi encontrado.
  static const String localSeguroTitulo = 'Não encontrei sinais de golpe';

  /// Explicação local quando o texto parece comum.
  static const String localSeguroExplicacao =
      'O texto não mostra pedidos urgentes de senha ou links perigosos. Mesmo assim, só abra links de quem você conhece.';

  /// Explicação local quando o endereço pertence a um domínio oficial conhecido.
  static const String localDominioOficialExplicacao =
      'O endereço pertence a um site oficial conhecido. Confira sempre se foi você quem pediu essa mensagem.';

  /// Título local para risco médio.
  static const String localAtencaoTitulo = 'Fique em alerta com esta mensagem';

  /// Explicação local para risco médio.
  static const String localAtencaoExplicacao =
      'Encontrei sinais comuns em tentativas de golpe. Não toque em links nem responda antes de confirmar.';

  /// Título local para risco alto.
  static const String localAltoRiscoTitulo =
      'Cuidado: parece tentativa de golpe';

  /// Explicação local para risco alto.
  static const String localAltoRiscoExplicacao =
      'Há vários sinais fortes de fraude neste texto. Não toque no link e não envie senha, código ou PIX.';
}
