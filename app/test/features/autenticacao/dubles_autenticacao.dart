import 'package:memora/features/autenticacao/data/ultimo_acesso_local.dart';
import 'package:memora/features/autenticacao/domain/autenticacao.dart';

/// Base para dublês que exercitam apenas parte do contrato.
///
/// Os métodos não sobrescritos **falham alto** de propósito. Um dublê que
/// devolvesse sucesso silencioso para uma chamada inesperada faria o teste
/// passar pelo motivo errado — que é o pior defeito possível num teste.
///
/// [encerrarSessao] é a exceção, e não devolve erro: ela é chamada em caminhos
/// de limpeza que não são o objeto de nenhum teste, e quebrar ali só
/// esconderia a asserção de verdade atrás de um erro de arrumação.
abstract class RepositorioDeTeste implements RepositorioAutenticacao {
  @override
  Future<ResultadoAutenticacao> cadastrar(DadosDeCadastro dados) =>
      throw UnimplementedError('cadastrar não deveria ser chamado aqui');

  @override
  Future<ResultadoAutenticacao> entrar(DadosDeEntrada dados) =>
      throw UnimplementedError('entrar não deveria ser chamado aqui');

  @override
  Future<ResultadoAutenticacao> renovarSessao() =>
      throw UnimplementedError('renovarSessao não deveria ser chamado aqui');

  @override
  Future<void> encerrarSessao() async {}

  @override
  Future<ResultadoDeCanal> enviarCodigoDeCanal(String canalId) =>
      throw UnimplementedError(
        'enviarCodigoDeCanal não deveria ser chamado aqui',
      );

  @override
  Future<ResultadoDeCanal> confirmarCanal(String canalId, String codigo) =>
      throw UnimplementedError('confirmarCanal não deveria ser chamado aqui');

  @override
  Future<ResultadoDeCanal> solicitarRecuperacao(String identificador) =>
      throw UnimplementedError(
        'solicitarRecuperacao não deveria ser chamado aqui',
      );

  @override
  Future<ResultadoAutenticacao> confirmarRecuperacao({
    required String identificador,
    required String codigo,
    required String novaSenha,
  }) => throw UnimplementedError(
    'confirmarRecuperacao não deveria ser chamado aqui',
  );
}

/// [UltimoAcesso] guardado em memória, para teste sem plataforma.
class UltimoAcessoEmMemoria implements UltimoAcesso {
  /// O identificador guardado.
  String? valor;

  /// Quantas vezes [lembrar] foi chamado.
  int gravacoes = 0;

  /// Cria o dublê, opcionalmente já com um identificador guardado.
  UltimoAcessoEmMemoria([this.valor]);

  @override
  Future<String?> identificador() async => valor;

  @override
  Future<void> lembrar(String identificador) async {
    gravacoes++;
    valor = identificador;
  }

  @override
  Future<void> esquecer() async => valor = null;
}
