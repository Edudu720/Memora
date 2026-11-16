import '../../domain/entidades/categoria_servico.dart';
import '../../domain/entidades/endereco_servico.dart';
import '../../domain/entidades/estabelecimento_servico.dart';
import '../../domain/repositorios/repositorio_localizador.dart';

/// Conversor JSON para os retornos da API do Localizador de Serviços.
class EstabelecimentoServicoDto {
  /// Converte o payload JSON da busca em [ResultadoBuscaServicos].
  static ResultadoBuscaServicos deJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? intMap = json['consultaInterpretada'] as Map<String, dynamic>?;
    final Map<String, dynamic>? regMap = json['regiaoOrigem'] as Map<String, dynamic>?;
    final List<dynamic> itens = (json['estabelecimentos'] as List<dynamic>?) ?? <dynamic>[];

    final List<EstabelecimentoServico> lista = itens
        .whereType<Map<String, dynamic>>()
        .map(deJsonItem)
        .toList();

    return ResultadoBuscaServicos(
      categoriaIdentificada: intMap?['categoriaIdentificada'] as String?,
      termoChave: intMap?['termoChave'] as String?,
      mensagemExplicativa: intMap?['mensagemExplicativa'] as String?,
      descricaoRegiao: (regMap?['descricao'] as String?) ?? 'Região selecionada',
      latitudeRegiao: (regMap?['latitude'] as num?)?.toDouble(),
      longitudeRegiao: (regMap?['longitude'] as num?)?.toDouble(),
      estabelecimentos: lista,
    );
  }

  /// Converte um item JSON individual em [EstabelecimentoServico].
  static EstabelecimentoServico deJsonItem(Map<String, dynamic> item) {
    final Map<String, dynamic>? endMap = item['endereco'] as Map<String, dynamic>?;

    final EnderecoServico endereco = EnderecoServico(
      logradouro: endMap?['logradouro'] as String?,
      numero: endMap?['numero'] as String?,
      bairro: endMap?['bairro'] as String?,
      cidade: endMap?['cidade'] as String?,
      estado: endMap?['estado'] as String?,
      cep: endMap?['cep'] as String?,
      textoFormatado: (endMap?['textoFormatado'] as String?) ??
          'Endereço cadastrado na base oficial',
    );

    final String catStr = (item['categoria'] as String?) ?? 'SAUDE';
    final CategoriaServico cat = CategoriaServico.porCodigo(catStr) ?? CategoriaServico.saude;

    return EstabelecimentoServico(
      id: (item['id'] as String?) ?? _UniqueKey().toString(),
      nome: (item['nome'] as String?) ?? 'Estabelecimento',
      categoria: cat,
      subtituloTipo: (item['subtituloTipo'] as String?) ?? cat.rotulo,
      endereco: endereco,
      latitude: (item['latitude'] as num?)?.toDouble(),
      longitude: (item['longitude'] as num?)?.toDouble(),
      distanciaMetros: (item['distanciaMetros'] as num?)?.toDouble(),
      distanciaFormatada: item['distanciaFormatada'] as String?,
      telefone: item['telefone'] as String?,
      horarioFuncionamento: item['horarioFuncionamento'] as String?,
      horarioConfirmado: (item['horarioConfirmado'] as bool?) ?? false,
      fonte: (item['fonte'] as String?) ?? 'OpenStreetMap',
      avisoTransparencia: item['avisoTransparencia'] as String?,
    );
  }
}

class _UniqueKey {
  @override
  String toString() => DateTime.now().microsecondsSinceEpoch.toString();
}
