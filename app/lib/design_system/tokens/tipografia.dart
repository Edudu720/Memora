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
  /// Menor tamanho permitido em qualquer texto do aplicativo.
  static const double tamanhoMinimo = 16.0;

  /// Título principal de uma tela.
  static const TextStyle tituloTela = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.25,
  );

  /// Título de seção ou agrupamento.
  static const TextStyle tituloSecao = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  /// Texto padrão do aplicativo.
  static const TextStyle corpo = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  /// Texto padrão com ênfase.
  static const TextStyle corpoForte = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  /// Texto auxiliar. **Nunca menor que [tamanhoMinimo].**
  static const TextStyle apoio = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  /// Rótulo dentro de botão.
  static const TextStyle rotuloBotao = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// Todos os estilos, usados pelos testes que garantem o piso de 16 sp.
  static const List<TextStyle> todos = <TextStyle>[
    tituloTela,
    tituloSecao,
    corpo,
    corpoForte,
    apoio,
    rotuloBotao,
  ];
}
