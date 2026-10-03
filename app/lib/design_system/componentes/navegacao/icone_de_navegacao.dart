/// Os desenhos da barra inferior (feature 004, T112, FR-015).
///
/// Enum, e não caminho solto de arquivo: um desenho que não existe **não
/// compila**, e cada destino é obrigado a ter as duas versões.
///
/// ## Por que desenhados, e não `Icons.*`
///
/// Os ícones do Material vêm de grades e pesos diferentes — a casa é mais
/// cheia que a engrenagem, a pessoa mais fina que as duas — e a revisão da
/// T044 pediu justamente "peso visual igual entre os três". Estes seis SVG
/// (três destinos × contorno e preenchido) saem da **mesma grade 24×24, do
/// mesmo traço de 2 e da mesma área**, de 3 a 21 nos dois eixos.
///
/// ## Contorno e preenchido
///
/// O destino atual usa a versão **preenchida**; os outros, a **contornada**.
/// É um dos sinais além da cor que a FR-015 exige: quem não distingue a
/// primária da cor do texto ainda vê qual desenho está cheio.
///
/// Os arquivos não têm cor própria (`currentColor`): quem os desenha os tinge
/// pelo tema, e por isso valem nos três temas sem uma linha a mais.
enum IconeDeNavegacao {
  /// A engrenagem: Ajustes.
  ajustes('ajustes'),

  /// A casa: Início.
  inicio('inicio'),

  /// A pessoa: Meu perfil.
  perfil('perfil');

  const IconeDeNavegacao(this._nome);

  final String _nome;

  /// O desenho só com o contorno — destino que **não** é o atual.
  String get caminhoContornado =>
      'assets/icones/navegacao/${_nome}_contorno.svg';

  /// O desenho cheio — o destino atual.
  String get caminhoPreenchido =>
      'assets/icones/navegacao/${_nome}_preenchido.svg';

  /// O arquivo do desenho, conforme o destino seja o atual ou não.
  String caminho({required bool preenchido}) =>
      preenchido ? caminhoPreenchido : caminhoContornado;
}
