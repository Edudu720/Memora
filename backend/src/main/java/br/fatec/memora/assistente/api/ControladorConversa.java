package br.fatec.memora.assistente.api;

import br.fatec.memora.assistente.aplicacao.AutorizadorDeAcao;
import br.fatec.memora.assistente.aplicacao.ServicoDeConversa;
import br.fatec.memora.assistente.infra.AssistenteIndisponivel;
import br.fatec.memora.assistente.infra.ClienteDaAssistente;
import br.fatec.memora.autenticacao.seguranca.PessoaAutenticada;
import br.fatec.memora.comum.CodigoDeErro;
import br.fatec.memora.comum.ContextoDaRequisicao;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.io.IOException;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

/**
 * {@code POST /v1/assistente/conversa} (T033, T034).
 *
 * <h2>Por que transmitir em vez de responder de uma vez</h2>
 *
 * O público do Memora é o que menos tolera tela parada. Ver o texto aparecendo
 * é o que diferencia <i>"está pensando"</i> de <i>"travou"</i> — e quem conclui
 * que travou fecha o aplicativo (SC-007).
 *
 * <h2>A armadilha do ThreadLocal, e por que ela importa aqui</h2>
 *
 * O {@link SseEmitter} responde em <b>outra thread</b>, e
 * {@link ContextoDaRequisicao} é {@code ThreadLocal}. Sem cuidado, a thread da
 * transmissão enxergaria um contexto vazio, e todo evento da trilha sairia
 * <b>sem origem de rede</b> — a auditoria perderia justamente o campo que
 * permite notar rajadas da mesma origem.
 *
 * <p>Pior: {@code ThreadLocal} em pool de threads não fica vazio, fica com o
 * valor de <b>outra</b> requisição. Por isso o contexto é capturado aqui e
 * reinstalado lá dentro, com limpeza no {@code finally}.
 *
 * <h2>Este endpoint nasce autenticado</h2>
 *
 * A última regra da {@code ConfiguracaoDeSegurancaWeb} é
 * {@code anyRequest().authenticated()}, e o {@code FiltroDeTokenDeAcesso}
 * resolve o sujeito <b>no banco</b>. É o que impede o token da sessão-chamariz
 * — assinado por nós, para um UUID que não existe — de abrir uma conversa que
 * custa dinheiro por chamada.
 */
@RestController
@RequestMapping("/v1/assistente")
public class ControladorConversa {

    private static final Logger LOG = LoggerFactory.getLogger(ControladorConversa.class);

    /**
     * Quanto tempo a conexão pode ficar aberta.
     *
     * <p>Generoso de propósito: uma resposta longa, num aparelho em rede ruim,
     * leva mais do que parece. Fechar cedo devolveria à pessoa uma tela cortada
     * no meio de um passo.
     */
    private static final long TIMEOUT_MS = 120_000L;

    private final ServicoDeConversa conversa;
    private final ExecutorService transmissores;

    /** Cria o controlador. */
    public ControladorConversa(ServicoDeConversa conversa) {
        this.conversa = conversa;
        this.transmissores = Executors.newVirtualThreadPerTaskExecutor();
    }

    /** O que o aplicativo envia. */
    public record ConversaRequisicao(
            @JsonProperty("mensagem") @NotBlank @Size(max = 2000) String mensagem,
            @JsonProperty("historico") @Size(max = 40) List<TurnoRequisicao> historico) {}

    /** Um turno do histórico, vindo do aparelho (FR-047). */
    public record TurnoRequisicao(
            @JsonProperty("autor") @NotBlank String autor,
            @JsonProperty("texto") @NotBlank @Size(max = 4000) String texto) {}

    /** Uma ação **já autorizada** pelo catálogo. */
    public record AcaoResposta(
            @JsonProperty("servico_id") UUID servicoId,
            @JsonProperty("nome_exibido") String nomeExibido,
            @JsonProperty("identificador_android") String identificadorAndroid) {}

    /** Um erro, com o texto já pronto para a pessoa. */
    public record ErroResposta(
            @JsonProperty("codigo") String codigo,
            @JsonProperty("mensagem") String mensagem) {}

    /**
     * Conversa um turno, transmitindo a resposta.
     *
     * <p>Erro previsto viaja como <b>evento</b>, e não como status HTTP: a
     * resposta já começou, e não há como trocar o código depois do primeiro
     * byte. O aplicativo trata o evento {@code erro} exibindo o texto que vem
     * nele — que já está na voz da Memora.
     */
    @PostMapping(value = "/conversa", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter conversar(
            @AuthenticationPrincipal PessoaAutenticada pessoa,
            @Valid @RequestBody ConversaRequisicao requisicao) {

        SseEmitter emissor = new SseEmitter(TIMEOUT_MS);

        // Capturado AQUI, na thread da requisição, onde o ThreadLocal ainda
        // tem valor. Ver a nota da classe.
        ContextoDaRequisicao contexto = ContextoDaRequisicao.atual();
        UUID pessoaId = pessoa.id();

        transmissores.execute(() -> transmitir(emissor, contexto, pessoaId, requisicao));
        return emissor;
    }

    private void transmitir(
            SseEmitter emissor,
            ContextoDaRequisicao contexto,
            UUID pessoaId,
            ConversaRequisicao requisicao) {

        ContextoDaRequisicao.instalar(contexto);
        try {
            ServicoDeConversa.Resultado resultado =
                    conversa.conversar(
                            pessoaId,
                            requisicao.mensagem(),
                            turnosDe(requisicao.historico()),
                            trecho -> enviar(emissor, "texto", trecho));

            if (resultado.acao().isPresent()) {
                AutorizadorDeAcao.AcaoAutorizada acao = resultado.acao().get();
                enviar(
                        emissor,
                        "acao",
                        new AcaoResposta(
                                acao.servicoId(),
                                acao.nomeExibido(),
                                acao.identificadorAndroid()));
            }

            enviar(emissor, "fim", "");
            emissor.complete();

        } catch (ServicoDeConversa.LimiteAtingido esgotou) {
            enviar(
                    emissor,
                    "erro",
                    new ErroResposta(
                            CodigoDeErro.LIMITE_DE_CONVERSAS.name(),
                            CodigoDeErro.LIMITE_DE_CONVERSAS.mensagemPadrao()));
            emissor.complete();

        } catch (AssistenteIndisponivel indisponivel) {
            // Falha PREVISTA do provedor: cota do plano gratuito, 5xx, rede, prazo.
            // E esperada no dia a dia, entao vai como WARN sem rastro de pilha. O
            // motivo (so o enum e o status) fica no log; o corpo de erro do
            // Google nem foi lido, e a pessoa recebe a frase da Memora.
            LOG.warn("{}", indisponivel.getMessage());
            enviar(
                    emissor,
                    "erro",
                    new ErroResposta(
                            CodigoDeErro.ASSISTENTE_INDISPONIVEL.name(),
                            CodigoDeErro.ASSISTENTE_INDISPONIVEL.mensagemPadrao()));
            emissor.complete();

        } catch (RuntimeException falha) {
            // O texto da exceção NUNCA vai para a resposta (FR-041): ele pode
            // carregar nome de classe, consulta ou detalhe do provedor. Vai
            // para o log, onde é útil, e a pessoa recebe a frase da Memora.
            LOG.error("falha ao conversar com a assistente", falha);
            enviar(
                    emissor,
                    "erro",
                    new ErroResposta(
                            CodigoDeErro.ERRO_INESPERADO.name(),
                            CodigoDeErro.ERRO_INESPERADO.mensagemPadrao()));
            emissor.complete();

        } finally {
            // Sem isto, a origem desta pessoa reaparece na requisição da
            // seguinte que pegar a mesma thread do pool.
            ContextoDaRequisicao.limpar();
        }
    }

    private void enviar(SseEmitter emissor, String tipo, Object dado) {
        try {
            emissor.send(SseEmitter.event().name(tipo).data(dado));
        } catch (IOException | IllegalStateException fechou) {
            // A pessoa fechou a tela no meio da resposta. É o caso comum, não
            // um defeito: nada a fazer além de parar de escrever.
            LOG.debug("conexao encerrada pelo cliente durante a transmissao");
        }
    }

    /**
     * Traduz o histórico do aparelho.
     *
     * <p>Autor desconhecido vira {@code PESSOA}, e não erro: o histórico é
     * conteúdo, e recusar a conversa inteira por causa de um rótulo estranho
     * deixaria a pessoa sem assistente por um detalhe que ela não controla.
     * Tratar como fala dela também é o lado seguro — conteúdo da pessoa é dado,
     * nunca instrução (FR-034).
     */
    private List<ClienteDaAssistente.Turno> turnosDe(List<TurnoRequisicao> historico) {
        if (historico == null) {
            return List.of();
        }
        return historico.stream()
                .map(
                        turno ->
                                new ClienteDaAssistente.Turno(
                                        "memora".equals(turno.autor().toLowerCase(Locale.ROOT))
                                                ? ClienteDaAssistente.Turno.Autor.MEMORA
                                                : ClienteDaAssistente.Turno.Autor.PESSOA,
                                        turno.texto()))
                .toList();
    }
}
