package br.fatec.memora.autenticacao.dominio;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Sessão com refresh token rotativo (T011).
 *
 * <h2>O que {@code familiaId} resolve</h2>
 *
 * Cada renovação cria uma sessão nova e marca a anterior como substituída.
 * Todas carregam a mesma {@code familiaId}, formando a cadeia de rotações.
 *
 * <p>Isso existe por causa de um cenário concreto: alguém copia o refresh token
 * do aparelho. O token roubado e o legítimo apontam para a mesma família. No
 * momento em que um deles usa um token <b>já substituído</b>, sabemos que há
 * duas partes com a mesma credencial — e não há como distinguir quem é o dono.
 * A resposta é derrubar a família inteira e obrigar a entrar de novo (R2).
 *
 * <p>Sem a família, a única alternativa seria revogar apenas o token reusado,
 * o que deixaria o ladrão dentro da conta.
 *
 * <h2>Por que {@code substituidaPor} é um UUID, não uma associação</h2>
 *
 * Mapear como {@code @OneToOne} convidaria a percorrer a cadeia de rotações
 * objeto por objeto — uma consulta por renovação, num caminho que roda a cada
 * abertura do aplicativo. A revogação em massa é uma única consulta por
 * {@code familiaId}.
 */
@Entity
@Table(name = "sessao")
public class Sessao {

    @Id
    @Column(nullable = false, updatable = false)
    private UUID id;

    @Column(name = "pessoa_id", nullable = false, updatable = false)
    private UUID pessoaId;

    @Column(name = "familia_id", nullable = false, updatable = false)
    private UUID familiaId;

    /** SENSÍVEL. Somente o hash; o token em claro nunca é persistido. */
    @Column(name = "refresh_token_hash", nullable = false, updatable = false)
    private String refreshTokenHash;

    /** Preenchido significa token já usado. Reaparecer é sinal de roubo. */
    @Column(name = "substituida_por")
    private UUID substituidaPor;

    @Column(name = "aparelho_descricao", length = 120)
    private String aparelhoDescricao;

    @Column(name = "criada_em", nullable = false, updatable = false)
    private Instant criadaEm;

    @Column(name = "expira_em", nullable = false)
    private Instant expiraEm;

    @Column(name = "revogada_em")
    private Instant revogadaEm;

    /** Exigido pelo JPA. Não usar em código de aplicação. */
    protected Sessao() {
    }

    /**
     * Abre a <b>primeira</b> sessão de uma família — cadastro ou entrada.
     *
     * <p>A família nasce aqui, com o mesmo valor do id da sessão inicial.
     */
    public static Sessao iniciarFamilia(
            UUID pessoaId,
            String refreshTokenHash,
            String aparelhoDescricao,
            Instant criadaEm,
            Instant expiraEm) {
        Sessao sessao = new Sessao(
                pessoaId, null, refreshTokenHash, aparelhoDescricao, criadaEm, expiraEm);
        sessao.familiaId = sessao.id;
        return sessao;
    }

    /**
     * Continua uma família existente — renovação de sessão.
     *
     * <p>Quem marca a sessão anterior como substituída é a camada de segurança
     * (T019), que precisa fazer as duas coisas na mesma transação.
     */
    public static Sessao continuarFamilia(
            UUID pessoaId,
            UUID familiaId,
            String refreshTokenHash,
            String aparelhoDescricao,
            Instant criadaEm,
            Instant expiraEm) {
        return new Sessao(
                pessoaId,
                Objects.requireNonNull(familiaId, "familiaId"),
                refreshTokenHash,
                aparelhoDescricao,
                criadaEm,
                expiraEm);
    }

    private Sessao(
            UUID pessoaId,
            UUID familiaId,
            String refreshTokenHash,
            String aparelhoDescricao,
            Instant criadaEm,
            Instant expiraEm) {
        this.id = UUID.randomUUID();
        this.pessoaId = Objects.requireNonNull(pessoaId, "pessoaId");
        this.familiaId = familiaId;
        this.refreshTokenHash = Objects.requireNonNull(refreshTokenHash, "refreshTokenHash");
        this.aparelhoDescricao = aparelhoDescricao;
        this.criadaEm = Objects.requireNonNull(criadaEm, "criadaEm");
        this.expiraEm = Objects.requireNonNull(expiraEm, "expiraEm");
    }

    /** Marca esta sessão como rotacionada, apontando para a que a sucedeu. */
    public void substituirPor(Sessao sucessora) {
        Objects.requireNonNull(sucessora, "sucessora");
        this.substituidaPor = sucessora.getId();
    }

    /** Encerra a sessão. Idempotente: revogar duas vezes preserva a data original. */
    public void revogar(Instant quando) {
        if (this.revogadaEm == null) {
            this.revogadaEm = Objects.requireNonNull(quando, "quando");
        }
    }

    /** Renova o prazo de validade a cada uso legítimo. */
    public void estenderValidade(Instant novoLimite) {
        this.expiraEm = Objects.requireNonNull(novoLimite, "novoLimite");
    }

    /**
     * Indica que este refresh token já foi trocado por outro.
     *
     * <p>É a pergunta que a detecção de reuso faz: se um token <i>já
     * substituído</i> chega de novo, alguém está usando credencial que deveria
     * estar descartada.
     */
    public boolean foiSubstituida() {
        return substituidaPor != null;
    }

    public boolean estaRevogada() {
        return revogadaEm != null;
    }

    public boolean expirouEm(Instant momento) {
        return !expiraEm.isAfter(momento);
    }

    /** Utilizável de fato: nem revogada, nem expirada, nem já rotacionada. */
    public boolean estaUtilizavelEm(Instant momento) {
        return !estaRevogada() && !expirouEm(momento) && !foiSubstituida();
    }

    public UUID getId() {
        return id;
    }

    public UUID getPessoaId() {
        return pessoaId;
    }

    public UUID getFamiliaId() {
        return familiaId;
    }

    public String getRefreshTokenHash() {
        return refreshTokenHash;
    }

    public UUID getSubstituidaPor() {
        return substituidaPor;
    }

    public String getAparelhoDescricao() {
        return aparelhoDescricao;
    }

    public Instant getCriadaEm() {
        return criadaEm;
    }

    public Instant getExpiraEm() {
        return expiraEm;
    }

    public Instant getRevogadaEm() {
        return revogadaEm;
    }

    @Override
    public boolean equals(Object outro) {
        if (this == outro) {
            return true;
        }
        return outro instanceof Sessao sessao && Objects.equals(id, sessao.id);
    }

    @Override
    public int hashCode() {
        return Objects.hashCode(id);
    }

    /**
     * Representação para log e depuração.
     *
     * <p><b>Omite o hash do refresh token.</b> Ele é Sensível: mesmo hasheado,
     * não tem por que circular em log.
     */
    @Override
    public String toString() {
        return "Sessao[id=%s, familia=%s, substituida=%s, revogada=%s]"
                .formatted(id, familiaId, foiSubstituida(), estaRevogada());
    }
}
