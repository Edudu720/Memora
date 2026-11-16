# Modelo de dados — feature 010

Nenhum dado novo é persistido, e nada vai ao servidor. As entidades abaixo são
**estado de interface**, vivem só na memória enquanto a tela existe.

---

## ExpressaoDaMemora (existente, ampliada)

O enum de hoje (`neutra`, `falando`, `comemorando`, `preocupada`, e na #71
também `dica` e `mini`) **continua com os mesmos valores**, para que nenhuma
tela precise mudar. O que muda é o que cada valor desenha.

| Valor | Pose 2.5D | Onde aparece |
|---|---|---|
| `neutra` | repouso: braços baixos, olhos abertos, leve "respiração" | cabeçalhos, Início |
| `falando` | boca/visor pulsando, um braço gesticula | balões, conversa |
| `pensando` *(novo)* | cabeça inclinada, mão no queixo | ajuda, "Estou pensando" da conversa |
| `comemorando` | braços para cima, salto curto | conclusões |
| `preocupada` | escudo à frente, olhos atentos | avisos de segurança |
| `acenando` *(novo)* | braço direito acenando | abertura, boas-vindas |
| `dica` *(da #71)* | segura um livro ou cartão | dicas, aprendizado |
| `mini` *(da #71)* | só a cabeça | lugares pequenos (cabeçalho da conversa) |

**Regra**: cada valor tem uma **pose parada** (usada com "reduzir movimento") e,
quando aplicável, uma **animação de entrada** e um **ciclo** (respiração, fala).

## GestoDaMemora (novo)

Animação curta e única disparada por um evento.

| Gesto | Disparado por | Duração-alvo | Com "reduzir movimento" |
|---|---|---|---|
| `aceno` | toque nela; entrada da abertura | ~1,2 s | não acontece |
| `piscada` | toque nela (alternado com o aceno) | ~0,3 s | não acontece |
| `comemoracao` | conclusão de um passo a passo | ~1,0 s, uma vez | pose `comemorando` parada |

**Estados**: `ocioso` → `emGesto` → `ocioso`. Toque em `emGesto` é ignorado
(spec, caso de borda "toques repetidos").

## DirecaoDaTransicao (novo)

| Valor | Entra por | Sai por |
|---|---|---|
| `avancar` | direita | esquerda (paralaxe ~30%) |
| `voltar` | esquerda | direita |
| `sobrepor` | baixo (folha) ou centro (diálogo) | — (a de trás não se move) |
| `destino` | lado relativo à posição na barra inferior | lado oposto |

Com "reduzir movimento", toda direção vira troca instantânea com esmaecer curto.

## BlocoDeTexto (conceitual, para o portão)

Uma constante de texto da interface. **Validação** (portão R6):
- no máximo 2 frases;
- nenhuma palavra ou frase proibida (memora-ux, seção 4);
- nenhum emoji, a menos que seja fala da IA.

## EstadoDaAbertura (novo)

`carregando` → (`pronto` **e** aceno concluído) → `saindo` → fluxo de
autenticação. Ramos: `demorando` (passou de 4 s: mostra a frase) e `falhou`
(vai à tela de erro).
