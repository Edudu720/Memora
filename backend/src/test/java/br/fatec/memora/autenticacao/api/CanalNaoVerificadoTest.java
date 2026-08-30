package br.fatec.memora.autenticacao.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import br.fatec.memora.autenticacao.aplicacao.EnviadorDeCodigo;
import br.fatec.memora.autenticacao.dominio.CanalContato;
import br.fatec.memora.autenticacao.dominio.EstadoDaConta;
import br.fatec.memora.autenticacao.dominio.PessoaUsuaria;
import br.fatec.memora.autenticacao.infra.RepositorioCanalContato;
import br.fatec.memora.autenticacao.infra.RepositorioCodigoVerificacao;
import br.fatec.memora.autenticacao.infra.RepositorioEventoAutenticacao;
import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
import br.fatec.memora.autenticacao.infra.RepositorioSessao;
import br.fatec.memora.suporte.TesteComBanco;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.ResultActions;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

/**
 * Cenário V4 do quickstart — canal não verificado não dá controle da conta
 * (T060).
 *
 * <p><b>Cobre FR-052 e FR-062</b>, a defesa contra o familiar que cadastra a
 * conta da pessoa idosa apontando o próprio contato como canal e passa a
 * controlar a recuperação — ou seja, a conta.
 *
 * <p>O passo 5 do V4 é literal: <i>"o cadastro assistido não conclui sem posse
 * confirmada"</i>. Aqui isso é observável de três formas independentes, e
 * qualquer uma que caia derruba a proteção: a conta fica
 * {@link EstadoDaConta#PENDENTE_VERIFICACAO}, a entrada é recusada, e o canal
 * continua {@code verificado = false}.
 */
@AutoConfigureMockMvc
@Import(CanalNaoVerificadoTest.EnvioQueGuarda.class)
@DisplayName("V4 — canal não verificado não recupera acesso")
class CanalNaoVerificadoTest extends TesteComBanco {

    private static final String EMAIL = "ana@gmail.com";

    private static final String SENHA = "pipoca no varal azul";

    @Autowired private MockMvc mockMvc;

    @Autowired private ObjectMapper json;

    @Autowired private RepositorioEventoAutenticacao eventos;

    @Autowired private RepositorioSessao sessoes;

    @Autowired private RepositorioCodigoVerificacao codigos;

    @Autowired private RepositorioCanalContato canais;

    @Autowired private RepositorioPessoaUsuaria pessoas;

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

    @Nested
    @DisplayName("O cadastro assistido não conclui sozinho (FR-062)")
    class NaoConclui {

        @Test
        @DisplayName("a conta nasce pendente de verificação")
        void contaNascePendente() throws Exception {
            cadastrarAssistido();

            assertThat(pessoas.findAll().getFirst().getEstado())
                    .isEqualTo(EstadoDaConta.PENDENTE_VERIFICACAO);
        }

        @Test
        @DisplayName("o canal nasce sem posse confirmada")
        void canalNasceNaoVerificado() throws Exception {
            cadastrarAssistido();

            assertThat(canais.findAll().getFirst().isVerificado()).isFalse();
        }

        /**
         * O ponto do V4. Se esta entrada passar, o acompanhante sai da mesa com
         * uma conta utilizável apontando para o contato dele — que é exatamente
         * o cenário que a FR-062 existe para impedir.
         */
        @Test
        @DisplayName("entrar é recusado enquanto a posse não for confirmada")
        void naoEntraAntesDeVerificar() throws Exception {
            cadastrarAssistido();

            entrar().andExpect(status().isUnauthorized());
        }

        /**
         * A recusa não conta o motivo. Dizer "confirme seu canal" informaria a
         * quem tentou a senha de outra pessoa que aquele identificador tem conta
         * — a FR-013 pelo avesso.
         */
        @Test
        @DisplayName("a recusa não revela que a conta existe e está pendente")
        void recusaGenerica() throws Exception {
            cadastrarAssistido();

            entrar().andExpect(jsonPath("$.codigo").value("CREDENCIAIS_INVALIDAS"));
        }

        /**
         * O caminho lateral que a revisão da PR #15 já encontrou uma vez, agora
         * com outro estado: cinco senhas erradas chamam
         * {@code PessoaUsuaria.bloquearAte}, e sem a guarda de
         * {@code EstadoDaConta.ehDeCicloDeVida()} isso sobrescreveria
         * {@code PENDENTE_VERIFICACAO} com {@code BLOQUEADA_TEMPORARIAMENTE}.
         *
         * <p>O efeito seria a FR-062 caindo por conta própria: passado o minuto
         * da tranca, a conta assistida entraria normalmente, sem que ninguém
         * tivesse confirmado canal nenhum. O acompanhante conseguiria isso
         * <b>de propósito</b>, errando a senha cinco vezes e esperando.
         */
        @Test
        @DisplayName("errar a senha cinco vezes não tira a conta do estado pendente")
        void bloqueioNaoConcluiCadastroAssistido() throws Exception {
            cadastrarAssistido();

            for (int tentativa = 0; tentativa < 5; tentativa++) {
                entrarComSenhaErrada();
            }

            assertThat(pessoas.findAll().getFirst().getEstado())
                    .isEqualTo(EstadoDaConta.PENDENTE_VERIFICACAO);
        }
    }

    @Nested
    @DisplayName("Cadastro comum segue liberado")
    class SemAcompanhante {

        @Test
        @DisplayName("sem modo assistido a conta nasce ativa e entra")
        void contaComumEntra() throws Exception {
            cadastrar(false);

            assertThat(pessoas.findAll().getFirst().getEstado()).isEqualTo(EstadoDaConta.ATIVA);
            entrar().andExpect(status().isOk());
        }
    }

    @Nested
    @DisplayName("Confirmar a posse conclui o cadastro (T057, T058)")
    class Conclui {

        @Test
        @DisplayName("com o código certo, o canal fica verificado")
        void verificaCanal() throws Exception {
            String token = tokenDe(cadastrarAssistido().andReturn());
            UUID canalId = canais.findAll().getFirst().getId();

            pedirCodigo(token, canalId).andExpect(status().isAccepted());
            verificar(token, canalId, envio.ultimoCodigo())
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.verificado").value(true));
        }

        @Test
        @DisplayName("a conta deixa de ser pendente e passa a entrar")
        void contaPassaASerAtiva() throws Exception {
            String token = tokenDe(cadastrarAssistido().andReturn());
            UUID canalId = canais.findAll().getFirst().getId();

            pedirCodigo(token, canalId);
            verificar(token, canalId, envio.ultimoCodigo());

            assertThat(pessoas.findAll().getFirst().getEstado()).isEqualTo(EstadoDaConta.ATIVA);
            entrar().andExpect(status().isOk());
        }

        @Test
        @DisplayName("código errado não verifica nada")
        void codigoErrado() throws Exception {
            String token = tokenDe(cadastrarAssistido().andReturn());
            UUID canalId = canais.findAll().getFirst().getId();
            pedirCodigo(token, canalId);

            verificar(token, canalId, errarUmDigito(envio.ultimoCodigo()))
                    .andExpect(status().isBadRequest());

            assertThat(canais.findAll().getFirst().isVerificado()).isFalse();
            assertThat(pessoas.findAll().getFirst().getEstado())
                    .isEqualTo(EstadoDaConta.PENDENTE_VERIFICACAO);
        }

        /** Uso único (FR-020): o mesmo código não serve duas vezes. */
        @Test
        @DisplayName("o código não pode ser usado de novo")
        void usoUnico() throws Exception {
            String token = tokenDe(cadastrarAssistido().andReturn());
            UUID canalId = canais.findAll().getFirst().getId();
            pedirCodigo(token, canalId);
            String codigo = envio.ultimoCodigo();
            verificar(token, canalId, codigo);

            verificar(token, canalId, codigo).andExpect(status().isBadRequest());
        }

        /** Pedir outro invalida o anterior — senão dois códigos vivos dobram a chance. */
        @Test
        @DisplayName("pedir código novo invalida o anterior")
        void codigoNovoInvalidaAnterior() throws Exception {
            String token = tokenDe(cadastrarAssistido().andReturn());
            UUID canalId = canais.findAll().getFirst().getId();

            pedirCodigo(token, canalId);
            String primeiro = envio.ultimoCodigo();
            pedirCodigo(token, canalId);

            verificar(token, canalId, primeiro).andExpect(status().isBadRequest());
            verificar(token, canalId, envio.ultimoCodigo()).andExpect(status().isOk());
        }
    }

    @Nested
    @DisplayName("A sessão-chamariz não vira acesso")
    class Chamariz {

        /**
         * O cadastro contra canal já existente devolve um JWT assinado por nós
         * para um sujeito que não existe (FR-010). Este é o teste que prova que
         * ele não abre caminho autenticado nenhum: se o filtro parasse na
         * assinatura, o chamariz viraria acesso.
         */
        @Test
        @DisplayName("o token do chamariz não autentica")
        void chamarizNaoAutentica() throws Exception {
            cadastrar(false);
            String doChamariz = tokenDe(cadastrar(false).andReturn());
            UUID canalDeOutra = canais.findAll().getFirst().getId();

            pedirCodigo(doChamariz, canalDeOutra).andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("sem token nenhum, também não")
        void semTokenNaoAutentica() throws Exception {
            cadastrar(false);
            UUID canalId = canais.findAll().getFirst().getId();

            mockMvc.perform(post("/v1/canais/{id}/codigo", canalId))
                    .andExpect(status().isUnauthorized())
                    .andExpect(jsonPath("$.codigo").value("SESSAO_EXPIRADA"));
        }
    }

    @Nested
    @DisplayName("Canal de outra conta")
    class CanalAlheio {

        /**
         * Estar autenticada não dá acesso a canal alheio. O {@code canalId} vem
         * da URL, e nada na URL é confiável.
         */
        @Test
        @DisplayName("pedir código para canal de outra pessoa não envia nada")
        void naoEnviaParaCanalAlheio() throws Exception {
            cadastrar(false);
            UUID canalDaAna = canais.findAll().getFirst().getId();
            String tokenDoBeto = tokenDe(cadastrarOutra().andReturn());

            pedirCodigo(tokenDoBeto, canalDaAna).andExpect(status().isAccepted());

            assertThat(envio.enviados).isEmpty();
        }

        @Test
        @DisplayName("verificar canal alheio é recusado")
        void naoVerificaCanalAlheio() throws Exception {
            String tokenDaAna = tokenDe(cadastrar(false).andReturn());
            UUID canalDaAna = canais.findAll().getFirst().getId();
            pedirCodigo(tokenDaAna, canalDaAna);
            String codigoDaAna = envio.ultimoCodigo();

            String tokenDoBeto = tokenDe(cadastrarOutra().andReturn());

            verificar(tokenDoBeto, canalDaAna, codigoDaAna)
                    .andExpect(status().isBadRequest());
            assertThat(canais.findById(canalDaAna).orElseThrow().isVerificado()).isFalse();
        }
    }

    // --- apoio ---------------------------------------------------------------

    private ResultActions cadastrarAssistido() throws Exception {
        return cadastrar(true);
    }

    private ResultActions cadastrar(boolean modoAssistido) throws Exception {
        return cadastrarCom("Ana", EMAIL, modoAssistido);
    }

    private ResultActions cadastrarOutra() throws Exception {
        return cadastrarCom("Beto", "beto@gmail.com", false);
    }

    private ResultActions cadastrarCom(String nome, String email, boolean modoAssistido)
            throws Exception {
        String corpo =
                """
                {
                  "nome_tratamento": "%s",
                  "canal": {"tipo": "email", "valor": "%s"},
                  "senha": "%s",
                  "modo_assistido": %s
                }
                """
                        .formatted(nome, email, SENHA, modoAssistido);

        return mockMvc.perform(
                post("/v1/auth/cadastro").contentType(MediaType.APPLICATION_JSON).content(corpo));
    }

    private ResultActions entrar() throws Exception {
        return entrarCom(SENHA);
    }

    private ResultActions entrarComSenhaErrada() throws Exception {
        return entrarCom("nao e essa a senha dela");
    }

    private ResultActions entrarCom(String senha) throws Exception {
        String corpo =
                """
                {"identificador": "%s", "senha": "%s"}
                """
                        .formatted(EMAIL, senha);

        return mockMvc.perform(
                post("/v1/auth/entrar").contentType(MediaType.APPLICATION_JSON).content(corpo));
    }

    private ResultActions pedirCodigo(String token, UUID canalId) throws Exception {
        return mockMvc.perform(
                post("/v1/canais/{id}/codigo", canalId)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token));
    }

    private ResultActions verificar(String token, UUID canalId, String codigo) throws Exception {
        return mockMvc.perform(
                post("/v1/canais/{id}/verificar", canalId)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"codigo": "%s"}
                                """.formatted(codigo)));
    }

    private String tokenDe(MvcResult resultado) throws Exception {
        return corpoDe(resultado).get("token_acesso").asText();
    }

    private JsonNode corpoDe(MvcResult resultado) throws Exception {
        return json.readTree(resultado.getResponse().getContentAsString());
    }

    private static String errarUmDigito(String codigo) {
        char primeiro = codigo.charAt(0);
        char trocado = primeiro == '9' ? '0' : (char) (primeiro + 1);
        return trocado + codigo.substring(1);
    }

    /**
     * Guarda o que seria enviado, em vez de enviar.
     *
     * <p>É o único jeito de o teste conhecer o código: no banco ele está
     * hasheado com Argon2, e é essa a garantia que a T059 pede. Um teste que
     * conseguisse ler o código do banco estaria provando o contrário do que
     * deveria.
     */
    @TestConfiguration
    static class EnvioQueGuarda {

        final List<String> enviados = new ArrayList<>();

        @Bean
        @Primary
        EnviadorDeCodigo enviadorQueGuarda() {
            return (canal, codigoEmClaro) -> enviados.add(codigoEmClaro);
        }

        String ultimoCodigo() {
            return enviados.getLast();
        }
    }
}
