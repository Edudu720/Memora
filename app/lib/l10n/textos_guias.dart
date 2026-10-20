/// Textos dos passo a passo de aplicativos e serviços (US4 e US5, T070 em
/// diante). Cada guia escreve aqui as frases dos seus passos; a estrutura do
/// guia mora em `features/aprendizado/data/guias/`.
///
/// Criado na fundação da feature 004 (T005), estruturado para nenhum texto
/// nascer solto dentro de um widget.
abstract final class TextosGuias {
  /// Rótulo curto: "Passo 2 de 4".
  static String passo(int atual, int total) => 'Passo $atual de $total';

  /// Rótulo para o leitor de tela: "Passo a passo, passo 2 de 4".
  static String passoDescrito(int atual, int total) =>
      'Passo a passo, passo $atual de $total';

  /// Selo visual obrigatório da captura (FR-028).
  static const String exemplo = 'Exemplo';

  /// Selo de captura pendente (FR-028a).
  static const String capturaPendente = 'Exemplo em preparação';

  /// Mensagem de carregamento da captura.
  static const String capturaCarregando = 'Carregando exemplo...';

  /// Mensagem de falha ao carregar captura.
  static const String capturaFalhou =
      'Não foi possível carregar a imagem de exemplo.';

  /// Título do aviso quando a etapa tem campo de senha (FR-032).
  static const String tituloAvisoSenha = 'Atenção com a sua senha';

  /// Mensagem do aviso quando a etapa tem campo de senha (FR-032, FR-049).
  static const String avisoSenha =
      'A sua senha só se digita no aplicativo oficial, nunca no Memora.';

  /// Ação em todo passo quando a tela real diverge do guia (FR-026).
  static const String telaDiferente = 'A minha tela está diferente';

  /// Mensagem de alerta exibida primeiro, sem internet, quando a tela diverge (FR-026).
  static const String avisoTelaDiferente =
      'Se a sua tela estiver diferente e pedindo senhas, códigos ou dados pessoais, '
      'cuidado: pode ser um golpe. Nunca informe seus dados se não tiver certeza.';

  /// Botão para conversar com a Memora após o aviso de tela diferente.
  static const String conversarSobreDiferenca =
      'Quero conversar com a Memora sobre isso';

  /// Ação para avançar na etapa.
  static const String continuar = 'Continuar';

  /// Ação para retornar à etapa anterior.
  static const String voltar = 'Voltar';

  /// Ação de saída do guia.
  static const String sairDoGuia = 'Sair do passo a passo';

  /// Ação de conclusão no último passo.
  static const String voltarAoHub = 'Voltar ao Hub';

  /// Ação permitida apenas para cotidiano com catálogo do servidor (FR-027).
  static const String pecaParaAbrir = 'Peça à Memora para abrir';

  /// Pedido que vai no rascunho da conversa ao pedir para a Memora abrir (FR-027).
  static String pedidoParaAbrir(String aplicativo) =>
      'Você pode abrir o $aplicativo para mim?';

  /// Instrução exibida como primeiro passo quando o aplicativo não está instalado (revisão #47).
  static String baixarNaLojaOficial(String aplicativo) =>
      'Antes de começar, instale o $aplicativo pela loja oficial do celular (Play Store). '
      'Nunca instale por links enviados em mensagens.';

  /// Descrição da captura do passo de baixar na loja oficial.
  static const String descricaoBaixarNaLojaOficial =
      'Instrução para instalar o aplicativo pela loja oficial Play Store';

  /// Título de celebração no último passo.
  static const String parabens = 'Parabéns!';
}
