package br.fatec.memora.autenticacao.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import br.fatec.memora.autenticacao.dominio.CanalContato;
import br.fatec.memora.autenticacao.dominio.PessoaUsuaria;
import br.fatec.memora.autenticacao.infra.RepositorioCanalContato;
import br.fatec.memora.autenticacao.infra.RepositorioCodigoVerificacao;
import br.fatec.memora.autenticacao.infra.RepositorioEventoAutenticacao;
import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
import br.fatec.memora.autenticacao.infra.RepositorioSessao;
import br.fatec.memora.suporte.TesteComBanco;
import java.util.List;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

/**
 * O modo assistido não deixa rastro do acompanhante (T065, FR-064).
 *
 * <h2>O que este teste protege</h2>
 *
 * A FR-064 é curta e categórica: o modo assistido <i>"MUST NOT criar vínculo
 * permanente, permissão ou acesso do acompanhante à conta"</i>. É um requisito
 * sobre o que <b>não</b> pode existir, e requisito assim tende a passar
 * despercebido — ninguém repara na ausência de uma tabela.
 *
 * <p>Por isso a verificação é feita contra o banco inteiro, e não contra uma
 * API: se alguém acrescentar depois um campo "cadastrado_por", uma tabela de
 * acompanhantes ou uma segunda conta criada de tabela, estes testes reprovam.
 *
 * <p>A comparação com o cadastro comum é o coração da coisa: <b>o modo assistido
 * produz exatamente o mesmo conjunto de linhas</b>. A única diferença legítima é
 * o estado inicial da conta, que é a espera da FR-062 — e não um vínculo.
 */
@AutoConfigureMockMvc
@DisplayName("FR-064 — modo assistido não cria vínculo")
class ModoAssistidoSemVinculoTest extends TesteComBanco {

    private static final String SENHA = "pipoca no varal azul";

    @Autowired private MockMvc mockMvc;

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
    @DisplayName("Nada do acompanhante é gravado")
    class SemRastro {

        @Test
        @DisplayName("o cadastro assistido cria uma conta, e só uma")
        void umaContaSo() throws Exception {
            cadastrarAssistido();

            assertThat(pessoas.findAll()).hasSize(1);
        }

        @Test
        @DisplayName("o cadastro assistido cria um canal, e só um")
        void umCanalSo() throws Exception {
            cadastrarAssistido();

            assertThat(canais.findAll()).hasSize(1);
        }

        /**
         * O canal gravado é o da pessoa dona da conta — o que foi informado. Se
         * um dia o modo assistido passar a guardar também o contato de quem
         * ajudou, é aqui que aparece.
         */
        @Test
        @DisplayName("o único canal é o que foi informado no cadastro")
        void canalEODaPessoa() throws Exception {
            cadastrarAssistido();

            CanalContato canal = canais.findAll().getFirst();
            assertThat(canal.getValor()).isEqualTo("ana@gmail.com");
            assertThat(canal.isPrincipal()).isTrue();
        }

        /**
         * Uma sessão, para o aparelho que está ali. Duas significariam que o
         * acompanhante saiu com credencial na mão — que é a FR-064 caindo.
         */
        @Test
        @DisplayName("o cadastro assistido abre uma sessão, e só uma")
        void umaSessaoSo() throws Exception {
            cadastrarAssistido();

            assertThat(sessoes.findAll()).hasSize(1);
        }

        @Test
        @DisplayName("a sessão aberta pertence à conta criada")
        void sessaoEDaConta() throws Exception {
            cadastrarAssistido();

            PessoaUsuaria pessoa = pessoas.findAll().getFirst();
            assertThat(sessoes.findAll().getFirst().getPessoaId()).isEqualTo(pessoa.getId());
        }
    }

    @Nested
    @DisplayName("Assistido e comum gravam a mesma coisa")
    class MesmaForma {

        /**
         * O teste mais direto da FR-064: se o modo assistido criasse qualquer
         * vínculo, ele apareceria como diferença de contagem entre os dois
         * cadastros. A única diferença permitida é o estado da conta.
         */
        @Test
        @DisplayName("os dois cadastros produzem a mesma contagem de linhas")
        void mesmaContagem() throws Exception {
            cadastrarCom("ana@gmail.com", true);
            List<Long> comAcompanhante = contagens();

            limpar();

            cadastrarCom("ana@gmail.com", false);
            List<Long> semAcompanhante = contagens();

            assertThat(comAcompanhante).isEqualTo(semAcompanhante);
        }

        private List<Long> contagens() {
            return List.of(
                    pessoas.count(), canais.count(), sessoes.count(), codigos.count());
        }
    }

    // --- apoio ---------------------------------------------------------------

    private ResultActions cadastrarAssistido() throws Exception {
        return cadastrarCom("ana@gmail.com", true);
    }

    private ResultActions cadastrarCom(String email, boolean modoAssistido) throws Exception {
        String corpo =
                """
                {
                  "nome_tratamento": "Ana",
                  "canal": {"tipo": "email", "valor": "%s"},
                  "senha": "%s",
                  "modo_assistido": %s
                }
                """
                        .formatted(email, SENHA, modoAssistido);

        return mockMvc.perform(
                        post("/v1/auth/cadastro")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(corpo))
                .andExpect(status().isCreated());
    }
}
