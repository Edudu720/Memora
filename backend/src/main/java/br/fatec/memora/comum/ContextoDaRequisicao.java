package br.fatec.memora.comum;

/**
 * O que se sabe sobre a requisição em curso, disponível a qualquer camada
 * (T026).
 *
 * <p>Preenchido pelo {@link FiltroRastreio} na entrada e limpo na saída. Existe
 * para que a auditoria (T025) e o tratamento de erro (T024) alcancem dados da
 * requisição sem receber {@code HttpServletRequest} como parâmetro por cinco
 * camadas — um serviço de domínio não deve conhecer a API de servlet.
 *
 * <h2>Por que {@code ThreadLocal}, e o que isso obriga</h2>
 *
 * É o mesmo mecanismo que o {@code MDC} do SLF4J e o
 * {@code SecurityContextHolder} do Spring já usam: no modelo servlet, uma
 * requisição ocupa uma thread do início ao fim.
 *
 * <p>O preço é que <b>esquecer de limpar vaza dado de uma pessoa para a
 * requisição seguinte</b>, porque a thread volta para o pool com o conteúdo
 * antigo. Daí a limpeza no {@code finally} do filtro, sem exceção, e o teste que
 * verifica isso.
 *
 * <p>A herança por thread filha <b>não</b> foi habilitada, de propósito: um
 * {@code InheritableThreadLocal} copiaria o contexto para qualquer thread criada
 * durante o processamento, inclusive threads de pool que sobrevivem à
 * requisição — trocando o esquecimento pontual por um vazamento silencioso e
 * duradouro. Trabalho assíncrono que precise destes dados deve recebê-los
 * explicitamente.
 *
 * @param traceId identifica a operação de ponta a ponta; vai no log e no
 *     cabeçalho da resposta
 * @param requestId identifica esta requisição; pode vir do cliente
 * @param origemHash endereço de rede já resumido. <b>CONFIDENCIAL</b> — nunca
 *     vai para log nem para resposta, só para a trilha de auditoria
 */
public record ContextoDaRequisicao(String traceId, String requestId, String origemHash) {

    private static final ThreadLocal<ContextoDaRequisicao> ATUAL = new ThreadLocal<>();

    /** Contexto vazio, para código executado fora de uma requisição HTTP. */
    private static final ContextoDaRequisicao VAZIO =
            new ContextoDaRequisicao(null, null, null);

    static void definir(ContextoDaRequisicao contexto) {
        ATUAL.set(contexto);
    }

    /**
     * Reinstala um contexto em <b>outra thread</b>.
     *
     * <p>Existe para resposta transmitida: o {@code SseEmitter} escreve numa
     * thread diferente da que recebeu a requisição, e {@code ThreadLocal} não
     * atravessa esse limite. Sem reinstalar, a trilha sairia sem origem de
     * rede — perdendo justamente o campo que permite notar rajadas da mesma
     * origem.
     *
     * <p>Quem chama <b>precisa</b> chamar {@link #limpar()} num {@code finally}.
     * Em pool de threads o descuido não deixa o contexto vazio: deixa o de
     * outra pessoa.
     */
    public static void instalar(ContextoDaRequisicao contexto) {
        ATUAL.set(contexto);
    }

    /** Remove o contexto da thread atual. Sempre num {@code finally}. */
    public static void limpar() {
        ATUAL.remove();
    }

    /**
     * O contexto da requisição em curso.
     *
     * <p>Devolve um contexto de campos nulos quando não há requisição — caso de
     * tarefa agendada, teste de unidade ou inicialização. Nunca devolve
     * {@code null}: quem chama não deveria precisar decidir se está dentro de
     * uma requisição, e a auditoria funciona igual nos dois casos, apenas sem
     * origem.
     */
    public static ContextoDaRequisicao atual() {
        ContextoDaRequisicao contexto = ATUAL.get();
        return contexto != null ? contexto : VAZIO;
    }
}
