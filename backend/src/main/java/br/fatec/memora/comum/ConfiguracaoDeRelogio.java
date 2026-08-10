package br.fatec.memora.comum;

import java.time.Clock;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * O relógio da aplicação, injetado em vez de consultado.
 *
 * <h2>Por que não {@code Instant.now()} espalhado</h2>
 *
 * Metade das regras desta feature é sobre tempo: token de 15 minutos, refresh de
 * 60 dias, bloqueio progressivo, janela do limitador. Testar qualquer uma delas
 * com o relógio do sistema significa esperar de verdade — ou, o que é pior,
 * escrever teste que passa hoje e falha na virada do horário de verão.
 *
 * <p>Com o relógio injetado, um teste troca por
 * {@link Clock#fixed(java.time.Instant, java.time.ZoneId)} e verifica a
 * expiração sem esperar um segundo sequer.
 *
 * <p>UTC, e não o fuso do servidor: toda coluna de instante é
 * {@code TIMESTAMPTZ}, e a trilha de auditoria precisa ser comparável entre
 * máquinas que podem estar configuradas de forma diferente.
 */
@Configuration
public class ConfiguracaoDeRelogio {

    @Bean
    Clock relogio() {
        return Clock.systemUTC();
    }
}
