import 'package:flutter/material.dart' show IconData, Icons;

/// Os desenhos da barra inferior (feature 013, FR-045, R5).
///
/// Enum, e não `IconData` solto: um desenho que não existe **não compila**, e
/// cada destino é obrigado a ter o seu.
///
/// ## A família única
///
/// Todo ícone do aplicativo é da variante **arredondada** dos ícones Material
/// que vêm com o Flutter (`Icons.*_rounded`) — a mesma que o resto das telas
/// já usa. Os seis SVG próprios da feature 004 (`assets/icones/navegacao/`)
/// saíram: eram uma segunda família, e dois estilos de desenho na mesma tela
/// era justamente o que a feature 013 veio desfazer.
///
/// A família arredondada não tem versão só com contorno para estes três
/// desenhos, e por isso o destino atual **não** se distingue pelo ícone
/// preenchido (era um dos sinais da 004). Ele continua marcado por mais de um
/// sinal além da cor: o indicador deslizante, a pílula atrás do ícone e o
/// rótulo em negrito.
enum IconeDeNavegacao {
  /// A engrenagem: Ajustes.
  ajustes(Icons.settings_rounded),

  /// A casa: Início.
  inicio(Icons.home_rounded),

  /// A pessoa: Meu perfil.
  perfil(Icons.person_rounded);

  const IconeDeNavegacao(this.dados);

  /// O desenho, da família arredondada.
  final IconData dados;
}
