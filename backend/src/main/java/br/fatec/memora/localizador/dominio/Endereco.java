package br.fatec.memora.localizador.dominio;

/**
 * Endereço normalizado do estabelecimento (FR-007).
 */
public record Endereco(
        String logradouro,
        String numero,
        String bairro,
        String cidade,
        String estado,
        String cep,
        String textoFormatado) {

    public static Endereco deLinhaUnica(String textoFormatado, String cidade, String estado) {
        return new Endereco(null, null, null, cidade, estado, null, textoFormatado);
    }
}
