package br.fatec.memora.localizador.infra;

/**
 * Exceção lançada quando os provedores geográficos externos (Nominatim ou Overpass API)
 * estão indisponíveis, expiram o tempo limite ou retornam resposta inválida.
 */
public class ProvedorGeograficoIndisponivelException extends RuntimeException {

    public ProvedorGeograficoIndisponivelException(String message) {
        super(message);
    }

    public ProvedorGeograficoIndisponivelException(String message, Throwable cause) {
        super(message, cause);
    }
}
