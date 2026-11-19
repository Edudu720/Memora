/// Textos do Botão SOS Persistente (Feature 014).
///
/// Escritos na voz da Memora e dentro dos limites da skill `memora-ux`:
/// no máximo duas frases curtas por bloco, sem emojis e sem afirmar que o
/// contato recebeu a mensagem sem confirmação real do destinatário (BR-007).
abstract final class TextosSos {
  /// O que a bolinha do SOS mostra escrito, e só isso: sem ícone e sem
  /// "Ajuda" (decisão do Henrique, 2026-11-18).
  static const String textoDaBolinha = 'SOS';

  /// O nome do botão para o leitor de tela. Começa pela palavra escrita na
  /// bolinha ([textoDaBolinha]), como pede a WCAG 2.5.3.
  static const String rotuloBotaoSos = 'SOS Ajuda';

  /// Descrição acessível anunciada pelo leitor de tela.
  static const String semanticaBotaoSos =
      'Botão de emergência SOS Ajuda. Abre a confirmação para avisar seu contato.';

  /// Título do modal antes da confirmação.
  static const String tituloConfirmacao = 'Pedir ajuda agora?';

  /// Explicação simples antes de enviar o alerta manual.
  static const String mensagemConfirmacao =
      'Vou avisar o seu contato de emergência agora. Você só confirma se estiver '
      'precisando de ajuda.';

  /// Orientação quando não há contato de emergência cadastrado.
  static const String mensagemSemContatoConfirmacao =
      'Você ainda não cadastrou um contato de emergência no Dispositivo de '
      'Cuidado. Posso te mostrar outras opções de ajuda agora.';

  /// Rótulo indicando quem receberá o pedido.
  static const String contatoIdentificado = 'Contato que será avisado:';

  /// Orientação transparente quando o contato ainda não possui e-mail para entrega remota.
  static const String avisoContatoSemEmail =
      'Contato sem e-mail para aviso pela internet. Se não enviar, avise pelo celular.';

  /// Opção de compartilhar localização quando o aparelho já tiver permissão.
  static const String incluirLocalizacaoRotulo =
      'Compartilhar sua localização neste pedido';

  /// Estado quando a localização está autorizada para acompanhar o pedido.
  static const String localizacaoAutorizada =
      'Sua localização aproximada vai junto para facilitar a ajuda.';

  /// Estado quando não há autorização de localização.
  static const String localizacaoNaoAutorizada =
      'Sem permissão de localização — o pedido vai mesmo assim.';

  /// Botão explícito de confirmação.
  static const String botaoConfirmarSos = 'Sim, pedir ajuda agora';

  /// Botão explícito de cancelamento antes do envio.
  static const String botaoCancelarSos = 'Não, cancelar pedido';

  /// Título enquanto o envio está em andamento.
  static const String tituloProcessando = 'Enviando pedido de ajuda';

  /// Aviso durante o processamento.
  static const String mensagemProcessando =
      'Estou encaminhando seu pedido agora. Aguarde só um instante.';

  /// Título após envio técnico aceito pelo servidor.
  static const String tituloEnviado = 'Pedido encaminhado';

  /// Feedback verdadeiro após aceite do servidor (BR-007, NFR-008).
  static const String mensagemEnviado =
      'Sua solicitação foi encaminhada pelo sistema, mas isso não confirma que o '
      'contato já leu. Se precisar de socorro urgente, ligue agora.';

  /// Título quando o aparelho está sem conexão de rede (FR-011).
  static const String tituloFalhaConexao = 'Sem internet no momento';

  /// Orientação alternativa quando falta internet (FR-016).
  static const String mensagemFalhaConexao =
      'Não consegui avisar pela internet agora. Você pode acionar seu contato '
      'pelo celular ou ligar para o 192.';

  /// Título quando o servidor não conseguiu entregar ao destinatário.
  static const String tituloFalhaEntrega = 'Não foi possível avisar pelo servidor';

  /// Orientação alternativa quando a notificação remota falha (FR-016).
  static const String mensagemFalhaEntrega =
      'Não consegui entregar o aviso para o seu contato agora. Tente falar '
      'direto com ele ou ligue para o 192.';

  /// Ação alternativa via WhatsApp/SMS/Discador local do aparelho.
  static const String botaoAcionarPeloAparelho = 'Avisar contato pelo celular';

  /// Ação explícita para ligar para o serviço público de urgência médica (BR-008).
  static const String botaoLigar192 = 'Ligar para o 192 (SAMU)';

  /// Botão para fechar o diálogo após concluir ou cancelar.
  static const String botaoFecharSos = 'Fechar';

  /// Aviso de transparência sobre serviços públicos de emergência (BR-008).
  static const String orientacaoEmergenciaPublica =
      'O Memora não substitui o atendimento público. Em urgência médica, ligue '
      'para o 192.';
}
