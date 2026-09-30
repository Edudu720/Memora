package br.fatec.memora.assistente.dominio;

import static org.assertj.core.api.Assertions.assertThat;

import br.fatec.memora.assistente.dominio.UsoDaAssistente.Desfecho;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * O que é "uma conversa" para o limite diário (FR-053).
 *
 * <p>Sem banco e sem Spring: a regra mora na entidade, e aqui ela é exercida
 * com instantes escritos à mão. O teste pelo serviço fica no H10
 * ({@code LimiteDeConversasTest}).
 */
@DisplayName("FR-053 — o que conta como uma conversa")
class UsoDaAssistenteTest {

    private static final int TETO = 3;
    private static final Instant INICIO = Instant.parse("2026-09-30T13:00:00Z");

    private UsoDaAssistente uso;
    private Instant agora;

    @BeforeEach
    void preparar() {
        uso = UsoDaAssistente.primeiroDoDia(UUID.randomUUID(), LocalDate.of(2026, 9, 30));
        agora = INICIO;
    }

    @Test
    @DisplayName("o primeiro turno do dia abre uma conversa")
    void primeiroTurnoAbre() {
        assertThat(turno()).isEqualTo(Desfecho.NOVA_CONVERSA);
        assertThat(uso.getConversas()).isEqualTo(1);
    }

    @Test
    @DisplayName("mensagens seguidas são uma conversa só — era o defeito: cada turno contava")
    void mensagensSeguidasSaoUmaConversa() {
        turno();
        for (int i = 0; i < 10; i++) {
            andar(Duration.ofMinutes(2));
            assertThat(turno()).isEqualTo(Desfecho.CONTINUA);
        }
        assertThat(uso.getConversas()).isEqualTo(1);
    }

    @Test
    @DisplayName("29 minutos de pausa ainda é a mesma conversa")
    void pausaCurtaContinua() {
        turno();
        andar(Duration.ofMinutes(29));
        assertThat(turno()).isEqualTo(Desfecho.CONTINUA);
    }

    @Test
    @DisplayName("30 minutos de pausa abrem outra")
    void pausaLongaAbreOutra() {
        turno();
        andar(UsoDaAssistente.PAUSA_QUE_ENCERRA_A_CONVERSA);
        assertThat(turno()).isEqualTo(Desfecho.NOVA_CONVERSA);
        assertThat(uso.getConversas()).isEqualTo(2);
    }

    @Test
    @DisplayName("a pausa conta a partir do último turno, e não do primeiro")
    void pausaContaDoUltimoTurno() {
        turno();
        for (int i = 0; i < 5; i++) {
            andar(Duration.ofMinutes(20));
            assertThat(turno()).isEqualTo(Desfecho.CONTINUA);
        }
        assertThat(uso.getConversas()).isEqualTo(1);
    }

    @Test
    @DisplayName("o 31º turno seguido abre outra conversa — senão o freio de custo some")
    void tetoDeTurnosAbreOutra() {
        for (int i = 0; i < UsoDaAssistente.TURNOS_POR_CONVERSA; i++) {
            turno();
        }
        assertThat(uso.getConversas()).isEqualTo(1);

        assertThat(turno()).isEqualTo(Desfecho.NOVA_CONVERSA);
        assertThat(uso.getConversas()).isEqualTo(2);
    }

    @Test
    @DisplayName("no teto, a conversa nova é recusada e nada muda")
    void tetoRecusaConversaNova() {
        esgotar();
        int conversas = uso.getConversas();

        andar(UsoDaAssistente.PAUSA_QUE_ENCERRA_A_CONVERSA);
        assertThat(turno()).isEqualTo(Desfecho.TETO_ATINGIDO);
        assertThat(uso.getConversas()).isEqualTo(conversas);

        // Recusar não pode reiniciar a pausa: senão cada insistência empurraria
        // a próxima conversa para mais longe, e o estado mentiria.
        assertThat(turno()).isEqualTo(Desfecho.TETO_ATINGIDO);
    }

    @Test
    @DisplayName("no teto, a conversa em curso continua — ninguém é cortado no meio de um passo")
    void conversaEmCursoContinuaNoTeto() {
        esgotar();

        andar(Duration.ofMinutes(5));
        assertThat(turno()).isEqualTo(Desfecho.CONTINUA);
    }

    @Test
    @DisplayName("no teto, a conversa em curso para nos 30 turnos, como qualquer outra")
    void conversaEmCursoNaoEhInfinita() {
        esgotar();
        // esgotar() deixou a terceira conversa com 1 turno; faltam 29.
        for (int i = 1; i < UsoDaAssistente.TURNOS_POR_CONVERSA; i++) {
            assertThat(turno()).isEqualTo(Desfecho.CONTINUA);
        }
        assertThat(turno()).isEqualTo(Desfecho.TETO_ATINGIDO);
    }

    /** Abre {@link #TETO} conversas, cada uma com um turno. */
    private void esgotar() {
        for (int i = 0; i < TETO; i++) {
            andar(UsoDaAssistente.PAUSA_QUE_ENCERRA_A_CONVERSA);
            assertThat(turno()).isEqualTo(Desfecho.NOVA_CONVERSA);
        }
    }

    private Desfecho turno() {
        return uso.registrarTurno(agora, TETO);
    }

    private void andar(Duration quanto) {
        agora = agora.plus(quanto);
    }
}
