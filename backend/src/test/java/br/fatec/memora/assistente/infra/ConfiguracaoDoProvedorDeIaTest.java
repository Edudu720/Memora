package br.fatec.memora.assistente.infra;

import static org.assertj.core.api.Assertions.assertThat;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;

/**
 * Qual assistente existe em cada configuração, e quando a subida falha (T064).
 *
 * <h2>Por que {@code ApplicationContextRunner} e não {@code @SpringBootTest}</h2>
 *
 * A seleção é só conversa entre propriedades, perfil e dois beans. Subir a
 * aplicação inteira — com banco e um Hikari de 20 conexões por contexto — para
 * provar isso seria o caminho do {@code too many clients already} que o
 * {@code TesteComBanco} documenta. Aqui o contexto tem exatamente a
 * configuração e o simulado, e custa milissegundos.
 *
 * <h2>O portão de produção</h2>
 *
 * É o mesmo desenho do {@code EnviadorDeCodigo} (R8): no perfil
 * {@code producao}, sem chave, a aplicação <b>não sobe</b>. Subir mesmo assim
 * faria a assistente responder erro a cada pergunta de uma pessoa idosa, e a
 * falha apareceria para ela em vez de para quem implanta.
 */
@DisplayName("Seleção do provedor de IA (T064)")
class ConfiguracaoDoProvedorDeIaTest {

    private static final String CHAVE = "chave-falsa-0123456789-ABCDEF";

    private ApplicationContextRunner contexto() {
        return new ApplicationContextRunner()
                .withUserConfiguration(
                        ConfiguracaoDoProvedorDeIa.class, ClienteDaAssistenteSimulado.class);
    }

    private ApplicationContextRunner emProducao() {
        return contexto().withInitializer(c -> c.getEnvironment().addActiveProfile("producao"));
    }

    @Test
    @DisplayName("sem nada configurado: o simulado, sem rede e sem chave")
    void padraoEhOSimulado() {
        contexto()
                .run(
                        c -> {
                            assertThat(c).hasNotFailed();
                            assertThat(c).hasSingleBean(ClienteDaAssistente.class);
                            assertThat(c).hasSingleBean(ClienteDaAssistenteSimulado.class);
                            assertThat(c).doesNotHaveBean(ClienteDaAssistenteGemini.class);
                        });
    }

    @Test
    @DisplayName("provedor=simulado explicito tambem e o simulado")
    void simuladoExplicito() {
        contexto()
                .withPropertyValues("memora.assistente.provedor=simulado")
                .run(c -> assertThat(c).hasSingleBean(ClienteDaAssistenteSimulado.class));
    }

    @Test
    @DisplayName("provedor=gemini com chave: o adaptador real entra e o simulado sai")
    void geminiComChave() {
        contexto()
                .withPropertyValues(
                        "memora.assistente.provedor=gemini",
                        "memora.assistente.gemini.chave=" + CHAVE)
                .run(
                        c -> {
                            assertThat(c).hasNotFailed();
                            assertThat(c).hasSingleBean(ClienteDaAssistente.class);
                            assertThat(c).hasSingleBean(ClienteDaAssistenteGemini.class);
                            assertThat(c).doesNotHaveBean(ClienteDaAssistenteSimulado.class);
                        });
    }

    @Test
    @DisplayName("provedor=gemini SEM chave: a aplicacao nao sobe, e a mensagem diz o que falta")
    void geminiSemChave() {
        contexto()
                .withPropertyValues("memora.assistente.provedor=gemini")
                .run(
                        c -> {
                            assertThat(c).hasFailed();
                            assertThat(rootCause(c.getStartupFailure()).getMessage())
                                    .contains("GEMINI_API_KEY")
                                    .contains("nao configurada");
                        });
    }

    @Test
    @DisplayName("producao SEM chave: nao sobe, mesmo sem ninguem ter pedido o gemini")
    void producaoSemChave() {
        emProducao()
                .run(
                        c -> {
                            assertThat(c).hasFailed();
                            assertThat(rootCause(c.getStartupFailure()).getMessage())
                                    .contains("GEMINI_API_KEY")
                                    .contains("nao configurada");
                        });
    }

    @Test
    @DisplayName("producao COM chave: sobe com o gemini, e o simulado nao existe")
    void producaoComChave() {
        emProducao()
                .withPropertyValues("memora.assistente.gemini.chave=" + CHAVE)
                .run(
                        c -> {
                            assertThat(c).hasNotFailed();
                            assertThat(c).hasSingleBean(ClienteDaAssistenteGemini.class);
                            assertThat(c).doesNotHaveBean(ClienteDaAssistenteSimulado.class);
                        });
    }

    @Test
    @DisplayName("producao pedindo o simulado: recusa em voz alta, em vez de ignorar o pedido")
    void producaoNaoAceitaSimulado() {
        emProducao()
                .withPropertyValues(
                        "memora.assistente.provedor=simulado",
                        "memora.assistente.gemini.chave=" + CHAVE)
                .run(
                        c -> {
                            assertThat(c).hasFailed();
                            assertThat(rootCause(c.getStartupFailure()).getMessage())
                                    .contains("producao")
                                    .contains("simulado");
                        });
    }

    @Test
    @DisplayName("provedor com erro de digitacao nao cai no simulado em silencio")
    void valorDesconhecido() {
        contexto()
                .withPropertyValues("memora.assistente.provedor=gemni")
                .run(
                        c -> {
                            assertThat(c).hasFailed();
                            assertThat(rootCause(c.getStartupFailure()).getMessage())
                                    .contains("gemni");
                        });
    }

    @Test
    @DisplayName("a chave nao aparece na mensagem de falha de chave malformada")
    void chaveMalformadaNaoVaza() {
        contexto()
                .withPropertyValues(
                        "memora.assistente.provedor=gemini",
                        "memora.assistente.gemini.chave=com espaco segredo-do-teste")
                .run(
                        c -> {
                            assertThat(c).hasFailed();
                            assertThat(rootCause(c.getStartupFailure()).getMessage())
                                    .doesNotContain("segredo-do-teste");
                        });
    }

    @Test
    @DisplayName("sobe com reserva desativada quando modelo-reserva esta vazio")
    void reservaVaziaAceita() {
        contexto()
                .withPropertyValues(
                        "memora.assistente.provedor=gemini",
                        "memora.assistente.gemini.chave=" + CHAVE,
                        "memora.assistente.gemini.modelo=gemini-3.6-flash",
                        "memora.assistente.gemini.modelo-reserva=",
                        "memora.assistente.gemini.tentativas-primario=2",
                        "memora.assistente.gemini.espera-retentativa-ms=0")
                .run(
                        c -> {
                            assertThat(c).hasNotFailed();
                            assertThat(c).hasSingleBean(ClienteDaAssistenteGemini.class);
                        });
    }

    @Test
    @DisplayName("reserva igual ao modelo principal registra (reserva: nenhum) no log de subida")
    void reservaIgualAoPrincipalRegistraNenhumNoLog() {
        Logger logger = (Logger) LoggerFactory.getLogger(ConfiguracaoDoProvedorDeIa.class);
        ListAppender<ILoggingEvent> appender = new ListAppender<>();
        appender.start();
        logger.addAppender(appender);
        try {
            contexto()
                    .withPropertyValues(
                            "memora.assistente.provedor=gemini",
                            "memora.assistente.gemini.chave=" + CHAVE,
                            "memora.assistente.gemini.modelo=gemini-3.6-flash",
                            "memora.assistente.gemini.modelo-reserva=gemini-3.6-flash")
                    .run(
                            c -> {
                                assertThat(c).hasNotFailed();
                                assertThat(appender.list)
                                        .extracting(ILoggingEvent::getFormattedMessage)
                                        .anyMatch(
                                                msg ->
                                                        msg.contains("modelo gemini-3.6-flash")
                                                                && msg.contains("(reserva: nenhum)"));
                            });
        } finally {
            logger.detachAppender(appender);
            appender.stop();
        }
    }

    @Test
    @DisplayName("modelo-reserva malformado ou tentativas invalidas derrubam subida sem vazar chave")
    void resilienciaInvalidaFalhaNaSubida() {
        contexto()
                .withPropertyValues(
                        "memora.assistente.provedor=gemini",
                        "memora.assistente.gemini.chave=" + CHAVE,
                        "memora.assistente.gemini.modelo-reserva=gemini/../invalido")
                .run(
                        c -> {
                            assertThat(c).hasFailed();
                            assertThat(rootCause(c.getStartupFailure()).getMessage())
                                    .contains("modelo-reserva")
                                    .doesNotContain(CHAVE);
                        });

        contexto()
                .withPropertyValues(
                        "memora.assistente.provedor=gemini",
                        "memora.assistente.gemini.chave=" + CHAVE,
                        "memora.assistente.gemini.tentativas-primario=0")
                .run(
                        c -> {
                            assertThat(c).hasFailed();
                            assertThat(rootCause(c.getStartupFailure()).getMessage())
                                    .contains("tentativas-primario")
                                    .doesNotContain(CHAVE);
                        });
    }

    private static Throwable rootCause(Throwable falha) {
        Throwable atual = falha;
        while (atual.getCause() != null && atual.getCause() != atual) {
            atual = atual.getCause();
        }
        return atual;
    }
}
