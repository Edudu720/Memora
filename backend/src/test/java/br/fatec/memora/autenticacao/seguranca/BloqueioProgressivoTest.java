package br.fatec.memora.autenticacao.seguranca;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Duration;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/** A escada de espera depois de falhas consecutivas (FR-014, R4). */
@DisplayName("Bloqueio progressivo")
class BloqueioProgressivoTest {

    private final BloqueioProgressivo escada = new BloqueioProgressivo();

    @Test
    @DisplayName("erro de digitacao nao bloqueia ninguem")
    void poucasFalhasNaoBloqueiam() {
        for (int falhas = 0; falhas < BloqueioProgressivo.FALHAS_ATE_BLOQUEAR; falhas++) {
            assertThat(escada.duracaoPara(falhas))
                    .as("%d falhas nao deveriam bloquear", falhas)
                    .isEmpty();
        }
    }

    @Test
    @DisplayName("a escada sobe 1, 5, 15 e 60 minutos")
    void escadaSobeConformeOEsperado() {
        assertThat(escada.duracaoPara(5)).contains(Duration.ofMinutes(1));
        assertThat(escada.duracaoPara(6)).contains(Duration.ofMinutes(5));
        assertThat(escada.duracaoPara(7)).contains(Duration.ofMinutes(15));
        assertThat(escada.duracaoPara(8)).contains(Duration.ofMinutes(60));
    }

    @Test
    @DisplayName("a espera para no ultimo degrau, nao cresce para sempre")
    void escadaTemTeto() {
        assertThat(escada.duracaoPara(9)).contains(Duration.ofMinutes(60));
        assertThat(escada.duracaoPara(50)).contains(Duration.ofMinutes(60));
        assertThat(escada.duracaoPara(5_000)).contains(Duration.ofMinutes(60));
    }

    @Test
    @DisplayName("a espera nunca diminui quando as falhas aumentam")
    void escadaNuncaDesce() {
        Duration anterior = Duration.ZERO;

        for (int falhas = BloqueioProgressivo.FALHAS_ATE_BLOQUEAR; falhas <= 20; falhas++) {
            Duration atual = escada.duracaoPara(falhas).orElseThrow();
            assertThat(atual)
                    .as("a espera diminuiu de %d para %d falhas", falhas - 1, falhas)
                    .isGreaterThanOrEqualTo(anterior);
            anterior = atual;
        }
    }

    @Test
    @DisplayName("contagem negativa nao bloqueia")
    void contagemNegativaNaoBloqueia() {
        assertThat(escada.duracaoPara(-1)).isEmpty();
    }
}
