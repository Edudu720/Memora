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

  /// Marca de módulo concluído por inteiro no catálogo (020).
  static const String moduloConcluido = 'Concluído';

  /// Leitura do cartão de seção pelo leitor de tela.
  static String secaoDescrita(String titulo, String subtitulo, String meta) =>
      '$titulo. $subtitulo. $meta.';

  /// Leitura do cartão de seção concluída pelo leitor de tela.
  static String secaoConcluidaDescrita(
    String titulo,
    String subtitulo,
    String meta,
  ) => '$titulo. $subtitulo. $meta. Concluído.';

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
      'Tela inicial do Instagram (ver fotos):\n'
      '1) Bolinhas dos stories no alto com fotos que duram um dia.\n'
      '2) Coração no topo à direita para ver avisos e curtidas.\n'
      '3) Botões abaixo da foto: toque no coração à esquerda para curtir, no balão para comentar ou no aviãozinho para enviar.\n'
      '4) Barra inferior: Início, Reels, Mensagens, Busca (lupa) e seu Perfil.';
  /// Ver, o story (1 de 2).
  static const String instagramVerStory1 =
      'Abrindo o story de um amigo na tela inicial:\n'
      '1) Toque numa das bolinhas coloridas dos seus amigos no alto da tela para abrir o story.\n'
      '2) Ícone de coração no topo à direita para suas notificações.\n'
      '3) Ícones de curtir, comentar e compartilhar embaixo da foto.\n'
      '4) Barra de navegação na parte de baixo da tela.';
  /// Ver, o story (2 de 2).
  static const String instagramVerStory2 =
      'Visualizando o story de um amigo:\n'
      '1) Nome do amigo no alto à esquerda e menu de três pontinhos à direita.\n'
      '2) Foto ou vídeo do story com legenda e cartão de música no centro (o story avança sozinho).\n'
      '3) Campo "Enviar mensagem" embaixo e coração à direita para curtir — ou deslize para baixo para sair.';
  /// Ver, passo 2.
  static const String instagramVer2 =
      'Indo para os vídeos curtos (Reels):\n'
      '1) Faixa de stories dos amigos no alto da tela.\n'
      '2) Coração de avisos no canto superior direito.\n'
      '3) Botões de interação abaixo da foto do feed.\n'
      '4) Barra inferior: toque no segundo ícone (Reels) para assistir a vídeos curtos.';
  /// Ver, passo 3.
  static const String instagramVer3 =
      'Assistindo aos Reels no Instagram:\n'
      '1) Abas "Reels" e "Amigos" no topo (deslize o dedo para cima para ver o próximo vídeo).\n'
      '2) Coluna à direita: coração para curtir, balão para comentar e aviãozinho para compartilhar.\n'
      '3) Nome do perfil criador embaixo com o botão "Seguir".';

  /// Story, passo 1.
  static const String instagramStory1 =
      'Começando a publicar um story:\n'
      '1) Toque na sua foto "Seu story", no alto à esquerda, onde há o sinal de mais (+) azul.\n'
      '2) Coração de notificações no canto superior direito.\n'
      '3) Botões de curtir, comentar e enviar abaixo da publicação.\n'
      '4) Barra inferior de navegação do aplicativo.';
  /// Story, passo 2.
  static const String instagramStory2 =
      'Tela "Adicionar ao story":\n'
      '1) Botões no alto para usar Modelos, Música ou Colagem.\n'
      '2) Quadro da câmera à esquerda caso queira tirar uma foto agora.\n'
      '3) Galeria "Recentes": toque na foto que você quer mostrar no seu story.';
  /// Story, passo 3.
  static const String instagramStory3 =
      'Pronto para publicar seu story:\n'
      '1) Ferramentas à direita para escrever texto (Aa), colocar figurinhas ou música.\n'
      '2) Toque no botão "Seu story", embaixo à esquerda, para publicar por 24 horas.\n'
      '3) Opção "Amigos Próximos" e seta azul caso queira escolher quem vai ver.';

  /// Avisos, passo 1.
  static const String instagramAvisos1 =
      'Onde ficam os avisos na tela inicial:\n'
      '1) Faixa superior com o seu story e o dos amigos.\n'
      '2) Toque no coração, no alto à direita, para ver quem curtiu ou começou a seguir você.\n'
      '3) Botões abaixo da foto no feed.\n'
      '4) Barra inferior com os atalhos do Instagram.';
  /// Avisos, passo 2.
  static const String instagramAvisos2 =
      'Tela de Notificações do Instagram:\n'
      '1) Avisos recentes mostrando quem curtiu suas fotos ou começou a seguir você.\n'
      '2) Sugestão com botão azul "Seguir" — confira sempre se você conhece mesmo a pessoa antes de aceitar.\n'
      '3) Histórico de avisos anteriores e dos últimos 30 dias.';
  /// Avisos, passo 3.
  static const String instagramAvisos3 =
      'Abrindo suas conversas na tela inicial:\n'
      '1) Stories no alto da página inicial.\n'
      '2) Coração de notificações no topo à direita.\n'
      '3) Botões de curtir e comentar na foto.\n'
      '4) Na barra inferior, toque no aviãozinho de papel, no meio, para abrir suas mensagens.';
  /// Avisos, passo 4.
  static const String instagramAvisos4 =
      'Caixa de Mensagens do Instagram:\n'
      '1) Barra de pesquisa no alto para procurar uma conversa pelo nome.\n'
      '2) Faixa com notas curtas deixadas pelos seus amigos.\n'
      '3) Lista "Mensagens": toque na conversa para ler (se alguém pedir dinheiro ou código, ligue para a pessoa antes).';

  /// Procurar, passo 1.
  static const String instagramProcurar1 =
      'Onde procurar pessoas na tela inicial:\n'
      '1) Faixa de stories no topo da tela.\n'
      '2) Coração de avisos no canto superior direito.\n'
      '3) Botões abaixo da foto principal.\n'
      '4) Na barra inferior, toque na lupa (segunda opção da direita) para abrir a busca.';
  /// Procurar, passo 2.
  static const String instagramProcurar2 =
      'Tela de busca e exploração:\n'
      '1) Toque na barra "Pesquisar" no alto da tela para digitar o nome de uma pessoa ou assunto.\n'
      '2) Grade abaixo com fotos e vídeos sugeridos sobre natureza, culinária, jardim e música.';
  /// Procurar, passo 3.
  static const String instagramProcurar3 =
      'Escolhendo um perfil na pesquisa:\n'
      '1) Barra no topo onde você digita o nome de quem procura.\n'
      '2) Lista "Recentes": toque sobre o nome ou foto para abrir o perfil, ou no "X" à direita para limpar.';

  /// Privada, passo 1.
  static const String instagramPrivada1 =
      'Abrindo o seu perfil na tela inicial:\n'
      '1) Stories no alto da tela.\n'
      '2) Coração de avisos no topo à direita.\n'
      '3) Botões embaixo da foto do feed.\n'
      '4) Na barra inferior, toque na sua foto, no canto direito, para abrir seu perfil.';
  /// Privada, passo 2.
  static const String instagramPrivada2 =
      'Tela do seu Perfil no Instagram:\n'
      '1) No topo, toque nas três linhas no canto direito para abrir as configurações da conta.\n'
      '2) Sua foto de perfil, número de publicações, seguidores e apresentação.\n'
      '3) Painel "Criar" caso queira publicar um novo Reel, Post ou Story.';
  /// Privada, passo 3.
  static const String instagramPrivada3 =
      'Tela "Configurações e atividade":\n'
      '1) Busca de ajustes e cartão "Conta Meta" com dados e segurança.\n'
      '2) Opções de itens salvos, arquivados, atividade e notificações.\n'
      '3) Toque em "Privacidade da conta", bem embaixo, para deixar sua conta privada só para quem você aceita.';

  /// Descrição da captura 1 do Instagram.
  static const String instagramCaptura1 =
      'Tela inicial do Instagram com quatro regiões numeradas: stories no alto, coração de avisos, botões da foto e barra inferior.';
  /// Descrição da captura 2 do Instagram.
  static const String instagramCaptura2 =
      'Vídeo nos Reels do Instagram com três áreas numeradas: topo, botões de curtir e comentar à direita e perfil criador embaixo.';
  /// Descrição da captura 3 do Instagram.
  static const String instagramCaptura3 =
      'Tela Adicionar ao story com três regiões numeradas: ferramentas no alto, câmera e grade de fotos recentes.';
  /// Descrição da captura 4 do Instagram.
  static const String instagramCaptura4 =
      'Tela de publicação do story com três marcações numeradas: ferramentas laterais, botão Seu story e Amigos Próximos.';
  /// Descrição da captura 5 do Instagram.
  static const String instagramCaptura5 =
      'Tela de Notificações do Instagram com três áreas numeradas destacando avisos recentes, botão Seguir e histórico.';
  /// Descrição da captura 6 do Instagram.
  static const String instagramCaptura6 =
      'Tela de Mensagens do Instagram com três regiões numeradas: barra de pesquisa, notas dos amigos e lista de conversas.';
  /// Descrição da captura 7 do Instagram.
  static const String instagramCaptura7 =
      'Tela de pesquisa do Instagram com duas áreas numeradas: barra Pesquisar no alto e grade de sugestões.';
  /// Descrição da captura 8 do Instagram.
  static const String instagramCaptura8 =
      'Tela de pesquisas recentes do Instagram com duas regiões numeradas: campo de busca e lista de perfis.';
  /// Descrição da captura 9 do Instagram.
  static const String instagramCaptura9 =
      'Perfil do Instagram com três áreas numeradas: barra superior com menu de três linhas, dados do perfil e painel Criar.';
  /// Descrição da captura 10 do Instagram.
  static const String instagramCaptura10 =
      'Tela Configurações e atividade do Instagram com três regiões numeradas até a opção Privacidade da conta embaixo.';
  /// Descrição da captura 11 do Instagram.
  static const String instagramCaptura11 =
      'Story aberto no Instagram com três áreas numeradas: nome do amigo no topo, imagem com música e barra Enviar mensagem.';

  // YouTube (T071 + Feature 016)
  /// Título do guia do YouTube.
  static const String tituloYoutube = 'Como assistir a vídeos no YouTube';
  /// Passo 1 do YouTube.
  static const String youtubePasso1 =
      'Tela inicial do YouTube:\n'
      '1) Capa e título do vídeo em destaque no alto — toque nele para assistir.\n'
      '2) Enquete interativa do canal no meio da tela para votar em novos temas.\n'
      '3) Barra inferior com Início, Shorts, criar (+), Inscrições e Você.';
  /// Descrição da captura do passo 1 do YouTube.
  static const String youtubeCaptura1 =
      'Tela inicial do YouTube com três regiões numeradas: vídeo em destaque, enquete do canal e barra inferior.';
  /// Passo 2 do YouTube.
  static const String youtubePasso2 =
      'Procurando vídeos e transmissões ao vivo:\n'
      '1) No alto à direita: transmitir na TV, sininho de avisos e lupa para pesquisar qualquer assunto.\n'
      '2) Faixa de filtros rápidos: Início, Inscrições, Música, Ao vivo e Mais.\n'
      '3) Vídeo com selo vermelho "AO VIVO" para ouvir ou assistir em tempo real.';
  /// Descrição da captura do passo 2 do YouTube.
  static const String youtubeCaptura2 =
      'Aba Ao vivo do YouTube com três áreas numeradas: lupa no topo, filtros de categoria e vídeo ao vivo.';
  /// Passo 3 do YouTube.
  static const String youtubePasso3 =
      'Vídeos curtos em tela cheia (Shorts):\n'
      '1) Lupa de busca e menu de três pontinhos no alto à direita.\n'
      '2) Botões laterais para curtir, ler comentários, salvar e compartilhar o vídeo.\n'
      '3) Nome do canal e botão "Inscrever-se" para acompanhar novos vídeos.\n'
      '4) Aba "Shorts" selecionada na barra inferior.';
  /// Descrição da captura do passo 3 do YouTube.
  static const String youtubeCaptura3 =
      'Tela Shorts do YouTube com quatro marcações numeradas: busca, botões laterais, botão Inscrever-se e aba Shorts.';
  /// Passo 4 do YouTube.
  static const String youtubePasso4 =
      'Canais que você acompanha (Inscrições):\n'
      '1) Aba "Inscrições" selecionada no alto da tela.\n'
      '2) Bolinhas com os canais que você segue e botão "Todos" à direita.\n'
      '3) Destaques "Mais relevantes" e vídeos novos publicados pelos seus canais.';
  /// Descrição da captura do passo 4 do YouTube.
  static const String youtubeCaptura4 =
      'Guia Inscrições do YouTube com três regiões numeradas: aba ativa, lista de canais e vídeos recentes.';
  /// Passo 5 do YouTube.
  static const String youtubePasso5 =
      'Sua área pessoal (aba "Você"):\n'
      '1) Seu nome, botão "Ver canal" e engrenagem de configurações no topo.\n'
      '2) Faixa "Histórico" para rever vídeos que você já assistiu.\n'
      '3) Seção "Biblioteca" com suas Playlists de músicas e vídeos salvos.\n'
      '4) Aba "Você" no canto inferior direito.';
  /// Descrição da captura do passo 5 do YouTube.
  static const String youtubeCaptura5 =
      'Aba Você do YouTube com quatro regiões numeradas: perfil, Histórico, Biblioteca de playlists e ícone inferior.';
  /// Passo 6 do YouTube.
  static const String youtubePasso6 =
      'Dentro da página de um canal:\n'
      '1) Foto, nome do canal, quantidade de inscritos e apresentação.\n'
      '2) Abas do canal para alternar entre Início, Vídeos, Shorts e Playlists.\n'
      '3) Vídeos recomendados "Para você" e lista completa de vídeos abaixo.';
  /// Descrição da captura do passo 6 do YouTube.
  static const String youtubeCaptura6 =
      'Página de canal no YouTube com três áreas numeradas: cabeçalho do canal, barra de abas e lista de vídeos.';
  /// Passo 7 do YouTube.
  static const String youtubePasso7 =
      'Explorando mais categorias no YouTube:\n'
      '1) Aba "Mais" selecionada na barra superior.\n'
      '2) Categorias para explorar Filmes, Paradas musicais, Jogos e Podcasts.\n'
      '3) Atalhos para outros serviços, como YouTube Music e YouTube Kids.';
  /// Descrição da captura do passo 7 do YouTube.
  static const String youtubeCaptura7 =
      'Menu Mais do YouTube com três regiões numeradas: aba Mais, categorias de conteúdo e aplicativos da família YouTube.';

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

  // Google Fotos (T072 + Feature 016)
  /// Título do guia do Google Fotos.
  static const String tituloGoogleFotos = 'Como rever suas fotos no Google Fotos';
  /// Passo 1 do Google Fotos.
  static const String googleFotosPasso1 =
      'Tela principal do Google Fotos:\n'
      '1) No alto: aviso de backup "Concluído", botão (+), sininho e sua inicial de perfil (U).\n'
      '2) Cartões de recordações ("Fim de tarde na praia", "Momentos em família").\n'
      '3) Grade com todas as suas fotos organizadas por data.\n'
      '4) Barra inferior com as abas Fotos, Álbuns, Criar e lupa de pesquisa.';
  /// Descrição da captura do passo 1 do Google Fotos.
  static const String googleFotosCaptura1 =
      'Tela principal do Google Fotos com quatro regiões numeradas: topo de backup, recordações, grade de fotos e barra inferior.';
  /// Passo 2 do Google Fotos.
  static const String googleFotosPasso2 =
      'Organizando suas fotos em Álbuns:\n'
      '1) Pastas "Fixados" (Câmera, Favoritas) e álbuns salvos "Neste dispositivo".\n'
      '2) Seção "Álbuns" com suas coleções por tema (Meu Jardim, Bichinhos, Receitas).\n'
      '3) Aba "Álbuns" selecionada no meio da barra inferior.';
  /// Descrição da captura do passo 2 do Google Fotos.
  static const String googleFotosCaptura2 =
      'Tela Álbuns do Google Fotos com três áreas numeradas: pastas do aparelho, álbuns temáticos e aba Álbuns.';
  /// Passo 3 do Google Fotos.
  static const String googleFotosPasso3 =
      'Criando lembranças na aba Criar:\n'
      '1) Sugestões prontas em "Novidade para você" com botão "Salvar".\n'
      '2) Ferramentas para montar "Colagem", "Vídeo de destaque" ou "Remix de foto".\n'
      '3) Aba "Criar" destacada à direita na barra inferior.';
  /// Descrição da captura do passo 3 do Google Fotos.
  static const String googleFotosCaptura3 =
      'Tela Criar do Google Fotos com três regiões numeradas: novidades sugeridas, ferramentas de colagem e aba Criar.';
  /// Passo 4 do Google Fotos.
  static const String googleFotosPasso4 =
      'Conferindo sua conta e cópia de segurança:\n'
      '1) Seu nome, e-mail e opção "Gerenciar sua Conta do Google".\n'
      '2) Medidor de espaço usado na nuvem e botão "Liberar espaço".\n'
      '3) Aviso verde "Backup concluído" confirmando que suas fotos estão guardadas com segurança.\n'
      '4) Atalhos para "Configurações do Fotos" e "Ajuda e feedback".';
  /// Descrição da captura do passo 4 do Google Fotos.
  static const String googleFotosCaptura4 =
      'Painel da conta no Google Fotos com quatro regiões numeradas: perfil, armazenamento, Backup concluído e configurações.';

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

  // TikTok (T070 + Feature 016)
  /// Título do guia do TikTok.
  static const String tituloTiktok = 'Como assistir e buscar vídeos no TikTok';
  /// Passo 1 do TikTok.
  static const String tiktokPasso1 =
      'Tela inicial "Para você" do TikTok:\n'
      '1) Abas no alto (Explorar, Dicas, Seguindo, Loja, Para você) e lupa de busca à direita.\n'
      '2) Coluna direita: perfil do criador, coração para curtir, balão de comentários, bandeirinha para salvar e seta para compartilhar.\n'
      '3) Nome do perfil e descrição do vídeo embaixo.\n'
      '4) Barra inferior: Início, Amigos, botão (+), Mensagens e Perfil.';
  /// Descrição da captura do passo 1 do TikTok.
  static const String tiktokCaptura1 =
      'Tela inicial do TikTok com quatro regiões numeradas: abas superiores, botões de interação à direita, legenda e barra inferior.';
  /// Passo 2 do TikTok.
  static const String tiktokPasso2 =
      'Aba "Amigos" do TikTok:\n'
      '1) No alto: botão para adicionar story (+), título "Amigos" e lupa de pesquisa.\n'
      '2) Botões laterais à direita para curtir, comentar, salvar ou compartilhar o vídeo.\n'
      '3) Aba "Amigos" selecionada na barra inferior para ver vídeos de quem você conhece.';
  /// Descrição da captura do passo 2 do TikTok.
  static const String tiktokCaptura2 =
      'Aba Amigos do TikTok com três áreas numeradas: topo com busca, coluna lateral de interação e aba Amigos.';
  /// Passo 3 do TikTok.
  static const String tiktokPasso3 =
      'Tela da Câmera (botão "+"):\n'
      '1) No alto: botão "X" para fechar, "Adicionar som" no meio e botão de virar a câmera à direita.\n'
      '2) Seletor de duração (10 min, 60 s, 15 s) e modo FOTO ou TEXTO.\n'
      '3) Botão redondo branco central para tirar a foto ou começar a gravar.';
  /// Descrição da captura do passo 3 do TikTok.
  static const String tiktokCaptura3 =
      'Tela da câmera do TikTok com três regiões numeradas: controles superiores, seletor de modo e botão disparador central.';
  /// Passo 4 do TikTok.
  static const String tiktokPasso4 =
      'Aba "Loja" do TikTok:\n'
      '1) Aba "Loja" selecionada no alto e ícone do carrinho de compras.\n'
      '2) Barra de busca com o botão preto "Procurar" para achar um produto.\n'
      '3) Categorias e vitrine de produtos com fotos, preços e avaliações.';
  /// Descrição da captura do passo 4 do TikTok.
  static const String tiktokCaptura4 =
      'Guia Loja do TikTok com três áreas numeradas: aba Loja no topo, barra Procurar e vitrine de ofertas.';
  /// Passo 5 do TikTok.
  static const String tiktokPasso5 =
      'Caixa de "Mensagens" do TikTok:\n'
      '1) Topo com ícone de adicionar amigos, título "Mensagens" e lupa.\n'
      '2) Faixa de stories e recados curtos dos seus contatos.\n'
      '3) Avisos de novos seguidores e lista de conversas com amigos.\n'
      '4) Aba "Mensagens" destacada na barra inferior.';
  /// Descrição da captura do passo 5 do TikTok.
  static const String tiktokCaptura5 =
      'Caixa de Mensagens do TikTok com quatro regiões numeradas: topo, stories, lista de conversas e aba Mensagens.';
  /// Passo 6 do TikTok.
  static const String tiktokPasso6 =
      'Seu "Perfil" no TikTok:\n'
      '1) No alto: editar perfil, encontrar amigos e menu de três tracinhos.\n'
      '2) Seu nome, foto de perfil e números de Seguindo, Seguidores e Curtidas.\n'
      '3) Abas para ver seus vídeos publicados, privados, salvos e curtidos.\n'
      '4) Aba "Perfil" selecionada no canto inferior direito.';
  /// Descrição da captura do passo 6 do TikTok.
  static const String tiktokCaptura6 =
      'Tela de Perfil do TikTok com quatro áreas numeradas: barra superior, dados do perfil, abas de vídeos e ícone Perfil.';

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

  // Meu INSS (T079 + Feature 016 Seções)
  /// Título do guia do Meu INSS.
  static const String tituloMeuInss = 'Como consultar benefícios no Meu INSS';
  /// Título da seção Entrar do Meu INSS.
  static const String meuInssSecaoEntrar = 'Entrar e autorizar o acesso';
  /// Subtítulo da seção Entrar do Meu INSS.
  static const String meuInssSecaoEntrarSubtitulo =
      'Como avançar na abertura e entrar com a conta gov.br.';
  /// Passo 1 de Entrar no Meu INSS.
  static const String meuInssEntrar1 =
      'Tela de boas-vindas do Meu INSS:\n'
      '1) Resumo dos serviços disponíveis: Pedidos, Agendamentos, Extratos e Aposentadoria.\n'
      '2) Toque no botão "Avançar", bem embaixo, para continuar.';
  /// Passo 2 de Entrar no Meu INSS.
  static const String meuInssEntrar2 =
      'Política de Privacidade do Meu INSS:\n'
      '1) Explicação sobre como o aplicativo protege e utiliza seus dados pessoais.\n'
      '2) Botões na base: toque no botão azul "Aceitar", bem embaixo, para prosseguir.';
  /// Passo 3 de Entrar no Meu INSS.
  static const String meuInssEntrar3 =
      'Tela de acesso ao Meu INSS:\n'
      '1) Toque no botão azul "Entrar com gov.br" para acessar todos os seus benefícios.\n'
      '2) Área "Serviços sem senha" abaixo, com Novo Pedido, Taxas de Consignado e Calendário de Pagamento.';
  /// Passo 4 de Entrar no Meu INSS.
  static const String meuInssEntrar4 =
      'Autorização da conta gov.br:\n'
      '1) Lista de dados da sua conta gov.br que serão compartilhados com o Meu INSS.\n'
      '2) Toque no botão azul "Autorizar", embaixo à direita, para confirmar.';
  /// Passo 5 de Entrar no Meu INSS.
  static const String meuInssEntrar5 =
      'Acesso com Biometria (digital):\n'
      '1) Pergunta se você deseja entrar no Meu INSS usando a digital cadastrada no celular.\n'
      '2) Toque em "Sim" (azul embaixo) para ativar a digital ou em "Não" para usar só a senha.';
  /// Passo 6 de Entrar no Meu INSS.
  static const String meuInssEntrar6 =
      'Notificações no celular:\n'
      '1) Pergunta se você quer receber avisos sobre seus pedidos e perícias no aparelho.\n'
      '2) Toque em "Sim" (azul embaixo) para receber os avisos ou em "Não" para pular.';
  /// Título da seção Início e Busca do Meu INSS.
  static const String meuInssSecaoInicio = 'Tela inicial, busca e letra';
  /// Subtítulo da seção Início e Busca do Meu INSS.
  static const String meuInssSecaoInicioSubtitulo =
      'Onde achar serviços, avisos e o ajuste de tamanho da fonte.';
  /// Passo 1 de Início e Busca no Meu INSS.
  static const String meuInssInicio1 =
      'Tela inicial do Meu INSS:\n'
      '1) Barra azul no topo: menu (três tracinhos), lupa de busca, sininho de avisos e seu perfil.\n'
      '2) Cartões em "Serviços para você": Extratos, Contribuições (CNIS), Benefícios por Incapacidade, Novo Pedido e Mais Serviços.\n'
      '3) Bloco "Precisa de ajuda?" com a assistente virtual Helô e outros canais.';
  /// Passo 2 de Início e Busca no Meu INSS.
  static const String meuInssInicio2 =
      'Menu lateral completo do Meu INSS:\n'
      '1) Atalhos rápidos para Início, Destaques, Novo Pedido e Consultar Pedidos.\n'
      '2) Categorias de Benefícios, Atualização, Extratos e Comprovantes e Cumprimento de Exigência.\n'
      '3) Categorias de Cadastro e Contribuições, Certidão (CTC), Recurso e Outros Serviços.';
  /// Passo 3 de Início e Busca no Meu INSS.
  static const String meuInssInicio3 =
      'Tela "Buscar Serviço":\n'
      '1) Barra "Do que você precisa?": digite o nome do serviço ou toque no microfone à direita.\n'
      '2) Lista de serviços abaixo: toque no item desejado para abrir.';
  /// Passo 4 de Início e Busca no Meu INSS.
  static const String meuInssInicio4 =
      'Tela de "Notificações" do Meu INSS:\n'
      '1) Lista de avisos oficiais recebidos, como informações sobre Prova de Vida e agências.\n'
      '2) Botões "Voltar" e "Configurar Notificações" na parte inferior.';
  /// Passo 5 de Início e Busca no Meu INSS.
  static const String meuInssInicio5 =
      'Tela "Meu Perfil" e tamanho da letra:\n'
      '1) Seu nome e CPF identificados no topo.\n'
      '2) Opções Nome de Exibição, Forma de Acesso, Notificações e Aparência da Tela.\n'
      '3) Toque em "Tamanho da Fonte" (A+) para deixar as letras maiores, ou em "Ajuda".\n'
      '4) Botão "Sair do Meu INSS" na base da tela.';
  /// Título da seção Extratos e Pedidos do Meu INSS.
  static const String meuInssSecaoExtratos = 'Extratos e novos pedidos';
  /// Subtítulo da seção Extratos e Pedidos do Meu INSS.
  static const String meuInssSecaoExtratosSubtitulo =
      'Como baixar o CNIS e acompanhar pedidos ou benefícios.';
  /// Passo 1 de Extratos e Pedidos no Meu INSS.
  static const String meuInssExtratos1 =
      'Tela "Extratos e Comprovantes":\n'
      '1) Campo "Do que você precisa?" para filtrar um documento pelo nome.\n'
      '2) Categorias "Extratos", "Comprovantes" e "Outros Documentos" — toque para abrir.\n'
      '3) Botão azul "Voltar" no rodapé.';
  /// Passo 2 de Extratos e Pedidos no Meu INSS.
  static const String meuInssExtratos2 =
      'Extrato de Contribuições (CNIS):\n'
      '1) "Lista de vínculo(s)" mostrando as empresas e datas trabalhadas.\n'
      '2) "Legenda de Indicadores" explicando as siglas do documento.\n'
      '3) Toque no botão azul "Baixar Documento", bem embaixo, para salvar o PDF.';
  /// Passo 3 de Extratos e Pedidos no Meu INSS.
  static const String meuInssExtratos3 =
      'Tela "Benefícios por Incapacidade":\n'
      '1) Barra de busca rápida no alto da lista.\n'
      '2) Opções para "Pedir Novo Benefício por Incapacidade", "Prorrogar", "Reanálise" ou "Revisar".\n'
      '3) Opções de "Alta a Pedido", "Auxílio-Acidente", "Resultado", "Laudo Médico" e "Consultar Pedidos".';
  /// Passo 4 de Extratos e Pedidos no Meu INSS.
  static const String meuInssExtratos4 =
      'Explicação antes de concluir o pedido:\n'
      '1) Quadro com as orientações e requisitos necessários para solicitar o benefício.\n'
      '2) Botões na base: toque no botão azul "Avançar" para seguir ou em "Voltar".';
  /// Passo 5 de Extratos e Pedidos no Meu INSS.
  static const String meuInssExtratos5 =
      'Tela "Novo Pedido":\n'
      '1) Pedidos mais frequentes: Empréstimo Consignado, Benefício por Incapacidade, Salário-Maternidade e Novo Benefício.\n'
      '2) Se não achou o que procura, toque no botão azul "Todos os Serviços", bem embaixo.';
  /// Título da seção Mais Serviços e Ajuda do Meu INSS.
  static const String meuInssSecaoAjuda = 'Mais serviços e ajuda';
  /// Subtítulo da seção Mais Serviços e Ajuda do Meu INSS.
  static const String meuInssSecaoAjudaSubtitulo =
      'Outros atalhos, assistente Helô e telefone oficial 135.';
  /// Passo 1 de Mais Serviços e Ajuda no Meu INSS.
  static const String meuInssAjuda1 =
      'Grade completa em "Mais Serviços":\n'
      '1) Barra "Do que você precisa?" para pesquisar qualquer serviço.\n'
      '2) Bloco "Destaques": Simular Aposentadoria, Prova de Vida, Carteira do Beneficiário, Meus Benefícios e Calendário de Pagamento.\n'
      '3) Bloco "Benefícios": Aposentadorias, Incapacidade, Assistenciais e Salário-Maternidade.';
  /// Passo 2 de Mais Serviços e Ajuda no Meu INSS.
  static const String meuInssAjuda2 =
      'Atendimento com a assistente virtual Helô:\n'
      '1) Barra azul "Chat" com botão de som à esquerda e "X" à direita para fechar.\n'
      '2) Mensagem da Helô e botão azul "Iniciar Atendimento" para tirar dúvidas na hora.';
  /// Passo 3 de Mais Serviços e Ajuda no Meu INSS.
  static const String meuInssAjuda3 =
      'Canais oficiais na tela "Ajuda":\n'
      '1) "Perguntas Frequentes" e "Assistente Virtual, Helô".\n'
      '2) "Ligue INSS (135)" para falar gratuitamente por telefone com a central oficial.\n'
      '3) "Encontre uma Agência" (endereço mais próximo) e "Ouvidoria (Fala.BR)".\n'
      '4) Botão azul "Voltar" na parte inferior.';
  /// Descrição da captura 1 do Meu INSS.
  static const String meuInssCaptura1 =
      'Tela de boas-vindas do Meu INSS com duas regiões numeradas: lista de serviços e botão Avançar.';
  /// Descrição da captura 2 do Meu INSS.
  static const String meuInssCaptura2 =
      'Política de Privacidade do Meu INSS com duas áreas numeradas: texto explicativo e botões Sair e Aceitar.';
  /// Descrição da captura 3 do Meu INSS.
  static const String meuInssCaptura3 =
      'Tela de entrada do Meu INSS com duas regiões numeradas: botão Entrar com gov.br e Serviços sem senha.';
  /// Descrição da captura 4 do Meu INSS.
  static const String meuInssCaptura4 =
      'Tela de autorização gov.br com duas áreas numeradas: dados compartilhados e botões Negar e Autorizar.';
  /// Descrição da captura 5 do Meu INSS.
  static const String meuInssCaptura5 =
      'Tela de acesso com biometria do Meu INSS com duas regiões numeradas: pergunta central e botões Não e Sim.';
  /// Descrição da captura 6 do Meu INSS.
  static const String meuInssCaptura6 =
      'Tela de notificações no celular do Meu INSS com duas áreas numeradas: aviso central e botões Não e Sim.';
  /// Descrição da captura 7 do Meu INSS.
  static const String meuInssCaptura7 =
      'Tela inicial do Meu INSS com três regiões numeradas: barra azul superior, Serviços para você e ajuda da Helô.';
  /// Descrição da captura 8 do Meu INSS.
  static const String meuInssCaptura8 =
      'Janela da assistente Helô aberta com duas áreas numeradas: cabeçalho do chat e botão Iniciar Atendimento.';
  /// Descrição da captura 9 do Meu INSS.
  static const String meuInssCaptura9 =
      'Menu lateral do Meu INSS dividido em três blocos numerados de serviços e categorias.';
  /// Descrição da captura 10 do Meu INSS.
  static const String meuInssCaptura10 =
      'Tela Buscar Serviço do Meu INSS com duas regiões numeradas: barra de pesquisa e lista de resultados.';
  /// Descrição da captura 11 do Meu INSS.
  static const String meuInssCaptura11 =
      'Tela de Notificações do Meu INSS com duas áreas numeradas: lista de avisos e botão Configurar Notificações.';
  /// Descrição da captura 12 do Meu INSS.
  static const String meuInssCaptura12 =
      'Tela Meu Perfil do Meu INSS com quatro regiões numeradas destacando dados, Tamanho da Fonte e Sair.';
  /// Descrição da captura 13 do Meu INSS.
  static const String meuInssCaptura13 =
      'Tela Extratos e Comprovantes do Meu INSS com três áreas numeradas: busca, categorias e botão Voltar.';
  /// Descrição da captura 14 do Meu INSS.
  static const String meuInssCaptura14 =
      'Extrato de Contribuições CNIS com três regiões numeradas: lista de vínculos, legenda e botão Baixar Documento.';
  /// Descrição da captura 15 do Meu INSS.
  static const String meuInssCaptura15 =
      'Tela explicativa de benefício no Meu INSS com duas áreas numeradas: regras de atenção e botões Voltar e Avançar.';
  /// Descrição da captura 16 do Meu INSS.
  static const String meuInssCaptura16 =
      'Tela Benefícios por Incapacidade com três regiões numeradas: busca, novos pedidos e acompanhamento.';
  /// Descrição da captura 17 do Meu INSS.
  static const String meuInssCaptura17 =
      'Tela Novo Pedido do Meu INSS com duas áreas numeradas: lista de pedidos e botão Todos os Serviços.';
  /// Descrição da captura 18 do Meu INSS.
  static const String meuInssCaptura18 =
      'Tela Mais Serviços do Meu INSS com três regiões numeradas: pesquisa, Destaques e Benefícios.';
  /// Descrição da captura 19 do Meu INSS.
  static const String meuInssCaptura19 =
      'Tela Ajuda do Meu INSS com quatro áreas numeradas: perguntas e Helô, telefone 135, agências e botão Voltar.';

  // e-Título (T081; refeito em 2026-11-12 com as capturas reais: entrar com a
  // biometria e um passeio pelas abas)
  /// Título do guia do e-Título.
  static const String tituloETitulo = 'Como usar o e-Título';
  /// Passo 1 do e-Título.
  static const String eTituloPasso1 =
      'Tela de entrada do e-Título:\n'
      '1) Sua foto, opção "Apagar meus dados" e chave "Biometria" ligada para entrar com a digital.\n'
      '2) Botão "Leia um boletim de urna" para conferência nas eleições.\n'
      '3) Toque no botão laranja "Entrar com biometria", bem embaixo, para acessar.';
  /// Descrição da captura do passo 1 do e-Título.
  static const String eTituloCaptura1 =
      'Tela de entrada do e-Título com três regiões numeradas: foto e chave Biometria, boletim de urna e botão Entrar com biometria.';
  /// Passo 2 do e-Título.
  static const String eTituloPasso2 =
      'Seu documento digital no e-Título:\n'
      '1) Foto, seu nome completo, número do título e aviso "BIOMETRIA COLETADA".\n'
      '2) Dados de Data de nascimento, Zona, Seção, Município/UF e Filiação.\n'
      '3) Barra inferior: toque em "Onde votar" (segunda opção) para ver seu local de votação.';
  /// Descrição da captura do passo 2 do e-Título.
  static const String eTituloCaptura2 =
      'Documento digital do e-Título com três áreas numeradas: foto e número do título, zona e seção e barra inferior.';
  /// Passo 3 do e-Título.
  static const String eTituloPasso3 =
      'Aba "Onde votar":\n'
      '1) Mapa com o pino azul mostrando onde fica o seu local de votação.\n'
      '2) Cartão com a sua Seção, Zona, nome da escola, endereço e botão "VER ROTAS".\n'
      '3) Barra inferior: toque em "ChatVote", no meio, se quiser tirar dúvidas.';
  /// Descrição da captura do passo 3 do e-Título.
  static const String eTituloCaptura3 =
      'Tela Onde votar do e-Título com três regiões numeradas: mapa, cartão com escola e endereço e barra inferior.';
  /// Passo 4 do e-Título.
  static const String eTituloPasso4 =
      'Tirando dúvidas no "ChatVote":\n'
      '1) Mensagem de boas-vindas do assistente virtual da Justiça Eleitoral.\n'
      '2) Campo "Digite a sua mensagem..." e botão redondo amarelo à direita para enviar sua pergunta.\n'
      '3) Aba "Notificações" (sininho) na barra inferior para ver os avisos oficiais.';
  /// Descrição da captura do passo 4 do e-Título.
  static const String eTituloCaptura4 =
      'Tela do ChatVote no e-Título com três áreas numeradas: mensagem de boas-vindas, campo de pergunta e aba Notificações.';
  /// Passo 5 do e-Título.
  static const String eTituloPasso5 =
      'Aba "Notificações" do e-Título:\n'
      '1) Lista de comunicados e lembretes enviados pela Justiça Eleitoral.\n'
      '2) Toque na aba "Mais opções", no canto inferior direito, para emitir certidões e consultar seu título.';
  /// Descrição da captura do passo 5 do e-Título.
  static const String eTituloCaptura5 =
      'Tela de Notificações do e-Título com duas regiões numeradas: avisos da Justiça Eleitoral e aba Mais opções.';
  /// Passo 6 do e-Título.
  static const String eTituloPasso6 =
      'Certidões e situação na aba "Mais opções":\n'
      '1) Bloco "Certidões": emita grátis a Certidão de Quitação Eleitoral, Crimes Eleitorais ou Trabalho Eleitoral.\n'
      '2) "Consultar Situação Eleitoral" (para ver se o título está em dia) e "Acompanhar Solicitação".\n'
      '3) "Justificativa de Ausência" e "Imprimir Título Eleitoral" para gerar o PDF.';
  /// Descrição da captura do passo 6 do e-Título.
  static const String eTituloCaptura6 =
      'Tela Mais opções do e-Título com três blocos numerados: Certidões, Atendimento ao Eleitor e Justificativa e impressão.';

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
      'Tela inicial do aplicativo FGTS:\n'
      '1) Logotipo oficial da CAIXA e do FGTS.\n'
      '2) Toque no botão laranja "Entrar no aplicativo" para começar.\n'
      '3) Link informativo sobre como o FGTS é aplicado.';
  /// Entrar, passo 2.
  static const String fgtsEntrar2 =
      'Identificação no Login Caixa:\n'
      '1) Toque no campo "CPF" e digite os 11 números do seu documento.\n'
      '2) Toque no botão laranja "Próximo" (na tela seguinte, digite sua senha apenas no app oficial da Caixa).\n'
      '3) Links "Cadastre-se" (para primeiro acesso) e "Preciso de ajuda".';
  /// Entrar, passo 3.
  static const String fgtsEntrar3 =
      'Termos e condições de uso do FGTS:\n'
      '1) Texto do contrato de utilização do aplicativo.\n'
      '2) Marque a caixinha "Li e aceito os termos e condições".\n'
      '3) Toque no botão "Continuar", bem embaixo, para prosseguir.';
  /// Entrar, passo 4.
  static const String fgtsEntrar4 =
      'Tela "Vamos começar?":\n'
      '1) Campo "Digite aqui" caso queira informar um apelido para o aplicativo.\n'
      '2) Botões embaixo: toque em "Cadastrar nome e continuar" ou em "Pular".';
  /// Entrar, passo 5.
  static const String fgtsEntrar5 =
      'Tela de avisos do FGTS:\n'
      '1) Explicação sobre as notificações gratuitas de depósitos e saques do seu FGTS.\n'
      '2) Toque no botão laranja "Ativar notificações" ou em "Agora não" para concluir a entrada.';

  /// Saldo e saque, passo 1.
  static const String fgtsSaque1 =
      'Página principal do FGTS (ver saldo):\n'
      '1) Em "SALDO TOTAL", toque em "Toque para exibir o saldo" no alto para mostrar o valor (olhe num lugar seguro).\n'
      '2) Cartão "Resumo do seu FGTS" e opção "Confira as suas contas FGTS".\n'
      '3) Atalhos para Saque digital, Conta bancária, Sistemática de saque e Informações úteis.\n'
      '4) Barra inferior: Principal, Saques, Meus dados e Mais.';
  /// Saldo e saque, passo 2.
  static const String fgtsSaque2 =
      'Indo para a área de Saques:\n'
      '1) Botão de exibir ou ocultar o saldo total no alto.\n'
      '2) Cartão central com o resumo das suas contas do FGTS.\n'
      '3) Atalhos rápidos em cartões coloridos.\n'
      '4) Na barra inferior, toque na segunda opção, "Saques", para ver as modalidades.';
  /// Saldo e saque, passo 3.
  static const String fgtsSaque3 =
      'Tela "Tudo sobre saques FGTS":\n'
      '1) Toque em "Solicitar saque" para pedir a liberação de valores previstos em lei.\n'
      '2) Opção "Acompanhar saques" para verificar pedidos já feitos.\n'
      '3) Aba "Saques" selecionada na barra inferior.';
  /// Saldo e saque, passo 4.
  static const String fgtsSaque4 =
      'Tela "Selecione o motivo do saque":\n'
      '1) Opções "Doença Grave" e "Falecimento do Trabalhador".\n'
      '2) Opção "Calamidade Pública" com regras e limite de valor.\n'
      '3) Opção "Aposentadoria" — toque no seu motivo para ver os documentos necessários.';

  /// Conta bancária, passo 1.
  static const String fgtsConta1 =
      'Abrindo "Meus dados" na tela principal:\n'
      '1) Saldo total do FGTS no topo da tela.\n'
      '2) Resumo das suas contas vinculadas.\n'
      '3) Cartões de atalho rápido para conta bancária e saques.\n'
      '4) Na barra inferior, toque em "Meus dados" (terceira opção) para gerenciar sua conta.';
  /// Conta bancária, passo 2.
  static const String fgtsConta2 =
      'Tela "Meus dados" do FGTS:\n'
      '1) Opções "Perfil" (dados pessoais e endereço) e "Notificações do FGTS".\n'
      '2) Toque em "Conta bancária" para escolher o banco que recebe os valores do seu FGTS.\n'
      '3) Opção "Termos e condições" do aplicativo.';
  /// Conta bancária, passo 3.
  static const String fgtsConta3 =
      'Tela "Minha conta bancária":\n'
      '1) Quadro mostrando a conta bancária cadastrada atualmente.\n'
      '2) Botão laranja "Alterar conta bancária" (nunca troque a pedido de ligações: faça só por vontade própria no app oficial).\n'
      '3) Botão "Excluir conta bancária" logo abaixo.';

  /// Saque-Aniversário, passo 1.
  static const String fgtsAniversario1 =
      'Abrindo o menu "Mais" na tela principal:\n'
      '1) Área do saldo total no alto da tela.\n'
      '2) Cartão de resumo e contas do FGTS.\n'
      '3) Atalhos rápidos na parte inferior da página.\n'
      '4) Na barra inferior, toque em "Mais", no canto direito, para ver outras configurações.';
  /// Saque-Aniversário, passo 2.
  static const String fgtsAniversario2 =
      'Menu "Mais" do FGTS:\n'
      '1) "Informações úteis" e "Sistemática de saque" — toque em Sistemática de saque para ver sua modalidade.\n'
      '2) "Empréstimos Contratados", "Autorização de consulta" e "Ressarcimento PIS/PASEP".\n'
      '3) "Edital Convocação", "Ajuda" e botão "Sair do aplicativo".';
  /// Saque-Aniversário, passo 3.
  static const String fgtsAniversario3 =
      'Tela "Optar pelo Saque-Aniversário":\n'
      '1) Modalidade atual ("Saque-Rescisão"), explicação do Saque-Aniversário e link para simular valor.\n'
      '2) Quadro "O que muda se eu fizer a opção?": leia com atenção, pois quem opta pelo Saque-Aniversário e é demitido saca só a multa rescisória.';

  /// Descrição da captura 1 do FGTS.
  static const String fgtsCaptura1 =
      'Tela de boas-vindas do FGTS com três regiões numeradas: logotipo, botão Entrar no aplicativo e link informativo.';
  /// Descrição da captura 2 do FGTS.
  static const String fgtsCaptura2 =
      'Tela Login Caixa do FGTS com três áreas numeradas: campo CPF, botão Próximo e links de cadastro e ajuda.';
  /// Descrição da captura 3 do FGTS.
  static const String fgtsCaptura3 =
      'Termos e condições do FGTS com três regiões numeradas: contrato, caixa Li e aceito e botão Continuar.';
  /// Descrição da captura 4 do FGTS.
  static const String fgtsCaptura4 =
      'Tela Vamos começar do FGTS com duas áreas numeradas: campo de nome e botões Cadastrar e Pular.';
  /// Descrição da captura 5 do FGTS.
  static const String fgtsCaptura5 =
      'Tela de notificações do FGTS com duas regiões numeradas: explicação central e botões Ativar notificações e Agora não.';
  /// Descrição da captura 6 do FGTS.
  static const String fgtsCaptura6 =
      'Página principal do FGTS com quatro áreas numeradas: saldo total, resumo das contas, atalhos rápidos e barra inferior.';
  /// Descrição da captura 7 do FGTS.
  static const String fgtsCaptura7 =
      'Tela Saques do FGTS com três regiões numeradas: Solicitar saque, Acompanhar saques e aba Saques.';
  /// Descrição da captura 8 do FGTS.
  static const String fgtsCaptura8 =
      'Tela Selecione o motivo do saque do FGTS com três blocos numerados de modalidades de saque.';
  /// Descrição da captura 9 do FGTS.
  static const String fgtsCaptura9 =
      'Tela Meus dados do FGTS com três regiões numeradas: Perfil e notificações, Conta bancária e Termos.';
  /// Descrição da captura 10 do FGTS.
  static const String fgtsCaptura10 =
      'Tela Minha conta bancária do FGTS com três áreas numeradas: conta atual, botão Alterar conta e botão Excluir.';
  /// Descrição da captura 11 do FGTS.
  static const String fgtsCaptura11 =
      'Tela Mais do FGTS com três blocos numerados destacando Sistemática de saque, consultas e Ajuda.';
  /// Descrição da captura 12 do FGTS.
  static const String fgtsCaptura12 =
      'Tela Optar pelo Saque-Aniversário com duas regiões numeradas: resumo da modalidade e quadro O que muda se eu fizer a opção.';

  // Poupatempo (T081 + Feature 016 Seções)
  /// Título do guia do Poupatempo.
  static const String tituloPoupatempo = 'Como agendar serviços no Poupatempo';
  /// Título da seção Entrar e Serviços do Poupatempo.
  static const String poupatempoSecaoEntrar = 'Entrar e explorar serviços';
  /// Subtítulo da seção Entrar e Serviços do Poupatempo.
  static const String poupatempoSecaoEntrarSubtitulo =
      'Como entrar pelo gov.br e abrir as categorias iniciais.';
  /// Passo 1 de Entrar no Poupatempo.
  static const String poupatempoEntrar1 =
      'Tela de boas-vindas do Poupatempo:\n'
      '1) Logotipo oficial "poupatempo SP.GOV.BR" e saudação inicial.\n'
      '2) Toque no botão azul "Entrar com o gov.br" para acessar os serviços.';
  /// Passo 2 de Entrar no Poupatempo.
  static const String poupatempoEntrar2 =
      'Identificação por CPF no gov.br:\n'
      '1) Digite os 11 números do seu CPF no campo em branco.\n'
      '2) Toque no botão azul "Continuar" logo abaixo.\n'
      '3) Outras opções de entrada: seu banco, aplicativo gov.br ou certificado.';
  /// Passo 3 de Entrar no Poupatempo.
  static const String poupatempoEntrar3 =
      'Digitando sua senha oficial gov.br:\n'
      '1) Digite sua senha no campo "Digite sua senha atual" (use o olhinho à direita se quiser conferir).\n'
      '2) Toque no botão azul "Entrar" ou em "Cancelar".\n'
      '3) Link "Esqueci minha senha" caso precise recuperar o acesso.';
  /// Passo 4 de Entrar no Poupatempo.
  static const String poupatempoEntrar4 =
      'Tela inicial do Poupatempo:\n'
      '1) Cartão "Recomendados para você" com campanhas e avisos úteis.\n'
      '2) Fileira "Serviços mais acessados" (Carteira de Identidade - CIN e 2ª via).\n'
      '3) Barra inferior com Início, Agenda, Pesquisa, PagSP e Carteira.';
  /// Passo 5 de Entrar no Poupatempo.
  static const String poupatempoEntrar5 =
      'Grade de "Categorias disponíveis":\n'
      '1) Atalhos rápidos no topo e título "Categorias disponíveis".\n'
      '2) Cartões de Água e esgoto, Atendimento ao consumidor, CNH e veículos e Documentos pessoais.\n'
      '3) Cartões de Educação, Impostos, Moradia, Saúde e Trabalho e aposentadoria.';
  /// Título da seção Buscar, Agendar e Carteira do Poupatempo.
  static const String poupatempoSecaoAgenda = 'Buscar, agendar e documentos';
  /// Subtítulo da seção Buscar, Agendar e Carteira do Poupatempo.
  static const String poupatempoSecaoAgendaSubtitulo =
      'Como pesquisar, ver sua agenda mensal e abrir documentos.';
  /// Passo 1 de Agenda e Carteira no Poupatempo.
  static const String poupatempoAgenda1 =
      'Tela "Buscar" do Poupatempo:\n'
      '1) Barra "O que você está buscando?": escreva o nome do serviço e toque na lupa.\n'
      '2) Lista "Navegar por todas as categorias" logo abaixo.\n'
      '3) Aba "Pesquisa" selecionada no meio da barra inferior.';
  /// Passo 2 de Agenda e Carteira no Poupatempo.
  static const String poupatempoAgenda2 =
      'Tela de "Agendamento":\n'
      '1) Cartão "Agendar" para marcar dia e horário em um posto do Poupatempo.\n'
      '2) Cartão "Consultar" para conferir horários que você já agendou.\n'
      '3) Aba "Agenda" destacada na barra inferior.';
  /// Passo 3 de Agenda e Carteira no Poupatempo.
  static const String poupatempoAgenda3 =
      'Calendário da sua Agenda:\n'
      '1) Barra escura com o mês atual e setas (< e >) para mudar de mês.\n'
      '2) Calendário mensal mostrando os dias da semana.\n'
      '3) Seção "AGENDAMENTOS" informando os atendimentos marcados no mês.';
  /// Passo 4 de Agenda e Carteira no Poupatempo.
  static const String poupatempoAgenda4 =
      'Lista de "Serviços mais solicitados":\n'
      '1) Documentos pessoais: Renovar CNH, Carteira de Identidade (CIN) e Antecedentes criminais.\n'
      '2) Habilitação: CNH definitiva, atividade remunerada (EAR), 1ª habilitação e 2ª via.\n'
      '3) Veículos: Transferir propriedade, Licenciar veículo, 2ª via de documento e Comunicar venda.';
  /// Passo 5 de Agenda e Carteira no Poupatempo.
  static const String poupatempoAgenda5 =
      'Tela "Carteira digital" do Poupatempo:\n'
      '1) Cartão "Vale Dados" com botão "Habilitar" para gerenciar permissões.\n'
      '2) Cartão "Documentos" — toque nele para abrir seus documentos digitais.\n'
      '3) Aba "Carteira" selecionada no canto inferior direito.';
  /// Descrição da captura 1 do Poupatempo.
  static const String poupatempoCaptura1 =
      'Tela de boas-vindas do Poupatempo com duas áreas numeradas: logotipo oficial e botão Entrar com o gov.br.';
  /// Descrição da captura 2 do Poupatempo.
  static const String poupatempoCaptura2 =
      'Tela do gov.br no Poupatempo com três regiões numeradas: campo CPF, botão Continuar e outras opções.';
  /// Descrição da captura 3 do Poupatempo.
  static const String poupatempoCaptura3 =
      'Tela de senha do gov.br no Poupatempo com três áreas numeradas: campo de senha, botões Entrar e Cancelar e Esqueci minha senha.';
  /// Descrição da captura 4 do Poupatempo.
  static const String poupatempoCaptura4 =
      'Tela inicial do Poupatempo com três regiões numeradas: recomendados, Serviços mais acessados e barra inferior.';
  /// Descrição da captura 5 do Poupatempo.
  static const String poupatempoCaptura5 =
      'Grade de Categorias disponíveis do Poupatempo dividida em três áreas numeradas.';
  /// Descrição da captura 6 do Poupatempo.
  static const String poupatempoCaptura6 =
      'Tela Buscar do Poupatempo com três regiões numeradas: campo de busca, grade de categorias e aba Pesquisa.';
  /// Descrição da captura 7 do Poupatempo.
  static const String poupatempoCaptura7 =
      'Tela Agendamento do Poupatempo com três áreas numeradas: cartão Agendar, cartão Consultar e aba Agenda.';
  /// Descrição da captura 8 do Poupatempo.
  static const String poupatempoCaptura8 =
      'Calendário mensal da Agenda do Poupatempo com três regiões numeradas: seletor de mês, dias e lista de agendamentos.';
  /// Descrição da captura 9 do Poupatempo.
  static const String poupatempoCaptura9 =
      'Lista Serviços mais solicitados do Poupatempo dividida em três blocos numerados: documentos, CNH e veículos.';
  /// Descrição da captura 10 do Poupatempo.
  static const String poupatempoCaptura10 =
      'Tela Carteira digital do Poupatempo com três áreas numeradas: Vale Dados, cartão Documentos e aba Carteira.';

  // Carteira Digital (T082 + Feature 016 Seções)
  /// Título do guia da Carteira Digital.
  static const String tituloCarteiraDigital = 'Como acessar seus documentos na Carteira Digital';
  /// Título da seção Habilitação e Credencial da Carteira Digital.
  static const String carteiraDigitalSecaoCnh = 'Habilitação e credencial';
  /// Subtítulo da seção Habilitação e Credencial da Carteira Digital.
  static const String carteiraDigitalSecaoCnhSubtitulo =
      'Como abrir a CNH digital, serviços e credencial de estacionamento.';
  /// Passo 1 de CNH na Carteira Digital.
  static const String carteiraDigitalCnh1 =
      'Tela inicial da Carteira Digital de Trânsito:\n'
      '1) Barra superior: menu (três tracinhos), sininho de avisos e seu perfil.\n'
      '2) Cartão verde "CONDUTOR" — toque nele para abrir sua CNH e serviços.\n'
      '3) Cartão amarelo "VEÍCULOS" (CRLV) e cartão azul "INFRAÇÕES" (multas).\n'
      '4) Cartão "EDUCAÇÃO" com informações e cursos de trânsito.';
  /// Passo 2 de CNH na Carteira Digital.
  static const String carteiraDigitalCnh2 =
      'Menu lateral da Carteira Digital:\n'
      '1) Sua identificação com nome e CPF no topo.\n'
      '2) Atalhos para Central de Mensagens, Privacidade, Termo de Responsabilidade, Preferências e Tutorial.\n'
      '3) Opções "Assistente Virtual", "Sobre a CNH do Brasil" e "Sair da Conta".';
  /// Passo 3 de CNH na Carteira Digital.
  static const String carteiraDigitalCnh3 =
      'Painel "CONDUTOR":\n'
      '1) Quadro "Informações do Condutor" com categoria, validade e selo Bom Condutor.\n'
      '2) Botão "CNH" (toque para abrir o documento digital) e "SERVIÇOS PARA CNH".\n'
      '3) Botões "CADASTRO POSITIVO" e "CREDENCIAL DE ESTACIONAMENTO".';
  /// Passo 4 de CNH na Carteira Digital.
  static const String carteiraDigitalCnh4 =
      'Sua "HABILITAÇÃO" (CNH Digital):\n'
      '1) Aviso superior sobre verificação do QR Code com o aplicativo Vio.\n'
      '2) Documento completo da CNH Digital — deslize para o lado para ver o verso e o QR Code.\n'
      '3) Indicador de páginas e botão "Histórico de emissões da CNH" embaixo.';
  /// Passo 5 de CNH na Carteira Digital.
  static const String carteiraDigitalCnh5 =
      'Tela "Serviços para CNH":\n'
      '1) Resumo "Informações da Habilitação" com categoria, UF e data de validade.\n'
      '2) Botões "ALTERAÇÃO DE CATEGORIA" e "REINICIAR HABILITAÇÃO".\n'
      '3) Botões "EXAMES TOXICOLÓGICOS" e "CURSOS ESPECIALIZADOS".';
  /// Passo 6 de CNH na Carteira Digital.
  static const String carteiraDigitalCnh6 =
      'Tela "Credencial de Estacionamento":\n'
      '1) Explicação sobre a credencial de vaga preferencial e requisito de conta gov.br Prata ou Ouro.\n'
      '2) Opções para emitir a credencial de vaga preferencial conforme o seu perfil.\n'
      '3) Botões "Histórico de emissões" e "Consultar vínculo do veículo".';
  /// Título da seção Veículos e Infrações da Carteira Digital.
  static const String carteiraDigitalSecaoVeiculos = 'Veículos, infrações e bom condutor';
  /// Subtítulo da seção Veículos e Infrações da Carteira Digital.
  static const String carteiraDigitalSecaoVeiculosSubtitulo =
      'Como consultar seus veículos, multas e Cadastro Positivo.';
  /// Passo 1 de Veículos na Carteira Digital.
  static const String carteiraDigitalVeiculos1 =
      'Tela "VEÍCULOS":\n'
      '1) Cabeçalho com seta de voltar e horário da última atualização.\n'
      '2) Toque no botão azul "RECARREGAR LISTA DE VEÍCULOS" no centro para buscar carros no seu CPF.';
  /// Passo 2 de Veículos na Carteira Digital.
  static const String carteiraDigitalVeiculos2 =
      'Menu de "INFRAÇÕES":\n'
      '1) Toque em "Por Infrator" para consultar multas registradas no seu CPF.\n'
      '2) Toque em "Por Veículo" para consultar multas de um automóvel específico.';
  /// Passo 3 de Veículos na Carteira Digital.
  static const String carteiraDigitalVeiculos3 =
      'Lista de "Infrações por Infrator":\n'
      '1) Barra azul "Filtro ativo" e ícone de funil no alto à direita para filtrar datas.\n'
      '2) Faixa amarela "Aderir ao SNE" para receber avisos eletrônicos e descontos em multas.\n'
      '3) Área central informando se há ou não infrações registradas.';
  /// Passo 4 de Veículos na Carteira Digital.
  static const String carteiraDigitalVeiculos4 =
      'Tela "CADASTRO POSITIVO":\n'
      '1) Quadro "Informações do Cadastro Positivo" mostrando situação "Ativo" e selo Bom Condutor.\n'
      '2) Botões para ler o que é o cadastro e o "TERMO DE AUTORIZAÇÃO".\n'
      '3) Opções "Parceiros do Bom Condutor", "Excluir Autorização" e "Histórico".';
  /// Descrição da captura 1 da Carteira Digital.
  static const String carteiraDigitalCaptura1 =
      'Tela inicial da Carteira Digital com quatro regiões numeradas: topo, Condutor, Veículos e Infrações e Educação.';
  /// Descrição da captura 2 da Carteira Digital.
  static const String carteiraDigitalCaptura2 =
      'Menu lateral da Carteira Digital com três blocos numerados: identificação, preferências e saída.';
  /// Descrição da captura 3 da Carteira Digital.
  static const String carteiraDigitalCaptura3 =
      'Painel Condutor da Carteira Digital com três áreas numeradas: dados do condutor, CNH e serviços e credencial.';
  /// Descrição da captura 4 da Carteira Digital.
  static const String carteiraDigitalCaptura4 =
      'Tela da CNH Digital com três regiões numeradas: aviso Vio, documento da CNH e histórico de emissões.';
  /// Descrição da captura 5 da Carteira Digital.
  static const String carteiraDigitalCaptura5 =
      'Tela Serviços para CNH com três áreas numeradas: dados da habilitação, categoria e exames e cursos.';
  /// Descrição da captura 6 da Carteira Digital.
  static const String carteiraDigitalCaptura6 =
      'Tela Credencial de Estacionamento com três regiões numeradas: orientações, emissão da credencial e histórico.';
  /// Descrição da captura 7 da Carteira Digital.
  static const String carteiraDigitalCaptura7 =
      'Tela Veículos da Carteira Digital com duas áreas numeradas: cabeçalho e botão Recarregar Lista de Veículos.';
  /// Descrição da captura 8 da Carteira Digital.
  static const String carteiraDigitalCaptura8 =
      'Tela Infrações da Carteira Digital com duas opções numeradas: Por Infrator e Por Veículo.';
  /// Descrição da captura 9 da Carteira Digital.
  static const String carteiraDigitalCaptura9 =
      'Tela Infrações por Infrator com três regiões numeradas: filtro ativo, faixa Aderir ao SNE e resultado.';
  /// Descrição da captura 10 da Carteira Digital.
  static const String carteiraDigitalCaptura10 =
      'Tela Cadastro Positivo da Carteira Digital com três áreas numeradas: situação ativa, termos e opções.';

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

  // Carteira de Trabalho Digital (T082 + Feature 016 Seções)
  /// Título do guia da Carteira de Trabalho Digital.
  static const String tituloCarteiraDeTrabalho = 'Como acessar a Carteira de Trabalho Digital';
  /// Título da seção Entrar e Contratos da Carteira de Trabalho.
  static const String carteiraDeTrabalhoSecaoContratos = 'Entrar e ver contratos';
  /// Subtítulo da seção Entrar e Contratos da Carteira de Trabalho.
  static const String carteiraDeTrabalhoSecaoContratosSubtitulo =
      'Como conectar com o gov.br, consultar vínculos e gerar PDF.';
  /// Passo 1 de Contratos na Carteira de Trabalho.
  static const String carteiraDeTrabalhoContratos1 =
      'Tela inicial da Carteira de Trabalho Digital:\n'
      '1) Brasão da República e título oficial do aplicativo.\n'
      '2) Toque no botão azul "Entrar com gov.br", no meio da tela, para acessar.\n'
      '3) Quadro informativo de cursos de qualificação gratuitos na base.';
  /// Passo 2 de Contratos na Carteira de Trabalho.
  static const String carteiraDeTrabalhoContratos2 =
      'Autorização da conta gov.br:\n'
      '1) Lista dos dados básicos utilizados pelo serviço "CTPS Digital".\n'
      '2) Toque no botão azul "Autorizar", embaixo à direita, para confirmar o acesso.';
  /// Passo 3 de Contratos na Carteira de Trabalho.
  static const String carteiraDeTrabalhoContratos3 =
      'Painel inicial da Carteira de Trabalho:\n'
      '1) Cabeçalho azul com seu nome, CPF, sininho de avisos e olhinho para esconder dados.\n'
      '2) Cartões "Contratos de Trabalho Digitais" (toque para abrir) e "Outros vínculos".\n'
      '3) Cartão "Enviar Carteira de Trabalho Digital" para salvar ou compartilhar em PDF.\n'
      '4) Barra inferior: Carteira, Benefícios, Emprego, Empréstimos e Menu.';
  /// Passo 4 de Contratos na Carteira de Trabalho.
  static const String carteiraDeTrabalhoContratos4 =
      'Tela "Contratos de Trabalho Digitais":\n'
      '1) Topo com seta de voltar, resumo gráfico e botão azul redondo à direita para atualizar.\n'
      '2) Lista com os seus contratos registrados, mostrando cargo, empresa e datas.\n'
      '3) Botão "OUTROS VÍNCULOS DE TRABALHO" na parte inferior.';
  /// Passo 5 de Contratos na Carteira de Trabalho.
  static const String carteiraDeTrabalhoContratos5 =
      'Tela "Outros vínculos de trabalho":\n'
      '1) Mensagem central informando se existem outros vínculos nas bases integradas.\n'
      '2) Toque no botão azul "VOLTAR" para retornar à tela anterior.';
  /// Passo 6 de Contratos na Carteira de Trabalho.
  static const String carteiraDeTrabalhoContratos6 =
      'Tela "Enviar Carteira de Trabalho Digital":\n'
      '1) Escolha se quer enviar "Todos os dados da carteira" ou apenas "Dados Pessoais".\n'
      '2) Marque nas caixinhas quais "Contratos de Trabalho Digitais" deseja incluir.\n'
      '3) Toque no botão azul "GERAR PDF", bem embaixo, para salvar o documento.';
  /// Título da seção Benefícios e Menu da Carteira de Trabalho.
  static const String carteiraDeTrabalhoSecaoBeneficios = 'Benefícios, empréstimos e menu';
  /// Subtítulo da seção Benefícios e Menu da Carteira de Trabalho.
  static const String carteiraDeTrabalhoSecaoBeneficiosSubtitulo =
      'Onde consultar Abono Salarial, Seguro-Desemprego e opções do menu.';
  /// Passo 1 de Benefícios na Carteira de Trabalho.
  static const String carteiraDeTrabalhoBeneficios1 =
      'Aba "Benefícios" da Carteira de Trabalho:\n'
      '1) Cartão "ABONO SALARIAL" com botão "CONSULTAR".\n'
      '2) Cartão "SEGURO-DESEMPREGO" com opções para "CONSULTAR" ou "SOLICITAR".\n'
      '3) Cartões de Apoio Financeiro, Benefício Taxista e Benefício Emergencial.\n'
      '4) Aba "Benefícios" selecionada na barra inferior.';
  /// Passo 2 de Benefícios na Carteira de Trabalho.
  static const String carteiraDeTrabalhoBeneficios2 =
      'Aba "Emprego" da Carteira de Trabalho:\n'
      '1) Explicação sobre a confirmação de dados para acessar as opções de emprego.\n'
      '2) Botão azul "ATUALIZAR INFORMAÇÕES PESSOAIS" e opção "NÃO QUERO ATUALIZAR AGORA".\n'
      '3) Aba "Emprego" selecionada no meio da barra inferior.';
  /// Passo 3 de Benefícios na Carteira de Trabalho.
  static const String carteiraDeTrabalhoBeneficios3 =
      'Aba "Empréstimos" (Crédito do Trabalhador):\n'
      '1) Atalhos para "Simular empréstimo", "Meus empréstimos", "Portabilidade" e "Permissões".\n'
      '2) Botão azul "SIMULAR EMPRÉSTIMO" e cartão "Ficou com dúvida?" abaixo.\n'
      '3) Aba "Empréstimos" selecionada na barra inferior.';
  /// Passo 4 de Benefícios na Carteira de Trabalho.
  static const String carteiraDeTrabalhoBeneficios4 =
      'Aba "Menu" da Carteira de Trabalho:\n'
      '1) Lista completa de áreas: Carteira de Trabalho, Benefícios, Emprego, Notificações, Empréstimos, Extratos e Outras opções.\n'
      '2) Opção "Sair" para encerrar o acesso na sua conta com segurança.\n'
      '3) Aba "Menu" selecionada no canto inferior direito.';
  /// Descrição da captura 1 da Carteira de Trabalho Digital.
  static const String carteiraDeTrabalhoCaptura1 =
      'Tela inicial da Carteira de Trabalho Digital com três áreas numeradas: brasão, botão Entrar com gov.br e banner inferior.';
  /// Descrição da captura 2 da Carteira de Trabalho Digital.
  static const String carteiraDeTrabalhoCaptura2 =
      'Tela de autorização gov.br na Carteira de Trabalho com duas regiões numeradas: lista de dados e botões Negar e Autorizar.';
  /// Descrição da captura 3 da Carteira de Trabalho Digital.
  static const String carteiraDeTrabalhoCaptura3 =
      'Painel inicial da Carteira de Trabalho com quatro áreas numeradas: cabeçalho, contratos, enviar carteira e barra inferior.';
  /// Descrição da captura 4 da Carteira de Trabalho Digital.
  static const String carteiraDeTrabalhoCaptura4 =
      'Tela Contratos de Trabalho Digitais com três regiões numeradas: topo com botão atualizar, lista de empresas e outros vínculos.';
  /// Descrição da captura 5 da Carteira de Trabalho Digital.
  static const String carteiraDeTrabalhoCaptura5 =
      'Tela Outros vínculos de trabalho com duas áreas numeradas: aviso central e botão azul Voltar.';
  /// Descrição da captura 6 da Carteira de Trabalho Digital.
  static const String carteiraDeTrabalhoCaptura6 =
      'Tela Enviar Carteira de Trabalho Digital com três regiões numeradas: dados pessoais, seleção de contratos e botão Gerar PDF.';
  /// Descrição da captura 7 da Carteira de Trabalho Digital.
  static const String carteiraDeTrabalhoCaptura7 =
      'Aba Benefícios da Carteira de Trabalho com quatro áreas numeradas: Abono Salarial, Seguro-Desemprego, outros apoios e aba ativa.';
  /// Descrição da captura 8 da Carteira de Trabalho Digital.
  static const String carteiraDeTrabalhoCaptura8 =
      'Aba Emprego da Carteira de Trabalho com três regiões numeradas: aviso, botão Atualizar Informações Pessoais e aba Emprego.';
  /// Descrição da captura 9 da Carteira de Trabalho Digital.
  static const String carteiraDeTrabalhoCaptura9 =
      'Aba Empréstimos da Carteira de Trabalho com três áreas numeradas: atalhos do Crédito do Trabalhador, botão Simular e aba ativa.';
  /// Descrição da captura 10 da Carteira de Trabalho Digital.
  static const String carteiraDeTrabalhoCaptura10 =
      'Aba Menu da Carteira de Trabalho com três regiões numeradas: lista de seções, opção Sair e aba Menu.';
}
