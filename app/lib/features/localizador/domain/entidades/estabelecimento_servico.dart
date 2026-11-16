import 'categoria_servico.dart';
import 'endereco_servico.dart';

/// Estabelecimento de utilidade pública ou serviço essencial (FR-006 a FR-008).
class EstabelecimentoServico {
  /// Identificador único do estabelecimento na origem.
  final String id;

  /// Nome exibido do estabelecimento.
  final String nome;

  /// Categoria essencial a que pertence.
  final CategoriaServico categoria;

  /// Descrição curta do tipo de atendimento.
  final String subtituloTipo;

  /// Endereço estruturado e legível.
  final EnderecoServico endereco;

  /// Latitude geográfica, quando disponível.
  final double? latitude;

  /// Longitude geográfica, quando disponível.
  final double? longitude;

  /// Distância estimada em metros a partir da origem.
  final double? distanciaMetros;

  /// Distância formatada para leitura em voz ou na tela.
  final String? distanciaFormatada;

  /// Telefone de contato público, quando confirmado.
  final String? telefone;

  /// Texto do horário de funcionamento, quando conhecido.
  final String? horarioFuncionamento;

  /// Indica se o horário foi confirmado na fonte pública.
  final bool horarioConfirmado;

  /// Nome da fonte pública que forneceu o registro.
  final String fonte;

  /// Aviso explicativo exibido no cartão quando necessário.
  final String? avisoTransparencia;

  /// Cria uma instância de [EstabelecimentoServico].
  const EstabelecimentoServico({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.subtituloTipo,
    required this.endereco,
    this.latitude,
    this.longitude,
    this.distanciaMetros,
    this.distanciaFormatada,
    this.telefone,
    this.horarioFuncionamento,
    this.horarioConfirmado = false,
    required this.fonte,
    this.avisoTransparencia,
  });

  /// Indica se possui latitude e longitude válidas.
  bool get temCoordenadas => latitude != null && longitude != null;

  /// Indica se há telefone não vazio para discagem.
  bool get temTelefone => telefone != null && telefone!.trim().isNotEmpty;
}
