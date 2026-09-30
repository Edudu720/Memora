-- =============================================================================
-- V7 — o limite diario conta conversas, e nao turnos (FR-053)
--
-- A V4 contava cada chamada ao endpoint de conversa, e o teto de 20 virava 20
-- MENSAGENS por dia: o bastante para um unico passo a passo dificil acabar com
-- o dia da pessoa.
--
-- Uma conversa e a sequencia de turnos sem pausa de 30 minutos e com no maximo
-- 30 turnos. Para saber se um turno continua a conversa ou abre outra, o
-- servidor precisa de duas coisas: quando foi o ultimo turno, e quantos a
-- conversa atual ja tem. Nenhuma das duas e conteudo — a conversa continua so
-- no aparelho (FR-047, D3).
-- =============================================================================

ALTER TABLE uso_da_assistente
    ADD COLUMN ultimo_turno_em    TIMESTAMPTZ,
    ADD COLUMN turnos_na_conversa INTEGER NOT NULL DEFAULT 0;

ALTER TABLE uso_da_assistente
    ADD CONSTRAINT ck_uso_turnos_positivo CHECK (turnos_na_conversa >= 0);

COMMENT ON COLUMN uso_da_assistente.ultimo_turno_em IS
    'Instante do ultimo turno. Pausa de 30 min ou mais abre conversa nova (FR-053).';
COMMENT ON COLUMN uso_da_assistente.turnos_na_conversa IS
    'Turnos da conversa em curso. No 31o, abre-se outra (FR-053).';
