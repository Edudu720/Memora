package br.fatec.memora.autenticacao.api;

import br.fatec.memora.autenticacao.api.DtosDeCadastro.CadastroRequisicao;
import br.fatec.memora.autenticacao.api.DtosDeCadastro.CanalResposta;
import br.fatec.memora.autenticacao.api.DtosDeCadastro.PessoaResposta;
import br.fatec.memora.autenticacao.api.DtosDeCadastro.SessaoResposta;
import br.fatec.memora.autenticacao.aplicacao.ServicoDeCadastro;
import br.fatec.memora.autenticacao.dominio.MascaradorDeCanal;
import br.fatec.memora.autenticacao.dominio.TipoDeCanal;
import br.fatec.memora.comum.CodigoDeErro;
import br.fatec.memora.comum.FalhaDoMemora;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Locale;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * {@code POST /v1/auth/cadastro} (T033).
 *
 * <h2>O que esta classe faz, e o que ela não faz</h2>
 *
 * Ela traduz: JSON do contrato para argumentos de domínio na entrada, e o
 * resultado do serviço para o corpo do contrato na saída. <b>Nenhuma decisão de
 * negócio mora aqui</b> — inclusive a de não revelar conta existente, que está
 * em {@code ServicoDeCadastro} justamente porque precisa valer para qualquer
 * chamador, não só para este.
 *
 * <p>A consequência prática é que o método abaixo não tem ramificação nenhuma
 * entre o caminho real e o caminho chamariz. Se tivesse, seria por onde a
 * diferença vazaria.
 */
@RestController
@RequestMapping("/v1/auth")
public class ControladorCadastro {

    private final ServicoDeCadastro cadastro;

    public ControladorCadastro(ServicoDeCadastro cadastro) {
        this.cadastro = cadastro;
    }

    @PostMapping("/cadastro")
    public ResponseEntity<SessaoResposta> cadastrar(
            @Valid @RequestBody CadastroRequisicao requisicao) {

        TipoDeCanal tipo = tipoDoContrato(requisicao.canal().tipo());

        ServicoDeCadastro.Cadastrada resultado =
                cadastro.cadastrar(
                        requisicao.nomeTratamento().trim(),
                        tipo,
                        requisicao.canal().valor(),
                        requisicao.senha(),
                        requisicao.aparelhoDescricao());

        return ResponseEntity.status(HttpStatus.CREATED).body(corpoDe(resultado));
    }

    /**
     * {@code email}/{@code telefone} do contrato para a constante do domínio.
     *
     * <p>Valor fora do enum vira {@code DADOS_INVALIDOS}, e não erro inesperado:
     * é dado que chegou errado, não defeito nosso.
     */
    private TipoDeCanal tipoDoContrato(String tipo) {
        try {
            return TipoDeCanal.valueOf(tipo.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException naoExiste) {
            throw FalhaDoMemora.de(CodigoDeErro.DADOS_INVALIDOS);
        }
    }

    /**
     * Monta o corpo da resposta.
     *
     * <p>O canal sai sempre com {@code verificado = false}: o cadastro cria o
     * canal sem posse confirmada, e o chamariz não tem canal nenhum. Que os dois
     * digam a mesma coisa é requisito, não coincidência.
     */
    private SessaoResposta corpoDe(ServicoDeCadastro.Cadastrada resultado) {
        CanalResposta canal =
                new CanalResposta(
                        resultado.canalId(),
                        resultado.tipoDoCanal().name().toLowerCase(Locale.ROOT),
                        MascaradorDeCanal.mascarar(
                                resultado.tipoDoCanal(), resultado.valorNormalizado()),
                        false,
                        true);

        PessoaResposta pessoa =
                new PessoaResposta(
                        resultado.pessoaId(),
                        resultado.nomeTratamento(),
                        List.of(canal),
                        true);

        return new SessaoResposta(
                resultado.tokenAcesso(),
                resultado.refreshToken(),
                resultado.expiraEmSegundos(),
                pessoa);
    }
}
