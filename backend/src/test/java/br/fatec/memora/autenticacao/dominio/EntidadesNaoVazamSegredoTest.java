package br.fatec.memora.autenticacao.dominio;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Nenhuma entidade imprime segredo em {@code toString} (FR-040).
 *
 * <h2>Por que isto merece teste</h2>
 *
 * O caminho mais comum para vazar credencial em log nao e alguem escrever
 * {@code log.info(senha)}. E um {@code toString} gerado pela IDE ou por Lombok
 * cair dentro de uma mensagem de excecao — e a partir dali o hash da senha, o
 * refresh token e o e-mail da pessoa passam a viver no arquivo de log, fora de
 * qualquer classificacao de sensibilidade.
 *
 * <p>Estes testes falham se alguem, no futuro, trocar os {@code toString}
 * escritos a mao por um gerado automaticamente.
 */
@DisplayName("Entidades nao vazam segredo em toString")
class EntidadesNaoVazamSegredoTest {

    private static final Instant AGORA = Instant.now();

    @Test
    @DisplayName("PessoaUsuaria nao imprime o hash da senha")
    void pessoaNaoImprimeSenha() {
        String segredo = "$argon2id$v=19$m=65536,t=4,p=1$SEGREDO";
        PessoaUsuaria pessoa = new PessoaUsuaria("Ana", segredo, AGORA);

        assertThat(pessoa.toString()).doesNotContain(segredo, "SEGREDO", "argon2");
        assertThat(pessoa.toString()).contains(pessoa.getId().toString());
    }

    @Test
    @DisplayName("CanalContato nao imprime o e-mail nem o hash dele")
    void canalNaoImprimeValor() {
        CanalContato canal = new CanalContato(
                UUID.randomUUID(),
                TipoDeCanal.EMAIL,
                "ana.silva@exemplo.com",
                "hash-confidencial",
                true,
                AGORA);

        assertThat(canal.toString())
                .doesNotContain("ana.silva@exemplo.com", "hash-confidencial");
        assertThat(canal.toString()).contains("EMAIL");
    }

    @Test
    @DisplayName("Sessao nao imprime o hash do refresh token")
    void sessaoNaoImprimeToken() {
        Sessao sessao = Sessao.iniciarFamilia(
                UUID.randomUUID(),
                "hash-do-refresh-token",
                "Pixel 6",
                AGORA,
                AGORA.plus(Duration.ofDays(60)));

        assertThat(sessao.toString()).doesNotContain("hash-do-refresh-token");
        assertThat(sessao.toString()).contains(sessao.getFamiliaId().toString());
    }

    @Test
    @DisplayName("CodigoVerificacao nao imprime o hash do codigo")
    void codigoNaoImprimeHash() {
        CodigoVerificacao codigo = new CodigoVerificacao(
                UUID.randomUUID(),
                FinalidadeDoCodigo.RECUPERACAO_ACESSO,
                "hash-do-codigo-de-6-digitos",
                AGORA,
                AGORA.plus(Duration.ofMinutes(10)));

        assertThat(codigo.toString()).doesNotContain("hash-do-codigo-de-6-digitos");
        assertThat(codigo.toString()).contains("RECUPERACAO_ACESSO");
    }

    @Test
    @DisplayName("EventoAutenticacao nao imprime a origem hasheada")
    void eventoNaoImprimeOrigem() {
        EventoAutenticacao evento = EventoAutenticacao.semConta(
                TipoDeEvento.FALHA_ENTRADA,
                ResultadoDoEvento.FALHA,
                "hash-do-endereco-de-rede",
                AGORA);

        assertThat(evento.toString()).doesNotContain("hash-do-endereco-de-rede");
        assertThat(evento.toString()).contains("FALHA_ENTRADA");
    }
}
