package br.fatec.memora.localizador.dominio;

/**
 * Entidade de domínio que representa um estabelecimento de utilidade pública ou serviço essencial.
 */
public record Estabelecimento(
        String id,
        String nome,
        CategoriaServico categoria,
        String subtituloTipo,
        Endereco endereco,
        Double latitude,
        Double longitude,
        Double distanciaMetros,
        String distanciaFormatada,
        String telefone,
        String horarioFuncionamento,
        boolean horarioConfirmado,
        FonteDados fonte,
        String avisoTransparencia) {

    public Estabelecimento comDistancia(Double distanciaMetros, String distanciaFormatada) {
        return new Estabelecimento(
                id,
                nome,
                categoria,
                subtituloTipo,
                endereco,
                latitude,
                longitude,
                distanciaMetros,
                distanciaFormatada,
                telefone,
                horarioFuncionamento,
                horarioConfirmado,
                fonte,
                avisoTransparencia);
    }
}
