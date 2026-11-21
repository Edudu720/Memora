import '../../domain/entidades/analise_golpe.dart';
import '../../domain/repositorios/repositorio_analise_golpe.dart';
import '../../domain/servicos/analisador_local_de_golpes.dart';

/// Repositório simulado usado quando `Ambiente.usaServidorReal` é `false`
/// (modo demonstração) ou em testes isolados.
///
/// Usa a classificação determinística de [AnalisadorLocalDeGolpes] para
/// produzir respostas realistas tanto no modo simulado online
/// ([OrigemAnalise.servidorIa]) quanto no modo offline ([OrigemAnalise.localOffline]).
class RepositorioAnaliseGolpeSimulado implements RepositorioAnaliseGolpe {
  /// Atraso opcional para exercitar estados de carregamento em testes.
  final Duration atraso;

  /// Quando `true`, simula a execução sem conexão devolvendo origem offline.
  final bool modoOffline;

  final AnalisadorLocalDeGolpes _analisadorLocal;

  /// Cria o repositório simulado de análise de golpes.
  const RepositorioAnaliseGolpeSimulado({
    this.atraso = Duration.zero,
    this.modoOffline = false,
    AnalisadorLocalDeGolpes analisadorLocal = const AnalisadorLocalDeGolpes(),
  }) : _analisadorLocal = analisadorLocal;

  @override
  Future<AnaliseGolpe> analisar(String conteudo) async {
    if (atraso > Duration.zero) {
      await Future<void>.delayed(atraso);
    }

    final AnaliseGolpe base = _analisadorLocal.analisar(conteudo);
    if (modoOffline) {
      return base;
    }

    return AnaliseGolpe(
      risco: base.risco,
      origem: OrigemAnalise.servidorIa,
      titulo: base.titulo,
      explicacao: base.explicacao,
      orientacoes: base.orientacoes,
      sinaisDetectados: base.sinaisDetectados,
      analisadoPorIa: true,
    );
  }
}
