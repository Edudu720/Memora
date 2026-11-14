package br.fatec.memora.autenticacao.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import br.fatec.memora.autenticacao.aplicacao.EnviadorDeCodigo;
import br.fatec.memora.autenticacao.aplicacao.ServicoDeExpurgoDeContaPendente;
import br.fatec.memora.autenticacao.dominio.EstadoDaConta;
import br.fatec.memora.autenticacao.infra.RepositorioCanalContato;
import br.fatec.memora.autenticacao.infra.RepositorioCodigoVerificacao;
import br.fatec.memora.autenticacao.infra.RepositorioEventoAutenticacao;
import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
import br.fatec.memora.autenticacao.infra.RepositorioSessao;
import br.fatec.memora.suporte.TesteComBanco;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.ResultActions;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

/**
 * Testes de integração para o expurgo de contas assistidas abandonadas em
 * {@link EstadoDaConta#PENDENTE_VERIFICACAO} (T065b, FR-004 a FR-007 da Feature 006).
 */
@AutoConfigureMockMvc
@Import(ExpurgoDeContaPendenteTest.EnvioQueGuarda.class)
@DisplayName("T065b — expurgo seguro de contas assistidas abandonadas (> 24h)")
class ExpurgoDeContaPendenteTest extends TesteComBanco {

    private static final String EMAIL = "maria.assistida@gmail.com";
    private static final String SENHA_INICIAL = "pipoca no varal azul";
    private static final String SENHA_NOVA = "bolo de milho quentinho";

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper json;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private RepositorioEventoAutenticacao eventos;
    @Autowired private RepositorioSessao sessoes;
    @Autowired private RepositorioCodigoVerificacao codigos;
    @Autowired private RepositorioCanalContato canais;
    @Autowired private RepositorioPessoaUsuaria pessoas;
    @Autowired private ServicoDeExpurgoDeContaPendente servicoDeExpurgo;
    @Autowired private EnvioQueGuarda envio;

    @AfterEach
    void limpar() {
        envio.enviados.clear();
        eventos.deleteAll();
        codigos.deleteAll();
        sessoes.deleteAll();
        canais.deleteAll();
        pessoas.deleteAll();
    }

    @Test
    @DisplayName(
            "novo cadastro com o mesmo e-mail após 24h expurga a conta pendente abandonada e cria conta real")
    void novoCadastroExpurgaContaPendenteExpiradaECriaNovaConta() throws Exception {
        MvcResult abandonada =
                cadastrarCom("Dona Maria", EMAIL, SENHA_INICIAL, true)
                        .andExpect(status().isCreated())
                        .andReturn();
        UUID idAbandonada = UUID.fromString(corpoDe(abandonada).get("pessoa_id").asText());
        UUID canalAbandonado =
                UUID.fromString(corpoDe(abandonada).get("canal").get("id").asText());
        String tokenAbandonado = corpoDe(abandonada).get("token_acesso").asText();

        // Emite código de verificação para garantir que codigo_verificacao também é limpo em cascata
        pedirCodigo(tokenAbandonado, canalAbandonado).andExpect(status().isAccepted());
        assertThat(codigos.count()).isEqualTo(1);
        assertThat(eventos.findByPessoaIdOrderByOcorridoEmDesc(idAbandonada)).isNotEmpty();

        retroagirCriacao(idAbandonada, Duration.ofHours(25));

        MvcResult novoCadastro =
                cadastrarCom("Dona Maria", EMAIL, SENHA_NOVA, false)
                        .andExpect(status().isCreated())
                        .andReturn();
        UUID idNova = UUID.fromString(corpoDe(novoCadastro).get("pessoa_id").asText());

        assertThat(idNova).isNotEqualTo(idAbandonada);
        assertThat(pessoas.findById(idAbandonada)).isEmpty();
        assertThat(eventos.findByPessoaIdOrderByOcorridoEmDesc(idAbandonada)).isEmpty();
        assertThat(pessoas.findById(idNova)).isPresent();
        assertThat(pessoas.findById(idNova).get().getEstado()).isEqualTo(EstadoDaConta.ATIVA);

        entrarCom(EMAIL, SENHA_NOVA).andExpect(status().isOk());
    }

    @Test
    @DisplayName(
            "conta pendente recente (<= 24h) não é expurgada e novo cadastro recebe chamariz (FR-010)")
    void contaPendenteRecentePreservaChamarizENaoEExpurgada() throws Exception {
        MvcResult pendenteRecente =
                cadastrarCom("Dona Maria", EMAIL, SENHA_INICIAL, true)
                        .andExpect(status().isCreated())
                        .andReturn();
        UUID idOriginal = UUID.fromString(corpoDe(pendenteRecente).get("pessoa_id").asText());

        retroagirCriacao(idOriginal, Duration.ofHours(23));

        cadastrarCom("Outra Tentativa", EMAIL, SENHA_NOVA, false)
                .andExpect(status().isCreated());

        assertThat(pessoas.count()).isEqualTo(1);
        assertThat(pessoas.findById(idOriginal)).isPresent();
        assertThat(pessoas.findById(idOriginal).get().getEstado())
                .isEqualTo(EstadoDaConta.PENDENTE_VERIFICACAO);
    }

    @Test
    @DisplayName("conta ATIVA mesmo com mais de 24h jamais é expurgada e preserva chamariz")
    void contaAtivaAntigaPreservaChamarizENaoEExpurgada() throws Exception {
        MvcResult contaAtiva =
                cadastrarCom("Dona Maria", EMAIL, SENHA_INICIAL, false)
                        .andExpect(status().isCreated())
                        .andReturn();
        UUID idAtiva = UUID.fromString(corpoDe(contaAtiva).get("pessoa_id").asText());

        retroagirCriacao(idAtiva, Duration.ofHours(72));

        cadastrarCom("Impostor", EMAIL, SENHA_NOVA, false).andExpect(status().isCreated());

        assertThat(pessoas.count()).isEqualTo(1);
        assertThat(pessoas.findById(idAtiva)).isPresent();
        assertThat(pessoas.findById(idAtiva).get().getEstado()).isEqualTo(EstadoDaConta.ATIVA);
        entrarCom(EMAIL, SENHA_INICIAL).andExpect(status().isOk());
    }

    @Test
    @DisplayName(
            "rotina agendada expurga em lote apenas contas PENDENTE_VERIFICACAO com mais de 24h")
    void rotinaAgendadaExpurgaApenasContasPendentesVencidas() throws Exception {
        MvcResult expirada =
                cadastrarCom("Expirada", "expirada@gmail.com", SENHA_INICIAL, true)
                        .andExpect(status().isCreated())
                        .andReturn();
        UUID idExpirada = UUID.fromString(corpoDe(expirada).get("pessoa_id").asText());
        UUID canalExpirado = UUID.fromString(corpoDe(expirada).get("canal").get("id").asText());
        String tokenExpirado = corpoDe(expirada).get("token_acesso").asText();
        pedirCodigo(tokenExpirado, canalExpirado).andExpect(status().isAccepted());
        retroagirCriacao(idExpirada, Duration.ofHours(26));

        MvcResult recente =
                cadastrarCom("Recente", "recente@gmail.com", SENHA_INICIAL, true)
                        .andExpect(status().isCreated())
                        .andReturn();
        UUID idRecente = UUID.fromString(corpoDe(recente).get("pessoa_id").asText());
        retroagirCriacao(idRecente, Duration.ofHours(4));

        MvcResult ativa =
                cadastrarCom("Ativa", "ativa@gmail.com", SENHA_INICIAL, false)
                        .andExpect(status().isCreated())
                        .andReturn();
        UUID idAtiva = UUID.fromString(corpoDe(ativa).get("pessoa_id").asText());
        retroagirCriacao(idAtiva, Duration.ofHours(48));

        int expurgadas = servicoDeExpurgo.expurgarContasPendentesVencidas();

        assertThat(expurgadas).isEqualTo(1);
        assertThat(pessoas.findById(idExpirada)).isEmpty();
        assertThat(eventos.findByPessoaIdOrderByOcorridoEmDesc(idExpirada)).isEmpty();
        assertThat(pessoas.findById(idRecente)).isPresent();
        assertThat(pessoas.findById(idAtiva)).isPresent();
    }

    private void retroagirCriacao(UUID pessoaId, Duration idade) {
        Instant instantePassado = Instant.now().minus(idade);
        jdbc.update(
                "UPDATE pessoa_usuaria SET criada_em = ? WHERE id = ?",
                Timestamp.from(instantePassado),
                pessoaId);
    }

    private ResultActions cadastrarCom(
            String nome, String email, String senha, boolean modoAssistido) throws Exception {
        String corpo =
                """
                {
                  "nome_tratamento": "%s",
                  "canal": {"tipo": "email", "valor": "%s"},
                  "senha": "%s",
                  "modo_assistido": %s
                }
                """
                        .formatted(nome, email, senha, modoAssistido);

        return mockMvc.perform(
                post("/v1/auth/cadastro").contentType(MediaType.APPLICATION_JSON).content(corpo));
    }

    private ResultActions entrarCom(String identificador, String senha) throws Exception {
        String corpo =
                """
                {"identificador": "%s", "senha": "%s"}
                """
                        .formatted(identificador, senha);

        return mockMvc.perform(
                post("/v1/auth/entrar").contentType(MediaType.APPLICATION_JSON).content(corpo));
    }

    private ResultActions pedirCodigo(String token, UUID canalId) throws Exception {
        return mockMvc.perform(
                post("/v1/canais/{id}/codigo", canalId)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token));
    }

    private JsonNode corpoDe(MvcResult resultado) throws Exception {
        return json.readTree(resultado.getResponse().getContentAsString());
    }

    @TestConfiguration
    static class EnvioQueGuarda {

        final List<String> enviados = new ArrayList<>();

        @Bean
        @Primary
        EnviadorDeCodigo enviadorQueGuarda() {
            return (canal, codigoEmClaro) -> enviados.add(codigoEmClaro);
        }
    }
}
