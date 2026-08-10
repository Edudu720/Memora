package br.fatec.memora.comum;

import static org.assertj.core.api.Assertions.assertThat;

import jakarta.servlet.FilterChain;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.slf4j.MDC;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

/**
 * Rastreio da requisicao (T026).
 *
 * <p>Tres garantias sao verificadas aqui, e as tres tem consequencia de
 * seguranca, nao apenas de observabilidade:
 *
 * <ol>
 *   <li>Request ID malformado do cliente e descartado — senao vira forja de log
 *       e cabecalho partido na resposta;
 *   <li>o contexto e limpo ao fim — senao a origem de uma pessoa reaparece na
 *       requisicao da seguinte, quando a thread volta ao pool;
 *   <li>a origem sai resumida com chave — endereco em claro nao chega ao banco,
 *       e resumo sem chave seria revertido por forca bruta.
 * </ol>
 */
@DisplayName("Rastreio da requisicao")
class FiltroRastreioTest {

    /** 32 bytes: o piso exigido pela {@link ConfiguracaoDeRastreio}. */
    private static final String CHAVE = "chave-de-teste-com-trinta-e-dois";

    private static final String OUTRA_CHAVE = "outra-chave-de-teste-com-32-bytes";

    private final FiltroRastreio filtro = new FiltroRastreio(ConfiguracaoDeRastreio.chaveDe(CHAVE));

    @Nested
    @DisplayName("Identificadores")
    class Identificadores {

        @Test
        @DisplayName("toda resposta sai com Trace ID e Request ID")
        void semprePresentes() throws Exception {
            MockHttpServletResponse resposta = executar(requisicao(), chainVazia());

            assertThat(resposta.getHeader(FiltroRastreio.CABECALHO_TRACE_ID)).isNotBlank();
            assertThat(resposta.getHeader(FiltroRastreio.CABECALHO_REQUEST_ID)).isNotBlank();
        }

        @Test
        @DisplayName("o Trace ID e sempre nosso, mesmo se o cliente mandar um")
        void traceIdNuncaVemDoCliente() throws Exception {
            MockHttpServletRequest requisicao = requisicao();
            requisicao.addHeader(FiltroRastreio.CABECALHO_TRACE_ID, "trace-escolhido-pelo-cliente");

            MockHttpServletResponse resposta = executar(requisicao, chainVazia());

            assertThat(resposta.getHeader(FiltroRastreio.CABECALHO_TRACE_ID))
                    .isNotEqualTo("trace-escolhido-pelo-cliente");
        }

        @Test
        @DisplayName("Request ID bem formado do cliente e preservado")
        void requestIdDoClientePreservado() throws Exception {
            MockHttpServletRequest requisicao = requisicao();
            requisicao.addHeader(FiltroRastreio.CABECALHO_REQUEST_ID, "abc-123_XYZ");

            MockHttpServletResponse resposta = executar(requisicao, chainVazia());

            assertThat(resposta.getHeader(FiltroRastreio.CABECALHO_REQUEST_ID))
                    .isEqualTo("abc-123_XYZ");
        }

        /**
         * Quebra de linha no valor permitiria escrever uma linha de log inteira,
         * forjada, sob o nome do sistema — e partir a resposta HTTP em duas.
         */
        @Test
        @DisplayName("Request ID com quebra de linha e descartado")
        void requestIdComQuebraDeLinhaDescartado() throws Exception {
            MockHttpServletRequest requisicao = requisicao();
            requisicao.addHeader(
                    FiltroRastreio.CABECALHO_REQUEST_ID,
                    "valido\r\nWARN entrada autorizada para conta alheia");

            MockHttpServletResponse resposta = executar(requisicao, chainVazia());

            assertThat(resposta.getHeader(FiltroRastreio.CABECALHO_REQUEST_ID))
                    .doesNotContain("\n")
                    .doesNotContain("\r")
                    .doesNotContain("entrada autorizada");
        }

        @Test
        @DisplayName("Request ID longo demais e descartado")
        void requestIdLongoDescartado() throws Exception {
            MockHttpServletRequest requisicao = requisicao();
            requisicao.addHeader(FiltroRastreio.CABECALHO_REQUEST_ID, "a".repeat(65));

            MockHttpServletResponse resposta = executar(requisicao, chainVazia());

            assertThat(resposta.getHeader(FiltroRastreio.CABECALHO_REQUEST_ID))
                    .hasSizeLessThanOrEqualTo(64);
        }
    }

    @Nested
    @DisplayName("Contexto")
    class Contexto {

        @Test
        @DisplayName("fica disponivel para as camadas de dentro")
        void disponivelDuranteACadeia() throws Exception {
            AtomicReference<ContextoDaRequisicao> visto = new AtomicReference<>();

            executar(requisicao(), (req, res) -> visto.set(ContextoDaRequisicao.atual()));

            assertThat(visto.get().traceId()).isNotBlank();
            assertThat(visto.get().requestId()).isNotBlank();
            assertThat(visto.get().origemHash()).isNotBlank();
        }

        @Test
        @DisplayName("e limpo ao fim, para a thread nao levar dado a proxima pessoa")
        void limpoAoFim() throws Exception {
            executar(requisicao(), chainVazia());

            assertThat(ContextoDaRequisicao.atual().traceId()).isNull();
            assertThat(ContextoDaRequisicao.atual().origemHash()).isNull();
            assertThat(MDC.get(FiltroRastreio.MDC_TRACE_ID)).isNull();
            assertThat(MDC.get(FiltroRastreio.MDC_REQUEST_ID)).isNull();
        }

        @Test
        @DisplayName("e limpo tambem quando a requisicao explode")
        void limpoMesmoComExcecao() {
            FilterChain queFalha =
                    (req, res) -> {
                        throw new IllegalStateException("falha no meio do caminho");
                    };

            try {
                executar(requisicao(), queFalha);
            } catch (Exception esperada) {
                // A excecao sobe; o que se verifica e a limpeza.
            }

            assertThat(ContextoDaRequisicao.atual().traceId()).isNull();
            assertThat(MDC.get(FiltroRastreio.MDC_TRACE_ID)).isNull();
        }
    }

    @Nested
    @DisplayName("Origem de rede")
    class Origem {

        @Test
        @DisplayName("o endereco nao aparece em claro em lugar nenhum")
        void enderecoNaoApareceEmClaro() throws Exception {
            AtomicReference<ContextoDaRequisicao> visto = new AtomicReference<>();
            MockHttpServletRequest requisicao = requisicao();
            requisicao.setRemoteAddr("203.0.113.42");

            MockHttpServletResponse resposta =
                    executar(requisicao, (req, res) -> visto.set(ContextoDaRequisicao.atual()));

            assertThat(visto.get().origemHash()).doesNotContain("203.0.113.42");
            assertThat(resposta.getHeaderNames())
                    .allSatisfy(
                            nome ->
                                    assertThat(resposta.getHeader(nome))
                                            .doesNotContain("203.0.113.42"));
        }

        @Test
        @DisplayName("o mesmo endereco resume igual — senao nao da para correlacionar abuso")
        void mesmoEnderecoMesmoResumo() throws Exception {
            assertThat(origemDe("203.0.113.42")).isEqualTo(origemDe("203.0.113.42"));
        }

        @Test
        @DisplayName("enderecos diferentes resumem diferente")
        void enderecosDiferentesResumosDiferentes() throws Exception {
            assertThat(origemDe("203.0.113.42")).isNotEqualTo(origemDe("203.0.113.43"));
        }

        /**
         * Prova que ha chave no meio. Com SHA-256 puro os dois filtros
         * produziriam o mesmo valor — e quem obtivesse o banco reverteria a
         * coluna inteira montando o dicionario do IPv4.
         */
        @Test
        @DisplayName("chave diferente resume diferente: e HMAC, nao resumo simples")
        void chaveMudaOResumo() throws Exception {
            String comUmaChave = origemDe("203.0.113.42");
            String comOutraChave =
                    origemComFiltro(
                            new FiltroRastreio(ConfiguracaoDeRastreio.chaveDe(OUTRA_CHAVE)),
                            "203.0.113.42");

            assertThat(comUmaChave).isNotEqualTo(comOutraChave);
        }

        private String origemDe(String endereco) throws Exception {
            return origemComFiltro(filtro, endereco);
        }

        private String origemComFiltro(FiltroRastreio filtro, String endereco) throws Exception {
            AtomicReference<ContextoDaRequisicao> visto = new AtomicReference<>();
            MockHttpServletRequest requisicao = requisicao();
            requisicao.setRemoteAddr(endereco);

            filtro.doFilter(
                    requisicao,
                    new MockHttpServletResponse(),
                    (req, res) -> visto.set(ContextoDaRequisicao.atual()));

            return visto.get().origemHash();
        }
    }

    private MockHttpServletRequest requisicao() {
        MockHttpServletRequest requisicao = new MockHttpServletRequest("POST", "/v1/auth/entrar");
        requisicao.setRemoteAddr("198.51.100.7");
        return requisicao;
    }

    private FilterChain chainVazia() {
        return (req, res) -> {};
    }

    private MockHttpServletResponse executar(MockHttpServletRequest requisicao, FilterChain cadeia)
            throws Exception {
        MockHttpServletResponse resposta = new MockHttpServletResponse();
        filtro.doFilter(requisicao, resposta, cadeia);
        return resposta;
    }
}
