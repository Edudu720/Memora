package br.fatec.memora.autenticacao.dominio;

/**
 * Situação de uma conta do Memora.
 *
 * <p>Gravado como texto pela restrição {@code ck_pessoa_estado} da migration
 * V1. Acrescentar um valor aqui exige acrescentar na restrição também — o banco
 * recusa valor desconhecido em vez de aceitar em silêncio.
 */
public enum EstadoDaConta {

    /** Pode entrar normalmente. */
    ATIVA,

    /**
     * Bloqueada por tentativas consecutivas de entrada (FR-014).
     *
     * <p>É temporária por decisão de produto: bloqueio permanente por erro de
     * digitação puniria exatamente o público que a feature existe para servir.
     */
    BLOQUEADA_TEMPORARIAMENTE,

    /** Desativada pela própria pessoa. Sujeita a anonimização. */
    DESATIVADA
}
