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
        this(nomeTratamento, senhaHash, criadaEm, EstadoDaConta.ATIVA);
    }

    /**
     * Cria uma conta num estado escolhido — hoje, {@link EstadoDaConta#ATIVA} ou
     * {@link EstadoDaConta#PENDENTE_VERIFICACAO} (T057).
     *
     * <p>O cadastro assistido usa a segunda forma: a conta existe, mas não
     * serve para entrar enquanto a posse do canal não for confirmada (FR-062).
     *
     * @param estadoInicial nunca {@link EstadoDaConta#DESATIVADA}, que é
     *     resultado de um ato posterior e não de nascimento
     */
    public PessoaUsuaria(
            String nomeTratamento, String senhaHash, Instant criadaEm,
            EstadoDaConta estadoInicial) {
        this.id = UUID.randomUUID();
        this.nomeTratamento = Objects.requireNonNull(nomeTratamento, "nomeTratamento");
        this.senhaHash = senhaHash;
        this.estado = exigirEstadoDeNascimento(estadoInicial);
        this.criadaEm = Objects.requireNonNull(criadaEm, "criadaEm");
        this.falhasConsecutivas = 0;
    }

    private static EstadoDaConta exigirEstadoDeNascimento(EstadoDaConta estado) {
        Objects.requireNonNull(estado, "estadoInicial");
        if (estado != EstadoDaConta.ATIVA && estado != EstadoDaConta.PENDENTE_VERIFICACAO) {
            throw new IllegalArgumentException("Conta nao nasce em " + estado);
        }
        return estado;
    }

    /**
     * Conclui a verificação de posse do canal e libera a conta (T057, FR-062).
     *
     * <p>Só age sobre conta {@link EstadoDaConta#PENDENTE_VERIFICACAO}. Chamar
     * isto numa conta {@link EstadoDaConta#DESATIVADA} não a ressuscita, e numa
     * conta já ativa não faz nada — verificar um segundo canal é operação
     * comum e não pode mexer no ciclo de vida.
     *
     * @return {@code true} se esta chamada foi a que ativou a conta
     */
    public boolean concluirVerificacaoPendente() {
        if (this.estado != EstadoDaConta.PENDENTE_VERIFICACAO) {
            return false;
        }
        this.estado = EstadoDaConta.ATIVA;
        return true;
    }

    /**
     * Registra entrada bem-sucedida: zera as falhas e move o último acesso.
     *
     * <p>Zerar aqui é o que impede que falhas espalhadas ao longo de semanas
     * somem até bloquear uma conta legítima.
     *
     * <p><b>Estado de ciclo de vida não vira {@code ATIVA} por aqui.</b> Ver
     * {@link EstadoDaConta#ehDeCicloDeVida()}: {@link EstadoDaConta#DESATIVADA}
     * é terminal e {@link EstadoDaConta#PENDENTE_VERIFICACAO} espera um ato
     * explícito. Promover qualquer um dos dois como efeito colateral de um
     * login é como a conta desativada ressuscitava antes da revisão da PR #15 —
     * e seria como o cadastro assistido furaria a FR-062.
     */
    public void registrarEntradaBemSucedida(Instant quando) {
        this.falhasConsecutivas = 0;
        this.bloqueadaAte = null;
        if (!this.estado.ehDeCicloDeVida()) {
            this.estado = EstadoDaConta.ATIVA;
        }
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

    /**
     * Bloqueia a conta temporariamente até o instante informado (FR-014).
     *
     * <p><b>Estado de ciclo de vida não se perde ao ser bloqueado.</b>
     * {@code estado} guarda duas coisas de naturezas diferentes: o ciclo de vida
     * da conta ({@code PENDENTE_VERIFICACAO}, {@code DESATIVADA}) e uma tranca
     * temporária cuja verdade real mora em {@code bloqueada_ate}. Sem esta
     * guarda, cinco tentativas recusadas sobrescreveriam {@code DESATIVADA} com
     * {@code BLOQUEADA_TEMPORARIAMENTE}, e passado o prazo da tranca a conta
     * desativada entraria normalmente — apagando de quebra qualquer registro de
     * que ela um dia foi desativada. Com {@code PENDENTE_VERIFICACAO} o efeito
     * seria pior: a conta assistida sairia da espera sem ninguém ter confirmado
     * canal nenhum.
     */
    public void bloquearAte(Instant limite) {
        this.bloqueadaAte = Objects.requireNonNull(limite, "limite");
        if (!this.estado.ehDeCicloDeVida()) {
            this.estado = EstadoDaConta.BLOQUEADA_TEMPORARIAMENTE;
        }
    }

    /**
     * Desativa a conta.
     *
     * <p>Estado terminal por decisão: nem o bloqueio temporário nem uma entrada
     * bem-sucedida saem dele. Reativar é ato explícito, e ainda não existe.
     */
    public void desativar() {
        this.estado = EstadoDaConta.DESATIVADA;
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
