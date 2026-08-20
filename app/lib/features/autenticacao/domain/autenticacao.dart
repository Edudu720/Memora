import 'package:flutter/foundation.dart' show immutable;

/// Tipo do canal de contato escolhido no cadastro (decisão D1).
enum TipoCanal {
  /// Endereço de e-mail.
  email,

  /// Número de telefone celular.
  telefone;

  /// Nome exibido à pessoa.
  String get rotulo => switch (this) {
        TipoCanal.email => 'E-mail',
        TipoCanal.telefone => 'Telefone',
      };
}

/// Pessoa autenticada no Memora.
@immutable
class PessoaAutenticada {
  /// Identificador da conta.
  final String id;

  /// Como a pessoa quer ser chamada. **Nunca é credencial** (FR-003).
  final String nomeTratamento;

  /// Cria uma pessoa autenticada.
  const PessoaAutenticada({required this.id, required this.nomeTratamento});
}

/// Dados informados no cadastro.
@immutable
class DadosDeCadastro {
  /// Como a pessoa quer ser chamada.
  final String nomeTratamento;

  /// Tipo do canal informado.
  final TipoCanal tipoCanal;

  /// Valor do canal — e-mail ou telefone.
  final String canal;

  /// Senha escolhida.
  final String senha;

  /// Houve acompanhante no cadastro (decisão D3).
  final bool modoAssistido;

  /// Cria os dados de cadastro.
  const DadosDeCadastro({
    required this.nomeTratamento,
    required this.tipoCanal,
    required this.canal,
    required this.senha,
    this.modoAssistido = false,
  });
}

/// Dados informados no login (FR-011).
///
/// Carrega **apenas identificador e senha**. Não existe campo de tipo aqui: quem
/// decide se o valor é e-mail ou telefone é o servidor, pela presença do `@`.
/// Perguntar o tipo devolveria à pessoa a pergunta *"com qual dos dois você se
/// cadastrou?"* — que é exatamente o que a FR-051 existe para evitar.
@immutable
class DadosDeEntrada {
  /// E-mail ou telefone com que a pessoa se cadastrou.
  final String identificador;

  /// Senha escolhida no cadastro.
  final String senha;

  /// Cria os dados de entrada.
  const DadosDeEntrada({required this.identificador, required this.senha});
}

/// Falhas previstas da autenticação.
///
/// São **códigos**, não mensagens: o texto exibido vive na camada de
/// apresentação, para que a persona da Memora fique num lugar só.
enum FalhaAutenticacao {
  /// Dados recusados pelo servidor.
  dadosInvalidos,

  /// Identificador ou senha não conferem. **Deliberadamente genérica**
  /// (FR-013): não distingue conta inexistente de senha errada.
  credenciaisInvalidas,

  /// Bloqueio temporário por excesso de tentativas.
  muitasTentativas,

  /// Sem conexão.
  semConexao,

  /// Qualquer outra falha inesperada.
  inesperada,
}

/// Resultado de uma operação de autenticação.
@immutable
sealed class ResultadoAutenticacao {
  const ResultadoAutenticacao();
}

/// A operação deu certo.
@immutable
class AutenticacaoConcluida extends ResultadoAutenticacao {
  /// Quem foi autenticado.
  final PessoaAutenticada pessoa;

  /// Cria um resultado de sucesso.
  const AutenticacaoConcluida(this.pessoa);
}

/// A operação falhou.
@immutable
class AutenticacaoFalhou extends ResultadoAutenticacao {
  /// Qual falha ocorreu.
  final FalhaAutenticacao falha;

  /// Quando tentar de novo, em segundos. Presente apenas em bloqueio.
  final int? tentarNovamenteEmSegundos;

  /// Cria um resultado de falha.
  const AutenticacaoFalhou(this.falha, {this.tentarNovamenteEmSegundos});
}

/// Contrato de autenticação usado pela camada de apresentação.
///
/// A implementação real conversa com a API pelo cliente **gerado** a partir de
/// `contracts/openapi.yaml` (decisão R8). A interface existe para que as telas
/// possam ser construídas e testadas sem depender do backend estar de pé.
abstract interface class RepositorioAutenticacao {
  /// Cria a conta e **já devolve a pessoa autenticada** (FR-009).
  ///
  /// Quando o canal já pertence a alguém, o resultado é **idêntico** ao de um
  /// cadastro novo, sem revelar a existência da conta (FR-010).
  Future<ResultadoAutenticacao> cadastrar(DadosDeCadastro dados);

  /// Entra com identificador e senha (FR-011).
  ///
  /// A recusa é **sempre** [FalhaAutenticacao.credenciaisInvalidas], sem
  /// distinguir conta inexistente de senha errada (FR-013). Depois de falhas
  /// seguidas vem [FalhaAutenticacao.muitasTentativas], e aí
  /// `tentarNovamenteEmSegundos` traz a espera que a FR-015 manda anunciar.
  Future<ResultadoAutenticacao> entrar(DadosDeEntrada dados);

  /// Troca o refresh guardado por uma sessão nova, sem pedir senha (FR-016).
  ///
  /// O refresh **rotaciona a cada uso**: a implementação precisa guardar o par
  /// novo no lugar do antigo. Apresentar duas vezes o mesmo refresh é o que o
  /// servidor trata como roubo, e ele derruba a família inteira de tokens.
  Future<ResultadoAutenticacao> renovarSessao();

  /// Encerra a sessão **neste aparelho**.
  ///
  /// Existe porque a FR-017 manda encerrar a sessão por inatividade, e não há
  /// como encerrar nada sem isto: sem apagar a credencial local, o monitor
  /// levaria a pessoa ao login e a renovação automática a colocaria de volta
  /// dentro no mesmo instante.
  ///
  /// **É só o lado do aparelho.** Revogar a sessão no servidor depende de
  /// `POST /v1/auth/sair`, que é a T074 e ainda não existe. Enquanto isso, o
  /// refresh apagado aqui continua válido lá até vencer — limitação conhecida,
  /// que a US4 fecha junto com a T077.
  Future<void> encerrarSessao();
}
