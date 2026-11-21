package br.fatec.memora.antigolpe.infra;

import br.fatec.memora.antigolpe.dominio.NivelRiscoGolpe;
import br.fatec.memora.antigolpe.dominio.ResultadoAnaliseGolpe;
import br.fatec.memora.assistente.infra.AssistenteIndisponivel;
import br.fatec.memora.assistente.infra.AssistenteIndisponivel.Motivo;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.HttpTimeoutException;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.regex.Pattern;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;
import tools.jackson.databind.node.ArrayNode;
import tools.jackson.databind.node.ObjectNode;

/**
 * Adaptador Gemini REST ({@code :generateContent}) para análise estruturada antigolpe (ADR-002).
 *
 * <p>Usa JDK {@link HttpClient} e Jackson 3 ({@link JsonMapper}), envia a chave exclusivamente no
 * cabeçalho {@code x-goog-api-key}, separa {@code systemInstruction} do conteúdo do usuário e
 * descarta o corpo de erro do provedor externo sem carregá-lo em memória.
 */
public class ClienteAnaliseGolpeGemini implements ClienteAnaliseGolpe, AutoCloseable {

    public static final String URL_BASE_PADRAO =
            "https://generativelanguage.googleapis.com/v1beta";
    public static final String MODELO_RESERVA_PADRAO = "gemini-3.5-flash-lite";

    static final String CABECALHO_DA_CHAVE = "x-goog-api-key";

    private static final Logger LOG = LoggerFactory.getLogger(ClienteAnaliseGolpeGemini.class);

    private static final Pattern FORMATO_DO_MODELO = Pattern.compile("[A-Za-z0-9._-]+");
    private static final Pattern FORMATO_DA_CHAVE = Pattern.compile("[\\x21-\\x7E]+");

    private final JsonMapper json = JsonMapper.builder().build();
    private final HttpClient http;
    private final String chave;
    private final String modelo;
    private final String modeloReserva;
    private final URI endereco;
    private final URI enderecoReserva;
    private final Duration leitura;
    private final Duration esperaEntreTentativas;

    public ClienteAnaliseGolpeGemini(
            String chave, String modelo, String urlBase, Duration conexao, Duration leitura) {
        this(chave, modelo, MODELO_RESERVA_PADRAO, urlBase, conexao, leitura);
    }

    public ClienteAnaliseGolpeGemini(
            String chave,
            String modelo,
            String modeloReserva,
            String urlBase,
            Duration conexao,
            Duration leitura) {
        this(
                chave,
                modelo,
                modeloReserva,
                urlBase,
                conexao,
                leitura,
                Duration.ofMillis(100));
    }

    ClienteAnaliseGolpeGemini(
            String chave,
            String modelo,
            String modeloReserva,
            String urlBase,
            Duration conexao,
            Duration leitura,
            Duration esperaEntreTentativas) {
        if (chave == null || chave.isBlank()) {
            throw new IllegalStateException(
                    "GEMINI_API_KEY nao configurada: o provedor 'gemini' precisa da chave da API "
                            + "(variavel de ambiente GEMINI_API_KEY).");
        }
        if (!FORMATO_DA_CHAVE.matcher(chave.strip()).matches()) {
            throw new IllegalStateException(
                    "GEMINI_API_KEY com formato invalido: so caracteres ASCII visiveis, sem "
                            + "espacos nem quebras de linha.");
        }
        if (modelo == null || !FORMATO_DO_MODELO.matcher(modelo.strip()).matches()) {
            throw new IllegalStateException(
                    "memora.assistente.gemini.modelo invalido: use so letras, numeros, ponto, "
                            + "hifen e sublinhado.");
        }
        if (urlBase == null || urlBase.isBlank()) {
            throw new IllegalStateException("memora.assistente.gemini.url-base nao pode ser vazia.");
        }
        String base = urlBase.strip();
        if (base.endsWith("/")) {
            base = base.substring(0, base.length() - 1);
        }
        URI uriBase;
        try {
            uriBase = URI.create(base);
        } catch (IllegalArgumentException invalida) {
            throw new IllegalStateException(
                    "memora.assistente.gemini.url-base invalida: formato de URI incorreto.");
        }
        String esquema = uriBase.getScheme();
        if (esquema == null
                || (!esquema.equalsIgnoreCase("http") && !esquema.equalsIgnoreCase("https"))
                || uriBase.getHost() == null
                || uriBase.getHost().isBlank()) {
            throw new IllegalStateException(
                    "memora.assistente.gemini.url-base invalida: use http ou https com host valido.");
        }
        if (conexao == null || conexao.isZero() || conexao.isNegative()) {
            throw new IllegalStateException(
                    "memora.assistente.gemini.timeout-conexao-segundos invalido: deve ser maior que zero.");
        }
        if (leitura == null || leitura.isZero() || leitura.isNegative()) {
            throw new IllegalStateException(
                    "memora.assistente.gemini.timeout-leitura-segundos invalido: deve ser maior que zero.");
        }

        String modeloPrincipal = modelo.strip();
        String reservaNormalizada = null;
        URI reservaUri = null;
        if (modeloReserva != null && !modeloReserva.isBlank()) {
            String candidatoReserva = modeloReserva.strip();
            if (!FORMATO_DO_MODELO.matcher(candidatoReserva).matches()) {
                throw new IllegalStateException(
                        "memora.assistente.gemini.modelo-reserva invalido: use so letras, "
                                + "numeros, ponto, hifen e sublinhado.");
            }
            if (!candidatoReserva.equals(modeloPrincipal)) {
                reservaNormalizada = candidatoReserva;
                reservaUri =
                        URI.create(base + "/models/" + candidatoReserva + ":generateContent");
            }
        }

        this.chave = chave.strip();
        this.modelo = modeloPrincipal;
        this.modeloReserva = reservaNormalizada;
        this.endereco = URI.create(base + "/models/" + modeloPrincipal + ":generateContent");
        this.enderecoReserva = reservaUri;
        this.leitura = leitura;
        this.esperaEntreTentativas =
                esperaEntreTentativas != null && !esperaEntreTentativas.isNegative()
                        ? esperaEntreTentativas
                        : Duration.ZERO;
        this.http =
                HttpClient.newBuilder()
                        .connectTimeout(conexao)
                        .version(HttpClient.Version.HTTP_1_1)
                        .build();
    }

    String modelo() {
        return modelo;
    }

    String modeloReserva() {
        return modeloReserva;
    }

    Duration leitura() {
        return leitura;
    }

    @Override
    public ResultadoAnaliseGolpe analisar(String conteudo) {
        String corpoRequisicao = montarCorpo(conteudo);
        AssistenteIndisponivel ultimaFalha = null;

        for (int tentativa = 1; tentativa <= 2; tentativa++) {
            try {
                return executarRequisicao(endereco, corpoRequisicao);
            } catch (AssistenteIndisponivel falha) {
                ultimaFalha = falha;
                if (!ehFalhaTransitoria(falha.motivo())) {
                    throw falha;
                }
                if (Thread.currentThread().isInterrupted()) {
                    throw new AssistenteIndisponivel(Motivo.REDE, "interrompido");
                }
                if (tentativa == 1) {
                    LOG.warn(
                            "Tentativa 1/2 na analise antigolpe com modelo {} falhou ({}); repetindo.",
                            modelo,
                            falha.motivo());
                    aguardarRetentativa();
                }
            }
        }

        if (enderecoReserva != null) {
            if (Thread.currentThread().isInterrupted()) {
                throw new AssistenteIndisponivel(Motivo.REDE, "interrompido");
            }
            LOG.warn(
                    "Modelo principal {} falhou apos 2 tentativas ({}); acionando reserva {}.",
                    modelo,
                    ultimaFalha.motivo(),
                    modeloReserva);
            return executarRequisicao(enderecoReserva, corpoRequisicao);
        }

        throw ultimaFalha;
    }

    private ResultadoAnaliseGolpe executarRequisicao(URI destino, String corpoRequisicao) {
        if (Thread.currentThread().isInterrupted()) {
            throw new AssistenteIndisponivel(Motivo.REDE, "interrompido");
        }
        HttpRequest requisicao =
                HttpRequest.newBuilder(destino)
                        .timeout(leitura)
                        .header("Content-Type", "application/json")
                        .header(CABECALHO_DA_CHAVE, chave)
                        .POST(
                                HttpRequest.BodyPublishers.ofString(
                                        corpoRequisicao, StandardCharsets.UTF_8))
                        .build();

        HttpResponse<InputStream> resposta;
        try {
            resposta = http.send(requisicao, HttpResponse.BodyHandlers.ofInputStream());
        } catch (HttpTimeoutException estourou) {
            throw new AssistenteIndisponivel(Motivo.PRAZO, "tempo esgotado");
        } catch (IOException falhou) {
            throw new AssistenteIndisponivel(Motivo.REDE, falhou.getClass().getSimpleName());
        } catch (InterruptedException interrompido) {
            Thread.currentThread().interrupt();
            throw new AssistenteIndisponivel(Motivo.REDE, "interrompido");
        }

        String corpoTexto;
        try (InputStream corpo = resposta.body()) {
            int status = resposta.statusCode();
            if (status != 200) {
                // Descarta e fecha o fluxo de erro sem carregar string em memória (FR-041 / ADR-002).
                throw porStatus(status);
            }
            corpoTexto = new String(corpo.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException aoLerOuFechar) {
            throw new AssistenteIndisponivel(
                    Motivo.REDE, aoLerOuFechar.getClass().getSimpleName());
        }

        return interpretarResposta(corpoTexto);
    }

    private static boolean ehFalhaTransitoria(Motivo motivo) {
        return motivo == Motivo.COTA_ESGOTADA
                || motivo == Motivo.FALHA_DO_PROVEDOR
                || motivo == Motivo.PRAZO
                || motivo == Motivo.REDE;
    }

    private void aguardarRetentativa() {
        if (Thread.currentThread().isInterrupted()) {
            throw new AssistenteIndisponivel(Motivo.REDE, "interrompido");
        }
        if (esperaEntreTentativas.isZero()) {
            return;
        }
        try {
            Thread.sleep(esperaEntreTentativas.toMillis());
        } catch (InterruptedException interrompido) {
            Thread.currentThread().interrupt();
            throw new AssistenteIndisponivel(Motivo.REDE, "interrompido");
        }
    }

    @Override
    public void close() {
        http.shutdownNow();
    }

    String montarCorpo(String conteudo) {
        ObjectNode raiz = json.createObjectNode();

        raiz.putObject("systemInstruction")
                .putArray("parts")
                .addObject()
                .put("text", PersonaAntigolpe.INSTRUCAO);

        ObjectNode geracao = raiz.putObject("generationConfig");
        geracao.put("temperature", 0.1);
        geracao.put("responseMimeType", "application/json");
        ObjectNode esquema = geracao.putObject("responseSchema");
        esquema.put("type", "OBJECT");
        ObjectNode props = esquema.putObject("properties");
        ObjectNode propRisco = props.putObject("risco");
        propRisco.put("type", "STRING");
        ArrayNode enumRisco = propRisco.putArray("enum");
        enumRisco.add("BAIXO").add("MEDIO").add("ALTO");
        props.putObject("titulo").put("type", "STRING");
        props.putObject("explicacao").put("type", "STRING");
        ObjectNode propOrientacoes = props.putObject("orientacoes");
        propOrientacoes.put("type", "ARRAY");
        propOrientacoes.putObject("items").put("type", "STRING");
        ObjectNode propSinais = props.putObject("sinaisDetectados");
        propSinais.put("type", "ARRAY");
        propSinais.putObject("items").put("type", "STRING");
        esquema.putArray("required")
                .add("risco")
                .add("titulo")
                .add("explicacao")
                .add("orientacoes")
                .add("sinaisDetectados");

        ObjectNode msgUsuario = raiz.putArray("contents").addObject();
        msgUsuario.put("role", "user");
        msgUsuario.putArray("parts").addObject().put("text", envolverConteudo(conteudo));

        return json.writeValueAsString(raiz);
    }

    private static String envolverConteudo(String conteudo) {
        String seguro = conteudo == null ? "" : conteudo.replace("<", "[").replace(">", "]");
        return "<conteudo_analisado>\n" + seguro + "\n</conteudo_analisado>";
    }

    private ResultadoAnaliseGolpe interpretarResposta(String corpo) {
        if (corpo == null || corpo.isBlank()) {
            throw new AssistenteIndisponivel(Motivo.RESPOSTA_VAZIA, null);
        }

        JsonNode raiz;
        try {
            raiz = json.readTree(corpo);
        } catch (JacksonException ilegivel) {
            throw new AssistenteIndisponivel(Motivo.RESPOSTA_ILEGIVEL, "envelope invalido");
        }

        if (raiz.has("error")) {
            throw porStatus(raiz.path("error").path("code").asInt(500));
        }

        JsonNode partes = raiz.path("candidates").path(0).path("content").path("parts");
        if (!partes.isArray() || partes.isEmpty()) {
            throw new AssistenteIndisponivel(Motivo.RESPOSTA_VAZIA, null);
        }

        StringBuilder texto = new StringBuilder();
        for (JsonNode parte : partes) {
            if (parte.path("thought").asBoolean(false)) {
                continue;
            }
            JsonNode nodoTexto = parte.get("text");
            if (nodoTexto != null && nodoTexto.isString()) {
                texto.append(nodoTexto.stringValue());
            }
        }

        String jsonTexto = limparCercaMarkdown(texto.toString().strip());
        if (jsonTexto.isEmpty()) {
            throw new AssistenteIndisponivel(Motivo.RESPOSTA_VAZIA, null);
        }

        JsonNode analise;
        try {
            analise = json.readTree(jsonTexto);
        } catch (JacksonException ilegivel) {
            throw new AssistenteIndisponivel(Motivo.RESPOSTA_ILEGIVEL, "json interno invalido");
        }

        if (!analise.isObject()) {
            throw new AssistenteIndisponivel(Motivo.RESPOSTA_ILEGIVEL, "esperado objeto json");
        }

        NivelRiscoGolpe risco = parseRisco(analise.path("risco").asString(""));
        String titulo = analise.path("titulo").asString("").strip();
        String explicacao = analise.path("explicacao").asString("").strip();
        if (titulo.isEmpty() || explicacao.isEmpty()) {
            throw new AssistenteIndisponivel(Motivo.RESPOSTA_ILEGIVEL, "campos obrigatorios vazios");
        }

        List<String> orientacoes = lerListaStrings(analise.path("orientacoes"));
        List<String> sinais = lerListaStrings(analise.path("sinaisDetectados"));

        return new ResultadoAnaliseGolpe(risco, titulo, explicacao, orientacoes, sinais, true);
    }

    private static NivelRiscoGolpe parseRisco(String bruto) {
        String normalizado = bruto == null ? "" : bruto.strip().toUpperCase(Locale.ROOT);
        return switch (normalizado) {
            case "BAIXO" -> NivelRiscoGolpe.BAIXO;
            case "MEDIO" -> NivelRiscoGolpe.MEDIO;
            case "ALTO" -> NivelRiscoGolpe.ALTO;
            default ->
                    throw new AssistenteIndisponivel(
                            Motivo.RESPOSTA_ILEGIVEL, "nivel de risco invalido");
        };
    }

    private static List<String> lerListaStrings(JsonNode nodo) {
        if (!nodo.isArray()) {
            return List.of();
        }
        List<String> lista = new ArrayList<>();
        for (JsonNode item : nodo) {
            if (item.isString()) {
                String valor = item.stringValue().strip();
                if (!valor.isEmpty()) {
                    lista.add(valor);
                }
            }
        }
        return List.copyOf(lista);
    }

    private static String limparCercaMarkdown(String bruto) {
        if (bruto.startsWith("```")) {
            int primeiraQuebra = bruto.indexOf('\n');
            if (primeiraQuebra >= 0) {
                bruto = bruto.substring(primeiraQuebra + 1);
            }
            if (bruto.endsWith("```")) {
                bruto = bruto.substring(0, bruto.length() - 3);
            }
        }
        return bruto.strip();
    }

    private static AssistenteIndisponivel porStatus(int status) {
        if (status == 429) {
            return new AssistenteIndisponivel(Motivo.COTA_ESGOTADA, "http 429");
        }
        if (status >= 500) {
            return new AssistenteIndisponivel(Motivo.FALHA_DO_PROVEDOR, "http " + status);
        }
        return new AssistenteIndisponivel(Motivo.PEDIDO_RECUSADO, "http " + status);
    }
}
