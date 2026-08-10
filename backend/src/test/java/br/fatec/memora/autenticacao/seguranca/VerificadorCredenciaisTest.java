package br.fatec.memora.autenticacao.seguranca;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * Verificacao de senha que nao denuncia a existencia da conta (T022, R3).
 *
 * <p>A propriedade de <b>tempo</b> e medida em {@code TempoConstanteTest} (T023),
 * com o Argon2 real. Aqui verificamos o comportamento: que o hash e executado
 * mesmo sem conta, que e o que produz aquele tempo.
 */
@DisplayName("Verificador de credenciais")
class VerificadorCredenciaisTest {

    @Test
    @DisplayName("senha correta confere")
    void senhaCorretaConfere() {
        CodificadorDeMentira codificador = new CodificadorDeMentira();
        VerificadorCredenciais verificador = new VerificadorCredenciais(codificador);

        assertThat(verificador.confere("segredo-correto", codificador.encode("segredo-correto")))
                .isTrue();
    }

    @Test
    @DisplayName("senha errada nao confere")
    void senhaErradaNaoConfere() {
        CodificadorDeMentira codificador = new CodificadorDeMentira();
        VerificadorCredenciais verificador = new VerificadorCredenciais(codificador);

        assertThat(verificador.confere("chute", codificador.encode("segredo-correto"))).isFalse();
    }

    @Test
    @DisplayName("conta inexistente nao confere")
    void contaInexistenteNaoConfere() {
        CodificadorDeMentira codificador = new CodificadorDeMentira();
        VerificadorCredenciais verificador = new VerificadorCredenciais(codificador);

        assertThat(verificador.confere("qualquer-senha", null)).isFalse();
    }

    @Test
    @DisplayName("o hash roda mesmo sem conta — e o que iguala o tempo (R3)")
    void hashRodaMesmoSemConta() {
        CodificadorDeMentira codificador = new CodificadorDeMentira();
        VerificadorCredenciais verificador = new VerificadorCredenciais(codificador);
        codificador.comparacoes.set(0);

        verificador.confere("qualquer-senha", null);

        // Sem esta comparacao, a resposta para conta inexistente voltaria na hora
        // e a diferenca de tempo revelaria quem tem conta no Memora.
        assertThat(codificador.comparacoes.get())
                .as("a comparacao precisa acontecer mesmo sem hash armazenado")
                .isEqualTo(1);
    }

    @Test
    @DisplayName("o hash roda uma vez so quando a conta existe")
    void hashRodaUmaVezComConta() {
        CodificadorDeMentira codificador = new CodificadorDeMentira();
        VerificadorCredenciais verificador = new VerificadorCredenciais(codificador);
        String armazenado = codificador.encode("segredo-correto");
        codificador.comparacoes.set(0);

        verificador.confere("segredo-correto", armazenado);

        assertThat(codificador.comparacoes.get()).isEqualTo(1);
    }

    @Test
    @DisplayName("o hash ficticio nasce do mesmo codificador, com os mesmos parametros")
    void hashFicticioUsaOMesmoCodificador() {
        CodificadorDeMentira codificador = new CodificadorDeMentira();

        new VerificadorCredenciais(codificador);

        // Se o hash ficticio fosse uma constante escrita a mao, ele poderia
        // carregar parametros diferentes dos hashes reais — e a diferenca de
        // custo entre eles reabriria justamente o vazamento de tempo.
        assertThat(codificador.codificacoes.get())
                .as("o verificador deveria produzir o hash ficticio com o codificador recebido")
                .isEqualTo(1);
    }

    /**
     * Codificador barato, para o teste nao pagar 240 ms por chamada do Argon2
     * real. Conta quantas vezes foi usado — e esse numero que revela se o
     * verificador executou a comparacao.
     */
    private static final class CodificadorDeMentira implements PasswordEncoder {

        private final AtomicInteger comparacoes = new AtomicInteger();
        private final AtomicInteger codificacoes = new AtomicInteger();

        @Override
        public String encode(CharSequence senha) {
            codificacoes.incrementAndGet();
            return "codificado:" + senha;
        }

        @Override
        public boolean matches(CharSequence senha, String armazenado) {
            comparacoes.incrementAndGet();
            return ("codificado:" + senha).equals(armazenado);
        }
    }
}
