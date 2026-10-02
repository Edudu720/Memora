import 'package:flutter/material.dart';

import '../tokens/cores.dart';
import '../tokens/raio.dart';
import '../tokens/tipografia.dart';
import 'memora_theme_extension.dart';

/// Constrói os [ThemeData] do Memora a partir dos tokens.
///
/// Nenhum valor visual literal aparece aqui: tudo vem de `tokens/` (FR-002).
abstract final class TemasMemora {
  /// Tema claro, padrão do aplicativo.
  static ThemeData get claro => _construir(MemoraTheme.claro, Brightness.light);

  /// Tema escuro.
  static ThemeData get escuro => _construir(MemoraTheme.escuro, Brightness.dark);

  /// Tema de alto contraste, para baixa visão severa.
  static ThemeData get altoContraste =>
      _construir(MemoraTheme.altoContraste, Brightness.dark);

  /// Retorna o tema correspondente ao identificador.
  static ThemeData porId(MemoraTemaId id) => switch (id) {
        MemoraTemaId.claro => claro,
        MemoraTemaId.escuro => escuro,
        MemoraTemaId.altoContraste => altoContraste,
      };

  static ThemeData _construir(MemoraTheme memora, Brightness brilho) {
    final MemoraCores c = memora.cores;

    return ThemeData(
      useMaterial3: true,
      // Os componentes do Material (diálogo, campo, folha) herdam a família
      // daqui; os nossos já a recebem pelos estilos de MemoraTipografia.
      fontFamily: MemoraTipografia.familia,
      brightness: brilho,
      scaffoldBackgroundColor: c.fundo,
      colorScheme: ColorScheme(
        brightness: brilho,
        primary: c.primaria,
        onPrimary: c.sobrePrimaria,
        secondary: c.primaria,
        onSecondary: c.sobrePrimaria,
        error: c.perigo,
        onError: c.sobrePerigo,
        surface: c.superficie,
        onSurface: c.texto,
        outline: c.borda,
        surfaceContainerHighest: c.superficieAlt,
      ),
      textTheme: TextTheme(
        displayLarge: MemoraTipografia.destaque.copyWith(color: c.texto),
        displayMedium: MemoraTipografia.tituloTela.copyWith(color: c.texto),
        headlineMedium: MemoraTipografia.tituloSecao.copyWith(color: c.texto),
        bodyLarge: MemoraTipografia.corpo.copyWith(color: c.texto),
        bodyMedium: MemoraTipografia.corpo.copyWith(color: c.texto),
        bodySmall: MemoraTipografia.apoio.copyWith(color: c.textoSuave),
        labelLarge: MemoraTipografia.rotuloBotao.copyWith(color: c.texto),
      ),
      dividerTheme: DividerThemeData(color: c.borda),
      cardTheme: CardThemeData(
        color: c.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MemoraRaio.cartao),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[memora],
    );
  }
}
