/// Os textos da abertura do aplicativo (feature 013, T036; FR-038).
///
/// Na abertura quase não há texto: a Memora acena e o Memora carrega. Estas
/// são as únicas frases que aparecem, e só quando o carregamento demora ou
/// falha. Voz da Memora, primeira pessoa, no máximo duas frases, sem emoji; o
/// portão `texto_da_interface_test.dart` varre este arquivo.
abstract final class TextosAbertura {
  /// O que o leitor de tela diz enquanto a Memora acena (que, para ele, não
  /// existe: ela só enfeita).
  static const String abrindo = 'Abrindo o Memora.';

  /// Passados 4 segundos sem terminar de carregar (FR-038).
  static const String quasePronta = 'Estou quase pronta.';

  /// Quando o carregamento falha: sem culpa de ninguém e com um caminho.
  static const String falhou =
      'Não consegui abrir o Memora agora. Vamos tentar de novo?';

  /// O botão que tenta carregar outra vez.
  static const String tentarDeNovo = 'Tentar de novo';
}
