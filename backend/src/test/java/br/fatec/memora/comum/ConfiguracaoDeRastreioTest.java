package br.fatec.memora.comum;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import javax.crypto.SecretKey;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * A chave que resume a origem na trilha de auditoria (T026).
 *
 * <p>O que esta classe protege nao e o algoritmo — e a chave. HMAC com chave
 * conhecida vale exatamente o mesmo que SHA-256 puro, que o proprio
 * {@link FiltroRastreio} rejeitou por ser reversivel por forca bruta no espaco
 * do IPv4. Logo, os tres casos abaixo sao os tres jeitos de a protecao ser
 * perdida: chave publica, chave curta e chave que muda sem ninguem perceber.
 */
@DisplayName("Chave de resumo da origem")
class ConfiguracaoDeRastreioTest {

    /** Exatamente o piso, para provar que o limite e inclusivo. */
    private static final String CHAVE_NO_PISO = "12345678901234567890123456789012";

    @Nested
    @DisplayName("Sem configuracao")
    class SemConfiguracao {

        /**
         * O caso que motivou a mudanca. Antes havia um valor padrao commitado em
         * {@code application.properties}: quem esquecesse de configurar em
         * producao ficava com a trilha inteira reversivel por qualquer pessoa com
         * acesso de leitura ao repositorio, e nada avisava.
         */
        @ParameterizedTest
        @ValueSource(strings = {"", "   "})
        @DisplayName("chave vazia e sorteada, em vez de cair num padrao conhecido")
        void vaziaSorteia(String naoConfigurada) {
            assertThat(ConfiguracaoDeRastreio.chaveDe(naoConfigurada)).isNotNull();
        }

        @Test
        @DisplayName("nula e sorteada")
        void nulaSorteia() {
            assertThat(ConfiguracaoDeRastreio.chaveDe(null)).isNotNull();
        }

        /**
         * Duas subidas sem configuracao nao podem produzir a mesma chave: se
         * produzissem, seria um padrao fixo com outro nome.
         */
        @Test
        @DisplayName("cada subida sorteia uma chave diferente")
        void sorteioNaoSeRepete() {
            SecretKey primeira = ConfiguracaoDeRastreio.chaveDe("");
            SecretKey segunda = ConfiguracaoDeRastreio.chaveDe("");

            assertThat(primeira.getEncoded()).isNotEqualTo(segunda.getEncoded());
        }

        @Test
        @DisplayName("a chave sorteada tem o tamanho exigido")
        void sorteioTemTamanho() {
            assertThat(ConfiguracaoDeRastreio.chaveDe(null).getEncoded())
                    .hasSize(ConfiguracaoDeRastreio.TAMANHO_MINIMO_EM_BYTES);
        }
    }

    @Nested
    @DisplayName("Chave configurada")
    class Configurada {

        /**
         * Chave curta e adivinhavel, e adivinhar a chave aqui e reverter a trilha
         * inteira. Reprovar na subida e melhor do que rodar meses achando que a
         * origem esta protegida.
         */
        @ParameterizedTest
        @ValueSource(strings = {"curta", "memora-dev-chave-de-origem", "1234567890123456789012345678901"})
        @DisplayName("chave curta demais derruba a subida")
        void curtaDerruba(String curta) {
            assertThatThrownBy(() -> ConfiguracaoDeRastreio.chaveDe(curta))
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining("memora.rastreio.chave-de-origem");
        }

        @Test
        @DisplayName("chave no piso e aceita")
        void pisoEhAceito() {
            assertThat(ConfiguracaoDeRastreio.chaveDe(CHAVE_NO_PISO).getEncoded())
                    .hasSize(ConfiguracaoDeRastreio.TAMANHO_MINIMO_EM_BYTES);
        }

        /**
         * A razao de ser da configuracao: chave informada precisa sobreviver ao
         * reinicio, senao a contagem por origem do limitador (R4) recomeca.
         */
        @Test
        @DisplayName("a mesma chave configurada produz sempre o mesmo material")
        void configuradaEhEstavel() {
            assertThat(ConfiguracaoDeRastreio.chaveDe(CHAVE_NO_PISO).getEncoded())
                    .isEqualTo(ConfiguracaoDeRastreio.chaveDe(CHAVE_NO_PISO).getEncoded());
        }
    }
}
