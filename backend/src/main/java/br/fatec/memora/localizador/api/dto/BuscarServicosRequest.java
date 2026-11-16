package br.fatec.memora.localizador.api.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.Size;

/**
 * Contrato de entrada para consulta de serviços essenciais.
 * Suporta busca por categoria, texto livre (linguagem natural), coordenadas GPS ou região manual.
 */
public record BuscarServicosRequest(
        @JsonProperty("consulta")
        @Size(max = 200, message = "A consulta deve ter no máximo 200 caracteres")
        String consulta,

        @JsonProperty("categoria")
        String categoria,

        @JsonProperty("localizacao")
        CoordenadaRequest localizacao,

        @JsonProperty("regiaoManual")
        @Size(max = 120, message = "A região manual deve ter no máximo 120 caracteres")
        String regiaoManual,

        @JsonProperty("raioMetros")
        Integer raioMetros) {

    public record CoordenadaRequest(
            @JsonProperty("latitude") Double latitude,
            @JsonProperty("longitude") Double longitude) {}

    public boolean temLocalizacaoValida() {
        return localizacao != null
                && localizacao.latitude() != null
                && localizacao.longitude() != null;
    }

    public boolean temRegiaoManualValida() {
        return regiaoManual != null && !regiaoManual.trim().isBlank();
    }
}
