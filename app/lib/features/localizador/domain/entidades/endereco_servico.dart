/// Endereço legível e estruturado do estabelecimento (FR-007).
class EnderecoServico {
  /// Nome da rua ou avenida.
  final String? logradouro;

  /// Número predial.
  final String? numero;

  /// Nome do bairro.
  final String? bairro;

  /// Município.
  final String? cidade;

  /// Unidade federativa.
  final String? estado;

  /// Código de Endereçamento Postal.
  final String? cep;

  /// Endereço completo formatado para exibição.
  final String textoFormatado;

  /// Cria um [EnderecoServico].
  const EnderecoServico({
    this.logradouro,
    this.numero,
    this.bairro,
    this.cidade,
    this.estado,
    this.cep,
    required this.textoFormatado,
  });

  /// Constrói um endereço a partir apenas de um texto simples.
  factory EnderecoServico.deTexto(String texto, {String? cidade, String? estado}) {
    return EnderecoServico(
      cidade: cidade,
      estado: estado,
      textoFormatado: texto,
    );
  }
}
