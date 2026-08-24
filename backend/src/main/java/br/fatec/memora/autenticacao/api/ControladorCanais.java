package br.fatec.memora.autenticacao.api;

import br.fatec.memora.autenticacao.aplicacao.ServicoDeVerificacaoDeCanal;
import br.fatec.memora.autenticacao.dominio.CanalContato;
import br.fatec.memora.autenticacao.dominio.MascaradorDeCanal;
import br.fatec.memora.autenticacao.infra.RepositorioCanalContato;
import br.fatec.memora.autenticacao.seguranca.PessoaAutenticada;
import br.fatec.memora.comum.CodigoDeErro;
import br.fatec.memora.comum.FalhaDoMemora;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import java.util.Locale;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * {@code POST /v1/canais/{id}/codigo} e {@code POST /v1/canais/{id}/verificar}
 * (T058).
 *
 * <h2>Os dois primeiros endpoints autenticados do Memora</h2>
 *
 * Até aqui, tudo era público: cadastro, entrada e renovação produzem credencial
 * e por isso não podem exigir uma. Estes dois exigem, e quem resolve o token em
 * identidade é o {@code FiltroDeTokenDeAcesso} — que <b>consulta o banco</b> em
 * vez de confiar na assinatura, porque existe token nosso, perfeitamente
 * assinado, cuja conta não existe. Ver a sessão-chamariz em
 * {@code ServicoDeCadastro}.
 *
 * <p>Consequência prática: quem tentar cadastrar com o e-mail de outra pessoa
 * recebe {@code 201} com um token que <b>não</b> abre estes endpoints. A
 * resposta que ele recebe aqui é a mesma de um token vencido.
 *
 * <h2>O identificador do canal vem da URL, e a URL não é confiável</h2>
 *
 * Nenhum dos dois métodos confia no {@code canalId} recebido. Quem confere se
 * aquele canal pertence a quem está pedindo é o serviço, e canal alheio sai pelo
 * mesmo caminho de canal inexistente.
 */
@RestController
@RequestMapping("/v1/canais")
public class ControladorCanais {

    private final ServicoDeVerificacaoDeCanal verificacao;
    private final RepositorioCanalContato canais;

    public ControladorCanais(
            ServicoDeVerificacaoDeCanal verificacao, RepositorioCanalContato canais) {
        this.verificacao = verificacao;
        this.canais = canais;
    }

    /** O que o aplicativo envia para confirmar posse. */
    public record VerificarRequisicao(
            @JsonProperty("codigo") @NotBlank @Pattern(regexp = "^[0-9]{6}$") String codigo) {}

    /**
     * Envia o código de verificação.
     *
     * <p>Responde {@code 202} <b>sempre</b>, e o serviço decide em silêncio se
     * havia o que enviar. O contrato diz "código enviado, se o canal for
     * elegível" exatamente para permitir isso: distinguir canal inexistente de
     * canal alheio devolveria a quem perguntasse um mapa dos identificadores
     * que existem.
     */
    @PostMapping("/{canalId}/codigo")
    public ResponseEntity<Void> enviarCodigo(
            @AuthenticationPrincipal PessoaAutenticada pessoa, @PathVariable UUID canalId) {

        verificacao.solicitarCodigo(pessoa.id(), canalId);
        return ResponseEntity.accepted().build();
    }

    /**
     * Confere o código e devolve o canal já verificado.
     *
     * <p>A recusa é uma só, com o texto de {@link CodigoDeErro#DADOS_INVALIDOS}:
     * código errado, vencido, já usado e canal que não é seu dizem a mesma
     * coisa. Separá-los contaria a quem está tentando adivinhar em que ponto
     * ele errou.
     */
    @PostMapping("/{canalId}/verificar")
    public DtosDeAutenticacao.CanalResposta verificar(
            @AuthenticationPrincipal PessoaAutenticada pessoa,
            @PathVariable UUID canalId,
            @Valid @RequestBody VerificarRequisicao requisicao) {

        ServicoDeVerificacaoDeCanal.Resultado resultado =
                verificacao.verificar(pessoa.id(), canalId, requisicao.codigo());

        if (resultado == ServicoDeVerificacaoDeCanal.Resultado.RECUSADO) {
            throw FalhaDoMemora.de(
                    CodigoDeErro.DADOS_INVALIDOS,
                    "Esse código não conferiu. Ele vale por 10 minutinhos — "
                            + "se já passou, posso te enviar outro 😊");
        }

        return corpoDe(
                canais.findById(canalId)
                        .orElseThrow(() -> new IllegalStateException("canal verificado sumiu")));
    }

    /** O canal como ele sai: mascarado, sempre. */
    private DtosDeAutenticacao.CanalResposta corpoDe(CanalContato canal) {
        return new DtosDeAutenticacao.CanalResposta(
                canal.getId(),
                canal.getTipo().name().toLowerCase(Locale.ROOT),
                MascaradorDeCanal.mascarar(canal.getTipo(), canal.getValor()),
                canal.isVerificado(),
                canal.isPrincipal());
    }
}
