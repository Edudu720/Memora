package br.fatec.memora.assistente.infra;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import br.fatec.memora.suporte.ChaveDeTeste;
import br.fatec.memora.suporte.TesteComBanco;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;

/**
 * As protecoes do esquema da assistente recusam dado ruim (T011).
 *
 * <h2>O portao que este arquivo protege</h2>
 *
 * A FR-041 diz que a Memora nunca abre servico sensivel — banco, governo,
 * saude — nem com pedido e confirmacao. A migration V4 escreve isso como
 * restricao: servico SENSIVEL exige {@code identificador_android} nulo.
 *
 * <p>A consequencia e mais forte do que uma verificacao em Java: <b>servico
 * sensivel nao tem como ser aberto porque falta o dado necessario para
 * abri-lo</b>. Nao ha caminho de codigo que contorne a ausencia de um pacote.
 *
 * <p>Quem, no futuro, mudar a categoria de um banco para COTIDIANO vai ter que
 * preencher o pacote junto — e esse gesto e visivel na revisao. Uma verificacao
 * em codigo alguem remove sem querer; esta aqui o banco recusa.
 *
 * <h2>Por que SQL cru</h2>
 *
 * As fabricas de {@code ServicoConhecido} ja impedem a combinacao proibida em
 * tempo de compilacao. Passar por cima delas e o ponto: queremos a garantia que
 * sobrevive a um script de manutencao, a uma migration distraida e a um
 * mapeamento futuro que perca a regra.
 */
@DisplayName("Portoes do esquema da assistente")
class PortoesDoEsquemaDaAssistenteTest extends TesteComBanco {

    // Marcador e pacotes ficticios: "com.whatsapp" colidiria com o catalogo real
    // em ux_servico_pacote, e o marcador permite apagar so o que e nosso.
    private static final String MARCADOR = "Servico de teste";
    private static final String PACOTE_TESTE = "com.teste.portoes";

    @Autowired
    private JdbcTemplate jdbc;

    @AfterEach
    void limpar() {
        jdbc.execute("DELETE FROM evento_da_assistente");
        jdbc.execute("DELETE FROM uso_da_assistente");
        // So o que e deste teste. O catalogo real e semeado pelas migrations
        // V5/V6 e o container e um so para a suite: apagar a tabela inteira
        // deixaria CatalogoSemeadoTest (e qualquer outro) com o banco vazio.
        jdbc.update("DELETE FROM servico_conhecido WHERE nome_exibido = ?", MARCADOR);
        jdbc.execute("DELETE FROM pessoa_usuaria");
    }

    // -------------------------------------------------------------------------
    // A FR-041 escrita no banco
    // -------------------------------------------------------------------------

    @Test
    @DisplayName("servico sensivel COM pacote e recusado — e a FR-041 (banco nao abre)")
    void servicoSensivelComPacoteEhRecusado() {
        assertThatThrownBy(() -> inserirServico("SENSIVEL", "br.gov.meuinss"))
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("ck_servico_sensivel_nao_abre");
    }

    @Test
    @DisplayName("servico cotidiano SEM pacote e recusado — nao haveria o que abrir")
    void servicoCotidianoSemPacoteEhRecusado() {
        assertThatThrownBy(() -> inserirServico("COTIDIANO", null))
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("ck_servico_sensivel_nao_abre");
    }

    @Test
    @DisplayName("as duas combinacoes coerentes sao aceitas")
    void combinacoesCoerentesSaoAceitas() {
        assertThatCode(
                        () -> {
                            inserirServico("SENSIVEL", null);
                            inserirServico("COTIDIANO", PACOTE_TESTE);
                        })
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("categoria fora do enum e recusada")
    void categoriaInvalidaEhRecusada() {
        assertThatThrownBy(() -> inserirServico("QUASE_SENSIVEL", null))
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("ck_servico_categoria");
    }

    @Test
    @DisplayName("dois servicos ativos nao disputam o mesmo pacote")
    void pacoteEhUnicoEntreAtivos() {
        inserirServico("COTIDIANO", "com.teste.unico");

        assertThatThrownBy(() -> inserirServico("COTIDIANO", "com.teste.unico"))
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("ux_servico_pacote");
    }

    // -------------------------------------------------------------------------
    // A trilha nao se reescreve
    // -------------------------------------------------------------------------

    @Test
    @DisplayName("a trilha da assistente recusa UPDATE, mesmo por SQL direto (FR-020)")
    void trilhaNaoSeReescreve() {
        UUID id = inserirEvento("ACAO_RECUSADA");

        assertThatThrownBy(() -> jdbc.update(
                        "UPDATE evento_da_assistente SET tipo = 'ACAO_EXECUTADA' WHERE id = ?",
                        id))
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("somente insercao");

        assertThat(jdbc.queryForObject(
                        "SELECT tipo FROM evento_da_assistente WHERE id = ?", String.class, id))
                .isEqualTo("ACAO_RECUSADA");
    }

    @Test
    @DisplayName("a trilha admite DELETE, porque a retencao exige expurgo")
    void expurgoContinuaPossivel() {
        UUID id = inserirEvento("ACAO_EXECUTADA");

        assertThatCode(() -> jdbc.update("DELETE FROM evento_da_assistente WHERE id = ?", id))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("tipo de evento fora do enum e recusado")
    void tipoDeEventoInvalidoEhRecusado() {
        assertThatThrownBy(() -> inserirEvento("ACAO_QUASE_EXECUTADA"))
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("ck_evento_assistente_tipo");
    }

    @Test
    @DisplayName("o resumo do pedido nao passa de 120 caracteres")
    void resumoLongoEhRecusadoPeloBanco() {
        UUID pessoaId = inserirPessoa();

        assertThatThrownBy(() -> jdbc.update(
                        """
                        INSERT INTO evento_da_assistente
                            (id, pessoa_id, tipo, pedido_resumido, ocorrido_em)
                        VALUES (?, ?, 'ACAO_EXECUTADA', ?, now())
                        """,
                        UUID.randomUUID(),
                        pessoaId,
                        "x".repeat(121)))
                .isInstanceOf(DataAccessException.class);
    }

    // -------------------------------------------------------------------------
    // Contador diario
    // -------------------------------------------------------------------------

    @Test
    @DisplayName("contador de conversas negativo e recusado")
    void conversasNegativasSaoRecusadas() {
        UUID pessoaId = inserirPessoa();

        assertThatThrownBy(() -> jdbc.update(
                        """
                        INSERT INTO uso_da_assistente (pessoa_id, dia, conversas)
                        VALUES (?, current_date, -1)
                        """,
                        pessoaId))
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("ck_uso_conversas_positivo");
    }

    // -------------------------------------------------------------------------

    private void inserirServico(String categoria, String pacote) {
        jdbc.update(
                """
                INSERT INTO servico_conhecido
                    (id, chave, nome_exibido, categoria, identificador_android,
                     descricao_curta, ativo, criado_em, atualizado_em)
                VALUES (?, ?, ?, ?, ?, 'descricao', TRUE, now(), now())
                """,
                UUID.randomUUID(),
                ChaveDeTeste.nova(),
                MARCADOR,
                categoria,
                pacote);
    }

    private UUID inserirEvento(String tipo) {
        UUID id = UUID.randomUUID();
        jdbc.update(
                """
                INSERT INTO evento_da_assistente
                    (id, pessoa_id, tipo, ocorrido_em)
                VALUES (?, ?, ?, now())
                """,
                id,
                inserirPessoa(),
                tipo);
        return id;
    }

    private UUID inserirPessoa() {
        UUID id = UUID.randomUUID();
        jdbc.update(
                """
                INSERT INTO pessoa_usuaria
                    (id, nome_tratamento, estado, criada_em, falhas_consecutivas)
                VALUES (?, 'Ana', 'ATIVA', now(), 0)
                """,
                id);
        return id;
    }
}
