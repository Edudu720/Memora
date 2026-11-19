import 'package:flutter/material.dart';

import '../navegacao/rota_memora.dart';
import '../tokens/cores.dart';
import '../tokens/dimensoes.dart';
import '../tokens/elevacao.dart';
import '../tokens/raio.dart';
import '../tokens/tipografia.dart';
import 'memora_theme_extension.dart';

/// Constrói os [ThemeData] do Memora a partir dos tokens.
///
/// Nenhum valor visual literal aparece aqui: tudo vem de `tokens/` (FR-002).
abstract final class TemasMemora {
  /// Tema claro, padrão do aplicativo.
  static final ThemeData claro = _construir(MemoraTheme.claro, Brightness.light);

  /// Tema escuro.
  static final ThemeData escuro = _construir(MemoraTheme.escuro, Brightness.dark);

  /// Tema de alto contraste, para baixa visão severa.
  static final ThemeData altoContraste = _construir(
    MemoraTheme.altoContraste,
    Brightness.dark,
  );

  /// Retorna o tema correspondente ao identificador, opcionalmente com uma
  /// [paleta] (FR-039, R15).
  static ThemeData porId(MemoraTemaId id, {String? paleta}) {
    final String? paletaNormalizada =
        (paleta == null || paleta == 'azul') ? null : paleta;
    if (paletaNormalizada == null) {
      return switch (id) {
        MemoraTemaId.claro => claro,
        MemoraTemaId.escuro => escuro,
        MemoraTemaId.altoContraste => altoContraste,
      };
    }
    return switch (id) {
      MemoraTemaId.claro => _construir(
          MemoraTheme.claro.comPaleta(paletaNormalizada),
          Brightness.light,
        ),
      MemoraTemaId.escuro => _construir(
          MemoraTheme.escuro.comPaleta(paletaNormalizada),
          Brightness.dark,
        ),
      MemoraTemaId.altoContraste => altoContraste,
    };
  }

  static ThemeData _construir(MemoraTheme memora, Brightness brilho) {
    final MemoraCores c = memora.cores;

    return ThemeData(
      useMaterial3: true,
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
        surfaceContainerHighest: c.superficieSutil,
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
      dividerTheme: DividerThemeData(
        color: c.bordaSutil,
        thickness: MemoraDimensoes.espessuraBordaSutil,
        space: MemoraDimensoes.espessuraBordaSutil,
      ),
      cardTheme: CardThemeData(
        color: c.superficie,
        elevation: MemoraElevacao.plana,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MemoraRaio.cartao),
        ),
      ),
      // Toda rota de página que não seja uma `RotaMemora` — as de pacotes e
      // as que chegarem de fora — desliza do mesmo jeito (feature 013, T049).
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: TransicaoMemora(),
        },
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.superficie,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(MemoraRaio.cartao),
          ),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[memora],
    );
  }
}
