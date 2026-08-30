-- =============================================================================
-- V5 — O catalogo inicial (T044)
--
-- Migration separada da V4 de proposito: aquela cria a ESTRUTURA, esta traz o
-- CONTEUDO. O catalogo vai mudar com o tempo — aplicativo que sai do ar,
-- servico do governo que entra —, e cada mudanca vira uma migration propria,
-- com data e autor. Misturar as duas coisas faria a estrutura ser reescrita
-- toda vez que alguem acrescentasse um aplicativo.
--
-- =============================================================================
-- De onde veio esta lista
-- =============================================================================
--
-- Nao foi escolhida por impressao. Entre pessoas de 60 anos ou mais no Brasil,
-- o WhatsApp tem 58,7% de penetracao e o Instagram 26,3%; 74,5% dos idosos ja
-- usam internet (IBGE, 2025), e 81% dos de 60 a 69 anos tem celular proprio
-- (TIC Domicilios 2025).
--
-- O criterio para entrar como COTIDIANO foi duplo:
--   1. uso real e alto neste publico, e
--   2. identificador de pacote ESTAVEL entre fabricantes.
--
-- O segundo item eliminou candidatos obvios: camera, galeria do sistema,
-- telefone e contatos sao usadissimos, e cada fabricante usa um pacote
-- diferente. Abrir "o aplicativo errado" num aparelho Samsung porque o pacote
-- foi escrito pensando num Motorola e pior do que nao abrir.
--
-- =============================================================================
-- Por que so o Gov.br em SENSIVEL, por enquanto
-- =============================================================================
--
-- Decisao do Eduardo, 2026-08-29: comecar com o Gov.br e acrescentar os demais
-- servicos depois. Bancos, INSS e saude entram em migrations proprias, quando a
-- equipe definir a lista.
--
-- A conta que essa espera nao paga: enquanto um servico NAO esta aqui, a Memora
-- nem ensina nem abre — ela simplesmente nao o conhece. Isso e seguro (nada e
-- aberto por engano) e incompleto (a pessoa nao recebe ajuda). O oposto seria
-- perigoso, e por isso a ordem de entrada e essa.
--
-- Repare que nenhum servico SENSIVEL tem identificador_android: a restricao
-- ck_servico_sensivel_nao_abre recusaria a linha. E a FR-041 escrita no banco —
-- servico sensivel nao tem como ser aberto porque falta o dado.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- COTIDIANO — a Memora ensina E pode abrir
-- -----------------------------------------------------------------------------
INSERT INTO servico_conhecido
    (id, nome_exibido, categoria, identificador_android, descricao_curta,
     ativo, criado_em, atualizado_em)
VALUES
    (gen_random_uuid(), 'WhatsApp', 'COTIDIANO', 'com.whatsapp',
     'Mandar mensagem, audio e fazer chamada de video',
     TRUE, now(), now()),

    (gen_random_uuid(), 'Facebook', 'COTIDIANO', 'com.facebook.katana',
     'Ver o que a familia e os amigos postaram',
     TRUE, now(), now()),

    (gen_random_uuid(), 'Instagram', 'COTIDIANO', 'com.instagram.android',
     'Ver fotos e videos de quem voce segue',
     TRUE, now(), now()),

    (gen_random_uuid(), 'YouTube', 'COTIDIANO', 'com.google.android.youtube',
     'Assistir videos, musica e receitas',
     TRUE, now(), now()),

    (gen_random_uuid(), 'Google Fotos', 'COTIDIANO',
     'com.google.android.apps.photos',
     'Ver as fotos que voce tirou e as que te enviaram',
     TRUE, now(), now()),

    (gen_random_uuid(), 'Telegram', 'COTIDIANO', 'org.telegram.messenger',
     'Outro jeito de mandar mensagem',
     TRUE, now(), now());


-- -----------------------------------------------------------------------------
-- SENSIVEL — a Memora SO ensina, e nunca abre
--
-- Um item so, por decisao da equipe. Os demais entram em migrations proprias.
-- -----------------------------------------------------------------------------
INSERT INTO servico_conhecido
    (id, nome_exibido, categoria, identificador_android, descricao_curta,
     ativo, criado_em, atualizado_em)
VALUES
    (gen_random_uuid(), 'Gov.br', 'SENSIVEL', NULL,
     'Servicos do governo: documentos, beneficios e agendamentos',
     TRUE, now(), now());
