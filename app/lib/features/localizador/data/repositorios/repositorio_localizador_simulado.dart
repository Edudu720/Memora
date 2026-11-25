import '../../domain/entidades/categoria_servico.dart';
import '../../domain/entidades/endereco_servico.dart';
import '../../domain/entidades/estabelecimento_servico.dart';
import '../../domain/repositorios/repositorio_localizador.dart';

/// Repositório simulado em memória para testes offline, widget tests e pré-visualização.
class RepositorioLocalizadorSimulado implements RepositorioLocalizador {
  /// Atraso artificial opcional utilizado para testar estados de carregamento.
  final Duration demora;

  /// Cria o repositório simulado de demonstração.
  RepositorioLocalizadorSimulado({this.demora = Duration.zero});

  /// Conjunto fixo de exemplos ilustrativos sem dados de contato reais.
  static final List<EstabelecimentoServico> todosOsEstabelecimentos = <EstabelecimentoServico>[
    const EstabelecimentoServico(
      id: 'ubs-boer',
      nome: 'UBS Jardim Boer - Dr. Sérgio Pássaro (Exemplo)',
      categoria: CategoriaServico.saude,
      subtituloTipo: 'Unidade Básica de Saúde (Posto de Saúde)',
      endereco: EnderecoServico(
        logradouro: 'Rua das Amoras',
        numero: '120',
        bairro: 'Jardim Boer',
        cidade: 'Americana',
        estado: 'SP',
        cep: '13470-000',
        textoFormatado: 'Rua das Amoras, 120 - Jardim Boer, Americana - SP',
      ),
      latitude: -22.7410,
      longitude: -47.3340,
      distanciaMetros: 350,
      distanciaFormatada: '350 metros',
      horarioFuncionamento: 'Segunda a Sexta, das 07:00 às 16:30',
      fonte: 'Modo Demonstração',
      avisoTransparencia:
          'Exemplo ilustrativo de demonstração. Telefone desabilitado neste modo.',
    ),
    const EstabelecimentoServico(
      id: 'farmacia-popular',
      nome: 'Farmácia Drogaria São Paulo (Exemplo)',
      categoria: CategoriaServico.saude,
      subtituloTipo: 'Farmácia e Medicamentos',
      endereco: EnderecoServico(
        logradouro: 'Rua Rui Barbosa',
        numero: '450',
        bairro: 'Centro',
        cidade: 'Americana',
        estado: 'SP',
        cep: '13465-280',
        textoFormatado: 'Rua Rui Barbosa, 450 - Centro, Americana - SP',
      ),
      latitude: -22.7380,
      longitude: -47.3310,
      distanciaMetros: 820,
      distanciaFormatada: '820 metros',
      horarioFuncionamento: 'Diariamente, das 07:00 às 23:00',
      fonte: 'Modo Demonstração',
      avisoTransparencia:
          'Exemplo ilustrativo de demonstração. Telefone desabilitado neste modo.',
    ),
    const EstabelecimentoServico(
      id: 'poupatempo-americana',
      nome: 'Poupatempo Americana (Exemplo)',
      categoria: CategoriaServico.servicosPublicos,
      subtituloTipo: 'Central de Atendimento ao Cidadão',
      endereco: EnderecoServico(
        logradouro: 'Rua Carioba',
        numero: '262',
        bairro: 'Carioba',
        cidade: 'Americana',
        estado: 'SP',
        cep: '13472-000',
        textoFormatado: 'Rua Carioba, 262 - Carioba, Americana - SP',
      ),
      latitude: -22.7320,
      longitude: -47.3270,
      distanciaMetros: 1200,
      distanciaFormatada: '1,2 km',
      horarioFuncionamento: 'Segunda a Sexta, das 09:00 às 17:00',
      fonte: 'Modo Demonstração',
      avisoTransparencia:
          'Exemplo ilustrativo de demonstração. Telefone desabilitado neste modo.',
    ),
    const EstabelecimentoServico(
      id: 'bombeiros-americana',
      nome: 'Corpo de Bombeiros de Americana',
      categoria: CategoriaServico.emergencia,
      subtituloTipo: 'Posto de Bombeiros / Resgate (Exemplo)',
      endereco: EnderecoServico(
        logradouro: 'Avenida Campos Salles',
        numero: '1200',
        bairro: 'Vila Pavan',
        cidade: 'Americana',
        estado: 'SP',
        cep: '13465-590',
        textoFormatado: 'Avenida Campos Salles, 1200 - Vila Pavan, Americana - SP',
      ),
      latitude: -22.7440,
      longitude: -47.3290,
      distanciaMetros: 950,
      distanciaFormatada: '950 metros',
      horarioFuncionamento: 'Atendimento 24 horas',
      fonte: 'Modo Demonstração',
      avisoTransparencia:
          'Exemplo ilustrativo de demonstração. Telefone desabilitado neste modo.',
    ),
    const EstabelecimentoServico(
      id: 'correios-centro',
      nome: 'Correios - Agência Central Americana (Exemplo)',
      categoria: CategoriaServico.cotidiano,
      subtituloTipo: 'Agência Postal e Encomendas',
      endereco: EnderecoServico(
        logradouro: 'Praça Comendador Müller',
        numero: '35',
        bairro: 'Centro',
        cidade: 'Americana',
        estado: 'SP',
        cep: '13465-290',
        textoFormatado: 'Praça Comendador Müller, 35 - Centro, Americana - SP',
      ),
      latitude: -22.7392,
      longitude: -47.3315,
      distanciaMetros: 600,
      distanciaFormatada: '600 metros',
      horarioFuncionamento: 'Segunda a Sexta, das 09:00 às 17:00',
      fonte: 'Modo Demonstração',
      avisoTransparencia:
          'Exemplo ilustrativo de demonstração. Telefone desabilitado neste modo.',
    ),
  ];

  @override
  Future<ResultadoBuscaServicos> buscarServicos({
    String? consulta,
    CategoriaServico? categoria,
    double? latitude,
    double? longitude,
    String? regiaoManual,
    int? raioMetros,
  }) async {
    if (demora > Duration.zero) {
      await Future<void>.delayed(demora);
    }

    final CategoriaServico catEfetiva = categoria ?? CategoriaServico.saude;
    final List<EstabelecimentoServico> filtrados = todosOsEstabelecimentos
        .where((EstabelecimentoServico e) => e.categoria == catEfetiva)
        .toList();
    final List<EstabelecimentoServico> resultado = filtrados.isNotEmpty
        ? filtrados
        : todosOsEstabelecimentos;

    return ResultadoBuscaServicos(
      categoriaIdentificada: catEfetiva.rotulo,
      termoChave: catEfetiva.rotulo,
      mensagemExplicativa:
          'Modo demonstração: exibindo exemplos ilustrativos de ${catEfetiva.rotulo.toLowerCase()}',
      descricaoRegiao: regiaoManual != null && regiaoManual.isNotEmpty
          ? '$regiaoManual (Demonstração)'
          : 'Americana - SP (Demonstração)',
      latitudeRegiao: resultado.first.latitude,
      longitudeRegiao: resultado.first.longitude,
      ehDemonstracao: true,
      estabelecimentos: resultado,
    );
  }
}
