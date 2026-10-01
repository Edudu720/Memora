# Contrato: catálogo — a `chave` e as linhas novas

Muda o contrato de `GET /v1/assistente/catalogo`, definido em
[`specs/003-hub-e-assistente/contracts/openapi.yaml`](../../003-hub-e-assistente/contracts/openapi.yaml).
**A mudança é aditiva**: um campo novo, obrigatório na resposta; nenhum campo
sai, nenhum muda de tipo.

## O schema `Servico`, depois

```yaml
Servico:
  type: object
  required: [id, chave, nome_exibido, categoria, memora_pode_abrir]
  properties:
    id:
      type: string
      format: uuid
    chave:                       # NOVO
      type: string
      pattern: '^[a-z0-9-]+$'
      maxLength: 40
      description: |
        Identificador estável do item, igual em qualquer banco. É o que liga o
        item ao guia de passo a passo embarcado no aplicativo. O `id` continua
        sendo o que a trilha de auditoria referencia.
    nome_exibido:
      type: string
    descricao_curta:
      type: string
    categoria:
      type: string
      enum: [sensivel, cotidiano]
    memora_pode_abrir:
      type: boolean
    identificador_android:
      type: string
```

## O que o aplicativo faz com ela

| Situação | Comportamento |
|---|---|
| Item com guia | Tocar abre o passo a passo |
| Item **sem** guia (servidor mais novo que o aplicativo) | Tocar abre a conversa com a Memora já perguntando sobre aquele item. Não some, porque a conversa funciona; não abre tela vazia |
| Guia sem item no catálogo (item retirado do ar) | O guia não aparece em lugar nenhum. Retirar do catálogo continua sendo o jeito de tirar algo do ar sem nova versão (R6 da 003) |

## A migration

Três migrations, para cada lote de linhas entrar junto com os guias dele (R8):

| Migration | O que faz |
|---|---|
| `V8__chave_do_catalogo.sql` | Cria `chave` e preenche as 8 linhas existentes |
| `V9__aplicativos_do_wireframe.sql` | Os aplicativos cotidianos novos |
| `V10__servicos_sociais.sql` | Os serviços sociais novos |

Detalhe das linhas em [data-model.md](../data-model.md#servico_conhecido--migrations-v8-a-v10).

**Portões no backend**, provados quebrando, como todo portão do projeto:

- **`chave` é obrigatória e única**: inserir sem `chave`, ou repetida, é recusado
  pelo banco.
- **As linhas sensíveis novas não abrem**: `ck_servico_sensivel_nao_abre` recusa
  qualquer uma delas com pacote. O teste insere uma de propósito.
- **O catálogo semeado sobrevive à suíte**: cada teste das migrations apaga só o que criou
  (achado 1 da revisão de 2026-10-01 — o `DELETE` global já derrubou o CI).
