package br.fatec.memora.antigolpe.dominio;

/**
 * Classificação de risco de golpe atribuída a uma mensagem ou link analisado.
 */
public enum NivelRiscoGolpe {
    BAIXO,
    MEDIO,
    ALTO;

    /**
     * Retorna o maior nível de risco entre {@code a} e {@code b}, garantindo piso monotônico.
     */
    public static NivelRiscoGolpe max(NivelRiscoGolpe a, NivelRiscoGolpe b) {
        if (a == null) {
            return b == null ? BAIXO : b;
        }
        if (b == null) {
            return a;
        }
        return a.ordinal() >= b.ordinal() ? a : b;
    }
}
