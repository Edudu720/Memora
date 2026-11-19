package br.fatec.memora.emergencia.api.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.Instant;
import java.util.UUID;

/**
 * Resposta da solicitação de emergência SOS com status verdadeiro do envio (FR-010, BR-007).
 */
public record SolicitarSosResponse(
        @JsonProperty("eventoId") UUID eventoId,
        @JsonProperty("tipo") String tipo,
        @JsonProperty("status") String status,
        @JsonProperty("mensagem") String mensagem,
        @JsonProperty("ocorridoEm") Instant ocorridoEm) {}
