package br.fatec.memora.assistente;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import br.fatec.memora.suporte.TesteComBanco;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

/**
 * A {@code chave} do catálogo é obrigatória, única, de formato fixo — e chega
 * ao aplicativo (T031, feature 004).
 *
 * <h2>O que este arquivo protege</h2>
 *
 * A {@code chave} é o <b>elo entre o banco e os guias embarcados</b> no
 * aplicativo: o guia do WhatsApp é encontrado pelo texto {@code whatsapp}, e não
 * por um UUID que cada banco sorteia diferente. Três coisas precisam ser
 * verdade para esse elo valer:
 *
 * <ul>
 *   <li><b>Obrigatória</b> — item sem chave não encontraria guia nenhum e
 *       cairia, em silêncio, no caminho de "servidor mais novo que o
 *       aplicativo";
 *   <li><b>Única</b> — sem o {@code UNIQUE}, dois itens disputariam o mesmo
 *       guia, e a pessoa tocaria em "Instagram" e leria o passo a passo do
 *       "Facebook";
 *   <li><b>De formato fixo</b> — ASCII minúsculo, números e hífen. A chave é
 *       escrita à mão nas migrations e comparada, byte a byte, com a do guia;
 *       {@code WhatsApp} e {@code whatsapp} seriam duas chaves, e só uma delas
 *       acharia o guia.
 * </ul>
 *
 * <h2>Por que SQL cru</h2>
 *
 * Passa-se por cima da entidade de propósito: a garantia que importa é a que
 * sobrevive a uma migration distraída ou a um script de manutenção, e essa só o
 * banco dá. Cada recusa confere o <b>nome da restrição</b> na mensagem — uma
 * chave repetida que fosse recusada por outra razão (pacote repetido, por
 * exemplo) passaria num teste que só esperasse "alguma exceção".
 *
 * <h2>Só o que é nosso</h2>
 *
 * O catálogo semeado é de todo o container, e a suíte inteira o compartilha.
 * Cada teste apaga apenas o que criou (achado de 2026-10-01: um {@code DELETE}
 * global já derrubou o catálogo e o CI).
 */
@AutoConfigureMockMvc
@DisplayName("A chave do catálogo")
class ChaveDoCatalogoTest extends TesteComBanco {

    private static final String MARCADOR = "Serviço de teste da chave";

    private static final String EMAIL = "chave.catalogo@gmail.com";

    private static final String SENHA = "pipoca no varal azul";

    /** O que a V8 escreve, por nome — a verdade que o aplicativo espelha. */
    private static final Map<String, String> CHAVES_SEMEADAS =
            Map.of(
                    "WhatsApp", "whatsapp",
                    "Facebook", "facebook",
                    "Instagram", "instagram",
                    "YouTube", "youtube",
                    "Google Fotos", "google-fotos",
                    "Telegram", "telegram",
                    "Gov.br", "gov-br",
                    "Meu INSS", "meu-inss");

    @Autowired private JdbcTemplate jdbc;

    @Autowired private MockMvc mockMvc;

    @Autowired private ObjectMapper json;

    @AfterEach
    void limpar() {
        // Só o que é deste teste: as linhas de catálogo marcadas e a conta que o
        // teste do endpoint cadastrou. O catálogo real vem da V5, V6 e V8.
        jdbc.update("DELETE FROM servico_conhecido WHERE nome_exibido = ?", MARCADOR);

        List<UUID> pessoas =
                jdbc.queryForList(
                        "SELECT pessoa_id FROM canal_contato WHERE valor = ?", UUID.class, EMAIL);
        for (UUID pessoa : pessoas) {
            jdbc.update("DELETE FROM evento_autenticacao WHERE pessoa_id = ?", pessoa);
            // Canais, sessões e códigos saem junto, em cascata.
            jdbc.update("DELETE FROM pessoa_usuaria WHERE id = ?", pessoa);
        }
    }

    // -------------------------------------------------------------------------
    // O que a migration semeou
    // -------------------------------------------------------------------------

    @Test
    @DisplayName("as oito linhas semeadas têm cada uma a chave certa")
    void linhasSemeadasTemAChaveCerta() {
        Map<String, String> encontradas = new HashMap<>();
        jdbc.query(
                "SELECT nome_exibido, chave FROM servico_conhecido",
                resultado -> {
                    String nome = resultado.getString("nome_exibido");
                    if (CHAVES_SEMEADAS.containsKey(nome)) {
                        encontradas.put(nome, resultado.getString("chave"));
                    }
                });

        assertThat(encontradas).containsExactlyInAnyOrderEntriesOf(CHAVES_SEMEADAS);
    }

    // -------------------------------------------------------------------------
    // O banco recusa chave ruim
    // -------------------------------------------------------------------------

    @Test
    @DisplayName("serviço sem chave é recusado")
    void semChaveEhRecusado() {
        assertThatThrownBy(() -> inserir(null))
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("chave")
                .hasMessageContaining("not-null");
    }

    @Test
    @DisplayName("chave repetida é recusada pela unicidade — e só por ela")
    void chaveRepetidaEhRecusada() {
        // "whatsapp" já existe, semeada. Pacote único: se a recusa viesse do
        // ux_servico_pacote, o teste provaria a coisa errada.
        assertThatThrownBy(() -> inserir("whatsapp"))
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("ux_servico_chave");
    }

    @Test
    @DisplayName("duas linhas novas com a mesma chave também disputam a unicidade")
    void chaveRepetidaEntreLinhasNovas() {
        inserir("chave-de-teste-repetida");

        assertThatThrownBy(() -> inserir("chave-de-teste-repetida"))
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("ux_servico_chave");
    }

    @ParameterizedTest(name = "\"{0}\" é recusada pelo formato")
    @ValueSource(strings = {"WhatsApp2", "gov_br", "gov.br", "com espaco", "acentuação", ""})
    @DisplayName("maiúscula e caractere fora do formato são recusados")
    void formatoInvalidoEhRecusado(String chave) {
        assertThatThrownBy(() -> inserir(chave))
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("ck_servico_chave_formato");
    }

    @Test
    @DisplayName("chave com mais de 40 caracteres é recusada")
    void chaveLongaEhRecusada() {
        assertThatThrownBy(() -> inserir("a".repeat(41)))
                .isInstanceOf(DataAccessException.class)
                .hasMessageContaining("character varying(40)");
    }

    @Test
    @DisplayName("chave no formato é aceita")
    void chaveValidaEhAceita() {
        assertThatCode(() -> inserir("chave-valida-123")).doesNotThrowAnyException();
    }

    // -------------------------------------------------------------------------
    // O que chega ao aplicativo
    // -------------------------------------------------------------------------

    @Test
    @DisplayName("GET /v1/assistente/catalogo devolve a chave de cada item")
    void catalogoDevolveAChave() throws Exception {
        String token = cadastrarEObterToken();

        MvcResult resposta =
                mockMvc.perform(
                                get("/v1/assistente/catalogo")
                                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                        .andExpect(status().isOk())
                        .andReturn();

        JsonNode servicos =
                json.readTree(resposta.getResponse().getContentAsString()).get("servicos");

        Map<String, String> devolvidas = new HashMap<>();
        for (JsonNode servico : servicos) {
            assertThat(servico.hasNonNull("chave"))
                    .as("%s veio sem chave", servico.get("nome_exibido").asText())
                    .isTrue();
            assertThat(servico.get("chave").asText()).matches("^[a-z0-9-]+$");
            devolvidas.put(servico.get("nome_exibido").asText(), servico.get("chave").asText());
        }

        // Cada nome com a sua chave — incluindo os sensíveis (Gov.br, Meu INSS),
        // que viajam sem pacote mas com chave: o guia deles existe.
        assertThat(devolvidas).containsAllEntriesOf(CHAVES_SEMEADAS);
    }

    // -------------------------------------------------------------------------

    /**
     * Insere um serviço cotidiano de teste. Pacote único por chamada, para que a
     * única restrição que possa reclamar seja a que o teste examina.
     */
    private void inserir(String chave) {
        jdbc.update(
                """
                INSERT INTO servico_conhecido
                    (id, chave, nome_exibido, categoria, identificador_android,
                     descricao_curta, ativo, criado_em, atualizado_em)
                VALUES (?, ?, ?, 'COTIDIANO', ?, 'descricao', TRUE, now(), now())
                """,
                UUID.randomUUID(),
                chave,
                MARCADOR,
                "com.teste.chave." + UUID.randomUUID());
    }

    private String cadastrarEObterToken() throws Exception {
        String corpo =
                """
                {
                  "nome_tratamento": "Ana",
                  "canal": {"tipo": "email", "valor": "%s"},
                  "senha": "%s",
                  "modo_assistido": false
                }
                """
                        .formatted(EMAIL, SENHA);

        MvcResult resultado =
                mockMvc.perform(
                                post("/v1/auth/cadastro")
                                        .contentType(MediaType.APPLICATION_JSON)
                                        .content(corpo))
                        .andExpect(status().isCreated())
                        .andReturn();

        return json.readTree(resultado.getResponse().getContentAsString())
                .get("token_acesso")
                .asText();
    }
}
