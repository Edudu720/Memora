package br.fatec.memora.localizador.dominio;

/**
 * Categorias prioritárias para pessoas idosas no Localizador de Serviços (FR-002, 009-spec).
 */
public enum CategoriaServico {
    SAUDE("Saúde", "Postos de saúde, UPAs, hospitais e farmácias"),
    SERVICOS_PUBLICOS("Serviços públicos", "Poupatempo, INSS, CRAS e prefeitura"),
    EMERGENCIA("Emergência", "Bombeiros, SAMU, delegacias e pronto-socorro"),
    COTIDIANO("Serviços cotidianos", "Supermercados, bancos, lotéricas e correios");

    private final String rotulo;
    private final String descricao;

    CategoriaServico(String rotulo, String descricao) {
        this.rotulo = rotulo;
        this.descricao = descricao;
    }

    public String getRotulo() {
        return rotulo;
    }

    public String getDescricao() {
        return descricao;
    }
}
