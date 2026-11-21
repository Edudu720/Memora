package br.fatec.memora.antigolpe.infra;

import java.time.Duration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Conditional;
import org.springframework.context.annotation.Configuration;

/**
 * Configura o adaptador Gemini para análise antigolpe quando {@code memora.assistente.provedor}
 * resolve para Gemini.
 */
@Configuration
public class ConfiguracaoAnaliseGolpeIa {

    private static final Logger LOG = LoggerFactory.getLogger(ConfiguracaoAnaliseGolpeIa.class);
    static final long TIMEOUT_LEITURA_MAXIMO_SEGUNDOS = 25L;

    @Bean
    @Conditional(CondicaoProvedorAntigolpe.EhGemini.class)
    ClienteAnaliseGolpeGemini clienteAnaliseGolpeGemini(
            @Value("${memora.assistente.gemini.chave:}") String chave,
            @Value("${memora.assistente.gemini.modelo:gemini-3.6-flash}") String modelo,
            @Value("${memora.assistente.gemini.modelo-reserva:gemini-3.5-flash-lite}")
                    String modeloReserva,
            @Value("${memora.assistente.gemini.url-base:"
                            + ClienteAnaliseGolpeGemini.URL_BASE_PADRAO
                            + "}")
                    String urlBase,
            @Value("${memora.assistente.gemini.timeout-conexao-segundos:10}") long conexao,
            @Value("${memora.antigolpe.gemini.timeout-leitura-segundos:${memora.assistente.gemini.timeout-leitura-segundos:20}}")
                    long leitura) {

        long leituraEfetiva =
                leitura > 0 ? Math.min(leitura, TIMEOUT_LEITURA_MAXIMO_SEGUNDOS) : leitura;

        ClienteAnaliseGolpeGemini cliente =
                new ClienteAnaliseGolpeGemini(
                        chave,
                        modelo,
                        modeloReserva,
                        urlBase,
                        Duration.ofSeconds(conexao),
                        Duration.ofSeconds(leituraEfetiva));

        LOG.info(
                "Analise antigolpe configurada com provedor gemini, modelo {} (reserva: {}).",
                modelo,
                modeloReserva);
        return cliente;
    }
}
