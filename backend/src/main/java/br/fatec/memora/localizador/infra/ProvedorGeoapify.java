package br.fatec.memora.localizador.infra;

import br.fatec.memora.localizador.dominio.CategoriaServico;
import br.fatec.memora.localizador.dominio.Endereco;
import br.fatec.memora.localizador.dominio.Estabelecimento;
import br.fatec.memora.localizador.dominio.FonteDados;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

/**
 * Integração com a API comercial da Geoapify (Places v2 e Geocoding v1) baseada em OpenStreetMap.
 * Atua como provedor rápido e estável quando {@code MEMORA_LOCALIZADOR_GEOAPIFY_API_KEY} está configurada.
 */
@Component
public class ProvedorGeoapify implements ProvedorGeografico {

    public static final String PLACES_URL_PADRAO = "https://api.geoapify.com/v2/places";
    public static final String GEOCODE_URL_PADRAO = "https://api.geoapify.com/v1/geocode/search";
    public static final Duration TIMEOUT_PADRAO = Duration.ofSeconds(10);

    private static final Logger LOG = LoggerFactory.getLogger(ProvedorGeoapify.class);
    private static final String AVISO_SEM_CONFIRMACAO =
            "Telefone e horários não confirmados na base pública. Recomendamos ligar antes se possível.";

    private final HttpClient httpClient;
    private final JsonMapper jsonMapper;
    private final String apiKey;
    private final String placesUrl;
    private final String geocodeUrl;
    private final Duration timeout;

    @Autowired
    public ProvedorGeoapify(
            JsonMapper jsonMapper,
            @Value("${memora.localizador.geoapify.api-key:}") String apiKey,
            @Value("${memora.localizador.geoapify.places-url:" + PLACES_URL_PADRAO + "}") String placesUrl,
            @Value("${memora.localizador.geoapify.geocode-url:" + GEOCODE_URL_PADRAO + "}") String geocodeUrl) {
        this(jsonMapper, apiKey, placesUrl, geocodeUrl, TIMEOUT_PADRAO);
    }

    ProvedorGeoapify(
            JsonMapper jsonMapper,
            String apiKey,
            String placesUrl,
            String geocodeUrl,
            Duration timeout) {
        this.jsonMapper = jsonMapper != null ? jsonMapper : JsonMapper.builder().build();
        this.apiKey = apiKey != null ? apiKey.trim() : "";
        this.placesUrl = (placesUrl != null && !placesUrl.isBlank()) ? placesUrl : PLACES_URL_PADRAO;
        this.geocodeUrl = (geocodeUrl != null && !geocodeUrl.isBlank()) ? geocodeUrl : GEOCODE_URL_PADRAO;
        this.timeout = timeout != null ? timeout : TIMEOUT_PADRAO;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(this.timeout)
                .build();
    }

    /** Indica se há chave configurada para acionar o provedor Geoapify. */
    public boolean estaConfigurado() {
        return !apiKey.isEmpty();
    }

    @Override
    public List<Estabelecimento> buscarPorCoordenadas(
            double latitude,
            double longitude,
            int raioMetros,
            CategoriaServico categoria,
            String termoFiltro) {
        if (!estaConfigurado()) {
            throw new ProvedorGeograficoIndisponivelException(
                    "Chave do provedor Geoapify não configurada.");
        }

        CategoriaServico catEfetiva = categoria != null ? categoria : CategoriaServico.SAUDE;
        String categoriasGeoapify = mapearCategorias(catEfetiva);
        String chaveCodificada = URLEncoder.encode(apiKey, StandardCharsets.UTF_8);
        String url = String.format(
                Locale.US,
                "%s?categories=%s&filter=circle:%.6f,%.6f,%d&bias=proximity:%.6f,%.6f&limit=20&lang=pt&apiKey=%s",
                placesUrl,
                categoriasGeoapify,
                longitude,
                latitude,
                raioMetros,
                longitude,
                latitude,
                chaveCodificada);

        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .timeout(timeout)
                    .header("User-Agent", ProvedorOpenStreetMapOverpass.USER_AGENT_PROJETO)
                    .GET()
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() == 200) {
                return parsearPlaces(response.body(), catEfetiva);
            }
            LOG.warn("Geoapify Places retornou HTTP {} sem fallback fictício.", response.statusCode());
            throw new ProvedorGeograficoIndisponivelException(
                    "Serviço de mapas retornou status HTTP " + response.statusCode());
        } catch (ProvedorGeograficoIndisponivelException e) {
            throw e;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new ProvedorGeograficoIndisponivelException(
                    "Consulta ao serviço de mapas interrompida.", e);
        } catch (Exception e) {
            LOG.warn(
                    "Falha ao consultar Geoapify Places ({}): {}",
                    e.getClass().getSimpleName(),
                    sanitizarMensagem(e.getMessage()));
            throw new ProvedorGeograficoIndisponivelException(
                    "Não foi possível consultar o serviço de mapas no momento.", e);
        }
    }

    @Override
    public CoordenadasGeo geocodificarRegiao(String regiaoManual) {
        if (regiaoManual == null || regiaoManual.trim().isBlank()) {
            return null;
        }
        if (!estaConfigurado()) {
            throw new ProvedorGeograficoIndisponivelException(
                    "Chave do provedor Geoapify não configurada.");
        }

        String textoCodificado = URLEncoder.encode(regiaoManual.trim(), StandardCharsets.UTF_8);
        String chaveCodificada = URLEncoder.encode(apiKey, StandardCharsets.UTF_8);
        String url = String.format(
                Locale.US,
                "%s?text=%s&filter=countrycode:br&limit=1&lang=pt&apiKey=%s",
                geocodeUrl,
                textoCodificado,
                chaveCodificada);

        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .timeout(timeout)
                    .header("User-Agent", ProvedorOpenStreetMapOverpass.USER_AGENT_PROJETO)
                    .GET()
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() == 200) {
                JsonNode root = jsonMapper.readTree(response.body());
                JsonNode features = root.path("features");
                if (features.isArray() && !features.isEmpty()) {
                    JsonNode props = features.get(0).path("properties");
                    if (props.hasNonNull("lat") && props.hasNonNull("lon")) {
                        double lat = props.get("lat").asDouble();
                        double lon = props.get("lon").asDouble();
                        String nome = textoOuNull(props, "formatted");
                        return new CoordenadasGeo(lat, lon, nome != null ? nome : regiaoManual.trim());
                    }
                }
                return null;
            }
            LOG.warn("Geoapify Geocoding retornou HTTP {}.", response.statusCode());
            throw new ProvedorGeograficoIndisponivelException(
                    "Serviço de geocodificação retornou status HTTP " + response.statusCode());
        } catch (ProvedorGeograficoIndisponivelException e) {
            throw e;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new ProvedorGeograficoIndisponivelException(
                    "Consulta de geocodificação interrompida.", e);
        } catch (Exception e) {
            LOG.warn(
                    "Erro ao geocodificar com Geoapify ({}): {}",
                    e.getClass().getSimpleName(),
                    sanitizarMensagem(e.getMessage()));
            throw new ProvedorGeograficoIndisponivelException(
                    "Não foi possível consultar o serviço de geocodificação no momento.", e);
        }
    }

    private List<Estabelecimento> parsearPlaces(String json, CategoriaServico categoria) {
        List<Estabelecimento> lista = new ArrayList<>();
        try {
            JsonNode root = jsonMapper.readTree(json);
            JsonNode features = root.path("features");
            if (features.isArray()) {
                for (JsonNode feature : features) {
                    JsonNode props = feature.path("properties");
                    String nome = textoOuNull(props, "name");
                    if (nome == null) {
                        continue;
                    }

                    double lat = props.hasNonNull("lat")
                            ? props.get("lat").asDouble()
                            : feature.path("geometry").path("coordinates").path(1).asDouble();
                    double lon = props.hasNonNull("lon")
                            ? props.get("lon").asDouble()
                            : feature.path("geometry").path("coordinates").path(0).asDouble();

                    String placeId = textoOuNull(props, "place_id");
                    String id = "osm:geoapify:" + (placeId != null ? placeId : Math.abs(nome.hashCode()));

                    String logradouro = textoOuNull(props, "street");
                    String numero = textoOuNull(props, "housenumber");
                    String bairro = textoOuNull(props, "suburb");
                    String cidade = textoOuNull(props, "city");
                    String estado = textoOuNull(props, "state_code");
                    if (estado == null) {
                        estado = textoOuNull(props, "state");
                    }
                    String cep = textoOuNull(props, "postcode");

                    String formatado = construirTextoFormatado(
                            logradouro,
                            numero,
                            bairro,
                            cidade,
                            textoOuNull(props, "formatted"));
                    Endereco endereco = new Endereco(logradouro, numero, bairro, cidade, estado, cep, formatado);

                    JsonNode contact = props.path("contact");
                    JsonNode raw = props.path("datasource").path("raw");

                    String fone = textoOuNull(contact, "phone");
                    if (fone == null) {
                        fone = textoOuNull(raw, "phone");
                    }
                    if (fone == null) {
                        fone = textoOuNull(raw, "contact:phone");
                    }

                    String horario = textoOuNull(props, "opening_hours");
                    if (horario == null) {
                        horario = textoOuNull(raw, "opening_hours");
                    }
                    boolean horarioConf = horario != null && !horario.isBlank();

                    String aviso = (!horarioConf && fone == null) ? AVISO_SEM_CONFIRMACAO : null;
                    String subtitulo = resolverSubtitulo(props, raw, categoria);

                    lista.add(new Estabelecimento(
                            id,
                            nome,
                            categoria,
                            subtitulo,
                            endereco,
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
            LOG.warn(
                    "Erro ao fazer parse da resposta Geoapify ({}): {}",
                    e.getClass().getSimpleName(),
                    sanitizarMensagem(e.getMessage()));
            throw new ProvedorGeograficoIndisponivelException(
                    "Resposta inválida do serviço de mapas.", e);
        }
        return lista;
    }

    private String mapearCategorias(CategoriaServico categoria) {
        return switch (categoria) {
            case SAUDE -> "healthcare.pharmacy,healthcare.hospital,healthcare.clinic_or_praxis,healthcare";
            case SERVICOS_PUBLICOS -> "office.government,building.public_and_civil,activity.community_center";
            case EMERGENCIA -> "service.police,service.fire_station,healthcare.hospital";
            case COTIDIANO -> "service.financial,commercial.supermarket,commercial.food_and_drink.bakery";
        };
    }

    private String resolverSubtitulo(JsonNode props, JsonNode raw, CategoriaServico categoria) {
        JsonNode cats = props.path("categories");
        if (cats.isArray()) {
            String todas = cats.toString().toLowerCase(Locale.ROOT);
            if (todas.contains("pharmacy")) return "Farmácia";
            if (todas.contains("hospital")) return "Hospital";
            if (todas.contains("clinic")) return "Clínica / Posto de Saúde";
            if (todas.contains("police")) return "Polícia";
            if (todas.contains("fire_station")) return "Corpo de Bombeiros";
            if (todas.contains("supermarket")) return "Supermercado";
            if (todas.contains("bakery")) return "Padaria";
            if (todas.contains("financial")) return "Banco / Financeiro";
            if (todas.contains("government") || todas.contains("public_and_civil")) return "Serviço Público";
        }
        String amenity = textoOuNull(raw, "amenity");
        if (amenity != null) return amenity;
        return categoria.getRotulo();
    }

    private String construirTextoFormatado(
            String logradouro, String numero, String bairro, String cidade, String formatted) {
        StringBuilder sb = new StringBuilder();
        if (logradouro != null) {
            sb.append(logradouro);
            if (numero != null) {
                sb.append(", ").append(numero);
            }
        }
        if (bairro != null) {
            if (!sb.isEmpty()) sb.append(" - ");
            sb.append(bairro);
        }
        if (cidade != null) {
            if (!sb.isEmpty()) sb.append(", ");
            sb.append(cidade);
        }
        if (!sb.isEmpty()) {
            return sb.toString();
        }
        return formatted != null ? formatted : "Endereço cadastrado no OpenStreetMap";
    }

    private String textoOuNull(JsonNode node, String campo) {
        if (node == null || node.isMissingNode() || node.isNull()) {
            return null;
        }
        JsonNode alvo = node.path(campo);
        if (alvo.isMissingNode() || alvo.isNull()) {
            return null;
        }
        String valor = alvo.asText().trim();
        return valor.isEmpty() ? null : valor;
    }

    private String sanitizarMensagem(String msg) {
        if (msg == null) return "sem detalhes";
        return msg.replaceAll("apiKey=[^&\\s]+", "apiKey=***");
    }
}
