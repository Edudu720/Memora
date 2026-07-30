package br.fatec.memora.autenticacao.seguranca;

import java.security.SecureRandom;
import java.util.Base64;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * A chave que assina o token de acesso (T018).
 *
 * <h2>Nenhum segredo escrito no código</h2>
 *
 * A Constituição proíbe secret no repositório. Um valor padrão em
 * {@code application.properties} seria exatamente isso — e o pior tipo, porque
 * quem esquecesse de trocar em produção teria tokens assináveis por qualquer
 * pessoa que lesse o repositório.
 *
 * <p>Por isso: se {@code memora.token.segredo} não estiver configurado, a chave
 * é <b>sorteada na subida</b>. Desenvolvimento funciona sem configurar nada, e a
 * consequência de não configurar em produção é visível em vez de silenciosa —
 * toda sessão morre a cada implantação, porque a chave mudou.
 */
@Configuration
public class ConfiguracaoDeToken {

    private static final Logger LOG = LoggerFactory.getLogger(ConfiguracaoDeToken.class);

    /** HS256 exige chave de pelo menos 256 bits. */
    private static final int TAMANHO_MINIMO_EM_BYTES = 32;

    private static final String ALGORITMO = "HmacSHA256";

    @Bean
    EmissorDeTokenDeAcesso emissorDeTokenDeAcesso(
            @Value("${memora.token.segredo:}") String segredoConfigurado) {
        return new EmissorDeTokenDeAcesso(chaveDe(segredoConfigurado));
    }

    /**
     * Monta a chave a partir do segredo configurado.
     *
     * @param segredoConfigurado segredo em base64, ou vazio para sortear
     * @throws IllegalStateException se o segredo existir mas não servir — falhar
     *     na subida é melhor do que rodar com chave fraca
     */
    static SecretKey chaveDe(String segredoConfigurado) {
        if (segredoConfigurado == null || segredoConfigurado.isBlank()) {
            LOG.warn(
                    "memora.token.segredo nao configurado: chave sorteada nesta subida. "
                            + "Toda sessao existente deixa de valer a cada reinicio. "
                            + "Configure a variavel em producao.");
            return chaveSorteada();
        }

        byte[] bytes;
        try {
            bytes = Base64.getDecoder().decode(segredoConfigurado.trim());
        } catch (IllegalArgumentException naoEhBase64) {
            throw new IllegalStateException(
                    "memora.token.segredo precisa estar em base64", naoEhBase64);
        }

        if (bytes.length < TAMANHO_MINIMO_EM_BYTES) {
            throw new IllegalStateException(
                    "memora.token.segredo tem %d bits; HS256 exige no minimo 256 bits"
                            .formatted(bytes.length * 8));
        }

        return new SecretKeySpec(bytes, ALGORITMO);
    }

    private static SecretKey chaveSorteada() {
        byte[] bytes = new byte[TAMANHO_MINIMO_EM_BYTES];
        new SecureRandom().nextBytes(bytes);
        return new SecretKeySpec(bytes, ALGORITMO);
    }
}
