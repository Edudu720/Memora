package br.fatec.memora.autenticacao.dominio;

/**
 * Situação de uma conta do Memora.
 *
 * <p>Gravado como texto pela restrição {@code ck_pessoa_estado} da migration
 * V1, ampliada pela V3. Acrescentar um valor aqui exige acrescentar na restrição
 * também — o banco recusa valor desconhecido em vez de aceitar em silêncio.
 *
 * <h2>Duas naturezas no mesmo campo</h2>
 *
 * {@code estado} guarda coisas diferentes, e confundi-las já produziu defeito
 * aqui (ver a revisão da PR #15):
 *
 * <ul>
 *   <li><b>Ciclo de vida</b> — {@link #PENDENTE_VERIFICACAO} e
 *       {@link #DESATIVADA}. Só mudam por ato explícito.
 *   <li><b>Tranca temporária</b> — o par {@link #ATIVA} /
 *       {@link #BLOQUEADA_TEMPORARIAMENTE}, cuja verdade real mora em
 *       {@code bloqueada_ate}.
 * </ul>
 *
 * <p>A tranca <b>nunca</b> sobrescreve um estado de ciclo de vida, e é
 * {@link #ehDeCicloDeVida()} que carrega essa regra para quem precisa dela.
 */
public enum EstadoDaConta {

    /** Pode entrar normalmente. */
    ATIVA,

    /**
     * Conta criada em modo assistido, à espera da confirmação de posse do canal
     * (FR-062, T057).
     *
     * <p>A FR-062 exige posse confirmada <b>antes</b> de o cadastro concluir, e
     * o canal só existe depois de a conta existir. Este estado é a resolução
     * dessa circularidade: a conta existe, mas não serve para entrar — a sessão
     * devolvida no cadastro assistido só abre o caminho de confirmar o canal.
     *
     * <p><b>Não é um estado de espera inofensivo.</b> Enquanto ela durar, a
     * conta não entra e não recupera acesso, que é precisamente o que impede o
     * acompanhante de sair dali com uma conta utilizável apontando para o
     * contato dele.
     */
    PENDENTE_VERIFICACAO,

    /**
     * Bloqueada por tentativas consecutivas de entrada (FR-014).
     *
     * <p>É temporária por decisão de produto: bloqueio permanente por erro de
     * digitação puniria exatamente o público que a feature existe para servir.
     */
    BLOQUEADA_TEMPORARIAMENTE,

    /** Desativada pela própria pessoa. Sujeita a anonimização. */
    DESATIVADA;

    /**
     * Este estado descreve o ciclo de vida da conta, e não uma tranca?
     *
     * <p>Quem responde {@code true} não é sobrescrito por bloqueio nem por
     * entrada bem-sucedida. Sem esta regra, cinco senhas erradas apagariam
     * {@link #DESATIVADA}, e uma entrada bem-sucedida promoveria a
     * {@link #ATIVA} uma conta que ainda não confirmou canal nenhum — furando a
     * FR-062 pelo caminho lateral.
     */
    public boolean ehDeCicloDeVida() {
        return this == PENDENTE_VERIFICACAO || this == DESATIVADA;
    }

    /**
     * A conta pode abrir sessão de uso comum?
     *
     * <p>Não confunda com a tranca temporária: uma conta
     * {@link #BLOQUEADA_TEMPORARIAMENTE} continua podendo entrar quando o prazo
     * de {@code bloqueada_ate} vence, e quem confere isso é o
     * {@code LimitadorTentativas}. O que este método recusa é o que nenhum
     * prazo destranca.
     */
    public boolean permiteEntrar() {
        return !ehDeCicloDeVida();
    }
}
