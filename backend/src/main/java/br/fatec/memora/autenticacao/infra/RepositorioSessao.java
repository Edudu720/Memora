package br.fatec.memora.autenticacao.infra;

import br.fatec.memora.autenticacao.dominio.Sessao;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Acesso às sessões (T014).
 *
 * <p>As duas consultas centrais são a busca pelo hash do refresh token, que
 * roda a cada renovação, e a revogação por família, que é a resposta à detecção
 * de reuso.
 */
public interface RepositorioSessao extends JpaRepository<Sessao, UUID> {

    /**
     * Localiza a sessão pelo hash do refresh token apresentado.
     *
     * <p>Usa {@code uq_sessao_refresh_token_hash}. Se a sessão encontrada já
     * tiver {@code substituidaPor} preenchido, o token é um reuso — e a resposta
     * é revogar a família inteira (R2).
     */
    Optional<Sessao> findByRefreshTokenHash(String refreshTokenHash);

    /** Toda a cadeia de rotações. Usa {@code ix_sessao_familia}. */
    List<Sessao> findByFamiliaId(UUID familiaId);

    /** Sessões de uma conta. Usa {@code ix_sessao_pessoa}. */
    List<Sessao> findByPessoaId(UUID pessoaId);

    /**
     * Revoga de uma vez todas as sessões ainda ativas de uma família.
     *
     * <p>É a reação à detecção de reuso de token (R2). Feito como atualização
     * em massa e não carregando as entidades porque precisa ser <b>uma</b>
     * instrução: buscar, decidir e gravar uma por uma abriria janela para a
     * requisição concorrente do atacante passar no meio.
     *
     * <p>Exige transação de quem chama, e a atualização não passa pelo contexto
     * de persistência — entidade já carregada na mesma transação fica
     * desatualizada.
     *
     * @return quantas sessões foram revogadas
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            UPDATE Sessao s
               SET s.revogadaEm = :quando
             WHERE s.familiaId = :familiaId
               AND s.revogadaEm IS NULL
            """)
    int revogarFamilia(@Param("familiaId") UUID familiaId, @Param("quando") Instant quando);

    /**
     * Revoga todas as sessões ativas de uma conta.
     *
     * <p>É o que a troca de senha exige (FR-021): quem trocou a senha porque
     * suspeitou de invasão precisa que o invasor caia fora de todos os
     * aparelhos, não só do atual.
     *
     * @return quantas sessões foram revogadas
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            UPDATE Sessao s
               SET s.revogadaEm = :quando
             WHERE s.pessoaId = :pessoaId
               AND s.revogadaEm IS NULL
            """)
    int revogarSessoesDaPessoa(@Param("pessoaId") UUID pessoaId, @Param("quando") Instant quando);
}
