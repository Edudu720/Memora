import '../entidades/categoria_servico.dart';
import '../entidades/estabelecimento_servico.dart';

/// Resultado de busca no Localizador com metadados explicativos.
class ResultadoBuscaServicos {
  /// Código da categoria reconhecida na consulta livre, se houver.
  final String? categoriaIdentificada;

  /// Termo-chave extraído pelo backend para a consulta.
  final String? termoChave;

  /// Mensagem em linguagem simples explicando o resultado.
  final String? mensagemExplicativa;

  /// Descrição legível da região pesquisada.
  final String descricaoRegiao;

  /// Latitude central da região pesquisada.
  final double? latitudeRegiao;

  /// Longitude central da região pesquisada.
  final double? longitudeRegiao;

  /// Indica se os itens são meramente ilustrativos (modo demonstração).
  final bool ehDemonstracao;

  /// Lista de estabelecimentos retornados.
  final List<EstabelecimentoServico> estabelecimentos;

  /// Cria um [ResultadoBuscaServicos].
  const ResultadoBuscaServicos({
    this.categoriaIdentificada,
    this.termoChave,
    this.mensagemExplicativa,
    required this.descricaoRegiao,
    this.latitudeRegiao,
    this.longitudeRegiao,
    this.ehDemonstracao = false,
    required this.estabelecimentos,
  });
}

/// Contrato de busca de serviços essenciais no mobile.
abstract class RepositorioLocalizador {
  /// Busca serviços próximos por categoria, consulta livre, GPS ou região manual.
  Future<ResultadoBuscaServicos> buscarServicos({
    String? consulta,
    CategoriaServico? categoria,
    double? latitude,
    double? longitude,
    String? regiaoManual,
    int? raioMetros,
  });
}
