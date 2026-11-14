package br.fatec.memora.autenticacao.infra;

import br.fatec.memora.autenticacao.dominio.EventoAutenticacao;
import br.fatec.memora.autenticacao.dominio.TipoDeEvento;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Acesso à trilha de auditoria (T014).
 *
 * <p>Herda {@code JpaRepository} pela conveniência de {@code save} e das
 * consultas, mas a tabela é <b>somente inserção</b>: chamar {@code save} sobre
 * um evento já persistido não gera UPDATE, porque a entidade é
 * {@code @Immutable} e o gatilho {@code tg_evento_somente_insercao} recusaria a
 * instrução de qualquer forma.
 */
public interface RepositorioEventoAutenticacao extends JpaRepository<EventoAutenticacao, UUID> {

    /**
     * Histórico de uma conta, do mais recente para o mais antigo.
     *
     * <p>Usa {@code ix_evento_pessoa_ocorrido}.
     */
    List<EventoAutenticacao> findByPessoaIdOrderByOcorridoEmDesc(UUID pessoaId);

    /**
     * Conta eventos de um tipo em uma janela de tempo, para uma conta.
     *
     * <p>Sustenta a decisão de bloqueio progressivo (FR-014): o que importa não
     * é o total histórico de falhas, e sim quantas ocorreram <i>agora</i>.
     */
    long countByPessoaIdAndTipoAndOcorridoEmAfter(
            UUID pessoaId, TipoDeEvento tipo, Instant desde);

    /**
     * Conta eventos de um tipo por origem de rede em uma janela.
     *
     * <p>É a camada de rate limiting que não depende de conta (R4): uma rajada
     * de tentativas contra <i>contas diferentes</i> a partir da mesma origem é
     * invisível para o contador por conta, e é justamente o padrão de quem testa
     * listas de credenciais vazadas.
     */
    long countByOrigemHashAndTipoAndOcorridoEmAfter(
            String origemHash, TipoDeEvento tipo, Instant desde);

    /**
     * Remove todos os eventos vinculados a uma conta que está sendo expurgada
     * por abandono em {@code PENDENTE_VERIFICACAO} (T065b).
     *
     * <p>A constraint {@code fk_evento_pessoa} não possui {@code ON DELETE CASCADE}
     * e o gatilho {@code tg_evento_somente_insercao} bloqueia apenas {@code UPDATE},
     * permitindo {@code DELETE} explícito durante o expurgo de conta nunca ativada.
     */
    @Modifying
    @Query("DELETE FROM EventoAutenticacao e WHERE e.pessoaId = :pessoaId")
    void deletarPorPessoaId(@Param("pessoaId") UUID pessoaId);
}
