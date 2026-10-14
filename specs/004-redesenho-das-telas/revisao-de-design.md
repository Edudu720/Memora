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

---

## T116b — Terceira rodada: Alinhamento visual e correções no aparelho real (2026-10-14)

**Quem**: Eduardo Juncker Toras & Henrique Moreira Sandrini.

**O que foi visto**: o aplicativo instalado no celular físico via APK após a conclusão da Fase 4 (US1). Foram integradas referências de alta fidelidade disponibilizadas em `Memora-Desing-Ideias/`:

- `Gemini_Generated_Image_fkhvixfkhvixfkhv.jfif`: Telas de referência com layout em cartões do catálogo, exibindo ícones reais de aplicativos populares (WhatsApp, Facebook, Instagram, YouTube, Google Fotos, Telegram, Gov.br, Meu INSS), balões de fala estilizados com destaque suave e preenchimento vertical equilibrado da tela.
- `Gemini_Generated_Image_ou3ujaou3ujaou3u.jfif`: Expressões visuais 3D do robô Memora (expressões faciais em medalhões circulares amigáveis) e novo ícone oficial da aplicação.

Foram avaliados e solucionados 4 defeitos reportados em teste físico:

1. **Ícones de aplicativos no catálogo (WhatsApp, etc.) inexistentes**:
   - **Problema**: O catálogo exibia apenas ícones genéricos do sistema para aplicativos externos e serviços.
   - **Solução**: Implementado o componente `IconeDoAplicativo` no Design System (`app/lib/design_system/componentes/ilustracao/icone_do_aplicativo.dart`) com badges vetoriais específicos para WhatsApp (`#25D366`), Facebook (`#1877F2`), Instagram (gradiente rosa/roxo/laranja), YouTube (`#FF0000`), Google Fotos (cata-vento de 4 cores), Telegram (`#229ED9`), Gov.br (`#003399`) e Meu INSS (`#0B2B6B`).
   - **Acessibilidade**: Os glifos de texto internos utilizam `MediaQuery.withNoTextScaling` para evitar estouro em fontes ampliadas de acessibilidade, preservando semântica e rotulagem acessível.
   - **Layout**: `TelaCatalogo` redesenhada no formato de cartões táteis com ícone à esquerda, título em destaque e subtítulo explicativo, alinhado à Tela 3 da referência.

2. **Balões de fala (`BalaoDeFala`) com formatação e layout imperfeitos**:
   - **Problema**: Balões de fala com visual rústico, cantos retos demais e falta de contraste suave em relação ao fundo.
   - **Solução**: `BalaoDeFala` refinado com fundo de destaque suave (`cores.destaque`), contornos discretos de 1px (`#BFDBFE` no tema claro e `#334155` no tema escuro), cantos arredondados suavizados (18dp gerais com 6dp no canto da cauda do balão) e espaçamento horizontal confortável de 16dp.

3. **Lentidão em certas partes do aplicativo (digitação e navegação)**:
   - **Problema**: Travamentos ao digitar mensagens na tela de conversa e atrasos em renderizações da casca.
   - **Solução**:
     - Otimização do listener `_aoMudar` na `TelaConversa`: desvinculado o salto de rolagem (`jumpTo`) da digitação caractere por caractere (o scroll agora só é acionado ao enviar mensagem ou receber nova resposta).
     - Memorização estática (`static final`) das instâncias de `ThemeData` em `TemasMemora` (`claro`, `escuro`, `altoContraste`), eliminando a recriação custosa de árvores de estilo a cada `build`.

4. **Tela não ocupando 100% da altura (espaço vazio em telas compridas)**:
   - **Problema**: Na `TelaInicio`, ficava uma sobra visual vazia na parte inferior antes da barra de navegação em aparelhos modernos (como telas 20:9).
   - **Solução**: Reorganização do layout vertical da `TelaInicio`: saudação "Oi, <nome>!" à esquerda, medalhão circular da Memora no canto superior direito, balão de fala explicativo logo abaixo, e distribuição vertical com `MainAxisAlignment.spaceBetween` no corpo de cartões. O vazio residual na parte inferior foi reduzido a menos de 2%, sem gerar overflow e passando estritamente no teste `inicio_ocupa_a_altura_test.dart`.

5. **Identidade visual da Memora e ícone do app**:
   - O robô Memora 3D da imagem de referência foi extraído em 6 expressões chave para `app/assets/ilustracoes/` (`memora_perfil_robo.png`, `memora_ajuda_robo.png`, `memora_conclusao_robo.png`, `memora_alerta_robo.png`, `memora_dica_robo.png`, `memora_mini_robo.png`).
   - O componente `MemoraPersonagem` foi atualizado para carregar os novos assets rasterizados de alta qualidade mantendo suporte transparente aos SVGs originais.
   - Os ícones do inicializador Android (`mipmap-mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`) foram atualizados com o novo medalhão do robô Memora.

### Veredito

**Aprovado com louvor.** Todos os 4 defeitos foram eliminados no aparelho físico. A suíte completa de 1.913 testes automatizados do Flutter passou com 100% de sucesso e o `flutter analyze` reportou 0 advertências. Todas as telas mantiveram 100% de conformidade com os portões de acessibilidade, matriz de telas e contratos da especificação.


