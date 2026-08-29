# Data Model — Hub e a assistente que ensina

Duas tabelas no servidor e um armazenamento local no aparelho. **O conteúdo das
conversas não aparece em nenhuma tabela** — é a FR-047, e é deliberado.

---

## Servidor — PostgreSQL

### `servico_conhecido`

O catálogo. É ele quem responde à pergunta que a FR-022 exige: *isto pode ser
aberto?*

| Campo | Tipo | Classificação | Regras |
|---|---|---|---|
| `id` | UUID | Público | chave primária |
| `nome_exibido` | TEXT | Público | como a pessoa chama o serviço: *"WhatsApp"*, *"Meu INSS"* |
| `categoria` | TEXT | Público | `SENSIVEL` ou `COTIDIANO` — em maiúsculas, como os demais enums do projeto |
| `identificador_android` | TEXT | Público | o pacote (`com.whatsapp`). **Nulo quando `SENSIVEL`** |
| `descricao_curta` | TEXT | Público | o que é, em linguagem comum |
| `ativo` | BOOLEAN | Público | tirar do ar sem apagar histórico |
| `criado_em` / `atualizado_em` | TIMESTAMPTZ | Interno | |

**Regras que o banco garante, e não só o código:**

- `categoria = 'SENSIVEL'` **exige** `identificador_android IS NULL`.
  É a FR-041 escrita como restrição: um serviço sensível não tem como ser aberto,
  porque não existe o dado necessário para abri-lo. Alguém que mude a categoria
  no futuro precisa apagar o pacote junto — e isso é intencional.
- `identificador_android` é único entre os ativos.

**Índices**: `categoria` (as duas listas do catálogo), `identificador_android`
(a consulta de autorização, que roda a cada sugestão do modelo).

---

### `evento_da_assistente`

A trilha da FR-020. Mesmo molde de `evento_autenticacao`: entidade `@Immutable`,
gatilho recusando UPDATE no banco, `DELETE` permitido para o expurgo por
retenção.

| Campo | Tipo | Classificação | Regras |
|---|---|---|---|
| `id` | UUID | Público | |
| `pessoa_id` | UUID | Interno | FK para `pessoa_usuaria` |
| `tipo` | TEXT | Público | `ACAO_EXECUTADA`, `ACAO_RECUSADA`, `CONVERSA_INICIADA`, `LIMITE_ATINGIDO` |
| `servico_id` | UUID | Público | FK para `servico_conhecido`, nulo quando não há serviço |
| `pedido_resumido` | TEXT | **Confidencial** | o que a pessoa pediu, em no máximo 120 caracteres — o que a FR-023 precisa para o registro ser legível |
| `ocorrido_em` | TIMESTAMPTZ | Público | |
| `origem_hash` | TEXT | Interno | HMAC da origem, como em `evento_autenticacao` |

**O que nunca entra aqui** (FR-036): senha, código, token, e o **conteúdo da
conversa**. `pedido_resumido` é a exceção estreita e consciente: sem alguma
lembrança do pedido, o registro vira *"uma ação foi executada às 14h"*, que não
serve à pessoa e portanto não cumpre a FR-023.

> ⚠️ **`pedido_resumido` é Confidencial e vem de texto digitado.** Ele precisa ser
> truncado no servidor, e não confiado ao aparelho — senão o campo vira um lugar
> onde se escreve o que se quiser numa tabela imutável.

---

## Aparelho — armazenamento local

### Conversa

Fica no aparelho (FR-047) e é apagada ao sair da conta (FR-048), junto com o
resto dos dados pessoais.

| Elemento | O quê |
|---|---|
| `Mensagem` | autor (`pessoa` ou `memora`), texto, momento |
| `Orientacao` | os passos de um caminho ensinado, e em qual a pessoa está (FR-049) |
| `AcaoSugerida` | serviço, nome exibido e o estado: oferecida, confirmada, recusada |

**Não vai no cofre de credenciais.** O `flutter_secure_storage` é para token e
refresh; o cenário V8 da feature 001 reprova se sobrar **qualquer coisa** lá
depois de sair. A conversa não é credencial — mas é Confidencial, então também
não vai em `SharedPreferences`, que é onde mora só o identificador do último
acesso.

> **Decisão que a implementação precisa tomar**: qual armazenamento local recebe
> a conversa. As duas caixas que o projeto já usa estão descartadas pelos motivos
> acima. A tarefa correspondente precisa escolher e justificar — provavelmente um
> arquivo em diretório privado do aplicativo, apagado por `LimpezaDeSessao`.

---

## Como as duas categorias mudam o comportamento

| | `COTIDIANO` | `SENSIVEL` |
|---|---|---|
| A assistente ensina | ✅ | ✅ |
| A assistente pode abrir | ✅ com confirmação | ❌ **nunca**, nem com confirmação |
| Aparece em | *Meus aplicativos* | *Serviços do dia a dia* |
| Tem `identificador_android` | sim | **não** — o banco recusa |
| Exemplos | WhatsApp, Instagram, YouTube, câmera | Gov.br, Meu INSS, banco, agendamento de saúde |

A regra em uma frase: **quanto mais sensível o serviço, menos a Memora toca
nele.** É o inverso da conveniência, e é o ponto — abrir o banco pela pessoa
treina nela o gesto que o golpista precisa que ela tenha.
