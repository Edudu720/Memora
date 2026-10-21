package br.fatec.memora.assistente.aplicacao;

import br.fatec.memora.assistente.dominio.EventoDaAssistente;
import br.fatec.memora.assistente.dominio.ServicoConhecido;
import br.fatec.memora.assistente.dominio.TipoDeEventoDaAssistente;
import br.fatec.memora.assistente.infra.ClienteDaAssistente;
import br.fatec.memora.assistente.infra.PersonaDaMemora;
import br.fatec.memora.assistente.infra.RepositorioEventoDaAssistente;
import br.fatec.memora.assistente.infra.RepositorioServicoConhecido;
import br.fatec.memora.assistente.seguranca.LimitePorConta;
import br.fatec.memora.comum.ContextoDaRequisicao;
import java.time.Clock;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Consumer;
import org.springframework.stereotype.Service;

/**
 * Conduz um turno de conversa (T032).
 *
 * <h2>A ordem das operações é a segurança</h2>
 *
 * <ol>
 *   <li>o limite diário é verificado <b>antes</b> de qualquer coisa;
 *   <li>a conversa é contada <b>antes</b> de falar com o provedor — contar só o
 *       que deu certo permitiria gastar a cota inteira em chamadas que falham
 *       no fim, que é o que um atacante faria;
 *   <li>a persona e o catálogo são montados <b>aqui</b>, e não vêm do
 *       aparelho (FR-034);
 *   <li>a resposta do modelo passa pelo {@link AutorizadorDeAcao} — e é só
 *       nesse ponto que uma sugestão pode virar ação.
 * </ol>
 *
 * <h2>Nada de conversa é gravado</h2>
 *
 * O histórico chega do aparelho, é usado para montar o pedido e é descartado
 * (FR-047). A única coisa que sobra no banco é a contagem e, quando há ação, um
 * evento sem o texto da conversa.
 *
 * <p>O preço está declarado na R3 do research: o histórico viaja a cada turno,
 * então o custo de uma conversa cresce com o número de turnos.
 */
@Service
public class ServicoDeConversa {

    /**
     * Teto de <b>turnos</b> que viajam num pedido (FR-056).
     *
     * <p>Um turno é uma <b>troca</b>: a mensagem da pessoa e a resposta da
     * Memora (data-model.md, "Turno — a unidade de conta"). Protege duas coisas
     * ao mesmo tempo: o custo, que cresce com o histórico (R3), e o contexto do
     * modelo. Conversa mais longa que isto segue funcionando — o que se perde
     * são os turnos mais antigos, que é exatamente o que uma pessoa esqueceria
     * também.
     */
    public static final int TURNOS_NO_PEDIDO = 20;

    /**
     * Teto de <b>mensagens</b> do {@code historico}: dois por turno (FR-056).
     *
     * <p>É também o {@code maxItems} do contrato, e o controlador valida com
     * esta mesma constante para os dois números não divergirem.
     */
    public static final int MENSAGENS_NO_PEDIDO = 2 * TURNOS_NO_PEDIDO;

    private final ClienteDaAssistente assistente;
    private final PersonaDaMemora persona;
    private final RepositorioServicoConhecido servicos;
    private final RepositorioEventoDaAssistente eventos;
    private final AutorizadorDeAcao autorizador;
    private final LimitePorConta limite;
    private final Clock relogio;

    /** Cria o serviço. */
    public ServicoDeConversa(
            ClienteDaAssistente assistente,
            PersonaDaMemora persona,
            RepositorioServicoConhecido servicos,
            RepositorioEventoDaAssistente eventos,
            AutorizadorDeAcao autorizador,
            LimitePorConta limite,
            Clock relogio) {
        this.assistente = assistente;
        this.persona = persona;
        this.servicos = servicos;
        this.eventos = eventos;
        this.autorizador = autorizador;
        this.limite = limite;
        this.relogio = relogio;
    }

    /**
     * Conversa um turno.
     *
     * @param aoReceberTrecho chamado a cada pedaço de texto, para o streaming
     * @return o texto completo e a ação, se alguma foi autorizada
     * @throws LimiteAtingido quando a cota diária acabou
     */
    public Resultado conversar(
            UUID pessoaId,
            String mensagem,
            List<ClienteDaAssistente.Turno> historico,
            Consumer<String> aoReceberTrecho) {

        // Um turno não é uma conversa (FR-053): só o que abre conversa nova conta
        // no teto, e só ele vira CONVERSA_INICIADA na trilha.
        switch (limite.registrarTurno(pessoaId)) {
            case TETO_ATINGIDO -> {
                registrar(pessoaId, TipoDeEventoDaAssistente.LIMITE_ATINGIDO, null, null);
                throw new LimiteAtingido();
            }
            case NOVA_CONVERSA ->
                    registrar(pessoaId, TipoDeEventoDaAssistente.CONVERSA_INICIADA, null, null);
            case CONTINUA -> {
                // a conversa em curso segue, sem contar de novo
            }
        }

        List<ServicoConhecido> catalogo = servicos.findByAtivoTrueOrderByNomeExibido();

        ClienteDaAssistente.Resposta resposta =
                assistente.conversar(
                        new ClienteDaAssistente.Pedido(
                                PersonaDaMemora.INSTRUCAO,
                                persona.catalogoPara(catalogo),
                                ultimosTurnos(historico),
                                mensagem),
                        aoReceberTrecho);

        // O PONTO DA FEATURE: a resposta do modelo passa por uma porta que ele
        // não controla. Sugestão que não estiver no catálogo morre aqui.
        Optional<AutorizadorDeAcao.AcaoAutorizada> acao =
                autorizador.autorizar(resposta.sugestao());

        // Sugestão recusada vira trilha. Silenciosa para a pessoa — dizer "a
        // Memora tentou abrir seu banco e eu impedi" assustaria quem não fez
        // nada de errado —, e nada silenciosa para nós: uma sequência destes
        // eventos é o sinal de que alguém está tentando.
        if (resposta.sugestao().isPresent() && acao.isEmpty()) {
            registrar(pessoaId, TipoDeEventoDaAssistente.ACAO_RECUSADA, null, mensagem);
        }

        return new Resultado(resposta.texto(), acao);
    }

    /**
     * As mensagens dos {@value #TURNOS_NO_PEDIDO} turnos mais recentes — as
     * últimas {@value #MENSAGENS_NO_PEDIDO} (FR-056).
     *
     * <p>Corta pelo <b>fim</b>: numa conversa longa, o que importa para o
     * próximo passo é o que acabou de ser dito. O aparelho já manda só estas;
     * o corte aqui é defesa, e conta em mensagens porque o {@code historico} é
     * uma lista de mensagens, não de trocas.
     */
    private List<ClienteDaAssistente.Turno> ultimosTurnos(
            List<ClienteDaAssistente.Turno> historico) {
        if (historico == null || historico.isEmpty()) {
            return List.of();
        }
        int inicio = Math.max(0, historico.size() - MENSAGENS_NO_PEDIDO);
        return List.copyOf(historico.subList(inicio, historico.size()));
    }

    private void registrar(
            UUID pessoaId, TipoDeEventoDaAssistente tipo, UUID servicoId, String pedido) {
        EventoDaAssistente evento =
                servicoId == null
                        ? EventoDaAssistente.semServico(
                                pessoaId,
                                tipo,
                                pedido,
                                ContextoDaRequisicao.atual().origemHash(),
                                agora())
                        : EventoDaAssistente.sobreServico(
                                pessoaId,
                                tipo,
                                servicoId,
                                pedido,
                                ContextoDaRequisicao.atual().origemHash(),
                                agora());
        eventos.save(evento);
    }

    private Instant agora() {
        return Instant.now(relogio);
    }

    /** O que a assistente respondeu, já com a autorização resolvida. */
    public record Resultado(
            String texto, Optional<AutorizadorDeAcao.AcaoAutorizada> acao) {}

    /** A cota diária de conversas acabou (R7). */
    public static class LimiteAtingido extends RuntimeException {

        /** Cria a falha. */
        public LimiteAtingido() {
            super("limite diario de conversas atingido");
        }
    }
}
