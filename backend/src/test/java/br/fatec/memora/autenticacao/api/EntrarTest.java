package br.fatec.memora.autenticacao.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import br.fatec.memora.autenticacao.dominio.EstadoDaConta;
import br.fatec.memora.autenticacao.dominio.PessoaUsuaria;
import br.fatec.memora.autenticacao.dominio.TipoDeEvento;
import br.fatec.memora.autenticacao.infra.RepositorioCanalContato;
import br.fatec.memora.autenticacao.infra.RepositorioEventoAutenticacao;
import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
import br.fatec.memora.autenticacao.infra.RepositorioSessao;
import br.fatec.memora.suporte.TesteComBanco;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.ResultActions;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

/**
 * {@code POST /v1/auth/entrar} (T047).
 *
 * <p>Cobre FR-011, FR-013 e FR-051. O bloqueio progressivo tem arquivo próprio,
 * em {@link BloqueioProgressivoNoLoginTest}.
 */
@AutoConfigureMockMvc
@DisplayName("T047 — entrada com identificador e senha")
class EntrarTest extends TesteComBanco {

    private static final String EMAIL = "ana@gmail.com";

    private static final String TELEFONE = "(19) 99999-1234";

    private static final String SENHA = "pipoca no varal azul";

    @Autowired private MockMvc mockMvc;

    @Autowired private ObjectMapper json;

    @Autowired private RepositorioEventoAutenticacao eventos;

    @Autowired private RepositorioSessao sessoes;

    @Autowired private RepositorioCanalContato canais;

    @Autowired private RepositorioPessoaUsuaria pessoas;

    @AfterEach
    void limpar() {
        eventos.deleteAll();
        sessoes.deleteAll();
        canais.deleteAll();
        pessoas.deleteAll();
    }

    @Nested
    @DisplayName("Quem acerta, entra")
    class CaminhoFeliz {

        @Test
        @DisplayName("entrar com o e-mail do cadastro devolve 200 com a sessão")
        void entraComEmail() throws Exception {
            cadastrar("Ana", "email", EMAIL);

            entrar(EMAIL, SENHA)
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.token_acesso").isNotEmpty())
                    .andExpect(jsonPath("$.refresh_token").isNotEmpty())
                    .andExpect(jsonPath("$.expira_em_segundos").value(900))
                    .andExpect(jsonPath("$.pessoa.nome_tratamento").value("Ana"));
        }

        /**
         * A FR-051 em um teste: quem se cadastrou com telefone entra com
         * telefone, sem informar em lugar nenhum que aquilo é um telefone.
         */
        @Test
        @DisplayName("entrar com telefone funciona sem informar o tipo do canal")
        void entraComTelefone() throws Exception {
            cadastrar("Roberto", "telefone", TELEFONE);

            entrar(TELEFONE, SENHA)
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.pessoa.nome_tratamento").value("Roberto"));
        }

        /**
         * O teclado do Android põe maiúscula na primeira letra sozinho. Se a
         * normalização do T037 sair do caminho do login, é aqui que aparece.
         */
        @Test
        @DisplayName("maiúsculas e espaços no identificador não impedem a entrada")
        void normalizaOIdentificador() throws Exception {
            cadastrar("Ana", "email", EMAIL);

            entrar("  Ana@Gmail.com  ", SENHA).andExpect(status().isOk());
        }

        /** O telefone escrito de outro jeito é a mesma linha (T037). */
        @Test
        @DisplayName("telefone com outra pontuação continua entrando")
        void telefoneComOutraPontuacao() throws Exception {
            cadastrar("Roberto", "telefone", TELEFONE);

            entrar("19999991234", SENHA).andExpect(status().isOk());
        }

        /**
         * Decisão de 2026-08-15: o login aceita qualquer canal cadastrado. O
         * cadastro cria o canal como não verificado, e o fluxo de confirmação de
         * posse só chega na US5 — exigir verificação aqui deixaria toda conta
         * recém-criada sem poder entrar.
         */
        @Test
        @DisplayName("canal ainda não verificado serve para entrar")
        void canalNaoVerificadoEntra() throws Exception {
            cadastrar("Ana", "email", EMAIL);

            assertThat(canais.findAll()).allMatch(canal -> !canal.isVerificado());

            entrar(EMAIL, SENHA)
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.pessoa.canais[0].verificado").value(false));
        }

        @Test
        @DisplayName("a entrada bem-sucedida aparece na trilha de auditoria")
        void trilhaRegistraEntrada() throws Exception {
            cadastrar("Ana", "email", EMAIL);
            entrar(EMAIL, SENHA);

            assertThat(eventos.findAll())
                    .anyMatch(evento -> evento.getTipo() == TipoDeEvento.ENTRADA);
        }

        @Test
        @DisplayName("a entrada abre uma sessão nova, sem derrubar a do cadastro")
        void abreSessaoNova() throws Exception {
            cadastrar("Ana", "email", EMAIL);
            long antes = sessoes.count();

            entrar(EMAIL, SENHA);

            assertThat(sessoes.count()).isEqualTo(antes + 1);
        }
    }

    @Nested
    @DisplayName("Quem erra recebe sempre a mesma resposta (FR-013)")
    class RecusaGenerica {

        @Test
        @DisplayName("senha errada devolve 401 com CREDENCIAIS_INVALIDAS")
        void senhaErrada() throws Exception {
            cadastrar("Ana", "email", EMAIL);

            entrar(EMAIL, "senha que nao e a dela")
                    .andExpect(status().isUnauthorized())
                    .andExpect(jsonPath("$.codigo").value("CREDENCIAIS_INVALIDAS"));
        }

        @Test
        @DisplayName("identificador inexistente devolve 401 com CREDENCIAIS_INVALIDAS")
        void contaInexistente() throws Exception {
            entrar("ninguem@gmail.com", SENHA)
                    .andExpect(status().isUnauthorized())
                    .andExpect(jsonPath("$.codigo").value("CREDENCIAIS_INVALIDAS"));
        }

        /**
         * O critério duro: não basta o mesmo código, o corpo inteiro precisa ser
         * igual. Um campo a mais em um dos caminhos já seria o oráculo que a
         * FR-013 existe para fechar.
         */
        @Test
        @DisplayName("os dois erros produzem exatamente o mesmo corpo")
        void mesmoCorpoNosDoisCasos() throws Exception {
            cadastrar("Ana", "email", EMAIL);

            JsonNode senhaErrada = corpoDe(entrar(EMAIL, "outra senha qualquer").andReturn());
            JsonNode semConta = corpoDe(entrar("ninguem@gmail.com", SENHA).andReturn());

            assertThat(semConta).isEqualTo(senhaErrada);
        }

        /**
         * A R3 mede tempo, não só texto. Se alguém puser um atalho para conta
         * inexistente — devolver antes de rodar o Argon2 —, a diferença de
         * latência transforma este endpoint em lista de quem usa o Memora.
         *
         * <p>A margem é generosa de propósito: o alvo é reprovar quem
         * <b>remove</b> o hash, e sem ele a diferença é de ~240 ms contra ~1 ms.
         */
        @Test
        @DisplayName("conta inexistente e senha errada levam tempos da mesma ordem")
        void mesmaOrdemDeGrandeza() throws Exception {
            cadastrar("Ana", "email", EMAIL);
            entrar(EMAIL, "aquece a jvm");

            long comConta = duracaoDe(EMAIL, "senha errada mas a conta existe");
            long semConta = duracaoDe("ninguem@gmail.com", SENHA);

            assertThat(semConta)
                    .as("sem conta (%d ms) contra conta existente (%d ms)", semConta, comConta)
                    .isGreaterThan(comConta / 4);
        }

        @Test
        @DisplayName("a tentativa recusada aparece na trilha de auditoria")
        void trilhaRegistraFalha() throws Exception {
            cadastrar("Ana", "email", EMAIL);

            entrar(EMAIL, "senha errada");

            assertThat(eventos.findAll())
                    .anyMatch(evento -> evento.getTipo() == TipoDeEvento.FALHA_ENTRADA);
        }

        /**
         * Sem conta não há id a informar, e inventar um revelaria pela própria
         * existência do vínculo que aquele identificador não existe (FR-040).
         */
        @Test
        @DisplayName("a falha sem conta é registrada sem apontar para pessoa nenhuma")
        void falhaSemContaNaoApontaPessoa() throws Exception {
            entrar("ninguem@gmail.com", SENHA);

            assertThat(eventos.findAll())
                    .filteredOn(evento -> evento.getTipo() == TipoDeEvento.FALHA_ENTRADA)
                    .isNotEmpty()
                    .allMatch(evento -> evento.getPessoaId() == null);
        }

        @Test
        @DisplayName("corpo sem identificador é dado inválido, não credencial inválida")
        void corpoIncompleto() throws Exception {
            String corpo = """
                    {"senha": "%s"}
                    """.formatted(SENHA);

            mockMvc.perform(
                            post("/v1/auth/entrar")
                                    .contentType(MediaType.APPLICATION_JSON)
                                    .content(corpo))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.codigo").value("DADOS_INVALIDOS"));
        }
    }

    @Nested
    @DisplayName("O que a resposta nunca pode conter")
    class NadaSensivelNaResposta {

        @Test
        @DisplayName("o canal sai mascarado, nunca completo")
        void canalMascarado() throws Exception {
            cadastrar("Ana", "email", EMAIL);

            JsonNode corpo = corpoDe(entrar(EMAIL, SENHA).andReturn());
            String mascarado = corpo.at("/pessoa/canais/0/valor_mascarado").asText();

            assertThat(mascarado).isNotEqualTo(EMAIL).contains("****");
        }

        /**
         * O hash da senha nunca deve ter caminho até a resposta. O teste varre a
         * árvore inteira em vez de conferir campo a campo, porque o risco real é
         * um campo <b>novo</b> aparecer no futuro carregando o que não devia.
         */
        @Test
        @DisplayName("nenhum campo da resposta contém hash de senha")
        void semHashDeSenha() throws Exception {
            cadastrar("Ana", "email", EMAIL);

            JsonNode corpo = corpoDe(entrar(EMAIL, SENHA).andReturn());

            assertThat(valores(corpo)).noneMatch(valor -> valor.contains("$argon2"));
        }
    }

    /**
     * A guarda que recusa conta desativada.
     *
     * <p>Ela existia sem nenhum teste: os 244 passavam com a guarda funcionando
     * e passariam iguais com ela removida. A reincidência do bloqueio — o
     * caminho que chegava a apagar o {@code DESATIVADA} — está em
     * {@link BloqueioProgressivoNoLoginTest}, porque precisa do relógio
     * ajustável de lá.
     */
    @Nested
    @DisplayName("Conta desativada não entra")
    class ContaDesativada {

        /** É a mesma resposta de senha errada, e precisa ser: FR-013. */
        @Test
        @DisplayName("senha certa em conta desativada devolve 401 CREDENCIAIS_INVALIDAS")
        void desativadaNaoEntra() throws Exception {
            cadastrar("Ana", "email", EMAIL);
            desativarAConta();

            entrar(EMAIL, SENHA)
                    .andExpect(status().isUnauthorized())
                    .andExpect(jsonPath("$.codigo").value("CREDENCIAIS_INVALIDAS"));
        }

        @Test
        @DisplayName("a recusa não abre sessão nenhuma")
        void naoAbreSessao() throws Exception {
            cadastrar("Ana", "email", EMAIL);
            long depoisDoCadastro = sessoes.count();
            desativarAConta();

            entrar(EMAIL, SENHA);

            assertThat(sessoes.count()).isEqualTo(depoisDoCadastro);
        }

        /** Entrar recusado não pode reativar o que foi desativado. */
        @Test
        @DisplayName("a conta continua desativada depois da tentativa")
        void continuaDesativada() throws Exception {
            cadastrar("Ana", "email", EMAIL);
            desativarAConta();

            entrar(EMAIL, SENHA);

            assertThat(pessoas.findAll())
                    .allMatch(pessoa -> pessoa.getEstado() == EstadoDaConta.DESATIVADA);
        }
    }

    // --- apoio ---------------------------------------------------------------

    private void desativarAConta() {
        PessoaUsuaria pessoa = pessoas.findAll().getFirst();
        pessoa.desativar();
        pessoas.saveAndFlush(pessoa);
    }

    private ResultActions cadastrar(String nome, String tipo, String canal) throws Exception {
        String corpo =
                """
                {
                  "nome_tratamento": "%s",
                  "canal": {"tipo": "%s", "valor": "%s"},
                  "senha": "%s"
                }
                """
                        .formatted(nome, tipo, canal, SENHA);

        return mockMvc.perform(
                post("/v1/auth/cadastro").contentType(MediaType.APPLICATION_JSON).content(corpo));
    }

    private ResultActions entrar(String identificador, String senha) throws Exception {
        String corpo =
                """
                {"identificador": "%s", "senha": "%s"}
                """
                        .formatted(identificador, senha);

        return mockMvc.perform(
                post("/v1/auth/entrar").contentType(MediaType.APPLICATION_JSON).content(corpo));
    }

    private long duracaoDe(String identificador, String senha) throws Exception {
        long inicio = System.nanoTime();
        entrar(identificador, senha);
        return (System.nanoTime() - inicio) / 1_000_000;
    }

    private JsonNode corpoDe(MvcResult resultado) throws Exception {
        return json.readTree(resultado.getResponse().getContentAsString());
    }

    /** Todos os valores folha do JSON, como texto. */
    private List<String> valores(JsonNode no) {
        List<String> encontrados = new ArrayList<>();
        percorrer(no, encontrados);
        return encontrados;
    }

    private void percorrer(JsonNode no, List<String> encontrados) {
        if (no.isObject()) {
            for (Map.Entry<String, JsonNode> campo : no.properties()) {
                percorrer(campo.getValue(), encontrados);
            }
        } else if (no.isArray()) {
            no.forEach(item -> percorrer(item, encontrados));
        } else {
            encontrados.add(no.asText());
        }
    }
}
