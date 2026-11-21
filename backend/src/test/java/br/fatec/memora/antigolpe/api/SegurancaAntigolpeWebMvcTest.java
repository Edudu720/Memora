package br.fatec.memora.antigolpe.api;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import br.fatec.memora.antigolpe.api.dto.AnalisarGolpeResponse;
import br.fatec.memora.antigolpe.aplicacao.ServicoAnaliseGolpe;
import br.fatec.memora.antigolpe.dominio.NivelRiscoGolpe;
import br.fatec.memora.autenticacao.api.ConfiguracaoDeSegurancaWeb;
import br.fatec.memora.autenticacao.dominio.EstadoDaConta;
import br.fatec.memora.autenticacao.dominio.PessoaUsuaria;
import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
import br.fatec.memora.autenticacao.seguranca.EmissorDeTokenDeAcesso;
import br.fatec.memora.comum.TratadorGlobalDeErros;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(controllers = ControladorAnaliseGolpe.class)
@Import({ConfiguracaoDeSegurancaWeb.class, TratadorGlobalDeErros.class})
@DisplayName("Segurança Web — POST /v1/golpes/analisar protegido por JWT real sem Docker")
class SegurancaAntigolpeWebMvcTest {

    @Autowired private MockMvc mockMvc;

    @MockitoBean private EmissorDeTokenDeAcesso emissor;
    @MockitoBean private RepositorioPessoaUsuaria pessoas;
    @MockitoBean private ServicoAnaliseGolpe servico;

    @Test
    @DisplayName("requisição sem token retorna 401 SESSAO_EXPIRADA")
    void semTokenRetorna401() throws Exception {
        mockMvc.perform(
                        post("/v1/golpes/analisar")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"conteudo\": \"Oi\"}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.codigo").value("SESSAO_EXPIRADA"));
    }

    @Test
    @DisplayName("token inválido retorna 401 SESSAO_EXPIRADA")
    void tokenInvalidoRetorna401() throws Exception {
        when(emissor.sujeitoDoToken("token-invalido")).thenReturn(Optional.empty());

        mockMvc.perform(
                        post("/v1/golpes/analisar")
                                .header(HttpHeaders.AUTHORIZATION, "Bearer token-invalido")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"conteudo\": \"Oi\"}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.codigo").value("SESSAO_EXPIRADA"));
    }

    @Test
    @DisplayName("token válido de usuário inexistente (chamariz) retorna 401 SESSAO_EXPIRADA")
    void usuarioDesconhecidoRetorna401() throws Exception {
        UUID pessoaId = UUID.randomUUID();
        when(emissor.sujeitoDoToken("token-chamariz"))
                .thenReturn(
                        Optional.of(
                                new EmissorDeTokenDeAcesso.SujeitoDoToken(
                                        pessoaId, UUID.randomUUID())));
        when(pessoas.findById(pessoaId)).thenReturn(Optional.empty());

        mockMvc.perform(
                        post("/v1/golpes/analisar")
                                .header(HttpHeaders.AUTHORIZATION, "Bearer token-chamariz")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"conteudo\": \"Oi\"}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.codigo").value("SESSAO_EXPIRADA"));
    }

    @Test
    @DisplayName("usuário DESATIVADA retorna 401 SESSAO_EXPIRADA")
    void usuarioDesativadoRetorna401() throws Exception {
        UUID pessoaId = UUID.randomUUID();
        PessoaUsuaria contaDesativada =
                new PessoaUsuaria("Maria", null, Instant.parse("2026-01-01T00:00:00Z"));
        ReflectionTestUtils.setField(contaDesativada, "id", pessoaId);
        contaDesativada.desativar();

        when(emissor.sujeitoDoToken("token-desativado"))
                .thenReturn(
                        Optional.of(
                                new EmissorDeTokenDeAcesso.SujeitoDoToken(
                                        pessoaId, UUID.randomUUID())));
        when(pessoas.findById(pessoaId)).thenReturn(Optional.of(contaDesativada));

        mockMvc.perform(
                        post("/v1/golpes/analisar")
                                .header(HttpHeaders.AUTHORIZATION, "Bearer token-desativado")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"conteudo\": \"Oi\"}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.codigo").value("SESSAO_EXPIRADA"));
    }

    @Test
    @DisplayName("usuário PENDENTE_VERIFICACAO é recusado pelo controlador com 401 SESSAO_EXPIRADA")
    void usuarioPendenteRetorna401() throws Exception {
        UUID pessoaId = UUID.randomUUID();
        PessoaUsuaria contaPendente =
                new PessoaUsuaria(
                        "Maria",
                        null,
                        Instant.parse("2026-01-01T00:00:00Z"),
                        EstadoDaConta.PENDENTE_VERIFICACAO);
        ReflectionTestUtils.setField(contaPendente, "id", pessoaId);

        when(emissor.sujeitoDoToken("token-pendente"))
                .thenReturn(
                        Optional.of(
                                new EmissorDeTokenDeAcesso.SujeitoDoToken(
                                        pessoaId, UUID.randomUUID())));
        when(pessoas.findById(pessoaId)).thenReturn(Optional.of(contaPendente));

        mockMvc.perform(
                        post("/v1/golpes/analisar")
                                .header(HttpHeaders.AUTHORIZATION, "Bearer token-pendente")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"conteudo\": \"Oi\"}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.codigo").value("SESSAO_EXPIRADA"));
    }

    @Test
    @DisplayName("usuário ATIVA com Bearer JWT válido recebe 200 OK")
    void usuarioAtivaRecebe200() throws Exception {
        UUID pessoaId = UUID.randomUUID();
        PessoaUsuaria contaAtiva =
                new PessoaUsuaria("Maria", null, Instant.parse("2026-01-01T00:00:00Z"));
        ReflectionTestUtils.setField(contaAtiva, "id", pessoaId);

        when(emissor.sujeitoDoToken("token-valido"))
                .thenReturn(
                        Optional.of(
                                new EmissorDeTokenDeAcesso.SujeitoDoToken(
                                        pessoaId, UUID.randomUUID())));
        when(pessoas.findById(pessoaId)).thenReturn(Optional.of(contaAtiva));
        when(servico.analisar(eq(pessoaId), eq("Mensagem normal")))
                .thenReturn(
                        new AnalisarGolpeResponse(
                                NivelRiscoGolpe.BAIXO,
                                "Não encontrei sinais claros de golpe.",
                                "Continue com cuidado.",
                                List.of("Confirme se tiver dúvida."),
                                List.of(),
                                false));

        mockMvc.perform(
                        post("/v1/golpes/analisar")
                                .header(HttpHeaders.AUTHORIZATION, "Bearer token-valido")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"conteudo\": \"Mensagem normal\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.risco").value("BAIXO"))
                .andExpect(jsonPath("$.analisadoPorIa").value(false));
    }
}
