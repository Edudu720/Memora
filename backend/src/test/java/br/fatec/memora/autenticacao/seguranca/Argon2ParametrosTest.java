package br.fatec.memora.autenticacao.seguranca;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * Protege os parâmetros do Argon2id contra enfraquecimento acidental.
 *
 * <p>Este teste não confia na constante declarada: ele <b>lê o hash gerado</b>.
 * O formato PHC embute os parâmetros efetivamente usados, por exemplo:
 *
 * <pre>$argon2id$v=19$m=19456,t=2,p=1$c2FsdA$aGFzaA</pre>
 *
 * <p>Assim, trocar o codificador por um mais fraco — inclusive voltando ao
 * padrão do Spring Security, que usa 16.384 KiB — faz o teste falhar.
 */
class Argon2ParametrosTest {

    private static final Pattern FORMATO_PHC =
            Pattern.compile("^\\$argon2(id|i|d)\\$v=(\\d+)\\$m=(\\d+),t=(\\d+),p=(\\d+)\\$");

    private final PasswordEncoder codificador =
            new ConfiguracaoDeSenha().codificadorDeSenha("");

    @Test
    @DisplayName("a memória usada não fica abaixo do mínimo da OWASP")
    void memoriaAtendeAoMinimoDaOwasp() {
        Matcher m = parametrosDoHash();

        int memoria = Integer.parseInt(m.group(3));

        assertThat(memoria)
                .as("O padrão do Spring Security usa 16.384 KiB, abaixo do "
                        + "mínimo de %d KiB recomendado pela OWASP. "
                        + "Parâmetro fraco não gera bug, gera vítima.",
                        ConfiguracaoDeSenha.MEMORIA_MINIMA_OWASP_KIB)
                .isGreaterThanOrEqualTo(ConfiguracaoDeSenha.MEMORIA_MINIMA_OWASP_KIB);
    }

    @Test
    @DisplayName("o número de iterações não fica abaixo do mínimo")
    void iteracoesAtendemAoMinimo() {
        Matcher m = parametrosDoHash();

        int iteracoes = Integer.parseInt(m.group(4));

        assertThat(iteracoes)
                .isGreaterThanOrEqualTo(ConfiguracaoDeSenha.ITERACOES_MINIMAS_OWASP);
    }

    @Test
    @DisplayName("a variante usada é a argon2id")
    void usaVarianteId() {
        Matcher m = parametrosDoHash();

        assertThat(m.group(1))
                .as("argon2i e argon2d resistem a ataques diferentes. A "
                        + "variante id combina as duas defesas e é a "
                        + "recomendada para senha.")
                .isEqualTo("id");
    }

    @Test
    @DisplayName("senhas iguais geram hashes diferentes")
    void salTornaCadaHashUnico() {
        String a = codificador.encode("uma frase que so eu lembro");
        String b = codificador.encode("uma frase que so eu lembro");

        assertThat(a)
                .as("Sem sal por senha, senhas iguais viram hashes iguais e um "
                        + "vazamento expõe todo mundo de uma vez.")
                .isNotEqualTo(b);
    }

    @Test
    @DisplayName("a senha correta é reconhecida e a errada é recusada")
    void verificaSenhaCorretamente() {
        String hash = codificador.encode("uma frase que so eu lembro");

        assertThat(codificador.matches("uma frase que so eu lembro", hash)).isTrue();
        assertThat(codificador.matches("outra frase qualquer", hash)).isFalse();
    }

    /** Extrai os parâmetros efetivamente usados a partir do hash gerado. */
    private Matcher parametrosDoHash() {
        String hash = codificador.encode("senha de teste do memora");
        Matcher m = FORMATO_PHC.matcher(hash);

        assertThat(m.find())
                .as("Hash gerado fora do formato PHC esperado: %s", hash)
                .isTrue();

        return m;
    }
}
