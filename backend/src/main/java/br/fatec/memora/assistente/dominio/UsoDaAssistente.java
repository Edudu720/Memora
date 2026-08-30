package br.fatec.memora.assistente.dominio;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import java.io.Serializable;
import java.time.LocalDate;
import java.util.Objects;
import java.util.UUID;

/**
 * Quantas conversas uma conta abriu em um dia (R7 do research).
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

    @Column(nullable = false)
    private int conversas;

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

    /** Registra mais uma conversa aberta neste dia. */
    public void registrarConversa() {
        this.conversas++;
    }

    /** O teto já foi atingido? */
    public boolean atingiu(int teto) {
        return conversas >= teto;
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
