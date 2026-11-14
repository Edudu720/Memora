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

  /// Leitor de tela: o anel de destaque sobre a captura.
  static const String areaDestacada = 'Área destacada na tela para tocar';

  /// Leitor de tela: o selo "Exemplo".
  static const String seloExemploDescrito =
      'Ilustração demonstrativa de exemplo';

  /// Botão visível logo abaixo da captura (FR-028b).
  static const String verImagemMaior = 'Ver a imagem maior';

  /// Dica do leitor de tela para a captura que se pode tocar (FR-028b).
  static const String dicaAmpliar = 'Toque duas vezes para ver a imagem maior';

  /// Botão que aumenta a imagem na ampliação (FR-028b).
  static const String aproximar = 'Aproximar';

  /// Botão que diminui a imagem na ampliação (FR-028b).
  static const String afastar = 'Afastar';

  /// Botão que fecha a ampliação (FR-028b).
  static const String fecharImagem = 'Fechar';

  /// Quanto a imagem está ampliada; também é o aviso do leitor de tela.
  ///
  /// [vezes] é 1 para a imagem inteira. Número com decimais quando a pessoa
  /// ampliou com os dois dedos e parou entre dois degraus.
  static String ampliadaVezes(double vezes) {
    if (vezes < 1.05) return 'Imagem inteira';
    final bool inteiro = (vezes - vezes.round()).abs() < 0.05;
    final String numero = inteiro
        ? vezes.round().toString()
        : vezes.toStringAsFixed(1).replaceAll('.', ',');
    return 'Ampliada $numero vezes';
  }

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
  static const String voltarAoHub = 'Voltar ao início';

  /// Convite no final do guia para tirar dúvidas com o chatbot (revisão WhatsApp).
  static const String ficouComDuvida = 'Ficou com alguma dúvida? Pode perguntar';

  /// Rascunho inicial na conversa quando a pessoa tira dúvida no final do guia.
  static String rascunhoDuvida(String aplicativo) =>
      'Tenho uma dúvida sobre o $aplicativo';

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

  /// Instrução da caixa de etapa para as ações de cada passo (FR-002a, T125c).
  static const String instrucaoAcoesPasso = 'Escolha como continuar:';

  /// Instrução da caixa de etapa na última etapa do guia (FR-002a, T125c).
  static const String instrucaoConclusao = 'O que você quer fazer agora?';

  // Seletor de seção dos guias extensos (FR-028d, T137)

  /// Pergunta da Memora no topo do seletor de seção. O nome do serviço vai em
  /// negrito (`**x**`, o balão sabe desenhar).
  static String perguntaDaSecao(String servico) =>
      'O que você quer aprender no **$servico**? Escolha uma das opções abaixo:';

  /// Quantos passos tem a seção: "1 passo", "5 passos".
  static String quantidadeDePassos(int quantidade) =>
      '$quantidade ${quantidade == 1 ? 'passo' : 'passos'}';

  /// Marca da seção cujo último passo a pessoa já alcançou.
  static String secaoJaAprendida(String contagem) =>
      '$contagem · Já aprendeu';

  /// Leitura do cartão de seção pelo leitor de tela.
  static String secaoDescrita(String titulo, String subtitulo, String meta) =>
      '$titulo. $subtitulo. $meta.';

  /// Saída do seletor para quem não achou o assunto: leva à conversa.
  ///
  /// Curto de propósito: o "não achei" já está na pergunta da Memora, logo
  /// acima, e o rótulo longo ocupava meia tela no aparelho pequeno a 200%.
  static const String naoAcheiOQueProcuro = 'Perguntar à Memora';

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

  // Instagram (T071; refeito na T135 com imagens recriadas por IA, em cinco
  // seções — ver a linha do Instagram no CAPTURAS.md)
  /// Título do guia do Instagram.
  static const String tituloInstagram = 'Como usar o Instagram';

  /// Seção "Ver fotos e vídeos" do Instagram.
  static const String instagramSecaoVer = 'Ver fotos e vídeos';
  /// O que se aprende na seção "Ver fotos e vídeos".
  static const String instagramSecaoVerSubtitulo =
      'Curtir as fotos, ver os stories e os Reels';
  /// Seção "Publicar um story" do Instagram.
  static const String instagramSecaoStory = 'Publicar um story';
  /// O que se aprende na seção "Publicar um story".
  static const String instagramSecaoStorySubtitulo =
      'Mostrar uma foto aos amigos por um dia';
  /// Seção "Avisos e mensagens" do Instagram.
  static const String instagramSecaoAvisos = 'Avisos e mensagens';
  /// O que se aprende na seção "Avisos e mensagens".
  static const String instagramSecaoAvisosSubtitulo =
      'Quem curtiu, quem quer seguir você e as conversas';
  /// Seção "Procurar pessoas" do Instagram.
  static const String instagramSecaoProcurar = 'Procurar pessoas';
  /// O que se aprende na seção "Procurar pessoas".
  static const String instagramSecaoProcurarSubtitulo =
      'Achar amigos, família e assuntos';
  /// Seção "Deixar a conta privada" do Instagram.
  static const String instagramSecaoPrivada = 'Deixar a conta privada';
  /// O que se aprende na seção "Deixar a conta privada".
  static const String instagramSecaoPrivadaSubtitulo =
      'Só quem você aceita vê as suas fotos';

  /// Ver, passo 1.
  static const String instagramVer1 =
      'Estas são as fotos dos seus amigos. Para curtir uma, toque no coração, embaixo da foto, à esquerda.';
  /// Ver, o story (1 de 2).
  static const String instagramVerStory1 =
      'As bolinhas no alto são os stories: fotos e vídeos que os amigos mostram por um dia. Toque numa delas para ver.';
  /// Ver, o story (2 de 2).
  static const String instagramVerStory2 =
      'O story passa sozinho. Para responder, toque em "Enviar mensagem", embaixo. Para sair, deslize o dedo para baixo.';
  /// Ver, passo 2.
  static const String instagramVer2 =
      'Para ver vídeos curtos, toque no segundo ícone de baixo, o dos Reels.';
  /// Ver, passo 3.
  static const String instagramVer3 =
      'Para ver o próximo vídeo, deslize o dedo para cima. Para curtir, toque no coração, à direita. Agora você sabe ver fotos e vídeos.';

  /// Story, passo 1.
  static const String instagramStory1 =
      'Toque na sua foto, no alto, à esquerda, onde está escrito "Seu story" e tem o sinal de mais.';
  /// Story, passo 2.
  static const String instagramStory2 =
      'Escolha a foto que quer mostrar: toque nela, em "Recentes".';
  /// Story, passo 3.
  static const String instagramStory3 =
      'Para todos os seus seguidores verem, toque em "Seu story", embaixo, à esquerda. A foto fica no ar por um dia. Agora você sabe publicar um story.';

  /// Avisos, passo 1.
  static const String instagramAvisos1 =
      'Para ver quem curtiu ou começou a seguir você, toque no coração, no alto, à direita.';
  /// Avisos, passo 2.
  static const String instagramAvisos2 =
      'Antes de tocar em "Seguir", confira se você conhece mesmo essa pessoa. Golpistas criam perfis com a foto e o nome de parentes.';
  /// Avisos, passo 3.
  static const String instagramAvisos3 =
      'Para ver as suas conversas, volte ao início e toque no aviãozinho de papel, embaixo, no meio.';
  /// Avisos, passo 4.
  static const String instagramAvisos4 =
      'Toque na conversa que você quer ler. Se alguém pedir dinheiro ou código por mensagem, ligue para a pessoa antes de fazer qualquer coisa. Agora você sabe ver avisos e mensagens.';

  /// Procurar, passo 1.
  static const String instagramProcurar1 =
      'Para procurar alguém, toque na lupa, embaixo, a segunda opção da direita.';
  /// Procurar, passo 2.
  static const String instagramProcurar2 =
      'Toque na barra de pesquisa, no alto, e escreva o nome da pessoa ou do assunto.';
  /// Procurar, passo 3.
  static const String instagramProcurar3 =
      'As pesquisas que você já fez aparecem aqui: toque num nome para abrir o perfil. Agora você sabe procurar pessoas.';

  /// Privada, passo 1.
  static const String instagramPrivada1 =
      'Toque na sua foto, embaixo, à direita, para abrir o seu perfil.';
  /// Privada, passo 2.
  static const String instagramPrivada2 =
      'No seu perfil, toque nas três linhas, no alto, à direita.';
  /// Privada, passo 3.
  static const String instagramPrivada3 =
      'Desça até "Privacidade da conta" e toque nela para deixar a conta privada. Assim, só quem você aceita vê as suas fotos, e um golpista não consegue copiá-las.';

  /// Descrição da captura 1 do Instagram.
  static const String instagramCaptura1 =
      'Início do Instagram com uma conta de exemplo: os stories no alto, uma foto com os botões de curtir, comentar e enviar, e embaixo as opções Início, Reels, Mensagens, Pesquisar e Perfil.';
  /// Descrição da captura 2 do Instagram.
  static const String instagramCaptura2 =
      'Um Reel de exemplo de receita de bolo, com os botões de curtir, comentar e compartilhar à direita.';
  /// Descrição da captura 3 do Instagram.
  static const String instagramCaptura3 =
      'Tela Adicionar ao story, com as fotos recentes do celular para escolher.';
  /// Descrição da captura 4 do Instagram.
  static const String instagramCaptura4 =
      'Tela de edição do story, com os botões Seu story e Amigos próximos embaixo.';
  /// Descrição da captura 5 do Instagram.
  static const String instagramCaptura5 =
      'Tela de Notificações com curtidas e sugestões de perfis para seguir.';
  /// Descrição da captura 6 do Instagram.
  static const String instagramCaptura6 =
      'Tela de Mensagens com a lista de conversas de exemplo.';
  /// Descrição da captura 7 do Instagram.
  static const String instagramCaptura7 =
      'Tela de pesquisa, com a barra Pesquisar no alto e fotos sugeridas.';
  /// Descrição da captura 8 do Instagram.
  static const String instagramCaptura8 =
      'Pesquisas recentes, com nomes de perfis de exemplo.';
  /// Descrição da captura 9 do Instagram.
  static const String instagramCaptura9 =
      'Perfil de exemplo, com o menu de três linhas no alto, à direita, e a lista Criar aberta embaixo.';
  /// Descrição da captura 10 do Instagram.
  static const String instagramCaptura10 =
      'Configurações e atividade, com a opção Privacidade da conta embaixo, marcada como Público.';
  /// Descrição da captura 11 do Instagram.
  static const String instagramCaptura11 =
      'Um story de exemplo de um amigo cuidando do jardim, com a capa de uma música e o campo Enviar mensagem embaixo.';

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

  // TikTok (T070)
  /// Título do guia do TikTok.
  static const String tituloTiktok = 'Como assistir e buscar vídeos no TikTok';
  /// Passo 1 do TikTok.
  static const String tiktokPasso1 =
      'Abra o TikTok. Você verá vídeos passando um após o outro na sua tela.';
  /// Descrição da captura do passo 1 do TikTok.
  static const String tiktokCaptura1 =
      'Tela principal do TikTok com um vídeo ocupando a tela inteira e opções de interação à direita.';
  /// Passo 2 do TikTok.
  static const String tiktokPasso2 =
      'Deslize o dedo de baixo para cima para trocar de vídeo e ver o próximo.';
  /// Descrição da captura do passo 2 do TikTok.
  static const String tiktokCaptura2 =
      'Gesto de deslizar o dedo na tela para avançar ao próximo vídeo.';
  /// Passo 3 do TikTok.
  static const String tiktokPasso3 =
      'Para procurar um assunto específico, toque na lupa de busca no canto superior.';
  /// Descrição da captura do passo 3 do TikTok.
  static const String tiktokCaptura3 =
      'Ícone de lupa no topo da tela para abrir o campo de busca.';
  /// Passo 4 do TikTok.
  static const String tiktokPasso4 =
      'Digite o que deseja encontrar (como receitas ou artesanato) e toque no vídeo que gostar.';
  /// Descrição da captura do passo 4 do TikTok.
  static const String tiktokCaptura4 =
      'Resultados de busca no TikTok organizados em lista de vídeos.';

  // Gov.br (T078)
  /// Título do guia do Gov.br.
  static const String tituloGovBr = 'Como acessar sua conta Gov.br';
  /// Passo 1 do Gov.br.
  static const String govBrPasso1 =
      'Toque no botão azul "Entrar com gov.br", no meio da tela.';
  /// Descrição da captura do passo 1 do Gov.br.
  static const String govBrCaptura1 =
      'Tela inicial do aplicativo Gov.br com o botão Entrar com gov.br em destaque.';
  /// Passo 2 do Gov.br.
  static const String govBrPasso2 =
      'Toque na caixa branca e digite os 11 números do seu CPF, sem pontos nem traço.';
  /// Descrição da captura do passo 2 do Gov.br.
  static const String govBrCaptura2 =
      'Tela de identificação do Gov.br com campo para digitação do CPF.';
  /// Passo 3 do Gov.br.
  static const String govBrPasso3 =
      'Toque no botão azul "Continuar", logo abaixo do campo de CPF.';
  /// Descrição da captura do passo 3 do Gov.br.
  static const String govBrCaptura3 =
      'Botão Continuar habilitado após a digitação do CPF.';
  /// Passo 4 do Gov.br.
  static const String govBrPasso4 =
      'Digite a sua senha no campo próprio. Lembre-se: sua senha só se digita no aplicativo oficial.';
  /// Descrição da captura do passo 4 do Gov.br.
  static const String govBrCaptura4 =
      'Tela oficial do Gov.br com o campo de senha vazio.';
  /// Passo 5 do Gov.br.
  static const String govBrPasso5 =
      'Toque no botão "Entrar". Parabéns! Você aprendeu a acessar sua conta oficial do governo com segurança.';
  /// Descrição da captura do passo 5 do Gov.br.
  static const String govBrCaptura5 =
      'Tela principal logada do Gov.br exibindo a carteira de documentos e serviços.';

  // Meu INSS (T079)
  /// Título do guia do Meu INSS.
  static const String tituloMeuInss = 'Como consultar benefícios no Meu INSS';
  /// Passo 1 do Meu INSS.
  static const String meuInssPasso1 =
      'Toque no botão azul "Entrar com gov.br", embaixo, para se conectar.';
  /// Descrição da captura do passo 1 do Meu INSS.
  static const String meuInssCaptura1 =
      'Tela inicial do Meu INSS com opção de acesso pelo Gov.br.';
  /// Passo 2 do Meu INSS.
  static const String meuInssPasso2 =
      'Digite seu CPF e senha da conta gov.br oficial na tela de acesso.';
  /// Descrição da captura do passo 2 do Meu INSS.
  static const String meuInssCaptura2 =
      'Tela oficial de login com campos de CPF e senha vazios.';
  /// Passo 3 do Meu INSS.
  static const String meuInssPasso3 =
      'Toque no cartão "Extrato de Benefício", no alto da tela inicial.';
  /// Descrição da captura do passo 3 do Meu INSS.
  static const String meuInssCaptura3 =
      'Painel do Meu INSS mostrando os atalhos de extrato e agendamentos.';
  /// Passo 4 do Meu INSS.
  static const String meuInssPasso4 =
      'Veja o extrato com o valor e a data do seu benefício. Parabéns! Você já sabe conferir seu benefício.';
  /// Descrição da captura do passo 4 do Meu INSS.
  static const String meuInssCaptura4 =
      'Demonstrativo detalhado do benefício no Meu INSS.';

  // e-Título (T081; refeito em 2026-11-12 com as capturas reais: entrar com a
  // biometria e um passeio pelas abas)
  /// Título do guia do e-Título.
  static const String tituloETitulo = 'Como usar o e-Título';
  /// Passo 1 do e-Título.
  static const String eTituloPasso1 =
      'Abra o e-Título e toque no botão laranja "Entrar com biometria", embaixo, para entrar com a sua digital.';
  /// Descrição da captura do passo 1 do e-Título.
  static const String eTituloCaptura1 =
      'Tela de entrada do e-Título, com uma foto de exemplo, a opção Biometria ligada e o botão laranja Entrar com biometria embaixo.';
  /// Passo 2 do e-Título.
  static const String eTituloPasso2 =
      'Pronto, você entrou. Este é o seu título de eleitor no celular. Para saber onde você vota, toque em "Onde votar", embaixo, a segunda opção da esquerda.';
  /// Descrição da captura do passo 2 do e-Título.
  static const String eTituloCaptura2 =
      'Tela principal do e-Título com um título de eleitor de exemplo: foto, nome, número, zona e seção. Embaixo, as opções e-Título, Onde votar, Notificações e Mais opções.';
  /// Passo 3 do e-Título.
  static const String eTituloPasso3 =
      'Aqui aparecem o lugar onde você vota, a seção e a zona. Para tirar uma dúvida sobre as eleições, toque em "ChatVote", embaixo, no meio.';
  /// Descrição da captura do passo 3 do e-Título.
  static const String eTituloCaptura3 =
      'Tela Onde votar do e-Título, com um mapa e um cartão com a seção, a zona e uma escola de exemplo como local de votação.';
  /// Passo 4 do e-Título.
  static const String eTituloPasso4 =
      'No ChatVote você escreve a sua dúvida no campo de baixo e toca na seta amarela para enviar. Para ver os avisos da Justiça Eleitoral, toque em "Notificações", embaixo, a segunda opção da direita.';
  /// Descrição da captura do passo 4 do e-Título.
  static const String eTituloCaptura4 =
      'Tela do ChatVote do e-Título, com a mensagem de boas-vindas, o campo Digite a sua mensagem e o botão amarelo de enviar embaixo.';
  /// Passo 5 do e-Título.
  static const String eTituloPasso5 =
      'Aqui chegam os avisos da Justiça Eleitoral. Para ver tudo o que o e-Título faz, toque em "Mais opções", embaixo, à direita.';
  /// Descrição da captura do passo 5 do e-Título.
  static const String eTituloCaptura5 =
      'Tela de Notificações do e-Título com quatro avisos da Justiça Eleitoral.';
  /// Passo 6 do e-Título.
  static const String eTituloPasso6 =
      'Em "Mais opções" ficam as certidões, a justificativa de ausência e "Consultar Situação Eleitoral", que mostra se o seu título está em dia. Agora você já sabe entrar e andar pelo e-Título.';
  /// Descrição da captura do passo 6 do e-Título.
  static const String eTituloCaptura6 =
      'Tela Mais opções do e-Título, com as certidões, a consulta da situação eleitoral, a justificativa de ausência e a impressão do título.';

  // Serasa (T081)
  /// Título do guia do Serasa.
  static const String tituloSerasa = 'Como consultar seu CPF no Serasa';
  /// Passo 1 do Serasa.
  static const String serasaPasso1 =
      'Abra o aplicativo e toque no botão "Entrar", embaixo na tela.';
  /// Descrição da captura do passo 1 do Serasa.
  static const String serasaCaptura1 =
      'Tela inicial do aplicativo Serasa com destaque para o botão de acesso.';
  /// Passo 2 do Serasa.
  static const String serasaPasso2 =
      'Digite seu CPF e a senha da sua conta Serasa no campo protegido.';
  /// Descrição da captura do passo 2 do Serasa.
  static const String serasaCaptura2 =
      'Tela oficial de autenticação da Serasa com campo de senha vazio.';
  /// Passo 3 do Serasa.
  static const String serasaPasso3 =
      'Toque em "Meu CPF" no menu inferior para consultar sua pontuação.';
  /// Descrição da captura do passo 3 do Serasa.
  static const String serasaCaptura3 =
      'Tela principal do Serasa destacando o menu Meu CPF.';
  /// Passo 4 do Serasa.
  static const String serasaPasso4 =
      'Confira sua pontuação de score e pendências financeiras. Parabéns! Agora você acompanha sua situação financeira com segurança.';
  /// Descrição da captura do passo 4 do Serasa.
  static const String serasaCaptura4 =
      'Painel do Serasa Score mostrando a pontuação e status de pendências.';

  // FGTS (T081; refeito na T138 com as capturas reais, em quatro seções)
  /// Título do guia do FGTS.
  static const String tituloFgts = 'Como usar o aplicativo do FGTS';

  /// Seção "Entrar no aplicativo" do FGTS.
  static const String fgtsSecaoEntrar = 'Entrar no aplicativo';
  /// O que se aprende na seção "Entrar no aplicativo".
  static const String fgtsSecaoEntrarSubtitulo =
      'O primeiro acesso, com o seu CPF';
  /// Seção "Ver o saldo e pedir um saque" do FGTS.
  static const String fgtsSecaoSaque = 'Ver o saldo e pedir um saque';
  /// O que se aprende na seção "Ver o saldo e pedir um saque".
  static const String fgtsSecaoSaqueSubtitulo =
      'Quanto você tem e onde pedir o saque';
  /// Seção "Conta bancária para receber" do FGTS.
  static const String fgtsSecaoConta = 'Conta bancária para receber';
  /// O que se aprende na seção "Conta bancária para receber".
  static const String fgtsSecaoContaSubtitulo =
      'A conta que recebe o dinheiro do seu FGTS';
  /// Seção "Saque-Aniversário" do FGTS.
  static const String fgtsSecaoAniversario = 'Saque-Aniversário';
  /// O que se aprende na seção "Saque-Aniversário".
  static const String fgtsSecaoAniversarioSubtitulo =
      'O que é e o que muda se você optar';

  /// Entrar, passo 1.
  static const String fgtsEntrar1 =
      'Abra o aplicativo do FGTS e toque no botão laranja "Entrar no aplicativo", embaixo.';
  /// Entrar, passo 2.
  static const String fgtsEntrar2 =
      'Toque no campo "CPF", digite os números do seu CPF e toque em "Próximo", logo abaixo. Na tela seguinte, a Caixa pede a sua senha: ela só se digita ali, no aplicativo oficial.';
  /// Entrar, passo 3.
  static const String fgtsEntrar3 =
      'Leia os termos com calma. Depois, marque "Li e aceito os termos e condições", embaixo, e toque em "Continuar".';
  /// Entrar, passo 4.
  static const String fgtsEntrar4 =
      'O aplicativo pergunta como você quer ser chamado. Se quiser, escreva no campo; se não, toque em "Pular", embaixo.';
  /// Entrar, passo 5.
  static const String fgtsEntrar5 =
      'Para receber os avisos do FGTS, toque em "Ativar notificações". Se preferir não receber, toque em "Agora não". Pronto: você já sabe entrar no aplicativo do FGTS.';

  /// Saldo e saque, passo 1.
  static const String fgtsSaque1 =
      'Esta é a página principal. Para ver quanto você tem, toque em "Toque para exibir o saldo", no alto. Quem estiver perto também vê: olhe o saldo num lugar tranquilo.';
  /// Saldo e saque, passo 2.
  static const String fgtsSaque2 =
      'Para pedir um saque, toque em "Saques", embaixo, a segunda opção da esquerda.';
  /// Saldo e saque, passo 3.
  static const String fgtsSaque3 =
      'Toque em "Solicitar saque", a primeira opção da lista.';
  /// Saldo e saque, passo 4.
  static const String fgtsSaque4 =
      'Escolha o motivo do seu saque, como doença grave ou calamidade pública: cada um diz as condições e os documentos. Agora você sabe ver o saldo e onde pedir um saque.';

  /// Conta bancária, passo 1.
  static const String fgtsConta1 =
      'Para cuidar da conta que recebe o dinheiro do FGTS, toque em "Meus dados", embaixo, a segunda opção da direita.';
  /// Conta bancária, passo 2.
  static const String fgtsConta2 =
      'Toque em "Conta bancária", a terceira opção da lista.';
  /// Conta bancária, passo 3.
  static const String fgtsConta3 =
      'Aqui aparece a conta cadastrada, e "Alterar conta bancária" troca a conta. Se alguém ligar pedindo para você trocar a conta, é golpe: só você troca, aqui, no aplicativo oficial. Agora você sabe onde fica a sua conta.';

  /// Saque-Aniversário, passo 1.
  static const String fgtsAniversario1 =
      'Para conhecer o Saque-Aniversário, toque em "Mais", embaixo, à direita.';
  /// Saque-Aniversário, passo 2.
  static const String fgtsAniversario2 =
      'Toque em "Sistemática de saque", a segunda opção da lista.';
  /// Saque-Aniversário, passo 3.
  static const String fgtsAniversario3 =
      'Antes de decidir, leia com calma "O que muda se eu fizer a opção?". Quem opta pelo Saque-Aniversário e perde o emprego recebe só a multa, e não o saldo todo. Agora você sabe onde fica e o que muda.';

  /// Descrição da captura 1 do FGTS.
  static const String fgtsCaptura1 =
      'Tela de boas-vindas do aplicativo do FGTS, com o botão laranja Entrar no aplicativo.';
  /// Descrição da captura 2 do FGTS.
  static const String fgtsCaptura2 =
      'Tela de entrada da Caixa com o campo CPF vazio e o botão Próximo.';
  /// Descrição da captura 3 do FGTS.
  static const String fgtsCaptura3 =
      'Termos e condições do aplicativo do FGTS, com a opção Li e aceito os termos e o botão Continuar, embaixo.';
  /// Descrição da captura 4 do FGTS.
  static const String fgtsCaptura4 =
      'Tela Vamos começar, que pergunta como você quer ser chamado, com os botões Cadastrar nome e continuar e Pular.';
  /// Descrição da captura 5 do FGTS.
  static const String fgtsCaptura5 =
      'Tela Fique por dentro de tudo, com os botões Ativar notificações e Agora não.';
  /// Descrição da captura 6 do FGTS.
  static const String fgtsCaptura6 =
      'Página principal do FGTS, com o saldo escondido, os atalhos e, embaixo, as opções Principal, Saques, Meus dados e Mais.';
  /// Descrição da captura 7 do FGTS.
  static const String fgtsCaptura7 =
      'Tela Saques, com as opções Solicitar saque e Acompanhar saques.';
  /// Descrição da captura 8 do FGTS.
  static const String fgtsCaptura8 =
      'Tela Selecione o motivo do saque, com doença grave, falecimento do trabalhador, calamidade pública e aposentadoria.';
  /// Descrição da captura 9 do FGTS.
  static const String fgtsCaptura9 =
      'Tela Meus dados, com Perfil, Notificações do FGTS, Conta bancária e Termos e condições.';
  /// Descrição da captura 10 do FGTS.
  static const String fgtsCaptura10 =
      'Tela Minha conta bancária de exemplo, sem dados de conta, com os botões Alterar conta bancária e Excluir conta bancária.';
  /// Descrição da captura 11 do FGTS.
  static const String fgtsCaptura11 =
      'Tela Mais, com Informações úteis, Sistemática de saque, Empréstimos contratados e outras opções.';
  /// Descrição da captura 12 do FGTS.
  static const String fgtsCaptura12 =
      'Tela Optar pelo Saque-Aniversário, com a explicação e o quadro O que muda se eu fizer a opção.';

  // Poupatempo (T081)
  /// Título do guia do Poupatempo.
  static const String tituloPoupatempo = 'Como agendar serviços no Poupatempo';
  /// Passo 1 do Poupatempo.
  static const String poupatempoPasso1 =
      'Toque no botão "Entrar com gov.br" no alto da tela inicial.';
  /// Descrição da captura do passo 1 do Poupatempo.
  static const String poupatempoCaptura1 =
      'Tela inicial do Poupatempo SP com opção de acesso pelo Gov.br.';
  /// Passo 2 do Poupatempo.
  static const String poupatempoPasso2 =
      'Informe seu CPF e senha da conta gov.br no ambiente oficial.';
  /// Descrição da captura do passo 2 do Poupatempo.
  static const String poupatempoCaptura2 =
      'Ambiente oficial de identificação com campo de senha vazio.';
  /// Passo 3 do Poupatempo.
  static const String poupatempoPasso3 =
      'Toque em "Serviços" e escolha o documento que precisa agendar.';
  /// Descrição da captura do passo 3 do Poupatempo.
  static const String poupatempoCaptura3 =
      'Lista de serviços disponíveis para agendamento no Poupatempo.';
  /// Passo 4 do Poupatempo.
  static const String poupatempoPasso4 =
      'Escolha o dia, horário e posto de atendimento mais próximo. Parabéns! Seu agendamento está concluído.';
  /// Descrição da captura do passo 4 do Poupatempo.
  static const String poupatempoCaptura4 =
      'Confirmação do agendamento com data, hora e endereço do posto Poupatempo.';

  // Carteira Digital (T082)
  /// Título do guia da Carteira Digital.
  static const String tituloCarteiraDigital = 'Como acessar seus documentos na Carteira Digital';
  /// Passo 1 da Carteira Digital.
  static const String carteiraDigitalPasso1 =
      'Toque no botão "Entrar com gov.br" na tela principal.';
  /// Descrição da captura do passo 1 da Carteira Digital.
  static const String carteiraDigitalCaptura1 =
      'Tela de abertura da Carteira Digital com botão de conexão gov.br.';
  /// Passo 2 da Carteira Digital.
  static const String carteiraDigitalPasso2 =
      'Digite o seu CPF e senha da conta gov.br no ambiente oficial protegido.';
  /// Descrição da captura do passo 2 da Carteira Digital.
  static const String carteiraDigitalCaptura2 =
      'Tela de autenticação unificada do governo com campo de senha protegido e vazio.';
  /// Passo 3 da Carteira Digital.
  static const String carteiraDigitalPasso3 =
      'Toque na aba "Documentos" no menu inferior para ver sua lista.';
  /// Descrição da captura do passo 3 da Carteira Digital.
  static const String carteiraDigitalCaptura3 =
      'Aba Documentos exibindo miniaturas de RG e certidões cadastradas.';
  /// Passo 4 da Carteira Digital.
  static const String carteiraDigitalPasso4 =
      'Toque no documento para abrir em tamanho legível. Parabéns! Seus documentos oficiais estão sempre seguros com você.';
  /// Descrição da captura do passo 4 da Carteira Digital.
  static const String carteiraDigitalCaptura4 =
      'Documento digital oficial aberto com dados legíveis e código de autenticidade.';

  // Correios (T082)
  /// Título do guia dos Correios.
  static const String tituloCorreios = 'Como rastrear encomendas nos Correios';
  /// Passo 1 dos Correios.
  static const String correiosPasso1 =
      'Toque na barra "Rastrear encomendas", no topo da tela inicial.';
  /// Descrição da captura do passo 1 dos Correios.
  static const String correiosCaptura1 =
      'Tela principal do aplicativo Correios destacando o campo de rastreamento.';
  /// Passo 2 dos Correios.
  static const String correiosPasso2 =
      'Digite o código da sua encomenda de 13 letras e números.';
  /// Descrição da captura do passo 2 dos Correios.
  static const String correiosCaptura2 =
      'Teclado ativo digitando código de rastreamento no padrão dos Correios.';
  /// Passo 3 dos Correios.
  static const String correiosPasso3 =
      'Caso queira receber alertas, entre com seu login e senha do idCorreios.';
  /// Descrição da captura do passo 3 dos Correios.
  static const String correiosCaptura3 =
      'Tela opcional de acesso idCorreios com campo de senha vazio.';
  /// Passo 4 dos Correios.
  static const String correiosPasso4 =
      'Veja onde seu pacote está e a previsão de entrega. Parabéns! Agora você sabe rastrear qualquer entrega dos Correios.';
  /// Descrição da captura do passo 4 dos Correios.
  static const String correiosCaptura4 =
      'Histórico de rastreamento com cidades por onde o pacote passou e data prevista.';

  // Carteira de Trabalho Digital (T082)
  /// Título do guia da Carteira de Trabalho Digital.
  static const String tituloCarteiraDeTrabalho = 'Como acessar a Carteira de Trabalho Digital';
  /// Passo 1 da Carteira de Trabalho Digital.
  static const String carteiraDeTrabalhoPasso1 =
      'Toque no botão azul "Entrar com gov.br" no meio da tela.';
  /// Descrição da captura do passo 1 da Carteira de Trabalho Digital.
  static const String carteiraDeTrabalhoCaptura1 =
      'Tela de apresentação da Carteira de Trabalho Digital com botão de acesso.';
  /// Passo 2 da Carteira de Trabalho Digital.
  static const String carteiraDeTrabalhoPasso2 =
      'Digite o seu CPF e a senha oficial da sua conta gov.br.';
  /// Descrição da captura do passo 2 da Carteira de Trabalho Digital.
  static const String carteiraDeTrabalhoCaptura2 =
      'Tela oficial de autenticação com campos de CPF e senha vazios.';
  /// Passo 3 da Carteira de Trabalho Digital.
  static const String carteiraDeTrabalhoPasso3 =
      'Toque na aba "Contratos", embaixo, para ver seus registros de emprego.';
  /// Descrição da captura do passo 3 da Carteira de Trabalho Digital.
  static const String carteiraDeTrabalhoCaptura3 =
      'Menu Contratos mostrando a lista de empregos anteriores e atuais.';
  /// Passo 4 da Carteira de Trabalho Digital.
  static const String carteiraDeTrabalhoPasso4 =
      'Confira as datas de admissão, cargo e anotações da empresa. Parabéns! Seu histórico de trabalho está sempre acessível.';
  /// Descrição da captura do passo 4 da Carteira de Trabalho Digital.
  static const String carteiraDeTrabalhoCaptura4 =
      'Detalhes de um contrato de trabalho com data de admissão e salário anotados.';
}
