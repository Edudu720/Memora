package br.fatec.memora.emergencia.api;

import br.fatec.memora.autenticacao.seguranca.PessoaAutenticada;
import br.fatec.memora.comum.CodigoDeErro;
import br.fatec.memora.comum.FalhaDoMemora;
import br.fatec.memora.emergencia.api.dto.SolicitarSosRequest;
import br.fatec.memora.emergencia.api.dto.SolicitarSosResponse;
import br.fatec.memora.emergencia.aplicacao.ServicoEmergenciaSos;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Endpoint autenticado para acionamento de emergência SOS (Feature 014).
 *
 * <p>A classificação {@code QUEDA_AUTOMATICA} existe no modelo apenas como reserva estrutural; no
 * aplicativo todo pedido remoto exige confirmação explícita da pessoa (Princípio VI).
 */
@RestController
@RequestMapping({"/v1/emergencias", "/api/v1/emergencias"})
public class EmergenciaSosController {

    private final ServicoEmergenciaSos servico;

    public EmergenciaSosController(ServicoEmergenciaSos servico) {
        this.servico = servico;
    }

    @PostMapping("/sos")
    public ResponseEntity<SolicitarSosResponse> solicitarSos(
            @AuthenticationPrincipal PessoaAutenticada pessoa,
            @Valid @RequestBody SolicitarSosRequest request) {
        if (pessoa == null || pessoa.estaPendenteDeVerificacao()) {
            throw FalhaDoMemora.de(CodigoDeErro.SESSAO_EXPIRADA);
        }
        SolicitarSosResponse resposta = servico.registrarEEnviar(pessoa.id(), request);
        return ResponseEntity.ok(resposta);
    }
}
