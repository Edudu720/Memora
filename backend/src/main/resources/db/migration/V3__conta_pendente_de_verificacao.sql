-- =============================================================================
-- V3 — Conta pendente de verificacao (T057)
--
-- O modo assistido (D3) exige que o canal de recuperacao tenha posse confirmada
-- ANTES de o cadastro concluir (FR-062), e o cenario V4 e literal: "o cadastro
-- assistido nao conclui sem posse confirmada".
--
-- Isso esbarra numa circularidade: o canal so passa a existir dentro do
-- cadastro, e os endpoints que confirmam posse exigem autenticacao, que so
-- existe depois do cadastro. A saida escolhida foi um estado intermediario —
-- a conta nasce PENDENTE_VERIFICACAO, recebe sessao que serve para confirmar o
-- canal e nada mais, e so vira ATIVA quando a posse e confirmada.
--
-- A restricao ck_pessoa_estado precisa ser recriada, e nao apenas ampliada:
-- CHECK nao aceita alteracao no lugar. Enquanto ela nao conhecer o valor novo,
-- o banco recusa a insercao — que e exatamente a protecao que o enum
-- EstadoDaConta documenta.
--
-- ck_evento_tipo nao e tocada de proposito: CANAL_VERIFICADO ja consta dela
-- desde a V1. O que faltava era o valor no enum TipoDeEvento, do lado Java.
-- =============================================================================

ALTER TABLE pessoa_usuaria
    DROP CONSTRAINT ck_pessoa_estado;

ALTER TABLE pessoa_usuaria
    ADD CONSTRAINT ck_pessoa_estado CHECK (
        estado IN (
            'ATIVA',
            'PENDENTE_VERIFICACAO',
            'BLOQUEADA_TEMPORARIAMENTE',
            'DESATIVADA'
        )
    );
