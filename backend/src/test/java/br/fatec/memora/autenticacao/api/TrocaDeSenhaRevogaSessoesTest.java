package br.fatec.memora.autenticacao.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import br.fatec.memora.autenticacao.aplicacao.EnviadorDeCodigo;
import br.fatec.memora.autenticacao.aplicacao.NotificadorDeConta;
import br.fatec.memora.autenticacao.dominio.CanalContato;
import br.fatec.memora.autenticacao.dominio.EstadoDaConta;
import br.fatec.memora.autenticacao.dominio.Sessao;
import br.fatec.memora.autenticacao.dominio.TipoDeEvento;
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
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.ResultActions;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

/**
 * Cenário V5 do quickstart — trocar a senha derruba todas as sessões (T069).
 *
 * <p><b>Cobre FR-019 a FR-022.</b> O V5 é curto de escrever e é o que separa
 * "recuperar a conta" de "dividir a conta com quem invadiu": quem troca a senha
 * por suspeitar de invasão precisa que a sessão do invasor morra junto. Uma
 * recuperação que troca a senha e deixa o refresh token antigo funcionando por
 * 60 dias é pior que inútil — ela dá à pessoa a sensação de ter resolvido.
 *
 * <p>Os quatro passos do cenário estão aqui, um a um: dois aparelhos
 * autenticados, a troca pelo fluxo de recuperação, as duas sessões antigas
 * paradas, e a notificação da FR-022.
 */
@AutoConfigureMockMvc
@Import({TrocaDeSenhaRevogaSessoesTest.EnvioQueGuarda.class,
        TrocaDeSenhaRevogaSessoesTest.AvisoQueGuarda.class})
@DisplayName("V5 — trocar a senha derruba todas as sessões")
class TrocaDeSenhaRevogaSessoesTest extends TesteComBanco {

    private static final String EMAIL = "ana@gmail.com";

    private static final String SENHA = "pipoca no varal azul";

    private static final String SENHA_NOVA = "girassol na janela verde";

    @Autowired private MockMvc mockMvc;

    @Autowired private ObjectMapper json;

    @Autowired private RepositorioEventoAutenticacao eventos;

    @Autowired private RepositorioSessao sessoes;

    @Autowired private RepositorioCodigoVerificacao codigos;

    @Autowired private RepositorioCanalContato canais;

    @Autowired private RepositorioPessoaUsuaria pessoas;

    @Autowired private EnvioQueGuarda envio;

    @Autowired private AvisoQueGuarda aviso;

    @AfterEach
    void limpar() {
        envio.enviados.clear();
        aviso.avisados.clear();
        eventos.deleteAll();
        codigos.deleteAll();
        sessoes.deleteAll();
        canais.deleteAll();
        pessoas.deleteAll();
    }

    @Nested
    @DisplayName("O cenário V5, passo a passo")
    class CenarioCompleto {

        /**
         * O passo 3 do V5, e o motivo de a feature existir. Se este teste passar
         * com a revogação desligada, é porque ele está medindo outra coisa.
         */
        @Test
        @DisplayName("as duas sessões anteriores param de funcionar")
        void ambasAsSessoesMorrem() throws Exception {
            cadastrar();
            String refreshDoCelular = refreshDe(entrar("Celular da Ana").andReturn());
            String refreshDoTablet = refreshDe(entrar("Tablet da sala").andReturn());

            trocarSenha();

            renovar(refreshDoCelular).andExpect(status().isUnauthorized());
            renovar(refreshDoTablet).andExpect(status().isUnauthorized());
        }

        /** A revogação é no banco, e não só no caminho da renovação. */
        @Test
        @DisplayName("as sessões antigas ficam marcadas como revogadas")
        void sessoesAntigasRevogadasNoBanco() throws Exception {
            cadastrar();
            entrar("Celular da Ana");
            entrar("Tablet da sala");
            List<UUID> antigas = sessoes.findAll().stream().map(Sessao::getId).toList();

            trocarSenha();

            assertThat(antigas).hasSize(3); // cadastro + dois logins
            assertThat(antigas)
                    .allSatisfy(
                            id ->
                                    assertThat(sessoes.findById(id).orElseThrow().getRevogadaEm())
                                            .isNotNull());
        }

        /**
         * A sessão emitida pela própria recuperação precisa sobreviver. Revogar
         * depois de emitir mataria a sessão nova junto com as velhas, e a pessoa
         * sairia da recuperação com um token morto — trocando um problema por
         * outro.
         */
        @Test
        @DisplayName("a sessão emitida pela recuperação continua valendo")
        void sessaoNovaSobrevive() throws Exception {
            cadastrar();
            entrar("Celular da Ana");

            String refreshNovo = refreshDe(trocarSenha().andReturn());

            renovar(refreshNovo).andExpect(status().isOk());
        }

        /** O passo 4 do V5. */
        @Test
        @DisplayName("a pessoa é notificada pelo canal (FR-022)")
        void notificaPeloCanal() throws Exception {
            cadastrar();

            trocarSenha();

            assertThat(aviso.avisados).hasSize(1);
            assertThat(aviso.avisados.getFirst()).isEqualTo(canais.findAll().getFirst().getId());
        }
    }

    @Nested
    @DisplayName("A senha nova passa a valer, e a antiga não")
    class SenhaTrocada {

        @Test
        @DisplayName("entra com a senha nova")
        void entraComSenhaNova() throws Exception {
            cadastrar();
            trocarSenha();

            entrarCom(SENHA_NOVA, "Celular da Ana").andExpect(status().isOk());
        }

        @Test
        @DisplayName("a senha antiga é recusada")
        void senhaAntigaNaoServe() throws Exception {
            cadastrar();
            trocarSenha();

            entrarCom(SENHA, "Celular da Ana").andExpect(status().isUnauthorized());
        }

        /** A trilha da FR-039 precisa registrar a alteração. */
        @Test
        @DisplayName("a troca fica na trilha de auditoria")
        void registraNaTrilha() throws Exception {
            cadastrar();
            trocarSenha();

            assertThat(eventos.findAll())
                    .anySatisfy(
                            evento ->
                                    assertThat(evento.getTipo())
                                            .isEqualTo(TipoDeEvento.SENHA_ALTERADA));
        }
    }

    @Nested
    @DisplayName("Quem chegou aqui vindo do bloqueio sai destrancado")
    class SaidaDoBloqueio {

        /**
         * A tela de bloqueio oferece "Criar uma senha nova" como saída. Se a
         * troca não limpasse {@code bloqueada_ate}, a pessoa faria tudo certo e
         * continuaria trancada do lado de fora — a saída oferecida seria porta
         * pintada na parede.
         */
        @Test
        @DisplayName("trocar a senha destranca a conta bloqueada")
        void destrancaContaBloqueada() throws Exception {
            cadastrar();
            for (int tentativa = 0; tentativa < 5; tentativa++) {
                entrarCom("nao e essa a senha dela", "Celular da Ana");
            }
            assertThat(pessoas.findAll().getFirst().getBloqueadaAte()).isNotNull();

            trocarSenha();

            assertThat(pessoas.findAll().getFirst().getBloqueadaAte()).isNull();
            assertThat(pessoas.findAll().getFirst().getFalhasConsecutivas()).isZero();
            entrarCom(SENHA_NOVA, "Celular da Ana").andExpect(status().isOk());
        }
    }

    @Nested
    @DisplayName("A solicitação não conta quem existe (FR-019)")
    class NaoRevelaExistencia {

        @Test
        @DisplayName("conta que existe recebe 202")
        void contaExistente() throws Exception {
            cadastrar();

            solicitar(EMAIL)
                    .andExpect(status().isAccepted())
                    .andExpect(jsonPath("$.mensagem").value(ControladorRecuperacao.MENSAGEM_ACEITA));
        }

        @Test
        @DisplayName("conta que não existe recebe o mesmo 202, com o mesmo texto")
        void contaInexistente() throws Exception {
            solicitar("ninguem@gmail.com")
                    .andExpect(status().isAccepted())
                    .andExpect(jsonPath("$.mensagem").value(ControladorRecuperacao.MENSAGEM_ACEITA));
        }

        /** O silêncio precisa ser real: nada enviado é o que o 202 esconde. */
        @Test
        @DisplayName("conta que não existe não gera envio nenhum")
        void inexistenteNaoEnvia() throws Exception {
            solicitar("ninguem@gmail.com");

            assertThat(envio.enviados).isEmpty();
        }
    }

    @Nested
    @DisplayName("Canal não verificado não recupera (FR-052, FR-062)")
    class SoCanalVerificado {

        /**
         * O golpe da FR-062 em uma linha: o acompanhante cadastra a conta da
         * pessoa idosa apontando o próprio contato. Se canal não verificado
         * recebesse código de recuperação, ele controlaria a conta para sempre —
         * e a US5 inteira teria sido escrita à toa.
         */
        @Test
        @DisplayName("canal não verificado não recebe código")
        void naoEnviaParaCanalNaoVerificado() throws Exception {
            cadastrar(); // o cadastro cria o canal NAO verificado

            solicitar(EMAIL).andExpect(status().isAccepted());

            assertThat(envio.enviados).isEmpty();
            assertThat(codigos.findAll()).isEmpty();
        }

        @Test
        @DisplayName("conta desativada não recupera")
        void contaDesativadaNaoRecupera() throws Exception {
            cadastrar();
            verificarCanal();
            desativarAConta();

            solicitar(EMAIL).andExpect(status().isAccepted());

            assertThat(envio.enviados).isEmpty();
        }
    }

    @Nested
    @DisplayName("O código de recuperação tem as três proteções")
    class ProtecoesDoCodigo {

        @Test
        @DisplayName("código errado é recusado sem trocar a senha")
        void codigoErrado() throws Exception {
            cadastrar();
            verificarCanal();
            solicitar(EMAIL);

            confirmar(errarUmDigito(envio.ultimoCodigo()), SENHA_NOVA)
                    .andExpect(status().isBadRequest());

            entrarCom(SENHA, "Celular da Ana").andExpect(status().isOk());
        }

        /** Uso único (FR-020). */
        @Test
        @DisplayName("o mesmo código não serve duas vezes")
        void usoUnico() throws Exception {
            cadastrar();
            verificarCanal();
            solicitar(EMAIL);
            String codigo = envio.ultimoCodigo();
            confirmar(codigo, SENHA_NOVA).andExpect(status().isOk());

            confirmar(codigo, "outra frase bem comprida").andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("pedir código novo invalida o anterior")
        void codigoNovoInvalidaAnterior() throws Exception {
            cadastrar();
            verificarCanal();
            solicitar(EMAIL);
            String primeiro = envio.ultimoCodigo();
            solicitar(EMAIL);

            confirmar(primeiro, SENHA_NOVA).andExpect(status().isBadRequest());
            confirmar(envio.ultimoCodigo(), SENHA_NOVA).andExpect(status().isOk());
        }

        /**
         * O quinto erro descarta o código. É o que impede varrer as 10^6
         * possibilidades com um código só.
         */
        @Test
        @DisplayName("cinco erros descartam o código, e o certo já não serve")
        void cincoErrosDescartam() throws Exception {
            cadastrar();
            verificarCanal();
            solicitar(EMAIL);
            String certo = envio.ultimoCodigo();

            for (int tentativa = 0; tentativa < 5; tentativa++) {
                confirmar(errarUmDigito(certo), SENHA_NOVA).andExpect(status().isBadRequest());
            }

            confirmar(certo, SENHA_NOVA).andExpect(status().isBadRequest());
        }
    }

    @Nested
    @DisplayName("A senha nova passa pela mesma política do cadastro")
    class PoliticaDeSenhaNaTroca {

        @Test
        @DisplayName("senha curta é recusada, com o texto que explica o que fazer")
        void senhaCurta() throws Exception {
            cadastrar();
            verificarCanal();
            solicitar(EMAIL);

            confirmar(envio.ultimoCodigo(), "curta")
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.codigo").value("DADOS_INVALIDOS"))
                    .andExpect(jsonPath("$.mensagem").value(org.hamcrest.Matchers.containsString("curtinha")));
        }
    }

    // --- apoio ---------------------------------------------------------------

    /** Cadastra e já confirma a posse do canal, que é o caminho normal da US5. */
    private void verificarCanal() {
        CanalContato canal = canais.findAll().getFirst();
        canal.marcarComoVerificado(java.time.Instant.now());
        canais.saveAndFlush(canal);
    }

    private void desativarAConta() {
        var pessoa = pessoas.findAll().getFirst();
        pessoa.desativar();
        pessoas.saveAndFlush(pessoa);
        assertThat(pessoas.findAll().getFirst().getEstado()).isEqualTo(EstadoDaConta.DESATIVADA);
    }

    /** O caminho completo: verificar o canal, pedir o código e confirmar. */
    private ResultActions trocarSenha() throws Exception {
        verificarCanal();
        solicitar(EMAIL);
        return confirmar(envio.ultimoCodigo(), SENHA_NOVA).andExpect(status().isOk());
    }

    private ResultActions cadastrar() throws Exception {
        String corpo =
                """
                {
                  "nome_tratamento": "Ana",
                  "canal": {"tipo": "email", "valor": "%s"},
                  "senha": "%s"
                }
                """
                        .formatted(EMAIL, SENHA);

        return mockMvc.perform(
                post("/v1/auth/cadastro").contentType(MediaType.APPLICATION_JSON).content(corpo));
    }

    private ResultActions entrar(String aparelho) throws Exception {
        return entrarCom(SENHA, aparelho);
    }

    private ResultActions entrarCom(String senha, String aparelho) throws Exception {
        String corpo =
                """
                {"identificador": "%s", "senha": "%s", "aparelho_descricao": "%s"}
                """
                        .formatted(EMAIL, senha, aparelho);

        return mockMvc.perform(
                post("/v1/auth/entrar").contentType(MediaType.APPLICATION_JSON).content(corpo));
    }

    private ResultActions renovar(String refreshToken) throws Exception {
        return mockMvc.perform(
                post("/v1/auth/sessao/renovar")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"refresh_token": "%s"}
                                """.formatted(refreshToken)));
    }

    private ResultActions solicitar(String identificador) throws Exception {
        return mockMvc.perform(
                post("/v1/auth/recuperacao/solicitar")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"identificador": "%s"}
                                """.formatted(identificador)));
    }

    private ResultActions confirmar(String codigo, String novaSenha) throws Exception {
        String corpo =
                """
                {"identificador": "%s", "codigo": "%s", "nova_senha": "%s"}
                """
                        .formatted(EMAIL, codigo, novaSenha);

        return mockMvc.perform(
                post("/v1/auth/recuperacao/confirmar")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(corpo));
    }

    private String refreshDe(MvcResult resultado) throws Exception {
        return corpoDe(resultado).get("refresh_token").asText();
    }

    private JsonNode corpoDe(MvcResult resultado) throws Exception {
        return json.readTree(resultado.getResponse().getContentAsString());
    }

    private static String errarUmDigito(String codigo) {
        char primeiro = codigo.charAt(0);
        char trocado = primeiro == '9' ? '0' : (char) (primeiro + 1);
        return trocado + codigo.substring(1);
    }

    /** Guarda o código em vez de enviar — no banco ele está hasheado, e deve estar. */
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

    /** Guarda para qual canal o aviso da FR-022 iria. */
    @TestConfiguration
    static class AvisoQueGuarda {

        final List<UUID> avisados = new ArrayList<>();

        @Bean
        @Primary
        NotificadorDeConta notificadorQueGuarda() {
            return (canal, nomeTratamento) -> avisados.add(canal.getId());
        }
    }
}
