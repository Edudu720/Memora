package br.fatec.memora.assistente;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import br.fatec.memora.assistente.dominio.CategoriaDoServico;
import br.fatec.memora.assistente.dominio.ServicoConhecido;
import br.fatec.memora.assistente.infra.RepositorioServicoConhecido;
import br.fatec.memora.suporte.TesteComBanco;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;

/**
 * Os serviços sociais da V10 respeitam a regra de serviço sensível (T083, US5).
 *
 * Todas as novas linhas da V10 entram como SENSIVEL e sem identificador Android:
 * a Memora ensina o caminho oficial por passo a passo ilustrado no aplicativo,
 * mas nunca abre nenhum desses serviços (FR-041).
 */
@DisplayName("Os serviços sociais da V10")
class ServicosSociaisTest extends TesteComBanco {

    private static final String MARCADOR = "Serviço social de teste";

    private static final Map<String, String> SERVICOS_V10 =
            Map.of(
                    "e-titulo", "e-Título",
                    "serasa", "Serasa",
                    "fgts", "FGTS",
                    "poupatempo", "Poupatempo",
                    "carteira-digital", "Carteira Digital",
                    "correios", "Correios",
                    "carteira-de-trabalho", "Carteira de Trabalho Digital");

    @Autowired private RepositorioServicoConhecido servicos;

    @Autowired private JdbcTemplate jdbc;

    @AfterEach
    void limpar() {
        // Apaga apenas o que este teste criou, preservando o catálogo semeado.
        jdbc.update("DELETE FROM servico_conhecido WHERE nome_exibido = ?", MARCADOR);
    }

    @Test
    @DisplayName("todos os serviços sociais da V10 estão presentes e nenhum pode ser aberto")
    void todosOsServicosSociaisEstaoPresentesESaoSensiveis() {
        List<ServicoConhecido> sensiveis =
                servicos.findByCategoriaAndAtivoTrueOrderByNomeExibido(
                        CategoriaDoServico.SENSIVEL);

        List<String> chavesEncontradas =
                sensiveis.stream().map(ServicoConhecido::getChave).toList();

        for (Map.Entry<String, String> entry : SERVICOS_V10.entrySet()) {
            assertThat(chavesEncontradas)
                    .as("Chave %s (%s) ausente nos sensíveis", entry.getKey(), entry.getValue())
                    .contains(entry.getKey());
        }

        for (ServicoConhecido s : sensiveis) {
            if (SERVICOS_V10.containsKey(s.getChave())) {
                assertThat(s.podeSerAberto())
                        .as("%s (%s) não deveria poder ser aberto", s.getNomeExibido(), s.getChave())
                        .isFalse();
                assertThat(s.getIdentificadorAndroid())
                        .as("%s (%s) tem pacote gravado", s.getNomeExibido(), s.getChave())
                        .isEmpty();
            }
        }
    }

    @Test
    @DisplayName("inserir um serviço sensível com pacote é recusado por ck_servico_sensivel_nao_abre")
    void inserirSensivelComPacoteEhRecusadoPeloBanco() {
        assertThatThrownBy(
                        () ->
                                jdbc.update(
                                        """
                                        INSERT INTO servico_conhecido
                                            (id, chave, nome_exibido, categoria, identificador_android,
                                             descricao_curta, ativo, criado_em, atualizado_em)
                                        VALUES
                                            (?, 'teste-sensivel', ?, 'SENSIVEL', 'br.gov.sp.poupatempo',
                                             'Tentativa indevida de associar pacote a serviço sensível',
                                             TRUE, now(), now())
                                        """,
                                        UUID.randomUUID(),
                                        MARCADOR))
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("ck_servico_sensivel_nao_abre");
    }
}

