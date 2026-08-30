package br.fatec.memora.assistente;

import static org.assertj.core.api.Assertions.assertThat;

import br.fatec.memora.assistente.aplicacao.ServicoDeConversa;
import br.fatec.memora.assistente.dominio.ServicoConhecido;
import br.fatec.memora.assistente.infra.ClienteDaAssistente;
import br.fatec.memora.assistente.infra.ClienteDaAssistenteSimulado;
import br.fatec.memora.assistente.infra.RepositorioServicoConhecido;
import br.fatec.memora.suporte.TesteComBanco;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

/**
 * Cenario H6 — a conversa nao existe no servidor (T042).
 *
 * <h2>Por que este teste varre o banco inteiro</h2>
 *
 * A decisao D3 recusou guardar conversa no servidor, e a razao e o que isso
 * criaria: um acervo Confidencial sobre a intimidade de pessoas idosas, que sao
 * o alvo preferencial de golpe no Brasil.
 *
 * <p>Verificar so a tabela da trilha nao bastaria. O jeito mais provavel de
 * quebrar a FR-047 no futuro nao e alguem gravar em {@code evento_da_assistente}
 * de proposito — e alguem criar uma tabela nova "so para o historico", ou
 * esquecer de truncar o {@code pedido_resumido}. Por isso o teste procura o
 * texto em <b>todas</b> as colunas de texto do banco.
 */
@DisplayName("H6 — a conversa nao existe no servidor")
class ConversaNaoPersisteTest extends TesteComBanco {

    /**
     * Frases marcadas, que so poderiam chegar ao banco vindas da conversa.
     *
     * <p>Sao propositalmente estranhas: uma busca por "ola" acharia qualquer
     * coisa, e um teste que passa por acaso nao protege nada.
     */
    private static final String SEGREDO_DA_PESSOA =
            "meu neto chama xilofonezinho e mora em pindamonhangaba";

    private static final String SEGREDO_DA_MEMORA =
            "vamos procurar o quadradinho zarabatana na sua tela";

    @Autowired
    private ServicoDeConversa conversa;

    @Autowired
    private ClienteDaAssistenteSimulado assistente;

    @Autowired
    private RepositorioServicoConhecido servicos;

    @Autowired
    private JdbcTemplate jdbc;

    private UUID pessoaId;

    @BeforeEach
    void preparar() {
        pessoaId = inserirPessoa();
        servicos.save(
                ServicoConhecido.cotidiano(
                        "WhatsApp", "com.whatsapp", "Mensagens", Instant.now()));
        assistente.limpar().responderCom(SEGREDO_DA_MEMORA);
    }

    @AfterEach
    void limpar() {
        jdbc.execute("DELETE FROM evento_da_assistente");
        jdbc.execute("DELETE FROM uso_da_assistente");
        servicos.deleteAll();
        jdbc.execute("DELETE FROM pessoa_usuaria");
        assistente.limpar();
    }

    @Test
    @DisplayName("nem o que a pessoa disse nem o que a Memora respondeu ficam no banco")
    void nadaDaConversaFicaNoBanco() {
        conversa.conversar(pessoaId, SEGREDO_DA_PESSOA, List.of(), trecho -> {});

        assertThat(colunasQueContem(SEGREDO_DA_PESSOA))
                .as("o que a pessoa escreveu apareceu no banco")
                .isEmpty();
        assertThat(colunasQueContem(SEGREDO_DA_MEMORA))
                .as("o que a Memora respondeu apareceu no banco")
                .isEmpty();
    }

    @Test
    @DisplayName("o historico que viaja no pedido tambem nao fica")
    void historicoNaoFicaNoBanco() {
        conversa.conversar(
                pessoaId,
                "e agora?",
                List.of(
                        new ClienteDaAssistente.Turno(
                                ClienteDaAssistente.Turno.Autor.PESSOA, SEGREDO_DA_PESSOA)),
                trecho -> {});

        assertThat(colunasQueContem(SEGREDO_DA_PESSOA)).isEmpty();
    }

    @Test
    @DisplayName("a conversa e contada, ainda que o conteudo nao seja guardado")
    void aContagemAcontece() {
        // Sem este caso, um servico que nao fizesse absolutamente nada passaria
        // nos dois testes acima.
        conversa.conversar(pessoaId, SEGREDO_DA_PESSOA, List.of(), trecho -> {});

        Integer conversas =
                jdbc.queryForObject(
                        "SELECT conversas FROM uso_da_assistente WHERE pessoa_id = ?",
                        Integer.class,
                        pessoaId);
        assertThat(conversas).isEqualTo(1);

        Long eventos =
                jdbc.queryForObject(
                        "SELECT count(*) FROM evento_da_assistente WHERE pessoa_id = ?",
                        Long.class,
                        pessoaId);
        assertThat(eventos).isEqualTo(1L);
    }

    @Test
    @DisplayName("sugestao recusada vira trilha, mas o pedido entra truncado")
    void pedidoLongoEhTruncado() {
        String pedidoEnorme = SEGREDO_DA_PESSOA.repeat(10);
        assistente.sugerirAbrir("com.banco.aplicativo");

        conversa.conversar(pessoaId, pedidoEnorme, List.of(), trecho -> {});

        String gravado =
                jdbc.queryForObject(
                        """
                        SELECT pedido_resumido FROM evento_da_assistente
                        WHERE pessoa_id = ? AND tipo = 'ACAO_RECUSADA'
                        """,
                        String.class,
                        pessoaId);

        // O corte acontece no servidor. Confia-lo ao aparelho transformaria um
        // campo de tabela imutavel em texto livre de tamanho arbitrario.
        assertThat(gravado).hasSizeLessThanOrEqualTo(120);
    }

    /**
     * Procura um trecho em todas as colunas de texto do banco.
     *
     * <p>Le o catalogo do PostgreSQL em vez de listar as tabelas na mao: uma
     * lista escrita a mao nao conheceria a tabela que alguem criar amanha, e
     * essa e exatamente a tabela que este teste precisa pegar.
     */
    private List<String> colunasQueContem(String trecho) {
        List<String> achados = new ArrayList<>();

        List<java.util.Map<String, Object>> colunas =
                jdbc.queryForList(
                        """
                        SELECT table_name, column_name
                        FROM information_schema.columns
                        WHERE table_schema = 'public'
                          AND data_type IN ('text', 'character varying', 'character')
                          AND table_name <> 'flyway_schema_history'
                        """);

        for (java.util.Map<String, Object> coluna : colunas) {
            String tabela = (String) coluna.get("table_name");
            String campo = (String) coluna.get("column_name");

            Long quantos =
                    jdbc.queryForObject(
                            "SELECT count(*) FROM %s WHERE %s LIKE ?".formatted(tabela, campo),
                            Long.class,
                            "%" + trecho + "%");

            if (quantos != null && quantos > 0) {
                achados.add(tabela + "." + campo);
            }
        }
        return achados;
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
