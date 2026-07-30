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
 * Código de 6 dígitos para confirmar posse de canal ou recuperar acesso (T012).
 *
 * <h2>Por que código e não link</h2>
 *
 * A decisão R5 escolheu código digitado em vez de link clicável. O motivo é a
 * defesa contra engenharia social: ensinar uma pessoa idosa a clicar em link
 * recebido por mensagem é ensinar exatamente o hábito que o golpe usa. Digitar
 * um número no aplicativo que ela mesma abriu não tem essa ambiguidade.
 *
 * <h2>Uso único, prazo curto, tentativas contadas</h2>
 *
 * As três proteções são independentes e cada uma cobre uma falha da outra:
 * o prazo de 10 minutos limita a janela de um código interceptado; o uso único
 * impede replay; e o limite de tentativas impede adivinhar 6 dígitos por força
 * bruta.
 */
@Entity
@Table(name = "codigo_verificacao")
public class CodigoVerificacao {

    /**
     * Tentativas erradas admitidas antes de o código ser descartado.
     *
     * <p>Cinco é folgado para quem digita devagar e apertado para quem tenta
     * adivinhar: com 10<sup>6</sup> combinações, cinco chances dão 0,0005% de
     * acerto por código.
     */
    public static final int MAXIMO_DE_TENTATIVAS = 5;

    @Id
    @Column(nullable = false, updatable = false)
    private UUID id;

    @Column(name = "canal_id", nullable = false, updatable = false)
    private UUID canalId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30, updatable = false)
    private FinalidadeDoCodigo finalidade;

    /** SENSÍVEL. Hasheado; o código em claro existe apenas no envio. */
    @Column(name = "codigo_hash", nullable = false, updatable = false)
    private String codigoHash;

    @Column(name = "expira_em", nullable = false)
    private Instant expiraEm;

    @Column(name = "usado_em")
    private Instant usadoEm;

    @Column(nullable = false)
    private int tentativas;

    @Column(name = "criado_em", nullable = false, updatable = false)
    private Instant criadoEm;

    /** Exigido pelo JPA. Não usar em código de aplicação. */
    protected CodigoVerificacao() {
    }

    public CodigoVerificacao(
            UUID canalId,
            FinalidadeDoCodigo finalidade,
            String codigoHash,
            Instant criadoEm,
            Instant expiraEm) {
        this.id = UUID.randomUUID();
        this.canalId = Objects.requireNonNull(canalId, "canalId");
        this.finalidade = Objects.requireNonNull(finalidade, "finalidade");
        this.codigoHash = Objects.requireNonNull(codigoHash, "codigoHash");
        this.criadoEm = Objects.requireNonNull(criadoEm, "criadoEm");
        this.expiraEm = Objects.requireNonNull(expiraEm, "expiraEm");
        this.tentativas = 0;
    }

    /** Consome o código. Uso único (FR-020): a segunda chamada não tem efeito. */
    public void marcarComoUsado(Instant quando) {
        if (this.usadoEm == null) {
            this.usadoEm = Objects.requireNonNull(quando, "quando");
        }
    }

    /** Contabiliza uma tentativa errada. */
    public void registrarTentativaErrada() {
        this.tentativas++;
    }

    /** Descarta o código antecipadamente — usado ao emitir um substituto. */
    public void invalidar(Instant quando) {
        marcarComoUsado(quando);
    }

    public boolean foiUsado() {
        return usadoEm != null;
    }

    public boolean expirouEm(Instant momento) {
        return !expiraEm.isAfter(momento);
    }

    public boolean excedeuTentativas() {
        return tentativas >= MAXIMO_DE_TENTATIVAS;
    }

    /** Ainda vale: não usado, dentro do prazo e com tentativas restantes. */
    public boolean estaValidoEm(Instant momento) {
        return !foiUsado() && !expirouEm(momento) && !excedeuTentativas();
    }

    public UUID getId() {
        return id;
    }

    public UUID getCanalId() {
        return canalId;
    }

    public FinalidadeDoCodigo getFinalidade() {
        return finalidade;
    }

    public String getCodigoHash() {
        return codigoHash;
    }

    public Instant getExpiraEm() {
        return expiraEm;
    }

    public Instant getUsadoEm() {
        return usadoEm;
    }

    public int getTentativas() {
        return tentativas;
    }

    public Instant getCriadoEm() {
        return criadoEm;
    }

    @Override
    public boolean equals(Object outro) {
        if (this == outro) {
            return true;
        }
        return outro instanceof CodigoVerificacao codigo && Objects.equals(id, codigo.id);
    }

    @Override
    public int hashCode() {
        return Objects.hashCode(id);
    }

    /**
     * Representação para log e depuração.
     *
     * <p><b>Omite o hash do código.</b> Um código de 6 dígitos tem espaço de
     * busca pequeno: hash vazado é hash quebrado em segundos.
     */
    @Override
    public String toString() {
        return "CodigoVerificacao[id=%s, finalidade=%s, usado=%s, tentativas=%d]"
                .formatted(id, finalidade, foiUsado(), tentativas);
    }
}
