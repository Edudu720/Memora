-- =============================================================================
-- V11 — TikTok no catalogo cotidiano (feature 004, US4, T070, T075)
--
-- Acrescenta o TikTok como servico cotidiano abrivel com guia passo a passo.
-- =============================================================================

INSERT INTO servico_conhecido
    (id, chave, nome_exibido, categoria, identificador_android,
     descricao_curta, ativo, criado_em, atualizado_em)
VALUES
    (gen_random_uuid(), 'tiktok', 'TikTok', 'COTIDIANO', 'com.zhiliaoapp.musically',
     'Assistir a vídeos e seguir criadores de conteúdo',
     TRUE, now(), now());

