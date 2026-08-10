package br.fatec.memora.autenticacao.seguranca;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Arrays;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.argon2.Argon2PasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * O tempo de resposta nao revela se a conta existe (T023, R3).
 *
 * <h2>Como este teste foi validado</h2>
 *
 * Teste de tempo e facil de escrever de um jeito que nunca reprova. Este foi
 * conferido introduzindo o atalho de proposito em {@link VerificadorCredenciais}
 * — devolver {@code false} direto quando nao ha hash armazenado — e confirmando
 * que ele reprova com folga.
 *
 * <h2>Usa o Argon2 real</h2>
 *
 * Com codificador barato o teste nao provaria nada: a diferenca que interessa so
 * aparece quando o hash custa os ~240 ms calibrados em T017.
 */
@DisplayName("Tempo constante na verificacao de credenciais")
class TempoConstanteTest {

    /** Amostras por cenario. Mediana descarta o pico ocasional da JVM. */
    private static final int AMOSTRAS = 5;

    /**
     * Piso de tempo para o caminho sem conta.
     *
     * <p>O hash calibrado custa cerca de 240 ms. Um atalho devolveria em menos
     * de 1 ms. O piso de 100 ms fica longe dos dois lados: nao reprova por
     * lentidao de maquina compartilhada, e nao passa se o hash for pulado.
     */
    private static final long PISO_EM_MILISSEGUNDOS = 100;

    /** Diferenca relativa tolerada entre as medianas. */
    private static final double DIFERENCA_MAXIMA = 0.50;

    private final PasswordEncoder codificador = new Argon2PasswordEncoder(
            ConfiguracaoDeSenha.TAMANHO_SAL,
            ConfiguracaoDeSenha.TAMANHO_HASH,
            ConfiguracaoDeSenha.PARALELISMO,
            ConfiguracaoDeSenha.MEMORIA_KIB,
            ConfiguracaoDeSenha.ITERACOES);

    @Test
    @DisplayName("conta inexistente custa o mesmo que senha errada em conta existente")
    void tempoNaoDenunciaExistenciaDaConta() {
        VerificadorCredenciais verificador = new VerificadorCredenciais(codificador);
        String hashDeContaReal = codificador.encode("senha-verdadeira-da-conta");

        // Aquece: a primeira passagem paga compilacao JIT e alocacao inicial.
        verificador.confere("chute", hashDeContaReal);
        verificador.confere("chute", null);

        long comConta = medianaEmMilissegundos(
                () -> verificador.confere("chute-errado", hashDeContaReal));
        long semConta = medianaEmMilissegundos(() -> verificador.confere("chute-errado", null));

        assertThat(semConta)
                .as("conta inexistente respondeu em %d ms — o hash foi pulado?", semConta)
                .isGreaterThanOrEqualTo(PISO_EM_MILISSEGUNDOS);

        double diferencaRelativa =
                Math.abs(comConta - semConta) / (double) Math.min(comConta, semConta);

        assertThat(diferencaRelativa)
                .as("com conta: %d ms, sem conta: %d ms", comConta, semConta)
                .isLessThanOrEqualTo(DIFERENCA_MAXIMA);
    }

    @Test
    @DisplayName("nenhum dos dois caminhos confere a senha errada")
    void nenhumCaminhoAceitaSenhaErrada() {
        VerificadorCredenciais verificador = new VerificadorCredenciais(codificador);

        assertThat(verificador.confere("chute", codificador.encode("outra-senha"))).isFalse();
        assertThat(verificador.confere("chute", null)).isFalse();
    }

    private static long medianaEmMilissegundos(Runnable operacao) {
        long[] medidas = new long[AMOSTRAS];

        for (int i = 0; i < AMOSTRAS; i++) {
            long inicio = System.nanoTime();
            operacao.run();
            medidas[i] = (System.nanoTime() - inicio) / 1_000_000;
        }

        Arrays.sort(medidas);
        return medidas[AMOSTRAS / 2];
    }
}
