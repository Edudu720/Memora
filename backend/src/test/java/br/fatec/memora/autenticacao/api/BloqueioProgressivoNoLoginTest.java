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
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Locale;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
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
 * Cenário V6 do quickstart: bloqueio progressivo com texto acolhedor (T049,
 * T050).
 *
 * <p>Cobre FR-014 e FR-015. A escada em si — 1, 5, 15 e 60 minutos — já tem
 * teste de unidade em {@code BloqueioProgressivoTest}; o que falta, e é o que
 * este arquivo faz, é percorrê-la <b>pelo endpoint</b>, conferindo que o
 * {@code 429} sai com {@code tentar_novamente_em_segundos} e que o texto passa
 * na revisão de UX que o V6 exige.
 *
 * <h2>Por que um relógio ajustável</h2>
 *
 * A escada só avança quando a espera anterior termina: durante o bloqueio, a
 * tentativa é recusada sem contar. Percorrer os quatro degraus com o relógio do
 * sistema levaria 1 + 5 + 15 + 60 minutos de teste. Com o relógio injetado
 * (ver {@code ConfiguracaoDeRelogio}), o mesmo percurso custa milissegundos — e
 * é exatamente para isto que ele foi injetado.
 */
@AutoConfigureMockMvc
@Import(BloqueioProgressivoNoLoginTest.RelogioDeTeste.class)
@DisplayName("V6 — bloqueio progressivo com texto acolhedor")
class BloqueioProgressivoNoLoginTest extends TesteComBanco {

    private static final String EMAIL = "ana@gmail.com";

    private static final String SENHA = "pipoca no varal azul";

    private static final String SENHA_ERRADA = "essa aqui nao e a senha dela";

    /** Os quatro degraus da R4, em segundos, na ordem em que devem aparecer. */
    private static final List<Long> ESCADA_ESPERADA = List.of(60L, 300L, 900L, 3600L);

    @Autowired private MockMvc mockMvc;

    @Autowired private ObjectMapper json;

    @Autowired private RelogioAjustavel relogio;

    @Autowired private RepositorioEventoAutenticacao eventos;

    @Autowired private RepositorioSessao sessoes;

    @Autowired private RepositorioCanalContato canais;

    @Autowired private RepositorioPessoaUsuaria pessoas;

    @BeforeEach
    void prepararConta() throws Exception {
        relogio.reiniciar();
        cadastrar();
    }

    @AfterEach
    void limpar() {
        eventos.deleteAll();
        sessoes.deleteAll();
        canais.deleteAll();
        pessoas.deleteAll();
    }

    @Nested
    @DisplayName("Passo 2 — a quinta senha errada devolve 429 com a espera")
    class QuintaTentativa {

        @Test
        @DisplayName("as quatro primeiras falhas ainda respondem 401")
        void quatroPrimeirasSao401() throws Exception {
            for (int tentativa = 1; tentativa <= 4; tentativa++) {
                errarSenha()
                        .andExpect(status().isUnauthorized())
                        .andExpect(jsonPath("$.codigo").value("CREDENCIAIS_INVALIDAS"));
            }
        }

        @Test
        @DisplayName("a quinta responde 429 com tentar_novamente_em_segundos")
        void quintaEh429() throws Exception {
            errarSenha(4);

            errarSenha()
                    .andExpect(status().isTooManyRequests())
                    .andExpect(jsonPath("$.codigo").value("MUITAS_TENTATIVAS"))
                    .andExpect(jsonPath("$.tentar_novamente_em_segundos").value(60));
        }

        /**
         * Enquanto a espera vale, insistir não conta nova falha — senão a pessoa
         * que tentasse três vezes durante o bloqueio pularia dois degraus da
         * escada sem nunca ter tido a chance de acertar.
         */
        @Test
        @DisplayName("insistir durante o bloqueio não avança a escada")
        void insistirNaoAvanca() throws Exception {
            errarSenha(5);

            errarSenha().andExpect(jsonPath("$.tentar_novamente_em_segundos").value(60));
            errarSenha().andExpect(jsonPath("$.tentar_novamente_em_segundos").value(60));
        }

        /** Acertar a senha durante o bloqueio também não entra (FR-014). */
        @Test
        @DisplayName("nem a senha certa entra enquanto a espera vale")
        void senhaCertaTambemEsperaria() throws Exception {
            errarSenha(5);

            entrar(SENHA).andExpect(status().isTooManyRequests());
        }

        @Test
        @DisplayName("o bloqueio aparece na trilha de auditoria")
        void trilhaRegistraBloqueio() throws Exception {
            errarSenha(5);

            assertThat(eventos.findAll())
                    .anyMatch(evento -> evento.getTipo() == TipoDeEvento.BLOQUEIO);
        }
    }

    @Nested
    @DisplayName("Passo 3 — o bloqueio cresce: 1, 5, 15 e 60 minutos")
    class EscadaCresce {

        /**
         * O percurso completo do V6. Cada degrau exige esperar o anterior
         * terminar e errar de novo: é assim que a reincidência é medida.
         */
        @Test
        @DisplayName("cada reincidência devolve o próximo degrau, e o teto se mantém")
        void percorreAEscada() throws Exception {
            errarSenha(4);

            for (long esperado : ESCADA_ESPERADA) {
                long devolvido = esperaDe(errarSenha().andReturn());

                assertThat(devolvido)
                        .as("degrau esperado de %d s da escada 1/5/15/60", esperado)
                        .isEqualTo(esperado);

                relogio.avancar(Duration.ofSeconds(devolvido + 1));
            }

            // Passado o ultimo degrau, a espera fica no teto em vez de crescer
            // sem limite — bloqueio permanente por acumulo e exatamente o que a
            // FR-014 evita.
            assertThat(esperaDe(errarSenha().andReturn())).isEqualTo(3600);
        }

        @Test
        @DisplayName("depois que a espera passa, a senha certa entra de novo")
        void esperaTerminaEAContaVolta() throws Exception {
            errarSenha(5);

            relogio.avancar(Duration.ofSeconds(61));

            entrar(SENHA).andExpect(status().isOk());
        }

        /**
         * Entrar zera o contador. Sem isso, quem errou quatro vezes hoje e
         * acertou seria bloqueada no primeiro erro de amanhã.
         */
        @Test
        @DisplayName("entrar com sucesso zera as falhas acumuladas")
        void sucessoZeraOContador() throws Exception {
            errarSenha(4);
            entrar(SENHA).andExpect(status().isOk());

            errarSenha().andExpect(status().isUnauthorized());
        }
    }

    /**
     * O bloqueio temporário não pode devolver ao ar uma conta desativada.
     *
     * <p>{@code estado} guarda duas coisas de naturezas diferentes — o ciclo de
     * vida da conta e uma tranca cuja verdade mora em {@code bloqueada_ate} —, e
     * era o bloqueio que apagava o {@code DESATIVADA} escrevendo por cima.
     * Cinco recusas bastavam para a guarda de {@code ServicoDeEntrada} deixar de
     * enxergar o que devia recusar.
     */
    @Nested
    @DisplayName("Bloqueio não ressuscita conta desativada")
    class ContaDesativadaContinuaDesativada {

        @Test
        @DisplayName("cinco recusas e a espera vencida não devolvem a conta")
        void bloqueioNaoReativa() throws Exception {
            desativarAConta();

            // A senha esta certa em todas: quem recusa e o estado da conta. Cada
            // recusa conta uma falha, e a quinta aplica o bloqueio de 1 minuto,
            // que e onde o estado era sobrescrito.
            for (int tentativa = 1; tentativa <= 5; tentativa++) {
                entrar(SENHA).andExpect(status().is4xxClientError());
            }

            relogio.avancar(Duration.ofSeconds(61));

            // Sem a correcao, esta e a tentativa que devolvia 200 e ainda
            // gravava ATIVA: a tranca ja vencera e o DESATIVADA nao existia mais.
            entrar(SENHA).andExpect(status().is4xxClientError());

            assertThat(pessoas.findAll())
                    .allMatch(pessoa -> pessoa.getEstado() == EstadoDaConta.DESATIVADA);
        }
    }

    /**
     * A revisão de UX que o V6 torna obrigatória.
     *
     * <p>O cenário é explícito: <i>"bloqueio tecnicamente correto com texto
     * ríspido reprova"</i>. Estas verificações são a parte automatizável da
     * FR-015 — explicar o motivo, oferecer a recuperação e não punir. O tom em
     * si continua sendo julgamento humano, e é isso que a V10 vai medir com
     * pessoas de verdade.
     */
    @Nested
    @DisplayName("Revisão de UX obrigatória do texto (FR-015)")
    class TextoAcolhedor {

        @Test
        @DisplayName("a mensagem explica o motivo do bloqueio")
        void explicaOMotivo() throws Exception {
            assertThat(mensagemDoBloqueio()).contains("proteger sua conta");
        }

        @Test
        @DisplayName("a mensagem oferece o caminho de recuperação")
        void ofereceRecuperacao() throws Exception {
            assertThat(mensagemDoBloqueio()).contains("senha nova");
        }

        /**
         * A espera concreta viaja no campo, e não no texto: ela muda a cada
         * degrau, e uma frase com "5 minutinhos" fixos mentiria em três dos
         * quatro casos.
         */
        @Test
        @DisplayName("o quando vem no campo, e o texto não promete prazo fixo")
        void prazoVemNoCampo() throws Exception {
            errarSenha(4);
            MvcResult resultado = errarSenha().andReturn();

            assertThat(esperaDe(resultado)).isPositive();
            assertThat(corpoDe(resultado).get("mensagem").asText()).doesNotContain("5 minutos");
        }

        /**
         * A lista não é de palavrão: é de vocabulário que culpa a pessoa ou
         * descreve o mecanismo interno. Qualquer um dos dois reprova no V6.
         */
        @Test
        @DisplayName("a mensagem não usa tom de punição nem jargão técnico")
        void semPunicaoNemJargao() throws Exception {
            String mensagem = mensagemDoBloqueio().toLowerCase(Locale.ROOT);

            assertThat(mensagem)
                    .doesNotContain("bloquead")
                    .doesNotContain("excedeu")
                    .doesNotContain("inválid")
                    .doesNotContain("negad")
                    .doesNotContain("proibid")
                    .doesNotContain("erro")
                    .doesNotContain("falha");
        }

        private String mensagemDoBloqueio() throws Exception {
            errarSenha(4);
            return corpoDe(errarSenha().andReturn()).get("mensagem").asText();
        }
    }

    // --- apoio ---------------------------------------------------------------

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

    private ResultActions entrar(String senha) throws Exception {
        String corpo =
                """
                {"identificador": "%s", "senha": "%s"}
                """
                        .formatted(EMAIL, senha);

        return mockMvc.perform(
                post("/v1/auth/entrar").contentType(MediaType.APPLICATION_JSON).content(corpo));
    }

    private ResultActions errarSenha() throws Exception {
        return entrar(SENHA_ERRADA);
    }

    private void desativarAConta() {
        PessoaUsuaria pessoa = pessoas.findAll().getFirst();
        pessoa.desativar();
        pessoas.saveAndFlush(pessoa);
    }

    private void errarSenha(int vezes) throws Exception {
        for (int i = 0; i < vezes; i++) {
            errarSenha();
        }
    }

    private long esperaDe(MvcResult resultado) throws Exception {
        return corpoDe(resultado).get("tentar_novamente_em_segundos").asLong();
    }

    private JsonNode corpoDe(MvcResult resultado) throws Exception {
        return json.readTree(resultado.getResponse().getContentAsString());
    }

    /**
     * Relógio que o teste move na mão, no lugar do {@code Clock} da aplicação.
     *
     * <p>Substituir o relógio inteiro, e não só adiantar o banco, é o que faz o
     * teste exercitar o mesmo caminho da produção: quem compara
     * {@code bloqueada_ate} com o agora é o {@code LimitadorTentativas}, e é o
     * agora dele que precisa andar.
     */
    static final class RelogioAjustavel extends Clock {

        private static final Instant INICIO = Instant.parse("2026-08-15T12:00:00Z");

        private Instant momento = INICIO;

        void reiniciar() {
            momento = INICIO;
        }

        void avancar(Duration quanto) {
            momento = momento.plus(quanto);
        }

        @Override
        public ZoneId getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(ZoneId zona) {
            return this;
        }

        @Override
        public Instant instant() {
            return momento;
        }
    }

    @TestConfiguration
    static class RelogioDeTeste {

        @Bean
        @Primary
        RelogioAjustavel relogioAjustavel() {
            return new RelogioAjustavel();
        }
    }
}
