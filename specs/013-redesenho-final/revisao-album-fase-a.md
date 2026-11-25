# Álbum de telas contra a memora-ux — Fase A (T044)

**Data**: 2026-11-18 · **Commit**: `redesign-final` em `3127087` (#90, #91, #93 e #94 dentro)
**Como**: `cd app; flutter test test/album` → 96 PNGs (32 telas × claro, escuro, alto contraste),
com a Atkinson carregada. Conferidas as 32 no tema claro e 8 no alto contraste (01, 07, 09, 12,
14, 19, 24, 31) contra a seção 5 da `.claude/skills/memora-ux/SKILL.md`.

O álbum não é *golden*: as imagens ficam em `app/build/album/` (ignorado pelo Git) e quem julga é
gente. Itens 1 e 2 da checagem (matriz 4 × 3 e "reduzir movimento") são cobertos pela suíte
(`flutter test`, rodada na T043), não pelo olho.

## Resultado por item da checagem

| # | Item da seção 5 | Resultado |
|---|---|---|
| 1 | Matriz de aparelhos, sem estouro e usável | Coberto pela suíte (T043) |
| 2 | "Reduzir movimento": nada some | Coberto pela suíte (T043) |
| 3 | No máximo duas frases por bloco | ⚠️ Um aviso (A6) |
| 4 | Palavra proibida / tom de incapacidade | ⚠️ "Atalhos" (A3); gênero (A4) |
| 5 | Memora com a expressão certa, uma vez só | 🔴 Duas Memoras em 19 e 31 (A2), já na **T096** |
| 6 | Ícone sem texto, imagem onde deveria haver vetor | 🔴 Emoji como texto (A1); ⚠️ ícone repetido (A5) |
| 7 | "Como um golpista exploraria esta tela?" | ✅ Avisos antigolpe visíveis em 08, 09, 14, 22, 28 e 32; nada animado esconde aviso ou confirmação. ⚠️ Privacidade (A7) |

## Achados

### 🔴 A1 — Emoji no texto do cadastro, desenhado como quadrado vazio
`app/lib/features/autenticacao/presentation/telas/tela_cadastro.dart:141`:
`'documento — eu nunca preciso disso 😊'`. O texto está **literal no widget**, fora do `l10n/`, e
por isso o portão de texto da T068 não o vê. No álbum, a fonte não tem o glifo e sai um "▯"; num
aparelho sem a fonte de emoji, o mesmo. A memora-ux proíbe emoji em texto de tela.
**Correção**: tirar o emoji e levar o texto para `textos_autenticacao.dart`.

### 🔴 A2 — Duas Memoras na mesma tela (FR-006)
- **19 — O que eu fiz por você**: a Memora do cartão e a do estado vazio.
- **31 — Dispositivo de Cuidado**: a do cabeçalho e a do cartão "Dispositivo Conectado".
Já é a **T096** (agente em andamento, branch `redesign/T073-estados`).

### ⚠️ A3 — "Atalhos rápidos" no Início (12)
"Atalho" é jargão (mesma leitura da revisão da #85). Sugestão: "O que você quer fazer?" ou
"Também posso te ajudar com".

### ⚠️ A4 — Texto que supõe mulher (decisão pendente)
A revisão da #90 pediu forma neutra em `caminhoPercorrido` e `porqueNaoAbroServicoSensivel`, mas
o resto do aplicativo segue no feminino:
- `textos_autenticacao.dart:240` e `:245` — "você vai entrar sozinha", **"Quero entrar sozinha"** (06)
- `textos_apresentacao.dart:81` e `textos_ajuda.dart:101` — "você consiga sozinha" (10)
- `textos_assistente.dart:263` — "Prefiro tentar sozinha"
- `tela_registro.dart:106` — **"Você fez tudo sozinha até agora"** (19; literal fora do `l10n/`)
- `textos_casca.dart:55` e `textos_perfil.dart:15` — **"Como você quer ser chamada"** (29)
- `galeria_memora.dart:612` — exemplo da galeria (só depuração)

Nem a spec nem a memora-ux têm regra de gênero. **Decisão do Henrique**: neutro em tudo (e então
vira regra na memora-ux e palavra vigiada pelo portão) ou aceitar o feminino.

### ⚠️ A5 — Mesmo ícone para três portas diferentes no Hub (13)
"Serviços sociais", "Dispositivo de Cuidado" e "Localizador de Serviços" usam o mesmo prédio de
governo. Para quem se guia pelo desenho, as três parecem a mesma coisa. Sugestão: coração/pulso
para o Cuidado e alfinete de mapa para o Localizador (variante `_rounded`).

### ⚠️ A6 — Aviso da conversa expandido com três frases no segundo parágrafo (14)
"Não escreva dados pessoais aqui. Para eu te responder, (...) podem ler. Não escreva senha,
documento, (...)". A primeira e a terceira dizem o mesmo; dá para fundir em duas.

### ⚠️ A7 — "o Memora não guarda cópia" na Privacidade (27)
Verdade sobre o Memora, mas a conversa vai para o nível gratuito do Gemini, que pode guardá-la e
usá-la (FR-051, Emenda 1). Lida ao lado de "a conversa viaja a cada pergunta", a frase sugere que
ninguém guarda. É a pendência da equipe já registrada no `CLAUDE.md` ("a frase de Privacidade
diante do Gemini gratuito"). Sugestão: "o Memora não guarda cópia, mas o serviço do Google pode
guardar o que você escreve".

### Menores
- **03 — Cadastro**: "Como posso te chamar?" aparece duas vezes seguidas (título da caixa e rótulo
  do campo).
- **32 — Alerta de queda**: "Ao zerar, **prepararemos** o pedido de ajuda" sai da voz da Memora
  (primeira pessoa do singular). Sugestão: "Quando chegar a zero, eu preparo o pedido de ajuda."

## O que está bem
- A Memora aparece com a expressão do contexto em toda a autenticação, na apresentação, no Início
  (anfitriã), na Ajuda e no alerta de queda (preocupada, com escudo).
- Alto contraste: bordas fortes, foco e seleção visíveis, nenhum texto sobre degradê.
- Avisos antigolpe presentes e legíveis onde a constituição exige (recuperação, conversa,
  apresentação, Minha conta, alerta de queda).
- A galeria só aparece em Ajustes porque o álbum roda em depuração (R9).

## Quem faz o quê (atualizado no mesmo dia)
- **A1** ✅ corrigido em `redesign/texto-neutro`: sem emoji, texto levado para
  `TextosAutenticacao.cadastroSoONecessario`.
- **A2** ✅ T096 (`redesign/T073-estados`): `EstadoVazio` e `MensagemErro` ganharam `comMemora`, e
  o Cuidado ficou só com a Memora do painel. O portão é o `memora_unica_nos_estados_test.dart`.
- **A4** ✅ **decisão do Henrique: neutro em tudo.** Corrigido em `redesign/texto-neutro` (inclusive
  dois textos dos guias que o portão novo achou) e no título do registro vazio (T096). O portão
  `texto_da_interface_test.dart` reprova "você … sozinha", "quero … sozinha", "ser chamada" e
  "fica tranquila"; a regra entrou na seção 4 da memora-ux.
- **A7** ✅ decisão do Henrique: a Privacidade diz que a conversa viaja até um serviço do Google,
  que pode guardar o que a pessoa escreve.
- **A3, A5, A6 e os menores** → ficam para a T074 (frente do Eduardo, "corrigir o que reprovar").
