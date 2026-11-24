package br.fatec.memora.localizador.infra;

import br.fatec.memora.localizador.dominio.CategoriaServico;
import br.fatec.memora.localizador.dominio.Endereco;
import br.fatec.memora.localizador.dominio.Estabelecimento;
import br.fatec.memora.localizador.dominio.FonteDados;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;
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
import java.util.Set;
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
    public static final Duration ORCAMENTO_MAXIMO_OVERPASS = Duration.ofSeconds(10);

    private static final Logger LOG = LoggerFactory.getLogger(ProvedorOpenStreetMapOverpass.class);
    private static final Set<String> ROTULOS_GENERICOS_CATEGORIA = Set.of(
            "saúde",
            "saude",
            "posto de saúde",
            "posto de saude",
            "serviços públicos",
            "servicos publicos",
            "serviços ao cidadão",
            "servicos ao cidadao",
            "emergência",
            "emergencia",
            "serviços cotidianos",
            "servicos cotidianos");
    private static final String OVERPASS_URL_PADRAO = "https://overpass-api.de/api/interpreter";
    public static final List<String> OVERPASS_URLS_PADRAO = List.of(
            OVERPASS_URL_PADRAO,
            "https://overpass.kumi.systems/api/interpreter",
            "https://overpass.private.coffee/api/interpreter");
    private static final String NOMINATIM_URL_PADRAO = "https://nominatim.openstreetmap.org/search";

    private final HttpClient httpClient;
    private final JsonMapper jsonMapper;
    private final List<String> overpassUrls;
    private final String nominatimUrl;
    private final LongSupplier relogioMs;
    private final EsperaComInterrupcao esperarMs;
    private final Duration timeoutNominatim;
    private final Duration timeoutOverpass;
    private final Object nominatimLock = new Object();
    private long ultimoEnvioNominatimMs = -INTERVALO_MINIMO_NOMINATIM_MS;

    @Autowired
    public ProvedorOpenStreetMapOverpass(JsonMapper jsonMapper) {
        this(
                jsonMapper,
                OVERPASS_URLS_PADRAO,
                NOMINATIM_URL_PADRAO,
                System::currentTimeMillis,
                Thread::sleep,
                TIMEOUT_NOMINATIM_PADRAO,
                TIMEOUT_OVERPASS_PADRAO);
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
            List<String> overpassUrls,
            String nominatimUrl) {
        this(
                jsonMapper,
                overpassUrls,
                nominatimUrl,
                System::currentTimeMillis,
                Thread::sleep,
                TIMEOUT_NOMINATIM_PADRAO,
                TIMEOUT_OVERPASS_PADRAO);
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
        this(
                jsonMapper,
                List.of(overpassUrl != null ? overpassUrl : OVERPASS_URL_PADRAO),
                nominatimUrl,
                relogioMs,
                esperarMs,
                timeoutNominatim,
                timeoutOverpass);
    }

    ProvedorOpenStreetMapOverpass(
            JsonMapper jsonMapper,
            List<String> overpassUrls,
            String nominatimUrl,
            LongSupplier relogioMs,
            EsperaComInterrupcao esperarMs,
            Duration timeoutNominatim,
            Duration timeoutOverpass) {
        this.jsonMapper = jsonMapper != null ? jsonMapper : JsonMapper.builder().build();
        this.overpassUrls = (overpassUrls != null && !overpassUrls.isEmpty())
                ? List.copyOf(overpassUrls)
                : OVERPASS_URLS_PADRAO;
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
        ProvedorGeograficoIndisponivelException ultimaFalha = null;
        long inicioNano = System.nanoTime();

        for (String urlAtual : overpassUrls) {
            if (ultimaFalha != null
                    && Duration.ofNanos(System.nanoTime() - inicioNano).compareTo(ORCAMENTO_MAXIMO_OVERPASS) >= 0) {
                LOG.warn(
                        "Orçamento total de tempo do Overpass ({}s) esgotado; interrompendo tentativa em {}.",
                        ORCAMENTO_MAXIMO_OVERPASS.toSeconds(),
                        urlAtual);
                break;
            }
            try {
                HttpRequest request = HttpRequest.newBuilder()
                        .uri(URI.create(urlAtual))
                        .timeout(timeoutOverpass)
                        .header("User-Agent", USER_AGENT_PROJETO)
                        .header("Content-Type", "application/x-www-form-urlencoded")
                        .POST(HttpRequest.BodyPublishers.ofString("data=" + queryOverpass))
                        .build();

                HttpResponse<String> response =
                        httpClient.send(request, HttpResponse.BodyHandlers.ofString());
                if (response.statusCode() == 200) {
                    return parsearElementosOverpass(response.body(), categoria);
                }
                LOG.warn(
                        "Overpass API em {} retornou HTTP {} sem fallback fictício.",
                        urlAtual,
                        response.statusCode());
                ultimaFalha = new ProvedorGeograficoIndisponivelException(
                        "Serviço público de mapas retornou status HTTP " + response.statusCode());
            } catch (ProvedorGeograficoIndisponivelException e) {
                ultimaFalha = e;
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new ProvedorGeograficoIndisponivelException(
                        "Consulta ao serviço público de mapas interrompida.", e);
            } catch (Exception e) {
                LOG.warn(
                        "Falha ao consultar Overpass API em {} ({}): {}",
                        urlAtual,
                        e.getClass().getSimpleName(),
                        e.getMessage());
                ultimaFalha = new ProvedorGeograficoIndisponivelException(
                        "Não foi possível consultar o serviço de mapas no momento.", e);
            }
        }

        throw ultimaFalha != null
                ? ultimaFalha
                : new ProvedorGeograficoIndisponivelException(
                        "Não foi possível consultar o serviço de mapas no momento.");
    }

    /**
     * Busca estabelecimentos delimitados por viewbox no Nominatim como contingência rápida
     * quando as instâncias públicas do Overpass estão indisponíveis ou lentas.
     */
    public List<Estabelecimento> buscarPorCoordenadasViaNominatim(
            double latitude,
            double longitude,
            int raioMetros,
            CategoriaServico categoria,
            String termoFiltro) {
        CategoriaServico categoriaEfetiva = categoria != null ? categoria : CategoriaServico.SAUDE;
        int raioEfetivo = raioMetros > 0 ? raioMetros : 5000;

        double dLat = raioEfetivo / 111320.0;
        double cosLat = Math.max(0.1, Math.cos(Math.toRadians(latitude)));
        double dLon = raioEfetivo / (111320.0 * cosLat);
        double sul = latitude - dLat;
        double norte = latitude + dLat;
        double oeste = longitude - dLon;
        double leste = longitude + dLon;

        List<String> termosBusca = resolverTermosNominatim(categoriaEfetiva, termoFiltro);

        for (String termoBusca : termosBusca) {
            try {
                aguardarJanelaNominatim();
                String url = String.format(
                        Locale.US,
                        "%s?q=%s&format=json&limit=20&addressdetails=1&extratags=1&countrycodes=br&viewbox=%.5f,%.5f,%.5f,%.5f&bounded=1",
                        nominatimUrl,
                        URLEncoder.encode(termoBusca, StandardCharsets.UTF_8),
                        oeste,
                        norte,
                        leste,
                        sul);

                HttpRequest request = HttpRequest.newBuilder()
                        .uri(URI.create(url))
                        .timeout(timeoutNominatim)
                        .header("User-Agent", USER_AGENT_PROJETO)
                        .GET()
                        .build();

                HttpResponse<String> response =
                        httpClient.send(request, HttpResponse.BodyHandlers.ofString());
                if (response.statusCode() != 200) {
                    LOG.warn(
                            "Nominatim busca regional retornou HTTP {} sem fallback fictício.",
                            response.statusCode());
                    throw new ProvedorGeograficoIndisponivelException(
                            "Serviço público de mapas retornou status HTTP " + response.statusCode());
                }

                List<Estabelecimento> encontrados =
                        parsearElementosNominatim(response.body(), categoriaEfetiva);
                if (!encontrados.isEmpty()) {
                    return encontrados;
                }
            } catch (ProvedorGeograficoIndisponivelException e) {
                throw e;
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new ProvedorGeograficoIndisponivelException(
                        "Consulta ao serviço público de mapas interrompida.", e);
            } catch (Exception e) {
                LOG.warn(
                        "Falha ao consultar busca regional no Nominatim ({}): {}",
                        e.getClass().getSimpleName(),
                        e.getMessage());
                throw new ProvedorGeograficoIndisponivelException(
                        "Não foi possível consultar o serviço de mapas no momento.", e);
            }
        }

        return List.of();
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
            LOG.warn("Erro ao geocodificar com Nominatim ({}): {}", e.getClass().getSimpleName(), e.getMessage());
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

    private List<String> resolverTermosNominatim(CategoriaServico categoria, String termoFiltro) {
        if (termoFiltro != null && !termoFiltro.trim().isBlank()) {
            String limpo = termoFiltro.trim();
            String minusculo = limpo.toLowerCase(Locale.ROOT);
            if (!ROTULOS_GENERICOS_CATEGORIA.contains(minusculo)) {
                if (minusculo.contains("farmácia") || minusculo.contains("farmacia")) {
                    return List.of("farmacia");
                }
                if (minusculo.contains("supermercado") || minusculo.contains("mercado")) {
                    return List.of("supermercado");
                }
                if (minusculo.contains("banco") || minusculo.contains("lotérica") || minusculo.contains("loterica")) {
                    return List.of("banco");
                }
                if (minusculo.contains("correio")) {
                    return List.of("correios");
                }
                return List.of(limpo);
            }
        }
        return switch (categoria) {
            case SAUDE -> List.of("hospital", "farmacia");
            case SERVICOS_PUBLICOS -> List.of("correios", "prefeitura");
            case EMERGENCIA -> List.of("policia", "hospital");
            case COTIDIANO -> List.of("supermercado", "banco");
        };
    }

    private List<Estabelecimento> parsearElementosNominatim(String json, CategoriaServico categoriaEfetiva) {
        List<Estabelecimento> lista = new ArrayList<>();
        try {
            JsonNode array = jsonMapper.readTree(json);
            if (array.isArray()) {
                for (JsonNode el : array) {
                    JsonNode address = el.path("address");
                    String nome = textoOuNull(el, "name");
                    if (nome == null) {
                        nome = primeiroNaoNulo(
                                textoOuNull(address, "amenity"),
                                textoOuNull(address, "shop"),
                                extrairPrimeiroSegmento(textoOuNull(el, "display_name")));
                    }
                    if (nome == null) {
                        continue;
                    }

                    double lat = el.path("lat").asDouble(Double.NaN);
                    double lon = el.path("lon").asDouble(Double.NaN);
                    if (Double.isNaN(lat) || Double.isNaN(lon)) {
                        continue;
                    }

                    String placeId = textoOuNull(el, "place_id");
                    String id = "osm:nominatim:" + (placeId != null ? placeId : Math.abs(nome.hashCode()));

                    String logradouro = primeiroNaoNulo(
                            textoOuNull(address, "road"),
                            textoOuNull(address, "pedestrian"),
                            textoOuNull(address, "street"));
                    String numero = textoOuNull(address, "house_number");
                    String bairro = primeiroNaoNulo(
                            textoOuNull(address, "suburb"),
                            textoOuNull(address, "neighbourhood"),
                            textoOuNull(address, "quarter"));
                    String cidade = primeiroNaoNulo(
                            textoOuNull(address, "city"),
                            textoOuNull(address, "town"),
                            textoOuNull(address, "municipality"),
                            textoOuNull(address, "village"));
                    String estado = extrairEstadoNominatim(address);
                    String cep = textoOuNull(address, "postcode");

                    String formatado = construirTextoFormatado(logradouro, numero, bairro, cidade);
                    Endereco end = new Endereco(logradouro, numero, bairro, cidade, estado, cep, formatado);

                    JsonNode extratags = el.path("extratags");
                    String fone = primeiroNaoNulo(
                            textoOuNull(extratags, "phone"),
                            textoOuNull(extratags, "contact:phone"));
                    String horario = textoOuNull(extratags, "opening_hours");
                    boolean horarioConf = horario != null && !horario.isBlank();

                    String aviso = (!horarioConf && fone == null)
                            ? "Telefone e horários não confirmados na base pública. Recomendamos ligar antes se possível."
                            : null;

                    String tipo = textoOuNull(el, "type");
                    String subtitulo = tipo != null ? tipo : categoriaEfetiva.getRotulo();

                    lista.add(new Estabelecimento(
                            id,
                            nome,
                            categoriaEfetiva,
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
            LOG.warn("Erro ao fazer parse dos elementos Nominatim: {}", e.getMessage());
            throw new ProvedorGeograficoIndisponivelException(
                    "Resposta inválida do serviço público de mapas.", e);
        }
        return lista;
    }

    private String extrairEstadoNominatim(JsonNode address) {
        String iso = textoOuNull(address, "ISO3166-2-lvl4");
        if (iso != null && iso.startsWith("BR-") && iso.length() > 3) {
            return iso.substring(3);
        }
        return primeiroNaoNulo(textoOuNull(address, "state_code"), textoOuNull(address, "state"));
    }

    private String extrairPrimeiroSegmento(String displayName) {
        if (displayName == null) {
            return null;
        }
        int idx = displayName.indexOf(',');
        String primeiro = (idx >= 0 ? displayName.substring(0, idx) : displayName).trim();
        return primeiro.isEmpty() ? null : primeiro;
    }

    private String textoOuNull(JsonNode node, String campo) {
        if (node == null || node.isMissingNode() || node.isNull()) {
            return null;
        }
        JsonNode alvo = node.path(campo);
        if (alvo.isMissingNode() || alvo.isNull()) {
            return null;
        }
        String valor = alvo.asText("").trim();
        return valor.isEmpty() ? null : valor;
    }

    private String primeiroNaoNulo(String... valores) {
        for (String v : valores) {
            if (v != null && !v.isBlank()) {
                return v;
            }
        }
        return null;
    }
}
