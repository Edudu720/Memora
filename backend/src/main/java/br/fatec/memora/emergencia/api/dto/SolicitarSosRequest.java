package br.fatec.memora.emergencia.api.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;

/**
 * Payload de solicitação manual ou automática de emergência SOS (Feature 014).
 */
public record SolicitarSosRequest(
        @JsonProperty("tipo") @NotBlank @Size(max = 30) String tipo,
        @JsonProperty("eventoId") @NotNull UUID eventoId,
        @JsonProperty("localizacao") @Valid LocalizacaoRequest localizacao,
        @JsonProperty("contatoNome") @Size(max = 120) String contatoNome,
        @JsonProperty("contatoDestino") @Size(max = 160) String contatoDestino) {

    /** Coordenadas opcionais compartilhadas mediante autorização no aparelho. */
    public record LocalizacaoRequest(
            @JsonProperty("latitude")
                    @NotNull
                    @DecimalMin("-90.0")
                    @DecimalMax("90.0")
                    Double latitude,
            @JsonProperty("longitude")
                    @NotNull
                    @DecimalMin("-180.0")
                    @DecimalMax("180.0")
                    Double longitude) {}
}
