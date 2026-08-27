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

  /// Identificador do canal principal, quando o servidor o informa.
  ///
  /// É o que o cadastro assistido precisa para pedir e confirmar o código de
  /// posse (FR-062): sem ele, o aplicativo teria a conta criada e nenhuma
  /// forma de dizer *qual* canal está confirmando.
  final String? canalId;

  /// A posse do canal já foi confirmada?
  ///
  /// No cadastro comum isto começa `false` e não bloqueia nada. No modo
  /// assistido é o que separa a conta que já pode ser usada da que ainda
  /// espera — o servidor recusa a entrada enquanto for `false`.
  final bool canalVerificado;

  /// Cria uma pessoa autenticada.
  const PessoaAutenticada({
    required this.id,
    required this.nomeTratamento,
    this.canalId,
    this.canalVerificado = false,
  });
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

  /// Pede que o servidor envie um código de 6 dígitos ao canal (T058, R5).
  ///
  /// Responde igual exista ou não o canal, e pertença ele a quem for: o
  /// servidor devolve `202` sempre, para que este caminho não vire um oráculo
  /// de quais identificadores existem. Pedir de novo **invalida** o código
  /// anterior — quem tocar duas vezes em "reenviar" deve digitar o segundo.
  Future<ResultadoDeCanal> enviarCodigoDeCanal(String canalId);

  /// Confirma a posse do canal com o código recebido (FR-052, FR-062).
  ///
  /// É o que conclui o cadastro assistido: enquanto a posse não é confirmada, a
  /// conta existe mas não entra. A recusa é uma só — código errado, vencido, já
  /// usado e canal alheio dizem a mesma coisa.
  Future<ResultadoDeCanal> confirmarCanal(String canalId, String codigo);

  /// Pede um código para recuperar o acesso (FR-018, FR-019).
  ///
  /// **Responde igual exista a conta ou não.** O servidor devolve `202`
  /// sempre, e este método devolve [CanalConcluido] sempre que a chamada
  /// chegar — inclusive para um identificador que não pertence a ninguém.
  /// [CanalFalhou] aqui significa *não consegui perguntar*, e nunca *essa
  /// conta não existe*: distinguir os dois casos daria a quem tentasse a lista
  /// de quem tem conta no Memora, que é o que a FR-019 existe para negar.
  ///
  /// Só vai para canal **verificado** — é o que a FR-052 exige, e o que o modo
  /// assistido da US5 tornou possível: sem posse confirmada, um acompanhante
  /// que cadastrasse o próprio contato controlaria a recuperação da conta
  /// alheia para sempre (FR-062).
  Future<ResultadoDeCanal> solicitarRecuperacao(String identificador);

  /// Define a senha nova com o código recebido (FR-020, FR-021).
  ///
  /// Devolve sessão porque a troca **já é um acesso**: a pessoa provou posse
  /// do canal e escolheu a senha, e mandá-la digitar de novo o que acabou de
  /// criar seria burocracia. O contrato responde `200` com sessão por isso.
  ///
  /// A recusa é **uma só** — código errado, vencido e já usado dizem a mesma
  /// coisa, como na confirmação de canal. Separá-los contaria a quem está
  /// adivinhando em que ponto do espaço de códigos ele chegou.
  ///
  /// Do outro lado, o servidor **revoga todas as sessões** (FR-021) e notifica
  /// pelo canal cadastrado (FR-022). Nada disso é responsabilidade daqui.
  Future<ResultadoAutenticacao> confirmarRecuperacao({
    required String identificador,
    required String codigo,
    required String novaSenha,
  });
}

/// Resultado de uma operação sobre canal de contato.
///
/// Separado de [ResultadoAutenticacao] de propósito: confirmar um canal **não**
/// produz sessão nem troca quem está autenticado. Reaproveitar o outro tipo
/// obrigaria a inventar uma [PessoaAutenticada] onde não há nenhuma novidade
/// sobre a pessoa.
@immutable
sealed class ResultadoDeCanal {
  const ResultadoDeCanal();
}

/// A operação sobre o canal deu certo.
@immutable
class CanalConcluido extends ResultadoDeCanal {
  /// Cria um resultado de sucesso.
  const CanalConcluido();
}

/// A operação sobre o canal falhou.
@immutable
class CanalFalhou extends ResultadoDeCanal {
  /// Qual falha ocorreu.
  final FalhaAutenticacao falha;

  /// Cria um resultado de falha.
  const CanalFalhou(this.falha);
}
