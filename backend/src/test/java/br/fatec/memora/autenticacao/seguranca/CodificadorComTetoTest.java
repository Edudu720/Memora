package br.fatec.memora.autenticacao.seguranca;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * O teto de hashes simultâneos, que existe porque 10 cadastros ao mesmo tempo
 * derrubaram uma JVM de 384 MB de heap com {@code OutOfMemoryError}.
 */
@DisplayName("Teto de hashes de senha simultâneos")
class CodificadorComTetoTest {

    private static final long MIB = 1024L * 1024L;

    /** Dublê que segura cada chamada até ser liberado e anota o pico de simultâneas. */
    private static final class CodificadorBloqueante implements PasswordEncoder {

        final AtomicInteger emAndamento = new AtomicInteger();
        final AtomicInteger pico = new AtomicInteger();
        final CountDownLatch liberar = new CountDownLatch(1);

        @Override
        public String encode(CharSequence senha) {
            entrar();
            try {
                liberar.await();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            } finally {
                emAndamento.decrementAndGet();
            }
            return "hash:" + senha;
        }

        @Override
        public boolean matches(CharSequence senha, String hash) {
            return encode(senha).equals(hash);
        }

        private void entrar() {
            int agora = emAndamento.incrementAndGet();
            pico.accumulateAndGet(agora, Math::max);
        }
    }

    @Nested
    @DisplayName("A fila")
    class Fila {

        @Test
        @DisplayName("com teto 2 e 6 threads, nunca há mais de 2 hashes ao mesmo tempo")
        void picoIgualAoTeto() throws Exception {
            CodificadorBloqueante dubles = new CodificadorBloqueante();
            PasswordEncoder codificador = new CodificadorComTeto(dubles, 2);
            ExecutorService pool = Executors.newFixedThreadPool(6);
            try {
                List<Future<String>> resultados = new ArrayList<>();
                for (int i = 0; i < 6; i++) {
                    String senha = "senha-" + i;
                    resultados.add(pool.submit(() -> codificador.encode(senha)));
                }

                // Espera as duas primeiras chegarem ao dublê e dá tempo às demais de
                // tentarem entrar: se o teto vazar, o pico passa de 2 aqui.
                aguardar(() -> dubles.emAndamento.get() == 2);
                Thread.sleep(300);
                assertThat(dubles.emAndamento.get()).isEqualTo(2);

                dubles.liberar.countDown();

                for (int i = 0; i < 6; i++) {
                    assertThat(resultados.get(i).get(10, TimeUnit.SECONDS))
                            .isEqualTo("hash:senha-" + i);
                }
                assertThat(dubles.pico.get())
                        .as("O teto era 2: o pico de hashes simultaneos nao pode ser outro")
                        .isEqualTo(2);
            } finally {
                pool.shutdownNow();
            }
        }

        @Test
        @DisplayName("a permissão volta mesmo quando o hash falha")
        void liberaNoFinally() {
            PasswordEncoder quebrado =
                    new PasswordEncoder() {
                        @Override
                        public String encode(CharSequence senha) {
                            throw new IllegalStateException("falhou");
                        }

                        @Override
                        public boolean matches(CharSequence senha, String hash) {
                            throw new IllegalStateException("falhou");
                        }
                    };
            PasswordEncoder codificador = new CodificadorComTeto(quebrado, 1);

            for (int i = 0; i < 3; i++) {
                assertThatThrownBy(() -> codificador.encode("x"))
                        .isInstanceOf(IllegalStateException.class);
                assertThatThrownBy(() -> codificador.matches("x", "y"))
                        .isInstanceOf(IllegalStateException.class);
            }
            // Se a permissão vazasse, a segunda chamada já ficaria presa para sempre
            // e este teste não chegaria aqui.
        }

        @Test
        @DisplayName("interrompido na espera, restaura a flag e não calcula o hash")
        void interrupcaoNaEspera() throws Exception {
            CodificadorBloqueante dubles = new CodificadorBloqueante();
            PasswordEncoder codificador = new CodificadorComTeto(dubles, 1);
            ExecutorService pool = Executors.newFixedThreadPool(2);
            try {
                pool.submit(() -> codificador.encode("ocupa a unica permissao"));
                aguardar(() -> dubles.emAndamento.get() == 1);

                AtomicInteger interrompida = new AtomicInteger();
                Future<?> espera =
                        pool.submit(
                                () -> {
                                    try {
                                        codificador.encode("espera");
                                    } catch (IllegalStateException e) {
                                        interrompida.set(
                                                Thread.currentThread().isInterrupted() ? 1 : 0);
                                    }
                                });
                Thread.sleep(200);
                espera.cancel(true);
                aguardar(() -> interrompida.get() == 1);

                assertThat(dubles.pico.get()).isEqualTo(1);
            } finally {
                dubles.liberar.countDown();
                pool.shutdownNow();
            }
        }

        @Test
        @DisplayName("upgradeEncoding só delega e não ocupa permissão")
        void upgradeNaoOcupaPermissao() {
            PasswordEncoder interno =
                    new PasswordEncoder() {
                        @Override
                        public String encode(CharSequence senha) {
                            throw new AssertionError("nao deveria calcular hash");
                        }

                        @Override
                        public boolean matches(CharSequence senha, String hash) {
                            throw new AssertionError("nao deveria calcular hash");
                        }

                        @Override
                        public boolean upgradeEncoding(String hash) {
                            return true;
                        }
                    };

            assertThat(new CodificadorComTeto(interno, 1).upgradeEncoding("qualquer")).isTrue();
        }
    }

    @Nested
    @DisplayName("Como o teto é escolhido")
    class Escolha {

        @Test
        @DisplayName("pela memória: 384 MiB dão 3, 100 MiB dão 1 e 4 GiB dão 32")
        void pelaMemoria() {
            assertThat(ConfiguracaoDeSenha.tetoPelaMemoria(384 * MIB)).isEqualTo(3);
            assertThat(ConfiguracaoDeSenha.tetoPelaMemoria(100 * MIB)).isEqualTo(1);
            assertThat(ConfiguracaoDeSenha.tetoPelaMemoria(4096 * MIB)).isEqualTo(32);
        }

        @Test
        @DisplayName("memória minúscula nunca resulta em teto zero")
        void nuncaZero() {
            assertThat(ConfiguracaoDeSenha.tetoPelaMemoria(1 * MIB)).isEqualTo(1);
        }

        @Test
        @DisplayName("vazio calcula pela memória; valor explícito vale")
        void vazioOuExplicito() {
            assertThat(ConfiguracaoDeSenha.tetoDe("", 384 * MIB)).isEqualTo(3);
            assertThat(ConfiguracaoDeSenha.tetoDe("  ", 384 * MIB)).isEqualTo(3);
            assertThat(ConfiguracaoDeSenha.tetoDe(null, 384 * MIB)).isEqualTo(3);
            assertThat(ConfiguracaoDeSenha.tetoDe("5", 384 * MIB)).isEqualTo(5);
        }

        @Test
        @DisplayName("valor explícito menor que 1 ou que não é número derruba a subida")
        void invalidoDerruba() {
            for (String invalido : new String[] {"0", "-1", "tres"}) {
                assertThatThrownBy(() -> ConfiguracaoDeSenha.tetoDe(invalido, 384 * MIB))
                        .as("teto '%s'", invalido)
                        .isInstanceOf(IllegalStateException.class)
                        .hasMessageContaining("memora.senha.hashes-simultaneos");

                assertThatThrownBy(() -> new ConfiguracaoDeSenha().codificadorDeSenha(invalido))
                        .as("bean com teto '%s'", invalido)
                        .isInstanceOf(IllegalStateException.class);
            }
        }
    }

    private static void aguardar(java.util.function.BooleanSupplier condicao)
            throws InterruptedException {
        long limite = System.nanoTime() + TimeUnit.SECONDS.toNanos(10);
        while (!condicao.getAsBoolean()) {
            if (System.nanoTime() > limite) {
                throw new AssertionError("condicao nao se cumpriu em 10 s");
            }
            Thread.sleep(10);
        }
    }
}
