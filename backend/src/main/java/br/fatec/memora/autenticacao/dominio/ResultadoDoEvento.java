package br.fatec.memora.autenticacao.dominio;

/**
 * Desfecho de um evento de autenticação.
 *
 * <p>Existe separado de {@link TipoDeEvento} porque o mesmo tipo pode ter os
 * dois desfechos: uma recuperação solicitada para conta inexistente é
 * {@code RECUPERACAO_SOLICITADA} com {@code FALHA}, e a resposta da API
 * continua idêntica à do caso de sucesso (FR-019).
 */
public enum ResultadoDoEvento {

    SUCESSO,

    FALHA
}
