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

  /// Mensagem exibida quando o limite de análises por período é atingido.
  static const String erroLimiteAnalises =
      'Você fez muitas análises em pouco tempo. Aguarde alguns minutos e tente de novo.';

  /// Mensagem quando a sessão expirou durante uma chamada autenticada.
  static const String sessaoExpirada =
      'Por segurança, preciso que você entre de novo.';

  /// Botão de tentar novamente em caso de erro.
  static const String tentarNovamente = 'Tentar de novo';

  /// Badge exibido quando o resultado veio da IA no servidor.
  static const String origemServidorIa = 'Análise com inteligência artificial';

  /// Badge exibido quando o resultado veio das regras automáticas do servidor.
  static const String origemServidorRegras = 'Análise automática de segurança';

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

  /// Sinal quando o link usa endereço numérico em vez de domínio.
  static const String sinalIp =
      'O link aponta para um número de endereço, algo comum em golpes.';

  /// Sinal quando o link usa `@` ou barra invertida para disfarçar a autoridade.
  static const String sinalArroba =
      'O link usa "@" para disfarçar o endereço verdadeiro do site.';

  /// Sinal quando o domínio usa codificação punycode (`xn--`).
  static const String sinalPunycode =
      'O endereço do site usa caracteres especiais disfarçados.';

  /// Sinal quando o domínio mistura letras de outro alfabeto (homógrafo).
  static const String sinalHomografo =
      'O endereço do site mistura letras parecidas de outro alfabeto para imitar um nome conhecido.';

  /// Sinal quando o link usa encurtador de URL.
  static const String sinalEncurtador =
      'O link é encurtado e esconde o endereço final da página.';

  /// Sinal quando o domínio termina em extensão incomum de alto abuso.
  static const String sinalTldSuspeito =
      'O site usa uma terminação incomum para serviços oficiais.';

  /// Sinal quando o texto ou endereço imita marca conhecida fora do site oficial.
  static const String sinalMarcaFalsa =
      'Cita marca ou órgão conhecido junto com um endereço fora do site oficial.';

  /// Sinal quando há pressão de tempo, ameaça ou bloqueio.
  static const String sinalUrgencia =
      'Usa tom de pressa, ameaça ou bloqueio para apressar sua decisão.';

  /// Sinal quando há pedido de senha, código, PIX ou transferência.
  static const String sinalCredencialOuDinheiro =
      'Pede senha, código de verificação, dados pessoais ou transferência.';

  /// Sinal quando há promessa de prêmio, sorteio ou dinheiro fácil.
  static const String sinalPremio =
      'Promete prêmio, brinde ou dinheiro fácil para chamar atenção.';

  /// Sinal quando há tentativa de levar a conversa para outro telefone ou suporte.
  static const String sinalRedirecionamento =
      'Pede para ligar ou chamar em outro número diante de um suposto problema.';

  /// Sinal quando o link não usa conexão segura com cadeado.
  static const String sinalHttpSemProtecao =
      'O link usa conexão sem cadeado de proteção.';

  /// Sinal quando pede instalação de arquivo externo ou aplicativo de acesso remoto.
  static const String sinalAcessoRemotoOuApk =
      'Pede para instalar programa fora da loja oficial ou liberar controle remoto do celular.';

  /// Sinal quando usa a história de troca de número para pedir dinheiro.
  static const String sinalTrocaDeNumero =
      'Diz que trocou de número para pedir dinheiro ou favor com pressa.';

  /// Primeira orientação para resultado seguro.
  static const String orientacaoSeguro1 =
      'Continue confirmando quem enviou antes de responder.';

  /// Segunda orientação para resultado seguro.
  static const String orientacaoSeguro2 =
      'Nunca compartilhe senhas ou códigos recebidos por mensagem.';

  /// Terceira orientação para resultado seguro.
  static const String orientacaoSeguro3 =
      'Se ainda tiver dúvida, confira pelo canal oficial do serviço.';

  /// Primeira orientação para resultado de atenção.
  static const String orientacaoAtencao1 =
      'Não toque em links antes de confirmar quem enviou.';

  /// Segunda orientação para resultado de atenção.
  static const String orientacaoAtencao2 =
      'Não informe senha, código de verificação nem dados pessoais.';

  /// Terceira orientação para resultado de atenção.
  static const String orientacaoAtencao3 =
      'Confira no aplicativo oficial do serviço ou fale com alguém de confiança.';

  /// Primeira orientação para resultado de alto risco.
  static const String orientacaoAltoRisco1 =
      'Não toque em nenhum link nem responda esta mensagem.';

  /// Segunda orientação para resultado de alto risco.
  static const String orientacaoAltoRisco2 =
      'Nunca envie senha, código de 6 dígitos, foto de documento ou PIX.';

  /// Terceira orientação para resultado de alto risco.
  static const String orientacaoAltoRisco3 =
      'Apague ou bloqueie o remetente e confirme pelo telefone oficial do cartão.';
}
