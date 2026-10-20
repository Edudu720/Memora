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

  // WhatsApp (T071)
  /// Título do guia do WhatsApp.
  static const String tituloWhatsapp = 'Como mandar mensagem no WhatsApp';
  /// Passo 1 do WhatsApp.
  static const String whatsappPasso1 =
      'Toque no botão verde de nova conversa, embaixo, à direita da tela.';
  /// Descrição da captura do passo 1 do WhatsApp.
  static const String whatsappCaptura1 =
      'Tela principal do WhatsApp mostrando conversas e o botão verde de mensagem no canto inferior direito.';
  /// Passo 2 do WhatsApp.
  static const String whatsappPasso2 =
      'Toque no nome do contato com quem você quer conversar, no alto da lista.';
  /// Descrição da captura do passo 2 do WhatsApp.
  static const String whatsappCaptura2 =
      'Lista de contatos do WhatsApp com nomes e fotos.';
  /// Passo 3 do WhatsApp.
  static const String whatsappPasso3 =
      'Toque na barra branca de mensagem, embaixo, e digite o seu recado.';
  /// Descrição da captura do passo 3 do WhatsApp.
  static const String whatsappCaptura3 =
      'Tela de conversa do WhatsApp com o teclado aberto e a barra de digitação embaixo.';
  /// Passo 4 do WhatsApp.
  static const String whatsappPasso4 =
      'Toque no botão verde com uma setinha, embaixo, à direita, para enviar. Muito bem! Você enviou a sua mensagem.';
  /// Descrição da captura do passo 4 do WhatsApp.
  static const String whatsappCaptura4 =
      'Mensagem enviada na conversa com botão de envio à direita.';

  // Instagram (T071)
  /// Título do guia do Instagram.
  static const String tituloInstagram = 'Como ver fotos e vídeos no Instagram';
  /// Passo 1 do Instagram.
  static const String instagramPasso1 =
      'Toque no ícone de casinha, embaixo, à esquerda, para ir à tela inicial.';
  /// Descrição da captura do passo 1 do Instagram.
  static const String instagramCaptura1 =
      'Tela inicial do Instagram com o ícone de casinha selecionado embaixo à esquerda.';
  /// Passo 2 do Instagram.
  static const String instagramPasso2 =
      'Arraste o dedo de baixo para cima no meio da tela para ver as fotos e vídeos postados.';
  /// Descrição da captura do passo 2 do Instagram.
  static const String instagramCaptura2 =
      'Linha do tempo do Instagram com fotos e vídeos de amigos e perfis.';
  /// Passo 3 do Instagram.
  static const String instagramPasso3 =
      'Toque no desenho de coraçãozinho, logo abaixo da foto, para curtir o que você gostou.';
  /// Descrição da captura do passo 3 do Instagram.
  static const String instagramCaptura3 =
      'Publicação no Instagram com o ícone de coração para curtir abaixo da foto.';
  /// Passo 4 do Instagram.
  static const String instagramPasso4 =
      'Para ver os vídeos curtos, toque no ícone de vídeo, embaixo, no meio. Parabéns! Agora você já sabe acompanhar o Instagram.';
  /// Descrição da captura do passo 4 do Instagram.
  static const String instagramCaptura4 =
      'Aba de vídeos Reels com botão de reprodução no meio da barra inferior.';

  // YouTube (T071)
  /// Título do guia do YouTube.
  static const String tituloYoutube = 'Como assistir a vídeos no YouTube';
  /// Passo 1 do YouTube.
  static const String youtubePasso1 =
      'Toque na lupa de pesquisa, no alto, à direita da tela.';
  /// Descrição da captura do passo 1 do YouTube.
  static const String youtubeCaptura1 =
      'Tela inicial do YouTube mostrando vídeos recomendados e uma lupa no alto à direita.';
  /// Passo 2 do YouTube.
  static const String youtubePasso2 =
      'Digite o que você quer assistir na barra de pesquisa no alto e toque na lupa do teclado.';
  /// Descrição da captura do passo 2 do YouTube.
  static const String youtubeCaptura2 =
      'Barra de pesquisa do YouTube no alto com sugestões de vídeos.';
  /// Passo 3 do YouTube.
  static const String youtubePasso3 =
      'Toque na foto ou no título do vídeo escolhido na lista para começar a assistir.';
  /// Descrição da captura do passo 3 do YouTube.
  static const String youtubeCaptura3 =
      'Lista de resultados de busca com miniaturas e títulos de vídeos.';
  /// Passo 4 do YouTube.
  static const String youtubePasso4 =
      'Toque no meio do vídeo a qualquer momento para pausar ou continuar. Parabéns! Agora você assiste ao que quiser no YouTube.';
  /// Descrição da captura do passo 4 do YouTube.
  static const String youtubeCaptura4 =
      'Vídeo em reprodução no YouTube com os botões de pausar e tela cheia.';

  // Facebook (T072)
  /// Título do guia do Facebook.
  static const String tituloFacebook = 'Como ver publicações no Facebook';
  /// Passo 1 do Facebook.
  static const String facebookPasso1 =
      'Toque no ícone de casinha, no alto, à esquerda, para ver o feed de notícias.';
  /// Descrição da captura do passo 1 do Facebook.
  static const String facebookCaptura1 =
      'Tela principal do Facebook com o ícone da casinha azul no topo.';
  /// Passo 2 do Facebook.
  static const String facebookPasso2 =
      'Deslize o dedo de baixo para cima no meio da tela para ver as mensagens dos seus amigos.';
  /// Descrição da captura do passo 2 do Facebook.
  static const String facebookCaptura2 =
      'Publicações recentes de amigos e páginas com fotos e textos no Facebook.';
  /// Passo 3 do Facebook.
  static const String facebookPasso3 =
      'Toque no botão \'Curtir\' com a mãozinha, embaixo da publicação que gostar.';
  /// Descrição da captura do passo 3 do Facebook.
  static const String facebookCaptura3 =
      'Publicação com botões de curtir, comentar e compartilhar embaixo.';
  /// Passo 4 do Facebook.
  static const String facebookPasso4 =
      'Para ver seus amigos e avisos, toque no sino no alto, à direita. Pronto! Agora você sabe navegar no Facebook.';
  /// Descrição da captura do passo 4 do Facebook.
  static const String facebookCaptura4 =
      'Barra superior do Facebook destacando o ícone de sino de notificações.';

  // Google Fotos (T072)
  /// Título do guia do Google Fotos.
  static const String tituloGoogleFotos = 'Como rever suas fotos no Google Fotos';
  /// Passo 1 do Google Fotos.
  static const String googleFotosPasso1 =
      'Toque no botão \'Fotos\' com o catavento colorido, embaixo, à esquerda.';
  /// Descrição da captura do passo 1 do Google Fotos.
  static const String googleFotosCaptura1 =
      'Tela do Google Fotos com a aba Fotos selecionada na barra inferior.';
  /// Passo 2 do Google Fotos.
  static const String googleFotosPasso2 =
      'Deslize para cima para navegar pelos dias e meses e ver fotos antigas.';
  /// Descrição da captura do passo 2 do Google Fotos.
  static const String googleFotosCaptura2 =
      'Mosaico organizado por datas com miniaturas das fotos da pessoa.';
  /// Passo 3 do Google Fotos.
  static const String googleFotosPasso3 =
      'Toque em cima de qualquer foto para abrir ela grande na tela inteira.';
  /// Descrição da captura do passo 3 do Google Fotos.
  static const String googleFotosCaptura3 =
      'Foto aberta ocupando toda a tela com botões de compartilhar e editar embaixo.';
  /// Passo 4 do Google Fotos.
  static const String googleFotosPasso4 =
      'Toque na setinha no alto, à esquerda, para voltar à galeria. Parabéns! Suas lembranças estão sempre guardadas aqui.';
  /// Descrição da captura do passo 4 do Google Fotos.
  static const String googleFotosCaptura4 =
      'Foto em tela cheia com seta de voltar no canto superior esquerdo.';

  // Telegram (T072)
  /// Título do guia do Telegram.
  static const String tituloTelegram = 'Como conversar no Telegram';
  /// Passo 1 do Telegram.
  static const String telegramPasso1 =
      'Toque no ícone azul com lápis, embaixo, à direita, para iniciar uma conversa.';
  /// Descrição da captura do passo 1 do Telegram.
  static const String telegramCaptura1 =
      'Tela inicial do Telegram com a lista de canais e o botão redondo de lápis embaixo à direita.';
  /// Passo 2 do Telegram.
  static const String telegramPasso2 =
      'Toque no contato ou grupo com quem você quer falar na lista.';
  /// Descrição da captura do passo 2 do Telegram.
  static const String telegramCaptura2 =
      'Lista de contatos do Telegram com fotos de perfil e nomes.';
  /// Passo 3 do Telegram.
  static const String telegramPasso3 =
      'Escreva o seu texto na barra embaixo da tela onde diz \'Mensagem\'.';
  /// Descrição da captura do passo 3 do Telegram.
  static const String telegramCaptura3 =
      'Tela de chat com a barra de texto e ícones de anexo e microfone.';
  /// Passo 4 do Telegram.
  static const String telegramPasso4 =
      'Toque no aviãozinho azul, embaixo, à direita, para enviar. Parabéns! Você já pode trocar mensagens pelo Telegram.';
  /// Descrição da captura do passo 4 do Telegram.
  static const String telegramCaptura4 =
      'Conversa do Telegram com balão de mensagem e botão de envio com avião de papel.';
}
