package br.fatec.memora.assistente.dominio;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;
import org.hibernate.annotations.Immutable;

/**
 * Trilha do que a assistente fez (T009, FR-020). <b>Somente inserção.</b>
 *
 * <h2>As mesmas três camadas de EventoAutenticacao</h2>
 *
 * <ol>
 *   <li>{@code @Immutable} — o Hibernate não emite UPDATE;
 *   <li>nenhum método que altere estado, aqui;
 *   <li>o gatilho {@code tg_evento_assistente_somente_insercao}, que recusa
 *       UPDATE <b>no banco</b>, inclusive por SQL avulso.
 * </ol>
 *
 * A terceira é a que vale quando as duas primeiras falham.
 *
 * <h2>O limite de 120 caracteres não é estético</h2>
 *
 * {@code pedidoResumido} é a única exceção à FR-036, que proíbe conteúdo de
 * conversa no registro. Ela existe porque sem alguma lembrança do pedido o
 * registro da FR-023 viraria <i>"uma ação aconteceu às 14h"</i>, que não serve à
 * pessoa — e a FR-023 existe justamente para ela poder desconfiar.
 *
 * <p>O corte acontece <b>aqui, no servidor</b>. Confiá-lo ao aparelho
 * transformaria um campo de tabela imutável em texto livre de tamanho
 * arbitrário, escrito por quem controla o cliente.
 */
@Entity
@Immutable
@Table(name = "evento_da_assistente")
public class EventoDaAssistente {

    /** Quanto do pedido cabe no registro. */
    public static final int LIMITE_DO_RESUMO = 120;

    @Id
    @Column(nullable = false, updatable = false)
    private UUID id;

    @Column(name = "pessoa_id", nullable = false, updatable = false)
    private UUID pessoaId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40, updatable = false)
    private TipoDeEventoDaAssistente tipo;

    /** Nulo quando o evento não é sobre um serviço — {@code LIMITE_ATINGIDO}. */
    @Column(name = "servico_id", updatable = false)
    private UUID servicoId;

    /** CONFIDENCIAL. Truncado a {@link #LIMITE_DO_RESUMO}. */
    @Column(name = "pedido_resumido", length = LIMITE_DO_RESUMO, updatable = false)
    private String pedidoResumido;

    /** CONFIDENCIAL. Endereço de rede hasheado, nunca em claro. */
    @Column(name = "origem_hash", updatable = false)
    private String origemHash;

    @Column(name = "ocorrido_em", nullable = false, updatable = false)
    private Instant ocorridoEm;

    /** Exigido pelo JPA. Não usar em código de aplicação. */
    protected EventoDaAssistente() {
    }

    /**
     * Registra um evento ligado a um serviço — ação executada ou recusada.
     *
     * @param pedidoResumido o que a pessoa pediu; <b>truncado aqui</b>
     */
    public static EventoDaAssistente sobreServico(
            UUID pessoaId,
            TipoDeEventoDaAssistente tipo,
            UUID servicoId,
            String pedidoResumido,
            String origemHash,
            Instant ocorridoEm) {
        return new EventoDaAssistente(
                pessoaId,
                tipo,
                Objects.requireNonNull(servicoId, "servicoId"),
                pedidoResumido,
                origemHash,
                ocorridoEm);
    }

    /**
     * Registra um evento que não é sobre um serviço.
     *
     * <p>Fábrica separada para que a ausência de serviço seja escolha explícita
     * de quem chama, e não um {@code null} esquecido — mesmo raciocínio de
     * {@code EventoAutenticacao.semConta}.
     *
     * <p><b>Aceita o pedido mesmo sem serviço</b>, e essa combinação é o caso
     * mais importante da trilha: quando o modelo sugere abrir algo que o
     * catálogo recusa, não há serviço a apontar — o pacote não existe lá —, mas
     * há um pedido, e é ele que diz o que estava sendo tentado.
     *
     * <p>Uma versão anterior desta fábrica descartava o pedido, e o evento
     * {@code ACAO_RECUSADA} — o mais valioso de todos — era gravado vazio. O
     * cenário H6 pegou isso.
     */
    public static EventoDaAssistente semServico(
            UUID pessoaId,
            TipoDeEventoDaAssistente tipo,
            String pedidoResumido,
            String origemHash,
            Instant ocorridoEm) {
        return new EventoDaAssistente(
                pessoaId, tipo, null, pedidoResumido, origemHash, ocorridoEm);
    }

    private EventoDaAssistente(
            UUID pessoaId,
            TipoDeEventoDaAssistente tipo,
            UUID servicoId,
            String pedidoResumido,
            String origemHash,
            Instant ocorridoEm) {
        this.id = UUID.randomUUID();
        this.pessoaId = Objects.requireNonNull(pessoaId, "pessoaId");
        this.tipo = Objects.requireNonNull(tipo, "tipo");
        this.servicoId = servicoId;
        this.pedidoResumido = truncar(pedidoResumido);
        this.origemHash = origemHash;
        this.ocorridoEm = Objects.requireNonNull(ocorridoEm, "ocorridoEm");
    }

    private static final java.util.regex.Pattern DIGITOS_CONSECUTIVOS =
            java.util.regex.Pattern.compile("\\b\\d{4,}\\b");

    private static final java.util.regex.Pattern TERMOS_DE_SEGREDO =
            java.util.regex.Pattern.compile(
                    "(?i)\\b(senha|c[oó]digo|codigo|token|pin)\\s*(?:[:=]|é|e)?\\s*(\\S+)",
                    java.util.regex.Pattern.UNICODE_CHARACTER_CLASS);

    /**
     * Sanitiza e corta o pedido no limite da coluna (T079, FR-036).
     *
     * <p>Filtra senha, código, token e sequência de 4 ou mais dígitos do
     * {@code pedido_resumido} antes de gravar na trilha de auditoria.
     *
     * <p>Truncar em vez de recusar é deliberado: uma exceção aqui abortaria o
     * registro de uma ação que <b>já aconteceu</b>, e trilha com buraco é pior
     * que trilha com frase cortada.
     */
    static String truncar(String pedido) {
        if (pedido == null) {
            return null;
        }
        String limpo = pedido.strip();
        if (limpo.isEmpty()) {
            return null;
        }
        // Mascara termos de segredo (senha, código, pin, token)
        String sanitizado = TERMOS_DE_SEGREDO.matcher(limpo).replaceAll(m -> m.group(1) + " ***");
        // Mascara sequências longas de dígitos (4 ou mais)
        sanitizado = DIGITOS_CONSECUTIVOS.matcher(sanitizado).replaceAll("***");

        return sanitizado.length() <= LIMITE_DO_RESUMO
                ? sanitizado
                : sanitizado.substring(0, LIMITE_DO_RESUMO);
    }

    public UUID getId() {
        return id;
    }

    public UUID getPessoaId() {
        return pessoaId;
    }

    public TipoDeEventoDaAssistente getTipo() {
        return tipo;
    }

    public Optional<UUID> getServicoId() {
        return Optional.ofNullable(servicoId);
    }

    public Optional<String> getPedidoResumido() {
        return Optional.ofNullable(pedidoResumido);
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
        return outro instanceof EventoDaAssistente evento && Objects.equals(id, evento.id);
    }

    @Override
    public int hashCode() {
        return Objects.hashCode(id);
    }

    /** Não inclui {@code pedidoResumido} nem {@code origemHash}: são Confidenciais. */
    @Override
    public String toString() {
        return "EventoDaAssistente[id=%s, tipo=%s, em=%s]".formatted(id, tipo, ocorridoEm);
    }
}
