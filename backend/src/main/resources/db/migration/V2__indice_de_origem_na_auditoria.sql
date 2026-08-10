-- =============================================================================
-- V2 — Indice para a camada de limite por origem (T021)
--
-- O LimitadorTentativas conta falhas de entrada por origem de rede a cada
-- tentativa, dentro de uma janela deslizante. O data-model.md previa apenas o
-- indice (pessoa_id, ocorrido_em), suficiente para consultar auditoria de uma
-- conta, mas nao para essa contagem: sem indice proprio ela percorre a tabela
-- que mais cresce no sistema, e o caminho de login degrada junto com o volume
-- de auditoria.
--
-- A ordem das colunas segue a consulta: igualdade primeiro (origem, tipo),
-- faixa depois (ocorrido_em).
-- =============================================================================

CREATE INDEX ix_evento_origem_ocorrido
    ON evento_autenticacao (origem_hash, tipo, ocorrido_em);
