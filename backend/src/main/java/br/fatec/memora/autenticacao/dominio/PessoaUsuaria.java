package br.fatec.memora.autenticacao.dominio;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Quem usa o Memora (T009).
 *
 * <h2>Por que o id é atribuído e não gerado pelo banco</h2>
 *
 * Identificador sequencial permitiria deduzir quantas pessoas usam o sistema e
 * facilitaria IDOR. O UUID é sorteado no construtor, o que também deixa a
 * entidade com identidade completa antes de ser persistida — {@code equals}
 * funciona desde o primeiro instante.
 *
 * <h2>Fronteira do agregado</h2>
 *
 * Canais, sessões e códigos referenciam esta entidade <b>por id</b>, sem
 * associação JPA. É deliberado: nada no domínio precisa navegar de uma sessão
 * até o objeto da pessoa, e associação preguiçosa com
 * {@code open-in-view=false} explode fora de transação. Consulta é papel de
 * repositório.
 */
@Entity
@Table(name = "pessoa_usuaria")
public class PessoaUsuaria {

    @Id
    @Column(nullable = false, updatable = false)
    private UUID id;

    @Column(name = "nome_tratamento", nullable = false, length = 80)
    private String nomeTratamento;

    /** SENSÍVEL. Argon2id. Nulo apenas em conta exclusivamente social (FR-053). */
    @Column(name = "senha_hash")
    private String senhaHash;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private EstadoDaConta estado;

    @Column(name = "criada_em", nullable = false, updatable = false)
    private Instant criadaEm;

    @Column(name = "ultimo_acesso_em")
    private Instant ultimoAcessoEm;

    @Column(name = "falhas_consecutivas", nullable = false)
    private int falhasConsecutivas;

    @Column(name = "bloqueada_ate")
    private Instant bloqueadaAte;

    /** Exigido pelo JPA. Não usar em código de aplicação. */
    protected PessoaUsuaria() {
    }

    /**
     * Cria uma conta ativa.
     *
     * @param nomeTratamento como a pessoa quer ser chamada; nunca é credencial
     * @param senhaHash      hash Argon2id, ou {@code null} em conta social
     * @param criadaEm       instante da criação
     */
    public PessoaUsuaria(String nomeTratamento, String senhaHash, Instant criadaEm) {
        this.id = UUID.randomUUID();
        this.nomeTratamento = Objects.requireNonNull(nomeTratamento, "nomeTratamento");
        this.senhaHash = senhaHash;
        this.estado = EstadoDaConta.ATIVA;
        this.criadaEm = Objects.requireNonNull(criadaEm, "criadaEm");
        this.falhasConsecutivas = 0;
    }

    /**
     * Registra entrada bem-sucedida: zera as falhas e move o último acesso.
     *
     * <p>Zerar aqui é o que impede que falhas espalhadas ao longo de semanas
     * somem até bloquear uma conta legítima.
     */
    public void registrarEntradaBemSucedida(Instant quando) {
        this.falhasConsecutivas = 0;
        this.bloqueadaAte = null;
        this.estado = EstadoDaConta.ATIVA;
        this.ultimoAcessoEm = Objects.requireNonNull(quando, "quando");
    }

    /**
     * Contabiliza uma tentativa recusada.
     *
     * <p>A escada de espera (1, 5, 15, 60 min) não vive aqui — é do
     * {@code BloqueioProgressivo} (T049). Esta entidade apenas guarda o
     * contador e até quando o bloqueio vale.
     */
    public void registrarFalhaDeEntrada() {
        this.falhasConsecutivas++;
    }

    /** Bloqueia a conta temporariamente até o instante informado (FR-014). */
    public void bloquearAte(Instant limite) {
        this.bloqueadaAte = Objects.requireNonNull(limite, "limite");
        this.estado = EstadoDaConta.BLOQUEADA_TEMPORARIAMENTE;
    }

    /** Troca o hash da senha. Quem revoga as sessões é a camada de segurança. */
    public void trocarSenhaHash(String novoHash) {
        this.senhaHash = Objects.requireNonNull(novoHash, "novoHash");
    }

    public boolean estaBloqueadaEm(Instant momento) {
        return bloqueadaAte != null && bloqueadaAte.isAfter(momento);
    }

    public UUID getId() {
        return id;
    }

    public String getNomeTratamento() {
        return nomeTratamento;
    }

    public String getSenhaHash() {
        return senhaHash;
    }

    public EstadoDaConta getEstado() {
        return estado;
    }

    public Instant getCriadaEm() {
        return criadaEm;
    }

    public Instant getUltimoAcessoEm() {
        return ultimoAcessoEm;
    }

    public int getFalhasConsecutivas() {
        return falhasConsecutivas;
    }

    public Instant getBloqueadaAte() {
        return bloqueadaAte;
    }

    @Override
    public boolean equals(Object outro) {
        if (this == outro) {
            return true;
        }
        return outro instanceof PessoaUsuaria pessoa && Objects.equals(id, pessoa.id);
    }

    @Override
    public int hashCode() {
        return Objects.hashCode(id);
    }

    /**
     * Representação para log e depuração.
     *
     * <p><b>Omite o hash da senha de propósito.</b> A FR-040 proíbe credencial
     * em log, e o caminho mais comum para violar isso é um {@code toString}
     * gerado automaticamente caindo dentro de uma mensagem de erro.
     */
    @Override
    public String toString() {
        return "PessoaUsuaria[id=%s, estado=%s]".formatted(id, estado);
    }
}
