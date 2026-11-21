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

/// Tipo categorizado de falha na chamada de análise antigolpe.
enum FalhaAnaliseGolpeTipo {
  /// O limite de análises por período foi atingido (`HTTP 429`).
  limiteExcedido,

  /// A requisição foi recusada pelo servidor (`HTTP 400` ou similar).
  requisicaoInvalida,
}

/// Falha estruturada lançada pelo repositório de análise antigolpe quando a
/// resposta não deve ser mascarada como modo offline.
class FalhaAnaliseGolpe implements Exception {
  /// Categoria da falha.
  final FalhaAnaliseGolpeTipo tipo;

  /// Mensagem amigável para a tela.
  final String mensagem;

  /// Tempo sugerido de espera em segundos (`Retry-After`), quando informado.
  final int? esperaEmSegundos;

  /// Código HTTP recebido, quando houver.
  final int? statusCode;

  /// Cria uma falha estruturada da análise antigolpe.
  const FalhaAnaliseGolpe(
    this.tipo, {
    this.mensagem = '',
    this.esperaEmSegundos,
    this.statusCode,
  });

  @override
  String toString() => mensagem;
}

/// Erro devolvido pela API em falhas de requisição não recuperáveis localmente
/// (como `400 Bad Request`).
class ErroRequisicaoAnaliseException extends FalhaAnaliseGolpe {
  /// Cria a exceção de erro de requisição.
  const ErroRequisicaoAnaliseException(
    String mensagem, {
    super.statusCode,
    super.esperaEmSegundos,
    FalhaAnaliseGolpeTipo tipo = FalhaAnaliseGolpeTipo.requisicaoInvalida,
  }) : super(tipo, mensagem: mensagem);
}

/// Contrato para analisar mensagens ou links suspeitos contra golpes.
abstract interface class RepositorioAnaliseGolpe {
  /// Avalia o [conteudo] e retorna a classificação de risco e orientações.
  Future<AnaliseGolpe> analisar(String conteudo);
}
