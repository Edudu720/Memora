package br.fatec.memora.assistente.infra;

import br.fatec.memora.assistente.dominio.EventoDaAssistente;
import br.fatec.memora.assistente.dominio.TipoDeEventoDaAssistente;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Acesso à trilha da assistente (T010).
 *
 * <p>Como {@code RepositorioEventoAutenticacao}, herda {@code JpaRepository}
 * pela conveniência — mas a tabela é <b>somente inserção</b>, e o gatilho
 * {@code tg_evento_assistente_somente_insercao} recusa UPDATE no banco.
 */
public interface RepositorioEventoDaAssistente extends JpaRepository<EventoDaAssistente, UUID> {

    /**
     * O que a assistente fez por uma pessoa, do mais recente ao mais antigo.
     *
     * <p>É o que a FR-023 mostra a ela. Usa {@code ix_evento_assistente_pessoa}.
     */
    List<EventoDaAssistente> findByPessoaIdAndTipoOrderByOcorridoEmDesc(
            UUID pessoaId, TipoDeEventoDaAssistente tipo);

    /**
     * Conta eventos de um tipo numa janela, para uma conta.
     *
     * <p>Serve para notar insistência: uma sequência de {@code ACAO_RECUSADA} é
     * o sinal de que alguém está tentando fazer a assistente abrir o que ela
     * não abre.
     */
    long countByPessoaIdAndTipoAndOcorridoEmAfter(
            UUID pessoaId, TipoDeEventoDaAssistente tipo, Instant desde);
}
