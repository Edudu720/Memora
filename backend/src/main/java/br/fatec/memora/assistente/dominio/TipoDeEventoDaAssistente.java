package br.fatec.memora.assistente.dominio;

/**
 * O que a trilha da assistente registra (FR-020).
 *
 * <p>Enum próprio, e não reuso de {@code TipoDeEvento} da autenticação: os dois
 * conjuntos não têm interseção, e juntá-los faria a restrição
 * {@code ck_evento_tipo} de uma tabela precisar conhecer os valores da outra.
 */
public enum TipoDeEventoDaAssistente {

    /** Uma conversa começou. Conta para o teto diário da R7. */
    CONVERSA_INICIADA,

    /**
     * A pessoa confirmou e o aplicativo foi aberto.
     *
     * <p>É o registro que a FR-023 mostra a ela. Orientação apenas ensinada
     * <b>não</b> gera este evento (FR-025): quem fez foi a própria pessoa.
     */
    ACAO_EXECUTADA,

    /**
     * O modelo sugeriu algo que o catálogo recusou.
     *
     * <p>Este evento é o valioso. Ele é a evidência de que o portão da FR-022
     * atuou — e uma sequência deles na mesma conta é o sinal de que alguém está
     * tentando fazer a assistente abrir o que ela não abre.
     */
    ACAO_RECUSADA,

    /** O teto diário de conversas foi atingido (R7). */
    LIMITE_ATINGIDO
}
