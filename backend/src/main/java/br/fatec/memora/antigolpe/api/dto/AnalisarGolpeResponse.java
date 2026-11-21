package br.fatec.memora.antigolpe.api.dto;

import br.fatec.memora.antigolpe.dominio.NivelRiscoGolpe;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

/**
 * Resposta da analise antigolpe com classificacao, explicacao e orientacoes praticas.
 */
public record AnalisarGolpeResponse(
        @JsonProperty("risco") NivelRiscoGolpe risco,
        @JsonProperty("titulo") String titulo,
        @JsonProperty("explicacao") String explicacao,
        @JsonProperty("orientacoes") List<String> orientacoes,
        @JsonProperty("sinaisDetectados") List<String> sinaisDetectados,
        @JsonProperty("analisadoPorIa") boolean analisadoPorIa) {}
