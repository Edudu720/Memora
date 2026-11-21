package br.fatec.memora.antigolpe.dominio;

import java.util.List;

/**
 * Resultado interno de uma análise antigolpe antes do mapeamento para DTO da API.
 */
public record ResultadoAnaliseGolpe(
        NivelRiscoGolpe risco,
        String titulo,
        String explicacao,
        List<String> orientacoes,
        List<String> sinaisDetectados,
        boolean analisadoPorIa) {

    public ResultadoAnaliseGolpe {
        risco = risco == null ? NivelRiscoGolpe.BAIXO : risco;
        orientacoes = orientacoes == null ? List.of() : List.copyOf(orientacoes);
        sinaisDetectados = sinaisDetectados == null ? List.of() : List.copyOf(sinaisDetectados);
    }
}
