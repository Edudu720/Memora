/// Textos da casca do aplicativo — a barra inferior e o que a cerca (feature
/// 004).
///
/// Mesma estrutura de `textos_autenticacao.dart`: as frases moram fora das
/// telas para viverem num lugar só, na voz da Memora, e virarem `.arb` no dia
/// em que houver um segundo idioma (D3 da 002).
abstract final class TextosCasca {
  // ---------------------------------------------------------------------------
  // Barra inferior (FR-015)
  //
  // Nomes em linguagem comum, e não "Hub" nem "Home" (FR-008). O wireframe só
  // tinha os ícones — engrenagem, casa e pessoa —, e ícone sozinho é
  // convenção que este público não necessariamente conhece.
  // ---------------------------------------------------------------------------

  /// Destino das configurações.
  static const String destinoConfiguracoes = 'Ajustes';

  /// Destino do Início.
  static const String destinoInicio = 'Início';

  /// Destino do perfil.
  static const String destinoPerfil = 'Meu perfil';

  // ---------------------------------------------------------------------------
  // Sair do Memora pelo botão "voltar" do aparelho
  //
  // Na raiz do Início, o "voltar" do sistema fecharia o aplicativo em
  // silêncio. Para quem não sabe que o gesto faz isso, o Memora simplesmente
  // some — e o Princípio II pede aviso sempre que a pessoa sai do Memora.
  // ---------------------------------------------------------------------------

  /// Título da pergunta.
  static const String tituloSairDoMemora = 'Fechar o Memora?';

  /// A pergunta, explicando o que acontece.
  static const String perguntaSairDoMemora =
      'Você continua na sua conta. Quando abrir o Memora de novo, '
      'ele volta para o Início.';

  /// Confirmar.
  static const String botaoFecharMemora = 'Sim, fechar o Memora';

  /// Ficar.
  static const String botaoFicar = 'Não, quero continuar';

  // ---------------------------------------------------------------------------
  // Perfil provisório — até a US8 (T097)
  // ---------------------------------------------------------------------------

  /// Título do perfil.
  static const String tituloPerfil = 'Meu perfil';

  /// Rótulo do nome.
  static const String rotuloNome = 'Como você quer ser chamada';

  /// Rótulo do canal.
  static const String rotuloCanal = 'E-mail ou telefone da conta';

  // ---------------------------------------------------------------------------
  // Início (FR-014) e o caminho para o Hub
  //
  // "Hub" é nome de trabalho do wireframe e não aparece para a pessoa
  // (FR-008): o atalho diz o que ela encontra lá.
  // ---------------------------------------------------------------------------

  /// A saudação do Início, com o nome de tratamento.
  static String inicioSaudacao(String nome) => 'Oi, $nome!';

  /// A frase de tutorial da Memora no Início (R2, regra 9): diz o que se faz
  /// nesta tela. [atalhos] é quantas caixas há para tocar — a frase concorda
  /// com o que está na tela, e com nenhuma não há o que dizer (FR-018).
  static String inicioTutorial(int atalhos) => atalhos == 1
      ? 'Aqui você escolhe o que quer fazer. Toque na caixa abaixo.'
      : 'Aqui você escolhe o que quer fazer. Toque numa das caixas abaixo.';

  /// A instrução da caixa de conversar (FR-002a): para que ela serve.
  static const String inicioInstrucaoConversar =
      'Tem uma dúvida sobre o celular? Converse comigo.';

  /// A instrução da caixa de ver tudo (FR-002a): para que ela serve.
  static const String inicioInstrucaoVerTudo =
      'Quer ver tudo o que o Memora tem? Toque aqui.';

  /// O atalho para conversar com a Memora — a ação principal do Início.
  static const String inicioConversar = 'Conversar com a Memora';

  /// O atalho para ver todas as partes do aplicativo.
  static const String inicioVerTudo = 'Ver tudo o que eu faço';

  // ---------------------------------------------------------------------------
  // Hub
  // ---------------------------------------------------------------------------

  /// Título da tela com todas as partes do aplicativo.
  static const String tituloHub = 'Vamos começar?';

  /// Título do estado vazio do Hub (FR-006).
  ///
  /// Não deveria aparecer: o Início só oferece o caminho quando há o que
  /// mostrar (FR-018). Existe porque toda tela diz algo, em vez de ficar em
  /// branco, quando não tem o que exibir.
  static const String hubVazioTitulo = 'Ainda não há nada por aqui';

  /// A explicação do estado vazio do Hub.
  static const String hubVazioExplicacao =
      'Quando houver algo para você abrir, vai aparecer nesta tela.';

  /// A faixa no pé do Hub quando há mais portas abaixo da dobra (FR-017).
  ///
  /// Curta de propósito: a 200% de ampliação ela já ocupa duas linhas, e a
  /// faixa fica sobre o pé da lista. A frase completa, com o gesto, é a do
  /// leitor de tela ([hubHaMaisLeitor]).
  static const String hubHaMais = 'Há mais abaixo';

  /// O que o leitor de tela diz no lugar de [hubHaMais]: a frase completa, com
  /// o gesto. Quem usa TalkBack rola por deslizar, e é o único jeito de saber
  /// que há mais portas depois da última lida.
  static const String hubHaMaisLeitor =
      'Há mais portas abaixo. Deslize para baixo para ver.';

  /// Rótulo do botão de ação principal do cartão herói no Início e no Hub.
  static const String acaoComecarConversa = 'Começar';

  /// Título da seção de atalhos rápidos do Início.
  static const String tituloAtalhosInicio = 'Atalhos rápidos';

  /// Balão de boas-vindas curto da Memora no topo do Início.
  static const String balaoInicio = 'Como posso te ajudar hoje?';

  /// Rótulo do atalho de cuidado na grade do Início.
  static const String atalhoCuidado = 'Cuidado';

  /// Descrição curta do atalho de cuidado na grade do Início.
  static const String atalhoCuidadoSubtitulo = 'Batimentos e queda';

  /// Rótulo curto para aplicativos na grade do Início.
  static const String atalhoAplicativosSubtitulo = 'Eu abro para você';

  /// Rótulo curto para serviços na grade do Início.
  static const String atalhoServicosSubtitulo = 'Eu só te ensino';

  /// Rótulo curto para ajuda na grade do Início.
  static const String atalhoAjudaSubtitulo = 'Dúvidas e apoio';

  /// Rótulo curto para registro na grade do Início.
  static const String atalhoRegistroSubtitulo = 'O que já abrimos';
}
