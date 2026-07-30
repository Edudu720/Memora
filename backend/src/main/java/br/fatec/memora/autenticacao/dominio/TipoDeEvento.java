package br.fatec.memora.autenticacao.dominio;

/**
 * O que aconteceu, na trilha de auditoria (FR-039).
 *
 * <p>Nenhum destes eventos carrega senha, código, token ou valor de canal em
 * texto legível — a proibição da FR-040 é absoluta.
 */
public enum TipoDeEvento {

    /** Conta criada. */
    CADASTRO,

    /** Entrada bem-sucedida. */
    ENTRADA,

    /** Tentativa de entrada recusada. */
    FALHA_ENTRADA,

    /** Conta bloqueada temporariamente por tentativas consecutivas (FR-014). */
    BLOQUEIO,

    /** Recuperação de acesso pedida. Registrada mesmo sem conta correspondente. */
    RECUPERACAO_SOLICITADA,

    /** Senha trocada. Revoga todas as sessões (FR-021). */
    SENHA_ALTERADA,

    /** Saída deliberada (FR-026). */
    SAIDA,

    /**
     * Refresh token já usado reapareceu (R2).
     *
     * <p>É o evento mais grave da trilha: indica token roubado. Derruba a
     * família inteira de sessões.
     */
    REUSO_TOKEN_DETECTADO,

    /** Posse de canal confirmada. */
    CANAL_VERIFICADO
}
