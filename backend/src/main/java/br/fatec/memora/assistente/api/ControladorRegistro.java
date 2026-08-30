package br.fatec.memora.assistente.api;

import br.fatec.memora.assistente.aplicacao.ServicoDeRegistro;
import br.fatec.memora.autenticacao.seguranca.PessoaAutenticada;
import br.fatec.memora.comum.CodigoDeErro;
import br.fatec.memora.comum.FalhaDoMemora;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * {@code POST /v1/assistente/acao} e {@code GET /v1/assistente/registro}
 * (T050, T058).
 *
 * <h2>O servidor reconfere, mesmo já tendo autorizado</h2>
 *
 * A ação chegou aqui porque o {@code AutorizadorDeAcao} a liberou durante a
 * conversa. Ainda assim, o serviço consulta o catálogo <b>de novo</b> antes de
 * gravar.
 *
 * <p>Não é desconfiança do próprio código: entre a autorização e o registro
 * passou tempo, e quem envia este pedido é o aplicativo. Um serviço pode ter
 * sido desativado nesse intervalo — e um pedido forjado, com o identificador de
 * um serviço sensível, precisa encontrar a mesma recusa que encontraria na
 * conversa.
 *
 * <h2>O texto é truncado no servidor</h2>
 *
 * {@code pedido_resumido} entra numa tabela imutável de 120 caracteres. Confiar
 * o corte a quem controla o cliente transformaria esse campo em texto livre de
 * tamanho arbitrário.
 */
@RestController
@RequestMapping("/v1/assistente")
public class ControladorRegistro {

    private final ServicoDeRegistro registro;

    /** Cria o controlador. */
    public ControladorRegistro(ServicoDeRegistro registro) {
        this.registro = registro;
    }

    /** O que o aplicativo envia depois de abrir. */
    public record AcaoRequisicao(
            @JsonProperty("servico_id") @NotNull UUID servicoId,
            @JsonProperty("pedido_resumido") @Size(max = 2000) String pedidoResumido) {}

    /** Uma ação executada, como a pessoa a vê. */
    public record AcaoRegistradaResposta(
            @JsonProperty("nome_exibido") String nomeExibido,
            @JsonProperty("pedido_resumido") String pedidoResumido,
            @JsonProperty("ocorrido_em") Instant ocorridoEm) {}

    /** O registro devolvido. */
    public record RegistroResposta(
            @JsonProperty("acoes") List<AcaoRegistradaResposta> acoes) {}

    /**
     * Registra que a pessoa confirmou e o aplicativo foi aberto (FR-020).
     *
     * <p>Recusa serviço desconhecido, inativo ou sensível — e a recusa também
     * vira trilha, como {@code ACAO_RECUSADA}. Se um pedido desses chegou até
     * aqui, algo está errado, e o registro disso vale mais que a recusa
     * silenciosa.
     *
     * <p>O texto da recusa não acusa a pessoa: quem tocou no botão fez tudo
     * certo, e um problema de registro não pode virar culpa dela.
     */
    @PostMapping("/acao")
    @ResponseStatus(HttpStatus.CREATED)
    public void registrar(
            @AuthenticationPrincipal PessoaAutenticada pessoa,
            @Valid @RequestBody AcaoRequisicao requisicao) {

        boolean gravou =
                registro.registrarExecucao(
                        pessoa.id(), requisicao.servicoId(), requisicao.pedidoResumido());

        if (!gravou) {
            throw FalhaDoMemora.de(
                    CodigoDeErro.DADOS_INVALIDOS,
                    "Não consegui anotar o que acabamos de fazer. Não se "
                            + "preocupe — o que importa é que deu certo 😊");
        }
    }

    /**
     * O que a Memora fez em nome da pessoa (FR-023).
     *
     * <p>Só ação executada. Orientação apenas ensinada <b>não</b> aparece
     * (FR-025): quem fez foi a própria pessoa, e listar isso como "o que a
     * Memora fez" tiraria dela o crédito que a US2 trabalhou para dar.
     */
    @GetMapping("/registro")
    public RegistroResposta listar(@AuthenticationPrincipal PessoaAutenticada pessoa) {
        return new RegistroResposta(
                registro.doQueAconteceu(pessoa.id()).stream().map(this::corpoDe).toList());
    }

    private AcaoRegistradaResposta corpoDe(ServicoDeRegistro.AcaoComNome acao) {
        return new AcaoRegistradaResposta(
                acao.nomeExibido(),
                acao.evento().getPedidoResumido().orElse(""),
                acao.evento().getOcorridoEm());
    }
}
