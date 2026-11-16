package br.fatec.memora.localizador.infra;

import br.fatec.memora.localizador.dominio.CategoriaServico;
import br.fatec.memora.localizador.dominio.Endereco;
import br.fatec.memora.localizador.dominio.Estabelecimento;
import br.fatec.memora.localizador.dominio.FonteDados;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.function.LongSupplier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

/**
 * Integração com OpenStreetMap via Overpass API e Nominatim para geocodificação.
 * Utiliza fontes públicas abertas e auditáveis (NFR-004), sem fallback fictício.
 */
@Component
public class ProvedorOpenStreetMapOverpass implements ProvedorGeografico {

    public static final String USER_AGENT_PROJETO =
            "Memora-Fatec/1.0 (+https://github.com/Edudu720/Memora)";
    public static final long INTERVALO_MINIMO_NOMINATIM_MS = 1000L;
    public static final Duration TIMEOUT_NOMINATIM_PADRAO = Duration.ofSeconds(5);
    public static final Duration TIMEOUT_OVERPASS_PADRAO = Duration.ofSeconds(6);

    private static final Logger LOG = LoggerFactory.getLogger(ProvedorOpenStreetMapOverpass.class);
    private static final String OVERPASS_URL_PADRAO = "https://overpass-api.de/api/interpreter";
    private static final String NOMINATIM_URL_PADRAO = "https://nominatim.openstreetmap.org/search";

    private final HttpClient httpClient;
    private final JsonMapper jsonMapper;
    private final String overpassUrl;
    private final String nominatimUrl;
    private final LongSupplier relogioMs;
    private final EsperaComInterrupcao esperarMs;
    private final Duration timeoutNominatim;
    private final Duration timeoutOverpass;
    private final Object nominatimLock = new Object();
    private long ultimoEnvioNominatimMs = -INTERVALO_MINIMO_NOMINATIM_MS;

    @Autowired
    public ProvedorOpenStreetMapOverpass(JsonMapper jsonMapper) {
        this(jsonMapper, OVERPASS_URL_PADRAO, NOMINATIM_URL_PADRAO);
    }

    public ProvedorOpenStreetMapOverpass(
            JsonMapper jsonMapper,
            String overpassUrl,
            String nominatimUrl) {
        this(
                jsonMapper,
                overpassUrl,
                nominatimUrl,
                System::currentTimeMillis,
                Thread::sleep);
    }

    public ProvedorOpenStreetMapOverpass(
            JsonMapper jsonMapper,
            String overpassUrl,
            String nominatimUrl,
            LongSupplier relogioMs,
            EsperaComInterrupcao esperarMs) {
        this(
                jsonMapper,
                overpassUrl,
                nominatimUrl,
                relogioMs,
                esperarMs,
                TIMEOUT_NOMINATIM_PADRAO,
                TIMEOUT_OVERPASS_PADRAO);
    }

    ProvedorOpenStreetMapOverpass(
            JsonMapper jsonMapper,
            String overpassUrl,
            String nominatimUrl,
            LongSupplier relogioMs,
            EsperaComInterrupcao esperarMs,
            Duration timeoutNominatim,
            Duration timeoutOverpass) {
        this.jsonMapper = jsonMapper != null ? jsonMapper : JsonMapper.builder().build();
        this.overpassUrl = overpassUrl != null ? overpassUrl : OVERPASS_URL_PADRAO;
        this.nominatimUrl = nominatimUrl != null ? nominatimUrl : NOMINATIM_URL_PADRAO;
        this.relogioMs = relogioMs != null ? relogioMs : System::currentTimeMillis;
        this.esperarMs = esperarMs != null ? esperarMs : (ms -> {});
        this.timeoutNominatim = timeoutNominatim != null ? timeoutNominatim : TIMEOUT_NOMINATIM_PADRAO;
        this.timeoutOverpass = timeoutOverpass != null ? timeoutOverpass : TIMEOUT_OVERPASS_PADRAO;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(this.timeoutNominatim)
                .build();
    }

    Duration timeoutNominatimConfigurado() {
        return timeoutNominatim;
    }

    Duration timeoutOverpassConfigurado() {
        return timeoutOverpass;
    }

    @FunctionalInterface
    public interface EsperaComInterrupcao {
        void esperar(long millis) throws InterruptedException;
    }

    @Override
    public List<Estabelecimento> buscarPorCoordenadas(
            double latitude,
            double longitude,
            int raioMetros,
            CategoriaServico categoria,
            String termoFiltro) {

        String queryOverpass = construirQueryOverpass(latitude, longitude, raioMetros, categoria);
        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(overpassUrl))
                    .timeout(timeoutOverpass)
                    .header("User-Agent", USER_AGENT_PROJETO)
                    .header("Content-Type", "application/x-www-form-urlencoded")
                    .POST(HttpRequest.BodyPublishers.ofString("data=" + queryOverpass))
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() == 200) {
                return parsearElementosOverpass(response.body(), categoria);
            }
            LOG.warn("Overpass API retornou HTTP {} sem fallback fictício.", response.statusCode());
            throw new ProvedorGeograficoIndisponivelException(
                    "Serviço público de mapas retornou status HTTP " + response.statusCode());
        } catch (ProvedorGeograficoIndisponivelException e) {
            throw e;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new ProvedorGeograficoIndisponivelException(
                    "Consulta ao serviço público de mapas interrompida.", e);
        } catch (Exception e) {
            LOG.warn("Falha ao consultar Overpass API: {}", e.getMessage());
            throw new ProvedorGeograficoIndisponivelException(
                    "Não foi possível consultar o serviço de mapas no momento.", e);
        }
    }

    @Override
    public CoordenadasGeo geocodificarRegiao(String regiaoManual) {
        if (regiaoManual == null || regiaoManual.trim().isBlank()) {
            return null;
        }

        try {
            aguardarJanelaNominatim();
            String encoded = java.net.URLEncoder.encode(regiaoManual + ", Brasil", java.nio.charset.StandardCharsets.UTF_8);
            String url = nominatimUrl + "?q=" + encoded + "&format=json&limit=1&addressdetails=1";

            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .timeout(timeoutNominatim)
                    .header("User-Agent", USER_AGENT_PROJETO)
                    .GET()
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() == 200) {
                JsonNode array = jsonMapper.readTree(response.body());
                if (array.isArray() && !array.isEmpty()) {
                    JsonNode primeiro = array.get(0);
                    double lat = primeiro.get("lat").asDouble();
                    double lon = primeiro.get("lon").asDouble();
                    String nome = primeiro.path("display_name").asText(regiaoManual);
                    return new CoordenadasGeo(lat, lon, nome);
                }
                return null;
            }
            LOG.warn("Nominatim retornou HTTP {} sem fallback de coordenadas.", response.statusCode());
            throw new ProvedorGeograficoIndisponivelException(
                    "Serviço de geocodificação retornou status HTTP " + response.statusCode());
        } catch (ProvedorGeograficoIndisponivelException e) {
            throw e;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new ProvedorGeograficoIndisponivelException(
                    "Consulta de geocodificação interrompida.", e);
        } catch (Exception e) {
            LOG.warn("Erro ao geocodificar com Nominatim: {}", e.getMessage());
            throw new ProvedorGeograficoIndisponivelException(
                    "Não foi possível consultar o serviço de geocodificação no momento.", e);
        }
    }

    private void aguardarJanelaNominatim() throws InterruptedException {
        synchronized (nominatimLock) {
            long agora = relogioMs.getAsLong();
            long decorrido = agora - ultimoEnvioNominatimMs;
            long espera = INTERVALO_MINIMO_NOMINATIM_MS - decorrido;
            if (espera > 0) {
                esperarMs.esperar(espera);
                agora = relogioMs.getAsLong();
            }
            ultimoEnvioNominatimMs = agora;
        }
    }

    private String construirQueryOverpass(double lat, double lon, int raio, CategoriaServico categoria) {
        String filtros = switch (categoria != null ? categoria : CategoriaServico.SAUDE) {
            case SAUDE -> "node[\"amenity\"=\"pharmacy\"](around:" + raio + "," + lat + "," + lon + ");"
                    + "node[\"amenity\"=\"hospital\"](around:" + raio + "," + lat + "," + lon + ");"
                    + "node[\"amenity\"=\"clinic\"](around:" + raio + "," + lat + "," + lon + ");"
                    + "node[\"healthcare\"](around:" + raio + "," + lat + "," + lon + ");";
            case SERVICOS_PUBLICOS -> "node[\"amenity\"=\"townhall\"](around:" + raio + "," + lat + "," + lon + ");"
                    + "node[\"amenity\"=\"post_office\"](around:" + raio + "," + lat + "," + lon + ");"
                    + "node[\"amenity\"=\"social_facility\"](around:" + raio + "," + lat + "," + lon + ");"
                    + "node[\"office\"=\"government\"](around:" + raio + "," + lat + "," + lon + ");";
            case EMERGENCIA -> "node[\"amenity\"=\"police\"](around:" + raio + "," + lat + "," + lon + ");"
                    + "node[\"amenity\"=\"fire_station\"](around:" + raio + "," + lat + "," + lon + ");"
                    + "node[\"emergency\"](around:" + raio + "," + lat + "," + lon + ");";
            case COTIDIANO -> "node[\"amenity\"=\"bank\"](around:" + raio + "," + lat + "," + lon + ");"
                    + "node[\"shop\"=\"supermarket\"](around:" + raio + "," + lat + "," + lon + ");"
                    + "node[\"amenity\"=\"post_office\"](around:" + raio + "," + lat + "," + lon + ");";
        };

        return String.format(Locale.US, "[out:json][timeout:5];(%s);out center 20;", filtros);
    }

    private List<Estabelecimento> parsearElementosOverpass(String json, CategoriaServico categoria) {
        List<Estabelecimento> lista = new ArrayList<>();
        try {
            JsonNode root = jsonMapper.readTree(json);
            JsonNode elements = root.path("elements");
            if (elements.isArray()) {
                for (JsonNode el : elements) {
                    JsonNode tags = el.path("tags");
                    String nome = tags.path("name").asText(null);
                    if (nome == null || nome.isBlank()) {
                        continue;
                    }

                    String id = "osm:node:" + el.path("id").asText();
                    double lat = el.path("lat").asDouble(el.path("center").path("lat").asDouble());
                    double lon = el.path("lon").asDouble(el.path("center").path("lon").asDouble());

                    String logradouro = tags.path("addr:street").asText(null);
                    String numero = tags.path("addr:housenumber").asText(null);
                    String bairro = tags.path("addr:suburb").asText(null);
                    String cidade = tags.path("addr:city").asText(null);
                    String estado = tags.path("addr:state").asText(null);
                    String cep = tags.path("addr:postcode").asText(null);

                    String formatado = construirTextoFormatado(logradouro, numero, bairro, cidade);
                    Endereco end = new Endereco(logradouro, numero, bairro, cidade, estado, cep, formatado);

                    String fone = tags.path("phone").asText(tags.path("contact:phone").asText(null));
                    String horario = tags.path("opening_hours").asText(null);
                    boolean horarioConf = horario != null && !horario.isBlank();

                    String aviso = null;
                    if (!horarioConf && fone == null) {
                        aviso = "Telefone e horários não confirmados na base pública. Recomendamos ligar antes se possível.";
                    }

                    String subtitulo = tags.path("amenity").asText(tags.path("shop").asText(categoria.getRotulo()));

                    lista.add(new Estabelecimento(
                            id,
                            nome,
                            categoria,
                            subtitulo,
                            end,
                            lat,
                            lon,
                            null,
                            null,
                            fone,
                            horario,
                            horarioConf,
                            FonteDados.OPEN_STREET_MAP,
                            aviso));
                }
            }
        } catch (Exception e) {
            LOG.warn("Erro ao fazer parse dos elementos Overpass: {}", e.getMessage());
            throw new ProvedorGeograficoIndisponivelException(
                    "Resposta inválida do serviço público de mapas.", e);
        }
        return lista;
    }

    private String construirTextoFormatado(String logradouro, String numero, String bairro, String cidade) {
        StringBuilder sb = new StringBuilder();
        if (logradouro != null && !logradouro.isBlank()) {
            sb.append(logradouro);
            if (numero != null && !numero.isBlank()) {
                sb.append(", ").append(numero);
            }
        }
        if (bairro != null && !bairro.isBlank()) {
            if (!sb.isEmpty()) sb.append(" - ");
            sb.append(bairro);
        }
        if (cidade != null && !cidade.isBlank()) {
            if (!sb.isEmpty()) sb.append(", ");
            sb.append(cidade);
        }
        return sb.isEmpty() ? "Endereço cadastrado no OpenStreetMap" : sb.toString();
    }
}
