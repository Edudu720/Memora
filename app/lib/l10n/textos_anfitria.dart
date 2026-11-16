/// As dicas da anfitriã do Início (feature 013, T086; FR-050).
///
/// ## Por que a lista mora aqui, fixa
///
/// A anfitriã **fala** com a pessoa assim que ela entra, e o que ela diz tem a
/// cara da Memora. Se as dicas viessem da IA ou do servidor, quem conseguisse
/// alterá-las faria a Memora "dizer" qualquer coisa ("toque aqui para
/// atualizar seu cadastro"). Por isso a lista é **escrita pela equipe, dentro
/// do aplicativo, e revista na PR**: mudar uma dica é mudar este arquivo.
///
/// ## A voz
///
/// Primeira pessoa, convite a fazer junto, no máximo duas frases por dica
/// (FR-016). Sem emoji, sem "idoso" e sem frase de incapacidade: o portão
/// `texto_da_interface_test.dart` varre este arquivo.
///
/// ## O formato
///
/// Cada dica é uma `static const String`, para o portão de texto enxergá-la.
/// [dicas] só as junta, na ordem em que aparecem: os lembretes antigolpe
/// ficam espalhados no meio das dicas de uso, e não todos juntos no fim —
/// quem espera uma dica de uso ouve o aviso sem ter de procurá-lo.
abstract final class TextosAnfitria {
  /// O que o leitor de tela diz da anfitriã, que é uma ação (FR-055).
  static const String rotuloDaAcao = 'Outra dica da Memora';

  // ---------------------------------------------------------------------------
  // Usar o celular e o Memora
  // ---------------------------------------------------------------------------

  /// Dica de uso: o passo a passo.
  static const String dicaPassoAPasso =
      'Cada guia mostra a tela do celular, um passo de cada vez. '
      'Eu fico com você até o fim.';

  /// Dica de uso: perguntar.
  static const String dicaPerguntar =
      'Pode me perguntar qualquer dúvida sobre o celular. Eu respondo com '
      'calma, quantas vezes precisar.';

  /// Dica de uso: letra maior.
  static const String dicaLetraMaior =
      'A letra está pequena? Em Ajustes, vamos deixá-la do tamanho que for '
      'melhor para você.';

  /// Dica de uso: errar um toque.
  static const String dicaErrarToque =
      'Tocou no lugar errado? Acontece com todo mundo, é só voltar e tentar '
      'de novo.';

  /// Dica de uso: o ritmo.
  static const String dicaRitmo =
      'Aqui você aprende no seu ritmo. Pode parar agora e continuar outro dia.';

  /// Dica de uso: as cores.
  static const String dicaCores =
      'Quer outra cor para o Memora? Em Ajustes você escolhe a que mais '
      'agrada aos seus olhos.';

  /// Dica de uso: palavra desconhecida.
  static const String dicaPalavra =
      'Apareceu uma palavra que você não conhece? Me pergunte, que eu explico '
      'em português simples.';

  /// Dica de uso: a pressa.
  static const String dicaSemPressa =
      'Não tenho pressa nenhuma. Leia no seu tempo, e a gente segue junto.';

  /// Dica de uso: a conta se fecha sozinha.
  static const String dicaContaSegura =
      'Se o celular ficar parado por muito tempo, eu fecho a sua conta para '
      'protegê-la. É só entrar de novo.';

  /// Dica de uso: aprender fazendo.
  static const String dicaFazerJunto =
      'Vamos escolher um aplicativo e aprender a usá-lo juntos? '
      'Eu mostro cada passo.';

  // ---------------------------------------------------------------------------
  // Lembretes antigolpe (FR-050: pelo menos três)
  // ---------------------------------------------------------------------------

  /// Antigolpe: o que a Memora nunca pede.
  static const String antigolpeSenha =
      'Eu nunca peço a sua senha nem o código que chega por mensagem. '
      'Se alguém pedir, é golpe.';

  /// Antigolpe: o falso atendente do banco.
  static const String antigolpeBanco =
      'O banco de verdade não liga pedindo senha. Desligue e ligue para o '
      'número que está no cartão.';

  /// Antigolpe: a pressa e o link.
  static const String antigolpeLink =
      'Mensagem com pressa e um link estranho? Não toque e fale antes com '
      'alguém de confiança.';

  /// Antigolpe: o código de verificação.
  static const String antigolpeCodigo =
      'Ninguém precisa do seu código de verificação, nem quem diz ser do '
      'suporte. Guarde-o só para você.';

  /// As dicas, na ordem em que aparecem (12 a 16, FR-050).
  static const List<String> dicas = <String>[
    dicaPassoAPasso,
    dicaPerguntar,
    antigolpeSenha,
    dicaLetraMaior,
    dicaErrarToque,
    antigolpeBanco,
    dicaRitmo,
    dicaCores,
    antigolpeLink,
    dicaPalavra,
    dicaSemPressa,
    antigolpeCodigo,
    dicaContaSegura,
    dicaFazerJunto,
  ];
}
