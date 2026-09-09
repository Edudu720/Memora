import '../../features/autenticacao/data/ultimo_acesso_local.dart';
import 'cofre_de_credenciais.dart';

/// Tira do aparelho o que a saída da conta precisa levar (T077, FR-026).
///
/// ## A contradição que esta classe resolve, e como
///
/// A FR-026 manda remover "todo dado pessoal e toda credencial" ao encerrar a
/// sessão. A FR-012 manda preencher previamente o identificador do último
/// acesso — e identificador **é** dado pessoal. As duas se cruzam no caso mais
/// comum de todos: a pessoa sai da conta e volta depois.
///
/// **A equipe decidiu manter o identificador** (2026-09-08, Henrique). O
/// raciocínio: apagar torna a FR-012 inútil justamente quando ela mais serve,
/// e o público desta feature é quem tem mais dificuldade em digitar um e-mail
/// inteiro. O que a FR-026 protege de verdade — o acesso à conta — é protegido
/// integralmente, porque **toda credencial vai embora**. Quem pegar o aparelho
/// encontra um e-mail preenchido e nenhuma forma de entrar com ele.
///
/// A decisão fica aqui e não espalhada: quem discordar muda [esquecerTudo] para
/// o padrão, num lugar só, e o teste que a fixa está em
/// `saida_limpa_armazenamento_test.dart`.
///
/// ## O que nunca é negociável
///
/// Token de acesso e refresh token saem **sempre**, e antes de qualquer outra
/// coisa. Se a limpeza falhar no meio, o que já terá acontecido é o que mais
/// importa: o refresh de 60 dias, que é o que realmente abre a conta, já não
/// está lá.
class LimpezaDeSessao {
  final CofreDeCredenciais _cofre;
  final UltimoAcesso _ultimoAcesso;

  /// Cria a limpeza sobre o cofre e o registro de último acesso.
  const LimpezaDeSessao({
    required CofreDeCredenciais cofre,
    required UltimoAcesso ultimoAcesso,
  })  : _cofre = cofre,
        _ultimoAcesso = ultimoAcesso;

  /// Remove do aparelho o que a saída leva.
  ///
  /// [esquecerTudo] apaga também o identificador do último acesso — é a leitura
  /// literal da FR-026, e o que faz sentido num aparelho compartilhado ou que
  /// vai ser vendido. Não é o padrão pelo motivo no cabeçalho.
  Future<void> executar({bool esquecerTudo = false}) async {
    // Primeiro e sempre: o que abre a conta.
    await _cofre.limpar();

    if (esquecerTudo) {
      await _ultimoAcesso.esquecer();
    }
  }
}
