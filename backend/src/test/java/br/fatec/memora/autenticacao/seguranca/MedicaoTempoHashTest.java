package br.fatec.memora.autenticacao.seguranca;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * Mede o custo real do hash no ambiente onde o código roda (tarefa T017).
 *
 * <p>Parâmetro que parece forte no papel pode estar fraco na máquina de
 * verdade. Um hash rápido demais significa que um atacante também o calcula
 * rápido — e a defesa do Argon2 é justamente ser caro.
 *
 * <p>Este teste <b>não falha por lentidão</b>: em máquina lenta ou em CI
 * compartilhado o tempo varia muito, e um limite superior geraria falha
 * intermitente. Ele falha apenas se o hash for <b>rápido demais</b>, o que
 * indica parâmetro enfraquecido.
 */
class MedicaoTempoHashTest {

    /**
     * Piso de custo. Abaixo disto o parâmetro está fraco para o hardware atual.
     *
     * <p>Valor deliberadamente conservador para não quebrar em CI: a análise
     * real é feita pelo número impresso, não por este limite.
     */
    private static final long PISO_MILISSEGUNDOS = 150;

    private final PasswordEncoder codificador =
            new ConfiguracaoDeSenha().codificadorDeSenha();

    @Test
    @DisplayName("o hash custa tempo suficiente neste ambiente")
    void medeCustoDoHash() {
        // Aquecimento, para não medir a inicialização da JVM.
        codificador.encode("aquecimento");

        int repeticoes = 5;
        long inicio = System.nanoTime();
        for (int i = 0; i < repeticoes; i++) {
            codificador.encode("uma frase que so eu lembro " + i);
        }
        long medioMs = (System.nanoTime() - inicio) / repeticoes / 1_000_000;

        System.out.printf(
                "%n[T017] Argon2id m=%d KiB, t=%d, p=%d -> %d ms por hash "
                        + "(alvo: 250 ms a 500 ms)%n",
                ConfiguracaoDeSenha.MEMORIA_KIB,
                ConfiguracaoDeSenha.ITERACOES,
                ConfiguracaoDeSenha.PARALELISMO,
                medioMs);

        assertThat(medioMs)
                .as("Hash rápido demais (%d ms) indica parâmetro enfraquecido. "
                        + "Aumente a memória em ConfiguracaoDeSenha.", medioMs)
                .isGreaterThanOrEqualTo(PISO_MILISSEGUNDOS);
    }
}
