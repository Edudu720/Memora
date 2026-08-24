package br.fatec.memora.autenticacao.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import br.fatec.memora.autenticacao.dominio.TipoDeEvento;
import br.fatec.memora.autenticacao.infra.RepositorioCanalContato;
import br.fatec.memora.autenticacao.infra.RepositorioEventoAutenticacao;
import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
import br.fatec.memora.autenticacao.infra.RepositorioSessao;
import br.fatec.memora.suporte.TesteComBanco;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.ResultActions;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

/**
 * {@code POST /v1/auth/sessao/renovar} (T048).
 *
 * <p>Cobre FR-016 e a rotação da R2 <b>pelo endpoint</b>. A mecânica da rotação
 * e a detecção de reuso já têm teste de unidade em {@code ServicoDeSessaoTest} e
 * {@code ReusoDeTokenTest} (cenário V3); aqui se verifica o que só existe na
 * borda: o corpo do contrato, o status e o fato de que nenhuma recusa conta
 * <i>por que</i> recusou.
 */
@AutoConfigureMockMvc
@DisplayName("T048 — renovação de sessão")
class RenovarSessaoTest extends TesteComBanco {

    private static final String EMAIL = "ana@gmail.com";

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
    @DisplayName("Reabrir o aplicativo e continuar conectada (FR-016)")
    class Rotacao {

        @Test
        @DisplayName("renovar com o refresh do cadastro devolve uma sessão nova")
        void renovaComRefreshDoCadastro() throws Exception {
            String refresh = refreshDe(cadastrar().andReturn());

            renovar(refresh)
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.token_acesso").isNotEmpty())
                    .andExpect(jsonPath("$.refresh_token").isNotEmpty())
                    .andExpect(jsonPath("$.expira_em_segundos").value(900))
                    .andExpect(jsonPath("$.pessoa.nome_tratamento").value("Ana"));
        }

        /** Rotação: o token apresentado é trocado, nunca devolvido de novo. */
        @Test
        @DisplayName("o refresh devolvido é diferente do apresentado")
        void refreshRotaciona() throws Exception {
            String primeiro = refreshDe(cadastrar().andReturn());

            String segundo = refreshDe(renovar(primeiro).andReturn());

            assertThat(segundo).isNotEqualTo(primeiro);
        }

        @Test
        @DisplayName("a renovação não exige token de acesso no cabeçalho")
        void naoExigeAutenticacao() throws Exception {
            String refresh = refreshDe(cadastrar().andReturn());

            // Sem nenhum cabecalho Authorization — e o ponto: quem chega aqui
            // esta justamente com o token de acesso vencido.
            renovar(refresh).andExpect(status().isOk());
        }

        @Test
        @DisplayName("renovar em cadeia continua funcionando")
        void cadeiaDeRenovacoes() throws Exception {
            String refresh = refreshDe(cadastrar().andReturn());

            for (int volta = 0; volta < 3; volta++) {
                refresh = refreshDe(renovar(refresh).andExpect(status().isOk()).andReturn());
            }

            assertThat(refresh).isNotBlank();
        }
    }

    @Nested
    @DisplayName("Toda recusa é igual (R2)")
    class Recusa {

        @Test
        @DisplayName("refresh desconhecido devolve 401 com CREDENCIAIS_INVALIDAS")
        void refreshDesconhecido() throws Exception {
            renovar("nao-e-um-refresh-token-nosso")
                    .andExpect(status().isUnauthorized())
                    .andExpect(jsonPath("$.codigo").value("CREDENCIAIS_INVALIDAS"));
        }

        /**
         * O reuso, pela borda: apresentar de novo um token já rotacionado indica
         * roubo, e derruba a família inteira. O V3 já prova a mecânica; aqui se
         * prova que ela chega ao endpoint.
         */
        @Test
        @DisplayName("reapresentar um refresh já usado devolve 401 e derruba a família")
        void reusoDerrubaAFamilia() throws Exception {
            String primeiro = refreshDe(cadastrar().andReturn());
            String segundo = refreshDe(renovar(primeiro).andReturn());

            renovar(primeiro).andExpect(status().isUnauthorized());

            // O que estava valido antes do reuso para de valer junto: e a unica
            // resposta possivel quando nao se sabe qual das duas copias e a
            // legitima.
            renovar(segundo).andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("o reuso aparece na trilha como REUSO_TOKEN_DETECTADO")
        void trilhaRegistraReuso() throws Exception {
            String primeiro = refreshDe(cadastrar().andReturn());
            renovar(primeiro);

            renovar(primeiro);

            assertThat(eventos.findAll())
                    .anyMatch(evento -> evento.getTipo() == TipoDeEvento.REUSO_TOKEN_DETECTADO);
        }

        /**
         * O motivo da recusa é da auditoria, não do cliente. Se um dia o corpo
         * passar a distinguir "expirado" de "reuso detectado", este teste
         * reprova — e é para isso que ele existe: a diferença contaria a quem
         * roubou o token que ele um dia foi válido.
         */
        @Test
        @DisplayName("reuso e token desconhecido produzem o mesmo corpo")
        void mesmoCorpoNasDuasRecusas() throws Exception {
            String primeiro = refreshDe(cadastrar().andReturn());
            renovar(primeiro);

            JsonNode porReuso = corpoDe(renovar(primeiro).andReturn());
            JsonNode porDesconhecido = corpoDe(renovar("token-que-nunca-existiu").andReturn());

            assertThat(porReuso).isEqualTo(porDesconhecido);
        }

        /**
         * O refresh da sessão-chamariz nunca é gravado: ele não corresponde a
         * sessão nenhuma e morre como token desconhecido. É a prova, pela borda,
         * de que a resposta indistinguível do cadastro não vira acesso.
         */
        @Test
        @DisplayName("o refresh da sessão-chamariz não renova nada")
        void chamarizNaoRenova() throws Exception {
            cadastrar();
            String doChamariz = refreshDe(cadastrar().andReturn());

            renovar(doChamariz)
                    .andExpect(status().isUnauthorized())
                    .andExpect(jsonPath("$.codigo").value("CREDENCIAIS_INVALIDAS"));
        }

        @Test
        @DisplayName("corpo sem refresh_token é dado inválido")
        void corpoIncompleto() throws Exception {
            mockMvc.perform(
                            post("/v1/auth/sessao/renovar")
                                    .contentType(MediaType.APPLICATION_JSON)
                                    .content("{}"))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.codigo").value("DADOS_INVALIDOS"));
        }
    }

    // --- apoio ---------------------------------------------------------------

    private ResultActions cadastrar() throws Exception {
        String corpo =
                """
                {
                  "nome_tratamento": "Ana",
                  "canal": {"tipo": "email", "valor": "%s"},
                  "senha": "%s"
                }
                """
                        .formatted(EMAIL, SENHA);

        return mockMvc.perform(
                post("/v1/auth/cadastro").contentType(MediaType.APPLICATION_JSON).content(corpo));
    }

    private ResultActions renovar(String refreshToken) throws Exception {
        String corpo =
                """
                {"refresh_token": "%s"}
                """
                        .formatted(refreshToken);

        return mockMvc.perform(
                post("/v1/auth/sessao/renovar")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(corpo));
    }

    private String refreshDe(MvcResult resultado) throws Exception {
        return corpoDe(resultado).get("refresh_token").asText();
    }

    private JsonNode corpoDe(MvcResult resultado) throws Exception {
        return json.readTree(resultado.getResponse().getContentAsString());
    }
}
