package br.fatec.memora.comum;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Corpo de <b>toda</b> resposta de erro da API (T024).
 *
 * <p>Implementa o esquema {@code Erro} de {@code contracts/openapi.yaml}. É o
 * único formato de erro que sai daqui: um aplicativo que aprende a ler esta
 * forma lê qualquer falha do sistema, e não precisa de tratamento especial por
 * endpoint.
 *
 * <h2>O que <b>nunca</b> entra aqui</h2>
 *
 * Stack trace, nome de classe, mensagem de exceção da plataforma, SQL, caminho
 * de arquivo, nome de tabela ou coluna. A FR-041 é categórica, e a forma de
 * garanti-la é estrutural: este record não tem campo onde tal coisa caberia.
 * Detalhe de diagnóstico vai para o log do servidor, correlacionado pelo Trace
 * ID (T026) — nunca para a resposta.
 *
 * <h2>Por que {@code @JsonProperty} em vez de estratégia global</h2>
 *
 * O contrato inteiro é snake_case, e seria tentador ligar
 * {@code SNAKE_CASE} no Jackson de uma vez. Não foi feito: a configuração global
 * mudaria a serialização de todo DTO futuro à distância, e quem escrever o
 * primeiro DTO da US1 não teria como saber disso lendo o próprio arquivo. Aqui o
 * nome que viaja no JSON está escrito ao lado do campo.
 *
 * @param codigo código estável do contrato, para o aplicativo decidir
 *     comportamento
 * @param mensagem texto pronto para exibição, na persona da Memora
 * @param tentarNovamenteEmSegundos espera restante; ausente do JSON quando não
 *     se trata de bloqueio temporário
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record Erro(
        @JsonProperty("codigo") String codigo,
        @JsonProperty("mensagem") String mensagem,
        @JsonProperty("tentar_novamente_em_segundos") Long tentarNovamenteEmSegundos) {

    /** Erro comum, sem espera associada. */
    public static Erro de(CodigoDeErro codigo, String mensagem) {
        return new Erro(codigo.name(), mensagem, null);
    }

    /**
     * Erro de bloqueio temporário.
     *
     * @param tentarNovamenteEmSegundos quanto falta para liberar
     */
    public static Erro comEspera(
            CodigoDeErro codigo, String mensagem, long tentarNovamenteEmSegundos) {
        return new Erro(codigo.name(), mensagem, tentarNovamenteEmSegundos);
    }
}
