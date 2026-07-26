import 'package:flutter/foundation.dart';

import '../../domain/autenticacao.dart';

/// Regras de senha, verificadas em tempo real enquanto a pessoa digita.
///
/// A política prioriza **comprimento** sobre complexidade simbólica (FR-042).
/// Exigir maiúscula, número e símbolo leva pessoas idosas a anotar a senha em
/// papel — o que piora a segurança real em vez de melhorar.
@immutable
class RegraDeSenha {
  /// Texto exibido à pessoa.
  final String descricao;

  /// Verifica se a senha atende à regra.
  final bool Function(String) atende;

  /// Cria uma regra de senha.
  const RegraDeSenha(this.descricao, this.atende);

  /// As regras aplicadas no cadastro.
  static final List<RegraDeSenha> todas = <RegraDeSenha>[
    RegraDeSenha('Ter pelo menos 10 letras', (String s) => s.length >= 10),
    RegraDeSenha(
      'Não ser uma senha muito comum',
      (String s) => !_comuns.contains(s.toLowerCase()),
    ),
  ];

  static const Set<String> _comuns = <String>{
    '1234567890',
    'senha123456',
    'password12',
    'memora1234',
    'abcdefghij',
  };
}

/// Estado do formulário de cadastro.
enum EstadoCadastro {
  /// Aguardando preenchimento.
  preenchendo,

  /// Enviando ao servidor.
  enviando,

  /// Conta criada e sessão iniciada.
  concluido,

  /// Algo deu errado.
  comErro,
}

/// Controla o formulário de cadastro.
///
/// Guarda o que já foi digitado mesmo quando ocorre erro (FR-006): apagar o
/// formulário de alguém que errou um campo é a forma mais rápida de fazer a
/// pessoa desistir.
class ControladorCadastro extends ChangeNotifier {
  final RepositorioAutenticacao _repositorio;

  /// Cria o controlador.
  ControladorCadastro(this._repositorio);

  String _nome = '';
  String _canal = '';
  String _senha = '';
  TipoCanal _tipoCanal = TipoCanal.email;
  bool _modoAssistido = false;

  EstadoCadastro _estado = EstadoCadastro.preenchendo;
  FalhaAutenticacao? _falha;
  PessoaAutenticada? _pessoa;
  bool _tentouEnviar = false;

  /// Nome de tratamento informado.
  String get nome => _nome;

  /// Canal informado.
  String get canal => _canal;

  /// Tipo do canal escolhido.
  TipoCanal get tipoCanal => _tipoCanal;

  /// Se há acompanhante ajudando (decisão D3).
  bool get modoAssistido => _modoAssistido;

  /// Estado atual do formulário.
  EstadoCadastro get estado => _estado;

  /// Falha ocorrida, se houver.
  FalhaAutenticacao? get falha => _falha;

  /// Pessoa autenticada, após o sucesso.
  PessoaAutenticada? get pessoa => _pessoa;

  /// Verdadeiro enquanto o envio está em andamento.
  bool get enviando => _estado == EstadoCadastro.enviando;

  /// Regras de senha atendidas até agora.
  List<bool> get regrasAtendidas =>
      RegraDeSenha.todas.map((RegraDeSenha r) => r.atende(_senha)).toList();

  /// Todas as regras de senha estão satisfeitas.
  bool get senhaValida => regrasAtendidas.every((bool ok) => ok);

  /// O formulário pode ser enviado.
  bool get podeEnviar =>
      _nome.trim().length >= 2 && _canalValido && senhaValida && !enviando;

  bool get _canalValido {
    final String v = _canal.trim();
    if (v.isEmpty) return false;
    return switch (_tipoCanal) {
      TipoCanal.email => v.contains('@') && v.contains('.'),
      TipoCanal.telefone => v.replaceAll(RegExp(r'\D'), '').length >= 10,
    };
  }

  /// Erro do canal, exibido apenas **depois** que a pessoa tentou enviar ou
  /// saiu do campo — nunca enquanto ela ainda está digitando.
  String? get erroCanal {
    if (!_tentouEnviar || _canalValido || _canal.isEmpty) return null;
    return switch (_tipoCanal) {
      TipoCanal.email =>
        'Não consegui entender esse e-mail. Pode conferir se está completo?',
      TipoCanal.telefone =>
        'Esse telefone parece incompleto. Pode conferir o DDD?',
    };
  }

  /// Erro do nome.
  String? get erroNome {
    if (!_tentouEnviar || _nome.trim().length >= 2) return null;
    return 'Como você gostaria que eu te chamasse?';
  }

  /// Atualiza o nome.
  void informarNome(String valor) {
    _nome = valor;
    notifyListeners();
  }

  /// Atualiza o canal.
  void informarCanal(String valor) {
    _canal = valor;
    notifyListeners();
  }

  /// Atualiza a senha.
  void informarSenha(String valor) {
    _senha = valor;
    notifyListeners();
  }

  /// Troca entre e-mail e telefone.
  void escolherTipoCanal(TipoCanal tipo) {
    _tipoCanal = tipo;
    _canal = '';
    notifyListeners();
  }

  /// Liga ou desliga o modo assistido.
  void definirModoAssistido(bool assistido) {
    _modoAssistido = assistido;
    notifyListeners();
  }

  /// Envia o cadastro.
  ///
  /// Ignora chamadas concorrentes: toque duplo no botão não pode criar duas
  /// contas (edge case da spec).
  Future<void> enviar() async {
    _tentouEnviar = true;
    if (enviando) return;
    if (!podeEnviar) {
      notifyListeners();
      return;
    }

    _estado = EstadoCadastro.enviando;
    _falha = null;
    notifyListeners();

    final ResultadoAutenticacao resultado = await _repositorio.cadastrar(
      DadosDeCadastro(
        nomeTratamento: _nome.trim(),
        tipoCanal: _tipoCanal,
        canal: _canal.trim().toLowerCase(),
        senha: _senha,
        modoAssistido: _modoAssistido,
      ),
    );

    switch (resultado) {
      case AutenticacaoConcluida(:final PessoaAutenticada pessoa):
        _pessoa = pessoa;
        _estado = EstadoCadastro.concluido;
      case AutenticacaoFalhou(:final FalhaAutenticacao falha):
        _falha = falha;
        _estado = EstadoCadastro.comErro;
    }
    notifyListeners();
  }

  /// Volta ao preenchimento após um erro, **preservando o que foi digitado**.
  void tentarNovamente() {
    _estado = EstadoCadastro.preenchendo;
    _falha = null;
    notifyListeners();
  }
}
