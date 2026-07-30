package br.fatec.memora.autenticacao.seguranca;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.HashSet;
import java.util.Set;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/** Geracao e hash do refresh token opaco (T018). */
@DisplayName("Gerador de segredo opaco")
class GeradorDeSegredoOpacoTest {

    private final GeradorDeSegredoOpaco gerador = new GeradorDeSegredoOpaco();

    @Test
    @DisplayName("nunca gera o mesmo segredo duas vezes")
    void segredosSaoUnicos() {
        Set<String> vistos = new HashSet<>();

        for (int i = 0; i < 1_000; i++) {
            assertThat(vistos.add(gerador.gerar())).as("segredo repetido na volta %d", i).isTrue();
        }
    }

    @Test
    @DisplayName("o segredo carrega ao menos 256 bits de entropia")
    void segredoTemEntropiaSuficiente() {
        String segredo = gerador.gerar();

        // Base64url sem preenchimento: cada caractere carrega 6 bits.
        assertThat(segredo.length() * 6).isGreaterThanOrEqualTo(256);
        assertThat(segredo).matches("[A-Za-z0-9_-]+");
    }

    @Test
    @DisplayName("o hash do mesmo segredo e sempre igual")
    void hashEhDeterministico() {
        String segredo = gerador.gerar();

        assertThat(gerador.hashDe(segredo)).isEqualTo(gerador.hashDe(segredo));
    }

    @Test
    @DisplayName("segredos diferentes produzem hashes diferentes")
    void hashDistingueSegredos() {
        assertThat(gerador.hashDe(gerador.gerar())).isNotEqualTo(gerador.hashDe(gerador.gerar()));
    }

    @Test
    @DisplayName("o hash nao contem o segredo")
    void hashNaoRevelaOSegredo() {
        String segredo = gerador.gerar();

        assertThat(gerador.hashDe(segredo)).doesNotContain(segredo);
    }

    @Test
    @DisplayName("o hash e rapido — refresh token nao usa Argon2")
    void hashEhRapido() {
        String segredo = gerador.gerar();
        gerador.hashDe(segredo); // aquece a JVM

        long inicio = System.nanoTime();
        for (int i = 0; i < 1_000; i++) {
            gerador.hashDe(segredo);
        }
        long milissegundos = (System.nanoTime() - inicio) / 1_000_000;

        // O Argon2 do projeto custa ~240 ms por hash: mil chamadas levariam
        // quatro minutos. Hash lento existe para proteger segredo de baixa
        // entropia, como senha. Um valor aleatorio de 256 bits nao tem o que
        // proteger por lentidao — e a renovacao de sessao roda a cada abertura
        // do aplicativo.
        assertThat(milissegundos)
                .as("mil hashes deveriam levar bem menos de um segundo")
                .isLessThan(1_000);
    }
}
