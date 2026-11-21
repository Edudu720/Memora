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

  /// O progresso no cabeçalho do seletor: "2 de 4 assuntos aprendidos".
  static String progressoDasSecoes(int aprendidas, int total) => aprendidas > 0
      ? '$aprendidas de $total assuntos aprendidos'
      : '$total assuntos para aprender';

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
  static const String tituloWhatsapp = 'Como usar o WhatsApp';
  /// Passo 1 do WhatsApp.
  static const String whatsappPasso1 =
      'Tela inicial do WhatsApp:\n'
      '1) Barra de busca para procurar conversas ou contatos.\n'
      '2) Ícones no alto: câmera rápida e menu de 3 pontinhos.\n'
      '3) Menu aberto com opções como Novo grupo e Configurações.\n'
      '4) Botão verde (+) embaixo à direita para iniciar nova conversa.\n'
      '5) Abas embaixo: Conversas, Atualizações, Comunidades e Ligações.';
  /// Descrição da captura do passo 1 do WhatsApp.
  static const String whatsappCaptura1 =
      'Tela principal do WhatsApp com cinco regiões numeradas: busca, câmera e menu, opções abertas, botão de nova conversa e abas inferiores.';
  /// Passo 2 do WhatsApp.
  static const String whatsappPasso2 =
      'Menu dos 3 pontinhos:\n'
      '1) Novo grupo e Nova comunidade para falar com várias pessoas juntas.\n'
      '2) Listas de transmissão e Dispositivos conectados (WhatsApp Web no computador).\n'
      '3) Mensagens Favoritas e opção Marcar tudo como lido.\n'
      '4) Carteira financeira e Configurações do aplicativo.';
  /// Descrição da captura do passo 2 do WhatsApp.
  static const String whatsappCaptura2 =
      'Menu de opções do WhatsApp com quatro blocos numerados explicando grupos, transmissão, favoritas e configurações.';
  /// Passo 3 do WhatsApp.
  static const String whatsappPasso3 =
      'Configurações do WhatsApp (parte 1):\n'
      '1) No alto à direita: lupa para buscar ajuste, código QR e editar nome.\n'
      '2) Transferências e Cobranças recorrentes.\n'
      '3) Dispositivos conectados para conferir computadores ligados à sua conta.\n'
      '4) Conta e Privacidade para proteger foto, recado e bloqueios.\n'
      '5) Listas, Conversas (cópia de segurança) e Aparência (tamanho de letra e tema).';
  /// Descrição da captura do passo 3 do WhatsApp.
  static const String whatsappCaptura3 =
      'Tela de Configurações do WhatsApp com cinco áreas numeradas: topo, carteira financeira, dispositivos, privacidade e aparência.';
  /// Passo 4 do WhatsApp.
  static const String whatsappPasso4 =
      'Configurações do WhatsApp (parte 2):\n'
      '1) Listas de transmissão e Notificações (toque e som das mensagens).\n'
      '2) Armazenamento e dados para liberar espaço e controlar uso de internet.\n'
      '3) Controle parental e Acessibilidade (aumentar contraste e reduzir animações).\n'
      '4) Idioma do app, Ajuda e feedback e Convidar amigos.';
  /// Descrição da captura do passo 4 do WhatsApp.
  static const String whatsappCaptura4 =
      'Segunda metade das Configurações do WhatsApp com quatro blocos numerados sobre notificações, espaço, acessibilidade e ajuda.';
  /// Título do passo 5 do WhatsApp (funcionalidades dentro da conversa).
  static const String whatsappPasso5Titulo =
      'Dentro de uma conversa do WhatsApp';
  /// Passo 5 do WhatsApp.
  static const String whatsappPasso5 =
      'Dentro de uma conversa do WhatsApp:\n'
      '1) No alto: voltar, contato, chamada de vídeo, ligação por voz e menu de 3 pontinhos;\n'
      '2) No centro: balões com mensagens trocadas e foto com botão de encaminhar;\n'
      '3) Abaixo das fotos: mensagens com links recebidos na conversa;\n'
      '4) Barra inferior: figurinhas, campo Mensagem, clipe para anexar, câmera e microfone para áudio.';
  /// Texto do passo 5 do WhatsApp.
  static const String whatsappPasso5Texto = whatsappPasso5;
  /// Descrição da captura do passo 5 do WhatsApp.
  static const String whatsappCaptura5 =
      'Conversa aberta no WhatsApp com quatro áreas numeradas: topo de chamadas, mensagens e foto, links recebidos e barra inferior com anexos e áudio.';

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
      'O story passa sozinho. Para responder, toque em "Enviar mensagem", embaixo, ou deslize o dedo para baixo para sair.';
  /// Ver, passo 2.
  static const String instagramVer2 =
      'Para ver vídeos curtos, toque no segundo ícone de baixo, o dos Reels.';
  /// Ver, passo 3.
  static const String instagramVer3 =
      'Para ver o próximo vídeo, deslize o dedo para cima; para curtir, toque no coração, à direita. Agora você sabe ver fotos e vídeos.';

  /// Story, passo 1.
  static const String instagramStory1 =
      'Toque na sua foto, no alto, à esquerda, onde está escrito "Seu story" e tem o sinal de mais.';
  /// Story, passo 2.
  static const String instagramStory2 =
      'Escolha a foto que quer mostrar: toque nela, em "Recentes".';
  /// Story, passo 3.
  static const String instagramStory3 =
      'Para mostrar aos seus seguidores por um dia, toque em "Seu story", embaixo, à esquerda. Agora você sabe publicar um story.';

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
      'Toque na conversa que você quer ler — agora você sabe ver avisos e mensagens. Se alguém pedir dinheiro ou código por mensagem, ligue para a pessoa antes de fazer qualquer coisa.';

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
      'Toque no meio do vídeo a qualquer momento para pausar ou continuar. Parabéns, agora você assiste ao que quiser no YouTube.';
  /// Descrição da captura do passo 4 do YouTube.
  static const String youtubeCaptura4 =
      'Vídeo em reprodução no YouTube com os botões de pausar e tela cheia.';

  // Facebook (T072)
  /// Título do guia do Facebook.
  static const String tituloFacebook = 'Como usar o Facebook passo a passo';
  /// Título da seção 1 do Facebook.
  static const String facebookSecao1Titulo = 'Feed, Vídeos e Marketplace';
  /// Subtítulo da seção 1 do Facebook.
  static const String facebookSecao1Subtitulo =
      'Veja publicações, assista aos Reels e explore anúncios';
  /// Título da seção 2 do Facebook.
  static const String facebookSecao2Titulo = 'Amigos, Notificações e Menu';
  /// Subtítulo da seção 2 do Facebook.
  static const String facebookSecao2Subtitulo =
      'Gerencie pedidos de amizade, avisos e configurações';
  /// Título da seção 3 do Facebook.
  static const String facebookSecao3Titulo = 'Seu Perfil e Informações';
  /// Subtítulo da seção 3 do Facebook.
  static const String facebookSecao3Subtitulo =
      'Personalize foto, apresentação e dados pessoais';

  /// Passo 1 do Facebook.
  static const String facebookPasso1 =
      'Tela inicial (Feed) do Facebook:\n'
      '1) No alto à direita: criar publicação (+), lupa de pesquisa e Messenger.\n'
      '2) Abas principais: Início, Vídeos (Reels), Amigos, Marketplace, Notificações e Perfil.\n'
      '3) Campo "No que você está pensando?" para escrever um texto ou postar foto.\n'
      '4) Cartão "Criar story" para postar foto curta que dura 24 horas.';
  /// Descrição da captura do passo 1 do Facebook.
  static const String facebookCaptura1 =
      'Tela inicial do Facebook com quatro regiões numeradas: ações do topo, barra de abas, criação de post e Stories.';
  /// Passo 2 do Facebook.
  static const String facebookPasso2 =
      'Vídeos curtos (Reels):\n'
      '1) Barra no topo indicando a aba de vídeos selecionada.\n'
      '2) Título Reels com lupa de busca e atalho para mensagens.\n'
      '3) Botões à direita: Curtir (mãozinha), Comentar, Compartilhar e Salvar vídeo.\n'
      '4) Nome da página embaixo com botão "Seguir" para ver novos vídeos dela.';
  /// Descrição da captura do passo 2 do Facebook.
  static const String facebookCaptura2 =
      'Tela de vídeo Reels no Facebook com quatro áreas numeradas mostrando curtida, comentários e botão Seguir.';
  /// Passo 3 do Facebook.
  static const String facebookPasso3 =
      'Marketplace (compra e venda):\n'
      '1) Lupa para buscar produtos por nome e botão de opções.\n'
      '2) Filtros "Vender", "Explorar", "Local" (sua cidade) e pino do mapa.\n'
      '3) Grade de anúncios com foto, preço e título — toque para ver detalhes e combinar com o vendedor.';
  /// Descrição da captura do passo 3 do Facebook.
  static const String facebookCaptura3 =
      'Tela do Marketplace no Facebook com três regiões numeradas para pesquisa, filtros locais e anúncios.';
  /// Passo 4 do Facebook.
  static const String facebookPasso4 =
      'Amigos e Pedidos de Amizade:\n'
      '1) Aba de bonequinhos no topo selecionada em azul.\n'
      '2) Botões "Sugestões" (conhecer pessoas) e "Seus amigos" (sua lista atual).\n'
      '3) Nos pedidos recebidos, toque em "Confirmar" para aceitar ou "Excluir" para recusar.';
  /// Descrição da captura do passo 4 do Facebook.
  static const String facebookCaptura4 =
      'Tela Amigos no Facebook com três marcações numeradas para aba ativa, sugestões e botões Confirmar e Excluir.';
  /// Passo 5 do Facebook.
  static const String facebookPasso5 =
      'Notificações (avisos):\n'
      '1) Ícone de sininho no topo para abrir seus avisos recentes.\n'
      '2) Lupa à direita para procurar um aviso específico.\n'
      '3) Lista de avisos: toque em qualquer linha para abrir a publicação.\n'
      '4) Três pontinhos (...) ao lado do aviso para silenciar ou remover se não quiser ver.';
  /// Descrição da captura do passo 5 do Facebook.
  static const String facebookCaptura5 =
      'Tela de Notificações do Facebook com quatro pontos numerados destacando sino, pesquisa, aviso e opções.';
  /// Passo 6 do Facebook.
  static const String facebookPasso6 =
      'Menu de Atalhos do Facebook:\n'
      '1) Cartão no topo para abrir seu próprio perfil ou criar uma página.\n'
      '2) Atalhos rápidos para Salvos, Lembranças e Marketplace.\n'
      '3) Botão "Ver mais", "Ajuda e suporte" e "Configurações e privacidade".';
  /// Descrição da captura do passo 6 do Facebook.
  static const String facebookCaptura6 =
      'Menu lateral do Facebook com três blocos numerados: cartão de perfil, atalhos e área de ajuda e configurações.';
  /// Passo 7 do Facebook.
  static const String facebookPasso7 =
      'Configurações e Privacidade:\n'
      '1) Toque em "Configurações" para ajustar nome, senha e segurança.\n'
      '2) "Central de Privacidade" e "Solicitações de dispositivos" (acessos ativos).\n'
      '3) "Sua atividade de anúncios", "Pedidos e cobranças" e "Histórico de links".\n'
      '4) Área "Atualizações" com novidades e recursos extras do aplicativo.';
  /// Descrição da captura do passo 7 do Facebook.
  static const String facebookCaptura7 =
      'Menu expandido de Configurações e Privacidade do Facebook com quatro regiões numeradas.';
  /// Passo 8 do Facebook.
  static const String facebookPasso8 =
      'Sua Página de Perfil:\n'
      '1) Botões no alto: editar perfil (lápis), buscar no perfil e mais opções (...).\n'
      '2) Ícone de câmera na foto redonda para escolher ou trocar sua foto de perfil.\n'
      '3) Botões "Adicionar ao story" e "Editar perfil".\n'
      '4) Cartão "Atualizar seu perfil" para completar seus interesses com facilidade.';
  /// Descrição da captura do passo 8 do Facebook.
  static const String facebookCaptura8 =
      'Tela de Perfil do Facebook com quatro áreas numeradas mostrando foto, botões principais e cartão de atualização.';
  /// Passo 9 do Facebook.
  static const String facebookPasso9 =
      'Editar Perfil (apresentação e dados):\n'
      '1) Câmera sobre a foto para trocar retrato ou imagem de capa.\n'
      '2) "Apresentação" para escrever uma frase sobre você ("Sobre você").\n'
      '3) "Dados pessoais": toque no lápis à direita para escolher quem pode ver sua cidade ou aniversário.';
  /// Descrição da captura do passo 9 do Facebook.
  static const String facebookCaptura9 =
      'Tela Editar Perfil do Facebook com três áreas numeradas: foto, apresentação e dados pessoais.';
  /// Passo 10 do Facebook.
  static const String facebookPasso10 =
      'Editar Perfil (trabalho e interesses):\n'
      '1) Trabalho e Educação para registrar onde trabalhou ou estudou.\n'
      '2) Hobbies e Interesses (músicas, programas de TV, filmes e jogos).\n'
      '3) Viagem e Links caso queira mostrar lugares ou sites favoritos.';
  /// Descrição da captura do passo 10 do Facebook.
  static const String facebookCaptura10 =
      'Segunda parte de Editar Perfil do Facebook com três blocos numerados sobre trabalho, interesses e viagens.';

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
      'Toque na setinha no alto, à esquerda, para voltar à galeria. Parabéns, suas lembranças estão sempre guardadas aqui.';
  /// Descrição da captura do passo 4 do Google Fotos.
  static const String googleFotosCaptura4 =
      'Foto em tela cheia com seta de voltar no canto superior esquerdo.';

  // Telegram (T072)
  /// Título do guia do Telegram.
  static const String tituloTelegram = 'Como usar o Telegram passo a passo';
  /// Título da seção 1 do Telegram.
  static const String telegramSecao1Titulo = 'Conversas e Contatos';
  /// Subtítulo da seção 1 do Telegram.
  static const String telegramSecao1Subtitulo =
      'Busque chats, inicie mensagens e salve novos contatos';
  /// Título da seção 2 do Telegram.
  static const String telegramSecao2Titulo = 'Perfil e Configurações';
  /// Subtítulo da seção 2 do Telegram.
  static const String telegramSecao2Subtitulo =
      'Ajuste foto, privacidade, idioma e ajuda no aplicativo';

  /// Passo 1 do Telegram.
  static const String telegramPasso1 =
      'Tela inicial de Chats do Telegram:\n'
      '1) Barra "Buscar Chats" no topo para localizar conversas, pessoas ou canais.\n'
      '2) Faixa de aviso (como aniversário) que você pode fechar no X.\n'
      '3) Botões à direita: câmera rápida e lápis azul para iniciar nova conversa.\n'
      '4) Abas inferiores: Chats, Contatos, Configurações e Perfil.';
  /// Descrição da captura do passo 1 do Telegram.
  static const String telegramCaptura1 =
      'Tela principal do Telegram com quatro regiões numeradas: busca, aviso, botões de ação e abas inferiores.';
  /// Passo 2 do Telegram.
  static const String telegramPasso2 =
      'Aba Contatos:\n'
      '1) Lupa no canto superior direito para pesquisar contatos salvos.\n'
      '2) Botão azul "+ Novo Contato" no centro quando a lista ainda estiver vazia.\n'
      '3) Aba "Contatos" destacada em azul na barra inferior.';
  /// Descrição da captura do passo 2 do Telegram.
  static const String telegramCaptura2 =
      'Aba Contatos do Telegram com três marcações numeradas: pesquisa, botão Novo Contato e aba ativa.';
  /// Passo 3 do Telegram.
  static const String telegramPasso3 =
      'Tela Nova Mensagem:\n'
      '1) Barra superior com seta de voltar, título "Nova Mensagem" e lupa.\n'
      '2) Atalhos para criar "Novo Grupo" (conversa em grupo) ou "Novo Canal".\n'
      '3) Botão "+ Novo Contato" para cadastrar um número antes de conversar.';
  /// Descrição da captura do passo 3 do Telegram.
  static const String telegramCaptura3 =
      'Tela Nova Mensagem do Telegram com três áreas numeradas: topo, opções de grupo e canal e Novo Contato.';
  /// Passo 4 do Telegram.
  static const String telegramPasso4 =
      'Cadastro de Novo Contato:\n'
      '1) Digite o Nome (obrigatório) e o Sobrenome (opcional).\n'
      '2) Informe o número de telefone com DDD (o Brasil já vem com +55).\n'
      '3) Opção para manter "Sincronizar com o celular" ligado.\n'
      '4) Botão azul "Criar Contato" para salvar e começar a conversar.';
  /// Descrição da captura do passo 4 do Telegram.
  static const String telegramCaptura4 =
      'Formulário Novo Contato do Telegram com quatro passos numerados de preenchimento até Criar Contato.';
  /// Passo 5 do Telegram.
  static const String telegramPasso5 =
      'Seu Perfil no Telegram:\n'
      '1) No topo à direita: código QR para compartilhar seu perfil e menu de 3 pontinhos.\n'
      '2) Atalhos rápidos: "Definir Foto", "Editar Informações" e "Configurações".\n'
      '3) Cartão com o seu número de telefone cadastrado.\n'
      '4) Botão azul "Adicione um post" se quiser publicar uma foto no perfil.';
  /// Descrição da captura do passo 5 do Telegram.
  static const String telegramCaptura5 =
      'Tela Perfil do Telegram com quatro áreas numeradas destacando ações do topo, foto, telefone e postagem.';
  /// Passo 6 do Telegram.
  static const String telegramPasso6 =
      'Configurações (topo da tela):\n'
      '1) Ícone de câmera na foto para trocar sua imagem de perfil.\n'
      '2) Aviso de segurança: confirme em "Sim" se o seu número continua sendo este.\n'
      '3) Atalhos para "Conta" (nome de usuário/bio) e "Configurações de Chat".\n'
      '4) Acesso direto para "Privacidade e Segurança" e "Notificações".';
  /// Descrição da captura do passo 6 do Telegram.
  static const String telegramCaptura6 =
      'Topo das Configurações do Telegram com quatro pontos numerados sobre foto, confirmação de número, conta e privacidade.';
  /// Passo 7 do Telegram.
  static const String telegramPasso7 =
      'Configurações (privacidade, dados e idioma):\n'
      '1) Barra superior com botão QR, lupa de busca e menu.\n'
      '2) Configurações de Chat, Privacidade e Segurança e Notificações.\n'
      '3) Dados e Armazenamento (limpar arquivos) e Pastas de Chat.\n'
      '4) Dispositivos conectados, Economia de Energia e Idioma.';
  /// Descrição da captura do passo 7 do Telegram.
  static const String telegramCaptura7 =
      'Lista intermediária de Configurações do Telegram dividida em quatro blocos numerados.';
  /// Passo 8 do Telegram.
  static const String telegramPasso8 =
      'Configurações (recursos e Ajuda):\n'
      '1) Recursos opcionais pagos (versão paga com estrela, Estrelas e Presente) — você não precisa pagar nada para usar o Telegram.\n'
      '2) Seção Ajuda com "Fazer uma Pergunta" ao suporte oficial.\n'
      '3) Perguntas Frequentes, Recursos do Telegram e Política de Privacidade.';
  /// Descrição da captura do passo 8 do Telegram.
  static const String telegramCaptura8 =
      'Parte inferior das Configurações do Telegram com três blocos numerados explicando recursos extras e Ajuda.';

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

  // Gov.br (006-guias-servicos-sociais)
  /// Título do guia do Gov.br.
  static const String tituloGovBr = 'Como usar o portal e conta Gov.br';
  /// Título da seção 1 do Gov.br.
  static const String govBrSecao1Titulo = 'Entrar na conta Gov.br';
  /// Subtítulo da seção 1 do Gov.br.
  static const String govBrSecao1Subtitulo = 'Acesse com seu CPF e senha oficial';
  /// Título da seção 2 do Gov.br.
  static const String govBrSecao2Titulo = 'Minha Área e Documentos';
  /// Subtítulo da seção 2 do Gov.br.
  static const String govBrSecao2Subtitulo = 'Veja sua caixa postal, dados e carteira';
  /// Título da seção 3 do Gov.br.
  static const String govBrSecao3Titulo = 'Baixar Certidões e Agenda';
  /// Subtítulo da seção 3 do Gov.br.
  static const String govBrSecao3Subtitulo = 'Emita comprovantes de vacina, eleitor e CPF';
  /// Título da seção 4 do Gov.br.
  static const String govBrSecao4Titulo = 'Buscar Serviços e Perfis';
  /// Subtítulo da seção 4 do Gov.br.
  static const String govBrSecao4Subtitulo = 'Encontre benefícios por perfil ou categoria';
  /// Título da seção 5 do Gov.br.
  static const String govBrSecao5Titulo = 'Aplicativos Oficiais';
  /// Subtítulo da seção 5 do Gov.br.
  static const String govBrSecao5Subtitulo = 'Conheça o Meu INSS, SUS e Carteira Digital';
  /// Título da seção 6 do Gov.br.
  static const String govBrSecao6Titulo = 'Ouvidoria e Desempenho';
  /// Subtítulo da seção 6 do Gov.br.
  static const String govBrSecao6Subtitulo = 'Envie dúvidas, elogios ou acompanhe protocolos';

  /// Passo 1 do Gov.br.
  static const String govBrPasso1 =
      'Página inicial do portal Gov.br:\n'
      '1) Menu "Atalhos gov.br" no alto.\n'
      '2) Botão azul "Entrar" no alto à direita para acessar sua conta.\n'
      '3) Barra "O que você procura?" para pesquisar serviços digitando ou pelo microfone.\n'
      '4) Lista "Mais Acessados" com os serviços mais procurados do momento.';
  /// Descrição da captura do passo 1 do Gov.br.
  static const String govBrCaptura1 =
      'Página inicial do portal gov.br com quatro áreas numeradas: atalhos, botão Entrar, pesquisa e Mais Acessados.';
  /// Passo 2 do Gov.br.
  static const String govBrPasso2 =
      'Tela de identificação pelo CPF:\n'
      '1) Caixa branca "Digite seu CPF": informe os 11 números sem pontos nem traço.\n'
      '2) Botão azul "Continuar" para seguir para a senha.\n'
      '3) Outras formas de entrar: pelo seu banco credenciado, app gov.br ou certificado digital.';
  /// Descrição da captura do passo 2 do Gov.br.
  static const String govBrCaptura2 =
      'Tela Identifique-se no gov.br com três marcações numeradas: campo de CPF, Continuar e opções alternativas.';
  /// Passo 3 do Gov.br.
  static const String govBrPasso3 =
      'Tela para digitar sua senha:\n'
      '1) Campo "Digite sua senha atual" — toque no olhinho amarelo à direita se quiser conferir o que digitou.\n'
      '2) Botão azul "Entrar" para concluir o acesso.\n'
      '3) Opções "Cancelar" e "Esqueci minha senha" caso não se lembre da senha.';
  /// Descrição da captura do passo 3 do Gov.br.
  static const String govBrCaptura3 =
      'Tela oficial de senha do gov.br com três regiões numeradas: senha com ícone de olho, botão Entrar e recuperação.';
  /// Passo 4 do Gov.br.
  static const String govBrPasso4 =
      'Menu da sua conta autenticada:\n'
      '1) Selo mostrando o nível da sua conta (Bronze, Prata ou Ouro).\n'
      '2) Botão "Minha área gov.br" para abrir seu painel pessoal.\n'
      '3) Lista com Dados Pessoais, Segurança da Conta, Procurações, Privacidade, Ajuda e Sair.';
  /// Descrição da captura do passo 4 do Gov.br.
  static const String govBrCaptura4 =
      'Menu da conta Gov.br logada com três áreas numeradas: nível da conta, Minha área e configurações pessoais.';

  /// Passo 5 do Gov.br.
  static const String govBrPasso5 =
      'Painel "Minha área gov.br":\n'
      '1) Botão "AUMENTAR NÍVEL" para passar de Bronze para Prata ou Ouro e liberar mais serviços.\n'
      '2) Atalhos rápidos para "Caixa postal" (avisos oficiais) e "Carteira de documentos".\n'
      '3) Acesso direto a "Baixar certidões", "Gerenciar dados de contato" e "Assinar documentos".';
  /// Descrição da captura do passo 5 do Gov.br.
  static const String govBrCaptura5 =
      'Painel Minha área gov.br com três marcações numeradas: aumentar nível, documentos e certidões.';
  /// Passo 6 do Gov.br.
  static const String govBrPasso6 =
      'Painel "Serviços gov.br":\n'
      '1) Barra lateral esquerda com ícones para Início, Agenda, Certidões, Sistemas e Aplicativos.\n'
      '2) Cartões "Agenda gov.br" e "Assinar documentos digitalmente".\n'
      '3) Cartões "Baixar certidões" e "Caixa Postal" para ver mensagens oficiais.';
  /// Descrição da captura do passo 6 do Gov.br.
  static const String govBrCaptura6 =
      'Painel Olá do Gov.br com três regiões numeradas destacando menu lateral e cartões de serviços.';
  /// Passo 7 do Gov.br.
  static const String govBrPasso7 =
      'Mais cartões em "Serviços gov.br":\n'
      '1) "Carteira de Documentos" (CNH, RG) e "Dados Pessoais".\n'
      '2) "Gerenciar dados de contato" (e-mail e telefone) e "Govinho" (crianças até 6 anos).\n'
      '3) "Notificações", "Privacidade", "Procurações Eletrônicas" e "Segurança da conta".';
  /// Descrição da captura do passo 7 do Gov.br.
  static const String govBrCaptura7 =
      'Grade de serviços do Gov.br com três blocos numerados para documentos, contatos e segurança.';
  /// Passo 8 do Gov.br.
  static const String govBrPasso8 =
      'Lista completa em "Minha conta":\n'
      '1) Atalhos para Carteira de documentos, certidões, validação eletrônica e serviços solicitados.\n'
      '2) Links para "Agenda GOV.BR", "Notificações" e "Ajuda da conta gov.br".\n'
      '3) Bloco "Minha conta" para conferir Dados Pessoais, Segurança, Procurações e Privacidade.';
  /// Descrição da captura do passo 8 do Gov.br.
  static const String govBrCaptura8 =
      'Lista Minha conta no Gov.br com três marcações numeradas organizando documentos, avisos e configurações.';

  /// Passo 9 do Gov.br.
  static const String govBrPasso9 =
      'Tela da "Agenda gov.br":\n'
      '1) Setas (< e >) para mudar de mês e ver datas importantes.\n'
      '2) Cartões com prazos e compromissos destacados em verde ("Atualizado").\n'
      '3) Botão "Ver Agenda" embaixo para consultar todos os agendamentos.';
  /// Descrição da captura do passo 9 do Gov.br.
  static const String govBrCaptura9 =
      'Tela Agenda gov.br com três regiões numeradas para navegação de mês, prazos e agenda completa.';
  /// Passo 10 do Gov.br.
  static const String govBrPasso10 =
      'Tela de "Certidões" (parte 1):\n'
      '1) "Cartão Nacional de Saúde" e "Carteira Nacional de Vacinação".\n'
      '2) "Certidão de Pessoa com Deficiência" e "Certificado de Cadastro Único".\n'
      '3) "Certidão de Quitação Eleitoral" e "Certidão de Antecedentes Criminais".';
  /// Descrição da captura do passo 10 do Gov.br.
  static const String govBrCaptura10 =
      'Primeira parte das Certidões no Gov.br com três pares numerados de documentos gratuitos.';
  /// Passo 11 do Gov.br.
  static const String govBrPasso11 =
      'Tela de "Certidões" (parte 2):\n'
      '1) "Consultar CNPJ" e "Comprovante de Situação Cadastral no CPF".\n'
      '2) Certidões de "Regularidade Fiscal" para empresas e cidadãos.\n'
      '3) "Certidão de Contas Julgadas" com emissão gratuita pelo portal.';
  /// Descrição da captura do passo 11 do Gov.br.
  static const String govBrCaptura11 =
      'Segunda parte das Certidões no Gov.br com três blocos numerados para CPF, CNPJ e regularidade fiscal.';

  /// Passo 12 do Gov.br.
  static const String govBrPasso12 =
      'Destaques do portal Gov.br:\n'
      '1) Barra "DESTAQUE" com os serviços federais mais procurados.\n'
      '2) "Entregar Meu Imposto de Renda (DIRPF)" e "Renegociação de Dívidas - Famílias".\n'
      '3) "Celular Seguro" (para bloquear aparelho roubado) e "Bolsa Família (PBF)".';
  /// Descrição da captura do passo 12 do Gov.br.
  static const String govBrCaptura12 =
      'Destaques do portal gov.br com três áreas numeradas: título, imposto e programas sociais.';
  /// Passo 13 do Gov.br.
  static const String govBrPasso13 =
      'Serviços Digitais por Perfil (parte 1):\n'
      '1) Perfil "Agricultor" para acesso a programas e crédito rural.\n'
      '2) Perfil "Turista" com informações úteis de viagem e documentação.\n'
      '3) Botão "Todos os Perfis" caso queira ver a lista completa.';
  /// Descrição da captura do passo 13 do Gov.br.
  static const String govBrCaptura13 =
      'Perfis Agricultor e Turista no Gov.br com três pontos numerados.';
  /// Passo 14 do Gov.br.
  static const String govBrPasso14 =
      'Serviços Digitais por Perfil (parte 2):\n'
      '1) Perfil "Aposentado" com atalhos diretos para benefícios e INSS.\n'
      '2) Perfil "Empreendedor" para quem tem MEI ou pequeno negócio.\n'
      '3) Botão "Todos os Perfis" para abrir todos os públicos disponíveis.';
  /// Descrição da captura do passo 14 do Gov.br.
  static const String govBrCaptura14 =
      'Perfis Aposentado e Empreendedor no Gov.br com três marcações numeradas.';
  /// Passo 15 do Gov.br.
  static const String govBrPasso15 =
      'Navegue por Categoria (letras A até E):\n'
      '1) Título "Navegue por categoria" para buscar assuntos por área.\n'
      '2) Agricultura e Pecuária, Assistência Social, Ciência e Comunicações.\n'
      '3) Cultura, Artes, Defesa Civil e Educação.';
  /// Descrição da captura do passo 15 do Gov.br.
  static const String govBrCaptura15 =
      'Categorias de A a E no portal Gov.br organizadas em três blocos numerados.';
  /// Passo 16 do Gov.br.
  static const String govBrPasso16 =
      'Navegue por Categoria (letras E até T):\n'
      '1) Educação e Pesquisa, Empresa/Comércio e Energia.\n'
      '2) Finanças, Impostos, Justiça, Segurança e Meio Ambiente.\n'
      '3) Saúde, Trabalho, Previdência e Infraestrutura.';
  /// Descrição da captura do passo 16 do Gov.br.
  static const String govBrCaptura16 =
      'Categorias de E a T no portal Gov.br divididas em três áreas numeradas.';

  /// Passo 17 do Gov.br.
  static const String govBrPasso17 =
      'Página de Aplicativos Móveis Oficiais:\n'
      '1) Aviso do governo explicando os aplicativos oficiais para evitar apps falsos.\n'
      '2) Cartão do aplicativo principal "gov.br" — toque para ver onde baixar com segurança.';
  /// Descrição da captura do passo 17 do Gov.br.
  static const String govBrCaptura17 =
      'Banner dos aplicativos móveis oficiais no Gov.br com duas áreas numeradas.';
  /// Passo 18 do Gov.br.
  static const String govBrPasso18 =
      'Galeria de Aplicativos Oficiais:\n'
      '1) Barra no alto com "Atalhos gov.br" e botão "Entrar".\n'
      '2) Botões "Filtrar" e "Ordenar" para localizar o aplicativo que você precisa.\n'
      '3) Cartão oficial (como Carteira Digital de Trânsito) com selo verificado.';
  /// Descrição da captura do passo 18 do Gov.br.
  static const String govBrCaptura18 =
      'Galeria de Aplicativos do Gov.br com três regiões numeradas para navegação, filtros e cartão do app.';
  /// Passo 19 do Gov.br.
  static const String govBrPasso19 =
      'Aplicativos mais acessados:\n'
      '1) "gov.br" e "Carteira Digital de Trânsito" (CNH no celular).\n'
      '2) "Meu INSS" (aposentadoria) e "Carteira de Trabalho Digital".\n'
      '3) "Cadastro Único" e "Meu SUS Digital" (vacinas e exames).\n'
      '4) "MEI", "Jornada do Estudante" e botão "Ver aplicativos".';
  /// Descrição da captura do passo 19 do Gov.br.
  static const String govBrCaptura19 =
      'Seção Aplicativos mais acessados no Gov.br com quatro linhas numeradas.';
  /// Passo 20 do Gov.br.
  static const String govBrPasso20 =
      'Atalhos para Benefícios Sociais:\n'
      '1) Aplicativo oficial "MEU INSS - Central de Serviços" para aposentadoria, pensão e perícia.\n'
      '2) Aplicativo oficial "CADASTRO ÚNICO" para acompanhar benefícios sociais da família.';
  /// Descrição da captura do passo 20 do Gov.br.
  static const String govBrCaptura20 =
      'Cartões dos aplicativos oficiais Meu INSS e Cadastro Único destacados em duas áreas numeradas.';
  /// Passo 21 do Gov.br.
  static const String govBrPasso21 =
      'Atalhos para Trabalho e Negócio:\n'
      '1) Aplicativo oficial "MEI" da Receita Federal para guias e notas fiscais.\n'
      '2) Aplicativo "CARTEIRA DE TRABALHO DIGITAL" do Ministério do Trabalho.';
  /// Descrição da captura do passo 21 do Gov.br.
  static const String govBrCaptura21 =
      'Cartões dos aplicativos oficiais MEI e Carteira de Trabalho Digital em duas áreas numeradas.';

  /// Passo 22 do Gov.br.
  static const String govBrPasso22 =
      'Painel "Desempenho dos Serviços":\n'
      '1) Título da seção de transparência do portal.\n'
      '2) Quantidade total de serviços disponíveis no portal Gov.br.\n'
      '3) Porcentagem de Serviços Digitais (94%) e Avaliações positivas da população.';
  /// Descrição da captura do passo 22 do Gov.br.
  static const String govBrCaptura22 =
      'Painel Desempenho dos Serviços no Gov.br com três indicadores numerados.';
  /// Passo 23 do Gov.br.
  static const String govBrPasso23 =
      'Ouvidoria e Acesso à Informação (parte 1):\n'
      '1) Cartão "DENÚNCIA" para comunicar irregularidades com segurança.\n'
      '2) Cartão "SOLICITAÇÃO" para pedir atendimentos ou informações públicas.';
  /// Descrição da captura do passo 23 do Gov.br.
  static const String govBrCaptura23 =
      'Tela da Ouvidoria Gov.br com dois cartões numerados para Denúncia e Solicitação.';
  /// Passo 24 do Gov.br.
  static const String govBrPasso24 =
      'Ouvidoria e Acesso à Informação (parte 2):\n'
      '1) Cartão "ELOGIO" para agradecer ou avaliar positivamente um atendimento.\n'
      '2) Cartão "RECLAMAÇÕES" para relatar problemas com algum serviço.\n'
      '3) Botão "Protocolo GOV.BR" para acompanhar o andamento da sua resposta.';
  /// Descrição da captura do passo 24 do Gov.br.
  static const String govBrCaptura24 =
      'Opções da Ouvidoria Gov.br com três marcações numeradas para Elogio, Reclamações e Protocolo.';

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
      'Veja o extrato com o valor e a data do seu benefício. Parabéns, você já sabe conferir seu benefício.';
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
      'Pronto, este é o seu título de eleitor no celular. Para saber onde você vota, toque em "Onde votar", embaixo, a segunda opção da esquerda.';
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

  // Serasa (006-guias-servicos-sociais)
  /// Título do guia do Serasa.
  static const String tituloSerasa = 'Como consultar seu CPF no Serasa';
  /// Título da seção 1 do Serasa.
  static const String serasaSecao1Titulo = 'Conhecer Início e Menu';
  /// Subtítulo da seção 1 do Serasa.
  static const String serasaSecao1Subtitulo = 'Navegue pela página inicial e menu de produtos';
  /// Título da seção 2 do Serasa.
  static const String serasaSecao2Titulo = 'Consultar Serasa Score';
  /// Subtítulo da seção 2 do Serasa.
  static const String serasaSecao2Subtitulo = 'Entenda sua pontuação e receba alertas';
  /// Título da seção 3 do Serasa.
  static const String serasaSecao3Titulo = 'Ver Dívidas e Acordos';
  /// Subtítulo da seção 3 do Serasa.
  static const String serasaSecao3Subtitulo = 'Confira se há pendências, ofertas e acordos';
  /// Título da seção 4 do Serasa.
  static const String serasaSecao4Titulo = 'Proteger seu CPF';
  /// Subtítulo da seção 4 do Serasa.
  static const String serasaSecao4Subtitulo = 'Acompanhe vazamentos e monitore seu documento';
  /// Título da seção 5 do Serasa.
  static const String serasaSecao5Titulo = 'Outros Serviços e Ajuda';
  /// Subtítulo da seção 5 do Serasa.
  static const String serasaSecao5Subtitulo = 'Valide boletos, veja extratos e tire dúvidas';

  /// Passo 1 do Serasa.
  static const String serasaPasso1 =
      'Página inicial do Serasa:\n'
      '1) Botão "Menu" no alto à esquerda para abrir todas as áreas.\n'
      '2) Botão "Entrar" no alto à direita para acessar sua conta.\n'
      '3) Botão rosa "Consultar CPF grátis" no rodapé para começar.';
  /// Descrição da captura do passo 1 do Serasa.
  static const String serasaCaptura1 =
      'Página inicial do Serasa com três regiões numeradas: Menu, Entrar e Consultar CPF grátis.';
  /// Passo 2 do Serasa.
  static const String serasaPasso2 =
      'Capa com aviso do Feirão Serasa:\n'
      '1) Faixa do aplicativo oficial Serasa (você pode fechar no X ou baixar na loja).\n'
      '2) Aviso de campanhas do Feirão para negociar dívidas com desconto.\n'
      '3) Botão rosa "Consultar CPF grátis" para entrar ou criar sua conta.';
  /// Descrição da captura do passo 2 do Serasa.
  static const String serasaCaptura2 =
      'Capa promocional do Serasa com três áreas numeradas destacando aplicativo oficial, Feirão e acesso gratuito.';
  /// Passo 3 do Serasa.
  static const String serasaPasso3 =
      'Menu lateral do Serasa:\n'
      '1) Botão X para fechar o menu quando terminar.\n'
      '2) Abas "Cadastrar" e "Entrar" para criar ou acessar seu cadastro.\n'
      '3) Atalhos para "Serasa Blog", "Canal de Denúncias" e "Central de Ajuda".\n'
      '4) Lista de Produtos: Crédito, Área Paga Opcional, Limpa Nome e Score.';
  /// Descrição da captura do passo 3 do Serasa.
  static const String serasaCaptura3 =
      'Menu lateral do Serasa com quatro blocos numerados explicando cadastro, ajuda e produtos.';
  /// Passo 4 do Serasa.
  static const String serasaPasso4 =
      'Tela inicial após entrar na conta:\n'
      '1) Ícones de conquistas e seu perfil no canto superior direito.\n'
      '2) Botão rosa "Conectar contas" para melhorar a análise do seu Score.\n'
      '3) Atalhos rápidos: Pedir cartão, Consultas ao meu CPF e Pedir empréstimo.\n'
      '4) Barra inferior fixa: Início, Finanças, Meu CPF, Dívidas e Serviços.';
  /// Descrição da captura do passo 4 do Serasa.
  static const String serasaCaptura4 =
      'Tela inicial autenticada do Serasa com quatro áreas numeradas de navegação e atalhos.';

  /// Passo 5 do Serasa.
  static const String serasaPasso5 =
      'Cartão do Serasa Score na tela inicial:\n'
      '1) Sua pontuação de 0 a 1000 e faixa de avaliação ("Bom", "Regular" ou "Excelente").\n'
      '2) Opção "Conecte suas contas" para enriquecer seu histórico.\n'
      '3) Indicador se o seu "Serasa Score" está liberado ou bloqueado para empresas consultarem.';
  /// Descrição da captura do passo 5 do Serasa.
  static const String serasaCaptura5 =
      'Cartão Serasa Score com três marcações numeradas mostrando pontuação, conexão de contas e status de visualização.';
  /// Passo 6 do Serasa.
  static const String serasaPasso6 =
      'Detalhes em "Seu Serasa Score":\n'
      '1) Pontuação detalhada, variação recente e o motivo principal da sua nota.\n'
      '2) Botão rosa "Ir para Minhas Contas" para gerenciar dados vinculados.\n'
      '3) Aba "Finanças" destacada na barra inferior.';
  /// Descrição da captura do passo 6 do Serasa.
  static const String serasaCaptura6 =
      'Página Seu Serasa Score com três regiões numeradas explicando nota, contas e aba Finanças.';
  /// Passo 7 do Serasa.
  static const String serasaPasso7 =
      'Acompanhamento de variações do Score:\n'
      '1) Oferta opcional paga do Serasa (você não precisa contratar nada para consultar grátis).\n'
      '2) "Variações na pontuação": toque para ver o histórico dos meses anteriores.\n'
      '3) "Contas conectadas" para revisar instituições financeiras ligadas.';
  /// Descrição da captura do passo 7 do Serasa.
  static const String serasaCaptura7 =
      'Tela intermediária do Serasa Score com três blocos numerados sobre oferta opcional paga, histórico e contas.';
  /// Passo 8 do Serasa.
  static const String serasaPasso8 =
      'Alertas e Monitoramento de Score:\n'
      '1) Botão rosa "Receber alertas do Score" para ser avisado quando a nota mudar.\n'
      '2) Atalhos para "Empresas em seu nome" e "Consulta de Identidade".\n'
      '3) Atalhos para "Consultas em seu nome" e "Vazamento de dados".';
  /// Descrição da captura do passo 8 do Serasa.
  static const String serasaCaptura8 =
      'Opções de monitoramento do Serasa com três regiões numeradas para alertas, CNPJ e vazamentos.';

  /// Passo 9 do Serasa.
  static const String serasaPasso9 =
      'Situação do nome e monitoramento:\n'
      '1) Cartão "Seu nome está limpo" indicando nenhuma dívida registrada e botão "Ver meu CPF".\n'
      '2) Área "Monitoramento de dados" para acompanhar quem consultou seu CPF.\n'
      '3) Aba "Dívidas" no rodapé para consultar acordos.';
  /// Descrição da captura do passo 9 do Serasa.
  static const String serasaCaptura9 =
      'Painel Seu nome está limpo com três áreas numeradas para status limpo, monitoramento e aba Dívidas.';
  /// Passo 10 do Serasa.
  static const String serasaPasso10 =
      'Aba "Minhas Dívidas":\n'
      '1) Abas superiores para alternar entre "Ofertas" e "Acordos".\n'
      '2) Filtros rápidos: "Em andamento", "Quitados" e "Vencidos".\n'
      '3) Área "Em andamento pela Serasa" onde ficam boletos e parcelas de acordos ativos.';
  /// Descrição da captura do passo 10 do Serasa.
  static const String serasaCaptura10 =
      'Tela Minhas Dívidas no Serasa com três regiões numeradas de abas, filtros e acordos.';
  /// Passo 11 do Serasa.
  static const String serasaPasso11 =
      'Situação de acordos na lista:\n'
      '1) "Acordos com a empresa parceira": acordos tratados fora da Serasa.\n'
      '2) "Acordos já quitados": histórico dos acordos que você já terminou de pagar.\n'
      '3) "Acordos vencidos ou cancelados": parcelas atrasadas ou canceladas.';
  /// Descrição da captura do passo 11 do Serasa.
  static const String serasaCaptura11 =
      'Lista detalhada de acordos no Serasa com três blocos numerados por status.';
  /// Passo 12 do Serasa.
  static const String serasaPasso12 =
      'Atalhos de Dívidas na aba Serviços:\n'
      '1) "Dívidas negativadas" para conferir pendências em seu CPF.\n'
      '2) "Meus acordos" para emitir segundas vias de boletos.\n'
      '3) "Propostas e ofertas" com condições de negociação.\n'
      '4) Aba "Serviços" selecionada embaixo à direita.';
  /// Descrição da captura do passo 12 do Serasa.
  static const String serasaCaptura12 =
      'Aba Serviços do Serasa com quatro marcações numeradas para pendências, acordos e ofertas.';

  /// Passo 13 do Serasa.
  static const String serasaPasso13 =
      'Topo da aba "Meu CPF":\n'
      '1) Título "Meu CPF" com resumo do seu documento.\n'
      '2) Banner opcional de recurso pago do Serasa (você pode apenas rolar para ver os serviços grátis).\n'
      '3) Cartão com atalho para consulta veicular.\n'
      '4) Aba central "Meu CPF" ativa na barra inferior.';
  /// Descrição da captura do passo 13 do Serasa.
  static const String serasaCaptura13 =
      'Topo da aba Meu CPF com quatro áreas numeradas para título, proteção, consulta e barra inferior.';
  /// Passo 14 do Serasa.
  static const String serasaPasso14 =
      'Saúde financeira gratuita:\n'
      '1) Selo "Gratuito" indicando que estes serviços não têm custo.\n'
      '2) "Dívidas e pendências" e "Extrato Serasa" (comprovante da situação do seu CPF).\n'
      '3) "Vazamento de dados" e "Documentos extraviados" (registre alerta caso perca RG ou CPF).';
  /// Descrição da captura do passo 14 do Serasa.
  static const String serasaCaptura14 =
      'Seção Saúde financeira gratuita do Serasa com três blocos numerados.';
  /// Passo 15 do Serasa.
  static const String serasaPasso15 =
      'Selo de segurança e Serasa Recomenda:\n'
      '1) Área "Seu selo atual" mostrando o nível de proteção da sua conta.\n'
      '2) Bloco "Serviços" com opções pagas sob demanda, como "Serasa Recomenda" ("Solicitar análise").';
  /// Descrição da captura do passo 15 do Serasa.
  static const String serasaCaptura15 =
      'Tela com selo de segurança e serviços sob demanda no Serasa divididos em duas regiões numeradas.';
  /// Passo 16 do Serasa.
  static const String serasaPasso16 =
      'Consultas de Dark Web, Carro e Assistência:\n'
      '1) "Saiba quem te consultou e se seu CPF vazou" (relatório Dark Web).\n'
      '2) "Serviços de assistência disponíveis 24h".\n'
      '3) "Extrato Veicular" para consultar débitos e multas de carros antes de comprar.';
  /// Descrição da captura do passo 16 do Serasa.
  static const String serasaCaptura16 =
      'Cartões de consultas especiais do Serasa com três regiões numeradas.';
  /// Passo 17 do Serasa.
  static const String serasaPasso17 =
      'Educação financeira e Consulta Terceiros:\n'
      '1) "Organize seus gastos sem complicação" (parceiro Organizze).\n'
      '2) "Cursos de educação financeira" para aprender a controlar o orçamento.\n'
      '3) "Consulta Terceiros Básica" para verificar um CPF ou CNPJ autorizado.';
  /// Descrição da captura do passo 17 do Serasa.
  static const String serasaCaptura17 =
      'Serviços adicionais do Serasa com três blocos numerados: organização, cursos e consulta terceiros.';

  /// Passo 18 do Serasa.
  static const String serasaPasso18 =
      'Área de Crédito e Empréstimos:\n'
      '1) Cartão "Empréstimos e Cartões" para simular opções no seu perfil.\n'
      '2) Bloco "Mais soluções financeiras" com atalho para "Empréstimo fácil".';
  /// Descrição da captura do passo 18 do Serasa.
  static const String serasaCaptura18 =
      'Área de crédito do Serasa com duas marcações numeradas para empréstimos e cartões.';
  /// Passo 19 do Serasa.
  static const String serasaPasso19 =
      'Bloqueio de consultas e Cadastro Positivo:\n'
      '1) "Bloqueio de consultas" para evitar que terceiros vejam seu Score sem aviso.\n'
      '2) "Cadastro Positivo" para consultar seu histórico de contas pagas em dia.\n'
      '3) Cartões "Soluções escolhidas para você" na parte inferior.';
  /// Descrição da captura do passo 19 do Serasa.
  static const String serasaCaptura19 =
      'Opções de bloqueio de consultas e Cadastro Positivo no Serasa com três áreas numeradas.';
  /// Passo 20 do Serasa.
  static const String serasaPasso20 =
      'Menu de Serviços — documentos e Score:\n'
      '1) "Pendências CPF/CNPJ" para checar obrigações financeiras.\n'
      '2) "Extrato Serasa" com histórico completo.\n'
      '3) "Bloquear Score" (função paga opcional).\n'
      '4) "Variações do Score" para rever sua evolução.';
  /// Descrição da captura do passo 20 do Serasa.
  static const String serasaCaptura20 =
      'Lista de Serviços no Serasa com quatro regiões numeradas para pendências, extrato e Score.';
  /// Passo 21 do Serasa.
  static const String serasaPasso21 =
      'Proteção de dados e Pedidos:\n'
      '1) "Proteção de dados" para configurar privacidade da conta.\n'
      '2) "Cadastro Positivo" para revisar dados compartilhados.\n'
      '3) "Cartões e empréstimos" na área de Crédito.\n'
      '4) "Acompanhar meus pedidos" caso tenha solicitado cartão ou análise.';
  /// Descrição da captura do passo 21 do Serasa.
  static const String serasaCaptura21 =
      'Tela de Proteção de dados e pedidos no Serasa com quatro blocos numerados.';
  /// Passo 22 do Serasa.
  static const String serasaPasso22 =
      'Validador de boleto e Central de Ajuda:\n'
      '1) Atalhos para "Meu perfil", "Conectar contas" e "Histórico de cartões".\n'
      '2) "Validador de boleto": confira antes de pagar se o código do boleto é verdadeiro.\n'
      '3) "Atualização cadastral" e "Central de Ajuda" para tirar dúvidas com segurança.';
  /// Descrição da captura do passo 22 do Serasa.
  static const String serasaCaptura22 =
      'Opções finais de Serviços do Serasa com três regiões numeradas destacando Validador de boleto e Ajuda.';

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
      'O aplicativo pergunta como deve chamar você. Se quiser, escreva no campo; se não, toque em "Pular", embaixo.';
  /// Entrar, passo 5.
  static const String fgtsEntrar5 =
      'Toque em "Ativar notificações" para receber avisos, ou em "Agora não" para pular. Pronto: você já sabe entrar no aplicativo do FGTS.';

  /// Saldo e saque, passo 1.
  static const String fgtsSaque1 =
      'Nesta página principal, toque em "Toque para exibir o saldo", no alto, para ver quanto você tem. Quem estiver perto também vê: olhe o saldo num lugar tranquilo.';
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
      'Aqui aparece sua conta cadastrada, e "Alterar conta bancária" faz a troca — agora você sabe onde ela fica. Se alguém ligar pedindo para você trocar a conta, é golpe: só você troca, aqui, no aplicativo oficial.';

  /// Saque-Aniversário, passo 1.
  static const String fgtsAniversario1 =
      'Para conhecer o Saque-Aniversário, toque em "Mais", embaixo, à direita.';
  /// Saque-Aniversário, passo 2.
  static const String fgtsAniversario2 =
      'Toque em "Sistemática de saque", a segunda opção da lista.';
  /// Saque-Aniversário, passo 3.
  static const String fgtsAniversario3 =
      'Antes de decidir, leia "O que muda se eu fizer a opção?", pois quem opta pelo Saque-Aniversário e perde o emprego recebe só a multa, e não o saldo todo. Agora você sabe onde fica e o que muda.';

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
      'Tela Vamos começar, que pergunta como deve chamar você, com os botões Cadastrar nome e continuar e Pular.';
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
      'Escolha o dia, horário e posto de atendimento mais próximo. Parabéns, seu agendamento está concluído.';
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
      'Toque no documento para abrir em tamanho legível. Parabéns, seus documentos oficiais estão sempre seguros com você.';
  /// Descrição da captura do passo 4 da Carteira Digital.
  static const String carteiraDigitalCaptura4 =
      'Documento digital oficial aberto com dados legíveis e código de autenticidade.';

  // Correios (006-guias-servicos-sociais)
  /// Título do guia dos Correios.
  static const String tituloCorreios = 'Como rastrear e usar os Correios';
  /// Título da seção 1 dos Correios.
  static const String correiosSecao1Titulo = 'Rastrear Encomenda';
  /// Subtítulo da seção 1 dos Correios.
  static const String correiosSecao1Subtitulo = 'Acompanhe o caminho da sua entrega passo a passo';
  /// Título da seção 2 dos Correios.
  static const String correiosSecao2Titulo = 'Calcular Frete e Meu Correios';
  /// Subtítulo da seção 2 dos Correios.
  static const String correiosSecao2Subtitulo = 'Consulte preços, prazos e entre na sua conta';

  /// Passo 1 dos Correios.
  static const String correiosPasso1 =
      'Página inicial dos Correios:\n'
      '1) Botão de menu (três tracinhos) no alto à esquerda.\n'
      '2) Botões "Entrar" e lupa de pesquisa no alto à direita.\n'
      '3) Área "Acompanhe seu Objeto" para rastrear suas encomendas.';
  /// Descrição da captura do passo 1 dos Correios.
  static const String correiosCaptura1 =
      'Portal inicial dos Correios com três áreas numeradas: menu, entrar e Acompanhe seu Objeto.';
  /// Passo 2 dos Correios.
  static const String correiosPasso2 =
      'Digitando o código do pacote:\n'
      '1) Toque na caixa branca e digite o código de 13 letras/números ou o seu CPF.\n'
      '2) Toque na lupa azul à direita da caixa para pesquisar.\n'
      '3) Atalhos rápidos abaixo: Preços e Prazos, Comprar, Aplicativo Correios e Busca CEP.';
  /// Descrição da captura do passo 2 dos Correios.
  static const String correiosCaptura2 =
      'Campo Acompanhe seu Objeto dos Correios com três marcações numeradas e teclado visível.';
  /// Passo 3 dos Correios.
  static const String correiosPasso3 =
      'Tela de verificação de rastreamento:\n'
      '1) Campo no alto mostrando o código do objeto ou CPF informado.\n'
      '2) Imagem com letras e números de segurança (use o som ou setas para trocar se estiver difícil).\n'
      '3) Caixa "Digite o texto contido na imagem" para copiar as letras.\n'
      '4) Botão azul "Consultar" para ver o andamento.';
  /// Descrição da captura do passo 3 dos Correios.
  static const String correiosCaptura3 =
      'Formulário de rastreamento dos Correios com quatro passos numerados até o botão Consultar.';
  /// Passo 4 dos Correios.
  static const String correiosPasso4 =
      'Linha do tempo da sua entrega:\n'
      '1) Cabeçalho com o código de rastreio e data da última atualização.\n'
      '2) Primeira linha no topo com a etapa mais recente (por exemplo: "Seu pacote foi entregue").\n'
      '3) Lista abaixo mostrando todo o caminho por onde a encomenda passou até chegar.';
  /// Descrição da captura do passo 4 dos Correios.
  static const String correiosCaptura4 =
      'Linha do tempo de rastreamento dos Correios com três regiões numeradas.';

  /// Passo 5 dos Correios.
  static const String correiosPasso5 =
      'Menu principal dos Correios:\n'
      '1) Opções "Enviar", "Receber" e "Comprar" para postagens e serviços.\n'
      '2) "Logística", "Atendimento" e "Acesso à Informação".\n'
      '3) Campo "Acompanhe seu Objeto" logo abaixo do menu.';
  /// Descrição da captura do passo 5 dos Correios.
  static const String correiosCaptura5 =
      'Menu aberto do portal dos Correios com três áreas numeradas.';
  /// Passo 6 dos Correios.
  static const String correiosPasso6 =
      'Simulador de Preços e Prazos (frete):\n'
      '1) Informe o CEP de "Origem" (quem envia) e de "Destino" (quem recebe).\n'
      '2) Preencha as medidas da caixa em centímetros: Altura, Largura e Comprimento.\n'
      '3) Toque no botão azul "Calcular Frete" para ver valor e prazo de entrega.';
  /// Descrição da captura do passo 6 dos Correios.
  static const String correiosCaptura6 =
      'Tela de cálculo de frete dos Correios com três passos numerados.';
  /// Passo 7 dos Correios.
  static const String correiosPasso7 =
      'Menu lateral do Rastreamento:\n'
      '1) "Rastreamento" e botão "Entrar" no topo amarelo.\n'
      '2) "Rastreamento em outros países", "Perguntas frequentes" e "Busca Agências" (achar agência perto de casa).\n'
      '3) "Central de Atendimento", Prazos de Guarda e Restrição de Entrega por CEP.';
  /// Descrição da captura do passo 7 dos Correios.
  static const String correiosCaptura7 =
      'Menu do Rastreamento dos Correios dividido em três blocos numerados.';
  /// Passo 8 dos Correios.
  static const String correiosPasso8 =
      'Login no "Meu Correios":\n'
      '1) Leia o lembrete: no campo Usuário, digite seu CPF ou CNPJ usando apenas números.\n'
      '2) Botão azul "Entrar" após preencher seus dados.\n'
      '3) Opções "Esqueci minha senha", "Cadastrar" (criar conta) e "Fale conosco".';
  /// Descrição da captura do passo 8 dos Correios.
  static const String correiosCaptura8 =
      'Tela de login do Meu Correios com três áreas numeradas.';

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
      'Confira as datas de admissão, cargo e anotações da empresa. Parabéns, seu histórico de trabalho está sempre acessível.';
  /// Descrição da captura do passo 4 da Carteira de Trabalho Digital.
  static const String carteiraDeTrabalhoCaptura4 =
      'Detalhes de um contrato de trabalho com data de admissão e salário anotados.';
}
