import '../../domain/entidades/categoria_servico.dart';
import '../../domain/repositorios/repositorio_localizador.dart';
import '../fontes/fonte_localizador_api.dart';

/// Implementação do repositório consumindo o servidor real sem fallback simulado.
class RepositorioLocalizadorApi implements RepositorioLocalizador {
  /// Fonte HTTP autenticada do localizador.
  final FonteLocalizadorApi fonte;

  /// Cria o repositório remoto do localizador.
  const RepositorioLocalizadorApi({required this.fonte});

  @override
  Future<ResultadoBuscaServicos> buscarServicos({
    String? consulta,
    CategoriaServico? categoria,
    double? latitude,
    double? longitude,
    String? regiaoManual,
    int? raioMetros,
  }) => fonte.buscarServicos(
    consulta: consulta,
    categoria: categoria,
    latitude: latitude,
    longitude: longitude,
    regiaoManual: regiaoManual,
    raioMetros: raioMetros,
  );
}
