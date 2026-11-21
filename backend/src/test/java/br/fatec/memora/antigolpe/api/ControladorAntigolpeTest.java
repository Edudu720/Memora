package br.fatec.memora.antigolpe.api;

import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.containsString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import br.fatec.memora.antigolpe.api.dto.AnalisarGolpeResponse;
import br.fatec.memora.antigolpe.aplicacao.ServicoAnaliseGolpe;
import br.fatec.memora.antigolpe.dominio.NivelRiscoGolpe;
import br.fatec.memora.antigolpe.seguranca.LimiteAnaliseGolpeExcedido;
import br.fatec.memora.autenticacao.dominio.EstadoDaConta;
import br.fatec.memora.autenticacao.seguranca.PessoaAutenticada;
import br.fatec.memora.comum.TratadorGlobalDeErros;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.core.MethodParameter;
import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.method.support.ModelAndViewContainer;

@DisplayName("ControladorAnaliseGolpe — contrato JSON, validação, autenticação e tratamento de erros")
class ControladorAntigolpeTest {

    private ServicoAnaliseGolpe servico;
    private PessoaAutenticada principalAtual;
    private MockMvc mockMvc;

    @BeforeEach
    void preparar() {
        servico = mock(ServicoAnaliseGolpe.class);
        ControladorAnaliseGolpe controlador = new ControladorAnaliseGolpe(servico);
        HandlerMethodArgumentResolver resolvedorPrincipal =
                new HandlerMethodArgumentResolver() {
                    @Override
                    public boolean supportsParameter(MethodParameter parameter) {
                        return parameter.hasParameterAnnotation(AuthenticationPrincipal.class);
                    }

                    @Override
                    public Object resolveArgument(
                            MethodParameter parameter,
                            ModelAndViewContainer mavContainer,
                            NativeWebRequest webRequest,
                            WebDataBinderFactory binderFactory) {
                        return principalAtual;
                    }
                };
        mockMvc =
                MockMvcBuilders.standaloneSetup(controlador)
                        .setCustomArgumentResolvers(resolvedorPrincipal)
                        .setControllerAdvice(new TratadorGlobalDeErros())
                        .build();
    }

    @Test
    @DisplayName("responde 200 OK com contrato JSON completo em /v1/golpes/analisar e /api/v1/golpes/analisar")
    void responde200ComContratoCompleto() throws Exception {
        UUID pessoaId = UUID.randomUUID();
        principalAtual = new PessoaAutenticada(pessoaId, EstadoDaConta.ATIVA, UUID.randomUUID());

        when(servico.analisar(eq(pessoaId), eq("Link suspeito http://45.33.12.9/pix")))
                .thenReturn(
                        new AnalisarGolpeResponse(
                                NivelRiscoGolpe.ALTO,
                                "Cuidado, isso parece um golpe.",
                                "Encontrei sinais fortes de tentativa de enganar você.",
                                List.of("Não toque no link."),
                                List.of("Link com endereço numérico."),
                                true));

        String corpo = """
                {"conteudo": "Link suspeito http://45.33.12.9/pix"}
                """;

        for (String rota : new String[] {"/v1/golpes/analisar", "/api/v1/golpes/analisar"}) {
            mockMvc.perform(post(rota).contentType(MediaType.APPLICATION_JSON).content(corpo))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.risco").value("ALTO"))
                    .andExpect(jsonPath("$.titulo").value("Cuidado, isso parece um golpe."))
                    .andExpect(
                            jsonPath("$.explicacao")
                                    .value("Encontrei sinais fortes de tentativa de enganar você."))
                    .andExpect(jsonPath("$.orientacoes[0]").value("Não toque no link."))
                    .andExpect(
                            jsonPath("$.sinaisDetectados[0]").value("Link com endereço numérico."))
                    .andExpect(jsonPath("$.analisadoPorIa").value(true));
        }
    }

    @Test
    @DisplayName("recusa usuário nulo ou pendente de verificação com 401 SESSAO_EXPIRADA")
    void recusaNuloOuPendenteCom401() throws Exception {
        String corpo = """
                {"conteudo": "Mensagem para analisar"}
                """;

        principalAtual = null;
        mockMvc.perform(
                        post("/v1/golpes/analisar")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(corpo))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.codigo").value("SESSAO_EXPIRADA"));

        principalAtual =
                new PessoaAutenticada(
                        UUID.randomUUID(), EstadoDaConta.PENDENTE_VERIFICACAO, UUID.randomUUID());
        mockMvc.perform(
                        post("/v1/golpes/analisar")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(corpo))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.codigo").value("SESSAO_EXPIRADA"));
    }

    @Test
    @DisplayName("recusa conteúdo vazio, >2000 chars, ausente ou JSON malformado com 400 sem vazar detalhes")
    void recusaEntradaInvalidaCom400SemVazarDetalhes() throws Exception {
        principalAtual =
                new PessoaAutenticada(UUID.randomUUID(), EstadoDaConta.ATIVA, UUID.randomUUID());

        String muitoLongo = "a".repeat(2001);
        List<String> invalidos =
                List.of(
                        "{}",
                        "{\"conteudo\": \"   \"}",
                        "{\"conteudo\": \"" + muitoLongo + "\"}",
                        "{json-quebrado");

        for (String corpo : invalidos) {
            mockMvc.perform(
                            post("/v1/golpes/analisar")
                                    .contentType(MediaType.APPLICATION_JSON)
                                    .content(corpo))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.codigo").value("DADOS_INVALIDOS"))
                    .andExpect(jsonPath("$.mensagem", not(containsString("conteudo"))))
                    .andExpect(jsonPath("$.mensagem", not(containsString("AnalisarGolpeRequest"))))
                    .andExpect(jsonPath("$.mensagem", not(containsString("Exception"))));
        }
    }

    @Test
    @DisplayName("responde 429 com Retry-After e tentar_novamente_em_segundos quando excede limite")
    void responde429QuandoExcedeLimite() throws Exception {
        UUID pessoaId = UUID.randomUUID();
        principalAtual = new PessoaAutenticada(pessoaId, EstadoDaConta.ATIVA, UUID.randomUUID());
        when(servico.analisar(eq(pessoaId), eq("Teste")))
                .thenThrow(new LimiteAnaliseGolpeExcedido(120L));

        mockMvc.perform(
                        post("/v1/golpes/analisar")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"conteudo\": \"Teste\"}"))
                .andExpect(status().isTooManyRequests())
                .andExpect(header().string("Retry-After", "120"))
                .andExpect(jsonPath("$.codigo").value("LIMITE_DE_CONVERSAS"))
                .andExpect(jsonPath("$.tentar_novamente_em_segundos").value(120));
    }

    @Test
    @DisplayName("erro inesperado devolve 500 ERRO_INESPERADO sem vazar detalhe interno")
    void erroInesperadoNaoVazaDetalhe() throws Exception {
        UUID pessoaId = UUID.randomUUID();
        principalAtual = new PessoaAutenticada(pessoaId, EstadoDaConta.ATIVA, UUID.randomUUID());
        when(servico.analisar(eq(pessoaId), eq("Teste")))
                .thenThrow(new RuntimeException("INTERNAL-SQL-SECRET-DETAIL"));

        mockMvc.perform(
                        post("/v1/golpes/analisar")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"conteudo\": \"Teste\"}"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.codigo").value("ERRO_INESPERADO"))
                .andExpect(jsonPath("$.mensagem", not(containsString("INTERNAL-SQL-SECRET-DETAIL"))))
                .andExpect(jsonPath("$.mensagem", not(containsString("RuntimeException"))));
    }
}
