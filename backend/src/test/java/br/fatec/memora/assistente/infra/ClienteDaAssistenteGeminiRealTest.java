package br.fatec.memora.assistente.infra;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;

/**
 * Uma conversa de verdade com o Gemini — opcional, e pulada sem chave (T063).
 *
 * <h2>Quando roda</h2>
 *
 * Só com {@code GEMINI_API_KEY} no ambiente. O CI não tem a chave, e quem clona
 * o repositório também não: o teste aparece como "pulado", e a suíte segue sem
 * rede.
 *
 * <h2>O que conversa, e o que não conversa</h2>
 *
 * Uma pergunta curta e <b>fictícia</b>, de ninguém. Com chave do nível
 * gratuito, o Google pode usar o conteúdo para melhorar os produtos dele e
 * revisores humanos podem lê-lo (ADR-002, FR-051): <b>nunca ponha aqui texto de
 * conversa real de uma pessoa</b>, nem dado pessoal, nem o nome de ninguém.
 *
 * <p>Os modelos de nível gratuito têm cota por minuto; uma pergunta por
 * execução não a esgota. A chave nunca é impressa.
 */
@DisplayName("Gemini de verdade (opcional)")
@EnabledIfEnvironmentVariable(named = "GEMINI_API_KEY", matches = ".+")
class ClienteDaAssistenteGeminiRealTest {

    @Test
    @DisplayName("uma pergunta curta e ficticia devolve texto, em pedacos")
    void respondeUmaPergunta() {
        try (ClienteDaAssistenteGemini cliente =
                new ClienteDaAssistenteGemini(
                        System.getenv("GEMINI_API_KEY"),
                        "gemini-3.8-flash",
                        ClienteDaAssistenteGemini.URL_BASE_PADRAO,
                        Duration.ofSeconds(10),
                        Duration.ofSeconds(60))) {

            List<String> trechos = new ArrayList<>();
            ClienteDaAssistente.Resposta resposta =
                    cliente.conversar(
                            new ClienteDaAssistente.Pedido(
                                    PersonaDaMemora.INSTRUCAO,
                                    "# Aplicativos que você pode ensinar E abrir\n\n"
                                            + "- WhatsApp (com.whatsapp): conversar com a família\n\n"
                                            + "# Serviços que você SÓ ensina, e nunca abre\n\n"
                                            + "- Gov.br: documentos do governo",
                                    List.of(),
                                    "Como aumento a letra do celular?"),
                            trechos::add);

            assertThat(resposta.texto()).as("veio texto").isNotBlank();
            assertThat(trechos).as("veio em pedacos, para a tela se mexer").isNotEmpty();
            assertThat(String.join("", trechos)).isEqualTo(resposta.texto());
        }
    }
}
