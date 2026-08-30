import 'package:flutter/foundation.dart';

import '../../../../l10n/textos_autenticacao.dart';
import '../../domain/autenticacao.dart';
import 'controlador_cadastro.dart' show RegraDeSenha;

/// Em que ponto da recuperação a pessoa está.
enum EtapaRecuperacao {
  /// Informando o e-mail ou telefone da conta.
  pedirCodigo,

  /// Digitando o número recebido e escolhendo a senha nova.
  definirSenha,

  /// Senha trocada, sessão nova em mãos.
  concluida,
}

/// Controla a recuperação de acesso (T072, US3).
///
/// ## A regra que decide tudo aqui é a FR-019
///
/// Depois de pedir o código, o controlador vai para [EtapaRecuperacao.definirSenha]
/// **sempre** — exista a conta ou não. Ele nem tem como saber qual dos dois
/// aconteceu: o servidor responde `202` nos dois casos, e o repositório devolve
/// [CanalConcluido] nos dois.
///
/// Isso é deliberado até no formato do código. Se um dia alguém acrescentar um
/// ramo aqui que trate "conta inexistente" de forma diferente, essa pessoa terá
/// que inventar de onde essa informação veio — e é aí que vai perceber que
/// inventá-la é o vazamento.
///
/// ## Por que "pedir outro número" volta à primeira etapa
///
/// O reenvio poderia acontecer sem sair do lugar, como na confirmação de canal.
/// Mas ali o canal foi digitado três telas antes e está certo; aqui ele acabou
/// de ser escrito por alguém que já está com dificuldade. **O motivo mais comum
/// de "não recebi" é o e-mail digitado errado**, e voltar mostra o identificador
/// para conferência antes de reenviar. Custa um toque a mais e resolve os dois
/// casos — o número que se perdeu e o endereço que estava errado.
///
/// ## O que este controlador não faz
///
/// Não revoga sessão (FR-021) nem notifica ninguém (FR-022): as duas coisas são
/// do servidor. Aqui só cabe contar à pessoa que aconteceram.
class ControladorRecuperacao extends ChangeNotifier {
  final RepositorioAutenticacao _repositorio;

  /// Cria o controlador.
  ///
  /// [identificadorInicial] vem da tela de login, que já o tinha preenchido do
  /// último acesso (FR-012). Pedir de novo o que está na tela anterior seria
  /// desfazer justamente a barreira que aquela regra removeu.
  ControladorRecuperacao(
    this._repositorio, {
    String identificadorInicial = '',
  }) : _identificador = identificadorInicial;

  String _identificador;
  String _codigo = '';
  String _senha = '';

  EtapaRecuperacao _etapa = EtapaRecuperacao.pedirCodigo;
  bool _enviando = false;
  FalhaAutenticacao? _falha;
  int _segundosDeEspera = 0;
  PessoaAutenticada? _pessoa;

  /// E-mail ou telefone informado.
  String get identificador => _identificador;

  /// Número de 6 dígitos digitado.
  String get codigo => _codigo;

  /// Senha nova digitada.
  String get senha => _senha;

  /// Etapa atual.
  EtapaRecuperacao get etapa => _etapa;

  /// Verdadeiro enquanto uma chamada está em andamento.
  bool get enviando => _enviando;

  /// Pessoa autenticada, depois da troca.
  PessoaAutenticada? get pessoa => _pessoa;

  /// Regras de senha atendidas até agora, na ordem de [RegraDeSenha.todas].
  ///
  /// São **as mesmas do cadastro**, de propósito: uma senha criada aqui vale
  /// tanto quanto uma criada lá, e dois conjuntos de regras divergiriam na
  /// primeira vez que alguém mexesse num deles.
  List<bool> get regrasAtendidas =>
      RegraDeSenha.todas.map((RegraDeSenha r) => r.atende(_senha)).toList();

  /// Todas as regras de senha estão satisfeitas.
  bool get senhaValida => regrasAtendidas.every((bool ok) => ok);

  /// O pedido de código pode ser enviado.
  bool get podePedirCodigo => _identificador.trim().isNotEmpty && !_enviando;

  /// A troca de senha pode ser enviada.
  bool get podeTrocarSenha =>
      _codigo.length == 6 && senhaValida && !_enviando;

  /// Confirmação do pedido, **idêntica exista a conta ou não** (FR-019).
  ///
  /// Nula antes do pedido. Depois dele, é sempre a mesma frase.
  String? get confirmacaoDoPedido => _etapa == EtapaRecuperacao.definirSenha
      ? TextosAutenticacao.recuperacaoSolicitada(_identificador.trim())
      : null;

  /// Texto a exibir para a falha atual, na voz da Memora.
  String? get mensagemDeErro => switch (_falha) {
        null => null,
        FalhaAutenticacao.dadosInvalidos => TextosAutenticacao.codigoNaoConfere,
        FalhaAutenticacao.credenciaisInvalidas =>
          TextosAutenticacao.codigoNaoConfere,
        FalhaAutenticacao.semConexao => TextosAutenticacao.semConexao,
        FalhaAutenticacao.muitasTentativas =>
          TextosAutenticacao.esperaNaRecuperacao(_segundosDeEspera),
        FalhaAutenticacao.inesperada => TextosAutenticacao.inesperada,
      };

  /// Atualiza o identificador.
  void informarIdentificador(String valor) {
    _identificador = valor;
    _falha = null;
    notifyListeners();
  }

  /// Atualiza o número digitado.
  void informarCodigo(String valor) {
    _codigo = valor;
    notifyListeners();
  }

  /// Atualiza a senha nova.
  void informarSenha(String valor) {
    _senha = valor;
    notifyListeners();
  }

  /// Pede o código ao servidor e segue para a etapa da senha.
  ///
  /// **Segue sempre**, dando certo. Não há ramo para "conta não existe" porque
  /// não existe essa resposta: é o `202` da FR-019 refletido aqui.
  Future<void> pedirCodigo() async {
    if (_enviando || !podePedirCodigo) return;

    _enviando = true;
    _falha = null;
    notifyListeners();

    final ResultadoDeCanal resultado =
        await _repositorio.solicitarRecuperacao(_identificador.trim());

    _enviando = false;
    switch (resultado) {
      case CanalConcluido():
        _codigo = '';
        _etapa = EtapaRecuperacao.definirSenha;
      case CanalFalhou(:final FalhaAutenticacao falha):
        // Só chega aqui quando não deu para perguntar — rede fora, servidor
        // mudo. Nunca "essa conta não existe".
        _falha = falha;
    }
    notifyListeners();
  }

  /// Volta à primeira etapa para conferir o identificador e pedir de novo.
  void pedirOutroCodigo() {
    if (_enviando) return;
    _etapa = EtapaRecuperacao.pedirCodigo;
    _codigo = '';
    _falha = null;
    notifyListeners();
  }

  /// Troca a senha com o número recebido (FR-020, FR-021).
  ///
  /// Ignora chamadas concorrentes: dois toques no botão gastariam duas vezes um
  /// código que é de uso único, e a segunda chamada seria recusada — deixando a
  /// pessoa com a senha já trocada e uma mensagem de erro na tela.
  Future<void> trocarSenha() async {
    if (_enviando || !podeTrocarSenha) return;

    _enviando = true;
    _falha = null;
    notifyListeners();

    final ResultadoAutenticacao resultado =
        await _repositorio.confirmarRecuperacao(
      identificador: _identificador.trim(),
      codigo: _codigo,
      novaSenha: _senha,
    );

    _enviando = false;
    switch (resultado) {
      case AutenticacaoConcluida(:final PessoaAutenticada pessoa):
        _pessoa = pessoa;
        _etapa = EtapaRecuperacao.concluida;
      case AutenticacaoFalhou(
          :final FalhaAutenticacao falha,
          :final int? tentarNovamenteEmSegundos,
        ):
        _falha = falha;
        _segundosDeEspera = tentarNovamenteEmSegundos ?? 0;
        // O código digitado sai da tela: ele não serve mais, e deixá-lo ali
        // convida a tocar no botão de novo com o mesmo valor recusado. A senha
        // **fica**, como no cadastro (FR-006) — ela não é o que falhou.
        _codigo = '';
    }
    notifyListeners();
  }
}
