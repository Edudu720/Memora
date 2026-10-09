package br.fatec.memora.assistente;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import br.fatec.memora.assistente.infra.AssistenteIndisponivel.Motivo;
import br.fatec.memora.assistente.infra.ClienteDaAssistenteSimulado;
import br.fatec.memora.autenticacao.infra.RepositorioCanalContato;
import br.fatec.memora.autenticacao.infra.RepositorioCodigoVerificacao;
import br.fatec.memora.autenticacao.infra.RepositorioEventoAutenticacao;
import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
import br.fatec.memora.autenticacao.infra.RepositorioSessao;
import br.fatec.memora.comum.CodigoDeErro;
import br.fatec.memora.suporte.TesteComBanco;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import tools.jackson.databind.ObjectMapper;

/**
 * O que a pessoa lê quando o provedor de IA cai (T063).
 *
 * <h2>Pelo endpoint de verdade, e não só pelo serviço</h2>
 *
 * O texto que chega à pessoa é escolhido no {@code ControladorConversa}, depois
 * da exceção. Testar o adaptador provou que a exceção não carrega texto do
 * Google; falta provar que o controlador não o <i>procura</i> em outro lugar, e
 * que a frase que sai é a da Memora — a FR-041 da feature 001, vista de fora.
 *
 * <p>O simulado falha sob comando, com cada motivo. Em nenhum deles o corpo da
 * resposta pode ter nome de classe, status HTTP, "429", "cota" ou
 * "provedor": para quem tem 70 anos, "erro 429" não é informação, é susto.
 */
@AutoConfigureMockMvc
@DisplayName("Provedor de IA fora do ar, visto pela pessoa (T063, FR-041)")
class ProvedorForaDoArNaConversaTest extends TesteComBanco {

    private static final String SENHA = "pipoca no varal azul";

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper json;
    @Autowired private ClienteDaAssistenteSimulado assistente;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private RepositorioEventoAutenticacao eventos;
    @Autowired private RepositorioCodigoVerificacao codigos;
    @Autowired private RepositorioSessao sessoes;
    @Autowired private RepositorioCanalContato canais;
    @Autowired private RepositorioPessoaUsuaria pessoas;

    @AfterEach
    void limpar() {
        assistente.limpar();
        jdbc.execute("DELETE FROM evento_da_assistente");
        jdbc.execute("DELETE FROM uso_da_assistente");
        eventos.deleteAll();
        codigos.deleteAll();
        sessoes.deleteAll();
        canais.deleteAll();
        pessoas.deleteAll();
    }

    @Test
    @DisplayName("cota, 5xx, rede e prazo chegam como a mesma frase da Memora, sem detalhe tecnico")
    void aPessoaLeAFraseDaMemora() throws Exception {
        String token = cadastrarEObterToken();

        for (Motivo motivo : Motivo.values()) {
            assistente.limpar().falharCom(motivo);

            String fluxo = conversar(token);

            assertThat(fluxo)
                    .as("motivo %s: o evento de erro tem o codigo da Memora", motivo)
                    .contains("event:erro")
                    .contains(CodigoDeErro.ASSISTENTE_INDISPONIVEL.name());
            assertThat(fluxo)
                    .as("motivo %s: a frase e a da Memora", motivo)
                    .contains("Estou com um pouquinho de dificuldade");
            assertThat(fluxo.toLowerCase())
                    .as("motivo %s: nada tecnico chega a pessoa", motivo)
                    .doesNotContain("429")
                    .doesNotContain("cota")
                    .doesNotContain("indisponivel:")
                    .doesNotContain("assistenteindisponivel")
                    .doesNotContain("exception")
                    .doesNotContain("provedor")
                    .doesNotContain("gemini")
                    .doesNotContain("google");
        }
    }

    // --- apoio ---------------------------------------------------------------

    private String conversar(String token) throws Exception {
        MvcResult resultado =
                mockMvc.perform(
                                post("/v1/assistente/conversa")
                                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                                        .contentType(MediaType.APPLICATION_JSON)
                                        .accept(MediaType.TEXT_EVENT_STREAM)
                                        .content("{\"mensagem\": \"Como aumento a letra?\"}"))
                        .andReturn();

        // A resposta e transmitida por outra thread; espera ate o evento de
        // erro (ou de fim) aparecer, com um teto para nao travar a suite.
        long limite = System.nanoTime() + 10_000_000_000L;
        String conteudo = "";
        while (System.nanoTime() < limite) {
            conteudo = resultado.getResponse().getContentAsString();
            if (conteudo.contains("event:erro") || conteudo.contains("event:fim")) {
                break;
            }
            Thread.sleep(25);
        }
        return conteudo;
    }

    private String cadastrarEObterToken() throws Exception {
        String corpo =
                """
                {
                  "nome_tratamento": "Ana",
                  "canal": {"tipo": "email", "valor": "ana.provedor@gmail.com"},
                  "senha": "%s",
                  "modo_assistido": false
                }
                """
                        .formatted(SENHA);
        MvcResult cadastro =
                mockMvc.perform(
                                post("/v1/auth/cadastro")
                                        .contentType(MediaType.APPLICATION_JSON)
                                        .content(corpo))
                        .andReturn();
        return json.readTree(cadastro.getResponse().getContentAsString())
                .get("token_acesso")
                .asText();
    }
}
