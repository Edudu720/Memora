# Revisão de design — feature 004

Cada revisão registra quem participou, o que foi visto, o veredito e o que
muda. As mudanças viram requisito na `spec.md` e tarefa no `tasks.md`; este
arquivo é o porquê delas.

---

## T044 — Início e Hub (2026-10-01)

**Quem**: Henrique Moreira Sandrini (Scrum Master). **Ainda não participaram**:
Eduardo Juncker Toras e Eduardo Moraes Trevisan — a T044 pede a equipe, e a
revisão deles fica em aberto.

**O que foi visto**: o aplicativo instalado num **Samsung Galaxy S20 FE**
(SM-G781B), em release, tema escuro (o do sistema), contra o simulado. Foi o
estado da `master` depois da #40 — **antes** da fase 3. Ou seja, viu-se a
fundação (fonte, Memora, barra inferior, Hub da 003 ainda com o desenho antigo,
boas-vindas da 001), e não o Início e o Hub novos. Os pontos abaixo valem para
os dois.

### Veredito

**Aprovada a direção, reprovado o acabamento.** Fonte, paleta, personagem e a
barra inferior ficam. O resultado está **junto demais** e **simples demais**
para quem usa — pessoas idosas, que precisam de cada coisa separada e
explicada. Pela regra da T044, a fase 4 só começa depois da R2 revista e das
mudanças abaixo planejadas.

### O que muda

| # | Pedido | Onde vira requisito |
|---|---|---|
| 1 | O ícone do aplicativo no celular é a Memora, um robô, no mesmo estilo das ilustrações de pessoas; o nome é **"Memora"**, com maiúscula | FR-009b |
| 2 | Barra inferior com ícones melhores e acabamento mais cuidado | FR-015 |
| 3 | A primeira tela ocupa a altura toda, sem vazio embaixo | FR-009 |
| 4 | A primeira tela só aparece para quem nunca entrou no aparelho; quem já tem cadastro vê uma tela de volta, com a Memora ou uma pessoa idosa de fundo | FR-009, FR-009a |
| 5 | Tudo muito junto: separar em caixas e explicar com texto o que fazer em cada uma | FR-002a, R2 (regras 8 e 9) |
| 6 | O Hub é simples demais: botões com acabamento refinado | FR-016, R2 (regra 3) |
| 7 | Em "Meus aplicativos", o ícone do aplicativo à esquerda | FR-023 (lista em vez de grade) |
| 8 | O aviso "a Memora nunca pede" menor e removível, sumindo ao mandar mensagem | FR-022, R5 — **ver a decisão abaixo** |
| 9 | Perfil com mais dados: plano, idade | FR-042, FR-042c — **plano fica fora** |
| 10 | Ajustes com mais personalização, inclusive cores | FR-039, R15 |
| 11 | Acessibilidade como foco | FR-038, FR-039a |
| 12 | Enquanto faltar captura de tela num guia, um aviso visível no aplicativo | FR-028a |
| 13 | "Carteira Digital" é o documento do gov.br, não a de trânsito | T080, `data-model.md` |

### Quatro pedidos que esbarravam numa decisão escrita

Perguntados ao Henrique, que decidiu:

- **O aviso encolhe, não some.** Aberto até a primeira mensagem; depois, uma
  linha com escudo, que se toca para ler. Recusado sumir: o golpista pressiona
  a pessoa *durante* a conversa, e "feche esse aviso" é o que ele pediria.
- **Plano não aparece.** A decisão da US9 continua: monetização nunca foi
  discutida, e uma tela de plano prepara para o golpe "seu plano venceu".
- **Idade é opcional**, informada no Perfil, e fica **só no aparelho**. O
  cadastro não muda, e o servidor não ganha dado novo.
- **Cores em paletas prontas**, cada combinação validada por contraste. Cor
  livre está fora.

### Em aberto

- A revisão dos dois Eduardos.
- **Rever o Início e o Hub novos**: realizada pelo Henrique via APK no celular em 2026-10-14 (ver abaixo).

---

## T116 — Segunda rodada: Início e Hub novos no aparelho real (2026-10-14)

**Quem**: Henrique Moreira Sandrini (Scrum Master).

**O que foi visto**: o aplicativo instalado no celular físico via APK com as telas novas da Fase 3/3b integradas (Início com a Memora e caixas de tutorial, Hub com acabamento refinado das portas, ícones da barra inferior, redução de respiro dinâmico).

### Veredito

**Aprovado.** As telas do Início e do Hub cumprem o acabamento e a linguagem visual definidos. O portão do merge está liberado para prosseguir com a implementação das fases seguintes no Spec-Kit.

