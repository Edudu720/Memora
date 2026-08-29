-- =============================================================================
-- V4 — Catalogo de servicos, trilha da assistente e uso diario (T004-T006)
--
-- Tres tabelas, e uma decisao de seguranca escrita como restricao:
--
--   servico_conhecido   — o catalogo que AUTORIZA. A FR-022 exige que a
--                         autorizacao seja determinstica e consultavel, e nao
--                         uma leitura da resposta do modelo.
--   evento_da_assistente— a trilha da FR-020, somente insercao.
--   uso_da_assistente   — o teto diario da R7, para que o custo por chamada
--                         nao vire negacao de servico.
--
-- O conteudo das conversas NAO aparece em nenhuma delas. E a FR-047, e a
-- decisao D3 da spec: guardar conversa de pessoa idosa no servidor criaria um
-- acervo Confidencial sobre quem e o alvo preferencial de golpe no Brasil.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- servico_conhecido — o catalogo
--
-- Duas categorias, e a regra que governa a feature inteira: quanto mais
-- sensivel o servico, MENOS a Memora toca nele.
--
--   COTIDIANO — Instagram, YouTube, WhatsApp. Ela ensina E pode abrir.
--   SENSIVEL  — Gov.br, banco, saude. Ela SO ensina, nunca abre.
--
-- Abrir o aplicativo do banco pela pessoa treinaria nela exatamente o gesto que
-- o golpista precisa que ela tenha: o de deixar outra pessoa entrar na conta
-- por ela.
-- -----------------------------------------------------------------------------
CREATE TABLE servico_conhecido (
    id                     UUID         NOT NULL,
    nome_exibido           VARCHAR(80)  NOT NULL,
    categoria              VARCHAR(20)  NOT NULL,
    identificador_android  VARCHAR(255),
    descricao_curta        VARCHAR(200) NOT NULL,
    ativo                  BOOLEAN      NOT NULL DEFAULT TRUE,
    criado_em              TIMESTAMPTZ  NOT NULL,
    atualizado_em          TIMESTAMPTZ  NOT NULL,

    CONSTRAINT pk_servico_conhecido PRIMARY KEY (id),

    CONSTRAINT ck_servico_categoria CHECK (categoria IN ('SENSIVEL', 'COTIDIANO')),

    -- O PORTAO DA FR-041, escrito no banco e nao no codigo.
    --
    -- Servico sensivel nao tem como ser aberto porque falta o dado necessario
    -- para abri-lo. Isso e mais forte que uma regra em Java: quem, no futuro,
    -- mudar a categoria de um banco para COTIDIANO vai ter que preencher o
    -- pacote junto, e esse gesto e visivel na revisao. Uma verificacao em
    -- codigo alguem remove sem querer; esta aqui o banco recusa.
    CONSTRAINT ck_servico_sensivel_nao_abre CHECK (
        (categoria = 'SENSIVEL'  AND identificador_android IS NULL)
        OR
        (categoria = 'COTIDIANO' AND identificador_android IS NOT NULL)
    )
);

-- A consulta da autorizacao roda a cada sugestao do modelo: precisa ser barata.
CREATE UNIQUE INDEX ux_servico_pacote
    ON servico_conhecido (identificador_android)
    WHERE identificador_android IS NOT NULL AND ativo;

CREATE INDEX ix_servico_categoria ON servico_conhecido (categoria, ativo);

COMMENT ON COLUMN servico_conhecido.identificador_android IS
    'Pacote Android. NULO quando SENSIVEL — e a FR-041: sem este dado, nao ha '
    'como abrir o aplicativo, nem por engano.';
COMMENT ON COLUMN servico_conhecido.ativo IS
    'Permite tirar um servico do ar sem apagar a trilha que aponta para ele.';


-- -----------------------------------------------------------------------------
-- evento_da_assistente — a trilha da FR-020
--
-- Mesmo molde de evento_autenticacao: somente insercao, com o gatilho recusando
-- UPDATE no banco. Auditoria que o auditado pode reescrever nao serve.
-- -----------------------------------------------------------------------------
CREATE TABLE evento_da_assistente (
    id               UUID         NOT NULL,
    pessoa_id        UUID         NOT NULL,
    tipo             VARCHAR(40)  NOT NULL,
    servico_id       UUID,
    pedido_resumido  VARCHAR(120),
    origem_hash      TEXT,
    ocorrido_em      TIMESTAMPTZ  NOT NULL,

    CONSTRAINT pk_evento_da_assistente PRIMARY KEY (id),

    -- Sem ON DELETE, como em evento_autenticacao: a trilha sobrevive a
    -- anonimizacao da conta.
    CONSTRAINT fk_evento_assistente_pessoa FOREIGN KEY (pessoa_id)
        REFERENCES pessoa_usuaria (id),

    CONSTRAINT fk_evento_assistente_servico FOREIGN KEY (servico_id)
        REFERENCES servico_conhecido (id),

    CONSTRAINT ck_evento_assistente_tipo CHECK (
        tipo IN (
            'CONVERSA_INICIADA',
            'ACAO_EXECUTADA',
            'ACAO_RECUSADA',
            'LIMITE_ATINGIDO'
        )
    )
);

CREATE INDEX ix_evento_assistente_pessoa
    ON evento_da_assistente (pessoa_id, ocorrido_em DESC);

COMMENT ON COLUMN evento_da_assistente.pedido_resumido IS
    'CONFIDENCIAL. O que a pessoa pediu, em ate 120 caracteres. E a excecao '
    'estreita a FR-036, e existe porque sem ela o registro da FR-023 viraria '
    '"uma acao aconteceu as 14h" — que nao serve a pessoa. TRUNCADO NO '
    'SERVIDOR: confiar o corte ao aparelho transformaria um campo de tabela '
    'imutavel em texto livre.';
COMMENT ON COLUMN evento_da_assistente.origem_hash IS
    'CONFIDENCIAL. Endereco de rede hasheado, como em evento_autenticacao.';

CREATE TRIGGER tg_evento_assistente_somente_insercao
    BEFORE UPDATE ON evento_da_assistente
    FOR EACH ROW EXECUTE FUNCTION recusar_alteracao_de_evento();


-- -----------------------------------------------------------------------------
-- uso_da_assistente — o teto diario (R7)
--
-- NAO estava na spec, e e consequencia direta de existir endpoint autenticado
-- que gasta dinheiro por chamada. Sem teto, uma conta comprometida esgota a
-- cota do provedor e derruba a assistente para todo mundo — uma negacao de
-- servico que se paga em reais.
--
-- Estado no banco, e nao em memoria, pelo mesmo motivo do LimitadorTentativas:
-- contador que zera no reinicio nao limita nada.
-- -----------------------------------------------------------------------------
CREATE TABLE uso_da_assistente (
    pessoa_id   UUID    NOT NULL,
    dia         DATE    NOT NULL,
    conversas   INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT pk_uso_da_assistente PRIMARY KEY (pessoa_id, dia),

    CONSTRAINT fk_uso_assistente_pessoa FOREIGN KEY (pessoa_id)
        REFERENCES pessoa_usuaria (id) ON DELETE CASCADE,

    CONSTRAINT ck_uso_conversas_positivo CHECK (conversas >= 0)
);

COMMENT ON TABLE uso_da_assistente IS
    'Contagem diaria por conta. ON DELETE CASCADE de proposito: diferente da '
    'trilha, isto e contador operacional e nao historico de seguranca.';
