package br.fatec.memora.antigolpe.infra;

import static org.assertj.core.api.Assertions.assertThat;

import br.fatec.memora.antigolpe.aplicacao.AnalisadorDeterministicoDeGolpes;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;

@DisplayName("ConfiguracaoAnaliseGolpeIa — seleção de provedor sem banco")
class ConfiguracaoAnaliseGolpeIaTest {

    private static final String CHAVE = "chave-falsa-0123456789-ABCDEF";

    private ApplicationContextRunner contexto() {
        return new ApplicationContextRunner()
                .withUserConfiguration(
                        ConfiguracaoAnaliseGolpeIa.class,
                        ClienteAnaliseGolpeSimulado.class,
                        AnalisadorDeterministicoDeGolpes.class);
    }

    private ApplicationContextRunner emProducao() {
        return contexto().withInitializer(c -> c.getEnvironment().addActiveProfile("producao"));
    }

    @Test
    @DisplayName("sem propriedade configurada: sobe com o simulado")
    void padraoEhOSimulado() {
        contexto()
                .run(
                        c -> {
                            assertThat(c).hasNotFailed();
                            assertThat(c).hasSingleBean(ClienteAnaliseGolpe.class);
                            assertThat(c).hasSingleBean(ClienteAnaliseGolpeSimulado.class);
                            assertThat(c).doesNotHaveBean(ClienteAnaliseGolpeGemini.class);
                        });
    }

    @Test
    @DisplayName("provedor=simulado explícito também seleciona o simulado")
    void simuladoExplicito() {
        contexto()
                .withPropertyValues("memora.assistente.provedor=simulado")
                .run(
                        c -> {
                            assertThat(c).hasNotFailed();
                            assertThat(c).hasSingleBean(ClienteAnaliseGolpeSimulado.class);
                            assertThat(c).doesNotHaveBean(ClienteAnaliseGolpeGemini.class);
                        });
    }

    @Test
    @DisplayName("provedor=gemini com chave: seleciona Gemini e exclui simulado")
    void geminiComChave() {
        contexto()
                .withPropertyValues(
                        "memora.assistente.provedor=gemini",
                        "memora.assistente.gemini.chave=" + CHAVE)
                .run(
                        c -> {
                            assertThat(c).hasNotFailed();
                            assertThat(c).hasSingleBean(ClienteAnaliseGolpe.class);
                            assertThat(c).hasSingleBean(ClienteAnaliseGolpeGemini.class);
                            assertThat(c).doesNotHaveBean(ClienteAnaliseGolpeSimulado.class);
                        });
    }

    @Test
    @DisplayName("provedor=gemini sem chave falha na subida")
    void geminiSemChaveFalha() {
        contexto()
                .withPropertyValues("memora.assistente.provedor=gemini")
                .run(
                        c -> {
                            assertThat(c).hasFailed();
                            assertThat(raiz(c.getStartupFailure()).getMessage())
                                    .contains("GEMINI_API_KEY");
                        });
    }

    @Test
    @DisplayName("perfil producao sem chave falha e com simulado explicito recusa")
    void producaoExigeGemini() {
        emProducao()
                .run(
                        c -> {
                            assertThat(c).hasFailed();
                            assertThat(raiz(c.getStartupFailure()).getMessage())
                                    .contains("GEMINI_API_KEY");
                        });

        emProducao()
                .withPropertyValues(
                        "memora.assistente.provedor=simulado",
                        "memora.assistente.gemini.chave=" + CHAVE)
                .run(
                        c -> {
                            assertThat(c).hasFailed();
                            assertThat(raiz(c.getStartupFailure()).getMessage())
                                    .contains("producao")
                                    .contains("simulado");
                        });

        emProducao()
                .withPropertyValues("memora.assistente.gemini.chave=" + CHAVE)
                .run(
                        c -> {
                            assertThat(c).hasNotFailed();
                            assertThat(c).hasSingleBean(ClienteAnaliseGolpeGemini.class);
                            assertThat(c).doesNotHaveBean(ClienteAnaliseGolpeSimulado.class);
                        });
    }

    @Test
    @DisplayName("provedor desconhecido falha na subida sem cair em simulado")
    void provedorDesconhecidoFalha() {
        contexto()
                .withPropertyValues("memora.assistente.provedor=gemni")
                .run(
                        c -> {
                            assertThat(c).hasFailed();
                            assertThat(raiz(c.getStartupFailure()).getMessage()).contains("gemni");
                        });
    }

    private static Throwable raiz(Throwable falha) {
        Throwable atual = falha;
        while (atual.getCause() != null && atual.getCause() != atual) {
            atual = atual.getCause();
        }
        return atual;
    }
}
