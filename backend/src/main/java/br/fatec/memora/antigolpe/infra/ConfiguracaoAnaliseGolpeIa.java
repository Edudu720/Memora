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

    @Bean
    @Conditional(CondicaoProvedorAntigolpe.EhGemini.class)
    ClienteAnaliseGolpeGemini clienteAnaliseGolpeGemini(
            @Value("${memora.assistente.gemini.chave:}") String chave,
            @Value("${memora.assistente.gemini.modelo:gemini-3.8-flash}") String modelo,
            @Value("${memora.assistente.gemini.url-base:"
                            + ClienteAnaliseGolpeGemini.URL_BASE_PADRAO
                            + "}")
                    String urlBase,
            @Value("${memora.assistente.gemini.timeout-conexao-segundos:10}") long conexao,
            @Value("${memora.assistente.gemini.timeout-leitura-segundos:60}") long leitura) {

        ClienteAnaliseGolpeGemini cliente =
                new ClienteAnaliseGolpeGemini(
                        chave,
                        modelo,
                        urlBase,
                        Duration.ofSeconds(conexao),
                        Duration.ofSeconds(leitura));

        LOG.info("Analise antigolpe configurada com provedor gemini, modelo {}.", modelo);
        return cliente;
    }
}
