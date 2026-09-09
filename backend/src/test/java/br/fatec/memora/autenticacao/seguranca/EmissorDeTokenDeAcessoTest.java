package br.fatec.memora.autenticacao.seguranca;

import static org.assertj.core.api.Assertions.assertThat;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/** Emissao e validacao do token de acesso de 15 minutos (T018, R2). */
@DisplayName("Emissor de token de acesso")
class EmissorDeTokenDeAcessoTest {

    private final EmissorDeTokenDeAcesso emissor = new EmissorDeTokenDeAcesso(chaveAleatoria());

    @Test
    @DisplayName("o token identifica de quem e a sessao")
    void tokenCarregaAPessoa() {
        UUID pessoaId = UUID.randomUUID();

        String token = emissor.emitir(pessoaId, UUID.randomUUID(), Instant.now());

        assertThat(emissor.pessoaDoToken(token)).contains(pessoaId);
    }

    /**
     * Sem este campo, {@code POST /v1/auth/sair} nao teria o que encerrar: o
     * {@code sub} diz quem e a pessoa, e uma pessoa tem varias sessoes (T074).
     */
    @Test
    @DisplayName("o token diz de qual sessao ele veio")
    void tokenCarregaAFamilia() {
        UUID pessoaId = UUID.randomUUID();
        UUID familiaId = UUID.randomUUID();

        String token = emissor.emitir(pessoaId, familiaId, Instant.now());

        assertThat(emissor.sujeitoDoToken(token))
                .contains(new EmissorDeTokenDeAcesso.SujeitoDoToken(pessoaId, familiaId));
    }

    @Test
    @DisplayName("vale 15 minutos, como o contrato promete (R2)")
    void validadeDeQuinzeMinutos() {
        assertThat(EmissorDeTokenDeAcesso.VALIDADE).isEqualTo(Duration.ofMinutes(15));
        assertThat(EmissorDeTokenDeAcesso.VALIDADE.toSeconds()).isEqualTo(900);
    }

    @Test
    @DisplayName("token vencido e recusado")
    void tokenVencidoEhRecusado() {
        String vencido = emissor.emitir(
                UUID.randomUUID(),
                UUID.randomUUID(),
                Instant.now().minus(Duration.ofMinutes(30)));

        assertThat(emissor.pessoaDoToken(vencido)).isEmpty();
    }

    @Test
    @DisplayName("token assinado com outra chave e recusado")
    void tokenDeOutraChaveEhRecusado() {
        String forjado =
                new EmissorDeTokenDeAcesso(chaveAleatoria())
                        .emitir(UUID.randomUUID(), UUID.randomUUID(), Instant.now());

        assertThat(emissor.pessoaDoToken(forjado)).isEmpty();
    }

    @Test
    @DisplayName("token com o conteudo alterado e recusado")
    void tokenAlteradoEhRecusado() {
        String token = emissor.emitir(UUID.randomUUID(), UUID.randomUUID(), Instant.now());
        String[] partes = token.split("\\.");
        // Troca um caractere do conteudo, preservando a assinatura original.
        String conteudoAlterado = (partes[1].charAt(0) == 'a' ? "b" : "a") + partes[1].substring(1);
        String adulterado = partes[0] + "." + conteudoAlterado + "." + partes[2];

        assertThat(emissor.pessoaDoToken(adulterado)).isEmpty();
    }

    @Test
    @DisplayName("texto que nem e um token e recusado sem explodir")
    void lixoEhRecusado() {
        assertThat(emissor.pessoaDoToken("isto-nao-e-um-token")).isEmpty();
        assertThat(emissor.pessoaDoToken("")).isEmpty();
    }

    private static SecretKey chaveAleatoria() {
        byte[] bytes = new byte[32];
        new SecureRandom().nextBytes(bytes);
        return new SecretKeySpec(bytes, "HmacSHA256");
    }
}
