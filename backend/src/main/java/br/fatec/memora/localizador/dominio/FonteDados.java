package br.fatec.memora.localizador.dominio;

/**
 * Fonte identificável de dados geográficos (NFR-004).
 * O Memora nunca alucina estabelecimentos via IA: todos provêm de fontes auditáveis.
 */
public enum FonteDados {
    OPEN_STREET_MAP("OpenStreetMap"),
    MINISTERIO_DA_SAUDE("Ministério da Saúde / CNES"),
    POUPATEMPO_OFICIAL("Portal Poupatempo"),
    BASE_MUNICIPAL("Base de Dados Municipal"),
    FONTE_LOCAL("Cadastro Local Verificado");

    private final String identificacao;

    FonteDados(String identificacao) {
        this.identificacao = identificacao;
    }

    public String getIdentificacao() {
        return identificacao;
    }
}
