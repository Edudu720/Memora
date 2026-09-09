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
     * Nome do campo que diz de qual sessao o token nasceu.
     *
     * <p>Curto de proposito: cada requisicao carrega o token inteiro, e nome de
     * campo tambem ocupa bytes.
     */
    public static final String CAMPO_FAMILIA = "fam";

    /**
     * Quem o token diz ser, e de qual sessao ele veio.
     *
     * <p><b>Nada aqui e autorizacao.</b> O token pode estar perfeitamente
     * assinado e apontar para conta que nao existe — ver a sessao-chamariz em
     * {@code ServicoDeCadastro}. Quem resolve isso e o
     * {@link FiltroDeTokenDeAcesso}, consultando o banco.
     *
     * @param familiaId a linhagem de sessao; {@code null} em token emitido antes
     *     de este campo existir, e por isso quem usa precisa tratar a ausencia
     */
    public record SujeitoDoToken(UUID pessoaId, UUID familiaId) {}

    /**
     * Emite um token para a pessoa informada.
     *
     * <h2>Por que o token carrega a familia da sessao (T074)</h2>
     *
     * Sem isto, {@code POST /v1/auth/sair} nao teria como saber <b>o que</b>
     * encerrar: o {@code sub} identifica a pessoa, e uma pessoa tem varias
     * sessoes. As alternativas eram piores — pedir o refresh token no corpo
     * mudaria o contrato e faria o aplicativo enviar o segredo de 60 dias numa
     * operacao que nao precisa dele; revogar todas as sessoes transformaria
     * "sair deste aparelho" em "derrubar todos os meus aparelhos", que e outra
     * funcionalidade e nao a que a FR-024 pede.
     *
     * <p>E a <b>familia</b>, e nao a linha da sessao, porque a renovacao cria
     * uma linha nova a cada rotacao. A familia e o que atravessa as rotacoes e
     * representa "este aparelho, desde que entrou".
     *
     * @param agora instante de referencia; recebido em vez de lido do relogio
     *     para que o teste consiga produzir token ja vencido
     */
    public String emitir(UUID pessoaId, UUID familiaId, Instant agora) {
        JwtClaimsSet conteudo = JwtClaimsSet.builder()
                .subject(pessoaId.toString())
                .claim(CAMPO_FAMILIA, familiaId.toString())
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
        return sujeitoDoToken(token).map(SujeitoDoToken::pessoaId);
    }

    /**
     * Quem e o token e de qual sessao ele veio, se ele for valido.
     *
     * <p>A familia vem como {@code null} quando o campo nao esta presente. Isso
     * acontece com token emitido antes da T074 e ainda dentro dos 15 minutos de
     * validade — a alternativa, recusar o token, deslogaria todo mundo no
     * momento da implantacao sem ganho nenhum de seguranca.
     */
    public Optional<SujeitoDoToken> sujeitoDoToken(String token) {
        try {
            Jwt decodificado = decodificador.decode(token);
            return Optional.of(
                    new SujeitoDoToken(
                            UUID.fromString(decodificado.getSubject()),
                            familiaDe(decodificado)));
        } catch (JwtException | IllegalArgumentException tokenRuim) {
            return Optional.empty();
        }
    }

    /** A familia do token, ou {@code null} — inclusive se vier escrita torta. */
    private static UUID familiaDe(Jwt decodificado) {
        String bruto = decodificado.getClaimAsString(CAMPO_FAMILIA);
        if (bruto == null) {
            return null;
        }
        try {
            return UUID.fromString(bruto);
        } catch (IllegalArgumentException naoEhUuid) {
            // Campo presente e ilegivel nao invalida o token: ele foi assinado
            // por nos, e quem usa a familia ja precisa tratar a ausencia.
            return null;
        }
    }
}
