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

  // e-Título (T081)
  /// Título do guia do e-Título.
  static const String tituloETitulo = 'Como acessar seu título no e-Título';
  /// Passo 1 do e-Título.
  static const String eTituloPasso1 =
      'Abra o aplicativo e toque no botão azul "Entrar", no meio da tela.';
  /// Descrição da captura do passo 1 do e-Título.
  static const String eTituloCaptura1 =
      'Tela de boas-vindas do aplicativo oficial e-Título com botão Entrar.';
  /// Passo 2 do e-Título.
  static const String eTituloPasso2 =
      'Digite os números do seu CPF ou Título de Eleitor no primeiro campo.';
  /// Descrição da captura do passo 2 do e-Título.
  static const String eTituloCaptura2 =
      'Tela de identificação com campo de CPF ou Título de Eleitor.';
  /// Passo 3 do e-Título.
  static const String eTituloPasso3 =
      'Digite a sua senha cadastrada no e-Título. Lembre-se: digite apenas no aplicativo oficial.';
  /// Descrição da captura do passo 3 do e-Título.
  static const String eTituloCaptura3 =
      'Tela de autenticação do e-Título com campo de senha vazio.';
  /// Passo 4 do e-Título.
  static const String eTituloPasso4 =
      'Veja o seu documento digital com sua foto e local de votação. Parabéns! Seu título está na palma da mão.';
  /// Descrição da captura do passo 4 do e-Título.
  static const String eTituloCaptura4 =
      'Tela do título eleitoral digital exibindo dados eleitorais e QR Code de validação.';

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

  // FGTS (T081)
  /// Título do guia do FGTS.
  static const String tituloFgts = 'Como consultar o saldo do FGTS';
  /// Passo 1 do FGTS.
  static const String fgtsPasso1 =
      'Toque no botão laranja "Entrar no aplicativo", no meio da tela.';
  /// Descrição da captura do passo 1 do FGTS.
  static const String fgtsCaptura1 =
      'Tela de boas-vindas do FGTS da Caixa com o botão Entrar no aplicativo.';
  /// Passo 2 do FGTS.
  static const String fgtsPasso2 =
      'Digite o seu CPF e toque em "Próximo" para avançar.';
  /// Descrição da captura do passo 2 do FGTS.
  static const String fgtsCaptura2 =
      'Tela de identificação por CPF do aplicativo FGTS.';
  /// Passo 3 do FGTS.
  static const String fgtsPasso3 =
      'Digite sua senha numérica da Caixa no teclado seguro do aplicativo oficial.';
  /// Descrição da captura do passo 3 do FGTS.
  static const String fgtsCaptura3 =
      'Tela de senha da Caixa Econômica Federal com campos de senha vazios.';
  /// Passo 4 do FGTS.
  static const String fgtsPasso4 =
      'Veja na tela o saldo total de suas contas de FGTS. Parabéns! Você já sabe conferir seus depósitos trabalhistas.';
  /// Descrição da captura do passo 4 do FGTS.
  static const String fgtsCaptura4 =
      'Extrato do FGTS exibindo valores e empresas trabalhadas.';

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
