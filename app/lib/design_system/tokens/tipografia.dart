import 'package:flutter/painting.dart';

/// Escala tipográfica do Memora.
///
/// Duas regras inegociáveis, ambas derivadas do público-alvo:
///
/// 1. **Família sem serifa.** Serifa reduz legibilidade em baixa visão e em
///    telas de baixa densidade (FR-006). Corrige a fonte serifada usada no
///    Chatbot do protótipo.
/// 2. **Piso de 16 sp.** Nenhum texto do aplicativo pode ser menor — inclusive
///    avisos e mensagens auxiliares, que é justamente onde interfaces costumam
///    encolher a fonte.
///
/// A escala parte de 18 sp no corpo, acima do padrão de 14–16 sp de
/// aplicativos comuns (research.md, R4).
abstract final class MemoraTipografia {
  /// Família de todo o aplicativo: Atkinson Hyperlegible Next, desenhada pelo
  /// Braille Institute para baixa visão (R3 da feature 004).
  ///
  /// Ela diferencia `I`, `l` e `1`, e `0` de `O` — as confusões que mais
  /// derrubam quem digita e-mail e código. E, embarcada, o texto é o mesmo em
  /// todo aparelho, em vez de mudar de fabricante para fabricante.
  ///
  /// **Os testes não a usam**, e de propósito: o `flutter test` mede com uma
  /// fonte quadrada, de 1 em por caractere, mais larga e com mais quebras que a
  /// real. A matriz de estouro fica pessimista nas duas direções. Só o álbum
  /// de telas (T043) vai carregá-la, porque ele existe para olhar.
  static const String familia = 'AtkinsonHyperlegibleNext';

  /// Menor tamanho permitido em qualquer texto do aplicativo.
  static const double tamanhoMinimo = 16.0;

  /// O título grande da entrada e do Início (feature 004).
  ///
  /// O wireframe abre com um título de ~36: o [tituloTela], com 32, não dava a
  /// hierarquia entre "onde estou" e "o que há aqui".
  static const TextStyle destaque = TextStyle(
    fontFamily: familia,
    fontSize: 36,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  /// Título principal de uma tela.
  static const TextStyle tituloTela = TextStyle(
    fontFamily: familia,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.25,
  );

  /// Título de seção ou agrupamento.
  static const TextStyle tituloSecao = TextStyle(
    fontFamily: familia,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  /// Texto padrão do aplicativo.
  static const TextStyle corpo = TextStyle(
    fontFamily: familia,
    fontSize: 18,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  /// Texto padrão com ênfase.
  static const TextStyle corpoForte = TextStyle(
    fontFamily: familia,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  /// Texto auxiliar. **Nunca menor que [tamanhoMinimo].**
  static const TextStyle apoio = TextStyle(
    fontFamily: familia,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  /// Rótulo dentro de botão.
  static const TextStyle rotuloBotao = TextStyle(
    fontFamily: familia,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// Todos os estilos, usados pelos testes que garantem o piso de 16 sp.
  static const List<TextStyle> todos = <TextStyle>[
    destaque,
    tituloTela,
    tituloSecao,
    corpo,
    corpoForte,
    apoio,
    rotuloBotao,
  ];
}
