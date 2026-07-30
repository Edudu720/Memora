package br.fatec.memora.autenticacao.seguranca;

import com.nimbusds.jose.jwk.source.ImmutableSecret;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import javax.crypto.SecretKey;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;

/**
 * Emite e valida o token de acesso de 15 minutos (T018, R2).
 *
 * <h2>Por que este e autocontido e o refresh nao</h2>
 *
 * O token de acesso acompanha <b>toda</b> requisicao. Se fosse opaco, cada
 * chamada custaria uma consulta ao banco so para descobrir de quem e. Como ele
 * vale apenas 15 minutos, a janela em que um token roubado serve e curta o
 * suficiente para dispensar revogacao individual.
 *
 * <p>O refresh token e o contrario: vale 60 dias e precisa ser revogavel na
 * hora. Por isso ele e opaco e mora no banco — ver
 * {@link GeradorDeSegredoOpaco}.
 *
 * <h2>Os 15 minutos nao chegam ate a pessoa</h2>
 *
 * Token curto <b>nao</b> significa pedir senha a cada 15 minutos. O refresh
 * renova em silencio, e a pessoa idosa continua conectada enquanto usar o
 * aplicativo (FR-016). A expiracao que ela percebe conta <b>inatividade</b>
 * (FR-017), nao tempo absoluto.
 */
public class EmissorDeTokenDeAcesso {

    /** Curto de proposito: limita a janela de um token de acesso roubado. */
    public static final Duration VALIDADE = Duration.ofMinutes(15);

    private static final MacAlgorithm ALGORITMO = MacAlgorithm.HS256;

    private final NimbusJwtEncoder codificador;
    private final NimbusJwtDecoder decodificador;

    public EmissorDeTokenDeAcesso(SecretKey chave) {
        this.codificador = new NimbusJwtEncoder(new ImmutableSecret<>(chave));
        this.decodificador =
                NimbusJwtDecoder.withSecretKey(chave).macAlgorithm(ALGORITMO).build();
    }

    /**
     * Emite um token para a pessoa informada.
     *
     * @param agora instante de referencia; recebido em vez de lido do relogio
     *     para que o teste consiga produzir token ja vencido
     */
    public String emitir(UUID pessoaId, Instant agora) {
        JwtClaimsSet conteudo = JwtClaimsSet.builder()
                .subject(pessoaId.toString())
                .issuedAt(agora)
                .expiresAt(agora.plus(VALIDADE))
                .build();

        JwsHeader cabecalho = JwsHeader.with(ALGORITMO).build();

        return codificador.encode(JwtEncoderParameters.from(cabecalho, conteudo)).getTokenValue();
    }

    /**
     * Diz de quem e o token, se ele for valido.
     *
     * <p>Devolve {@link Optional#empty()} para token vencido, assinado com outra
     * chave, adulterado ou que nem seja um token. Nao distingue os casos de
     * proposito: para quem chama, "invalido e invalido" — e a resposta ao
     * cliente tambem precisa ser uma so, para nao virar oraculo.
     *
     * <p>E {@code Optional} e nao excecao porque quem chama nao consegue
     * esquecer de tratar.
     */
    public Optional<UUID> pessoaDoToken(String token) {
        try {
            Jwt decodificado = decodificador.decode(token);
            return Optional.of(UUID.fromString(decodificado.getSubject()));
        } catch (JwtException | IllegalArgumentException tokenRuim) {
            return Optional.empty();
        }
    }
}
