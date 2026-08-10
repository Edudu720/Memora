package br.fatec.memora.autenticacao.dominio;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.ValueSource;

/**
 * Mascara do canal na resposta (FR-035, FR-041).
 *
 * <p>A mascara existe para a pessoa <b>reconhecer</b> o proprio canal sem que a
 * tela exiba o valor inteiro para quem estiver por perto. O caso que importa e o
 * da parte local curta: mostrar tres caracteres de uma parte local de dois
 * revelaria o endereco completo, que e exatamente o que a mascara evita.
 */
@DisplayName("Mascara do canal")
class MascaradorDeCanalTest {

    /**
     * O exemplo do contrato e "ana****@gmail.com". Ele descreve a <b>saida</b>,
     * nao a entrada: quem produz esse resultado e "anamaria@gmail.com", nao
     * "ana@gmail.com". Ler o exemplo como entrada foi o primeiro erro cometido
     * ao escrever este teste, e ele revelaria a parte local inteira — ver
     * {@link #localCurta}.
     */
    @ParameterizedTest
    @CsvSource({
        "anamaria@gmail.com,      ana****@gmail.com",
        "roberto@dominio.com.br,  rob****@dominio.com.br",
        "maria.silva@uol.com.br,  mar****@uol.com.br"
    })
    @DisplayName("e-mail mostra o comeco e o dominio inteiro")
    void email(String valor, String esperado) {
        assertThat(MascaradorDeCanal.mascarar(TipoDeCanal.EMAIL, valor)).isEqualTo(esperado);
    }

    /**
     * Se a parte local tem 3 caracteres ou menos, mostrar "os 3 primeiros" e
     * mostrar tudo. Some inteira.
     */
    @ParameterizedTest
    @ValueSource(strings = {"ab@x.com", "abc@x.com", "a@x.com", "ana@x.com"})
    @DisplayName("parte local curta e escondida por inteiro")
    void localCurta(String valor) {
        String mascarado = MascaradorDeCanal.mascarar(TipoDeCanal.EMAIL, valor);

        assertThat(mascarado).isEqualTo("****@x.com");
        assertThat(mascarado).doesNotContain(valor.substring(0, valor.indexOf('@')));
    }

    @Test
    @DisplayName("telefone mostra so os quatro ultimos digitos")
    void telefone() {
        assertThat(MascaradorDeCanal.mascarar(TipoDeCanal.TELEFONE, "19999991234"))
                .isEqualTo("****1234");
    }

    @ParameterizedTest
    @ValueSource(strings = {"1234", "123", ""})
    @DisplayName("telefone curto demais e escondido por inteiro")
    void telefoneCurto(String valor) {
        assertThat(MascaradorDeCanal.mascarar(TipoDeCanal.TELEFONE, valor)).isEqualTo("****");
    }

    @Test
    @DisplayName("valor sem arroba nao vira palpite de onde cortar")
    void semArroba() {
        assertThat(MascaradorDeCanal.mascarar(TipoDeCanal.EMAIL, "isto-nao-e-email"))
                .isEqualTo("****");
    }

    @Test
    @DisplayName("nulo nao estoura")
    void nulo() {
        assertThat(MascaradorDeCanal.mascarar(TipoDeCanal.EMAIL, null)).isEqualTo("****");
    }
}
