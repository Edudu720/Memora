package br.fatec.memora.assistente;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.asyncDispatch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import br.fatec.memora.assistente.infra.ClienteDaAssistenteSimulado;
import br.fatec.memora.autenticacao.infra.RepositorioCanalContato;
import br.fatec.memora.autenticacao.infra.RepositorioCodigoVerificacao;
import br.fatec.memora.autenticacao.infra.RepositorioEventoAutenticacao;
import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
import br.fatec.memora.autenticacao.infra.RepositorioSessao;
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
 * O fim da conversa não é recusado pela segurança.
 *
 * <h2>O que acontecia</h2>
 *
 * Quando o {@code SseEmitter} termina, o servidor faz um segundo despacho da
 * mesma requisição, do tipo {@code ASYNC}. O Spring Security autoriza também
 * esse despacho, mas o {@code FiltroDeTokenDeAcesso} — um
 * {@code OncePerRequestFilter} — não roda de novo nele: o despacho chegava sem
 * ninguém autenticado e era negado. Como a resposta já tinha ido, sobrava um
 * {@code AuthorizationDeniedException} com a pilha inteira no log, <b>uma vez
 * por conversa</b>. Achado no primeiro teste no celular com o Gemini, em
 * 2026-10-21: até ali o aplicativo nunca tinha conversado com o servidor real.
 *
 * <h2>Por que liberar o despacho não abre nada</h2>
 *
 * O despacho {@code ASYNC} só existe depois de uma requisição que já passou
 * pela cadeia inteira e foi autorizada. O portão de quem pode conversar
 * continua no despacho original — e o segundo teste prova que ele segue
 * fechado para quem não tem sessão.
 */
@AutoConfigureMockMvc
@DisplayName("O despacho assíncrono do fim da conversa")
class DespachoAssincronoDaConversaTest extends TesteComBanco {

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
    @DisplayName("terminada a resposta, o despacho ASYNC não é negado")
    void despachoAssincronoPassa() throws Exception {
        MvcResult resultado = conversar(cadastrarEObterToken());

        assertThat(resultado.getRequest().isAsyncStarted())
                .as("a conversa é SSE: a resposta precisa ter sido assíncrona")
                .isTrue();

        int status = mockMvc.perform(asyncDispatch(resultado)).andReturn().getResponse().getStatus();
        assertThat(status)
                .as("o fim da conversa foi recusado pela segurança")
                .isEqualTo(200);
    }

    @Test
    @DisplayName("sem sessão, a conversa continua fechada")
    void semSessaoContinuaFechado() throws Exception {
        int status =
                mockMvc.perform(
                                post("/v1/assistente/conversa")
                                        .contentType(MediaType.APPLICATION_JSON)
                                        .accept(MediaType.TEXT_EVENT_STREAM)
                                        .content("{\"mensagem\": \"Como aumento a letra?\"}"))
                        .andReturn()
                        .getResponse()
                        .getStatus();

        assertThat(status).isEqualTo(401);
    }

    // --- apoio ---------------------------------------------------------------

    private MvcResult conversar(String token) throws Exception {
        MvcResult resultado =
                mockMvc.perform(
                                post("/v1/assistente/conversa")
                                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                                        .contentType(MediaType.APPLICATION_JSON)
                                        .accept(MediaType.TEXT_EVENT_STREAM)
                                        .content("{\"mensagem\": \"Como aumento a letra?\"}"))
                        .andReturn();

        // A resposta é transmitida por outra thread; espera o evento de fim (ou
        // de erro), com um teto para não travar a suíte.
        long limite = System.nanoTime() + 10_000_000_000L;
        while (System.nanoTime() < limite) {
            String conteudo = resultado.getResponse().getContentAsString();
            if (conteudo.contains("event:erro") || conteudo.contains("event:fim")) {
                break;
            }
            Thread.sleep(25);
        }
        return resultado;
    }

    private String cadastrarEObterToken() throws Exception {
        String corpo =
                """
                {
                  "nome_tratamento": "Ana",
                  "canal": {"tipo": "email", "valor": "ana.despacho@gmail.com"},
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
