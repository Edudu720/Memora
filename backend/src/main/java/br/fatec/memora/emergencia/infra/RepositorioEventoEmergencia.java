package br.fatec.memora.emergencia.infra;

import br.fatec.memora.emergencia.dominio.EventoEmergencia;
import java.time.Instant;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

/**
 * Repositório JPA dos eventos de emergência SOS (Feature 014).
 */
public interface RepositorioEventoEmergencia extends JpaRepository<EventoEmergencia, UUID> {

    /**
     * Remove coordenadas de eventos cuja janela de retenção expirou (NFR-006).
     */
    @Modifying
    @Transactional
    @Query(
            """
            UPDATE EventoEmergencia e
               SET e.latitude = NULL,
                   e.longitude = NULL,
                   e.expiraLocalizacaoEm = NULL
             WHERE e.expiraLocalizacaoEm IS NOT NULL
               AND e.expiraLocalizacaoEm <= :agora
            """)
    int expurgarLocalizacoesExpiradas(@Param("agora") Instant agora);
}
