-- =============================================================================
-- V12 — Registro de eventos de emergencia SOS manual e queda (Feature 014)
--
-- Decisoes de seguranca e privacidade:
--   * ID gerado pelo cliente como UUID serve de chave de idempotencia (FR-012).
--   * Distingue explicitamente SOS_MANUAL de QUEDA_AUTOMATICA (FR-014, BR-003).
--   * Coordenadas de localizacao sao opcionais, condicionadas a autorizacao, e
--     expiram em 24 horas (expira_localizacao_em) para expurgo automatico (NFR-006).
-- =============================================================================

CREATE TABLE evento_emergencia (
    id                    UUID             NOT NULL,
    pessoa_id             UUID             NOT NULL,
    tipo                  VARCHAR(30)      NOT NULL,
    status                VARCHAR(40)      NOT NULL,
    latitude              DOUBLE PRECISION,
    longitude             DOUBLE PRECISION,
    contato_nome          VARCHAR(120),
    contato_destino       VARCHAR(160),
    entrega_id            VARCHAR(120),
    detalhe_tecnico       VARCHAR(255),
    ocorrido_em           TIMESTAMPTZ      NOT NULL,
    atualizado_em         TIMESTAMPTZ      NOT NULL,
    expira_localizacao_em TIMESTAMPTZ,

    CONSTRAINT pk_evento_emergencia PRIMARY KEY (id),
    CONSTRAINT fk_evento_emergencia_pessoa FOREIGN KEY (pessoa_id)
        REFERENCES pessoa_usuaria (id) ON DELETE CASCADE,
    CONSTRAINT ck_evento_emergencia_tipo CHECK (
        tipo IN ('SOS_MANUAL', 'QUEDA_AUTOMATICA')
    ),
    CONSTRAINT ck_evento_emergencia_status CHECK (
        status IN (
            'PENDENTE',
            'PROCESSANDO',
            'ENVIADO',
            'FALHA',
            'CONFIRMADO_PELO_DESTINATARIO'
        )
    ),
    CONSTRAINT ck_evento_emergencia_coordenadas CHECK (
        (latitude IS NULL AND longitude IS NULL)
        OR (
            latitude BETWEEN -90.0 AND 90.0
            AND longitude BETWEEN -180.0 AND 180.0
        )
    )
);

CREATE INDEX ix_evento_emergencia_pessoa
    ON evento_emergencia (pessoa_id, ocorrido_em DESC);

CREATE INDEX ix_evento_emergencia_expurgo_loc
    ON evento_emergencia (expira_localizacao_em)
    WHERE latitude IS NOT NULL OR longitude IS NOT NULL;
