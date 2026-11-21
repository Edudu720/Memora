package br.fatec.memora.antigolpe.api;

import br.fatec.memora.antigolpe.api.dto.AnalisarGolpeRequest;
import br.fatec.memora.antigolpe.api.dto.AnalisarGolpeResponse;
import br.fatec.memora.antigolpe.aplicacao.ServicoAnaliseGolpe;
import br.fatec.memora.antigolpe.seguranca.LimiteAnaliseGolpeExcedido;
import br.fatec.memora.autenticacao.seguranca.PessoaAutenticada;
import br.fatec.memora.comum.CodigoDeErro;
import br.fatec.memora.comum.Erro;
import br.fatec.memora.comum.FalhaDoMemora;
import jakarta.validation.Valid;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Endpoint autenticado para analise de risco de golpe em mensagens e links suspeitos.
 */
@RestController
@RequestMapping({"/v1/golpes", "/api/v1/golpes"})
public class ControladorAnaliseGolpe {

    private static final String MENSAGEM_LIMITE_EXCEDIDO =
            "Você já fez várias análises por agora. Vamos aguardar um pouquinho para tentar de novo?";

    private final ServicoAnaliseGolpe servico;

    public ControladorAnaliseGolpe(ServicoAnaliseGolpe servico) {
        this.servico = servico;
    }

    @PostMapping("/analisar")
    public ResponseEntity<AnalisarGolpeResponse> analisar(
            @AuthenticationPrincipal PessoaAutenticada pessoa,
            @Valid @RequestBody AnalisarGolpeRequest requisicao) {
        if (pessoa == null || pessoa.estaPendenteDeVerificacao()) {
            throw FalhaDoMemora.de(CodigoDeErro.SESSAO_EXPIRADA);
        }
        return ResponseEntity.ok(servico.analisar(pessoa.id(), requisicao.conteudo()));
    }

    @ExceptionHandler(LimiteAnaliseGolpeExcedido.class)
    public ResponseEntity<Erro> tratarLimiteExcedido(LimiteAnaliseGolpeExcedido ex) {
        long espera = ex.tentarNovamenteEmSegundos();
        return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                .header(HttpHeaders.RETRY_AFTER, String.valueOf(espera))
                .body(
                        Erro.comEspera(
                                CodigoDeErro.LIMITE_DE_CONVERSAS,
                                MENSAGEM_LIMITE_EXCEDIDO,
                                espera));
    }
}
