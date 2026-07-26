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
}
