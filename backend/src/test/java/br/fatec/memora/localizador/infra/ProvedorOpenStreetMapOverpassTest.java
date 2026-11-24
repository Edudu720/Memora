package br.fatec.memora.localizador.infra;

import static org.junit.jupiter.api.Assertions.*;

import br.fatec.memora.localizador.dominio.CategoriaServico;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicLong;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.json.JsonMapper;

class ProvedorOpenStreetMapOverpassTest {

    private HttpServer server;
    private volatile int statusOverpass = 200;
    private volatile String bodyOverpass = "{\"elements\":[]}";
    private volatile int statusNominatim = 200;
    private volatile String bodyNominatim = "[]";
    private volatile long atrasoOverpassMs = 0L;
    private volatile long atrasoNominatimMs = 0L;
    private final List<String> userAgentsOverpass = new CopyOnWriteArrayList<>();
    private final List<String> userAgentsNominatim = new CopyOnWriteArrayList<>();
    private final List<String> corposOverpass = new CopyOnWriteArrayList<>();

    @BeforeEach
    void setUp() throws IOException {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/overpass", exchange -> {
            userAgentsOverpass.add(exchange.getRequestHeaders().getFirst("User-Agent"));
            corposOverpass.add(new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));
            if (atrasoOverpassMs > 0) {
                try {
                    Thread.sleep(atrasoOverpassMs);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }
            byte[] bytes = bodyOverpass.getBytes(StandardCharsets.UTF_8);
            exchange.sendResponseHeaders(statusOverpass, bytes.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(bytes);
            }
        });
        server.createContext("/nominatim", exchange -> {
            userAgentsNominatim.add(exchange.getRequestHeaders().getFirst("User-Agent"));
            if (atrasoNominatimMs > 0) {
                try {
                    Thread.sleep(atrasoNominatimMs);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }
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

    private ProvedorOpenStreetMapOverpass criarProvedor() {
        int port = server.getAddress().getPort();
        return new ProvedorOpenStreetMapOverpass(
                JsonMapper.builder().build(),
                "http://127.0.0.1:" + port + "/overpass",
                "http://127.0.0.1:" + port + "/nominatim");
    }

    @Test
    @DisplayName("Lança ProvedorGeograficoIndisponivelException quando Overpass retorna erro HTTP sem usar base de Americana")
    void lancaExcecaoQuandoOverpassFalhaSemContingencia() {
        statusOverpass = 503;
        bodyOverpass = "Service Unavailable";
        ProvedorOpenStreetMapOverpass provedor = criarProvedor();

        assertThrows(
                ProvedorGeograficoIndisponivelException.class,
                () -> provedor.buscarPorCoordenadas(-23.5505, -46.6333, 5000, CategoriaServico.SAUDE, "ubs"));
    }

    @Test
    @DisplayName("Retorna null sem coordenadas padrão de Americana quando Nominatim não encontra região")
    void retornaNullSemFallbackAmericanaQuandoRegiaoNaoEncontrada() {
        statusNominatim = 200;
        bodyNominatim = "[]";
        ProvedorOpenStreetMapOverpass provedor = criarProvedor();

        assertNull(provedor.geocodificarRegiao("Bairro Inexistente XYZ"));
    }

    @Test
    @DisplayName("Lança ProvedorGeograficoIndisponivelException quando Nominatim falha com HTTP 503")
    void lancaExcecaoQuandoNominatimFalha() {
        statusNominatim = 503;
        bodyNominatim = "Unavailable";
        ProvedorOpenStreetMapOverpass provedor = criarProvedor();

        assertThrows(
                ProvedorGeograficoIndisponivelException.class,
                () -> provedor.geocodificarRegiao("Centro, São Paulo"));
    }

    @Test
    @DisplayName("Retorna lista vazia legítima quando Overpass responde 200 com zero elementos")
    void retornaListaVaziaLegitimaEmZeroElementos() {
        statusOverpass = 200;
        bodyOverpass = "{\"elements\":[]}";
        ProvedorOpenStreetMapOverpass provedor = criarProvedor();

        var resultado = provedor.buscarPorCoordenadas(-23.5505, -46.6333, 5000, CategoriaServico.SAUDE, "posto");
        assertNotNull(resultado);
        assertTrue(resultado.isEmpty());
    }

    @Test
    @DisplayName("Envia User-Agent identificável do Memora para Overpass e Nominatim")
    void enviaUserAgentDoProjetoParaOverpassENominatim() {
        statusOverpass = 200;
        bodyOverpass = "{\"elements\":[]}";
        statusNominatim = 200;
        bodyNominatim = "[{\"lat\":\"-23.5505\",\"lon\":\"-46.6333\",\"display_name\":\"São Paulo, Brasil\"}]";
        ProvedorOpenStreetMapOverpass provedor = criarProvedor();

        provedor.geocodificarRegiao("São Paulo");
        provedor.buscarPorCoordenadas(-23.5505, -46.6333, 5000, CategoriaServico.SAUDE, "posto");

        assertEquals(1, userAgentsNominatim.size());
        assertEquals(ProvedorOpenStreetMapOverpass.USER_AGENT_PROJETO, userAgentsNominatim.get(0));
        assertEquals(1, userAgentsOverpass.size());
        assertEquals(ProvedorOpenStreetMapOverpass.USER_AGENT_PROJETO, userAgentsOverpass.get(0));
    }

    @Test
    @DisplayName("Garante fila sincronizada com intervalo mínimo de 1000 ms entre consultas ao Nominatim")
    void enfileiraConsultasNominatimComIntervaloMinimoDeUmSegundo() {
        statusNominatim = 200;
        bodyNominatim = "[{\"lat\":\"-23.5505\",\"lon\":\"-46.6333\",\"display_name\":\"São Paulo, Brasil\"}]";

        AtomicLong relogioSimulado = new AtomicLong(10_000L);
        List<Long> pausasRegistradas = new CopyOnWriteArrayList<>();

        int port = server.getAddress().getPort();
        ProvedorOpenStreetMapOverpass provedor = new ProvedorOpenStreetMapOverpass(
                JsonMapper.builder().build(),
                "http://127.0.0.1:" + port + "/overpass",
                "http://127.0.0.1:" + port + "/nominatim",
                relogioSimulado::get,
                ms -> {
                    pausasRegistradas.add(ms);
                    relogioSimulado.addAndGet(ms);
                });

        provedor.geocodificarRegiao("Sé, São Paulo");
        assertTrue(pausasRegistradas.isEmpty(), "Primeira requisição não deve sofrer atraso desnecessário");

        relogioSimulado.addAndGet(200L);
        provedor.geocodificarRegiao("Pinheiros, São Paulo");

        assertEquals(1, pausasRegistradas.size());
        assertEquals(800L, pausasRegistradas.get(0));
    }

    @Test
    @DisplayName("Serializa chamadas concorrentes ao Nominatim garantindo >= 1000 ms entre consultas")
    void serializaChamadasConcorrentesNoNominatim() throws Exception {
        statusNominatim = 200;
        bodyNominatim = "[{\"lat\":\"-25.4284\",\"lon\":\"-49.2733\",\"display_name\":\"Curitiba, PR\"}]";

        AtomicLong relogioSimulado = new AtomicLong(50_000L);
        List<Long> instantesChamada = Collections.synchronizedList(new ArrayList<>());

        int port = server.getAddress().getPort();
        ProvedorOpenStreetMapOverpass provedor = new ProvedorOpenStreetMapOverpass(
                JsonMapper.builder().build(),
                "http://127.0.0.1:" + port + "/overpass",
                "http://127.0.0.1:" + port + "/nominatim",
                () -> {
                    long t = relogioSimulado.get();
                    instantesChamada.add(t);
                    return t;
                },
                ms -> relogioSimulado.addAndGet(ms));

        ExecutorService pool = Executors.newFixedThreadPool(2);
        CountDownLatch partida = new CountDownLatch(1);
        try {
            Future<?> f1 = pool.submit(() -> {
                partida.await();
                return provedor.geocodificarRegiao("Centro, Curitiba");
            });
            Future<?> f2 = pool.submit(() -> {
                partida.await();
                return provedor.geocodificarRegiao("Batel, Curitiba");
            });

            partida.countDown();
            assertNotNull(f1.get(5, TimeUnit.SECONDS));
            assertNotNull(f2.get(5, TimeUnit.SECONDS));
        } finally {
            pool.shutdownNow();
        }

        assertEquals(2, userAgentsNominatim.size());
        assertTrue(relogioSimulado.get() - 50_000L >= ProvedorOpenStreetMapOverpass.INTERVALO_MINIMO_NOMINATIM_MS);
    }

    @Test
    @DisplayName("Envia [timeout:5] no Overpass, mantém padrões 5s/6s e converte timeouts em 503")
    void respeitaTimeoutsConfiguradosEConverteExpiracaoEmExcecao() {
        ProvedorOpenStreetMapOverpass padrao = new ProvedorOpenStreetMapOverpass(JsonMapper.builder().build());
        assertEquals(Duration.ofSeconds(5), padrao.timeoutNominatimConfigurado());
        assertEquals(Duration.ofSeconds(6), padrao.timeoutOverpassConfigurado());

        statusOverpass = 200;
        bodyOverpass = "{\"elements\":[]}";
        criarProvedor().buscarPorCoordenadas(-25.4284, -49.2733, 5000, CategoriaServico.SAUDE, "posto");
        assertEquals(1, corposOverpass.size());
        assertTrue(corposOverpass.get(0).contains("[out:json][timeout:5];"));

        int port = server.getAddress().getPort();
        ProvedorOpenStreetMapOverpass comTimeoutCurto = new ProvedorOpenStreetMapOverpass(
                JsonMapper.builder().build(),
                "http://127.0.0.1:" + port + "/overpass",
                "http://127.0.0.1:" + port + "/nominatim",
                System::currentTimeMillis,
                ms -> {},
                Duration.ofMillis(120),
                Duration.ofMillis(120));

        atrasoNominatimMs = 350L;
        assertThrows(
                ProvedorGeograficoIndisponivelException.class,
                () -> comTimeoutCurto.geocodificarRegiao("Recife, PE"));

        atrasoNominatimMs = 0L;
        atrasoOverpassMs = 350L;
        assertThrows(
                ProvedorGeograficoIndisponivelException.class,
                () -> comTimeoutCurto.buscarPorCoordenadas(-8.0476, -34.8770, 5000, CategoriaServico.SAUDE, "ubs"));
    }

    @Test
    @DisplayName("Extrai addr:state do OpenStreetMap sem fixar SP em estabelecimentos de outros estados")
    void extraiEstadoRealSemFixarSp() {
        statusOverpass = 200;
        bodyOverpass = """
                {
                  "elements": [
                    {
                      "id": 101,
                      "lat": -25.4284,
                      "lon": -49.2733,
                      "tags": {
                        "name": "UBS Matriz Curitiba",
                        "amenity": "clinic",
                        "addr:street": "Rua XV de Novembro",
                        "addr:city": "Curitiba",
                        "addr:state": "PR"
                      }
                    },
                    {
                      "id": 102,
                      "lat": -8.0476,
                      "lon": -34.8770,
                      "tags": {
                        "name": "Posto Recife Centro",
                        "amenity": "hospital",
                        "addr:city": "Recife"
                      }
                    }
                  ]
                }
                """;

        var lista = criarProvedor()
                .buscarPorCoordenadas(-25.4284, -49.2733, 5000, CategoriaServico.SAUDE, "ubs");

        assertEquals(2, lista.size());
        assertEquals("PR", lista.get(0).endereco().estado());
        assertNull(lista.get(1).endereco().estado());
    }

    @Test
    @DisplayName("Faz rodízio para a segunda instância do Overpass quando a primeira falha com 502")
    void fazRodizioQuandoPrimeiraInstanciaFalha() {
        server.createContext("/overpass-falho", exchange -> {
            byte[] bytes = "server busy".getBytes(StandardCharsets.UTF_8);
            exchange.sendResponseHeaders(502, bytes.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(bytes);
            }
        });

        statusOverpass = 200;
        bodyOverpass = """
                {
                  "elements": [
                    {
                      "id": 777,
                      "lat": -22.74,
                      "lon": -47.33,
                      "tags": {
                        "name": "Farmácia Rodízio",
                        "amenity": "pharmacy"
                      }
                    }
                  ]
                }
                """;

        int port = server.getAddress().getPort();
        ProvedorOpenStreetMapOverpass provedor = new ProvedorOpenStreetMapOverpass(
                JsonMapper.builder().build(),
                List.of(
                        "http://127.0.0.1:" + port + "/overpass-falho",
                        "http://127.0.0.1:" + port + "/overpass"),
                "http://127.0.0.1:" + port + "/nominatim");

        var resultado = provedor.buscarPorCoordenadas(-22.74, -47.33, 5000, CategoriaServico.SAUDE, "farmácia");
        assertEquals(1, resultado.size());
        assertEquals("Farmácia Rodízio", resultado.get(0).nome());
        assertEquals(1, userAgentsOverpass.size());
    }

    @Test
    @DisplayName("Busca regional via Nominatim viewbox extrai estabelecimentos, estado ISO3166-2 e extratags")
    void buscarPorCoordenadasViaNominatimExtraiEstabelecimentosReais() {
        statusNominatim = 200;
        bodyNominatim = """
                [
                  {
                    "place_id": 987654,
                    "lat": "-22.7412",
                    "lon": "-47.3318",
                    "name": "Hospital Municipal Dr. Waldemar Tebaldi",
                    "type": "hospital",
                    "display_name": "Hospital Municipal Dr. Waldemar Tebaldi, Avenida da Saúde, Americana, SP, Brasil",
                    "address": {
                      "road": "Avenida da Saúde",
                      "house_number": "415",
                      "suburb": "Jardim Nossa Senhora de Fátima",
                      "city": "Americana",
                      "state": "São Paulo",
                      "ISO3166-2-lvl4": "BR-SP",
                      "postcode": "13478-640"
                    },
                    "extratags": {
                      "phone": "+55 19 3471-6750",
                      "opening_hours": "24/7"
                    }
                  }
                ]
                """;

        ProvedorOpenStreetMapOverpass provedor = criarProvedor();
        var lista = provedor.buscarPorCoordenadasViaNominatim(
                -22.74, -47.33, 5000, CategoriaServico.SAUDE, "Saúde");

        assertEquals(1, lista.size());
        var est = lista.get(0);
        assertEquals("osm:nominatim:987654", est.id());
        assertEquals("Hospital Municipal Dr. Waldemar Tebaldi", est.nome());
        assertEquals("hospital", est.subtituloTipo());
        assertEquals("SP", est.endereco().estado());
        assertEquals("Avenida da Saúde, 415 - Jardim Nossa Senhora de Fátima, Americana", est.endereco().textoFormatado());
        assertEquals("+55 19 3471-6750", est.telefone());
        assertEquals("24/7", est.horarioFuncionamento());
        assertTrue(est.horarioConfirmado());
        assertNull(est.avisoTransparencia());
    }
}
