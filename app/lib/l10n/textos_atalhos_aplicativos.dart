/// Textos da tela de atalhos diretos para aplicativos (Feature 015).
///
/// Linguagem literal, curta e acolhedora, sem termos técnicos como "App",
/// "Hub" ou "Chatbot" (FR-008) e livre de promessas ou cobranças (US9).
abstract final class TextosAtalhosAplicativos {
  /// Título principal da tela.
  static const String tituloTela = 'Abrir aplicativos';

  /// Título exibido na porta do catálogo completo.
  static const String portaAtalhos = 'Abrir aplicativos';

  /// Descrição curta na porta do catálogo completo.
  static const String descricaoPorta = 'Entre direto no aplicativo que quiser';

  /// Orientação curta exibida no topo da lista.
  static const String orientacaoTopo =
      'Toque no aplicativo que você deseja usar. Não precisa de passo a passo.';

  /// Mensagem exibida durante a checagem inicial dos aplicativos instalados.
  static const String carregando = 'Verificando aplicativos no celular...';

  /// Rótulo do selo quando o aplicativo foi encontrado no dispositivo.
  static const String statusInstalado = 'Instalado — Toque para abrir';

  /// Rótulo do selo quando o aplicativo ainda não está no dispositivo.
  static const String statusNaoInstalado = 'Não instalado — Toque para baixar';

  /// Título do diálogo de confirmação antes de abrir um aplicativo instalado.
  static String tituloConfirmarAbertura(String nomeAplicativo) =>
      'Abrir o $nomeAplicativo?';

  /// Explicação clara de saída do Memora e retorno pelo botão voltar.
  static String mensagemConfirmarAbertura(String nomeAplicativo) =>
      'Você vai sair do Memora e entrar no $nomeAplicativo. Para voltar depois, '
      'basta tocar no botão voltar do celular.';

  /// Rótulo do botão primário de confirmação de abertura.
  static const String botaoConfirmarAbertura = 'Sim, abrir agora';

  /// Rótulo do botão de cancelamento da abertura.
  static const String botaoCancelarAbertura = 'Não, continuar no Memora';

  /// Título do diálogo de orientação para instalar um aplicativo ausente.
  static String tituloConfirmarInstalacao(String nomeAplicativo) =>
      'Instalar o $nomeAplicativo?';

  /// Explicação de abertura segura na loja oficial Google Play Store.
  static String mensagemConfirmarInstalacao(String nomeAplicativo) =>
      'O $nomeAplicativo ainda não está no seu celular. Deseja abrir a loja '
      'oficial Google Play Store para instalá-lo?';

  /// Rótulo do botão primário de ida para a Google Play Store.
  static const String botaoConfirmarInstalacao = 'Ir para a Play Store';

  /// Rótulo do botão de recusa no diálogo de instalação.
  static const String botaoCancelarInstalacao = 'Agora não';

  /// Aviso amigável quando o sistema falha em iniciar o aplicativo escolhido.
  static String erroAoAbrirAplicativo(String nomeAplicativo) =>
      'Não foi possível abrir o $nomeAplicativo. Verifique se o aplicativo '
      'está atualizado.';

  /// Aviso amigável quando a loja oficial não pode ser aberta no aparelho.
  static String erroAoAbrirLoja(String nomeAplicativo) =>
      'Não foi possível abrir a loja oficial para instalar o $nomeAplicativo.';
}
