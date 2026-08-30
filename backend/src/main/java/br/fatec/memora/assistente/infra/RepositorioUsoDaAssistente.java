package br.fatec.memora.assistente.infra;

import br.fatec.memora.assistente.dominio.UsoDaAssistente;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/** Acesso ao contador diário do teto de conversas (T010, R7). */
public interface RepositorioUsoDaAssistente
        extends JpaRepository<UsoDaAssistente, UsoDaAssistente.Chave> {

    /** O uso de uma conta em um dia, se já houver. */
    Optional<UsoDaAssistente> findByPessoaIdAndDia(UUID pessoaId, LocalDate dia);
}
