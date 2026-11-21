package br.fatec.memora.antigolpe.api.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Corpo da requisicao de analise de mensagens ou links suspeitos.
 */
public record AnalisarGolpeRequest(
        @JsonProperty("conteudo") @NotBlank @Size(max = 2000) String conteudo) {}
