package br.fatec.memora.emergencia.dominio;

/**
 * Origem do evento de emergência (FR-014, BR-003 da Feature 014).
 */
public enum TipoEventoEmergencia {
    /** Pedido explícito acionado manualmente pelo botão SOS persistente. */
    SOS_MANUAL,

    /** Alerta automático disparado por detecção de queda no dispositivo IoT. */
    QUEDA_AUTOMATICA
}
