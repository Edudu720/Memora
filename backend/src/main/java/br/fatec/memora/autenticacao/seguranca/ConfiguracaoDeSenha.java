package br.fatec.memora.autenticacao.seguranca;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
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
 *
 * <h2>O teto de hashes simultâneos</h2>
 *
 * Cada hash aloca {@link #MEMORIA_KIB} KiB (64 MiB) de heap. Medido na imagem
 * do Docker com {@code --memory=512m} (o plano gratuito do Render), com
 * {@code MaxRAMPercentage=75}, isto é, ~384 MB de heap: <b>5 cadastros
 * simultâneos passam e 10 derrubam a JVM</b> com
 * {@code java.lang.OutOfMemoryError: Java heap space}. Os endpoints de cadastro,
 * entrada e recuperação são públicos, então qualquer um derrubaria o servidor.
 *
 * <p>O bean devolvido é o Argon2id embrulhado em {@link CodificadorComTeto},
 * que faz as chamadas além do teto esperarem na fila. O teto vem de
 * {@code memora.senha.hashes-simultaneos}; vazio, calcula-se metade do heap
 * dividida pelo custo de um hash (384 MiB resulta em 3), deixando a outra
 * metade para o resto da aplicação. Valor explícito menor que 1 derruba a
 * subida.
 *
 * <p>Continua existindo <b>um só</b> {@code PasswordEncoder}, e todo hash de
 * senha ou de código (cadastro, entrada, recuperação, verificação de canal,
 * {@code VerificadorCredenciais}) passa por ele. É por isso que a R3, o tempo
 * constante com ou sem conta, continua valendo: o hash roda sempre, e a fila é
 * a mesma nos dois casos.
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

    /** Fração do heap que os hashes simultâneos podem ocupar; o resto é da aplicação. */
    static final double FRACAO_DO_HEAP_PARA_HASHES = 0.5;

    private static final Logger LOG = LoggerFactory.getLogger(ConfiguracaoDeSenha.class);

    /**
     * Codificador de senha do Memora: Argon2id com teto de hashes simultâneos.
     *
     * @param tetoConfigurado valor de {@code memora.senha.hashes-simultaneos};
     *     vazio calcula pela memória disponível
     * @return codificador Argon2id com parâmetros explícitos
     * @throws IllegalStateException se o teto informado não for um inteiro
     *     maior ou igual a 1
     */
    @Bean
    public PasswordEncoder codificadorDeSenha(
            @Value("${memora.senha.hashes-simultaneos:}") String tetoConfigurado) {
        long memoriaMaxima = Runtime.getRuntime().maxMemory();
        boolean informado = tetoConfigurado != null && !tetoConfigurado.isBlank();
        int teto = tetoDe(tetoConfigurado, memoriaMaxima);

        LOG.info(
                "Teto de hashes de senha simultaneos: {} ({}).",
                teto,
                informado
                        ? "configurado em memora.senha.hashes-simultaneos"
                        : "calculado pelo heap maximo de %d MiB"
                                .formatted(memoriaMaxima / (1024 * 1024)));

        return new CodificadorComTeto(
                new Argon2PasswordEncoder(
                        TAMANHO_SAL, TAMANHO_HASH, PARALELISMO, MEMORIA_KIB, ITERACOES),
                teto);
    }

    /**
     * Decide o teto: o valor configurado, se houver, ou o calculado.
     *
     * <p>Falha na subida em vez de corrigir em silêncio: um 0 ou um texto que
     * não é número, aceitos como "sem teto", devolveriam a queda por memória
     * sem que ninguém soubesse que a proteção não está ligada.
     */
    static int tetoDe(String configurado, long memoriaMaximaEmBytes) {
        if (configurado == null || configurado.isBlank()) {
            return tetoPelaMemoria(memoriaMaximaEmBytes);
        }
        int valor;
        try {
            valor = Integer.parseInt(configurado.trim());
        } catch (NumberFormatException e) {
            throw new IllegalStateException(
                    "memora.senha.hashes-simultaneos deve ser um inteiro; veio '%s'"
                            .formatted(configurado),
                    e);
        }
        if (valor < 1) {
            throw new IllegalStateException(
                    "memora.senha.hashes-simultaneos deve ser pelo menos 1; veio %d"
                            .formatted(valor));
        }
        return valor;
    }

    /**
     * Quantos hashes cabem em metade do heap, no mínimo um.
     *
     * @param memoriaMaximaEmBytes {@code Runtime.maxMemory()}
     */
    static int tetoPelaMemoria(long memoriaMaximaEmBytes) {
        return Math.max(
                1,
                (int) (memoriaMaximaEmBytes * FRACAO_DO_HEAP_PARA_HASHES
                        / (MEMORIA_KIB * 1024L)));
    }
}
