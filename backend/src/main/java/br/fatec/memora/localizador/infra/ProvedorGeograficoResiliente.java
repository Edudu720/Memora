package br.fatec.memora.localizador.infra;

import br.fatec.memora.localizador.dominio.CategoriaServico;
import br.fatec.memora.localizador.dominio.Estabelecimento;
import java.time.Duration;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.LongSupplier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;

/**
 * Orquestrador resiliente dos provedores geográficos (Issue #81).
 *
 * <p>Combina cache regional em memória (padrão 24h), provedor principal {@link ProvedorGeoapify}
 * quando a chave de API está configurada e fallback automático para
 * {@link ProvedorOpenStreetMapOverpass} com rodízio de instâncias. Caso todos os provedores
 * externos falhem após haver cache prévio da mesma região, devolve os dados recentes com aviso
 * transparente de possível desatualização (FR-011 / NFR-005).
 */
@Component
@Primary
public class ProvedorGeograficoResiliente implements ProvedorGeografico {

    public static final String AVISO_CACHE_DESATUALIZADO =
            "Dados exibidos de consulta recente salva temporariamente; confirme horários por telefone antes de sair.";

    private static final Logger LOG = LoggerFactory.getLogger(ProvedorGeograficoResiliente.class);
    private static final int MAX_ENTRADAS_CACHE = 500;

    private final ProvedorGeoapify provedorGeoapify;
    private final ProvedorOpenStreetMapOverpass provedorOverpass;
    private final LongSupplier relogioMs;
    private final Duration ttlCache;
    private final Map<String, EntradaCacheLocais> cacheLocais = new ConcurrentHashMap<>();
    private final Map<String, EntradaCacheGeocode> cacheGeocode = new ConcurrentHashMap<>();

    @Autowired
    public ProvedorGeograficoResiliente(
            ProvedorGeoapify provedorGeoapify,
            ProvedorOpenStreetMapOverpass provedorOverpass,
            @Value("${memora.localizador.cache.ttl-horas:24}") long ttlHoras) {
        this(
                provedorGeoapify,
                provedorOverpass,
                System::currentTimeMillis,
                Duration.ofHours(Math.max(1L, ttlHoras)));
    }

    ProvedorGeograficoResiliente(
            ProvedorGeoapify provedorGeoapify,
            ProvedorOpenStreetMapOverpass provedorOverpass,
            LongSupplier relogioMs,
            Duration ttlCache) {
        this.provedorGeoapify = provedorGeoapify;
        this.provedorOverpass = provedorOverpass;
        this.relogioMs = relogioMs != null ? relogioMs : System::currentTimeMillis;
        this.ttlCache = (ttlCache != null && !ttlCache.isNegative() && !ttlCache.isZero())
                ? ttlCache
                : Duration.ofHours(24);
    }

    @Override
    public List<Estabelecimento> buscarPorCoordenadas(
            double latitude,
            double longitude,
            int raioMetros,
            CategoriaServico categoria,
            String termoFiltro) {

        String chave = construirChaveLocais(latitude, longitude, raioMetros, categoria);
        long agora = relogioMs.getAsLong();
        EntradaCacheLocais emCache = cacheLocais.get(chave);

        if (emCache != null && estaValido(emCache.instanteMs(), agora)) {
            return emCache.estabelecimentos();
        }

        try {
            List<Estabelecimento> aoVivo =
                    consultarLocaisAoVivo(latitude, longitude, raioMetros, categoria, termoFiltro);
            if (!aoVivo.isEmpty()) {
                limitarTamanhoCache(cacheLocais);
                cacheLocais.put(chave, new EntradaCacheLocais(List.copyOf(aoVivo), agora));
            }
            return aoVivo;
        } catch (ProvedorGeograficoIndisponivelException falha) {
            if (emCache != null && !emCache.estabelecimentos().isEmpty()) {
                LOG.warn(
                        "Provedores externos indisponíveis ({}). Servindo cache recente da região {}.",
                        falha.getMessage(),
                        chave);
                return marcarComoCacheRecente(emCache.estabelecimentos());
            }
            throw falha;
        }
    }

    @Override
    public CoordenadasGeo geocodificarRegiao(String regiaoManual) {
        if (regiaoManual == null || regiaoManual.trim().isBlank()) {
            return null;
        }

        String chave = regiaoManual.trim().toLowerCase(Locale.ROOT);
        long agora = relogioMs.getAsLong();
        EntradaCacheGeocode emCache = cacheGeocode.get(chave);

        if (emCache != null && estaValido(emCache.instanteMs(), agora)) {
            return emCache.coordenadas();
        }

        try {
            CoordenadasGeo coords = consultarGeocodeAoVivo(regiaoManual);
            if (coords != null) {
                limitarTamanhoCache(cacheGeocode);
                cacheGeocode.put(chave, new EntradaCacheGeocode(coords, agora));
            }
            return coords;
        } catch (ProvedorGeograficoIndisponivelException falha) {
            if (emCache != null) {
                LOG.warn(
                        "Geocodificação externa indisponível ({}). Usando cache recente para região.",
                        falha.getMessage());
                return emCache.coordenadas();
            }
            throw falha;
        }
    }

    private List<Estabelecimento> consultarLocaisAoVivo(
            double latitude,
            double longitude,
            int raioMetros,
            CategoriaServico categoria,
            String termoFiltro) {
        if (provedorGeoapify != null && provedorGeoapify.estaConfigurado()) {
            try {
                return provedorGeoapify.buscarPorCoordenadas(
                        latitude, longitude, raioMetros, categoria, termoFiltro);
            } catch (ProvedorGeograficoIndisponivelException falhaGeoapify) {
                LOG.warn(
                        "Geoapify falhou na busca ({}). Recorrendo ao fallback Overpass.",
                        falhaGeoapify.getMessage());
            }
        }
        try {
            return provedorOverpass.buscarPorCoordenadas(
                    latitude, longitude, raioMetros, categoria, termoFiltro);
        } catch (ProvedorGeograficoIndisponivelException falhaOverpass) {
            LOG.warn(
                    "Overpass indisponível ({}). Recorrendo à busca regional via Nominatim.",
                    falhaOverpass.getMessage());
            return provedorOverpass.buscarPorCoordenadasViaNominatim(
                    latitude, longitude, raioMetros, categoria, termoFiltro);
        }
    }

    private CoordenadasGeo consultarGeocodeAoVivo(String regiaoManual) {
        if (provedorGeoapify != null && provedorGeoapify.estaConfigurado()) {
            try {
                return provedorGeoapify.geocodificarRegiao(regiaoManual);
            } catch (ProvedorGeograficoIndisponivelException falhaGeoapify) {
                LOG.warn(
                        "Geoapify falhou na geocodificação ({}). Recorrendo ao Nominatim.",
                        falhaGeoapify.getMessage());
            }
        }
        return provedorOverpass.geocodificarRegiao(regiaoManual);
    }

    private List<Estabelecimento> marcarComoCacheRecente(List<Estabelecimento> originais) {
        return originais.stream()
                .map(e -> new Estabelecimento(
                        e.id(),
                        e.nome(),
                        e.categoria(),
                        e.subtituloTipo(),
                        e.endereco(),
                        e.latitude(),
                        e.longitude(),
                        e.distanciaMetros(),
                        e.distanciaFormatada(),
                        e.telefone(),
                        e.horarioFuncionamento(),
                        false,
                        e.fonte(),
                        AVISO_CACHE_DESATUALIZADO))
                .toList();
    }

    private String construirChaveLocais(
            double latitude, double longitude, int raioMetros, CategoriaServico categoria) {
        CategoriaServico catEfetiva = categoria != null ? categoria : CategoriaServico.SAUDE;
        double latCelula = Math.round(latitude * 100.0) / 100.0;
        double lonCelula = Math.round(longitude * 100.0) / 100.0;
        return String.format(Locale.US, "%s:%.2f:%.2f:%d", catEfetiva.name(), latCelula, lonCelula, raioMetros);
    }

    private boolean estaValido(long instanteCacheMs, long agoraMs) {
        return agoraMs >= instanteCacheMs && (agoraMs - instanteCacheMs) <= ttlCache.toMillis();
    }

    private void limitarTamanhoCache(Map<String, ?> mapa) {
        if (mapa.size() >= MAX_ENTRADAS_CACHE) {
            mapa.clear();
        }
    }

    private record EntradaCacheLocais(List<Estabelecimento> estabelecimentos, long instanteMs) {}

    private record EntradaCacheGeocode(CoordenadasGeo coordenadas, long instanteMs) {}
}
