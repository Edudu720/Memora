/// Estados possíveis do ditado por voz no campo da conversa (FR-013).
enum EstadoDitado {
  /// Nenhuma captura em andamento.
  ocioso,

  /// Aguardando explicação e concessão da permissão de microfone.
  aguardandoPermissao,

  /// Microfone aberto capturando a fala em tempo real para o rascunho.
  ouvindo,

  /// Dispositivo sem reconhecimento de voz ou permissão negada pelo sistema.
  indisponivel,

  /// Falha momentânea durante o reconhecimento de voz.
  erro,
}

/// Resultado estruturado das operações do leitor de voz (FR-013).
class ResultadoDitado {
  /// Estado resultante da tentativa.
  final EstadoDitado estado;

  /// Texto reconhecido até o momento, quando aplicável.
  final String texto;

  /// Mensagem amigável de apoio para casos de indisponibilidade ou erro.
  final String? mensagem;

  /// Cria um resultado de operação do ditado por voz.
  const ResultadoDitado({
    required this.estado,
    this.texto = '',
    this.mensagem,
  });

  /// Verdadeiro quando o recurso está pronto para uso ou escutando.
  bool get disponivel =>
      estado != EstadoDitado.indisponivel && estado != EstadoDitado.erro;
}

/// Contrato de domínio para leitura de voz com saída exclusiva em rascunho.
///
/// Toda implementação desta interface deve transcrever apenas para o callback
/// [aoReconhecer] sem salvar áudio em disco e sem disparar envio automático.
abstract class LeitorDeVoz {
  /// Verifica se o aparelho suporta reconhecimento de fala e se há permissão.
  Future<ResultadoDitado> verificarDisponibilidade();

  /// Inicia a escuta em idioma português do Brasil, entregando trechos
  /// parciais em [aoReconhecer].
  Future<ResultadoDitado> iniciarEscuta({
    required void Function(String textoParcial) aoReconhecer,
  });

  /// Encerra a escuta em andamento mantendo o texto já preenchido no rascunho.
  Future<void> pararEscuta();

  /// Libera os recursos nativos associados ao reconhecimento de fala.
  void dispose();
}
