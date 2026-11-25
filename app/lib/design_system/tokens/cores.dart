import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';

/// Cores semânticas do Memora.
///
/// Os valores desta classe são a **contraparte em código** de
/// `specs/002-design-system/ferramentas/validar_paleta.py`, que valida todos os
/// pares de contraste dos três temas e seis paletas segundo a WCAG 2.2.
///
/// **Nunca altere um valor aqui sem rodar o validador.** O teste
/// `test/design_system/contraste_test.dart` reprova se um par ficar abaixo do
/// mínimo exigido.
@immutable
class MemoraCores {
  /// Fundo da tela (canvas suave).
  final Color fundo;

  /// Superfície elevada padrão de cartão, diálogo e folha inferior.
  final Color superficie;

  /// Superfície secundária legada, preservada para compatibilidade gradual.
  final Color superficieAlt;

  /// Superfície tonal suave para badges, cabeçalho de etapa e balão da pessoa.
  final Color superficieSutil;

  /// Superfície elevada da navegação inferior e da barra de digitação.
  final Color superficieBarra;

  /// Divisor leve `1 px` e contorno sutil não-interativo no Claro/Escuro
  /// (`>= 3:1` no Alto Contraste).
  final Color bordaSutil;

  /// Tom suave da primária: pílula do destino ativo e realce tonal.
  ///
  /// **Nunca é o único sinal de estado.** Quem marca o destino ativo é o
  /// indicador superior em [primaria], o ícone preenchido e o negrito.
  final Color destaque;

  /// O círculo **claro** atrás de toda ilustração colorida, nos três temas.
  ///
  /// Claro mesmo nos temas escuros para impedir perda de contraste do robô
  /// azul da Memora. Decorativo: nada se escreve sobre ele.
  final Color medalhao;

  /// Ação principal e identidade visual do Memora.
  final Color primaria;

  /// Texto e ícone sobre [primaria].
  final Color sobrePrimaria;

  /// Texto principal.
  final Color texto;

  /// Texto de apoio, com menos ênfase.
  final Color textoSuave;

  /// Contorno obrigatório de campos de entrada, foco, opções e cartões em
  /// Alto Contraste (`>= 3.0:1`).
  final Color borda;

  /// Confirmação e êxito. **Nunca usada sozinha** — sempre com ícone e texto.
  final Color sucesso;

  /// Ação destrutiva e erro. **Nunca usada sozinha.**
  final Color perigo;

  /// Texto e ícone sobre [perigo].
  final Color sobrePerigo;

  /// Stop inicial do gradiente do `CartaoHeroi` (sólido em [altoContraste]).
  final Color gradienteHeroiInicio;

  /// Stop final do gradiente do `CartaoHeroi` (sólido em [altoContraste]).
  final Color gradienteHeroiFim;

  /// Texto e ícone sobre o gradiente do `CartaoHeroi` (`>= 4.5:1` / `7.0:1` AC
  /// contra ambos os stops).
  final Color sobreGradienteHeroi;

  /// Stop inicial do gradiente do `PainelHeroi` de Saúde.
  final Color gradienteSaudeInicio;

  /// Stop final do gradiente do `PainelHeroi` de Saúde.
  final Color gradienteSaudeFim;

  /// Texto e ícone sobre o gradiente de Saúde (`>= 4.5:1` / `7.0:1` AC contra
  /// ambos os stops).
  final Color sobreGradienteSaude;

  /// Fundo tonal suave para vitais e selos positivos (`BadgeDeStatus`).
  final Color saudeSuave;

  /// Texto de selos positivos sobre [superficie] e [saudeSuave] (`>= 4.5:1`).
  final Color sucessoTexto;

  /// Verdadeiro quando este conjunto corresponde ao tema de alto contraste.
  bool get ehAltoContraste =>
      fundo == altoContraste.fundo && borda == altoContraste.borda;

  /// Cria um conjunto de cores semânticas.
  const MemoraCores({
    required this.fundo,
    required this.superficie,
    required this.superficieAlt,
    required this.superficieSutil,
    required this.superficieBarra,
    required this.bordaSutil,
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
    required this.gradienteHeroiInicio,
    required this.gradienteHeroiFim,
    required this.sobreGradienteHeroi,
    required this.gradienteSaudeInicio,
    required this.gradienteSaudeFim,
    required this.sobreGradienteSaude,
    required this.saudeSuave,
    required this.sucessoTexto,
  });

  /// Tema claro (Base Azul).
  static const MemoraCores claro = MemoraCores(
    fundo: Color(0xFFF4F6FA),
    superficie: Color(0xFFFFFFFF),
    superficieAlt: Color(0xFFD8D8D8),
    superficieSutil: Color(0xFFEEF2FA),
    superficieBarra: Color(0xFFFFFFFF),
    bordaSutil: Color(0xFFE2E8F0),
    destaque: Color(0xFFE3EAFF),
    medalhao: Color(0xFFE3EAFF),
    primaria: Color(0xFF1040F8),
    sobrePrimaria: Color(0xFFFFFFFF),
    texto: Color(0xFF111111),
    textoSuave: Color(0xFF4A4A4A),
    borda: Color(0xFF596475),
    sucesso: Color(0xFF186A2E),
    perigo: Color(0xFFB3231F),
    sobrePerigo: Color(0xFFFFFFFF),
    gradienteHeroiInicio: Color(0xFF155EEF),
    gradienteHeroiFim: Color(0xFF0B3BC2),
    sobreGradienteHeroi: Color(0xFFFFFFFF),
    gradienteSaudeInicio: Color(0xFF0E7490),
    gradienteSaudeFim: Color(0xFF155EEF),
    sobreGradienteSaude: Color(0xFFFFFFFF),
    saudeSuave: Color(0xFFE6F6F4),
    sucessoTexto: Color(0xFF0F6A43),
  );

  /// Tema escuro (Base Azul).
  static const MemoraCores escuro = MemoraCores(
    fundo: Color(0xFF0F141E),
    superficie: Color(0xFF182030),
    superficieAlt: Color(0xFF2A2E36),
    superficieSutil: Color(0xFF222C40),
    superficieBarra: Color(0xFF161E2C),
    bordaSutil: Color(0xFF2B364B),
    destaque: Color(0xFF22305A),
    medalhao: Color(0xFFDCE5FF),
    primaria: Color(0xFF9CB8FF),
    sobrePrimaria: Color(0xFF06132E),
    texto: Color(0xFFF2F4F8),
    textoSuave: Color(0xFFC2C7D0),
    borda: Color(0xFF8EA0BD),
    sucesso: Color(0xFF7CD69A),
    perigo: Color(0xFFFF9B95),
    sobrePerigo: Color(0xFF3A0705),
    gradienteHeroiInicio: Color(0xFF1E40AF),
    gradienteHeroiFim: Color(0xFF162E7A),
    sobreGradienteHeroi: Color(0xFFFFFFFF),
    gradienteSaudeInicio: Color(0xFF0F5266),
    gradienteSaudeFim: Color(0xFF183C8C),
    sobreGradienteSaude: Color(0xFFFFFFFF),
    saudeSuave: Color(0xFF123532),
    sucessoTexto: Color(0xFF6EE7B7),
  );

  /// Tema de alto contraste, para baixa visão severa (`>= 7.0:1` em texto).
  static const MemoraCores altoContraste = MemoraCores(
    fundo: Color(0xFF000000),
    superficie: Color(0xFF0A0A0A),
    superficieAlt: Color(0xFF1A1A1A),
    superficieSutil: Color(0xFF141414),
    superficieBarra: Color(0xFF000000),
    bordaSutil: Color(0xFFFFFFFF),
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
    gradienteHeroiInicio: Color(0xFF8FB4FF),
    gradienteHeroiFim: Color(0xFF8FB4FF),
    sobreGradienteHeroi: Color(0xFF000000),
    gradienteSaudeInicio: Color(0xFF8FB4FF),
    gradienteSaudeFim: Color(0xFF8FB4FF),
    sobreGradienteSaude: Color(0xFF000000),
    saudeSuave: Color(0xFF0A0A0A),
    sucessoTexto: Color(0xFF80FFAA),
  );

  /// Retorna uma cópia com os campos informados substituídos.
  MemoraCores copyWith({
    Color? fundo,
    Color? superficie,
    Color? superficieAlt,
    Color? superficieSutil,
    Color? superficieBarra,
    Color? bordaSutil,
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
    Color? gradienteHeroiInicio,
    Color? gradienteHeroiFim,
    Color? sobreGradienteHeroi,
    Color? gradienteSaudeInicio,
    Color? gradienteSaudeFim,
    Color? sobreGradienteSaude,
    Color? saudeSuave,
    Color? sucessoTexto,
  }) {
    return MemoraCores(
      fundo: fundo ?? this.fundo,
      superficie: superficie ?? this.superficie,
      superficieAlt: superficieAlt ?? this.superficieAlt,
      superficieSutil: superficieSutil ?? this.superficieSutil,
      superficieBarra: superficieBarra ?? this.superficieBarra,
      bordaSutil: bordaSutil ?? this.bordaSutil,
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
      gradienteHeroiInicio: gradienteHeroiInicio ?? this.gradienteHeroiInicio,
      gradienteHeroiFim: gradienteHeroiFim ?? this.gradienteHeroiFim,
      sobreGradienteHeroi: sobreGradienteHeroi ?? this.sobreGradienteHeroi,
      gradienteSaudeInicio: gradienteSaudeInicio ?? this.gradienteSaudeInicio,
      gradienteSaudeFim: gradienteSaudeFim ?? this.gradienteSaudeFim,
      sobreGradienteSaude: sobreGradienteSaude ?? this.sobreGradienteSaude,
      saudeSuave: saudeSuave ?? this.saudeSuave,
      sucessoTexto: sucessoTexto ?? this.sucessoTexto,
    );
  }

  /// Interpola linearmente entre dois conjuntos de cores.
  static MemoraCores lerp(MemoraCores a, MemoraCores b, double t) {
    return MemoraCores(
      fundo: Color.lerp(a.fundo, b.fundo, t)!,
      superficie: Color.lerp(a.superficie, b.superficie, t)!,
      superficieAlt: Color.lerp(a.superficieAlt, b.superficieAlt, t)!,
      superficieSutil: Color.lerp(a.superficieSutil, b.superficieSutil, t)!,
      superficieBarra: Color.lerp(a.superficieBarra, b.superficieBarra, t)!,
      bordaSutil: Color.lerp(a.bordaSutil, b.bordaSutil, t)!,
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
      gradienteHeroiInicio: Color.lerp(
        a.gradienteHeroiInicio,
        b.gradienteHeroiInicio,
        t,
      )!,
      gradienteHeroiFim: Color.lerp(
        a.gradienteHeroiFim,
        b.gradienteHeroiFim,
        t,
      )!,
      sobreGradienteHeroi: Color.lerp(
        a.sobreGradienteHeroi,
        b.sobreGradienteHeroi,
        t,
      )!,
      gradienteSaudeInicio: Color.lerp(
        a.gradienteSaudeInicio,
        b.gradienteSaudeInicio,
        t,
      )!,
      gradienteSaudeFim: Color.lerp(
        a.gradienteSaudeFim,
        b.gradienteSaudeFim,
        t,
      )!,
      sobreGradienteSaude: Color.lerp(
        a.sobreGradienteSaude,
        b.sobreGradienteSaude,
        t,
      )!,
      saudeSuave: Color.lerp(a.saudeSuave, b.saudeSuave, t)!,
      sucessoTexto: Color.lerp(a.sucessoTexto, b.sucessoTexto, t)!,
    );
  }

  /// As seis paletas prontas de cor de destaque (FR-039, Feature 007).
  static const Map<String, PaletaDeDestaque> paletas = <String, PaletaDeDestaque>{
    'azul': PaletaDeDestaque(
      primariaClaro: Color(0xFF1040F8),
      sobrePrimariaClaro: Color(0xFFFFFFFF),
      destaqueClaro: Color(0xFFE3EAFF),
      medalhaoClaro: Color(0xFFE3EAFF),
      superficieSutilClaro: Color(0xFFEEF2FA),
      gradienteHeroiInicioClaro: Color(0xFF155EEF),
      gradienteHeroiFimClaro: Color(0xFF0B3BC2),
      sobreGradienteHeroiClaro: Color(0xFFFFFFFF),
      primariaEscuro: Color(0xFF9CB8FF),
      sobrePrimariaEscuro: Color(0xFF06132E),
      destaqueEscuro: Color(0xFF22305A),
      medalhaoEscuro: Color(0xFFDCE5FF),
      superficieSutilEscuro: Color(0xFF222C40),
      gradienteHeroiInicioEscuro: Color(0xFF1E40AF),
      gradienteHeroiFimEscuro: Color(0xFF162E7A),
      sobreGradienteHeroiEscuro: Color(0xFFFFFFFF),
    ),
    'verde': PaletaDeDestaque(
      primariaClaro: Color(0xFF12632B),
      sobrePrimariaClaro: Color(0xFFFFFFFF),
      destaqueClaro: Color(0xFFE0F2E5),
      medalhaoClaro: Color(0xFFE0F2E5),
      superficieSutilClaro: Color(0xFFE8F5EC),
      gradienteHeroiInicioClaro: Color(0xFF157A39),
      gradienteHeroiFimClaro: Color(0xFF0C5225),
      sobreGradienteHeroiClaro: Color(0xFFFFFFFF),
      primariaEscuro: Color(0xFF8FE2A5),
      sobrePrimariaEscuro: Color(0xFF062A12),
      destaqueEscuro: Color(0xFF143D22),
      medalhaoEscuro: Color(0xFFD2F5DC),
      superficieSutilEscuro: Color(0xFF163322),
      gradienteHeroiInicioEscuro: Color(0xFF166534),
      gradienteHeroiFimEscuro: Color(0xFF0E4423),
      sobreGradienteHeroiEscuro: Color(0xFFFFFFFF),
    ),
    'roxo': PaletaDeDestaque(
      primariaClaro: Color(0xFF5D28A6),
      sobrePrimariaClaro: Color(0xFFFFFFFF),
      destaqueClaro: Color(0xFFEFE6FD),
      medalhaoClaro: Color(0xFFEFE6FD),
      superficieSutilClaro: Color(0xFFF2ECFE),
      gradienteHeroiInicioClaro: Color(0xFF6D35BA),
      gradienteHeroiFimClaro: Color(0xFF4B1D8C),
      sobreGradienteHeroiClaro: Color(0xFFFFFFFF),
      primariaEscuro: Color(0xFFCDAFFF),
      sobrePrimariaEscuro: Color(0xFF230A47),
      destaqueEscuro: Color(0xFF351B5C),
      medalhaoEscuro: Color(0xFFECDEFF),
      superficieSutilEscuro: Color(0xFF2A1B47),
      gradienteHeroiInicioEscuro: Color(0xFF5B21B6),
      gradienteHeroiFimEscuro: Color(0xFF3D147C),
      sobreGradienteHeroiEscuro: Color(0xFFFFFFFF),
    ),
    'laranja-terra': PaletaDeDestaque(
      primariaClaro: Color(0xFF93370D),
      sobrePrimariaClaro: Color(0xFFFFFFFF),
      destaqueClaro: Color(0xFFFCE9DF),
      medalhaoClaro: Color(0xFFFCE9DF),
      superficieSutilClaro: Color(0xFFFDF0E8),
      gradienteHeroiInicioClaro: Color(0xFFB54708),
      gradienteHeroiFimClaro: Color(0xFF8A3105),
      sobreGradienteHeroiClaro: Color(0xFFFFFFFF),
      primariaEscuro: Color(0xFFFFB188),
      sobrePrimariaEscuro: Color(0xFF381002),
      destaqueEscuro: Color(0xFF4E210D),
      medalhaoEscuro: Color(0xFFFFE2D3),
      superficieSutilEscuro: Color(0xFF3A1F12),
      gradienteHeroiInicioEscuro: Color(0xFF9A3412),
      gradienteHeroiFimEscuro: Color(0xFF6E220A),
      sobreGradienteHeroiEscuro: Color(0xFFFFFFFF),
    ),
    'rosa': PaletaDeDestaque(
      primariaClaro: Color(0xFF941B55),
      sobrePrimariaClaro: Color(0xFFFFFFFF),
      destaqueClaro: Color(0xFFFDE6F0),
      medalhaoClaro: Color(0xFFFDE6F0),
      superficieSutilClaro: Color(0xFFFDEBF3),
      gradienteHeroiInicioClaro: Color(0xFFB32468),
      gradienteHeroiFimClaro: Color(0xFF87154B),
      sobreGradienteHeroiClaro: Color(0xFFFFFFFF),
      primariaEscuro: Color(0xFFFFAECB),
      sobrePrimariaEscuro: Color(0xFF38041B),
      destaqueEscuro: Color(0xFF541233),
      medalhaoEscuro: Color(0xFFFFE0EC),
      superficieSutilEscuro: Color(0xFF3D1629),
      gradienteHeroiInicioEscuro: Color(0xFF9D174D),
      gradienteHeroiFimEscuro: Color(0xFF6F0E37),
      sobreGradienteHeroiEscuro: Color(0xFFFFFFFF),
    ),
    'grafite': PaletaDeDestaque(
      primariaClaro: Color(0xFF344154),
      sobrePrimariaClaro: Color(0xFFFFFFFF),
      destaqueClaro: Color(0xFFE7ECF2),
      medalhaoClaro: Color(0xFFE7ECF2),
      superficieSutilClaro: Color(0xFFECF0F5),
      gradienteHeroiInicioClaro: Color(0xFF334155),
      gradienteHeroiFimClaro: Color(0xFF1E293B),
      sobreGradienteHeroiClaro: Color(0xFFFFFFFF),
      primariaEscuro: Color(0xFFB7C6DE),
      sobrePrimariaEscuro: Color(0xFF0E1826),
      destaqueEscuro: Color(0xFF232D3B),
      medalhaoEscuro: Color(0xFFE2EAF5),
      superficieSutilEscuro: Color(0xFF222C3A),
      gradienteHeroiInicioEscuro: Color(0xFF334155),
      gradienteHeroiFimEscuro: Color(0xFF1E293B),
      sobreGradienteHeroiEscuro: Color(0xFFFFFFFF),
    ),
  };

  /// Aplica a paleta [nome] sobre este conjunto de cores.
  ///
  /// No tema de alto contraste, a paleta **não se aplica** (FR-039).
  MemoraCores comPaleta(String? nome, {required bool ehEscuro}) {
    final PaletaDeDestaque pal = paletas[nome] ?? paletas['azul']!;
    if (ehEscuro) {
      return copyWith(
        primaria: pal.primariaEscuro,
        sobrePrimaria: pal.sobrePrimariaEscuro,
        destaque: pal.destaqueEscuro,
        medalhao: pal.medalhaoEscuro,
        superficieSutil: pal.superficieSutilEscuro,
        gradienteHeroiInicio: pal.gradienteHeroiInicioEscuro,
        gradienteHeroiFim: pal.gradienteHeroiFimEscuro,
        sobreGradienteHeroi: pal.sobreGradienteHeroiEscuro,
      );
    } else {
      return copyWith(
        primaria: pal.primariaClaro,
        sobrePrimaria: pal.sobrePrimariaClaro,
        destaque: pal.destaqueClaro,
        medalhao: pal.medalhaoClaro,
        superficieSutil: pal.superficieSutilClaro,
        gradienteHeroiInicio: pal.gradienteHeroiInicioClaro,
        gradienteHeroiFim: pal.gradienteHeroiFimClaro,
        sobreGradienteHeroi: pal.sobreGradienteHeroiClaro,
      );
    }
  }
}

/// Cores de destaque e gradiente herói de uma paleta nos temas claro e escuro.
@immutable
class PaletaDeDestaque {
  /// Primária no tema claro.
  final Color primariaClaro;

  /// Sobre primária no tema claro.
  final Color sobrePrimariaClaro;

  /// Destaque suave no tema claro.
  final Color destaqueClaro;

  /// Medalhão claro no tema claro.
  final Color medalhaoClaro;

  /// Superfície sutil no tema claro.
  final Color superficieSutilClaro;

  /// Stop inicial do gradiente herói no tema claro.
  final Color gradienteHeroiInicioClaro;

  /// Stop final do gradiente herói no tema claro.
  final Color gradienteHeroiFimClaro;

  /// Texto sobre gradiente herói no tema claro.
  final Color sobreGradienteHeroiClaro;

  /// Primária no tema escuro.
  final Color primariaEscuro;

  /// Sobre primária no tema escuro.
  final Color sobrePrimariaEscuro;

  /// Destaque suave no tema escuro.
  final Color destaqueEscuro;

  /// Medalhão no tema escuro.
  final Color medalhaoEscuro;

  /// Superfície sutil no tema escuro.
  final Color superficieSutilEscuro;

  /// Stop inicial do gradiente herói no tema escuro.
  final Color gradienteHeroiInicioEscuro;

  /// Stop final do gradiente herói no tema escuro.
  final Color gradienteHeroiFimEscuro;

  /// Texto sobre gradiente herói no tema escuro.
  final Color sobreGradienteHeroiEscuro;

  /// Cria uma paleta de destaque.
  const PaletaDeDestaque({
    required this.primariaClaro,
    required this.sobrePrimariaClaro,
    required this.destaqueClaro,
    required this.medalhaoClaro,
    required this.superficieSutilClaro,
    required this.gradienteHeroiInicioClaro,
    required this.gradienteHeroiFimClaro,
    required this.sobreGradienteHeroiClaro,
    required this.primariaEscuro,
    required this.sobrePrimariaEscuro,
    required this.destaqueEscuro,
    required this.medalhaoEscuro,
    required this.superficieSutilEscuro,
    required this.gradienteHeroiInicioEscuro,
    required this.gradienteHeroiFimEscuro,
    required this.sobreGradienteHeroiEscuro,
  });
}
