package br.fatec.memora.suporte;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;

/**
 * Relógio que o teste move na mão, no lugar do {@code Clock} da aplicação.
 *
 * <p>Substituir o relógio inteiro, e não só adiantar o banco, é o que faz o
 * teste exercitar o mesmo caminho da produção: quem compara o instante gravado
 * com o agora é o componente da aplicação, e é o agora <b>dele</b> que precisa
 * andar. Assim uma regra de 81 minutos, como a escada de bloqueio, ou de meia
 * hora, como a pausa que encerra uma conversa, cabe em milissegundos.
 *
 * <p>Para usar: {@code @Import(RelogioAjustavel.NoContexto.class)} na classe de
 * teste, e {@code @Autowired RelogioAjustavel}. O {@code @Import} cria um
 * contexto Spring próprio para a classe — uma subida a mais, e o container do
 * Postgres continua sendo o mesmo.
 */
public final class RelogioAjustavel extends Clock {

    private static final Instant INICIO = Instant.parse("2026-08-15T12:00:00Z");

    private Instant momento = INICIO;

    /** Volta ao instante inicial. Chame no {@code @BeforeEach}. */
    public void reiniciar() {
        momento = INICIO;
    }

    /** Anda o relógio. */
    public void avancar(Duration quanto) {
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

    /** Põe o relógio no lugar do da aplicação. */
    @TestConfiguration
    public static class NoContexto {

        @Bean
        @Primary
        RelogioAjustavel relogioAjustavel() {
            return new RelogioAjustavel();
        }
    }
}
