-- =============================================================================
-- V8 — a chave estavel do catalogo (feature 004, T029)
--
-- O `id` de cada servico e um UUID sorteado na V5 e na V6: muda de banco para
-- banco, e por isso nao serve para ligar a linha a nada que viva FORA do banco.
-- A feature 004 embarca no aplicativo um guia de passo a passo por item do
-- catalogo, e o guia precisa saber de qual item ele e. A `chave` e esse elo:
-- igual em qualquer banco, escrita a mao, legivel na revisao.
--
-- O `id` continua sendo o que a trilha de auditoria referencia. A chave nao
-- substitui nada; ela acrescenta um nome estavel.
--
-- =============================================================================
-- Por que preencher pelo nome_exibido
-- =============================================================================
--
-- E a unica coluna das linhas existentes que e igual em todo banco. Se algum
-- banco tiver uma linha a mais (um servico acrescentado a mao, fora de
-- migration), ela fica sem chave e o SET NOT NULL abaixo DERRUBA a migration.
-- E de proposito: linha de catalogo fora de migration e exatamente o que nao
-- deveria existir, e falhar alto obriga alguem a olhar para ela.
--
-- Formato da chave: ASCII minusculo, numeros e hifen. O teste do aplicativo
-- (catalogo_e_guias_test.dart) le as chaves DESTE arquivo e das migrations
-- seguintes, e reprova se o simulado divergir. Mantenha uma atribuicao por
-- linha, no formato  SET chave = '...'  — e o que ele procura.
-- =============================================================================

ALTER TABLE servico_conhecido
    ADD COLUMN chave VARCHAR(40);

UPDATE servico_conhecido SET chave = 'whatsapp'     WHERE nome_exibido = 'WhatsApp';
UPDATE servico_conhecido SET chave = 'facebook'     WHERE nome_exibido = 'Facebook';
UPDATE servico_conhecido SET chave = 'instagram'    WHERE nome_exibido = 'Instagram';
UPDATE servico_conhecido SET chave = 'youtube'      WHERE nome_exibido = 'YouTube';
UPDATE servico_conhecido SET chave = 'google-fotos' WHERE nome_exibido = 'Google Fotos';
UPDATE servico_conhecido SET chave = 'telegram'     WHERE nome_exibido = 'Telegram';
UPDATE servico_conhecido SET chave = 'gov-br'       WHERE nome_exibido = 'Gov.br';
UPDATE servico_conhecido SET chave = 'meu-inss'     WHERE nome_exibido = 'Meu INSS';

ALTER TABLE servico_conhecido
    ALTER COLUMN chave SET NOT NULL;

ALTER TABLE servico_conhecido
    ADD CONSTRAINT ux_servico_chave UNIQUE (chave);

ALTER TABLE servico_conhecido
    ADD CONSTRAINT ck_servico_chave_formato CHECK (chave ~ '^[a-z0-9-]+$');

COMMENT ON COLUMN servico_conhecido.chave IS
    'Identificador estavel, igual em qualquer banco. Liga o item ao guia embarcado no aplicativo (feature 004).';
