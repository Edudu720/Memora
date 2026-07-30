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
import org.hibernate.annotations.Immutable;

/**
 * Trilha de auditoria da autenticação (T013). <b>Somente inserção.</b>
 *
 * <h2>Três camadas para a mesma garantia</h2>
 *
 * A imutabilidade é declarada em três lugares, de propósito:
 *
 * <ol>
 *   <li>{@code @Immutable} — o Hibernate não emite UPDATE para esta entidade;
 *   <li>ausência de qualquer método que altere estado, aqui nesta classe;
 *   <li>o gatilho {@code tg_evento_somente_insercao} no banco, que recusa
 *       UPDATE mesmo vindo de um cliente SQL avulso.
 * </ol>
 *
 * A terceira é a que importa quando as duas primeiras falham. Trilha de
 * auditoria que pode ser reescrita não é trilha de auditoria — e o único jeito
 * de garantir isso é o banco recusar, não a equipe combinar.
 *
 * <h2>Por que {@code pessoaId} aceita nulo</h2>
 *
 * Uma tentativa de entrada em conta inexistente também precisa ser registrada,
 * para que rajadas de tentativa apareçam na auditoria. Como não há conta, não há
 * id — e inventar um revelaria, pela própria existência do registro, que a
 * conta não existe.
 *
 * <h2>O que nunca entra aqui</h2>
 *
 * Senha, código, refresh token ou valor de canal em texto legível. A proibição
 * da FR-040 é absoluta. O endereço de rede entra <b>hasheado</b>: dá para
 * correlacionar abuso da mesma origem sem reter o endereço de ninguém.
 */
@Entity
@Immutable
@Table(name = "evento_autenticacao")
public class EventoAutenticacao {

    @Id
    @Column(nullable = false, updatable = false)
    private UUID id;

    /** Nulo quando a conta não existe — registra sem confirmar existência. */
    @Column(name = "pessoa_id", updatable = false)
    private UUID pessoaId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40, updatable = false)
    private TipoDeEvento tipo;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20, updatable = false)
    private ResultadoDoEvento resultado;

    /** CONFIDENCIAL. Endereço de rede hasheado, nunca em claro. */
    @Column(name = "origem_hash", updatable = false)
    private String origemHash;

    @Column(name = "ocorrido_em", nullable = false, updatable = false)
    private Instant ocorridoEm;

    /** Exigido pelo JPA. Não usar em código de aplicação. */
    protected EventoAutenticacao() {
    }

    /**
     * Registra um evento ligado a uma conta conhecida.
     *
     * @param origemHash endereço de rede <b>já hasheado</b>, ou {@code null}
     */
    public static EventoAutenticacao de(
            UUID pessoaId,
            TipoDeEvento tipo,
            ResultadoDoEvento resultado,
            String origemHash,
            Instant ocorridoEm) {
        return new EventoAutenticacao(
                Objects.requireNonNull(pessoaId, "pessoaId"),
                tipo,
                resultado,
                origemHash,
                ocorridoEm);
    }

    /**
     * Registra um evento <b>sem conta associada</b>.
     *
     * <p>É o caso de tentativa contra identificador que não existe. Existe como
     * fábrica separada para que a ausência de conta seja uma escolha explícita
     * de quem chama, e não um {@code null} esquecido.
     */
    public static EventoAutenticacao semConta(
            TipoDeEvento tipo,
            ResultadoDoEvento resultado,
            String origemHash,
            Instant ocorridoEm) {
        return new EventoAutenticacao(null, tipo, resultado, origemHash, ocorridoEm);
    }

    private EventoAutenticacao(
            UUID pessoaId,
            TipoDeEvento tipo,
            ResultadoDoEvento resultado,
            String origemHash,
            Instant ocorridoEm) {
        this.id = UUID.randomUUID();
        this.pessoaId = pessoaId;
        this.tipo = Objects.requireNonNull(tipo, "tipo");
        this.resultado = Objects.requireNonNull(resultado, "resultado");
        this.origemHash = origemHash;
        this.ocorridoEm = Objects.requireNonNull(ocorridoEm, "ocorridoEm");
    }

    public UUID getId() {
        return id;
    }

    public UUID getPessoaId() {
        return pessoaId;
    }

    public TipoDeEvento getTipo() {
        return tipo;
    }

    public ResultadoDoEvento getResultado() {
        return resultado;
    }

    public String getOrigemHash() {
        return origemHash;
    }

    public Instant getOcorridoEm() {
        return ocorridoEm;
    }

    @Override
    public boolean equals(Object outro) {
        if (this == outro) {
            return true;
        }
        return outro instanceof EventoAutenticacao evento && Objects.equals(id, evento.id);
    }

    @Override
    public int hashCode() {
        return Objects.hashCode(id);
    }

    /** Não inclui {@code origemHash}: é Confidencial mesmo hasheado. */
    @Override
    public String toString() {
        return "EventoAutenticacao[id=%s, tipo=%s, resultado=%s, em=%s]"
                .formatted(id, tipo, resultado, ocorridoEm);
    }
}
