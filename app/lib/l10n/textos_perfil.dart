/// Textos do Perfil que dizem respeito à idade (T123, FR-042c).
///
/// Mesma estrutura de `textos_casca.dart`: as frases moram fora das telas, na
/// voz da Memora. O tom é de convite — a data é opcional e nada depende dela —
/// e os erros dizem o que fazer, sem bronca.
abstract final class TextosPerfil {
  // ---------------------------------------------------------------------------
  // Perfil geral (US8, FR-042)
  // ---------------------------------------------------------------------------

  /// Título da tela de perfil.
  static const String tituloPerfil = 'Meu perfil';

  /// Rótulo do nome.
  static const String rotuloNome = 'Como você quer ser chamada';

  /// Rótulo do canal de contato.
  static const String rotuloCanal = 'E-mail ou telefone da conta';

  /// Rótulo do aplicativo mais aprendido.
  static const String rotuloMaisAprendido = 'O que você mais aprendeu';

  /// Frase na voz da Memora quando a pessoa ainda não concluiu nenhum passo a passo.
  static const String maisAprendidoVazio = 'Ainda vamos aprender juntos!';

  // ---------------------------------------------------------------------------
  // A idade no Perfil
  // ---------------------------------------------------------------------------

  /// Rótulo da idade, mostrada como informação.
  static const String rotuloIdade = 'Idade';

  /// A idade por extenso: "1 ano", "72 anos".
  static String idade(int anos) {
    if (anos < 1) return 'Menos de 1 ano';
    return anos == 1 ? '1 ano' : '$anos anos';
  }

  /// Convite, quando a pessoa ainda não informou.
  static const String convite =
      'Se quiser, conte quando você nasceu e eu mostro a sua idade aqui. '
      'Fica só neste aparelho. Você não precisa informar.';

  /// Abre a tela de entrada, quando ainda não há data.
  static const String botaoInformar = 'Contar quando nasci';

  /// Abre a tela de entrada, quando já há data.
  static const String botaoMudar = 'Mudar a data';

  /// Tira a data do Perfil.
  static const String botaoTirar = 'Tirar a idade do meu perfil';

  /// Pergunta antes de tirar.
  static const String perguntaTirar = 'Tirar a sua idade do perfil?';

  /// O que acontece ao tirar.
  static const String avisoTirar =
      'A data de nascimento sai deste aparelho. Se quiser, você conta de novo '
      'depois.';

  /// Confirma a retirada.
  static const String botaoConfirmarTirar = 'Sim, tirar a idade';

  /// Desiste de tirar.
  static const String botaoManter = 'Não, deixar como está';

  // ---------------------------------------------------------------------------
  // A tela de entrada
  // ---------------------------------------------------------------------------

  /// Título da tela.
  static const String tituloEntrada = 'Quando você nasceu';

  /// Rótulo do dia.
  static const String rotuloDia = 'Dia';

  /// Ajuda do dia.
  static const String ajudaDia = 'O dia do mês, de 1 a 31.';

  /// Rótulo do mês.
  static const String rotuloMes = 'Mês';

  /// Ajuda do mês.
  static const String ajudaMes = 'O número do mês, de 1 a 12.';

  /// Rótulo do ano.
  static const String rotuloAno = 'Ano';

  /// Ajuda do ano.
  static const String ajudaAno = 'Com quatro números, como 1952.';

  /// Guarda a data.
  static const String botaoGuardar = 'Guardar';

  /// Desiste.
  static const String botaoCancelar = 'Cancelar';

  /// Falta preencher algo.
  static const String erroIncompleta =
      'Falta preencher o dia, o mês e o ano. Use só números.';

  /// Ano curto demais.
  static const String erroAnoCurto =
      'Escreva o ano com quatro números, como 1952.';

  /// Não foi possível guardar (falha do aparelho).
  static const String erroAoGuardar =
      'Não consegui guardar agora. Tente de novo.';

  /// Data que não existe.
  static const String erroImpossivel =
      'Essa data não existe no calendário. Confira o dia e o mês.';

  /// Data que ainda não chegou.
  static const String erroFutura = 'Essa data ainda não chegou. Confira o ano.';

  /// Data de mais de 120 anos.
  static const String erroAntiga =
      'Essa data ficou longe demais. Confira o ano.';
}
