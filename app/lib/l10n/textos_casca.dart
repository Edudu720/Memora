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
}
