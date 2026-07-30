package br.fatec.memora.autenticacao.infra;

import br.fatec.memora.autenticacao.dominio.CodigoVerificacao;
import br.fatec.memora.autenticacao.dominio.FinalidadeDoCodigo;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Acesso aos códigos de verificação (T014).
 *
 * <p>Usa {@code ix_codigo_canal_finalidade}: toda consulta aqui é por canal
 * <b>e</b> finalidade, porque um código pedido para confirmar posse não pode
 * servir para trocar senha.
 */
public interface RepositorioCodigoVerificacao extends JpaRepository<CodigoVerificacao, UUID> {

    /**
     * O código mais recente de um canal para uma finalidade.
     *
     * <p>Ordena pela criação porque só o último vale — pedir um novo invalida o
     * anterior. Se a pessoa clicou duas vezes em "enviar de novo", é o segundo
     * código que chegou no telefone dela.
     */
    Optional<CodigoVerificacao> findFirstByCanalIdAndFinalidadeOrderByCriadoEmDesc(
            UUID canalId, FinalidadeDoCodigo finalidade);

    List<CodigoVerificacao> findByCanalIdAndFinalidade(
            UUID canalId, FinalidadeDoCodigo finalidade);

    /**
     * Invalida os códigos ainda pendentes de um canal para uma finalidade.
     *
     * <p>Chamado <b>antes</b> de emitir um substituto. Sem isso, dois códigos
     * válidos ao mesmo tempo dobrariam a chance de acerto por força bruta e
     * criariam a confusão de a pessoa digitar o código da mensagem anterior.
     *
     * @return quantos códigos foram invalidados
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            UPDATE CodigoVerificacao c
               SET c.usadoEm = :quando
             WHERE c.canalId = :canalId
               AND c.finalidade = :finalidade
               AND c.usadoEm IS NULL
            """)
    int invalidarPendentes(
            @Param("canalId") UUID canalId,
            @Param("finalidade") FinalidadeDoCodigo finalidade,
            @Param("quando") Instant quando);
}
