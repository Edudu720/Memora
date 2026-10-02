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
  // Ajustes provisórios — até a US7 (T092)
  // ---------------------------------------------------------------------------

  /// Título da tela de ajustes.
  static const String tituloAjustes = 'Ajustes';

  /// A porta da aparência.
  static const String portaAparencia = 'Como eu vejo o Memora';

  /// O que a porta da aparência faz.
  static const String descricaoAparencia =
      'Deixar a letra maior, mudar as cores, enxergar melhor';

  /// A galeria, que só existe no modo de desenvolvimento (R9 da 002).
  static const String galeria = 'Galeria de componentes (desenvolvimento)';

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

  /// A pergunta que acompanha a saudação.
  static const String inicioConvite = 'O que vamos fazer hoje?';

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
}
