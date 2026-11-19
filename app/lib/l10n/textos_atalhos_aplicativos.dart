/// Textos da tela dedicada de abertura direta para aplicativos (Feature 015).
///
/// Linguagem literal, curta e acolhedora, alinhada ao portão de textos da 013
/// (no máximo duas frases curtas, sem emojis e sem termos proibidos).
abstract final class TextosAtalhosAplicativos {
  /// Título principal da tela dedicada.
  static const String tituloTela = 'Abrir aplicativos';

  /// Título do botão no catálogo para entrar na tela de abertura direta.
  static const String botaoVerAtalhosDiretos = 'Abrir um aplicativo direto';

  /// Orientação curta exibida no topo da lista.
  static const String orientacaoTopo = 'Toque no aplicativo que você quer abrir.';

  /// Mensagem exibida durante a consulta inicial no servidor e no aparelho.
  static const String carregando = 'Verificando aplicativos no celular...';

  /// Mensagem de erro quando o servidor do catálogo não responde.
  static const String erroAoCarregar =
      'Não consegui buscar os aplicativos agora. Tente de novo em instantes.';

  /// Título do estado vazio quando nenhum aplicativo cotidiano está ativo.
  static const String vazioTitulo = 'Nenhum aplicativo liberado';

  /// Explicação do estado vazio sem prometer prazos.
  static const String vazioExplicacao =
      'No momento não há aplicativos disponíveis para abrir por aqui.';

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

  /// Aviso amigável na voz da Memora quando falha ao iniciar o aplicativo.
  static String erroAoAbrirAplicativo(String nomeAplicativo) =>
      'Não consegui abrir o $nomeAplicativo agora. Confira se ele está '
      'atualizado na loja.';

  /// Aviso amigável na voz da Memora quando a loja oficial não pode ser aberta.
  static String erroAoAbrirLoja(String nomeAplicativo) =>
      'Não consegui abrir a loja oficial para instalar o $nomeAplicativo agora.';
}
