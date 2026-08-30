package br.fatec.memora.assistente.aplicacao;

import br.fatec.memora.assistente.dominio.EventoDaAssistente;
import br.fatec.memora.assistente.dominio.ServicoConhecido;
import br.fatec.memora.assistente.dominio.TipoDeEventoDaAssistente;
import br.fatec.memora.assistente.infra.RepositorioEventoDaAssistente;
import br.fatec.memora.assistente.infra.RepositorioServicoConhecido;
import br.fatec.memora.comum.ContextoDaRequisicao;
import java.time.Clock;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Escreve e lê a trilha do que a assistente fez (T050, T058).
 *
 * <h2>Duas leituras do mesmo registro</h2>
 *
 * A FR-020 quer a trilha para auditoria; a FR-023 quer que a <b>pessoa</b> a
 * veja. É o mesmo dado, e a segunda exigência é a que dá sentido à primeira:
 * um log que só a equipe lê serve à equipe, e quem precisa poder desconfiar do
 * que foi feito em seu nome é ela.
 */
@Service
public class ServicoDeRegistro {

    private final RepositorioEventoDaAssistente eventos;
    private final RepositorioServicoConhecido servicos;
    private final Clock relogio;

    /** Cria o serviço. */
    public ServicoDeRegistro(
            RepositorioEventoDaAssistente eventos,
            RepositorioServicoConhecido servicos,
            Clock relogio) {
        this.eventos = eventos;
        this.servicos = servicos;
        this.relogio = relogio;
    }

    /**
     * Registra que um aplicativo foi aberto.
     *
     * <p>Reconfere a autorização antes de gravar. Pedido para serviço que não
     * pode ser aberto vira {@code ACAO_RECUSADA} — e essa gravação é o ponto:
     * se um pedido desses chegou aqui, alguém está tentando algo, e uma recusa
     * silenciosa perderia exatamente o sinal que importa.
     *
     * @return {@code true} quando a execução foi registrada; {@code false}
     *     quando o serviço não podia ser aberto
     */
    @Transactional
    public boolean registrarExecucao(UUID pessoaId, UUID servicoId, String pedidoResumido) {
        Optional<ServicoConhecido> servico = servicos.findByIdAndAtivoTrue(servicoId);

        if (servico.isEmpty() || !servico.get().podeSerAberto()) {
            eventos.save(
                    EventoDaAssistente.semServico(
                            pessoaId,
                            TipoDeEventoDaAssistente.ACAO_RECUSADA,
                            pedidoResumido,
                            origem(),
                            agora()));
            return false;
        }

        eventos.save(
                EventoDaAssistente.sobreServico(
                        pessoaId,
                        TipoDeEventoDaAssistente.ACAO_EXECUTADA,
                        servicoId,
                        pedidoResumido,
                        origem(),
                        agora()));
        return true;
    }

    /**
     * O que a assistente executou por uma pessoa, do mais recente ao mais
     * antigo.
     *
     * <p>Filtra por {@code ACAO_EXECUTADA}, e só. Recusas e conversas iniciadas
     * ficam na trilha para nós, e não entram na lista que a pessoa vê: mostrar
     * a ela uma recusa que ela nem soube que aconteceu criaria um susto sem
     * nada a fazer a respeito.
     */
    @Transactional(readOnly = true)
    public List<AcaoComNome> doQueAconteceu(UUID pessoaId) {
        return eventos
                .findByPessoaIdAndTipoOrderByOcorridoEmDesc(
                        pessoaId, TipoDeEventoDaAssistente.ACAO_EXECUTADA)
                .stream()
                .map(this::comNome)
                .toList();
    }

    /**
     * Junta o evento ao nome do serviço.
     *
     * <p>O nome não é copiado para a trilha de propósito: ele muda — um
     * aplicativo é renomeado, a descrição melhora — e a trilha é imutável.
     * Guardar o nome ali congelaria uma informação que deve acompanhar o
     * catálogo.
     */
    private AcaoComNome comNome(EventoDaAssistente evento) {
        String nome =
                evento.getServicoId()
                        .flatMap(servicos::findById)
                        .map(ServicoConhecido::getNomeExibido)
                        // O serviço pode ter sido apagado depois. A ação
                        // aconteceu, e some da lista seria pior que um rótulo
                        // genérico.
                        .orElse("Um aplicativo");
        return new AcaoComNome(evento, nome);
    }

    private String origem() {
        return ContextoDaRequisicao.atual().origemHash();
    }

    private Instant agora() {
        return Instant.now(relogio);
    }

    /** Um evento da trilha com o nome do serviço resolvido. */
    public record AcaoComNome(EventoDaAssistente evento, String nomeExibido) {}
}
