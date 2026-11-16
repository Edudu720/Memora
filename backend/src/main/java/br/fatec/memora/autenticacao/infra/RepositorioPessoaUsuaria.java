package br.fatec.memora.autenticacao.infra;

import br.fatec.memora.autenticacao.dominio.EstadoDaConta;
import br.fatec.memora.autenticacao.dominio.PessoaUsuaria;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Acesso às contas (T014).
 *
 * <p>Não existe consulta por identificador de login aqui de propósito. O login
 * localiza a pessoa pelo <b>canal de contato</b>, através de
 * {@link RepositorioCanalContato#findByValorHash(String)} — porque a mesma
 * conta pode ter e-mail e telefone, e a FR-051 aceita qualquer canal verificado.
 * Procurar a pessoa direto exigiria duplicar o identificador nesta tabela.
 */
public interface RepositorioPessoaUsuaria extends JpaRepository<PessoaUsuaria, UUID> {

    /**
     * Busca contas em determinado estado criadas antes do instante limite (T065b).
     */
    @Query("SELECT p FROM PessoaUsuaria p WHERE p.estado = :estado AND p.criadaEm < :limite")
    List<PessoaUsuaria> buscarContasPorEstadoAnterioresA(
            @Param("estado") EstadoDaConta estado, @Param("limite") Instant limite);
}
