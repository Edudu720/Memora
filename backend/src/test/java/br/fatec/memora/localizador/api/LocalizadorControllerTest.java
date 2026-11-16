package br.fatec.memora.localizador.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import br.fatec.memora.localizador.api.dto.BuscarServicosRequest;
import br.fatec.memora.localizador.api.dto.BuscarServicosResponse;
import br.fatec.memora.localizador.aplicacao.ServicoLocalizador;
import br.fatec.memora.localizador.infra.ProvedorGeograficoIndisponivelException;
import br.fatec.memora.suporte.TesteComBanco;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.RequestMapping;
import tools.jackson.databind.ObjectMapper;

@AutoConfigureMockMvc
class LocalizadorControllerTest extends TesteComBanco {

    private static final String EMAIL_TESTE = "localizador.http@gmail.com";
    private static final String SENHA_TESTE = "pipoca no varal azul";

    @Autowired private MockMvc springMockMvc;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private ObjectMapper json;

    private ServicoLocalizador servicoLocalizador;
    private LocalizadorController controller;
    private MockMvc standaloneMockMvc;

    @BeforeEach
    void setUp() {
        servicoLocalizador = Mockito.mock(ServicoLocalizador.class);
        controller = new LocalizadorController(servicoLocalizador);
        standaloneMockMvc = MockMvcBuilders.standaloneSetup(controller).build();
    }

    @AfterEach
    void limparUsuarioTeste() {
        List<UUID> pessoas =
                jdbc.queryForList(
                        "SELECT pessoa_id FROM canal_contato WHERE valor = ?", UUID.class, EMAIL_TESTE);
        for (UUID pessoa : pessoas) {
            jdbc.update("DELETE FROM evento_autenticacao WHERE pessoa_id = ?", pessoa);
            jdbc.update("DELETE FROM pessoa_usuaria WHERE id = ?", pessoa);
        }
    }

    @Test
    @DisplayName("Retorna 200 OK com payload de estabelecimentos")
    void buscarSucesso() {
        var respEsperada = new BuscarServicosResponse(
                new BuscarServicosResponse.ConsultaInterpretadaDto("SAUDE", "farmácia", "Buscando farmácias"),
                new BuscarServicosResponse.RegiaoOrigemDto("Americana - SP", -22.7388, -47.3325, "GPS_DISPOSITIVO"),
                1,
                List.of(new BuscarServicosResponse.EstabelecimentoDto(
                        "farm:1",
                        "Farmácia Central",
                        "SAUDE",
                        "Farmácia",
                        null,
                        -22.7388,
                        -47.3325,
                        150.0,
                        "150 metros",
                        "(19) 3461-0000",
                        "08h às 20h",
                        true,
                        "OPEN_STREET_MAP",
                        null)));

        when(servicoLocalizador.buscar(any())).thenReturn(respEsperada);

        BuscarServicosRequest req = new BuscarServicosRequest(
                "farmacia",
                "SAUDE",
                new BuscarServicosRequest.CoordenadaRequest(-22.7388, -47.3325),
                null,
                5000);

        ResponseEntity<?> response = controller.buscar(req);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(respEsperada, response.getBody());
    }

    @Test
    @DisplayName("Retorna 400 Bad Request com mensagem transparente quando faltar região e GPS")
    void buscarErroSemRegiao() {
        when(servicoLocalizador.buscar(any())).thenThrow(new IllegalArgumentException("É necessário autorizar a localização ou informar uma região manual"));

        BuscarServicosRequest req = new BuscarServicosRequest(
                "farmacia",
                "SAUDE",
                null,
                null,
                5000);

        ResponseEntity<?> response = controller.buscar(req);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
    }

    @Test
    @DisplayName("Retorna 503 Service Unavailable quando provedor geográfico externo falha")
    void buscarErroProvedorIndisponivel() {
        when(servicoLocalizador.buscar(any()))
                .thenThrow(new ProvedorGeograficoIndisponivelException("OpenStreetMap indisponível"));

        BuscarServicosRequest req = new BuscarServicosRequest(
                "farmacia",
                "SAUDE",
                new BuscarServicosRequest.CoordenadaRequest(-23.5505, -46.6333),
                null,
                5000);

        ResponseEntity<?> response = controller.buscar(req);

        assertEquals(HttpStatus.SERVICE_UNAVAILABLE, response.getStatusCode());
    }

    @Test
    @DisplayName("Expõe rotas /v1/servicos e /api/v1/servicos no RequestMapping do controller")
    void mapeiaRotasV1EApiV1() {
        RequestMapping mapping = LocalizadorController.class.getAnnotation(RequestMapping.class);
        assertNotNull(mapping);
        List<String> caminhos = List.of(mapping.value());
        assertTrue(caminhos.contains("/v1/servicos"));
        assertTrue(caminhos.contains("/api/v1/servicos"));
    }

    @Test
    @DisplayName("MockMvc standalone serializa 200 OK, 400 e 503 em ambas as rotas")
    void mockMvcDespachaRotasESerializaJson() throws Exception {
        var respEsperada = new BuscarServicosResponse(
                new BuscarServicosResponse.ConsultaInterpretadaDto("SAUDE", "farmácia", "Buscando farmácias"),
                new BuscarServicosResponse.RegiaoOrigemDto("Curitiba - PR", -25.4284, -49.2733, "GPS_DISPOSITIVO"),
                1,
                List.of(new BuscarServicosResponse.EstabelecimentoDto(
                        "farm:1",
                        "Farmácia Matriz",
                        "SAUDE",
                        "Farmácia",
                        null,
                        -25.4284,
                        -49.2733,
                        120.0,
                        "120 metros",
                        null,
                        null,
                        false,
                        "OPEN_STREET_MAP",
                        null)));

        when(servicoLocalizador.buscar(any())).thenReturn(respEsperada);

        String corpoValido = "{\"categoria\":\"SAUDE\",\"localizacao\":{\"latitude\":-25.4284,\"longitude\":-49.2733}}";
        standaloneMockMvc.perform(post("/v1/servicos/buscar")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(corpoValido))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.regiaoOrigem.descricao").value("Curitiba - PR"))
                .andExpect(jsonPath("$.estabelecimentos[0].nome").value("Farmácia Matriz"));

        when(servicoLocalizador.buscar(any()))
                .thenThrow(new ProvedorGeograficoIndisponivelException("Overpass indisponível"));

        standaloneMockMvc.perform(post("/api/v1/servicos/buscar")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(corpoValido))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.erro").value("PROVEDOR_GEOGRAFICO_INDISPONIVEL"));
    }

    @Test
    @DisplayName("Spring Security exige Bearer JWT (401) e aceita token válido nas duas rotas")
    void springSecurityExigeJwtEDespachaRotasReais() throws Exception {
        String corpoSemRegiao = "{\"categoria\":\"SAUDE\"}";

        int statusSemTokenV1 = springMockMvc.perform(post("/v1/servicos/buscar")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(corpoSemRegiao))
                .andReturn().getResponse().getStatus();
        int statusSemTokenApiV1 = springMockMvc.perform(post("/api/v1/servicos/buscar")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(corpoSemRegiao))
                .andReturn().getResponse().getStatus();

        assertThat(statusSemTokenV1).isEqualTo(401);
        assertThat(statusSemTokenApiV1).isEqualTo(401);

        String token = cadastrarEObterToken();
        for (String rota : List.of("/v1/servicos/buscar", "/api/v1/servicos/buscar")) {
            springMockMvc.perform(post(rota)
                            .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(corpoSemRegiao))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.erro").value("DADOS_INSUFICIENTES"));
        }
    }

    private String cadastrarEObterToken() throws Exception {
        String corpo = """
                {
                  "nome_tratamento": "Maria",
                  "canal": {"tipo": "email", "valor": "%s"},
                  "senha": "%s",
                  "modo_assistido": false
                }
                """.formatted(EMAIL_TESTE, SENHA_TESTE);

        MvcResult resultado = springMockMvc.perform(post("/v1/auth/cadastro")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(corpo))
                .andExpect(status().isCreated())
                .andReturn();

        return json.readTree(resultado.getResponse().getContentAsString())
                .get("token_acesso")
                .asText();
    }
}
