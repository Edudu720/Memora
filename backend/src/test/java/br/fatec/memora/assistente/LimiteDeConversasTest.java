package br.fatec.memora.assistente;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import br.fatec.memora.assistente.aplicacao.ServicoDeConversa;
import br.fatec.memora.assistente.dominio.EventoDaAssistente;
import br.fatec.memora.assistente.dominio.TipoDeEventoDaAssistente;
import br.fatec.memora.assistente.dominio.UsoDaAssistente;
import br.fatec.memora.assistente.infra.ClienteDaAssistenteSimulado;
import br.fatec.memora.assistente.infra.RepositorioEventoDaAssistente;
import br.fatec.memora.comum.CodigoDeErro;
import br.fatec.memora.suporte.RelogioAjustavel;
import br.fatec.memora.suporte.TesteComBanco;
import br.fatec.memora.assistente.seguranca.LimitePorConta;
import java.time.Duration;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.TestPropertySource;

/**
 * Cenario H10 — o custo nao vira negacao de servico (R7 do research).
 *
 * <h2>Por que ha teto</h2>
 *
 * O endpoint de conversa <b>gasta dinheiro por chamada</b>. Sem teto, uma conta
 * comprometida esvazia a cota do provedor e derruba a assistente para todo
 * mundo — uma negacao de servico que se paga em reais e que ninguem percebe ate
 * a fatura chegar.
 *
 * <h2>Teto de 3, e nao 20</h2>
 *
 * {@code memora.assistente.conversas-por-dia=3} abaixo. Com o padrao, este
 * arquivo faria vinte chamadas so para chegar ao interessante. O numero do
 * produto e {@code LimitePorConta.TETO_PADRAO} e continua sendo decisao aberta
 * da equipe; o que se prova aqui e o <b>comportamento no limite</b>, qualquer
 * que ele seja.
 *
 * <p>A propriedade cria um contexto Spring proprio para esta classe — uma
 * subida a mais, e o container do Postgres continua sendo o mesmo.
 *
 * <h2>⚠️ Divergencia do quickstart, anotada de proposito</h2>
 *
 * O H10 diz esperar "{@code 429} com espera". Duas ressalvas, encontradas ao
 * escrever este teste:
 *
 * <ol>
 *   <li>A conversa e <b>SSE</b>. Quando a cota acaba, o fluxo ja respondeu
 *       {@code 200} e abriu o stream, entao o limite viaja como evento
 *       {@code erro} com o codigo {@code LIMITE_DE_CONVERSAS} — nao como
 *       status HTTP. O {@code 429} do {@link CodigoDeErro} so apareceria se o
 *       limite fosse checado antes de abrir o stream.
 *   <li>Nao ha <b>espera</b> no corpo: {@code ErroResposta} carrega codigo e
 *       mensagem, e a espera de fato e "amanha", que a frase ja diz.
 * </ol>
 *
 * <p>Nenhuma das duas e defeito, e as duas divergem do texto do cenario. Fica
 * escrito aqui e no CLAUDE.md para a equipe decidir se corrige o quickstart ou
 * o transporte.
 */
@TestPropertySource(properties = "memora.assistente.conversas-por-dia=3")
@Import(RelogioAjustavel.NoContexto.class)
@DisplayName("H10 — o custo nao vira negacao de servico")
class LimiteDeConversasTest extends TesteComBanco {

    private static final int TETO = 3;

    @Autowired private ServicoDeConversa conversa;

    @Autowired private ClienteDaAssistenteSimulado assistente;

    @Autowired private RepositorioEventoDaAssistente eventos;

    @Autowired private JdbcTemplate jdbc;

    @Autowired private RelogioAjustavel relogio;

    @Autowired private LimitePorConta limite;

    private UUID pessoaId;
    private UUID outraPessoaId;

    @BeforeEach
    void preparar() {
        relogio.reiniciar();
        pessoaId = inserirPessoa("Ana");
        outraPessoaId = inserirPessoa("Bento");
        assistente.limpar().responderCom("Vou te mostrar o caminho.");
    }

    @AfterEach
    void limpar() {
        jdbc.execute("DELETE FROM evento_da_assistente");
        jdbc.execute("DELETE FROM uso_da_assistente");
        jdbc.execute("DELETE FROM pessoa_usuaria");
        assistente.limpar();
    }

    @Test
    @DisplayName("ate o teto a conversa acontece; a seguinte e recusada")
    void oTetoSegura() {
        for (int i = 1; i <= TETO; i++) {
            final int turno = i;
            assertThat(conversar(pessoaId))
                    .as("conversa %d de %d deveria passar", turno, TETO)
                    .isNotNull();
        }

        assertThatThrownBy(() -> conversar(pessoaId))
                .isInstanceOf(ServicoDeConversa.LimiteAtingido.class);
    }

    @Test
    @DisplayName("o texto acolhe, e nao acusa a pessoa de ter errado algo")
    void oTextoAcolhe() {
        String texto = CodigoDeErro.LIMITE_DE_CONVERSAS.mensagemPadrao();

        // Quem esbarra aqui nao errou nada — so conversou bastante. As
        // palavras abaixo sao as do vocabulario de quem acusa, e nenhuma
        // delas pode aparecer. A do bloqueio de login pode falar em proteger
        // a conta; esta, nao.
        assertThat(texto.toLowerCase())
                .doesNotContain("cota")
                .doesNotContain("excedid")
                .doesNotContain("limite")
                .doesNotContain("bloquead")
                .doesNotContain("erro");

        // O acento importa: a primeira versao deste teste procurava "amanha"
        // sem til e reprovou no CI contra um texto perfeitamente correto. O
        // portao estava errado, nao o codigo — e so o CI viu, porque o Docker
        // nao subia nesta maquina.
        assertThat(texto)
                .as("precisa dizer que ha um amanha, senao a pessoa acha que perdeu o acesso")
                .containsIgnoringCase("amanhã");
    }

    @Test
    @DisplayName("a trilha registra LIMITE_ATINGIDO, e so quando ele e atingido")
    void aTrilhaRegistra() {
        for (int i = 1; i <= TETO; i++) {
            conversar(pessoaId);
        }

        assertThat(limitesNaTrilha(pessoaId))
                .as("ate aqui ninguem esbarrou em nada")
                .isEmpty();

        assertThatThrownBy(() -> conversar(pessoaId))
                .isInstanceOf(ServicoDeConversa.LimiteAtingido.class);

        assertThat(limitesNaTrilha(pessoaId)).hasSize(1);
    }

    @Test
    @DisplayName("insistir depois do teto nao gasta cota nem enche a trilha sem limite")
    void insistirNaoEscalona() {
        for (int i = 1; i <= TETO; i++) {
            conversar(pessoaId);
        }
        for (int i = 0; i < 4; i++) {
            assertThatThrownBy(() -> conversar(pessoaId))
                    .isInstanceOf(ServicoDeConversa.LimiteAtingido.class);
        }

        // Quatro insistencias, quatro registros: um por tentativa. E escrita
        // para quem JA esta autenticado, entao nao e a escrita ilimitada de
        // desconhecido que a revisao da #15 tirou do caminho bloqueado do
        // login. Se um dia incomodar, o caminho e contar de forma limitada —
        // nao deixar de registrar.
        assertThat(limitesNaTrilha(pessoaId)).hasSize(4);
    }

    @Test
    @DisplayName("o teto e por conta: esgotar a de uma nao fecha a porta da outra")
    void oTetoEhPorConta() {
        for (int i = 1; i <= TETO; i++) {
            conversar(pessoaId);
        }
        assertThatThrownBy(() -> conversar(pessoaId))
                .isInstanceOf(ServicoDeConversa.LimiteAtingido.class);

        // Sem este caso, um limitador global passaria nos testes acima e
        // derrubaria a assistente para todo mundo — que e exatamente a
        // negacao de servico que o teto existe para impedir.
        assertThat(conversar(outraPessoaId)).isNotNull();
    }

    @Test
    @DisplayName("mensagens seguidas sao uma conversa so, e nao gastam o teto (FR-053)")
    void mensagensSeguidasNaoGastam() {
        // O defeito que a FR-053 corrigiu: cada turno contava, e o teto de 20
        // virava 20 mensagens — um passo a passo dificil acabava com o dia.
        conversar(pessoaId);
        for (int i = 0; i < TETO * 3; i++) {
            relogio.avancar(Duration.ofMinutes(2));
            assertThat(continuar(pessoaId)).isNotNull();
        }

        assertThat(conversasContadas(pessoaId)).isEqualTo(1);
        assertThat(eventosDoTipo(pessoaId, TipoDeEventoDaAssistente.CONVERSA_INICIADA))
                .as("a trilha registra a conversa, e nao cada turno")
                .hasSize(1);
    }

    @Test
    @DisplayName("no teto, a conversa em curso continua ate terminar (FR-053)")
    void conversaEmCursoContinuaNoTeto() {
        for (int i = 1; i <= TETO; i++) {
            conversar(pessoaId);
        }

        // A terceira conversa acabou de abrir; a pessoa esta no meio dela.
        relogio.avancar(Duration.ofMinutes(5));
        assertThat(continuar(pessoaId)).isNotNull();

        // Meia hora depois, e outra conversa — e essa nao cabe mais.
        assertThatThrownBy(() -> conversar(pessoaId))
                .isInstanceOf(ServicoDeConversa.LimiteAtingido.class);
    }

    @Test
    @DisplayName("turnos simultaneos da mesma conta contam todos, sem erro (corrida no contador)")
    void turnosSimultaneosNaoSePerdem() throws Exception {
        // Relogio parado: os 40 turnos sao da mesma conversa ate o 30o, e o 31o
        // abre a segunda. Em qualquer ordem de chegada o resultado e o mesmo:
        // 2 conversas novas, 38 continuacoes, nenhum recusado (teto 3), e o
        // contador termina com 2 conversas e 10 turnos na atual.
        // Sem trava, todos leem o mesmo estado: a primeira chamada do dia
        // colide na chave primaria e o contador perde atualizacoes.
        final int turnos = 40;
        ExecutorService pool = Executors.newFixedThreadPool(8);
        CountDownLatch largada = new CountDownLatch(1);
        try {
            List<Future<UsoDaAssistente.Desfecho>> futuros = new ArrayList<>();
            for (int i = 0; i < turnos; i++) {
                futuros.add(
                        pool.submit(
                                () -> {
                                    largada.await();
                                    return limite.registrarTurno(pessoaId);
                                }));
            }
            largada.countDown();

            Map<UsoDaAssistente.Desfecho, Long> desfechos = new HashMap<>();
            for (Future<UsoDaAssistente.Desfecho> futuro : futuros) {
                desfechos.merge(futuro.get(30, TimeUnit.SECONDS), 1L, Long::sum);
            }

            assertThat(desfechos)
                    .containsEntry(UsoDaAssistente.Desfecho.NOVA_CONVERSA, 2L)
                    .containsEntry(UsoDaAssistente.Desfecho.CONTINUA, 38L)
                    .doesNotContainKey(UsoDaAssistente.Desfecho.TETO_ATINGIDO);
        } finally {
            pool.shutdownNow();
        }

        assertThat(conversasContadas(pessoaId)).isEqualTo(2);
        assertThat(
                        jdbc.queryForObject(
                                "SELECT turnos_na_conversa FROM uso_da_assistente WHERE pessoa_id = ?",
                                Integer.class,
                                pessoaId))
                .isEqualTo(10);
    }

    /** Abre uma conversa nova: meia hora de pausa, e o turno. */
    private ServicoDeConversa.Resultado conversar(UUID quem) {
        relogio.avancar(UsoDaAssistente.PAUSA_QUE_ENCERRA_A_CONVERSA);
        return continuar(quem);
    }

    /** Um turno, sem andar o relogio: segue a conversa em curso, se houver. */
    private ServicoDeConversa.Resultado continuar(UUID quem) {
        return conversa.conversar(quem, "como vejo as fotos do meu neto?", List.of(), t -> {});
    }

    private Integer conversasContadas(UUID quem) {
        return jdbc.queryForObject(
                "SELECT conversas FROM uso_da_assistente WHERE pessoa_id = ?",
                Integer.class,
                quem);
    }

    private List<EventoDaAssistente> eventosDoTipo(UUID quem, TipoDeEventoDaAssistente tipo) {
        return eventos.findByPessoaIdAndTipoOrderByOcorridoEmDesc(quem, tipo);
    }

    private List<EventoDaAssistente> limitesNaTrilha(UUID quem) {
        return eventos.findByPessoaIdAndTipoOrderByOcorridoEmDesc(
                quem, TipoDeEventoDaAssistente.LIMITE_ATINGIDO);
    }

    private UUID inserirPessoa(String nome) {
        UUID id = UUID.randomUUID();
        jdbc.update(
                """
                INSERT INTO pessoa_usuaria
                    (id, nome_tratamento, estado, criada_em, falhas_consecutivas)
                VALUES (?, ?, 'ATIVA', now(), 0)
                """,
                id,
                nome);
        return id;
    }
}
