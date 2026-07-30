package br.fatec.memora.autenticacao.seguranca;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.HexFormat;
import org.springframework.stereotype.Component;

/**
 * Gera e resume o refresh token opaco (T018).
 *
 * <h2>Por que o refresh token e opaco</h2>
 *
 * A decisao R2 recusou JWT como refresh justamente porque JWT nao e revogavel
 * sem lista de bloqueio. Um valor aleatorio sem significado proprio so vale
 * enquanto existir a linha correspondente no banco — revogar e apagar ou marcar
 * essa linha, e nada mais.
 *
 * <h2>Por que SHA-256 e nao Argon2</h2>
 *
 * O projeto usa Argon2id com 64 MiB e t=4 para senha, o que custa cerca de
 * 240 ms por hash. Isso e deliberado: senha e segredo de <b>baixa entropia</b>,
 * escolhido por pessoa, e a lentidao e o que torna a busca exaustiva caro.
 *
 * <p>Refresh token e o oposto: 256 bits sorteados por {@link SecureRandom}. Nao
 * existe dicionario nem busca exaustiva viavel contra ele, entao a lentidao nao
 * compraria seguranca nenhuma — apenas somaria 240 ms a cada abertura do
 * aplicativo, que e exatamente o caminho mais percorrido do produto.
 *
 * <p>O hash existe por outro motivo: quem obtiver uma copia do banco nao pode
 * sair usando as sessoes de todo mundo. Para isso, resumo rapido de valor
 * aleatorio basta.
 */
@Component
public class GeradorDeSegredoOpaco {

    /** 32 bytes = 256 bits de entropia. */
    private static final int TAMANHO_EM_BYTES = 32;

    private static final String ALGORITMO_DE_RESUMO = "SHA-256";

    private final SecureRandom aleatorio = new SecureRandom();
    private final Base64.Encoder codificador = Base64.getUrlEncoder().withoutPadding();

    /**
     * Sorteia um segredo novo.
     *
     * @return valor em base64url, seguro para viajar em JSON e em cabecalho
     */
    public String gerar() {
        byte[] bytes = new byte[TAMANHO_EM_BYTES];
        aleatorio.nextBytes(bytes);
        return codificador.encodeToString(bytes);
    }

    /**
     * Resume o segredo para guardar no banco.
     *
     * @return resumo em hexadecimal minusculo
     */
    public String hashDe(String segredo) {
        try {
            MessageDigest resumo = MessageDigest.getInstance(ALGORITMO_DE_RESUMO);
            byte[] digerido = resumo.digest(segredo.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digerido);
        } catch (NoSuchAlgorithmException impossivel) {
            // SHA-256 e obrigatorio em toda implementacao da plataforma Java.
            throw new IllegalStateException(ALGORITMO_DE_RESUMO + " indisponivel", impossivel);
        }
    }
}
