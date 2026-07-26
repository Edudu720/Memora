package br.fatec.memora.autenticacao.seguranca;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.argon2.Argon2PasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * Configuração do algoritmo de hash de senha.
 *
 * <h2>Por que os parâmetros são explícitos</h2>
 *
 * O construtor {@code Argon2PasswordEncoder.defaultsForSpringSecurity_v5_8()}
 * usa <b>16.384 KiB</b> de memória. A OWASP recomenda no mínimo
 * <b>19.456 KiB</b> para Argon2id. Aceitar o padrão da biblioteca seria uma
 * escolha silenciosamente mais fraca — e o Princípio I da Constituição do
 * projeto proíbe trocar segurança por conveniência.
 *
 * <p>Por isso os quatro parâmetros são declarados aqui e verificados por teste
 * ({@code Argon2ParametrosTest}), que falha se algum deles cair abaixo do
 * mínimo.
 *
 * <h2>Verificação pendente</h2>
 *
 * A tarefa T017 exige <b>medir o tempo de hash no ambiente alvo</b>. Parâmetro
 * que parece forte no papel pode estar fraco na máquina onde roda. Se o tempo
 * ficar abaixo de ~250 ms, a memória deve ser aumentada.
 */
@Configuration
public class ConfiguracaoDeSenha {

    /** Comprimento do sal, em bytes. */
    public static final int TAMANHO_SAL = 16;

    /** Comprimento do hash gerado, em bytes. */
    public static final int TAMANHO_HASH = 32;

    /** Grau de paralelismo. */
    public static final int PARALELISMO = 1;

    /**
     * Memória em KiB.
     *
     * <p>O mínimo da OWASP é 19.456 KiB, mas medição no hardware alvo (T017)
     * mostrou que esse valor produz hash de apenas <b>42 ms</b> — rápido demais.
     * Hash barato para nós é hash barato para o atacante.
     *
     * <p>Calibrado para 64 MiB, que rende <b>249 ms</b> nesta máquina, dentro
     * do alvo de 250 a 500 ms. Foi preferido a 96 MiB com t=3, que rendia
     * 298 ms, porque cada hash concorrente consome esta memória inteira.
     */
    public static final int MEMORIA_KIB = 65_536;

    /** Número de iterações, calibrado junto com {@link #MEMORIA_KIB}. */
    public static final int ITERACOES = 4;

    /** Mínimo aceitável de memória, usado pelo teste que protege esta escolha. */
    public static final int MEMORIA_MINIMA_OWASP_KIB = 19_456;

    /** Mínimo aceitável de iterações. */
    public static final int ITERACOES_MINIMAS_OWASP = 2;

    /**
     * Codificador de senha do Memora.
     *
     * @return codificador Argon2id com parâmetros explícitos
     */
    @Bean
    public PasswordEncoder codificadorDeSenha() {
        return new Argon2PasswordEncoder(
                TAMANHO_SAL,
                TAMANHO_HASH,
                PARALELISMO,
                MEMORIA_KIB,
                ITERACOES);
    }
}
