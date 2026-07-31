package br.fatec.memora.autenticacao.dominio;

/**
 * Para que serve um código de verificação.
 *
 * <p>A finalidade é separada de propósito: um código pedido para confirmar
 * posse de canal não pode servir para trocar senha. Reaproveitar o mesmo código
 * nas duas finalidades transformaria a confirmação de posse em caminho de
 * recuperação — exatamente o cenário que a FR-062 impede.
 */
public enum FinalidadeDoCodigo {

    /** Confirmar que a pessoa possui o canal informado (R5, FR-062). */
    VERIFICACAO_POSSE,

    /** Recuperar o acesso quando a senha foi esquecida (FR-019). */
    RECUPERACAO_ACESSO
}
