package br.fatec.memora.autenticacao.dominio;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * E-mail ou telefone de uma conta (T010).
 *
 * <h2>Unicidade de {@code (tipo, valor)}</h2>
 *
 * A restrição existe no banco ({@code uq_canal_tipo_valor}) e está declarada
 * aqui também. Ela impede duas contas com o mesmo e-mail — mas repare que a
 * violação <b>nunca</b> pode virar mensagem de erro para quem está cadastrando:
 * a FR-010 exige resposta idêntica quando o canal já existe, porque revelar
 * "este e-mail já tem conta" entrega ao golpista a lista de quem usa o app.
 *
 * <h2>Verificado é o que separa ajuda de captura</h2>
 *
 * Só canal verificado recebe código de recuperação (FR-052). Sem isso, um
 * acompanhante mal-intencionado cadastraria o próprio e-mail no cadastro de
 * outra pessoa e passaria a controlar a recuperação da conta dela (FR-062).
 */
@Entity
@Table(
        name = "canal_contato",
        uniqueConstraints = @UniqueConstraint(
                name = "uq_canal_tipo_valor",
                columnNames = {"tipo", "valor"}))
public class CanalContato {

    @Id
    @Column(nullable = false, updatable = false)
    private UUID id;

    @Column(name = "pessoa_id", nullable = false, updatable = false)
    private UUID pessoaId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20, updatable = false)
    private TipoDeCanal tipo;

    /** CONFIDENCIAL. Já normalizado: minúsculas, sem espaço. */
    @Column(nullable = false, updatable = false)
    private String valor;

    /** Localiza o canal no login sem varrer o valor em claro. */
    @Column(name = "valor_hash", nullable = false, updatable = false)
    private String valorHash;

    @Column(nullable = false)
    private boolean verificado;

    @Column(name = "verificado_em")
    private Instant verificadoEm;

    @Column(nullable = false)
    private boolean principal;

    @Column(name = "criado_em", nullable = false, updatable = false)
    private Instant criadoEm;

    /** Exigido pelo JPA. Não usar em código de aplicação. */
    protected CanalContato() {
    }

    /**
     * Cria um canal ainda <b>não verificado</b>.
     *
     * <p>Começar não verificado não é detalhe de implementação: é a postura de
     * segurança. Posse se prova, não se presume.
     *
     * @param valor já normalizado pelo {@code NormalizadorIdentificador}
     */
    public CanalContato(
            UUID pessoaId,
            TipoDeCanal tipo,
            String valor,
            String valorHash,
            boolean principal,
            Instant criadoEm) {
        this.id = UUID.randomUUID();
        this.pessoaId = Objects.requireNonNull(pessoaId, "pessoaId");
        this.tipo = Objects.requireNonNull(tipo, "tipo");
        this.valor = Objects.requireNonNull(valor, "valor");
        this.valorHash = Objects.requireNonNull(valorHash, "valorHash");
        this.principal = principal;
        this.criadoEm = Objects.requireNonNull(criadoEm, "criadoEm");
        this.verificado = false;
    }

    /**
     * Confirma a posse do canal.
     *
     * <p>Grava a data junto com o booleano porque o banco recusa canal
     * verificado sem data ({@code ck_canal_verificacao_coerente}) — e porque
     * saber <i>quando</i> a posse foi confirmada é o que sustenta a auditoria.
     */
    public void marcarComoVerificado(Instant quando) {
        this.verificado = true;
        this.verificadoEm = Objects.requireNonNull(quando, "quando");
    }

    public UUID getId() {
        return id;
    }

    public UUID getPessoaId() {
        return pessoaId;
    }

    public TipoDeCanal getTipo() {
        return tipo;
    }

    public String getValor() {
        return valor;
    }

    public String getValorHash() {
        return valorHash;
    }

    public boolean isVerificado() {
        return verificado;
    }

    public Instant getVerificadoEm() {
        return verificadoEm;
    }

    public boolean isPrincipal() {
        return principal;
    }

    public Instant getCriadoEm() {
        return criadoEm;
    }

    @Override
    public boolean equals(Object outro) {
        if (this == outro) {
            return true;
        }
        return outro instanceof CanalContato canal && Objects.equals(id, canal.id);
    }

    @Override
    public int hashCode() {
        return Objects.hashCode(id);
    }

    /**
     * Representação para log e depuração.
     *
     * <p><b>Omite o valor do canal.</b> E-mail e telefone são Confidenciais
     * (data-model.md) e a FR-040 proíbe dado de contato legível em log.
     */
    @Override
    public String toString() {
        return "CanalContato[id=%s, tipo=%s, verificado=%s]".formatted(id, tipo, verificado);
    }
}
