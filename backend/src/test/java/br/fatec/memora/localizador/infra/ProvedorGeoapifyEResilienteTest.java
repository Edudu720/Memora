package br.fatec.memora.localizador.infra;

import static org.junit.jupiter.api.Assertions.*;

import br.fatec.memora.localizador.aplicacao.InterpretadorDeIntencaoPorPalavrasChave;
import br.fatec.memora.localizador.aplicacao.ServicoLocalizador;
import br.fatec.memora.localizador.dominio.CategoriaServico;
import br.fatec.memora.localizador.dominio.Estabelecimento;
import br.fatec.memora.localizador.dominio.FonteDados;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import tools.jackson.databind.json.JsonMapper;

class ProvedorGeoapifyEResilienteTest {

    private HttpServer server;
    private volatile int statusPlaces = 200;
    private volatile String bodyPlaces = "{\"type\":\"FeatureCollection\",\"features\":[]}";
    private volatile int statusGeocode = 200;
    private volatile String bodyGeocode = "{\"type\":\"FeatureCollection\",\"features\":[]}";
    private volatile int statusOverpass = 200;
    private volatile String bodyOverpass = "{\"elements\":[]}";
    private volatile int statusNominatim = 503;
    private volatile String bodyNominatim = "[]";

    private final AtomicInteger chamadasPlaces = new AtomicInteger();
    private final AtomicInteger chamadasGeocode = new AtomicInteger();
    private final AtomicInteger chamadasOverpass = new AtomicInteger();
    private final AtomicInteger chamadasNominatim = new AtomicInteger();
    private final List<String> queriesPlaces = new CopyOnWriteArrayList<>();
    private final List<String> queriesNominatim = new CopyOnWriteArrayList<>();

    @BeforeEach
    void setUp() throws IOException {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/v2/places", exchange -> {
            chamadasPlaces.incrementAndGet();
            queriesPlaces.add(exchange.getRequestURI().getQuery());
            byte[] bytes = bodyPlaces.getBytes(StandardCharsets.UTF_8);
            exchange.sendResponseHeaders(statusPlaces, bytes.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(bytes);
            }
        });
        server.createContext("/v1/geocode/search", exchange -> {
            chamadasGeocode.incrementAndGet();
            byte[] bytes = bodyGeocode.getBytes(StandardCharsets.UTF_8);
            exchange.sendResponseHeaders(statusGeocode, bytes.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(bytes);
            }
        });
        server.createContext("/overpass", exchange -> {
            chamadasOverpass.incrementAndGet();
            byte[] bytes = bodyOverpass.getBytes(StandardCharsets.UTF_8);
            exchange.sendResponseHeaders(statusOverpass, bytes.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(bytes);
            }
        });
        server.createContext("/nominatim", exchange -> {
            chamadasNominatim.incrementAndGet();
            queriesNominatim.add(exchange.getRequestURI().getQuery());
            byte[] bytes = bodyNominatim.getBytes(StandardCharsets.UTF_8);
            exchange.sendResponseHeaders(statusNominatim, bytes.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(bytes);
            }
        });
        server.start();
    }

    @AfterEach
    void tearDown() {
        if (server != null) {
            server.stop(0);
        }
    }

    private ProvedorGeoapify criarGeoapify(String apiKey) {
        int port = server.getAddress().getPort();
        return new ProvedorGeoapify(
                JsonMapper.builder().build(),
                apiKey,
                "http://127.0.0.1:" + port + "/v2/places",
                "http://127.0.0.1:" + port + "/v1/geocode/search",
                Duration.ofSeconds(5));
    }

    private ProvedorOpenStreetMapOverpass criarOverpass() {
        int port = server.getAddress().getPort();
        return new ProvedorOpenStreetMapOverpass(
                JsonMapper.builder().build(),
                "http://127.0.0.1:" + port + "/overpass",
                "http://127.0.0.1:" + port + "/nominatim");
    }

    @Test
    @DisplayName("Geoapify extrai estabelecimentos e coordenadas brasileiras corretamente quando chave configurada")
    void geoapifyExtraiLocaisEGeocodeReais() {
        bodyPlaces = """
                {
                  "type": "FeatureCollection",
                  "features": [
                    {
                      "type": "Feature",
                      "properties": {
                        "place_id": "abc123",
                        "name": "Drogaria Todo Dia",
                        "categories": ["healthcare", "healthcare.pharmacy"],
                        "street": "Rua Washington Luiz",
                        "housenumber": "674",
                        "suburb": "Centro",
                        "city": "Americana",
                        "state_code": "SP",
                        "postcode": "13465-279",
                        "lat": -22.7405995,
                        "lon": -47.3325128,
                        "contact": {"phone": "+55 19 3407 6621"},
                        "opening_hours": "Mo-Su 07:00-23:00"
                      }
                    },
                    {
                      "type": "Feature",
                      "properties": {
                        "place_id": "semnome",
                        "street": "Rua Sem Nome",
                        "lat": -22.741,
                        "lon": -47.331
                      }
                    }
                  ]
                }
                """;
        bodyGeocode = """
                {
                  "type": "FeatureCollection",
                  "features": [
                    {
                      "type": "Feature",
                      "properties": {
                        "formatted": "Americana, SP, Brasil",
                        "lat": -22.7392463,
                        "lon": -47.3306032
                      }
                    }
                  ]
                }
                """;

        ProvedorGeoapify geoapify = criarGeoapify("chave-teste-simulada");
        assertTrue(geoapify.estaConfigurado());

        var coords = geoapify.geocodificarRegiao("Americana, SP");
        assertNotNull(coords);
        assertEquals("Americana, SP, Brasil", coords.nomeExibido());
        assertEquals(-22.7392463, coords.latitude(), 0.0001);

        List<Estabelecimento> locais =
                geoapify.buscarPorCoordenadas(-22.7388, -47.3325, 5000, CategoriaServico.SAUDE, "farmácia");
        assertEquals(1, locais.size());
        Estabelecimento est = locais.get(0);
        assertEquals("Drogaria Todo Dia", est.nome());
        assertEquals("Farmácia", est.subtituloTipo());
        assertEquals("Rua Washington Luiz, 674 - Centro, Americana", est.endereco().textoFormatado());
        assertEquals("SP", est.endereco().estado());
        assertEquals("+55 19 3407 6621", est.telefone());
        assertTrue(est.horarioConfirmado());
        assertEquals(FonteDados.OPEN_STREET_MAP, est.fonte());
        assertTrue(queriesPlaces.get(0).contains("categories=healthcare.pharmacy"));
    }

    @Test
    @DisplayName("Geoapify escolhe o bairro Centro em Americana-SP em vez de comércio homônimo em Ubá-MG para 'Americana, Centro'")
    void geoapifyPriorizaBairroECidadeSobreComercioHomonimoEmOutroEstado() {
        bodyGeocode = """
                {
                  "type": "FeatureCollection",
                  "features": [
                    {
                      "type": "Feature",
                      "properties": {
                        "result_type": "amenity",
                        "formatted": "Americana, Praça da Independência, Centro, Ubá - MG, 36500-017, Brasil",
                        "city": "Ubá",
                        "suburb": "Centro",
                        "state_code": "MG",
                        "lat": -21.120393,
                        "lon": -42.9393766,
                        "rank": {"importance": 0.0000627, "confidence": 0.5}
                      }
                    },
                    {
                      "type": "Feature",
                      "properties": {
                        "result_type": "suburb",
                        "formatted": "Centro, Americana - SP, 13465-279, Brasil",
                        "city": "Americana",
                        "suburb": "Centro",
                        "state_code": "SP",
                        "lat": -22.7403644,
                        "lon": -47.3305045,
                        "rank": {"importance": 0.146729, "confidence": 0.0}
                      }
                    }
                  ]
                }
                """;

        ProvedorGeoapify geoapify = criarGeoapify("chave-teste");
        var coords = geoapify.geocodificarRegiao("Americana, Centro");

        assertNotNull(coords);
        assertEquals("Centro, Americana - SP, 13465-279, Brasil", coords.nomeExibido());
        assertEquals(-22.7403644, coords.latitude(), 0.0001);
        assertEquals(-47.3305045, coords.longitude(), 0.0001);
    }

    @Test
    @DisplayName("Duas buscas seguidas na mesma região usam cache de 24h sem rechamar o servidor")
    void cacheEvitaNovaChamadaEmBuscasNaMesmaRegiao() {
        bodyPlaces = """
                {
                  "type": "FeatureCollection",
                  "features": [
                    {
                      "type": "Feature",
                      "properties": {
                        "place_id": "p1",
                        "name": "UBS Centro",
                        "categories": ["healthcare.clinic_or_praxis"],
                        "street": "Rua Rui Barbosa",
                        "city": "Americana",
                        "state_code": "SP",
                        "lat": -22.739,
                        "lon": -47.332
                      }
                    }
                  ]
                }
                """;

        AtomicLong relogio = new AtomicLong(1_000_000L);
        ProvedorGeograficoResiliente resiliente = new ProvedorGeograficoResiliente(
                criarGeoapify("chave-teste"),
                criarOverpass(),
                relogio::get,
                Duration.ofHours(24));

        List<Estabelecimento> primeira =
                resiliente.buscarPorCoordenadas(-22.7388, -47.3325, 5000, CategoriaServico.SAUDE, "ubs");
        assertEquals(1, primeira.size());
        assertEquals(1, chamadasPlaces.get());

        // Avança 1 hora (dentro das 24h) com coordenadas próximas na mesma célula (~1 km)
        relogio.addAndGet(Duration.ofHours(1).toMillis());
        List<Estabelecimento> segunda =
                resiliente.buscarPorCoordenadas(-22.7391, -47.3322, 5000, CategoriaServico.SAUDE, "posto");
        assertEquals(1, segunda.size());
        assertEquals("UBS Centro", segunda.get(0).nome());
        assertEquals(1, chamadasPlaces.get(), "Segunda busca dentro de 24h não deve chamar o servidor");
    }

    @Test
    @DisplayName("Quando Geoapify falha, cai para Overpass; quando todos falham após cache vencido, serve cache com aviso FR-011")
    void fallbackParaOverpassEServicoDeCacheVencidoNaFalhaTotal() {
        bodyPlaces = """
                {
                  "type": "FeatureCollection",
                  "features": [
                    {
                      "type": "Feature",
                      "properties": {
                        "place_id": "p2",
                        "name": "Farmácia Central",
                        "categories": ["healthcare.pharmacy"],
                        "city": "Americana",
                        "state_code": "SP",
                        "lat": -22.74,
                        "lon": -47.33,
                        "opening_hours": "Mo-Fr 08:00-18:00"
                      }
                    }
                  ]
                }
                """;
        bodyOverpass = """
                {
                  "elements": [
                    {
                      "id": 200,
                      "lat": -22.741,
                      "lon": -47.331,
                      "tags": {"name": "Hospital Fallback", "amenity": "hospital"}
                    }
                  ]
                }
                """;

        AtomicLong relogio = new AtomicLong(1_000_000L);
        ProvedorGeograficoResiliente resiliente = new ProvedorGeograficoResiliente(
                criarGeoapify("chave-teste"),
                criarOverpass(),
                relogio::get,
                Duration.ofHours(24));

        // 1) Aquece o cache pelo Geoapify
        List<Estabelecimento> inicial =
                resiliente.buscarPorCoordenadas(-22.74, -47.33, 5000, CategoriaServico.SAUDE, "farmácia");
        assertEquals("Farmácia Central", inicial.get(0).nome());

        // 2) Geoapify falha com 502 numa nova categoria -> cai automaticamente para Overpass
        statusPlaces = 502;
        List<Estabelecimento> viaOverpass =
                resiliente.buscarPorCoordenadas(-22.74, -47.33, 5000, CategoriaServico.EMERGENCIA, "hospital");
        assertEquals("Hospital Fallback", viaOverpass.get(0).nome());
        assertEquals(1, chamadasOverpass.get());

        // 3) Cache de SAUDE expira (> 24h) e agora TODOS os provedores externos falham -> serve cache com aviso FR-011
        relogio.addAndGet(Duration.ofHours(25).toMillis());
        statusOverpass = 503;

        List<Estabelecimento> cacheExpirado =
                resiliente.buscarPorCoordenadas(-22.74, -47.33, 5000, CategoriaServico.SAUDE, "farmácia");
        assertEquals(1, cacheExpirado.size());
        assertEquals("Farmácia Central", cacheExpirado.get(0).nome());
        assertFalse(cacheExpirado.get(0).horarioConfirmado());
        assertEquals(
                ProvedorGeograficoResiliente.AVISO_CACHE_DESATUALIZADO,
                cacheExpirado.get(0).avisoTransparencia());
    }

    @Test
    @DisplayName("Sem chave Geoapify configurada, pula Geoapify e consulta Overpass diretamente")
    void semChaveUsaOverpassDiretamente() {
        bodyOverpass = """
                {
                  "elements": [
                    {
                      "id": 300,
                      "lat": -22.742,
                      "lon": -47.332,
                      "tags": {"name": "UBS Direto Overpass", "amenity": "clinic"}
                    }
                  ]
                }
                """;

        ProvedorGeoapify semChave = criarGeoapify("   ");
        assertFalse(semChave.estaConfigurado());

        ProvedorGeograficoResiliente resiliente = new ProvedorGeograficoResiliente(
                semChave,
                criarOverpass(),
                System::currentTimeMillis,
                Duration.ofHours(24));

        List<Estabelecimento> locais =
                resiliente.buscarPorCoordenadas(-22.742, -47.332, 5000, CategoriaServico.SAUDE, "posto");
        assertEquals(1, locais.size());
        assertEquals("UBS Direto Overpass", locais.get(0).nome());
        assertEquals(0, chamadasPlaces.get(), "Não deve chamar Geoapify sem chave configurada");
        assertEquals(1, chamadasOverpass.get());
    }

    @Test
    @DisplayName("Quando Overpass falha com 503/timeout, recorre à busca regional delimitada via Nominatim viewbox")
    void quandoOverpassFalhaRecorreABuscaRegionalViaNominatim() {
        statusOverpass = 503;
        bodyOverpass = "Service Unavailable";
        statusNominatim = 200;
        bodyNominatim = """
                [
                  {
                    "place_id": 445566,
                    "lat": "-22.7395",
                    "lon": "-47.3310",
                    "name": "Drogasil Centro Americana",
                    "type": "pharmacy",
                    "address": {
                      "road": "Rua Trinta de Julho",
                      "house_number": "120",
                      "suburb": "Centro",
                      "city": "Americana",
                      "ISO3166-2-lvl4": "BR-SP",
                      "postcode": "13465-500"
                    },
                    "extratags": {
                      "phone": "+55 19 3461-0000"
                    }
                  }
                ]
                """;

        ProvedorGeograficoResiliente resiliente = new ProvedorGeograficoResiliente(
                criarGeoapify(""),
                criarOverpass(),
                System::currentTimeMillis,
                Duration.ofHours(24));

        List<Estabelecimento> locais =
                resiliente.buscarPorCoordenadas(-22.739, -47.331, 5000, CategoriaServico.SAUDE, "farmácia");

        assertEquals(1, locais.size());
        Estabelecimento est = locais.get(0);
        assertEquals("osm:nominatim:445566", est.id());
        assertEquals("Drogasil Centro Americana", est.nome());
        assertEquals("SP", est.endereco().estado());
        assertEquals("Rua Trinta de Julho, 120 - Centro, Americana", est.endereco().textoFormatado());
        assertEquals("+55 19 3461-0000", est.telefone());
        assertEquals(1, chamadasOverpass.get());
        assertEquals(1, chamadasNominatim.get());
        assertTrue(queriesNominatim.get(0).contains("bounded=1"));
        assertTrue(queriesNominatim.get(0).contains("viewbox="));
    }

    @Test
    @DisplayName("Contexto Spring injeta ProvedorGeograficoResiliente (@Primary) no ServicoLocalizador sem ambiguidade")
    void springResolveBeanPrimarioSemAmbiguidade() {
        try (AnnotationConfigApplicationContext ctx = new AnnotationConfigApplicationContext()) {
            ctx.registerBean(JsonMapper.class, () -> JsonMapper.builder().build());
            ctx.register(
                    ProvedorOpenStreetMapOverpass.class,
                    ProvedorGeoapify.class,
                    ProvedorGeograficoResiliente.class,
                    InterpretadorDeIntencaoPorPalavrasChave.class,
                    ServicoLocalizador.class);
            ctx.refresh();

            assertInstanceOf(ProvedorGeograficoResiliente.class, ctx.getBean(ProvedorGeografico.class));
            assertNotNull(ctx.getBean(ServicoLocalizador.class));
        }
    }
}
