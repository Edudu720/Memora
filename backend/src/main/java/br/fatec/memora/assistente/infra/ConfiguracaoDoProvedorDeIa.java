package br.fatec.memora.assistente.infra;

import java.time.Duration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Conditional;
import org.springframework.context.annotation.Configuration;

/**
 * Liga o adaptador do Gemini quando ele é o provedor escolhido (T064).
 *
 * <h2>A chave não tem padrão, e a ausência dela derruba a subida</h2>
 *
 * Mesma família do {@code EnviadorDeCodigo}, e com a razão da R8: subir sem
 * chave faria a assistente responder erro a cada pergunta, e a falha apareceria
 * para a pessoa idosa em vez de para quem implanta. Por isso a diferença para
 * {@code ConfiguracaoDeToken}, que sorteia um valor e segue com WARN: lá o
 * prejuízo é interno e reversível; aqui não existe valor sorteado que faça uma
 * chamada ao Google funcionar.
 *
 * <p>Nenhum valor de chave existe no repositório — nem de exemplo.
 *
 * <h2>Prazos explícitos</h2>
 *
 * Conexão e leitura têm número escrito (padrões abaixo, em segundos), e não o
 * "sem limite" do cliente HTTP. A leitura é o tempo <b>sem receber nada</b>,
 * não o da resposta inteira: um modelo que "pensa" demora a começar, e uma
 * resposta longa pode levar minutos transmitindo sem estar travada. O teto de
 * 120 s do {@code ControladorConversa} continua valendo por cima.
 */
@Configuration
public class ConfiguracaoDoProvedorDeIa {

    private static final Logger LOG = LoggerFactory.getLogger(ConfiguracaoDoProvedorDeIa.class);

    /**
     * O adaptador do Gemini.
     *
     * <p>O {@code AutoCloseable} do adaptador é o método de destruição: o Spring
     * o chama no fim do contexto e o vigia de leitura não vaza.
     */
    @Bean
    @Conditional(ProvedorEscolhido.EhGemini.class)
    ClienteDaAssistenteGemini clienteDaAssistenteGemini(
            @Value("${memora.assistente.gemini.chave:}") String chave,
            @Value("${memora.assistente.gemini.modelo:gemini-3.6-flash}") String modelo,
            @Value("${memora.assistente.gemini.modelo-reserva:gemini-3.5-flash-lite}")
                    String modeloReserva,
            @Value("${memora.assistente.gemini.url-base:" + ClienteDaAssistenteGemini.URL_BASE_PADRAO + "}")
                    String urlBase,
            @Value("${memora.assistente.gemini.timeout-conexao-segundos:10}") long conexao,
            @Value("${memora.assistente.gemini.timeout-leitura-segundos:60}") long leitura,
            @Value("${memora.assistente.gemini.tentativas-primario:2}") int tentativasPrimario,
            @Value("${memora.assistente.gemini.espera-retentativa-ms:500}")
                    long esperaRetentativaMs) {

        ClienteDaAssistenteGemini cliente =
                new ClienteDaAssistenteGemini(
                        chave,
                        modelo,
                        modeloReserva,
                        urlBase,
                        Duration.ofSeconds(conexao),
                        Duration.ofSeconds(leitura),
                        tentativasPrimario,
                        Duration.ofMillis(esperaRetentativaMs));

        String modeloLimpo = modelo == null ? "" : modelo.strip();
        String reservaLimpa = modeloReserva == null ? "" : modeloReserva.strip();
        String reservaLog =
                reservaLimpa.isEmpty() || reservaLimpa.equals(modeloLimpo)
                        ? "nenhum"
                        : reservaLimpa;
        LOG.info("Provedor de IA: gemini, modelo {} (reserva: {}).", modeloLimpo, reservaLog);
        // O nivel gratuito do Gemini deixa o Google usar o conteudo para melhorar
        // os produtos dele e revisores humanos podem le-lo. Desde 2026-10-03 isso
        // e RISCO ACEITO, nao violacao: a FR-051 foi reescrita e a Emenda 1 ao
        // Principio I (constituicao v1.1.0) o permite, desde que haja aviso
        // permanente na conversa, consentimento antes da primeira mensagem e
        // nenhum dado da pessoa enviado ao servico. A saida e trocar por um
        // servico que nao treine assim que houver verba. Nao ha como saber daqui
        // se a chave e gratuita ou paga, entao o aviso e condicional e fica
        // visivel a cada subida (ADR-002).
        LOG.warn(
                "Se a chave GEMINI_API_KEY for do nivel GRATUITO, o Google pode usar o conteudo "
                        + "das conversas para melhorar os produtos dele e revisores humanos "
                        + "podem le-lo. Isso e risco aceito (FR-051 reescrita, Emenda 1 ao "
                        + "Principio I), condicionado a aviso permanente na conversa, "
                        + "consentimento antes da primeira mensagem e nenhum dado da pessoa "
                        + "enviado ao servico. A saida e trocar por um servico que nao treine "
                        + "assim que houver verba (T086). Ver "
                        + "docs/architecture/adr-002-provedor-de-ia.md.");
        return cliente;
    }
}
