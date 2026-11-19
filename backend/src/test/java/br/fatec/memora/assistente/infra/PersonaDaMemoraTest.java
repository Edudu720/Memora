package br.fatec.memora.assistente.infra;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * O que a persona diz sobre serviço sensível (US5, FR-041, FR-042).
 *
 * <p>Este texto não é a segurança da feature — quem impede abrir o banco é o
 * {@code AutorizadorDeAcao} (H3). O que se protege aqui é a outra metade: que a
 * Memora <b>ensine</b> o banco. Uma instrução que diga "nunca ensina" faz um
 * modelo real recusar ajuda justamente onde a US5 existe para ajudar, e nenhum
 * teste com o simulado perceberia.
 */
@DisplayName("Persona — serviço sensível se ensina, e nunca se abre")
class PersonaDaMemoraTest {

    private static final String TEXTO = PersonaDaMemora.INSTRUCAO.toLowerCase(Locale.ROOT);

    @Test
    @DisplayName("nenhuma frase proíbe ensinar — era a contradição da primeira versão")
    void nadaProibeEnsinar() {
        assertThat(TEXTO)
                .doesNotContain("nem ensina")
                .doesNotContain("não ensina")
                .doesNotContain("nunca ensina");
    }

    @Test
    @DisplayName("diz que ensina o caminho de serviço sensível")
    void ensinaOSensivel() {
        assertThat(TEXTO).contains("banco").contains("ensina o caminho");
    }

    @Test
    @DisplayName("a recusa de abrir vale mesmo com pedido e confirmação (FR-041)")
    void recusaNaoTemExcecao() {
        // "Por conta própria" dava a entender que, com pedido, ela abriria.
        assertThat(TEXTO)
                .doesNotContain("por conta própria")
                .contains("mesmo que a pessoa peça");
    }
    @Test
    @DisplayName("afirma ser um programa de computador sem ficar repetindo (FR-013, T084)")
    void afirmaSerProgramaSemRepetir() {
        assertThat(TEXTO)
                .contains("programa de computador")
                .contains("sem ficar repetindo");
    }

    @Test
    @DisplayName("recusa ação financeira e irreversível explicando por quê (FR-018, FR-031, FR-037, T087)")
    void recusaAcaoFinanceiraEIrreversivel() {
        assertThat(TEXTO)
                .contains("ação financeira")
                .contains("pix")
                .contains("transferir")
                .contains("irreversíveis")
                .contains("segurança do dinheiro");
    }

    @Test
    @DisplayName("acolhe quando a pessoa não acha um botão porque a tela mudou (T090)")
    void acolheQuandoNaoAchaBotaoNaTela() {
        assertThat(TEXTO)
                .contains("não achei o botão")
                .contains("sem culpar")
                .contains("mudam desenhos");
    }

    @Test
    @DisplayName("limita a no máximo um emoji por mensagem, nunca no lugar de uma palavra (FR-023, T042)")
    void limitaUmEmojiPorMensagem() {
        assertThat(TEXTO)
                .contains("no máximo um emoji por mensagem")
                .contains("nunca no lugar de uma palavra");

        Pattern pictograma = Pattern.compile("\\p{IsExtended_Pictographic}");
        assertThat(contar(pictograma, ClienteDaAssistenteSimulado.RESPOSTA_PADRAO))
                .isLessThanOrEqualTo(1);
        assertThat(contar(pictograma, ClienteDaAssistenteSimulado.RECUSA_FINANCEIRA_PADRAO))
                .isLessThanOrEqualTo(1);
    }

    private static int contar(Pattern padrao, String texto) {
        Matcher matcher = padrao.matcher(texto);
        int total = 0;
        while (matcher.find()) {
            total++;
        }
        return total;
    }
}