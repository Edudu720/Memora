# Fase 0 — Pesquisa: Design System

**Feature**: 002-design-system
**Data**: 2026-07-24

---

## R1 — Derivação da paleta a partir do protótipo

**Método**: amostragem programática de **2.962.440 pixels** em 36 telas
(`ferramentas/amostrar_cores.py`), seguida de validação de contraste WCAG 2.2
(`ferramentas/validar_paleta.py`).

### O que a amostragem encontrou

| Cor | Ocorrência | Papel no protótipo | Contraste |
|---|---|---|---|
| `#F8F8F8` | 33,37% | Fundo | — |
| `#D8D8D8` | 12,37% | Superfície de cartão | 14,73:1 com texto preto |
| `#1040F8` | 3,76% | **Cor primária** | **6,75:1** com texto branco ✅ |
| `#78B8D8` | 0,68% | Balão do chat | 9,64:1 com texto preto ✅ |
| `#7090E8` | 0,10% | Azul claro | **3,07:1** ❌ reprova |

**Decisão**: manter `#1040F8` como cor primária e `#D8D8D8` como superfície. **A
identidade visual do Memora é preservada** — ela já atende à WCAG.

**Descartado**: `#7090E8` não pode carregar texto (3,07:1). Não entra na paleta.

**Rationale**: a expectativa inicial era de que a paleta do protótipo precisasse ser
substituída. A medição desmentiu. Corrigir o que não está quebrado seria
descaracterizar o projeto sem ganho.

### Paleta final validada

**48 pares testados nos três temas. Todos aprovados.** Ver
`ferramentas/validar_paleta.py` para os valores e a verificação reproduzível.

Margens mais apertadas (as que exigem atenção em qualquer alteração futura):

| Par | Tema | Resultado | Exigido |
|---|---|---|---|
| primária sobre superfície_alt | claro | 4,74:1 | 3:1 |
| borda sobre fundo | claro | 5,02:1 | 3:1 |
| perigo sobre fundo | claro | 6,22:1 | 4,5:1 |

---

## R2 — O defeito dos botões SIM/NÃO, medido

Medição direta da tela de Chatbot (`ferramentas/medir_botoes.py`):

| Botão | Cor | Tamanho | Contraste com texto preto |
|---|---|---|---|
| SIM | `#9EEE7E` | **77×24 px** | 14,98:1 ✅ |
| NÃO | `#E87B7B` | **77×24 px** | 7,55:1 ✅ |
| Separação | — | 62 px | ✅ adequada |

### Correção de uma avaliação anterior

A análise inicial afirmou que esses botões reprovavam em contraste. **Estava
errada** — era impressão visual, não medição. Ambos passam, inclusive no nível AAA.

**O defeito real é a altura: 24 px contra 48 dp exigidos — exatamente metade.**

*(Premissa: a tela do protótipo tem 390 px de largura, compatível com um quadro de
390 dp em densidade 1x, então px ≈ dp. Se o protótipo tiver sido exportado em outra
densidade, a proporção se mantém: a altura é metade da largura mínima de alvo.)*

**Registro para a defesa**: este é um bom exemplo do valor de medir em vez de opinar.
Um dos dois problemas que eu apontei não existia; o outro é pior do que parecia.

---

## R3 — Componente de confirmação (substitui SIM/NÃO)

**Problema**: além da altura, os dois botões têm **peso visual idêntico** e ficam
lado a lado. Num fluxo em que a assistente pede autorização para agir, isso viola o
Princípio VI — a confirmação precisa ser deliberada, não um toque entre dois iguais.

**Decisão**: componente `ConfirmacaoMemora`, com:

- **Empilhamento vertical**, largura total. Elimina a escolha por proximidade
  horizontal, que é onde o toque acidental acontece.
- **Altura mínima de 56 dp** — acima do mínimo de 48, porque este é um ponto de
  decisão e o público tem menor precisão motora.
- **Hierarquia explícita**: a ação confirmatória é preenchida e proeminente; a
  recusa é contornada e secundária — mas nunca escondida nem apagada.
- **Rótulos completos**: *"Sim, pode abrir"* e *"Agora não"*, em vez de "SIM" e
  "NÃO". Palavra isolada exige que a pessoa lembre a pergunta.
- **Ícone + texto**, nunca só cor (FR-014).

**Variante para ação irreversível** (FR-013): a ação destrutiva aparece **abaixo**,
separada por espaçamento maior, com cor de perigo e exigindo segunda confirmação.

**Rationale**: o protótipo acertou ao dar duas opções claras. Errou ao torná-las
equivalentes e pequenas. A correção preserva a intenção e remove o risco.

---

## R4 — Tipografia

**Decisão**: família **sem serifa**, com escala partindo de **18 sp** para texto de
corpo — acima do padrão de 14–16 sp de aplicativos comuns.

| Papel | Tamanho base | Peso |
|---|---|---|
| Título de tela | 32 sp | Bold |
| Título de seção | 24 sp | Bold |
| Corpo | **18 sp** | Regular |
| Corpo forte | 18 sp | SemiBold |
| Apoio | 16 sp | Regular |
| Rótulo de botão | 18 sp | SemiBold |

**Mínimo absoluto: 16 sp.** Nenhum texto do aplicativo pode ser menor — inclusive
avisos legais e mensagens auxiliares, que são justamente onde interfaces costumam
encolher a fonte.

**Corrige**: a fonte serifada do Chatbot do protótipo (FR-006). Serifa reduz
legibilidade em baixa visão e em telas de baixa densidade.

---

## R5 — Espaçamento, raio e elevação

**Escala de espaçamento** (base 4): 4, 8, 12, 16, 24, 32, 48, 64. Nenhum valor fora
da escala.

**Raio**: 12 (padrão), 24 (cartão), 999 (pílula — a forma dos botões do protótipo).

**Elevação**: usada com parcimônia. Sombra não é o sinal principal de que algo é
clicável — forma e cor são. Sombra sozinha é invisível para quem tem baixa visão.

---

## R6 — Arquitetura dos tokens no Flutter

**Decisão**: `ThemeExtension` tipada, exposta por um único ponto de acesso.

**Rationale**: o `ColorScheme` padrão do Material não comporta nossos papéis
semânticos (`superficie_alt`, `sucesso`, `perigo`, `sobre_perigo`) sem distorção.
`ThemeExtension` dá segurança de tipo — um token inexistente **não compila**.

**Regra derivada (FR-002)**: nenhum widget de feature acessa valor literal. Toda cor
e todo espaçamento vêm do tema.

---

## R7 — Escala de texto: sistema e aplicativo

**Decisão**: respeitar `MediaQuery.textScaler` do sistema **e** oferecer ajuste
próprio dentro do app (FR-019), multiplicando os dois.

**Limite superior**: escala combinada limitada a 2,0. Sem teto, o layout quebra em
casos extremos e a pessoa fica sem saída.

**Consequência de projeto**: nenhum contêiner com altura fixa (FR-026). Layouts
usam altura mínima e crescem com o conteúdo. É a causa nº 1 de quebra em escala
grande.

---

## R8 — Verificação automatizada

**Decisão**: três portões, todos capazes de falhar o build.

| Portão | Ferramenta | Verifica |
|---|---|---|
| Contraste | `ferramentas/validar_paleta.py` | 48 pares nos 3 temas (FR-030) |
| Área de toque e semântica | `flutter_test` com `meetsGuideline` | 48 dp e rótulos (FR-031, FR-010) |
| Valor literal | regra de análise estática | Cor ou espaçamento fora dos tokens (FR-032) |

**Rationale**: a Constituição exige 100% de conformidade (SC-001 a SC-005). Isso só
sobrevive a refatoração se estiver automatizado. Revisão manual degrada.

O validador de paleta **já está escrito e passando** — é executável hoje, antes de
existir qualquer código Flutter.

---

## R9 — Galeria de componentes

**Decisão**: uma tela de galeria dentro do próprio aplicativo, acessível apenas em
build de desenvolvimento, exibindo todos os componentes em todos os estados e nos
três temas (FR-033).

**Rationale**: alternativas como Storybook adicionam dependência e um segundo
ambiente de execução. Uma tela interna roda no mesmo motor de renderização do app
real — o que se vê é o que o usuário vê. Também serve de checklist visual na revisão
de PR.

---

## R10 — Internacionalização sem múltiplos idiomas

**Decisão**: todo texto passa pela camada de i18n desde já, mesmo havendo apenas
português (FR-036).

**Rationale**: custo marginal agora, custo alto depois. Extrair strings de um app
pronto é retrabalho garantido. E força uma disciplina útil: texto fica fora do
widget, o que facilita revisar a persona da Memora em um só lugar.

**O botão "Idiomas" sai da tela de configurações** enquanto houver um idioma só
(FR-037). Oferecer opção que não faz nada confunde o público e desgasta a confiança.

---

## Incógnitas resolvidas

| Incógnita | Resolvida em |
|---|---|
| Valores reais da paleta | R1 |
| Gravidade real dos botões SIM/NÃO | R2 |
| Como substituir a confirmação | R3 |
| Escala tipográfica | R4 |
| Espaçamento, raio, elevação | R5 |
| Estrutura dos tokens | R6 |
| Escala de texto | R7 |
| Verificação automatizada | R8 |
| Documentação viva | R9 |
| Estratégia de i18n | R10 |

**Nenhuma incógnita aberta.** Liberado para a Fase 1.
