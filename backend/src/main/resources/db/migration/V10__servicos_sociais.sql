-- =============================================================================
-- V10 — Servicos sociais no catalogo (feature 004, US5, T083)
--
-- Acrescenta os sete servicos sociais ao catalogo: e-Titulo, Serasa, FGTS,
-- Poupatempo, Carteira Digital, Correios e Carteira de Trabalho Digital.
--
-- Todas as linhas entram como SENSIVEL e com identificador_android = NULL:
-- a Memora ensina o caminho oficial por passo a passo ilustrado embarcado,
-- mas nunca abre nenhum desses servicos (FR-041, Principio VII). A restricao
-- ck_servico_sensivel_nao_abre garante que nenhum identificador de pacote
-- seja atribuido a essas linhas.
-- =============================================================================

INSERT INTO servico_conhecido
    (id, chave, nome_exibido, categoria, identificador_android,
     descricao_curta, ativo, criado_em, atualizado_em)
VALUES
    (gen_random_uuid(), 'e-titulo', 'e-Título', 'SENSIVEL', NULL,
     'Consultar situação eleitoral, local de votação e justificativa',
     TRUE, now(), now()),

    (gen_random_uuid(), 'serasa', 'Serasa', 'SENSIVEL', NULL,
     'Consultar CPF, score e renegociação de dívidas',
     TRUE, now(), now()),

    (gen_random_uuid(), 'fgts', 'FGTS', 'SENSIVEL', NULL,
     'Consultar saldo do FGTS, extrato e saque-aniversário',
     TRUE, now(), now()),

    (gen_random_uuid(), 'poupatempo', 'Poupatempo', 'SENSIVEL', NULL,
     'Agendar atendimentos e serviços públicos do estado',
     TRUE, now(), now()),

    (gen_random_uuid(), 'carteira-digital', 'Carteira Digital', 'SENSIVEL', NULL,
     'Documentos pessoais e carteira de identificação oficial',
     TRUE, now(), now()),

    (gen_random_uuid(), 'correios', 'Correios', 'SENSIVEL', NULL,
     'Rastrear encomendas e gerenciar entregas',
     TRUE, now(), now()),

    (gen_random_uuid(), 'carteira-de-trabalho', 'Carteira de Trabalho Digital', 'SENSIVEL', NULL,
     'Acessar contratos de trabalho, férias e seguro-desemprego',
     TRUE, now(), now());
