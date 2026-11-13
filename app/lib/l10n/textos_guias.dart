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

  static const String govBrPasso1 =
      'Na tela inicial do Gov.br, toque no botão azul "Entrar com gov.br" no topo ou centro da tela.';
  static const String govBrCaptura1 =
      'Página inicial do portal gov.br exibindo o botão azul Entrar com gov.br.';
  static const String govBrPasso2 =
      'Toque na caixa branca de CPF e digite os 11 números do seu CPF, sem pontos nem traço.';
  static const String govBrCaptura2 =
      'Tela Identifique-se no gov.br com campo para digitar o CPF e botão Continuar.';
  static const String govBrPasso3 =
      'Digite a sua senha no campo protegido. Lembre-se: sua senha só deve ser digitada no site ou aplicativo oficial.';
  static const String govBrCaptura3 =
      'Tela oficial de senha do gov.br com campo de senha protegido e opção de entrar.';
  static const String govBrPasso4 =
      'Pronto! Você entrou na sua conta Gov.br. Aqui aparecem seus atalhos e o nível da sua conta (Bronze, Prata ou Ouro).';
  static const String govBrCaptura4 =
      'Menu de atalhos da conta Gov.br autenticada exibindo selo de nível e opções rápidas.';

  static const String govBrPasso5 =
      'Em "Minha área gov.br", você acompanha avisos importantes e acessa seus serviços pessoais.';
  static const String govBrCaptura5 =
      'Painel Minha área gov.br com cabeçalho de boas-vindas e cartões de serviços.';
  static const String govBrPasso6 =
      'Use os botões rápidos para abrir sua Caixa Postal do governo ou consultar documentos guardados.';
  static const String govBrCaptura6 =
      'Atalhos rápidos do Gov.br para Caixa Postal e Documentos.';
  static const String govBrPasso7 =
      'Toque em "Carteira de Documentos", "Dados Pessoais" ou "Segurança da Conta" para conferir suas informações.';
  static const String govBrCaptura7 =
      'Cartões de Carteira de Documentos, Dados Pessoais e Segurança da Conta no Gov.br.';
  static const String govBrPasso8 =
      'Role a página "Minha Conta" para ver todos os serviços disponíveis vinculados ao seu CPF.';
  static const String govBrCaptura8 =
      'Lista de serviços vinculados à conta pessoal dentro do portal Gov.br.';

  static const String govBrPasso9 =
      'Na seção "Agenda gov.br", você confere compromissos e prazos de serviços públicos agendados.';
  static const String govBrCaptura9 =
      'Tela da Agenda gov.br mostrando calendário e avisos de agendamentos.';
  static const String govBrPasso10 =
      'Em "Certidões", toque na opção desejada para emitir comprovantes de vacinação, SUS ou quitação eleitoral.';
  static const String govBrCaptura10 =
      'Lista de certidões oficiais disponíveis para emissão gratuita no Gov.br.';
  static const String govBrPasso11 =
      'Você também pode baixar certidões de antecedentes criminais e regularidade fiscal com apenas um toque.';
  static const String govBrCaptura11 =
      'Opções de certidão de antecedentes criminais e regularidade fiscal no Gov.br.';

  static const String govBrPasso12 =
      'Na página principal, veja os destaques do momento, como Bolsa Família e Imposto de Renda.';
  static const String govBrCaptura12 =
      'Destaques do portal gov.br com cartões de benefícios e serviços mais buscados.';
  static const String govBrPasso13 =
      'Toque no perfil que combina com você, como Agricultor ou Turista, para ver serviços filtrados.';
  static const String govBrCaptura13 =
      'Grade de perfis de cidadão no Gov.br incluindo Agricultor e Turista.';
  static const String govBrPasso14 =
      'Pessoas aposentadas ou empreendedoras também encontram atalhos diretos para os seus direitos e serviços.';
  static const String govBrCaptura14 =
      'Cartões de perfil Aposentado e Empreendedor na página inicial do Gov.br.';
  static const String govBrPasso15 =
      'Se preferir procurar por assunto, escolha uma categoria na lista alfabética de A até D.';
  static const String govBrCaptura15 =
      'Lista de categorias de serviços públicos organizadas em ordem alfabética de A a D.';
  static const String govBrPasso16 =
      'Continue descendo para explorar as categorias de E até T e encontrar qualquer serviço federal.';
  static const String govBrCaptura16 =
      'Continuação da lista de categorias de serviços públicos de E a T.';

  static const String govBrPasso17 =
      'O governo reúne seus aplicativos oficiais em uma página segura para você não baixar apps falsos.';
  static const String govBrCaptura17 =
      'Banner oficial de aplicativos móveis do governo federal no portal Gov.br.';
  static const String govBrPasso18 =
      'Na galeria de aplicativos, confira os ícones oficiais antes de instalar no seu celular.';
  static const String govBrCaptura18 =
      'Galeria de aplicativos oficiais do governo com ícones e descrições.';
  static const String govBrPasso19 =
      'Entre os mais acessados estão o Meu INSS e o Meu SUS Digital para cuidar da aposentadoria e saúde.';
  static const String govBrCaptura19 =
      'Seção de aplicativos mais acessados destacando Meu INSS e Meu SUS Digital.';
  static const String govBrPasso20 =
      'Veja também o atalho para o Cadastro Único, usado para manter benefícios sociais atualizados.';
  static const String govBrCaptura20 =
      'Cartões dos aplicativos Meu INSS e Cadastro Único na página oficial.';
  static const String govBrPasso21 =
      'Para quem trabalha ou tem pequeno negócio, há links para o app MEI e Carteira de Trabalho Digital.';
  static const String govBrCaptura21 =
      'Atalhos para os aplicativos oficiais MEI e Carteira de Trabalho Digital.';

  static const String govBrPasso22 =
      'Em "Desempenho dos Serviços", você acompanha avaliações e tempos médios de atendimento.';
  static const String govBrCaptura22 =
      'Painel de Desempenho dos Serviços públicos no portal Gov.br.';
  static const String govBrPasso23 =
      'Precisou falar com o governo? Na Ouvidoria (Fala.BR), escolha entre fazer uma solicitação ou denúncia.';
  static const String govBrCaptura23 =
      'Tela da Ouvidoria com botões de Denúncia e Solicitação.';
  static const String govBrPasso24 =
      'Você também pode registrar elogios, reclamações e acompanhar seu número de protocolo.';
  static const String govBrCaptura24 =
      'Opções de Elogio, Reclamação e acompanhamento de protocolo na Ouvidoria.';

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

  static const String serasaPasso1 =
      'Na página inicial do Serasa, toque em "Consultar CPF grátis" para acessar sua conta.';
  static const String serasaCaptura1 =
      'Página inicial do Serasa com botão Consultar CPF grátis em destaque.';
  static const String serasaPasso2 =
      'Em épocas de negociação, você verá o aviso do Feirão Serasa Limpa Nome logo na capa.';
  static const String serasaCaptura2 =
      'Capa promocional do Feirão Serasa com informações de negociação de dívidas.';
  static const String serasaPasso3 =
      'Toque no menu lateral para explorar todos os serviços e produtos disponíveis para o seu CPF.';
  static const String serasaCaptura3 =
      'Menu lateral do Serasa exibindo categorias de produtos e serviços.';
  static const String serasaPasso4 =
      'Após entrar com seus dados, você vê a tela inicial logada com opções para conectar suas contas.';
  static const String serasaCaptura4 =
      'Tela inicial autenticada do Serasa com painel resumido e conexões de conta.';

  static const String serasaPasso5 =
      'No painel principal, toque no cartão "Serasa Score" para ver sua pontuação atual de 0 a 1000.';
  static const String serasaCaptura5 =
      'Cartão do Serasa Score mostrando a pontuação e faixa de avaliação.';
  static const String serasaPasso6 =
      'Na tela "Seu Serasa Score", veja o que ajuda ou prejudica sua nota de crédito.';
  static const String serasaCaptura6 =
      'Página detalhada Seu Serasa Score com explicação dos fatores da pontuação.';
  static const String serasaPasso7 =
      'Role para baixo para acompanhar o histórico de variações na sua pontuação ao longo dos meses.';
  static const String serasaCaptura7 =
      'Gráfico de variações do Serasa Score ao longo do tempo.';
  static const String serasaPasso8 =
      'Ative os "Alertas do Score" para ser avisado quando alguma empresa consultar seu CPF.';
  static const String serasaCaptura8 =
      'Seção de Alertas do Score em tempo real no Serasa.';

  static const String serasaPasso9 =
      'Quando não há pendências no seu CPF, o Serasa mostra o aviso positivo: "Seu nome está limpo".';
  static const String serasaCaptura9 =
      'Cartão de situação financeira indicando Seu nome está limpo.';
  static const String serasaPasso10 =
      'Na aba "Minhas Dívidas", confira se existem ofertas de desconto ou propostas de acordo.';
  static const String serasaCaptura10 =
      'Aba Minhas Dívidas exibindo ofertas e acordos disponíveis.';
  static const String serasaPasso11 =
      'Você também pode filtrar e conferir seus acordos já quitados ou eventuais parcelas vencidas.';
  static const String serasaCaptura11 =
      'Lista de acordos quitados e vencidos na aba Minhas Dívidas.';
  static const String serasaPasso12 =
      'Pelo menu de serviços, acesse rapidamente as opções de Dívidas e Meus acordos.';
  static const String serasaCaptura12 =
      'Atalhos de serviços para Dívidas e Meus acordos no Serasa.';

  static const String serasaPasso13 =
      'Toque na aba "Meu CPF" para conferir os detalhes cadastrais e a proteção do seu documento.';
  static const String serasaCaptura13 =
      'Tela principal da aba Meu CPF com resumo cadastral.';
  static const String serasaPasso14 =
      'Acompanhe o resumo de saúde financeira e verifique se houve algum alerta de vazamento de dados.';
  static const String serasaCaptura14 =
      'Painel de saúde financeira e verificação de vazamentos de dados.';
  static const String serasaPasso15 =
      'Veja o selo de segurança da sua conta e acesse seus relatórios detalhados quando precisar.';
  static const String serasaCaptura15 =
      'Área com selo de segurança e opções de relatórios do CPF.';
  static const String serasaPasso16 =
      'O Serasa também oferece consulta de dados na Dark Web e consulta veicular para checar histórico de carros.';
  static const String serasaCaptura16 =
      'Cartões de Consulta Dark Web e Consulta Veicular no Serasa.';
  static const String serasaPasso17 =
      'Você pode gerenciar o monitoramento do seu CPF, CNPJ ou de terceiros autorizados.';
  static const String serasaCaptura17 =
      'Opções de monitoramento de CPF, CNPJ e Terceiros no Serasa.';

  static const String serasaPasso18 =
      'Na seção de crédito, conheça ofertas de empréstimos e cartões selecionadas para o seu perfil.';
  static const String serasaCaptura18 =
      'Vitrine de empréstimos e cartões de crédito disponíveis no Serasa.';
  static const String serasaPasso19 =
      'Confira opções para bloquear consultas indesejadas ao seu CPF e gerenciar seu Cadastro Positivo.';
  static const String serasaCaptura19 =
      'Ferramentas de bloqueio de consultas e informações do Cadastro Positivo.';
  static const String serasaPasso20 =
      'Acesse o Extrato Serasa ou use a função de Bloquear Score para reforçar sua proteção.';
  static const String serasaCaptura20 =
      'Opções de Extrato Serasa e Bloquear Score na área de serviços.';
  static const String serasaPasso21 =
      'Veja as configurações de proteção de dados e acompanhe o status de pedidos realizados.';
  static const String serasaCaptura21 =
      'Tela de proteção de dados e histórico de pedidos no Serasa.';
  static const String serasaPasso22 =
      'Precisa confirmar um pagamento? Use o "Validador de boleto" ou acesse a "Central de Ajuda" sempre que tiver dúvida.';
  static const String serasaCaptura22 =
      'Atalhos para o Validador de boleto e Central de Ajuda do Serasa.';

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

  static const String correiosPasso1 =
      'Na página inicial dos Correios, você encontra os atalhos principais para encomendas e serviços.';
  static const String correiosCaptura1 =
      'Portal inicial dos Correios exibindo menu principal e área de serviços.';
  static const String correiosPasso2 =
      'Toque no campo "Acompanhe seu Objeto" e digite o código de rastreamento de 13 letras e números.';
  static const String correiosCaptura2 =
      'Campo Acompanhe seu Objeto destacado no portal dos Correios.';
  static const String correiosPasso3 =
      'Preencha o código de verificação de segurança exibido na imagem e toque na lupa para consultar.';
  static const String correiosCaptura3 =
      'Tela de rastreamento dos Correios com campo de código do objeto e verificação visual.';
  static const String correiosPasso4 =
      'Veja a linha do tempo da sua entrega com cada cidade por onde o pacote passou até chegar em casa.';
  static const String correiosCaptura4 =
      'Histórico completo de rastreamento mostrando linha do tempo e status da entrega.';

  static const String correiosPasso5 =
      'No menu superior, acesse as opções "Enviar", "Receber" e "Atendimento" conforme o que precisar.';
  static const String correiosCaptura5 =
      'Menu de navegação dos Correios com seções Enviar, Receber e Atendimento.';
  static const String correiosPasso6 =
      'Para saber quanto custa enviar uma caixa ou carta, informe o CEP de origem, destino e o tamanho no calculador de frete.';
  static const String correiosCaptura6 =
      'Tela de cálculo de preços e prazos por CEP nos Correios.';
  static const String correiosPasso7 =
      'Pelo menu também é possível localizar a agência dos Correios mais próxima da sua casa.';
  static const String correiosCaptura7 =
      'Menu dos Correios destacando opções de Rastreamento e Busca de Agências.';
  static const String correiosPasso8 =
      'Caso queira salvar seus envios e receber avisos, entre no "Meu Correios" com seu usuário e senha.';
  static const String correiosCaptura8 =
      'Tela de login do Meu Correios com campo protegido de usuário e senha.';

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
