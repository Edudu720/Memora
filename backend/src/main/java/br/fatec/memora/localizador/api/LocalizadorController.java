package br.fatec.memora.localizador.api;

import br.fatec.memora.localizador.api.dto.BuscarServicosRequest;
import br.fatec.memora.localizador.api.dto.BuscarServicosResponse;
import br.fatec.memora.localizador.aplicacao.ServicoLocalizador;
import br.fatec.memora.localizador.infra.ProvedorGeograficoIndisponivelException;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Endpoint de busca de serviços essenciais (FR-001, FR-006, contracts/localizador-api.md).
 */
@RestController
@RequestMapping({"/v1/servicos", "/api/v1/servicos"})
public class LocalizadorController {

    private final ServicoLocalizador servicoLocalizador;

    public LocalizadorController(ServicoLocalizador servicoLocalizador) {
        this.servicoLocalizador = servicoLocalizador;
    }

    @PostMapping("/buscar")
    public ResponseEntity<?> buscar(@RequestBody @Valid BuscarServicosRequest request) {
        try {
            BuscarServicosResponse response = servicoLocalizador.buscar(request);
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "status", 400,
                    "erro", "DADOS_INSUFICIENTES",
                    "mensagem", e.getMessage()));
        } catch (ProvedorGeograficoIndisponivelException e) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(Map.of(
                    "status", 503,
                    "erro", "PROVEDOR_GEOGRAFICO_INDISPONIVEL",
                    "mensagem", "Não foi possível consultar o serviço de mapas no momento. Tente novamente em instantes."));
        }
    }
}
