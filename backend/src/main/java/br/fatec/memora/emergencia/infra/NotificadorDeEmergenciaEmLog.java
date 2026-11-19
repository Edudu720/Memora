package br.fatec.memora.emergencia.infra;

import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * Adaptador de desenvolvimento/teste que registra o despacho SOS em log
 * estruturado sem divulgar coordenadas brutas desnecessariamente (FR-013).
 */
@Component
@Profile("!producao")
public class NotificadorDeEmergenciaEmLog implements NotificadorDeEmergencia {

    private static final Logger LOG = LoggerFactory.getLogger(NotificadorDeEmergenciaEmLog.class);

    @Override
    public ResultadoEntrega notificar(PedidoNotificacao pedido) {
        if (pedido.contatoDestino() == null || pedido.contatoDestino().isBlank()) {
            LOG.warn(
                    "Evento SOS {} sem contato de destino valido para despacho.",
                    pedido.eventoId());
            return ResultadoEntrega.falha("CONTATO_INEXISTENTE");
        }

        String entregaId = "log-" + UUID.randomUUID();
        LOG.info(
                "SOS [{}] tipo={} evento={} ocorridoEm={} contatoPresente=true comLocalizacao={}",
                entregaId,
                pedido.tipo(),
                pedido.eventoId(),
                pedido.ocorridoEm(),
                pedido.latitude() != null && pedido.longitude() != null);
        return ResultadoEntrega.sucesso(entregaId);
    }
}
