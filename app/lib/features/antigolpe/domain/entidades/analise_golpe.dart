import 'package:flutter/foundation.dart' show immutable, listEquals;

/// Classificação de risco de golpe da mensagem ou link analisado.
enum NivelRisco {
  /// Sem sinais evidentes de golpe.
  seguro,

  /// Sinais suspeitos que pedem cautela antes de tocar ou responder.
  atencao,

  /// Forte indício de fraude ou tentativa de golpe.
  altoRisco;

  /// Converte o código textual devolvido pela API (`BAIXO`, `MEDIO`, `ALTO`).
  static NivelRisco deCodigoApi(String? codigo) {
    final String normalizado = (codigo ?? '').trim().toUpperCase();
    return switch (normalizado) {
      'BAIXO' => NivelRisco.seguro,
      'MEDIO' => NivelRisco.atencao,
      'ALTO' => NivelRisco.altoRisco,
      _ => throw FormatException('Nivel de risco desconhecido: $codigo'),
    };
  }
}

/// Origem da análise apresentada à pessoa.
enum OrigemAnalise {
  /// Análise realizada pelo backend com inteligência artificial.
  servidorIa,

  /// Análise determinística local feita no aparelho sem depender do servidor.
  localOffline,
}

/// Resultado completo da análise antigolpe de uma mensagem ou link.
@immutable
class AnaliseGolpe {
  /// Nível de risco identificado.
  final NivelRisco risco;

  /// Origem da resposta (servidor/IA ou verificação local offline).
  final OrigemAnalise origem;

  /// Título curto e claro com o veredito.
  final String titulo;

  /// Explicação educativa em linguagem comum.
  final String explicacao;

  /// Passos práticos recomendados à pessoa.
  final List<String> orientacoes;

  /// Sinais concretos encontrados na mensagem ou link.
  final List<String> sinaisDetectados;

  /// Verdadeiro quando a análise contou com a IA do servidor.
  final bool analisadoPorIa;

  /// Cria um resultado de análise antigolpe.
  const AnaliseGolpe({
    required this.risco,
    required this.origem,
    required this.titulo,
    required this.explicacao,
    required this.orientacoes,
    required this.sinaisDetectados,
    required this.analisadoPorIa,
  });

  /// Verdadeiro quando o veredito veio do analisador local offline.
  bool get ehOffline => origem == OrigemAnalise.localOffline;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnaliseGolpe &&
        other.risco == risco &&
        other.origem == origem &&
        other.titulo == titulo &&
        other.explicacao == explicacao &&
        other.analisadoPorIa == analisadoPorIa &&
        listEquals(other.orientacoes, orientacoes) &&
        listEquals(other.sinaisDetectados, sinaisDetectados);
  }

  @override
  int get hashCode => Object.hash(
    risco,
    origem,
    titulo,
    explicacao,
    analisadoPorIa,
    Object.hashAll(orientacoes),
    Object.hashAll(sinaisDetectados),
  );
}
