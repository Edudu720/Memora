package br.fatec.memora.assistente.dominio;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import java.io.Serializable;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Objects;
import java.util.UUID;

/**
 * Quantas conversas uma conta abriu em um dia (R7 do research, FR-053).
 *
 * <p>Conta <b>conversas</b>, e não turnos. A primeira versão contava cada
 * mensagem, e o teto de 20 virava 20 mensagens por dia — o bastante para um
 * único passo a passo difícil acabar com o dia da pessoa.
 *
 * <h2>Por que isto existe, se não estava na spec</h2>
 *
 * É consequência direta de haver um endpoint autenticado que <b>gasta dinheiro
 * por chamada</b>. Sem teto, uma conta comprometida esgota a cota do provedor e
 * derruba a assistente para todo mundo — uma negação de serviço que se paga em
 * reais.
 *
 * <p>Estado no banco, e não em memória, pelo mesmo motivo do
 * {@code LimitadorTentativas}: contador que zera no reinício do processo não
 * limita nada, e quem quiser contorná-lo só precisa esperar um deploy.
 *
 * <h2>Diferente da trilha, isto pode ser apagado</h2>
 *
 * {@code uso_da_assistente} tem {@code ON DELETE CASCADE} e nenhum gatilho de
 * imutabilidade: é contador operacional, não histórico de segurança. A trilha
 * do que a assistente fez está em {@link EventoDaAssistente}, e essa não se
 * reescreve.
 */
@Entity
@Table(name = "uso_da_assistente")
@IdClass(UsoDaAssistente.Chave.class)
public class UsoDaAssistente {

    @Id
    @Column(name = "pessoa_id", nullable = false, updatable = false)
    private UUID pessoaId;

    @Id
    @Column(nullable = false, updatable = false)
    private LocalDate dia;

    /**
     * Pausa que encerra uma conversa: o mesmo prazo da inatividade da feature
     * 001. Quem ficou meia hora sem escrever voltou para outra coisa.
     */
    public static final Duration PAUSA_QUE_ENCERRA_A_CONVERSA = Duration.ofMinutes(30);

    /**
     * Turnos que cabem numa conversa. Sem este teto, contar conversas em vez de
     * turnos tiraria o freio de custo: uma "conversa" só, sem pausa, poderia ter
     * mil turnos. Com ele, o pior dia de uma conta é teto × 30 turnos.
     */
    public static final int TURNOS_POR_CONVERSA = 30;

    @Column(nullable = false)
    private int conversas;

    /**
     * Quando foi o último turno. Um instante, e nada do que foi dito: o conteúdo
     * continua só no aparelho (FR-047).
     */
    @Column(name = "ultimo_turno_em")
    private Instant ultimoTurnoEm;

    @Column(name = "turnos_na_conversa", nullable = false)
    private int turnosNaConversa;

    /** Exigido pelo JPA. Não usar em código de aplicação. */
    protected UsoDaAssistente() {
    }

    /** Primeiro uso do dia. */
    public static UsoDaAssistente primeiroDoDia(UUID pessoaId, LocalDate dia) {
        UsoDaAssistente uso = new UsoDaAssistente();
        uso.pessoaId = Objects.requireNonNull(pessoaId, "pessoaId");
        uso.dia = Objects.requireNonNull(dia, "dia");
        uso.conversas = 0;
        return uso;
    }

    /**
     * Registra um turno da pessoa, e decide se ele abre conversa nova (FR-053).
     *
     * <p>Uma conversa nova começa quando nenhuma está em curso: é o primeiro
     * turno do dia, passou {@link #PAUSA_QUE_ENCERRA_A_CONVERSA} desde o último
     * turno, ou a atual já tem {@link #TURNOS_POR_CONVERSA}. Só a conversa
     * <b>nova</b> esbarra no teto — a que está em curso continua, porque cortar
     * a pessoa no meio de um passo a passo é pior do que deixá-la terminar.
     *
     * <p>Recusado, o turno não muda nada: nem conta, nem reinicia a pausa.
     *
     * @param agora o instante do turno
     * @param teto  quantas conversas cabem no dia
     * @return o que este turno foi
     */
    public Desfecho registrarTurno(Instant agora, int teto) {
        Objects.requireNonNull(agora, "agora");

        boolean emCurso =
                ultimoTurnoEm != null
                        && Duration.between(ultimoTurnoEm, agora)
                                        .compareTo(PAUSA_QUE_ENCERRA_A_CONVERSA) < 0
                        && turnosNaConversa < TURNOS_POR_CONVERSA;

        if (emCurso) {
            turnosNaConversa++;
            ultimoTurnoEm = agora;
            return Desfecho.CONTINUA;
        }
        if (conversas >= teto) {
            return Desfecho.TETO_ATINGIDO;
        }
        conversas++;
        turnosNaConversa = 1;
        ultimoTurnoEm = agora;
        return Desfecho.NOVA_CONVERSA;
    }

    /** O que um turno foi, para o limite diário. */
    public enum Desfecho {
        /** Abriu uma conversa, e ela contou no teto do dia. */
        NOVA_CONVERSA,
        /** Seguiu a conversa em curso, sem contar no teto. */
        CONTINUA,
        /** Precisaria abrir conversa nova, e o teto do dia já foi atingido. */
        TETO_ATINGIDO
    }

    public UUID getPessoaId() {
        return pessoaId;
    }

    public LocalDate getDia() {
        return dia;
    }

    public int getConversas() {
        return conversas;
    }

    /** Chave composta de {@link UsoDaAssistente}. */
    public static class Chave implements Serializable {

        private UUID pessoaId;
        private LocalDate dia;

        /** Exigido pelo JPA. */
        public Chave() {
        }

        @Override
        public boolean equals(Object outro) {
            if (this == outro) {
                return true;
            }
            return outro instanceof Chave chave
                    && Objects.equals(pessoaId, chave.pessoaId)
                    && Objects.equals(dia, chave.dia);
        }

        @Override
        public int hashCode() {
            return Objects.hash(pessoaId, dia);
        }
    }
}
