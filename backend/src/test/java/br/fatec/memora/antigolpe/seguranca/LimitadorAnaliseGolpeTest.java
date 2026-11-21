package br.fatec.memora.antigolpe.seguranca;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

@DisplayName("LimitadorAnaliseGolpe — janela deslizante por conta com Clock")
class LimitadorAnaliseGolpeTest {

    @Test
    @DisplayName("permite até o limite por hora, bloqueia excedente com segundos de espera e isola usuários")
    void respeitaLimitePorHoraEPeriodoDeEspera() {
        Instant inicio = Instant.parse("2026-11-21T10:00:00Z");
        Clock relogio = Clock.fixed(inicio, ZoneOffset.UTC);
        LimitadorAnaliseGolpe limitador = new LimitadorAnaliseGolpe(relogio, 2, 5);

        UUID pessoaA = UUID.randomUUID();
        UUID pessoaB = UUID.randomUUID();

        limitador.verificarERegistrar(pessoaA);
        limitador.verificarERegistrar(pessoaA);

        assertThatThrownBy(() -> limitador.verificarERegistrar(pessoaA))
                .isInstanceOf(LimiteAnaliseGolpeExcedido.class)
                .satisfies(
                        ex ->
                                assertThat(((LimiteAnaliseGolpeExcedido) ex).tentarNovamenteEmSegundos())
                                        .isEqualTo(3600L));

        // Outra conta não é afetada.
        limitador.verificarERegistrar(pessoaB);
    }

    @Test
    @DisplayName("libera após expirar janela horária e respeita teto diário de 24h")
    void liberaAposHoraERespeitaTetoDiario() {
        Instant t0 = Instant.parse("2026-11-21T08:00:00Z");
        LimitadorAnaliseGolpe limitador =
                new LimitadorAnaliseGolpe(Clock.fixed(t0, ZoneOffset.UTC), 2, 3);
        UUID pessoa = UUID.randomUUID();

        assertThat(limitador.avaliarERegistrar(pessoa, t0).permitido()).isTrue();
        assertThat(limitador.avaliarERegistrar(pessoa, t0.plusSeconds(10)).permitido()).isTrue();
        assertThat(limitador.avaliarERegistrar(pessoa, t0.plusSeconds(20)).permitido()).isFalse();

        // Após 1h + 1s libera a 3ª chamada, atingindo o teto diário (3).
        Instant t1 = t0.plusSeconds(3601);
        assertThat(limitador.avaliarERegistrar(pessoa, t1).permitido()).isTrue();

        // Após mais 1h, ainda está bloqueado pelo teto diário (faltam 22h).
        Instant t2 = t1.plusSeconds(3601);
        LimitadorAnaliseGolpe.Decisao bloqueioDia = limitador.avaliarERegistrar(pessoa, t2);
        assertThat(bloqueioDia.permitido()).isFalse();
        assertThat(bloqueioDia.tentarNovamenteEmSegundos()).isGreaterThan(3600L);

        // Após 24h desde t0, volta a liberar.
        assertThat(limitador.avaliarERegistrar(pessoa, t0.plusSeconds(86401)).permitido()).isTrue();
    }
}
