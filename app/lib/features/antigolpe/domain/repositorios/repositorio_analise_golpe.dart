import '../entidades/analise_golpe.dart';

/// Erro de validação do texto informado para análise.
class ConteudoAnaliseInvalidoException implements Exception {
  /// Mensagem amigável explicando o ajuste necessário.
  final String mensagem;

  /// Cria a exceção de conteúdo inválido.
  const ConteudoAnaliseInvalidoException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Erro devolvido pela API em falhas de requisição não recuperáveis localmente
/// (como `400 Bad Request`).
class ErroRequisicaoAnaliseException implements Exception {
  /// Mensagem amigável para a tela.
  final String mensagem;

  /// Código HTTP recebido, quando houver.
  final int? statusCode;

  /// Cria a exceção de erro de requisição.
  const ErroRequisicaoAnaliseException(this.mensagem, {this.statusCode});

  @override
  String toString() => mensagem;
}

/// Contrato para analisar mensagens ou links suspeitos contra golpes.
abstract interface class RepositorioAnaliseGolpe {
  /// Avalia o [conteudo] e retorna a classificação de risco e orientações.
  Future<AnaliseGolpe> analisar(String conteudo);
}
