import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../l10n/textos_autenticacao.dart';
import '../../data/ultimo_acesso_local.dart';
import '../../domain/autenticacao.dart';

/// Estado da tela de login.
enum EstadoLogin {
  /// Tentando renovar a sessão antes de mostrar qualquer formulário.
  iniciando,

  /// Aguardando identificador e senha.
  preenchendo,

  /// Falando com o servidor.
  enviando,

  /// Bloqueado por excesso de tentativas (FR-014).
  bloqueado,

  /// Entrou.
  concluido,

  /// Algo deu errado, e não foi bloqueio.
  comErro,
}

/// Controla a tela de login (T051).
///
/// ## A renovação automática vem antes do formulário
///
/// A FR-016 manda manter a pessoa conectada entre usos, e o cenário 1 da US2 é
/// explícito: *"reabro o aplicativo e continuo conectada sem digitar nada"*.
/// Por isso [iniciar] tenta **renovar a sessão em silêncio** antes de exibir
/// campo nenhum. O formulário só aparece quando essa tentativa falha — e aí já
/// vem com o identificador do último acesso preenchido (FR-012), que é o
/// cenário 2.
///
/// Mostrar o formulário primeiro e renovar depois faria a tela piscar entre
/// "digite sua senha" e "bem-vinda de volta". Para quem tem dificuldade de
/// leitura, essa piscada é indistinguível de defeito.
///
/// ## O bloqueio se desfaz sozinho
///
/// Quando o servidor responde `429`, ele manda **o número de segundos**, não a
/// frase. O controlador transforma isso numa contagem regressiva que libera o
/// botão ao chegar a zero. Sem isso a FR-015 ficaria pela metade: a pessoa
/// saberia que precisa esperar, mas teria que adivinhar quando parou de esperar.
class ControladorLogin extends ChangeNotifier {
  final RepositorioAutenticacao _repositorio;
  final UltimoAcesso _ultimoAcesso;

  /// Cria o controlador.
  ControladorLogin(this._repositorio, this._ultimoAcesso);

  String _identificador = '';
  String _senha = '';

  EstadoLogin _estado = EstadoLogin.iniciando;
  FalhaAutenticacao? _falha;
  PessoaAutenticada? _pessoa;
  bool _veioDoUltimoAcesso = false;

  int _segundosRestantes = 0;
  Timer? _contagem;

  /// Identificador digitado.
  String get identificador => _identificador;

  /// Senha digitada.
  String get senha => _senha;

  /// Estado atual.
  EstadoLogin get estado => _estado;

  /// Falha ocorrida, se houver.
  FalhaAutenticacao? get falha => _falha;

  /// Pessoa autenticada, após o sucesso.
  PessoaAutenticada? get pessoa => _pessoa;

  /// Verdadeiro enquanto o envio está em andamento.
  bool get enviando => _estado == EstadoLogin.enviando;

  /// Verdadeiro enquanto a sessão está sendo renovada em silêncio.
  bool get iniciando => _estado == EstadoLogin.iniciando;

  /// Verdadeiro durante o bloqueio temporário.
  bool get bloqueado => _estado == EstadoLogin.bloqueado;

  /// Quantos segundos faltam do bloqueio.
  int get segundosRestantes => _segundosRestantes;

  /// O identificador foi preenchido a partir do último acesso (FR-012).
  ///
  /// Deixa de ser verdadeiro assim que a pessoa edita o campo: o aviso *"deixei
  /// preenchido do seu último acesso"* mentiria sobre um valor que ela mesma
  /// acabou de digitar.
  bool get veioDoUltimoAcesso => _veioDoUltimoAcesso;

  /// O formulário pode ser enviado.
  ///
  /// Exige apenas que os dois campos tenham conteúdo. Validar formato aqui
  /// devolveria à pessoa uma correção que o servidor nem pediu — e recusar um
  /// identificador "mal formatado" antes de enviar entregaria de graça a
  /// informação de qual formato o Memora aceita.
  bool get podeEnviar =>
      _identificador.trim().isNotEmpty &&
      _senha.isNotEmpty &&
      !enviando &&
      !bloqueado;

  /// Texto a exibir para a falha atual, na voz da Memora.
  String? get mensagemDeErro {
    if (bloqueado) return TextosAutenticacao.bloqueio(_segundosRestantes);
    return switch (_falha) {
      null => null,
      FalhaAutenticacao.credenciaisInvalidas =>
        TextosAutenticacao.credenciaisInvalidas,
      FalhaAutenticacao.semConexao => TextosAutenticacao.semConexao,
      FalhaAutenticacao.dadosInvalidos => TextosAutenticacao.dadosInvalidos,
      FalhaAutenticacao.muitasTentativas =>
        TextosAutenticacao.bloqueio(_segundosRestantes),
      FalhaAutenticacao.inesperada => TextosAutenticacao.inesperada,
    };
  }

  /// Tenta renovar a sessão e, falhando, prepara o formulário.
  ///
  /// Chamado uma vez, ao abrir a tela.
  Future<void> iniciar() async {
    _estado = EstadoLogin.iniciando;
    notifyListeners();

    final String? lembrado = await _ultimoAcesso.identificador();
    final ResultadoAutenticacao resultado = await _repositorio.renovarSessao();

    switch (resultado) {
      case AutenticacaoConcluida(:final PessoaAutenticada pessoa):
        _pessoa = pessoa;
        _estado = EstadoLogin.concluido;
      case AutenticacaoFalhou():
        // Falha ao renovar não é erro para mostrar: quem não tem sessão válida
        // simplesmente precisa entrar. Exibir "esses dados não conferem" a quem
        // não digitou nada seria acusar a pessoa de um erro que não cometeu.
        if (lembrado != null) {
          _identificador = lembrado;
          _veioDoUltimoAcesso = true;
        }
        _estado = EstadoLogin.preenchendo;
    }
    notifyListeners();
  }

  /// Atualiza o identificador.
  void informarIdentificador(String valor) {
    _identificador = valor;
    _veioDoUltimoAcesso = false;
    notifyListeners();
  }

  /// Atualiza a senha.
  void informarSenha(String valor) {
    _senha = valor;
    notifyListeners();
  }

  /// Envia o login.
  ///
  /// Ignora chamadas concorrentes: toque duplo no botão não pode virar duas
  /// tentativas, que gastariam dois degraus da escada de bloqueio de uma vez.
  Future<void> entrar() async {
    if (enviando || bloqueado) return;
    if (!podeEnviar) {
      notifyListeners();
      return;
    }

    _estado = EstadoLogin.enviando;
    _falha = null;
    notifyListeners();

    final ResultadoAutenticacao resultado = await _repositorio.entrar(
      DadosDeEntrada(identificador: _identificador.trim(), senha: _senha),
    );

    switch (resultado) {
      case AutenticacaoConcluida(:final PessoaAutenticada pessoa):
        _pessoa = pessoa;
        _estado = EstadoLogin.concluido;
        // Só agora. Gravar na tentativa deixaria um erro de digitação
        // pré-preenchido para sempre.
        await _ultimoAcesso.lembrar(_identificador.trim());

      case AutenticacaoFalhou(
          falha: FalhaAutenticacao.muitasTentativas,
          :final int? tentarNovamenteEmSegundos,
        ):
        _falha = FalhaAutenticacao.muitasTentativas;
        _senha = '';
        _iniciarContagem(tentarNovamenteEmSegundos ?? 60);

      case AutenticacaoFalhou(:final FalhaAutenticacao falha):
        _falha = falha;
        _estado = EstadoLogin.comErro;
    }
    notifyListeners();
  }

  /// Volta ao preenchimento após um erro, preservando o identificador.
  ///
  /// A senha **não** é preservada, ao contrário do cadastro (FR-006): lá o
  /// valor digitado é o que a pessoa está criando, e perdê-lo custa o
  /// formulário inteiro. Aqui a senha é justamente o que não conferiu.
  void tentarNovamente() {
    if (bloqueado) return;
    _estado = EstadoLogin.preenchendo;
    _falha = null;
    _senha = '';
    notifyListeners();
  }

  void _iniciarContagem(int segundos) {
    _contagem?.cancel();
    _segundosRestantes = segundos;
    _estado = EstadoLogin.bloqueado;

    _contagem = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      _segundosRestantes--;
      if (_segundosRestantes <= 0) {
        _segundosRestantes = 0;
        t.cancel();
        _contagem = null;
        _estado = EstadoLogin.preenchendo;
        _falha = null;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _contagem?.cancel();
    _contagem = null;
    super.dispose();
  }
}
