package br.fatec.memora.assistente.infra;

import br.fatec.memora.assistente.dominio.UsoDaAssistente;
import jakarta.persistence.LockModeType;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/** Acesso ao contador diário do teto de conversas (T010, R7). */
public interface RepositorioUsoDaAssistente
        extends JpaRepository<UsoDaAssistente, UsoDaAssistente.Chave> {

    /** O uso de uma conta em um dia, se já houver. */
    Optional<UsoDaAssistente> findByPessoaIdAndDia(UUID pessoaId, LocalDate dia);

    /**
     * O uso de uma conta em um dia, <b>com a linha travada</b> até o fim da
     * transação: quem chegar depois espera, e lê o estado que o primeiro
     * gravou.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select u from UsoDaAssistente u where u.pessoaId = :pessoaId and u.dia = :dia")
    Optional<UsoDaAssistente> findParaAtualizar(
            @Param("pessoaId") UUID pessoaId, @Param("dia") LocalDate dia);

    /**
     * Garante, de forma atômica, que a linha do dia existe. Dois primeiros usos
     * simultâneos não colidem na chave: o segundo não faz nada. Os valores são
     * os de {@link UsoDaAssistente#primeiroDoDia}.
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query(
            value =
                    """
                    INSERT INTO uso_da_assistente (pessoa_id, dia, conversas, turnos_na_conversa)
                    VALUES (:pessoaId, :dia, 0, 0)
                    ON CONFLICT (pessoa_id, dia) DO NOTHING
                    """,
            nativeQuery = true)
    void garantirLinhaDoDia(@Param("pessoaId") UUID pessoaId, @Param("dia") LocalDate dia);
}
