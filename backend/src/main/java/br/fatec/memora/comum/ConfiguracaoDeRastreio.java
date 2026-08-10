package br.fatec.memora.comum;

import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * A chave que resume o endereço de origem na trilha de auditoria (T026).
 *
 * <h2>Por que isto é um segredo, e não uma configuração qualquer</h2>
 *
 * O {@link FiltroRastreio} usa HMAC em vez de resumo simples porque o espaço de
 * endereços IPv4 inteiro cabe em força bruta: com SHA-256 puro, quem obtivesse
 * uma cópia do banco reverteria a coluna toda e saberia de onde cada pessoa
 * acessou. <b>Toda essa proteção é a chave.</b> Com uma chave conhecida, o HMAC
 * vale exatamente o mesmo que o resumo sem chave que ele veio substituir.
 *
 * <h2>Por isso não existe valor padrão no repositório</h2>
 *
 * Um padrão em {@code application.properties} seria um segredo commitado — o
 * que a Constituição proíbe, e o pior tipo, porque funciona: nada falha, nada
 * avisa, e quem esquecer de configurar em produção fica com a trilha inteira
 * reversível por qualquer pessoa que leia este repositório.
 *
 * <p>A saída é a mesma que a {@code ConfiguracaoDeToken} já adotou para o
 * segredo do token: <b>sem configuração, a chave é sorteada na subida</b>, com
 * WARN. Desenvolvimento funciona sem configurar nada, e a consequência de não
 * configurar em produção passa a ser visível.
 *
 * <h2>O preço do sorteio, dito por extenso</h2>
 *
 * Chave nova a cada reinício significa que os resumos gravados antes deixam de
 * casar com os novos, e a contagem por origem do {@code LimitadorTentativas}
 * (R4) recomeça do zero. É uma perda real — e ainda assim menor que a
 * alternativa: continuidade de contagem entre reinícios não vale entregar de
 * bandeja o endereço de origem de todo mundo. Em produção, configure
 * {@code MEMORA_CHAVE_ORIGEM} e nenhuma das duas coisas acontece.
 */
@Configuration
public class ConfiguracaoDeRastreio {

    private static final Logger LOG = LoggerFactory.getLogger(ConfiguracaoDeRastreio.class);

    /**
     * Mínimo em bytes para uma chave informada.
     *
     * <p>HMAC-SHA256 aceita chave de qualquer tamanho, mas chave curta é
     * adivinhável — e adivinhar a chave aqui é reverter a trilha inteira. 32
     * bytes é o tamanho do bloco do algoritmo e o mesmo piso que o segredo do
     * token já exige.
     */
    static final int TAMANHO_MINIMO_EM_BYTES = 32;

    private static final String ALGORITMO = "HmacSHA256";

    @Bean
    FiltroRastreio filtroRastreio(
            @Value("${memora.rastreio.chave-de-origem:}") String chaveConfigurada) {
        return new FiltroRastreio(chaveDe(chaveConfigurada));
    }

    /**
     * Monta a chave a partir do que foi configurado.
     *
     * <p>Diferente do segredo do token, o valor é lido como texto em UTF-8 e não
     * como base64: aqui não há formato exigido por padrão nenhum, e pedir base64
     * só acrescentaria um jeito a mais de errar na hora de configurar.
     *
     * @param chaveConfigurada a chave, ou vazio para sortear
     * @throws IllegalStateException se a chave existir mas for curta demais —
     *     falhar na subida é melhor do que resumir a trilha com chave fraca
     */
    static SecretKey chaveDe(String chaveConfigurada) {
        if (chaveConfigurada == null || chaveConfigurada.isBlank()) {
            LOG.warn(
                    "memora.rastreio.chave-de-origem nao configurada: chave sorteada nesta "
                            + "subida. A contagem por origem do limitador de tentativas (R4) "
                            + "recomeca a cada reinicio. Configure MEMORA_CHAVE_ORIGEM em "
                            + "producao.");
            return chaveSorteada();
        }

        byte[] bytes = chaveConfigurada.getBytes(StandardCharsets.UTF_8);
        if (bytes.length < TAMANHO_MINIMO_EM_BYTES) {
            throw new IllegalStateException(
                    "memora.rastreio.chave-de-origem tem %d bytes; o minimo e %d"
                            .formatted(bytes.length, TAMANHO_MINIMO_EM_BYTES));
        }

        return new SecretKeySpec(bytes, ALGORITMO);
    }

    private static SecretKey chaveSorteada() {
        byte[] bytes = new byte[TAMANHO_MINIMO_EM_BYTES];
        new SecureRandom().nextBytes(bytes);
        return new SecretKeySpec(bytes, ALGORITMO);
    }
}
