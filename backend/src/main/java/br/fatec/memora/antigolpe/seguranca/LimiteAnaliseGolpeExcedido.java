package br.fatec.memora.antigolpe.seguranca;

/**
 * Exceção lançada quando a pessoa excede o limite temporário de análises antigolpe.
 */
public class LimiteAnaliseGolpeExcedido extends RuntimeException {

    private static final long serialVersionUID = 1L;

    private final long tentarNovamenteEmSegundos;

    public LimiteAnaliseGolpeExcedido(long tentarNovamenteEmSegundos) {
        super("Limite temporario de analises antigolpe excedido.");
        this.tentarNovamenteEmSegundos = Math.max(1L, tentarNovamenteEmSegundos);
    }

    public long tentarNovamenteEmSegundos() {
        return tentarNovamenteEmSegundos;
    }
}
