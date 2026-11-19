package br.fatec.memora.emergencia.infra;

import br.fatec.memora.emergencia.dominio.TipoEventoEmergencia;
import java.time.Instant;
import java.util.UUID;

/**
 * Contrato de despacho de notificação de emergência para o contato cadastrado
 * (FR-007, FR-008, FR-013).
 */
public interface NotificadorDeEmergencia {

    /** Dados necessários para compor a notificação ao contato de confiança. */
    record PedidoNotificacao(
            UUID eventoId,
            UUID pessoaId,
            String nomeSolicitante,
            TipoEventoEmergencia tipo,
            Instant ocorridoEm,
            String contatoNome,
            String contatoDestino,
            Double latitude,
            Double longitude) {}

    /** Resultado técnico da tentativa de despacho pelo canal disponível. */
    record ResultadoEntrega(boolean entregue, String entregaId, String detalheTecnico) {
        public static ResultadoEntrega sucesso(String entregaId) {
            return new ResultadoEntrega(true, entregaId, null);
        }

        public static ResultadoEntrega falha(String detalheTecnico) {
            return new ResultadoEntrega(false, null, detalheTecnico);
        }
    }

    ResultadoEntrega notificar(PedidoNotificacao pedido);
}
