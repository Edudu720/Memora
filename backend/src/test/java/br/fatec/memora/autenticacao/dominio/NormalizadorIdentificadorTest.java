package br.fatec.memora.autenticacao.dominio;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Locale;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * Normalizacao do identificador (T037).
 *
 * <p>O que se protege aqui nao e formatacao: e a unicidade do canal. Duas formas
 * do mesmo identificador significam conta duplicada, login que falha para quem
 * digitou certo, e FR-010 furada — bastaria trocar uma maiuscula para descobrir
 * se o canal ja existe.
 */
@DisplayName("Normalizacao do identificador")
class NormalizadorIdentificadorTest {

    @Nested
    @DisplayName("E-mail")
    class Email {

        /**
         * O teclado do Android poe maiuscula na primeira letra sozinho. Se isso
         * gerasse outra forma canonica, a pessoa criaria a segunda conta da vida
         * sem perceber, e a primeira — com os dados dela — ficaria inacessivel.
         */
        @ParameterizedTest
        @ValueSource(
                strings = {
                    "ana@gmail.com",
                    "Ana@Gmail.com",
                    "ANA@GMAIL.COM",
                    "  ana@gmail.com  ",
                    "\tana@gmail.com\n"
                })
        @DisplayName("as variantes do mesmo endereco colapsam numa forma so")
        void variantesColapsam(String escrito) {
            assertThat(NormalizadorIdentificador.normalizar(TipoDeCanal.EMAIL, escrito))
                    .isEqualTo("ana@gmail.com");
        }

        /**
         * Ponto e sufixo +etiqueta sao politica do Gmail, nao regra de e-mail.
         * Aplicar a todos faria enderecos de pessoas diferentes colidirem em
         * servidores que os distinguem — e a pessoa errada perderia o acesso.
         */
        @Test
        @DisplayName("ponto e sufixo +etiqueta sao preservados")
        void naoInventaRegraDeProvedor() {
            assertThat(NormalizadorIdentificador.normalizar(TipoDeCanal.EMAIL, "a.na+livros@dominio.com"))
                    .isEqualTo("a.na+livros@dominio.com");
        }

        /**
         * Em turco, "I".toLowerCase() com o local do sistema devolve "i" sem
         * ponto — outro caractere. O mesmo endereco teria duas formas canonicas
         * conforme o local do servidor, e ninguem descobriria isso ate a conta
         * sumir em producao.
         */
        @Test
        @DisplayName("o resultado nao depende do local do servidor")
        void independeDoLocal() {
            Locale original = Locale.getDefault();
            try {
                Locale.setDefault(Locale.forLanguageTag("tr"));

                assertThat(NormalizadorIdentificador.normalizar(TipoDeCanal.EMAIL, "ANA@ILHA.COM"))
                        .isEqualTo("ana@ilha.com");
            } finally {
                Locale.setDefault(original);
            }
        }
    }

    @Nested
    @DisplayName("Telefone")
    class Telefone {

        /** A pessoa nao vai lembrar com qual pontuacao cadastrou. */
        @ParameterizedTest
        @ValueSource(
                strings = {
                    "19999991234",
                    "(19) 99999-1234",
                    "19 99999 1234",
                    "19.99999.1234",
                    " 19999991234 "
                })
        @DisplayName("pontuacao e espaco nao mudam a linha")
        void pontuacaoNaoImporta(String escrito) {
            assertThat(NormalizadorIdentificador.normalizar(TipoDeCanal.TELEFONE, escrito))
                    .isEqualTo("19999991234");
        }

        /**
         * Digito em largura dupla vem de teclado de outro idioma e passaria
         * despercebido: sem a normalizacao NFKC ele nao e descartado nem
         * convertido — vira um numero truncado, e o cadastro grava uma linha
         * que nao existe.
         */
        @Test
        @DisplayName("digito em variante tipografica vira digito comum")
        void varianteTipografica() {
            assertThat(NormalizadorIdentificador.normalizar(TipoDeCanal.TELEFONE, "１９９９９９９１２３４"))
                    .isEqualTo("19999991234");
        }

        /**
         * Presumir o codigo do pais faria a mesma linha ter duas formas
         * canonicas, conforme a pessoa tenha digitado o prefixo ou nao.
         */
        @Test
        @DisplayName("o codigo do pais nao e presumido nem removido")
        void naoPresumePais() {
            assertThat(NormalizadorIdentificador.normalizar(TipoDeCanal.TELEFONE, "+55 19 99999-1234"))
                    .isEqualTo("5519999991234");
        }
    }

    @Nested
    @DisplayName("Ausencia de valor")
    class SemValor {

        @Test
        @DisplayName("nulo continua nulo, em vez de virar vazio")
        void nuloContinuaNulo() {
            assertThat(NormalizadorIdentificador.normalizar(TipoDeCanal.EMAIL, null)).isNull();
        }

        @ParameterizedTest
        @CsvSource({"EMAIL,''", "TELEFONE,''", "TELEFONE,'()- '"})
        @DisplayName("valor sem conteudo util vira vazio, e a validacao decide")
        void semConteudoUtil(TipoDeCanal tipo, String valor) {
            assertThat(NormalizadorIdentificador.normalizar(tipo, valor)).isEmpty();
        }
    }
}
