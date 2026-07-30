package br.fatec.memora.autenticacao.infra;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import br.fatec.memora.suporte.TesteComBanco;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;

/**
 * As protecoes do esquema recusam dado ruim (T008).
 *
 * <h2>Por que este arquivo existe</h2>
 *
 * Teste que passa nao prova que o portao funciona. Escrever um gatilho e uma
 * restricao CHECK e facil; o que interessa e saber que eles <b>reprovam</b> o que
 * deveriam reprovar. Cada teste aqui tenta gravar exatamente o que a protecao
 * proibe e exige que o banco recuse.
 *
 * <h2>Por que SQL cru em vez dos repositorios</h2>
 *
 * A entidade {@code EventoAutenticacao} e {@code @Immutable}, entao o Hibernate
 * nunca emitiria o UPDATE que precisamos testar. Passar por cima dele e o ponto:
 * queremos a garantia que sobrevive a um cliente SQL avulso, a um script de
 * manutencao ou a um mapeamento futuro que esqueca o {@code @Immutable}.
 */
@DisplayName("Portoes do esquema")
class PortoesDoEsquemaTest extends TesteComBanco {

    @Autowired
    private JdbcTemplate jdbc;

    @AfterEach
    void limpar() {
        jdbc.execute("DELETE FROM codigo_verificacao");
        jdbc.execute("DELETE FROM canal_contato");
        jdbc.execute("DELETE FROM sessao");
        jdbc.execute("DELETE FROM evento_autenticacao");
        jdbc.execute("DELETE FROM pessoa_usuaria");
    }

    @Test
    @DisplayName("a trilha de auditoria recusa UPDATE, mesmo por SQL direto (FR-039)")
    void trilhaNaoSeReescreve() {
        UUID id = inserirEvento();

        assertThatThrownBy(() -> jdbc.update(
                        "UPDATE evento_autenticacao SET resultado = 'SUCESSO' WHERE id = ?", id))
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("somente insercao");

        assertThat(jdbc.queryForObject(
                        "SELECT resultado FROM evento_autenticacao WHERE id = ?", String.class, id))
                .isEqualTo("FALHA");
    }

    @Test
    @DisplayName("a trilha admite DELETE, porque a retencao de 12 meses exige expurgo")
    void expurgoContinuaPossivel() {
        UUID id = inserirEvento();

        assertThatCode(() -> jdbc.update("DELETE FROM evento_autenticacao WHERE id = ?", id))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("estado de conta fora do enum e recusado")
    void estadoInvalidoEhRecusado() {
        assertThatThrownBy(() -> jdbc.update(
                        """
                        INSERT INTO pessoa_usuaria
                            (id, nome_tratamento, estado, criada_em, falhas_consecutivas)
                        VALUES (?, 'Ana', 'ESTADO_INVENTADO', now(), 0)
                        """,
                        UUID.randomUUID()))
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("ck_pessoa_estado");
    }

    @Test
    @DisplayName("contador de falhas negativo e recusado")
    void falhasNegativasSaoRecusadas() {
        assertThatThrownBy(() -> jdbc.update(
                        """
                        INSERT INTO pessoa_usuaria
                            (id, nome_tratamento, estado, criada_em, falhas_consecutivas)
                        VALUES (?, 'Ana', 'ATIVA', now(), -1)
                        """,
                        UUID.randomUUID()))
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("ck_pessoa_falhas_nao_negativas");
    }

    @Test
    @DisplayName("canal verificado sem data de verificacao e estado impossivel")
    void verificacaoIncoerenteEhRecusada() {
        UUID pessoaId = inserirPessoa();

        assertThatThrownBy(() -> jdbc.update(
                        """
                        INSERT INTO canal_contato
                            (id, pessoa_id, tipo, valor, valor_hash, verificado,
                             verificado_em, principal, criado_em)
                        VALUES (?, ?, 'EMAIL', 'ana@exemplo.com', 'hash', TRUE,
                                NULL, TRUE, now())
                        """,
                        UUID.randomUUID(),
                        pessoaId))
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("ck_canal_verificacao_coerente");
    }

    @Test
    @DisplayName("sessao que expira antes de existir e recusada")
    void validadeIncoerenteEhRecusada() {
        UUID pessoaId = inserirPessoa();
        UUID sessaoId = UUID.randomUUID();

        assertThatThrownBy(() -> jdbc.update(
                        """
                        INSERT INTO sessao
                            (id, pessoa_id, familia_id, refresh_token_hash,
                             criada_em, expira_em)
                        VALUES (?, ?, ?, 'hash', now(), now() - interval '1 day')
                        """,
                        sessaoId,
                        pessoaId,
                        sessaoId))
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("ck_sessao_expira_depois_de_criar");
    }

    @Test
    @DisplayName("tipo de evento fora do enum e recusado")
    void tipoDeEventoInvalidoEhRecusado() {
        assertThatThrownBy(() -> jdbc.update(
                        """
                        INSERT INTO evento_autenticacao
                            (id, tipo, resultado, ocorrido_em)
                        VALUES (?, 'TIPO_INVENTADO', 'FALHA', now())
                        """,
                        UUID.randomUUID()))
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("ck_evento_tipo");
    }

    @Test
    @DisplayName("a contagem por origem tem indice — senao o limitador varre a trilha inteira")
    void indiceDaContagemPorOrigem() {
        // O LimitadorTentativas conta falhas por origem a cada tentativa de
        // entrada. Sem indice, essa contagem percorre a tabela que mais cresce
        // no sistema, e o caminho de login degrada junto com o volume de
        // auditoria.
        assertThat(jdbc.queryForObject(
                        """
                        SELECT count(*) FROM pg_indexes
                         WHERE schemaname = 'public'
                           AND indexname = 'ix_evento_origem_ocorrido'
                        """,
                        Integer.class))
                .isEqualTo(1);
    }

    @Test
    @DisplayName("o Flyway aplicou a migration inicial")
    void migrationRegistrada() {
        assertThat(jdbc.queryForObject(
                        """
                        SELECT success FROM flyway_schema_history
                         WHERE version = '1'
                        """,
                        Boolean.class))
                .isTrue();
    }

    /**
     * O driver do PostgreSQL nao infere tipo SQL para {@code Instant} em consulta
     * crua — {@code OffsetDateTime} e o tipo que casa com TIMESTAMPTZ. Pelo
     * Hibernate isso nao aparece, porque ele declara o tipo explicitamente; aqui
     * estamos falando JDBC direto.
     */
    private static OffsetDateTime agora() {
        return OffsetDateTime.now(ZoneOffset.UTC);
    }

    private UUID inserirPessoa() {
        UUID id = UUID.randomUUID();
        jdbc.update(
                """
                INSERT INTO pessoa_usuaria
                    (id, nome_tratamento, estado, criada_em, falhas_consecutivas)
                VALUES (?, 'Ana', 'ATIVA', ?, 0)
                """,
                id,
                agora());
        return id;
    }

    private UUID inserirEvento() {
        UUID id = UUID.randomUUID();
        jdbc.update(
                """
                INSERT INTO evento_autenticacao
                    (id, tipo, resultado, origem_hash, ocorrido_em)
                VALUES (?, 'FALHA_ENTRADA', 'FALHA', 'hash-origem', ?)
                """,
                id,
                agora());
        return id;
    }
}
