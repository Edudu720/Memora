# Fase 1 — Modelo de Tokens: Design System

**Feature**: 002-design-system
**Data**: 2026-07-24

---

## Tokens de cor

Valores validados em `ferramentas/validar_paleta.py`. **51 pares, 3 temas, todos
aprovados.** Alterar qualquer valor exige rodar o validador novamente.

| Token | Papel | Claro | Escuro | Alto contraste |
|---|---|---|---|---|
| `fundo` | Fundo da tela | `#F8F8F8` | `#101216` | `#000000` |
| `superficie` | Cartão, folha, diálogo | `#FFFFFF` | `#1B1E24` | `#000000` |
| `superficie_alt` | Superfície secundária | `#D8D8D8` | `#2A2E36` | `#1A1A1A` |
| `primaria` | Ação principal, identidade | `#1040F8` | `#9CB8FF` | `#8FB4FF` |
| `sobre_primaria` | Texto sobre a primária | `#FFFFFF` | `#06132E` | `#000000` |
| `texto` | Texto principal | `#111111` | `#F2F4F8` | `#FFFFFF` |
| `texto_suave` | Texto de apoio | `#4A4A4A` | `#C2C7D0` | `#E8E8E8` |
| `borda` | Contorno de componente | `#6B6B6B` | `#8A909C` | `#FFFFFF` |
| `sucesso` | Confirmação, êxito | `#186A2E` | `#7CD69A` | `#7BE49B` |
| `perigo` | Ação destrutiva, erro | `#B3231F` | `#FF9B95` | `#FF9E97` |
| `sobre_perigo` | Texto sobre perigo | `#FFFFFF` | `#3A0705` | `#000000` |

**Origem**: `fundo`, `superficie_alt` e `primaria` foram **amostrados do protótipo**
(R1). Os demais foram derivados e ajustados até passarem no validador.

**Removido**: `#7090E8` — 3,07:1 sobre branco, reprova como texto (só aceita texto escuro, 6,15:1, papel que a paleta não precisa). Não existe na paleta.

### Regra de composição

Cor **nunca** carrega significado sozinha (FR-014). `sucesso` e `perigo` sempre
acompanham ícone e texto.

---

## Tokens de tipografia

| Token | Tamanho | Peso | Uso |
|---|---|---|---|
| `titulo_tela` | 32 sp | Bold | Título principal |
| `titulo_secao` | 24 sp | Bold | Agrupamento |
| `corpo` | **18 sp** | Regular | Texto padrão |
| `corpo_forte` | 18 sp | SemiBold | Ênfase |
| `apoio` | 16 sp | Regular | Auxiliar |
| `rotulo_botao` | 18 sp | SemiBold | Dentro de botão |

**Família**: sem serifa (FR-006).
**Piso absoluto**: 16 sp. Nenhum texto menor, em nenhuma circunstância — inclusive
avisos e mensagens auxiliares.

---

## Tokens de espaçamento, raio, elevação e movimento

**Espaçamento** (base 4): `xs`=4 · `sm`=8 · `md`=12 · `lg`=16 · `xl`=24 · `xxl`=32
· `xxxl`=48 · `xxxxl`=64

**Raio**: `padrao`=12 · `cartao`=24 · `pilula`=999
*(A pílula preserva a forma dos botões do protótipo.)*

**Elevação**: `plana`=0 · `cartao`=1 · `flutuante`=3 · `modal`=6
Sombra **nunca** é o sinal principal de que algo é clicável — é invisível em baixa
visão. Forma e cor carregam o sinal.

**Movimento**: `rapido`=120 ms · `padrao`=200 ms · `lento`=320 ms
Toda animação é suprimida quando "reduzir movimento" está ativo (FR-027).

---

## Tokens de dimensão

| Token | Valor | Origem |
|---|---|---|
| `alvo_minimo` | 48 dp | WCAG 2.2 / Android (FR-009) |
| `alvo_decisao` | **56 dp** | Pontos de confirmação (R3) |
| `separacao_alvo` | 8 dp | Mínimo entre alvos |
| `escala_texto_max` | 2.0 | Teto combinado sistema + app (R7) |

---

## Entidade: Preferência de Aparência

Única entidade persistida desta feature.

| Campo | Tipo | Classificação | Regras |
|---|---|---|---|
| `tema` | enum | **Interno** | `sistema`, `claro`, `escuro`, `alto_contraste`. Padrão: `sistema` |
| `escala_texto` | decimal | **Interno** | 1.0 a 2.0. Padrão: 1.0 |
| `idioma` | texto | Interno | Fixo em `pt_BR` nesta fase (D3) |

**Armazenamento**: local e simples. **Não é dado sensível** — não exige
armazenamento seguro, diferente das credenciais da feature 001.

**Nota de privacidade**: a escolha de alto contraste ou de escala máxima permite
inferir deficiência visual. Por isso a preferência **permanece no aparelho** e não é
enviada ao servidor nesta fase.

**Transições**:

```
padrao (tema=sistema, escala=1.0)
  │ pessoa escolhe explicitamente
  ▼
personalizado  ──── "voltar ao padrão" (FR-022, um toque) ────► padrao
```

---

## O que este modelo deliberadamente NÃO tem

- **Cor livre escolhida pela pessoa.** FR-017. Escolha livre quebra a garantia de
  contraste, e quem se prejudica normalmente não identifica a causa.
- **Tema sincronizado entre aparelhos.** Exigiria enviar ao servidor um dado que
  permite inferir condição de saúde. Sem benefício proporcional nesta fase.
- **Tokens por feature.** Um único conjunto serve todo o aplicativo (FR-001). Token
  local é o começo da divergência visual.
