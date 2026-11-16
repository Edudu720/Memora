package br.fatec.memora.localizador.infra;

import br.fatec.memora.localizador.dominio.CategoriaServico;
import br.fatec.memora.localizador.dominio.Estabelecimento;
import java.util.List;

/**
 * Contrato de integração com provedores de dados geográficos abertos e verificáveis.
 */
public interface ProvedorGeografico {

    /**
     * Busca estabelecimentos em um raio geográfico (metros) a partir de coordenadas.
     */
    List<Estabelecimento> buscarPorCoordenadas(
            double latitude,
            double longitude,
            int raioMetros,
            CategoriaServico categoria,
            String termoFiltro);

    /**
     * Busca coordenadas para uma região manual (ex: "Jardim Ipiranga, Americana SP").
     */
    CoordenadasGeo geocodificarRegiao(String regiaoManual);

    record CoordenadasGeo(double latitude, double longitude, String nomeExibido) {}
}
