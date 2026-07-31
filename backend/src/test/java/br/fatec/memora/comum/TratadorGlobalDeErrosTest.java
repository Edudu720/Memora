package br.fatec.memora.comum;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.hamcrest.Matchers;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Tratamento global de erro (T024, FR-041).
 *
 * <p>Sem contexto do Spring e sem banco: o alvo aqui e a conversao de excecao em
 * resposta, e um controller de mentira exercita todos os caminhos em
 * milissegundos.
 *
 * <p>O teste que mais importa e {@code detalheInternoNaoVazaNaResposta}. Ele
 * lanca uma excecao cuja mensagem tem nome de constraint e de tabela — o formato
 * exato do que o Hibernate produz — e verifica que nada disso aparece no corpo.
 */
@DisplayName("Tratamento global de erro")
class TratadorGlobalDeErrosTest {

    private MockMvc mockMvc;

    @BeforeEach
    void montar() {
        mockMvc =
                MockMvcBuilders.standaloneSetup(new ControladorDeMentira())
                        .setControllerAdvice(new TratadorGlobalDeErros())
                        .build();
    }

    @Nested
    @DisplayName("Falha prevista")
    class FalhaPrevista {

        @Test
        @DisplayName("sai com o codigo, o status e o texto do contrato")
        void codigoStatusETexto() throws Exception {
            mockMvc.perform(get("/mentira/credenciais-invalidas"))
                    .andExpect(status().isUnauthorized())
                    .andExpect(jsonPath("$.codigo").value("CREDENCIAIS_INVALIDAS"))
                    .andExpect(
                            jsonPath("$.mensagem")
                                    .value(CodigoDeErro.CREDENCIAIS_INVALIDAS.mensagemPadrao()));
        }

        @Test
        @DisplayName("bloqueio traz a espera em tentar_novamente_em_segundos")
        void bloqueioTrazEspera() throws Exception {
            mockMvc.perform(get("/mentira/bloqueio"))
                    .andExpect(status().isTooManyRequests())
                    .andExpect(jsonPath("$.codigo").value("MUITAS_TENTATIVAS"))
                    .andExpect(jsonPath("$.tentar_novamente_em_segundos").value(300));
        }

        @Test
        @DisplayName("erro sem espera omite o campo, em vez de mandar nulo")
        void semEsperaOmiteOCampo() throws Exception {
            mockMvc.perform(get("/mentira/credenciais-invalidas"))
                    .andExpect(jsonPath("$.tentar_novamente_em_segundos").doesNotExist());
        }

        @Test
        @DisplayName("mensagem propria do caso concreto chega a pessoa")
        void mensagemPropria() throws Exception {
            mockMvc.perform(get("/mentira/mensagem-propria"))
                    .andExpect(jsonPath("$.mensagem").value(ControladorDeMentira.TEXTO_PROPRIO));
        }
    }

    @Nested
    @DisplayName("Falha inesperada")
    class FalhaInesperada {

        /**
         * O cenario real: excecao de integridade do banco, cuja mensagem descreve
         * o esquema. Se qualquer pedaco dela sair na resposta, a FR-041 caiu — e
         * junto com ela a FR-010, porque o nome da constraint de unicidade
         * denuncia que aquele canal ja pertence a alguem.
         */
        @Test
        @DisplayName("detalhe interno nao vaza na resposta")
        void detalheInternoNaoVazaNaResposta() throws Exception {
            mockMvc.perform(get("/mentira/vazamento"))
                    .andExpect(status().isInternalServerError())
                    .andExpect(jsonPath("$.codigo").value("ERRO_INESPERADO"))
                    .andExpect(
                            content()
                                    .string(
                                            Matchers.not(
                                                    Matchers.containsString(
                                                            "uq_canal_tipo_valor"))))
                    .andExpect(
                            content()
                                    .string(
                                            Matchers.not(
                                                    Matchers.containsString("canal_contato"))))
                    .andExpect(
                            content()
                                    .string(Matchers.not(Matchers.containsString("Exception"))));
        }

        @Test
        @DisplayName("o texto devolvido nao culpa a pessoa")
        void textoNaoCulpaAPessoa() throws Exception {
            mockMvc.perform(get("/mentira/vazamento"))
                    .andExpect(
                            jsonPath("$.mensagem")
                                    .value(CodigoDeErro.ERRO_INESPERADO.mensagemPadrao()));
        }
    }

    @Nested
    @DisplayName("Dado invalido")
    class DadoInvalido {

        @Test
        @DisplayName("corpo reprovado na validacao vira DADOS_INVALIDOS")
        void corpoReprovado() throws Exception {
            mockMvc.perform(
                            post("/mentira/validado")
                                    .contentType(MediaType.APPLICATION_JSON)
                                    .content("{\"nome\":\"\",\"senha\":\"curta\"}"))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.codigo").value("DADOS_INVALIDOS"));
        }

        @Test
        @DisplayName("a resposta nao enumera os campos reprovados")
        void naoEnumeraCampos() throws Exception {
            mockMvc.perform(
                            post("/mentira/validado")
                                    .contentType(MediaType.APPLICATION_JSON)
                                    .content("{\"nome\":\"\",\"senha\":\"curta\"}"))
                    .andExpect(content().string(Matchers.not(Matchers.containsString("senha"))))
                    .andExpect(content().string(Matchers.not(Matchers.containsString("nome"))));
        }

        @Test
        @DisplayName("JSON malformado vira DADOS_INVALIDOS, nao erro inesperado")
        void jsonMalformado() throws Exception {
            mockMvc.perform(
                            post("/mentira/validado")
                                    .contentType(MediaType.APPLICATION_JSON)
                                    .content("{isto nao e json"))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.codigo").value("DADOS_INVALIDOS"));
        }
    }

    /** Corpo qualquer, so para exercitar a validacao. */
    record CorpoValidado(@NotBlank String nome, @Size(min = 10) String senha) {}

    @RestController
    @RequestMapping("/mentira")
    static class ControladorDeMentira {

        static final String TEXTO_PROPRIO = "Esse numero de telefone parece incompleto. Vamos conferir? 😊";

        @org.springframework.web.bind.annotation.GetMapping("/credenciais-invalidas")
        void credenciaisInvalidas() {
            throw FalhaDoMemora.de(CodigoDeErro.CREDENCIAIS_INVALIDAS);
        }

        @org.springframework.web.bind.annotation.GetMapping("/bloqueio")
        void bloqueio() {
            throw FalhaDoMemora.bloqueio(300);
        }

        @org.springframework.web.bind.annotation.GetMapping("/mensagem-propria")
        void mensagemPropria() {
            throw FalhaDoMemora.de(CodigoDeErro.DADOS_INVALIDOS, TEXTO_PROPRIO);
        }

        @org.springframework.web.bind.annotation.GetMapping("/vazamento")
        void vazamento() {
            throw new IllegalStateException(
                    "ERROR: duplicate key value violates unique constraint "
                            + "\"uq_canal_tipo_valor\" na tabela canal_contato");
        }

        @PostMapping("/validado")
        void validado(@Valid @RequestBody CorpoValidado corpo) {
            // Nunca chega aqui nos testes: o corpo enviado sempre reprova.
        }
    }
}
