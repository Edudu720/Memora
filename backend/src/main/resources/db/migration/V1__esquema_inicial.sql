-- =============================================================================
-- V1 — Esquema inicial da autenticacao (T008)
--
-- Fonte: specs/001-autenticacao-acessivel/data-model.md
--
-- Decisoes que valem para todas as tabelas:
--
--   * CHAVE UUID, NAO SEQUENCIAL. Id sequencial permitiria deduzir quantas
--     pessoas usam o sistema e facilitaria IDOR. A Constituicao proibe expor
--     id interno sem necessidade.
--
--   * ENUM COMO VARCHAR + CHECK, nao como tipo ENUM do PostgreSQL. Alterar um
--     tipo ENUM nativo exige migration desconfortavel; o CHECK entrega a mesma
--     garantia e evolui com um ALTER simples.
--
--   * OS VALORES SAO GRAVADOS EM MAIUSCULAS. O data-model.md escreve
--     `ativa`, `email` e afins em minusculas por ser texto de documento; em
--     codigo, constante de enum Java e maiuscula. Gravar em maiuscula mantem
--     banco e codigo identicos, sem conversor no meio. A camada de API
--     converte para o formato do contrato (`email`, `telefone`) ao responder.
--
--   * TIMESTAMPTZ em todo campo de tempo. Instante e absoluto; guardar sem
--     fuso convida a erro de uma hora em horario de verao.
--
--   * O HIBERNATE NAO CRIA NADA. `ddl-auto=validate`: esta migration e a
--     unica fonte do esquema, e a aplicacao se recusa a subir se uma entidade
--     divergir daqui.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- PESSOA_USUARIA — quem usa o Memora
-- -----------------------------------------------------------------------------
CREATE TABLE pessoa_usuaria (
    id                  UUID         NOT NULL,
    nome_tratamento     VARCHAR(80)  NOT NULL,
    senha_hash          TEXT,
    estado              VARCHAR(30)  NOT NULL,
    criada_em           TIMESTAMPTZ  NOT NULL,
    ultimo_acesso_em    TIMESTAMPTZ,
    falhas_consecutivas INTEGER      NOT NULL DEFAULT 0,
    bloqueada_ate       TIMESTAMPTZ,

    CONSTRAINT pk_pessoa_usuaria PRIMARY KEY (id),
    CONSTRAINT ck_pessoa_estado CHECK (
        estado IN ('ATIVA', 'BLOQUEADA_TEMPORARIAMENTE', 'DESATIVADA')
    ),
    CONSTRAINT ck_pessoa_falhas_nao_negativas CHECK (falhas_consecutivas >= 0)
);

-- `senha_hash` e nulo quando a conta usa apenas login social (FR-053). A regra
-- "senha nula exige identidade externa" nao pode ser um CHECK aqui porque
-- depende de outra tabela, que so nasce na fase 8; fica na camada de dominio.
COMMENT ON COLUMN pessoa_usuaria.senha_hash IS
    'SENSIVEL. Argon2id (R1). Nulo apenas em conta exclusivamente social.';
COMMENT ON COLUMN pessoa_usuaria.nome_tratamento IS
    'Como a pessoa quer ser chamada. NUNCA e credencial (FR-003).';


-- -----------------------------------------------------------------------------
-- CANAL_CONTATO — e-mail ou telefone
-- -----------------------------------------------------------------------------
CREATE TABLE canal_contato (
    id            UUID         NOT NULL,
    pessoa_id     UUID         NOT NULL,
    tipo          VARCHAR(20)  NOT NULL,
    valor         TEXT         NOT NULL,
    valor_hash    TEXT         NOT NULL,
    verificado    BOOLEAN      NOT NULL DEFAULT FALSE,
    verificado_em TIMESTAMPTZ,
    principal     BOOLEAN      NOT NULL DEFAULT FALSE,
    criado_em     TIMESTAMPTZ  NOT NULL,

    CONSTRAINT pk_canal_contato PRIMARY KEY (id),
    CONSTRAINT fk_canal_pessoa FOREIGN KEY (pessoa_id)
        REFERENCES pessoa_usuaria (id) ON DELETE CASCADE,
    CONSTRAINT ck_canal_tipo CHECK (tipo IN ('EMAIL', 'TELEFONE')),

    -- Impede duas contas com o mesmo e-mail ou telefone (data-model.md).
    CONSTRAINT uq_canal_tipo_valor UNIQUE (tipo, valor),

    -- Canal verificado sem data de verificacao seria estado impossivel; e a
    -- data e o que sustenta a auditoria de quando a posse foi confirmada.
    CONSTRAINT ck_canal_verificacao_coerente CHECK (
        (verificado = FALSE AND verificado_em IS NULL)
        OR (verificado = TRUE AND verificado_em IS NOT NULL)
    )
);

CREATE INDEX ix_canal_valor_hash ON canal_contato (valor_hash);
CREATE INDEX ix_canal_pessoa ON canal_contato (pessoa_id);

COMMENT ON COLUMN canal_contato.valor IS
    'CONFIDENCIAL. Normalizado: minusculas, sem espaco.';
COMMENT ON COLUMN canal_contato.valor_hash IS
    'Permite localizar o canal no login sem varrer o valor em claro.';
COMMENT ON COLUMN canal_contato.verificado IS
    'Somente canal verificado recebe codigo de recuperacao (FR-052, FR-062).';


-- -----------------------------------------------------------------------------
-- SESSAO — refresh token rotativo com deteccao de reuso (R2)
-- -----------------------------------------------------------------------------
CREATE TABLE sessao (
    id                 UUID         NOT NULL,
    pessoa_id          UUID         NOT NULL,
    familia_id         UUID         NOT NULL,
    refresh_token_hash TEXT         NOT NULL,
    substituida_por    UUID,
    aparelho_descricao VARCHAR(120),
    criada_em          TIMESTAMPTZ  NOT NULL,
    expira_em          TIMESTAMPTZ  NOT NULL,
    revogada_em        TIMESTAMPTZ,

    CONSTRAINT pk_sessao PRIMARY KEY (id),
    CONSTRAINT fk_sessao_pessoa FOREIGN KEY (pessoa_id)
        REFERENCES pessoa_usuaria (id) ON DELETE CASCADE,

    -- A cadeia de rotacao aponta para a sessao que substituiu esta.
    CONSTRAINT fk_sessao_substituida_por FOREIGN KEY (substituida_por)
        REFERENCES sessao (id) ON DELETE SET NULL,

    -- Unico em vez de apenas indexado: o hash e a chave de busca a cada
    -- renovacao, e colisao entre familias romperia a deteccao de reuso.
    CONSTRAINT uq_sessao_refresh_token_hash UNIQUE (refresh_token_hash),

    CONSTRAINT ck_sessao_expira_depois_de_criar CHECK (expira_em > criada_em)
);

-- Revogacao em massa por familia (deteccao de reuso, troca de senha).
CREATE INDEX ix_sessao_familia ON sessao (familia_id);
CREATE INDEX ix_sessao_pessoa ON sessao (pessoa_id);

COMMENT ON COLUMN sessao.refresh_token_hash IS
    'SENSIVEL. Somente o hash; o token em claro nunca e persistido.';
COMMENT ON COLUMN sessao.familia_id IS
    'Agrupa a cadeia de rotacoes. Chave da deteccao de reuso (R2).';
COMMENT ON COLUMN sessao.substituida_por IS
    'Preenchido significa token ja usado. Se ele reaparecer, houve roubo: '
    'toda a familia e revogada.';


-- -----------------------------------------------------------------------------
-- CODIGO_VERIFICACAO — 6 digitos, 10 minutos, uso unico (R5)
-- -----------------------------------------------------------------------------
CREATE TABLE codigo_verificacao (
    id          UUID         NOT NULL,
    canal_id    UUID         NOT NULL,
    finalidade  VARCHAR(30)  NOT NULL,
    codigo_hash TEXT         NOT NULL,
    expira_em   TIMESTAMPTZ  NOT NULL,
    usado_em    TIMESTAMPTZ,
    tentativas  INTEGER      NOT NULL DEFAULT 0,
    criado_em   TIMESTAMPTZ  NOT NULL,

    CONSTRAINT pk_codigo_verificacao PRIMARY KEY (id),
    CONSTRAINT fk_codigo_canal FOREIGN KEY (canal_id)
        REFERENCES canal_contato (id) ON DELETE CASCADE,
    CONSTRAINT ck_codigo_finalidade CHECK (
        finalidade IN ('VERIFICACAO_POSSE', 'RECUPERACAO_ACESSO')
    ),
    CONSTRAINT ck_codigo_tentativas_nao_negativas CHECK (tentativas >= 0),
    CONSTRAINT ck_codigo_expira_depois_de_criar CHECK (expira_em > criado_em)
);

-- Solicitar novo codigo invalida o anterior da mesma finalidade.
CREATE INDEX ix_codigo_canal_finalidade ON codigo_verificacao (canal_id, finalidade);

COMMENT ON COLUMN codigo_verificacao.codigo_hash IS
    'SENSIVEL. Hasheado; o codigo em claro existe apenas no envio.';
COMMENT ON COLUMN codigo_verificacao.usado_em IS
    'Nulo ate o uso. Uso unico (FR-020).';


-- -----------------------------------------------------------------------------
-- EVENTO_AUTENTICACAO — trilha de auditoria (FR-039)
-- -----------------------------------------------------------------------------
CREATE TABLE evento_autenticacao (
    id          UUID         NOT NULL,
    pessoa_id   UUID,
    tipo        VARCHAR(40)  NOT NULL,
    resultado   VARCHAR(20)  NOT NULL,
    origem_hash TEXT,
    ocorrido_em TIMESTAMPTZ  NOT NULL,

    CONSTRAINT pk_evento_autenticacao PRIMARY KEY (id),

    -- Sem ON DELETE: diferente de canal e sessao, o evento nao acompanha o
    -- ciclo de vida da conta. A politica de retencao anonimiza a conta em vez
    -- de apagar, e a trilha precisa sobreviver a isso.
    CONSTRAINT fk_evento_pessoa FOREIGN KEY (pessoa_id)
        REFERENCES pessoa_usuaria (id),

    CONSTRAINT ck_evento_tipo CHECK (
        tipo IN (
            'CADASTRO',
            'ENTRADA',
            'FALHA_ENTRADA',
            'BLOQUEIO',
            'RECUPERACAO_SOLICITADA',
            'SENHA_ALTERADA',
            'SAIDA',
            'REUSO_TOKEN_DETECTADO',
            'CANAL_VERIFICADO'
        )
    ),
    CONSTRAINT ck_evento_resultado CHECK (resultado IN ('SUCESSO', 'FALHA'))
);

CREATE INDEX ix_evento_pessoa_ocorrido ON evento_autenticacao (pessoa_id, ocorrido_em);

COMMENT ON COLUMN evento_autenticacao.pessoa_id IS
    'Nulo quando a conta nao existe — registrar a tentativa sem confirmar '
    'existencia de conta.';
COMMENT ON COLUMN evento_autenticacao.origem_hash IS
    'CONFIDENCIAL. Endereco de rede hasheado: permite correlacionar abuso sem '
    'reter o endereco.';


-- -----------------------------------------------------------------------------
-- Portao de auditoria: a trilha nao se reescreve
--
-- O data-model.md diz "somente insercao". Deixar isso como acordo entre
-- pessoas nao protege nada: qualquer UPDATE distraido reescreve historico de
-- seguranca sem deixar marca. O gatilho abaixo recusa a alteracao no banco.
--
-- DELETE fica permitido de proposito: a retencao de 12 meses (data-model.md)
-- exige poder expurgar evento antigo. O que nao se admite e alterar o que
-- aconteceu.
-- -----------------------------------------------------------------------------
CREATE FUNCTION recusar_alteracao_de_evento() RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION
        'evento_autenticacao e somente insercao (FR-039): % foi recusado', TG_OP;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_evento_somente_insercao
    BEFORE UPDATE ON evento_autenticacao
    FOR EACH ROW EXECUTE FUNCTION recusar_alteracao_de_evento();
