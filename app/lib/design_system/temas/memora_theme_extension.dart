import 'package:flutter/material.dart';

import '../tokens/cores.dart';

/// Identifica qual tema está ativo.
enum MemoraTemaId {
  /// Tema claro.
  claro,

  /// Tema escuro.
  escuro,

  /// Tema de alto contraste.
  altoContraste,
}

/// Extensão de tema que carrega os tokens semânticos do Memora.
///
/// O `ColorScheme` do Material não comporta nossos papéis (`superficieAlt`,
/// `sucesso`, `perigo`, `sobrePerigo`) sem distorcer o significado deles. Uma
/// [ThemeExtension] tipada resolve isso e traz uma garantia importante: um
/// token inexistente **não compila** (research.md, R6).
///
/// Acesse sempre por [BuildContextMemora.memora]:
///
/// ```dart
/// final cores = context.memora.cores;
/// ```
@immutable
class MemoraTheme extends ThemeExtension<MemoraTheme> {
  /// Identificador do tema ativo.
  final MemoraTemaId id;
  /// Cores semânticas deste tema.
  final MemoraCores cores;

  /// O nome da paleta de destaque aplicada (uma das chaves de
  /// [MemoraCores.paletas]); `azul` é a de fábrica.
  ///
  /// É **ele** a fonte da paleta: quem precisa saber qual paleta está ativa
  /// (a Memora, que se pinta com as cores dela) lê este campo, em vez de
  /// adivinhar pela cor primária — que só diz qual paleta é enquanto nenhuma
  /// outra produzir a mesma primária. No alto contraste a paleta não vale
  /// (R15) e o nome fica `azul`.
  final String paleta;

  /// Contraste mínimo exigido para texto neste tema.
  ///
  /// 4.5:1 nos temas comuns; 7:1 no de alto contraste (FR-035).
  final double contrasteMinimoTexto;

  /// Cria um tema do Memora.
  const MemoraTheme({
    required this.id,
    required this.cores,
    required this.contrasteMinimoTexto,
    this.paleta = 'azul',
  });

  /// Tema claro, padrão do aplicativo.
  static const MemoraTheme claro = MemoraTheme(
    id: MemoraTemaId.claro,
    cores: MemoraCores.claro,
    contrasteMinimoTexto: 4.5,
  );

  /// Tema escuro.
  static const MemoraTheme escuro = MemoraTheme(
    id: MemoraTemaId.escuro,
    cores: MemoraCores.escuro,
    contrasteMinimoTexto: 4.5,
  );

  /// Tema de alto contraste, exigindo 7:1 no texto.
  static const MemoraTheme altoContraste = MemoraTheme(
    id: MemoraTemaId.altoContraste,
    cores: MemoraCores.altoContraste,
    contrasteMinimoTexto: 7.0,
  );

  /// Os três temas, usados pelos testes de contraste.
  static const List<MemoraTheme> todos = <MemoraTheme>[
    claro,
    escuro,
    altoContraste,
  ];

  /// Devolve uma copia deste tema com a paleta de destaque aplicada (FR-039, R15).
  MemoraTheme comPaleta(String nome) {
    if (id == MemoraTemaId.altoContraste) return this;
    final bool ehEscuro = id == MemoraTemaId.escuro;
    return copyWith(
      cores: cores.comPaleta(nome, ehEscuro: ehEscuro),
      // Nome desconhecido vira `azul`, como em [MemoraCores.comPaleta].
      paleta: MemoraCores.paletas.containsKey(nome) ? nome : 'azul',
    );
  }

  @override
  MemoraTheme copyWith({
    MemoraTemaId? id,
    MemoraCores? cores,
    double? contrasteMinimoTexto,
    String? paleta,
  }) {
    return MemoraTheme(
      id: id ?? this.id,
      cores: cores ?? this.cores,
      contrasteMinimoTexto: contrasteMinimoTexto ?? this.contrasteMinimoTexto,
      paleta: paleta ?? this.paleta,
    );
  }

  @override
  MemoraTheme lerp(covariant MemoraTheme? other, double t) {
    if (other == null) return this;
    return MemoraTheme(
      id: t < 0.5 ? id : other.id,
      cores: MemoraCores.lerp(cores, other.cores, t),
      contrasteMinimoTexto: t < 0.5
          ? contrasteMinimoTexto
          : other.contrasteMinimoTexto,
      paleta: t < 0.5 ? paleta : other.paleta,
    );
  }
}

/// Acesso aos tokens do Memora a partir do contexto.
extension BuildContextMemora on BuildContext {
  /// Tokens do tema ativo.
  ///
  /// Lança se o [MemoraTheme] não estiver registrado — falha alto e cedo é
  /// preferível a uma tela renderizada com cores erradas.
  MemoraTheme get memora {
    final tema = Theme.of(this).extension<MemoraTheme>();
    assert(
      tema != null,
      'MemoraTheme não registrado. Use um dos temas de design_system/temas.',
    );
    return tema!;
  }
}
