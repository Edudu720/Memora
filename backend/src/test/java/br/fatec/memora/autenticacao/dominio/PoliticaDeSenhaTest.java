package br.fatec.memora.autenticacao.dominio;

import static org.assertj.core.api.Assertions.assertThat;

import br.fatec.memora.autenticacao.dominio.PoliticaDeSenha.Recusa;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * Politica de senha (T034, FR-042).
 *
 * <p>Duas regras, e nenhuma fala de simbolo. Exigir maiuscula, numero e simbolo
 * produz "Senha@123" — curta, previsivel, presente em todo vazamento — e empurra
 * quem tem dificuldade com o teclado a escrever a senha num papel ao lado do
 * aparelho.
 */
@DisplayName("Politica de senha")
class PoliticaDeSenhaTest {

    @Nested
    @DisplayName("Comprimento")
    class Comprimento {

        @ParameterizedTest
        @ValueSource(strings = {"", "a", "curta", "novechars"})
        @DisplayName("abaixo do piso e recusada por comprimento")
        void abaixoDoPiso(String curta) {
            assertThat(PoliticaDeSenha.avaliar(curta)).isEqualTo(Recusa.CURTA);
        }

        @Test
        @DisplayName("nula e recusada, e nao estoura")
        void nulaNaoEstoura() {
            assertThat(PoliticaDeSenha.avaliar(null)).isEqualTo(Recusa.CURTA);
        }

        @Test
        @DisplayName("exatamente no piso e aceita")
        void noPisoEhAceita() {
            assertThat("dez.letras").hasSize(PoliticaDeSenha.COMPRIMENTO_MINIMO);
            assertThat(PoliticaDeSenha.aceita("dez.letras")).isTrue();
        }

        /**
         * O coracao da FR-042: frase longa sem simbolo nenhum passa, e a senha
         * "complexa" curta nao. Se este teste um dia exigir maiuscula ou digito,
         * a politica mudou de lado.
         */
        @Test
        @DisplayName("frase longa sem simbolo passa; complexa e curta nao")
        void comprimentoVenceComplexidade() {
            assertThat(PoliticaDeSenha.aceita("meu cachorro chama pipoca")).isTrue();
            assertThat(PoliticaDeSenha.aceita("S3nh@!9")).isFalse();
        }
    }

    @Nested
    @DisplayName("Senhas comprometidas")
    class Comprometidas {

        @ParameterizedTest
        @ValueSource(strings = {"1234567890", "senha123456", "qwertyuiop", "brasil12345"})
        @DisplayName("senha do topo de vazamento e recusada mesmo tendo o comprimento")
        void recusaConhecidas(String conhecida) {
            assertThat(conhecida.length()).isGreaterThanOrEqualTo(PoliticaDeSenha.COMPRIMENTO_MINIMO);
            assertThat(PoliticaDeSenha.avaliar(conhecida)).isEqualTo(Recusa.COMPROMETIDA);
        }

        /** Trocar a caixa e o desvio mais obvio da lista. */
        @ParameterizedTest
        @ValueSource(strings = {"Senha123456", "SENHA123456", "SeNhA123456"})
        @DisplayName("variacao de caixa nao escapa da lista")
        void caixaNaoEscapa(String variacao) {
            assertThat(PoliticaDeSenha.avaliar(variacao)).isEqualTo(Recusa.COMPROMETIDA);
        }

        @Test
        @DisplayName("senha longa e incomum e aceita")
        void incomumEhAceita() {
            assertThat(PoliticaDeSenha.aceita("pipoca no varal azul")).isTrue();
        }
    }

    @Nested
    @DisplayName("Acordo com o aplicativo")
    class AcordoComOAplicativo {

        /**
         * O aplicativo mostra "Ter pelo menos 10 letras" e habilita o botao com
         * base nisso. Se o piso do servidor subisse sem a tela acompanhar, a
         * pessoa veria a regra atendida na tela e o cadastro recusado — sem
         * nenhuma forma de entender por que.
         *
         * <p>Este teste le o controlador do aplicativo. E incomum, e e de
         * proposito: o acoplamento existe de verdade, e sem isto ele so
         * apareceria em producao.
         */
        @Test
        @DisplayName("o piso do servidor e o mesmo que a tela promete")
        void mesmoPisoDaTela() throws Exception {
            Path controlador =
                    Path.of("..", "app", "lib", "features", "autenticacao", "presentation",
                            "controladores", "controlador_cadastro.dart");

            assertThat(controlador).exists();

            List<String> regras =
                    Files.readAllLines(controlador).stream()
                            .filter(linha -> linha.contains("s.length >="))
                            .toList();

            assertThat(regras)
                    .as("regra de comprimento da senha no controlador do aplicativo")
                    .anySatisfy(
                            linha ->
                                    assertThat(linha)
                                            .contains(
                                                    "s.length >= "
                                                            + PoliticaDeSenha.COMPRIMENTO_MINIMO));
        }
    }
}
