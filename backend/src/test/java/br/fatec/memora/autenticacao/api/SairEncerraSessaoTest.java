package br.fatec.memora.autenticacao.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import br.fatec.memora.autenticacao.dominio.TipoDeEvento;
import br.fatec.memora.autenticacao.infra.RepositorioCanalContato;
import br.fatec.memora.autenticacao.infra.RepositorioCodigoVerificacao;
import br.fatec.memora.autenticacao.infra.RepositorioEventoAutenticacao;
import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
import br.fatec.memora.autenticacao.infra.RepositorioSessao;
import br.fatec.memora.suporte.TesteComBanco;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.ResultActions;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

/**
 * Sair encerra este aparelho, e só este (T074, FR-024, FR-026).
 *
 * <h2>O que precisa ser verdade ao mesmo tempo</h2>
 *
 * Sair é uma operação de duas metades que se contradizem se qualquer uma
 * falhar: precisa encerrar de verdade — senão o refresh de 60 dias que o
 * aplicativo tem em mãos continua abrindo a conta — e precisa encerrar
 * <b>só o aparelho de quem pediu</b>, senão "sair" vira "derrubar todos os meus
 * aparelhos", que é outra funcionalidade.
 *
 * <p>Os dois lados estão aqui, e cada um sozinho passaria numa implementação
 * errada: revogar tudo satisfaz o primeiro, revogar nada satisfaz o segundo.
 */
@AutoConfigureMockMvc
@DisplayName("Sair encerra a sessão deste aparelho")
class SairEncerraSessaoTest extends TesteComBanco {

    private static final String EMAIL = "ana@gmail.com";

    private static final String SENHA = "pipoca no varal azul";

    @Autowired private MockMvc mockMvc;

    @Autowired private ObjectMapper json;

    @Autowired private RepositorioEventoAutenticacao eventos;

    @Autowired private RepositorioSessao sessoes;

    @Autowired private RepositorioCodigoVerificacao codigos;

    @Autowired private RepositorioCanalContato canais;

    @Autowired private RepositorioPessoaUsuaria pessoas;

    @AfterEach
    void limpar() {
        eventos.deleteAll();
        codigos.deleteAll();
        sessoes.deleteAll();
        canais.deleteAll();
        pessoas.deleteAll();
    }

    @Nested
    @DisplayName("Encerra de verdade")
    class Encerra {

        @Test
        @DisplayName("responde 204")
        void respondeSemConteudo() throws Exception {
            cadastrar();
            MvcResult sessao = entrar("Celular").andReturn();

            sair(tokenDe(sessao)).andExpect(status().isNoContent());
        }

        /**
         * O ponto da operação. Se este teste passar com a revogação desligada, o
         * "sair" é decorativo: o refresh continua abrindo a conta por 60 dias.
         */
        @Test
        @DisplayName("o refresh token deixa de renovar")
        void refreshMorre() throws Exception {
            cadastrar();
            MvcResult sessao = entrar("Celular").andReturn();
            String refresh = refreshDe(sessao);

            sair(tokenDe(sessao));

            renovar(refresh).andExpect(status().isUnauthorized());
        }

        @Test
        @DisplayName("a sessão fica marcada como revogada no banco")
        void revogadaNoBanco() throws Exception {
            cadastrar();
            MvcResult sessao = entrar("Celular").andReturn();

            sair(tokenDe(sessao));

            assertThat(sessoes.findAll())
                    .filteredOn(s -> "Celular".equals(s.getAparelhoDescricao()))
                    .allSatisfy(s -> assertThat(s.getRevogadaEm()).isNotNull());
        }

        /** A trilha da FR-039 registra a saída. */
        @Test
        @DisplayName("a saída fica na trilha de auditoria")
        void registraNaTrilha() throws Exception {
            cadastrar();
            MvcResult sessao = entrar("Celular").andReturn();

            sair(tokenDe(sessao));

            assertThat(eventos.findAll())
                    .anySatisfy(e -> assertThat(e.getTipo()).isEqualTo(TipoDeEvento.SAIDA));
        }

        /**
         * A rotação cria uma linha de sessão nova a cada renovação. Se `sair`
         * revogasse a linha em vez da família, bastaria ter renovado uma vez
         * para o encerramento não alcançar o token em uso.
         */
        @Test
        @DisplayName("encerra mesmo depois de a sessão ter sido renovada")
        void encerraDepoisDeRotacionar() throws Exception {
            cadastrar();
            MvcResult inicial = entrar("Celular").andReturn();

            MvcResult renovada = renovar(refreshDe(inicial)).andReturn();
            String refreshNovo = refreshDe(renovada);
            String tokenNovo = tokenDe(renovada);

            sair(tokenNovo).andExpect(status().isNoContent());

            renovar(refreshNovo).andExpect(status().isUnauthorized());
        }
    }

    @Nested
    @DisplayName("Encerra só este aparelho")
    class SoEsteAparelho {

        /**
         * O outro lado. Sem ele, uma implementação que revogasse tudo passaria
         * em todos os testes acima — e a pessoa que saiu do tablet da filha
         * descobriria que o próprio celular também caiu.
         */
        @Test
        @DisplayName("a sessão do outro aparelho continua valendo")
        void outroAparelhoSobrevive() throws Exception {
            cadastrar();
            MvcResult celular = entrar("Celular").andReturn();
            MvcResult tablet = entrar("Tablet").andReturn();

            sair(tokenDe(celular));

            renovar(refreshDe(tablet)).andExpect(status().isOk());
        }

        @Test
        @DisplayName("a sessão do outro aparelho não é marcada no banco")
        void outroAparelhoIntactoNoBanco() throws Exception {
            cadastrar();
            MvcResult celular = entrar("Celular").andReturn();
            entrar("Tablet");

            sair(tokenDe(celular));

            assertThat(sessoes.findAll())
                    .filteredOn(s -> "Tablet".equals(s.getAparelhoDescricao()))
                    .allSatisfy(s -> assertThat(s.getRevogadaEm()).isNull());
        }

        /** Sair de uma conta não pode encostar na sessão de outra pessoa. */
        @Test
        @DisplayName("a sessão de outra conta não é tocada")
        void contaAlheiaIntacta() throws Exception {
            cadastrar();
            MvcResult daAna = entrar("Celular").andReturn();
            MvcResult doBeto = cadastrarBeto().andReturn();

            sair(tokenDe(daAna));

            renovar(refreshDe(doBeto)).andExpect(status().isOk());
        }
    }

    @Nested
    @DisplayName("Quem pode sair")
    class QuemPodeSair {

        @Test
        @DisplayName("sem token, 401")
        void semToken() throws Exception {
            mockMvc.perform(post("/v1/auth/sair")).andExpect(status().isUnauthorized());
        }

        /**
         * A sessão-chamariz é um JWT assinado por nós para um sujeito que não
         * existe. Se `sair` a aceitasse, não haveria dano direto — não há o que
         * revogar —, mas a resposta `204` diria a quem cadastrou com o e-mail
         * alheio que aquele token é aceito em algum lugar. Ele não é.
         */
        @Test
        @DisplayName("o token do chamariz não sai de lugar nenhum")
        void chamarizNaoSai() throws Exception {
            cadastrar();
            String doChamariz = tokenDe(cadastrar().andReturn());

            sair(doChamariz).andExpect(status().isUnauthorized());
        }

        /**
         * Quem está no meio do cadastro assistido precisa poder desistir.
         * Impedir a saída prenderia a pessoa exatamente no fluxo que a FR-062
         * quer que ela consiga abandonar — e sair só revoga, nunca concede.
         */
        @Test
        @DisplayName("conta pendente de verificação também consegue sair")
        void contaPendenteSai() throws Exception {
            MvcResult assistido = cadastrarAssistido().andReturn();

            sair(tokenDe(assistido)).andExpect(status().isNoContent());
        }
    }

    @Nested
    @DisplayName("Sair duas vezes não é erro")
    class Idempotente {

        /**
         * O aplicativo pode ter perdido a resposta da primeira chamada. Se a
         * segunda falhasse, a pessoa ficaria presa numa tela de saída que não
         * termina — e para quem não conseguiu sair, o pior desfecho não é sair
         * duas vezes, é continuar dentro.
         */
        @Test
        @DisplayName("a segunda chamada responde igual")
        void segundaChamadaResponde204() throws Exception {
            cadastrar();
            MvcResult sessao = entrar("Celular").andReturn();
            String token = tokenDe(sessao);

            sair(token).andExpect(status().isNoContent());
            sair(token).andExpect(status().isNoContent());
        }
    }

    // --- apoio ---------------------------------------------------------------

    private ResultActions cadastrar() throws Exception {
        return cadastrarCom("Ana", EMAIL, false);
    }

    private ResultActions cadastrarBeto() throws Exception {
        return cadastrarCom("Beto", "beto@gmail.com", false);
    }

    private ResultActions cadastrarAssistido() throws Exception {
        return cadastrarCom("Ana", EMAIL, true);
    }

    private ResultActions cadastrarCom(String nome, String email, boolean assistido)
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
                        .formatted(nome, email, SENHA, assistido);

        return mockMvc.perform(
                post("/v1/auth/cadastro").contentType(MediaType.APPLICATION_JSON).content(corpo));
    }

    private ResultActions entrar(String aparelho) throws Exception {
        String corpo =
                """
                {"identificador": "%s", "senha": "%s", "aparelho_descricao": "%s"}
                """
                        .formatted(EMAIL, SENHA, aparelho);

        return mockMvc.perform(
                post("/v1/auth/entrar").contentType(MediaType.APPLICATION_JSON).content(corpo));
    }

    private ResultActions sair(String token) throws Exception {
        return mockMvc.perform(
                post("/v1/auth/sair").header(HttpHeaders.AUTHORIZATION, "Bearer " + token));
    }

    private ResultActions renovar(String refreshToken) throws Exception {
        return mockMvc.perform(
                post("/v1/auth/sessao/renovar")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"refresh_token": "%s"}
                                """.formatted(refreshToken)));
    }

    private String tokenDe(MvcResult resultado) throws Exception {
        return corpoDe(resultado).get("token_acesso").asText();
    }

    private String refreshDe(MvcResult resultado) throws Exception {
        return corpoDe(resultado).get("refresh_token").asText();
    }

    private JsonNode corpoDe(MvcResult resultado) throws Exception {
        return json.readTree(resultado.getResponse().getContentAsString());
    }
}
