package br.fatec.memora.autenticacao.infra;

import br.fatec.memora.autenticacao.dominio.PessoaUsuaria;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

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
}
