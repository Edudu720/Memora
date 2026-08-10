package br.fatec.memora.autenticacao.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import br.fatec.memora.autenticacao.infra.RepositorioCanalContato;
import br.fatec.memora.autenticacao.infra.RepositorioEventoAutenticacao;
import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
import br.fatec.memora.autenticacao.infra.RepositorioSessao;
import br.fatec.memora.suporte.TesteComBanco;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

/**
 * Cenario V2 do quickstart: nenhuma resposta revela se a conta existe (T036).
 *
 * <p>Cobre FR-010 e SC-008. O quickstart e literal sobre o criterio: <i>"falha se
 * qualquer diferenca observavel em corpo, codigo de status ou tempo"</i>. Por
 * isso este arquivo nao se contenta em comparar campo a campo — ele compara a
 * <b>forma inteira</b> das duas respostas, e mede o tempo das duas.
 *
 * <p>O que ele protege: se alguem simplificar o caminho do canal ja existente —
 * devolvendo 409, pulando o hash da senha, ou omitindo um campo — a diferenca
 * aparece aqui e nao em producao.
 */
@AutoConfigureMockMvc
@DisplayName("V2 — nenhuma resposta revela se a conta existe")
class NaoRevelaExistenciaTest extends TesteComBanco {

    private static final String CANAL = "ana@gmail.com";

    private static final String SENHA = "pipoca no varal azul";

    @Autowired private MockMvc mockMvc;

    @Autowired private ObjectMapper json;

    @Autowired private RepositorioEventoAutenticacao eventos;

    @Autowired private RepositorioSessao sessoes;

    @Autowired private RepositorioCanalContato canais;

    @Autowired private RepositorioPessoaUsuaria pessoas;

    @AfterEach
    void limpar() {
        eventos.deleteAll();
        sessoes.deleteAll();
        canais.deleteAll();
        pessoas.deleteAll();
    }

    @Nested
    @DisplayName("Corpo e status")
    class CorpoEStatus {

        @Test
        @DisplayName("cadastrar com canal ja existente responde 201, como o cadastro novo")
        void mesmoStatus() throws Exception {
            cadastrar("Ana", CANAL).andExpect(status().isCreated());
            cadastrar("Ana", CANAL).andExpect(status().isCreated());
        }

        /**
         * O criterio duro do quickstart. Comparar campo a campo deixaria passar
         * um campo a mais no caminho novo; comparar a forma inteira nao.
         */
        @Test
        @DisplayName("as duas respostas tem exatamente a mesma forma")
        void mesmaForma() throws Exception {
            JsonNode primeira = corpoDe(cadastrar("Ana", CANAL).andReturn());
            JsonNode segunda = corpoDe(cadastrar("Ana", CANAL).andReturn());

            assertThat(caminhos(segunda))
                    .as("campos da resposta ao canal ja existente")
                    .isEqualTo(caminhos(primeira));
        }

        /**
         * O token do chamariz precisa ser um JWT de verdade. Se fosse texto
         * aleatorio, bastaria olhar os tres segmentos separados por ponto para
         * saber qual dos dois caminhos respondeu.
         */
        @Test
        @DisplayName("o token do segundo cadastro tem a mesma estrutura do primeiro")
        void tokenComMesmaEstrutura() throws Exception {
            String real = corpoDe(cadastrar("Ana", CANAL).andReturn()).get("token_acesso").asText();
            String chamariz =
                    corpoDe(cadastrar("Ana", CANAL).andReturn()).get("token_acesso").asText();

            assertThat(chamariz.split("\\.")).hasSameSizeAs(real.split("\\."));
            assertThat(chamariz).isNotEqualTo(real);
        }

        @Test
        @DisplayName("o refresh do segundo cadastro tem o mesmo tamanho do primeiro")
        void refreshComMesmoTamanho() throws Exception {
            String real = corpoDe(cadastrar("Ana", CANAL).andReturn()).get("refresh_token").asText();
            String chamariz =
                    corpoDe(cadastrar("Ana", CANAL).andReturn()).get("refresh_token").asText();

            assertThat(chamariz).hasSameSizeAs(real);
        }
    }

    @Nested
    @DisplayName("Nada e criado no caminho chamariz")
    class NadaEhCriado {

        /**
         * O outro lado da moeda: a resposta e indistinguivel, mas o banco nao
         * pode ter mudado. Se este teste falhar, a nao-revelacao virou cadastro
         * duplicado.
         */
        @Test
        @DisplayName("o segundo cadastro nao cria conta, canal nem sessao")
        void bancoIntacto() throws Exception {
            cadastrar("Ana", CANAL);

            long contasAntes = pessoas.count();
            long canaisAntes = canais.count();
            long sessoesAntes = sessoes.count();

            cadastrar("Ana", CANAL);

            assertThat(pessoas.count()).isEqualTo(contasAntes);
            assertThat(canais.count()).isEqualTo(canaisAntes);
            assertThat(sessoes.count()).isEqualTo(sessoesAntes);
        }

        /**
         * O chamariz nao pode ler a conta do dono real do canal para "parecer
         * verdadeiro": isso vazaria os dados dela para quem nao e ela.
         */
        @Test
        @DisplayName("a resposta ecoa o nome enviado agora, nao o da conta existente")
        void ecoaONomeEnviado() throws Exception {
            cadastrar("Ana", CANAL);

            JsonNode chamariz = corpoDe(cadastrar("Roberto", CANAL).andReturn());

            assertThat(chamariz.at("/pessoa/nome_tratamento").asText()).isEqualTo("Roberto");
        }

        /** A trilha enxerga a tentativa (FR-039), mesmo que o cliente nao saiba. */
        @Test
        @DisplayName("a tentativa aparece na trilha de auditoria")
        void trilhaEnxerga() throws Exception {
            cadastrar("Ana", CANAL);
            long antes = eventos.count();

            cadastrar("Ana", CANAL);

            assertThat(eventos.count()).isGreaterThan(antes);
        }
    }

    @Nested
    @DisplayName("Tempo")
    class Tempo {

        /**
         * O V2 manda medir. O caminho real gasta ~240 ms em Argon2; se o
         * chamariz pulasse o hash, responderia em ordens de grandeza menos, e a
         * latencia entregaria o que o corpo escondeu.
         *
         * <p>A margem e generosa de proposito: o alvo nao e cronometrar a JVM, e
         * sim reprovar quem <b>remover</b> o hash. Sem ele a diferenca e de
         * 240 ms contra ~1 ms, folgadamente fora de qualquer tolerancia.
         */
        @Test
        @DisplayName("os dois caminhos levam tempos da mesma ordem de grandeza")
        void mesmaOrdemDeGrandeza() throws Exception {
            cadastrar("Ana", CANAL); // aquece a JVM e cria a conta

            long real = duracaoDe("Ana", "outra.pessoa@gmail.com");
            long chamariz = duracaoDe("Ana", CANAL);

            assertThat(chamariz)
                    .as("cadastro com canal existente (%d ms) contra novo (%d ms)", chamariz, real)
                    .isGreaterThan(real / 4);
        }

        private long duracaoDe(String nome, String canal) throws Exception {
            long inicio = System.nanoTime();
            cadastrar(nome, canal);
            return (System.nanoTime() - inicio) / 1_000_000;
        }
    }

    // --- apoio ---------------------------------------------------------------

    private org.springframework.test.web.servlet.ResultActions cadastrar(String nome, String canal)
            throws Exception {
        String corpo =
                """
                {
                  "nome_tratamento": "%s",
                  "canal": {"tipo": "email", "valor": "%s"},
                  "senha": "%s"
                }
                """
                        .formatted(nome, canal, SENHA);

        return mockMvc.perform(
                post("/v1/auth/cadastro").contentType(MediaType.APPLICATION_JSON).content(corpo));
    }

    private JsonNode corpoDe(MvcResult resultado) throws Exception {
        return json.readTree(resultado.getResponse().getContentAsString());
    }

    /** Todos os caminhos de campo do JSON, para comparar a forma sem os valores. */
    private List<String> caminhos(JsonNode no) {
        List<String> encontrados = new ArrayList<>();
        percorrer(no, "", encontrados);
        return encontrados.stream().sorted().toList();
    }

    private void percorrer(JsonNode no, String prefixo, List<String> encontrados) {
        if (no.isObject()) {
            for (Map.Entry<String, JsonNode> campo : no.properties()) {
                percorrer(campo.getValue(), prefixo + "/" + campo.getKey(), encontrados);
            }
        } else if (no.isArray()) {
            for (int i = 0; i < no.size(); i++) {
                percorrer(no.get(i), prefixo + "[]", encontrados);
            }
        } else {
            encontrados.add(prefixo + ":" + no.getNodeType());
        }
    }
}
