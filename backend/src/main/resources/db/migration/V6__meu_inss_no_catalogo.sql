-- =============================================================================
-- V6 — Meu INSS entra no catalogo (decisao de 2026-08-29)
--
-- Primeira migration a exercitar o padrao que a V5 estabeleceu: o catalogo
-- muda com o tempo, e cada mudanca vira migration propria, com data e autor.
-- Alterar a V5 no lugar quebraria o checksum do Flyway em qualquer banco onde
-- ela ja tenha rodado.
--
-- Entra como SENSIVEL: beneficio, aposentadoria e dados previdenciarios sao
-- exatamente o tipo de servico que o golpista quer alcancar. A Memora ensina o
-- caminho e nunca abre — e a restricao ck_servico_sensivel_nao_abre garante
-- isso ao recusar qualquer identificador de aplicativo nesta linha.
--
-- Bancos e servicos de saude continuam fora, aguardando decisao da equipe.
-- =============================================================================

INSERT INTO servico_conhecido
    (id, nome_exibido, categoria, identificador_android, descricao_curta,
     ativo, criado_em, atualizado_em)
VALUES
    (gen_random_uuid(), 'Meu INSS', 'SENSIVEL', NULL,
     'Ver seu beneficio, extrato e agendar atendimento',
     TRUE, now(), now());
