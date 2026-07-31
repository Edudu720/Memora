package br.fatec.memora.comum;

import br.fatec.memora.autenticacao.dominio.EventoAutenticacao;
import br.fatec.memora.autenticacao.dominio.ResultadoDoEvento;
import br.fatec.memora.autenticacao.dominio.TipoDeEvento;
import br.fatec.memora.autenticacao.infra.RepositorioEventoAutenticacao;
import java.time.Instant;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Escreve a trilha de auditoria da autenticação (T025, FR-039 e FR-040).
 *
 * <p>Ponto único de escrita em {@code evento_autenticacao}. Existe para que a
 * regra "nenhum dado sensível na trilha" tenha um lugar só onde ser verificada,
 * em vez de depender de cada chamador lembrar dela.
 *
 * <h2>A assinatura é a garantia da FR-040</h2>
 *
 * Nenhum método daqui aceita senha, código, token ou valor de canal. Não é
 * convenção documentada — é que <b>não existe parâmetro onde passar</b>. O que
 * entra é: qual conta (ou nenhuma), o que aconteceu, se deu certo, e quando. A
 * origem de rede o serviço busca sozinho do {@link ContextoDaRequisicao}, já
 * resumida pelo {@link FiltroRastreio}, e o endereço em claro nunca chega até
 * aqui.
 *
 * <h2>Duas formas de gravar, e a diferença importa</h2>
 *
 * <p>Um evento de <b>recusa</b> costuma nascer numa operação que vai falhar. Se
 * ele participar da mesma transação, o rollback leva o registro junto — e a
 * trilha fica cega justamente para tentativa malsucedida, que é o que ela existe
 * para enxergar. Daí {@link #registrarMesmoComRollback}, em transação própria.
 *
 * <p>Um evento de <b>sucesso</b> não pode fazer isso. O evento de cadastro
 * aponta para uma conta criada na transação em curso e ainda não confirmada:
 * gravá-lo em transação separada quebraria a chave estrangeira
 * {@code fk_evento_pessoa}, porque a conta ainda não existe para quem olha de
 * fora. Por isso {@link #registrar} participa da transação do chamador — e se a
 * operação for desfeita, o registro do sucesso que não aconteceu vai junto, que
 * é o correto.
 *
 * <h2>Falha ao auditar derruba a operação</h2>
 *
 * Nada aqui engole exceção. Pelo Princípio I, uma entrada que o sistema não
 * conseguiu registrar não deve ser concedida em silêncio: preferimos recusar a
 * operação a mantê-la sem rastro.
 */
@Service
public class RegistroDeAuditoria {

    private final RepositorioEventoAutenticacao eventos;

    public RegistroDeAuditoria(RepositorioEventoAutenticacao eventos) {
        this.eventos = eventos;
    }

    /**
     * Registra um evento ligado a uma conta, dentro da transação em curso.
     *
     * @param pessoaId conta envolvida; obrigatória
     * @param agora recebido de fora, e não lido do relógio aqui dentro, para
     *     que o instante do evento seja o mesmo do resto da operação
     */
    @Transactional
    public EventoAutenticacao registrar(
            UUID pessoaId, TipoDeEvento tipo, ResultadoDoEvento resultado, Instant agora) {
        return eventos.save(
                EventoAutenticacao.de(pessoaId, tipo, resultado, origemAtual(), agora));
    }

    /**
     * Registra um evento <b>sem conta associada</b>, dentro da transação em
     * curso.
     *
     * <p>É o caso da tentativa contra identificador que não existe: precisa
     * aparecer na trilha, e não há id a informar — inventar um revelaria, pela
     * própria existência do registro, que aquela conta não existe.
     */
    @Transactional
    public EventoAutenticacao registrarSemConta(
            TipoDeEvento tipo, ResultadoDoEvento resultado, Instant agora) {
        return eventos.save(
                EventoAutenticacao.semConta(tipo, resultado, origemAtual(), agora));
    }

    /**
     * Registra em <b>transação própria</b>, para que o registro sobreviva ao
     * rollback da operação que o originou.
     *
     * <p>Para eventos de recusa: {@code FALHA_ENTRADA}, {@code BLOQUEIO},
     * {@code REUSO_TOKEN_DETECTADO}.
     *
     * <p><b>Não use para evento de sucesso que aponte para linha criada na
     * transação do chamador</b> — a chave estrangeira não a enxerga ainda. Ver a
     * explicação no cabeçalho desta classe.
     *
     * @param pessoaId conta envolvida, ou {@code null} quando não existe conta
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public EventoAutenticacao registrarMesmoComRollback(
            UUID pessoaId, TipoDeEvento tipo, ResultadoDoEvento resultado, Instant agora) {
        String origem = origemAtual();
        EventoAutenticacao evento =
                pessoaId == null
                        ? EventoAutenticacao.semConta(tipo, resultado, origem, agora)
                        : EventoAutenticacao.de(pessoaId, tipo, resultado, origem, agora);

        return eventos.save(evento);
    }

    /**
     * Origem de rede da requisição em curso, já resumida.
     *
     * <p>Nulo fora de uma requisição HTTP — tarefa agendada ou teste de unidade.
     * O evento é gravado do mesmo jeito: perder a origem é aceitável, perder o
     * evento não.
     */
    private String origemAtual() {
        return ContextoDaRequisicao.atual().origemHash();
    }
}
