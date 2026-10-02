import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';

/// Cores semânticas do Memora.
///
/// Os valores desta classe são a **contraparte em código** de
/// `specs/002-design-system/ferramentas/validar_paleta.py`, que valida os 66
/// pares de contraste dos três temas segundo a WCAG 2.2.
///
/// **Nunca altere um valor aqui sem rodar o validador.** O teste
/// `test/design_system/contraste_test.dart` reprova se um par ficar abaixo do
/// mínimo exigido.
///
/// Origem dos valores: `fundo`, `superficieAlt` e `primaria` foram amostrados
/// das 38 telas do protótipo (research.md, R1). Os demais foram derivados e
/// ajustados até atingirem conformidade.
@immutable
class MemoraCores {
  /// Fundo da tela.
  final Color fundo;

  /// Superfície de cartão, diálogo e folha inferior.
  final Color superficie;

  /// Superfície secundária, para agrupamentos internos.
  final Color superficieAlt;

  /// Tom suave da primária: pílula do destino ativo, medalhão das ilustrações
  /// e fundo de ilustração dos cartões (feature 004).
  ///
  /// **Nunca é o único sinal de estado.** Contra [fundo] e [superficie] ele mede
  /// só 1,1 a 1,6:1 — é reforço visual, não informação. Quem marca o destino
  /// ativo é o traço em [primaria] e o negrito. Sobre ele, [texto],
  /// [textoSuave] e [primaria] passam como texto (`validar_paleta.py`).
  final Color destaque;

  /// O círculo **claro** atrás de toda ilustração colorida, nos três temas.
  ///
  /// Claro mesmo nos temas escuros, de propósito: a Memora e as pessoas têm
  /// cores próprias, e sobre um fundo azul-marinho a cabeça azul da Memora
  /// sumia (medido no álbum de rascunho da T010). É o mesmo recurso dos
  /// círculos amarelos do wireframe. Decorativo: nada se escreve sobre ele.
  final Color medalhao;

  /// Ação principal e identidade visual do Memora.
  final Color primaria;

  /// Texto e ícone sobre [primaria].
  final Color sobrePrimaria;

  /// Texto principal.
  final Color texto;

  /// Texto de apoio, com menos ênfase.
  final Color textoSuave;

  /// Contorno de componente.
  final Color borda;

  /// Confirmação e êxito. **Nunca usada sozinha** — sempre com ícone e texto.
  final Color sucesso;

  /// Ação destrutiva e erro. **Nunca usada sozinha.**
  final Color perigo;

  /// Texto e ícone sobre [perigo].
  final Color sobrePerigo;

  /// Cria um conjunto de cores semânticas.
  const MemoraCores({
    required this.fundo,
    required this.superficie,
    required this.superficieAlt,
    required this.destaque,
    required this.medalhao,
    required this.primaria,
    required this.sobrePrimaria,
    required this.texto,
    required this.textoSuave,
    required this.borda,
    required this.sucesso,
    required this.perigo,
    required this.sobrePerigo,
  });

  /// Tema claro. Fundo, superfície secundária e primária vêm do protótipo.
  static const MemoraCores claro = MemoraCores(
    fundo: Color(0xFFF8F8F8),
    superficie: Color(0xFFFFFFFF),
    superficieAlt: Color(0xFFD8D8D8),
    destaque: Color(0xFFE3EAFF),
    medalhao: Color(0xFFE3EAFF),
    primaria: Color(0xFF1040F8),
    sobrePrimaria: Color(0xFFFFFFFF),
    texto: Color(0xFF111111),
    textoSuave: Color(0xFF4A4A4A),
    borda: Color(0xFF6B6B6B),
    sucesso: Color(0xFF186A2E),
    perigo: Color(0xFFB3231F),
    sobrePerigo: Color(0xFFFFFFFF),
  );

  /// Tema escuro.
  static const MemoraCores escuro = MemoraCores(
    fundo: Color(0xFF101216),
    superficie: Color(0xFF1B1E24),
    superficieAlt: Color(0xFF2A2E36),
    destaque: Color(0xFF22305A),
    medalhao: Color(0xFFDCE5FF),
    primaria: Color(0xFF9CB8FF),
    sobrePrimaria: Color(0xFF06132E),
    texto: Color(0xFFF2F4F8),
    textoSuave: Color(0xFFC2C7D0),
    borda: Color(0xFF8A909C),
    sucesso: Color(0xFF7CD69A),
    perigo: Color(0xFFFF9B95),
    sobrePerigo: Color(0xFF3A0705),
  );

  /// Tema de alto contraste, para baixa visão severa.
  ///
  /// Exige 7:1 no texto, superando o nível AA (FR-035).
  static const MemoraCores altoContraste = MemoraCores(
    fundo: Color(0xFF000000),
    superficie: Color(0xFF000000),
    superficieAlt: Color(0xFF1A1A1A),
    destaque: Color(0xFF10245A),
    medalhao: Color(0xFFDCE5FF),
    primaria: Color(0xFF8FB4FF),
    sobrePrimaria: Color(0xFF000000),
    texto: Color(0xFFFFFFFF),
    textoSuave: Color(0xFFE8E8E8),
    borda: Color(0xFFFFFFFF),
    sucesso: Color(0xFF7BE49B),
    perigo: Color(0xFFFF9E97),
    sobrePerigo: Color(0xFF000000),
  );

  /// Retorna uma cópia com os campos informados substituídos.
  MemoraCores copyWith({
    Color? fundo,
    Color? superficie,
    Color? superficieAlt,
    Color? destaque,
    Color? medalhao,
    Color? primaria,
    Color? sobrePrimaria,
    Color? texto,
    Color? textoSuave,
    Color? borda,
    Color? sucesso,
    Color? perigo,
    Color? sobrePerigo,
  }) {
    return MemoraCores(
      fundo: fundo ?? this.fundo,
      superficie: superficie ?? this.superficie,
      superficieAlt: superficieAlt ?? this.superficieAlt,
      destaque: destaque ?? this.destaque,
      medalhao: medalhao ?? this.medalhao,
      primaria: primaria ?? this.primaria,
      sobrePrimaria: sobrePrimaria ?? this.sobrePrimaria,
      texto: texto ?? this.texto,
      textoSuave: textoSuave ?? this.textoSuave,
      borda: borda ?? this.borda,
      sucesso: sucesso ?? this.sucesso,
      perigo: perigo ?? this.perigo,
      sobrePerigo: sobrePerigo ?? this.sobrePerigo,
    );
  }

  /// Interpola linearmente entre dois conjuntos de cores.
  static MemoraCores lerp(MemoraCores a, MemoraCores b, double t) {
    return MemoraCores(
      fundo: Color.lerp(a.fundo, b.fundo, t)!,
      superficie: Color.lerp(a.superficie, b.superficie, t)!,
      superficieAlt: Color.lerp(a.superficieAlt, b.superficieAlt, t)!,
      destaque: Color.lerp(a.destaque, b.destaque, t)!,
      medalhao: Color.lerp(a.medalhao, b.medalhao, t)!,
      primaria: Color.lerp(a.primaria, b.primaria, t)!,
      sobrePrimaria: Color.lerp(a.sobrePrimaria, b.sobrePrimaria, t)!,
      texto: Color.lerp(a.texto, b.texto, t)!,
      textoSuave: Color.lerp(a.textoSuave, b.textoSuave, t)!,
      borda: Color.lerp(a.borda, b.borda, t)!,
      sucesso: Color.lerp(a.sucesso, b.sucesso, t)!,
      perigo: Color.lerp(a.perigo, b.perigo, t)!,
      sobrePerigo: Color.lerp(a.sobrePerigo, b.sobrePerigo, t)!,
    );
  }
}
