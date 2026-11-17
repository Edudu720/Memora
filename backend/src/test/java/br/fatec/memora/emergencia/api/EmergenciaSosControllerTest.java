package br.fatec.memora.emergencia.api;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import br.fatec.memora.autenticacao.dominio.EstadoDaConta;
import br.fatec.memora.autenticacao.seguranca.PessoaAutenticada;
import br.fatec.memora.comum.FalhaDoMemora;
import br.fatec.memora.comum.TratadorGlobalDeErros;
import br.fatec.memora.emergencia.api.dto.SolicitarSosResponse;
import br.fatec.memora.emergencia.aplicacao.ServicoEmergenciaSos;
import java.time.Instant;
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

@DisplayName("EmergenciaSosController — rotas, autenticação e validação de contrato")
class EmergenciaSosControllerTest {

    private ServicoEmergenciaSos servico;
    private PessoaAutenticada principalAtual;
    private MockMvc mockMvc;

    @BeforeEach
    void preparar() {
        servico = mock(ServicoEmergenciaSos.class);
        EmergenciaSosController controller = new EmergenciaSosController(servico);
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
                MockMvcBuilders.standaloneSetup(controller)
                        .setCustomArgumentResolvers(resolvedorPrincipal)
                        .setControllerAdvice(new TratadorGlobalDeErros())
                        .build();
    }

    @Test
    @DisplayName("responde 200 OK com payload completo tanto em /v1 quanto em /api/v1")
    void respondeSucessoNasDuasRotas() throws Exception {
        UUID pessoaId = UUID.randomUUID();
        UUID eventoId = UUID.randomUUID();
        principalAtual = new PessoaAutenticada(pessoaId, EstadoDaConta.ATIVA, UUID.randomUUID());

        when(servico.registrarEEnviar(eq(pessoaId), any()))
                .thenReturn(
                        new SolicitarSosResponse(
                                eventoId,
                                "SOS_MANUAL",
                                "ENVIADO",
                                "Sua solicitação foi encaminhada.",
                                Instant.parse("2026-11-16T18:00:00Z")));

        String corpo =
                """
                {
                  "tipo": "SOS_MANUAL",
                  "eventoId": "%s",
                  "localizacao": {"latitude": -22.739, "longitude": -47.331}
                }
                """
                        .formatted(eventoId);

        for (String rota : new String[] {"/v1/emergencias/sos", "/api/v1/emergencias/sos"}) {
            mockMvc.perform(post(rota).contentType(MediaType.APPLICATION_JSON).content(corpo))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.eventoId").value(eventoId.toString()))
                    .andExpect(jsonPath("$.tipo").value("SOS_MANUAL"))
                    .andExpect(jsonPath("$.status").value("ENVIADO"))
                    .andExpect(jsonPath("$.mensagem").value("Sua solicitação foi encaminhada."));
        }
    }

    @Test
    @DisplayName("recusa usuário não autenticado ou pendente de verificação com 401")
    void recusaNaoAutenticadoOuPendente() throws Exception {
        String corpo =
                """
                {"tipo": "SOS_MANUAL", "eventoId": "%s"}
                """
                        .formatted(UUID.randomUUID());

        principalAtual = null;
        mockMvc.perform(
                        post("/api/v1/emergencias/sos")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(corpo))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.codigo").value("SESSAO_EXPIRADA"));

        principalAtual =
                new PessoaAutenticada(
                        UUID.randomUUID(), EstadoDaConta.PENDENTE_VERIFICACAO, UUID.randomUUID());
        mockMvc.perform(
                        post("/v1/emergencias/sos")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(corpo))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.codigo").value("SESSAO_EXPIRADA"));
    }

    @Test
    @DisplayName("recusa coordenadas fora da faixa geográfica com 400 DADOS_INVALIDOS")
    void recusaCoordenadasInvalidas() throws Exception {
        principalAtual =
                new PessoaAutenticada(UUID.randomUUID(), EstadoDaConta.ATIVA, UUID.randomUUID());

        String corpoInvalido =
                """
                {
                  "tipo": "SOS_MANUAL",
                  "eventoId": "%s",
                  "localizacao": {"latitude": 120.0, "longitude": -47.3}
                }
                """
                        .formatted(UUID.randomUUID());

        mockMvc.perform(
                        post("/api/v1/emergencias/sos")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(corpoInvalido))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.codigo").value("DADOS_INVALIDOS"));
    }

    @Test
    @DisplayName("responde 429 LIMITE_DE_SOS com tentar_novamente_em_segundos quando excede cota")
    void responde429QuandoExcedeLimiteSos() throws Exception {
        UUID pessoaId = UUID.randomUUID();
        principalAtual = new PessoaAutenticada(pessoaId, EstadoDaConta.ATIVA, UUID.randomUUID());
        when(servico.registrarEEnviar(eq(pessoaId), any()))
                .thenThrow(FalhaDoMemora.limiteSos(300));

        String corpo =
                """
                {"tipo": "SOS_MANUAL", "eventoId": "%s", "contatoDestino": "maria@email.com"}
                """
                        .formatted(UUID.randomUUID());

        mockMvc.perform(
                        post("/api/v1/emergencias/sos")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(corpo))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.codigo").value("LIMITE_DE_SOS"))
                .andExpect(jsonPath("$.tentar_novamente_em_segundos").value(300));
    }
}
