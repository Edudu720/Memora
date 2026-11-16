package br.fatec.memora.localizador.aplicacao;

import br.fatec.memora.localizador.api.dto.BuscarServicosRequest;
import br.fatec.memora.localizador.api.dto.BuscarServicosResponse;
import br.fatec.memora.localizador.dominio.CategoriaServico;
import br.fatec.memora.localizador.dominio.Estabelecimento;
import br.fatec.memora.localizador.infra.ProvedorGeografico;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import org.springframework.stereotype.Service;

/**
 * Serviço que orquestra a localização de serviços essenciais para o usuário sênior.
 * Garante privacidade absoluta (NFR-006): nenhuma coordenada geográfica é persistida.
 */
@Service
public class ServicoLocalizador {

    private static final int RAIO_PADRAO_METROS = 5000;
    private static final double RAIO_TERRA_METROS = 6371000.0;

    private final ProvedorGeografico provedorGeografico;
    private final InterpretadorDeIntencaoPorPalavrasChave interpretadorIntencao;

    public ServicoLocalizador(
            ProvedorGeografico provedorGeografico,
            InterpretadorDeIntencaoPorPalavrasChave interpretadorIntencao) {
        this.provedorGeografico = provedorGeografico;
        this.interpretadorIntencao = interpretadorIntencao;
    }

    public BuscarServicosResponse buscar(BuscarServicosRequest request) {
        if (!request.temLocalizacaoValida() && !request.temRegiaoManualValida()) {
            throw new IllegalArgumentException(
                    "É necessário autorizar a localização ou informar uma cidade/bairro de referência.");
        }

        CategoriaServico categoriaFiltro = parseCategoria(request.categoria());
        var intencao = interpretadorIntencao.interpretar(request.consulta(), categoriaFiltro);
        CategoriaServico categoriaEfetiva = intencao.categoria();

        double latitudeOrigem;
        double longitudeOrigem;
        String descricaoRegiao;
        String modoOrigem;

        if (request.temLocalizacaoValida()) {
            latitudeOrigem = request.localizacao().latitude();
            longitudeOrigem = request.localizacao().longitude();
            descricaoRegiao = "Sua localização atual";
            modoOrigem = "GPS_DISPOSITIVO";
        } else {
            var coords = provedorGeografico.geocodificarRegiao(request.regiaoManual());
            if (coords == null) {
                throw new IllegalArgumentException(
                        "Não foi possível encontrar a região informada. Tente digitar o nome da cidade e do bairro.");
            }
            latitudeOrigem = coords.latitude();
            longitudeOrigem = coords.longitude();
            descricaoRegiao = coords.nomeExibido();
            modoOrigem = "REGIAO_MANUAL";
        }

        int raio = (request.raioMetros() != null && request.raioMetros() > 0)
                ? request.raioMetros()
                : RAIO_PADRAO_METROS;

        List<Estabelecimento> brutos = provedorGeografico.buscarPorCoordenadas(
                latitudeOrigem,
                longitudeOrigem,
                raio,
                categoriaEfetiva,
                intencao.termoChave());

        List<Estabelecimento> comDistancia = brutos.stream()
                .map(e -> {
                    if (e.latitude() != null && e.longitude() != null) {
                        double distancia = calcularHaversine(latitudeOrigem, longitudeOrigem, e.latitude(), e.longitude());
                        return e.comDistancia(distancia, formatarDistanciaAmigavel(distancia));
                    }
                    return e;
                })
                .sorted(Comparator.comparing(
                        e -> e.distanciaMetros() != null ? e.distanciaMetros() : Double.MAX_VALUE))
                .toList();

        List<BuscarServicosResponse.EstabelecimentoDto> dtos = comDistancia.stream()
                .map(BuscarServicosResponse.EstabelecimentoDto::deDominio)
                .toList();

        var consultaDto = new BuscarServicosResponse.ConsultaInterpretadaDto(
                categoriaEfetiva.name(),
                intencao.termoChave(),
                intencao.mensagemExplicativa());

        var regiaoDto = new BuscarServicosResponse.RegiaoOrigemDto(
                descricaoRegiao,
                latitudeOrigem,
                longitudeOrigem,
                modoOrigem);

        return new BuscarServicosResponse(
                consultaDto,
                regiaoDto,
                dtos.size(),
                dtos);
    }

    private CategoriaServico parseCategoria(String raw) {
        if (raw == null || raw.trim().isBlank()) return null;
        try {
            return CategoriaServico.valueOf(raw.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    /**
     * Calcula distância geodésica entre dois pontos usando Haversine em metros.
     */
    public static double calcularHaversine(double lat1, double lon1, double lat2, double lon2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return RAIO_TERRA_METROS * c;
    }

    /**
     * Formata distância de forma acessível e compreensível para idosos.
     */
    public static String formatarDistanciaAmigavel(double metros) {
        if (metros < 1000) {
            return Math.round(metros) + " metros";
        }
        double km = metros / 1000.0;
        return String.format(Locale.forLanguageTag("pt-BR"), "%.1f km", km);
    }
}
