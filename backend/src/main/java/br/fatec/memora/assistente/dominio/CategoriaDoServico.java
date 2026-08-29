package br.fatec.memora.assistente.dominio;

/**
 * O que a Memora pode fazer com um serviço.
 *
 * <h2>A regra que governa a feature inteira</h2>
 *
 * <b>Quanto mais sensível o serviço, menos a Memora toca nele.</b> É o inverso
 * da conveniência, e é deliberado: abrir o aplicativo do banco pela pessoa
 * treinaria nela exatamente o gesto que o golpista precisa que ela tenha — o de
 * deixar outra pessoa entrar na conta por ela.
 *
 * <h2>Por que isto não é uma flag booleana</h2>
 *
 * {@code podeAbrir} resolveria o comportamento e perderia o motivo. A categoria
 * também decide em qual das duas portas do Hub o serviço aparece (FR-043,
 * FR-044), e uma flag obrigaria a inventar a segunda informação em outro lugar.
 *
 * <p>Os valores são gravados em <b>MAIÚSCULAS</b>, como os demais enums do
 * projeto, para que banco e constante Java sejam idênticos.
 */
public enum CategoriaDoServico {

    /**
     * Governo, banco, saúde, previdência, imposto. A Memora <b>só ensina</b>.
     *
     * <p>Serviço desta categoria não tem sequer identificador de aplicativo
     * gravado — a restrição {@code ck_servico_sensivel_nao_abre} recusa a linha.
     * Não há como abri-lo por engano, porque falta o dado necessário.
     */
    SENSIVEL,

    /**
     * Redes sociais, vídeo, mensagens, câmera, mapas. A Memora ensina <b>e
     * pode abrir</b>, sempre com confirmação explícita (FR-015).
     */
    COTIDIANO;

    /**
     * A Memora pode abrir um serviço desta categoria?
     *
     * <p>Nunca chame isto para decidir uma autorização — quem autoriza é o
     * {@code AutorizadorDeAcao}, consultando o catálogo. Este método serve para
     * <b>exibir</b> a informação na tela (FR-045), e a diferença importa: a
     * categoria vinda de um objeto em memória pode estar desatualizada; a do
     * banco, não.
     */
    public boolean permiteAbrir() {
        return this == COTIDIANO;
    }
}
