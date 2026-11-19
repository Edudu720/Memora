package br.fatec.memora.emergencia.dominio;

/**
 * Ciclo técnico de entrega do evento de emergência (FR-010, BR-007, NFR-008).
 */
public enum StatusEventoEmergencia {
    /** Evento criado, aguardando envio. */
    PENDENTE,

    /** Solicitação em processamento pelo canal de notificação. */
    PROCESSANDO,

    /** O serviço aceitou e encaminhou a notificação, sem garantir leitura. */
    ENVIADO,

    /** Falha técnica ao encaminhar a notificação ao contato de emergência. */
    FALHA,

    /** Confirmação real pelo destinatário quando o canal suportar recibo. */
    CONFIRMADO_PELO_DESTINATARIO
}
