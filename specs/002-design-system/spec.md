# Especificação de Funcionalidade: Design System

**Feature Branch**: `feature/002-design-system`

**Created**: 2026-07-24

**Status**: Draft — aguardando clarificações

**Input**: Sistema de design do Memora — tokens, componentes e temas — derivado das
38 telas do protótipo em `docs/design/prototipo/`, sob os princípios da
[Constituição](../../.specify/memory/constitution.md).

---

## Por que esta feature existe

O Design System **não é infraestrutura invisível**. Para este público, ele é o
produto: é o que determina se a Dona Ana enxerga o texto, acerta o botão e entende
o que é clicável.

Ele também é **dependência bloqueante** da feature 001 — não há como construir telas
acessíveis sem tokens validados na origem.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Distinguir o que é botão do que é informação (Priority: P1)

Dona Ana abre a tela de perfil. Ela vê o nome, a idade e o e-mail dela — e entende
imediatamente que **aquilo é informação**, não algo para tocar. Quando existe um
botão de verdade na tela, ele parece diferente de tudo o mais.

**Why this priority**: no protótipo atual, os dados do perfil são exibidos como
pílulas azuis **idênticas aos botões do Hub**. A pessoa não tem como saber o que
responde ao toque. É a falha de affordance mais grave encontrada na análise, e ela
se repete em qualquer tela que misture dado e ação.

**Independent Test**: mostrar a tela de perfil a uma pessoa de 65+ anos e pedir que
aponte o que ela acha que é clicável. Nenhum campo de informação deve ser apontado.

**Acceptance Scenarios**:

1. **Given** uma tela com dados e ações, **When** eu olho para ela, **Then** ações e
   informações têm forma visual claramente distinta.
2. **Given** que toco em algo clicável, **When** o toque é registrado, **Then**
   recebo retorno visual imediato.
3. **Given** um elemento que não é clicável, **When** eu toco nele, **Then** nada
   acontece e nada sugere que deveria acontecer.

---

### User Story 2 - Ler tudo com a letra do meu tamanho (Priority: P1)

Dona Ana aumentou a fonte do celular porque enxerga pouco. Ao abrir o Memora, todo
texto acompanha esse aumento — e nada some, corta ou se sobrepõe.

**Why this priority**: aumentar a fonte do sistema é a **primeira** coisa que uma
pessoa com baixa visão faz no aparelho. Um aplicativo que quebra nessa condição é
inutilizável justamente para quem mais precisa dele.

**Independent Test**: percorrer todas as telas com o texto do sistema em 200% e
verificar que nenhum conteúdo é perdido.

**Acceptance Scenarios**:

1. **Given** que ampliei o texto do sistema em 200%, **When** abro qualquer tela,
   **Then** todo o conteúdo permanece legível e alcançável.
2. **Given** que um texto ficou maior que o espaço, **When** a tela é desenhada,
   **Then** o espaço se adapta ao texto — o texto nunca é cortado.
3. **Given** qualquer tamanho de texto, **When** toco em um botão, **Then** a área
   de toque nunca fica menor que o mínimo acessível.

---

### User Story 3 - Deixar o aplicativo do meu jeito, sem estragar a leitura (Priority: P2)

Dona Ana entra nas configurações e muda o tema e o tamanho da letra do Memora. Ela
escolhe entre opções prontas, todas legíveis. **Não existe combinação possível que
deixe o texto ilegível.**

**Why this priority**: o protótipo promete *"Mexa como quiser"* com botões de Cores,
Temas e Fontes. A intenção é ótima — dá autonomia. Mas liberdade total de cor
**quebra a garantia de contraste**: a pessoa pode escolher amarelo sobre branco e
tornar o app inutilizável, sem entender por quê e sem saber voltar.

A resolução é oferecer **escolha entre opções curadas**, todas pré-validadas. A
pessoa mantém a sensação de personalizar; o sistema mantém a garantia de leitura.

**Independent Test**: percorrer todas as combinações oferecidas e verificar que
todas passam no contraste mínimo.

**Acceptance Scenarios**:

1. **Given** que estou nas configurações, **When** escolho um tema, **Then** ele é
   aplicado imediatamente em todo o aplicativo.
2. **Given** qualquer tema disponível, **When** ele é aplicado, **Then** todo texto
   continua atendendo ao contraste mínimo.
3. **Given** que mudei alguma configuração, **When** fecho e reabro o aplicativo,
   **Then** minha escolha foi preservada.
4. **Given** que me perdi nas configurações, **When** procuro voltar ao padrão,
   **Then** encontro essa opção com clareza e ela funciona em um toque.

---

### User Story 4 - Sentir que é sempre o mesmo aplicativo (Priority: P2)

Dona Ana navega do Hub para o Chatbot e para as configurações. Tudo parece do mesmo
lugar: mesmas cores, mesma letra, botões que se comportam igual.

**Why this priority**: o protótipo tem hoje **duas linguagens visuais concorrentes**
— telas de entrada em azul com cartões brancos, contra Hub e Chatbot em cinza com
fonte serifada. Para quem tem pouca familiaridade digital, mudança visual brusca é
lida como "saí do aplicativo" ou "algo deu errado" — e é exatamente o sinal que
golpistas exploram.

**Independent Test**: percorrer o aplicativo inteiro e verificar que nenhuma tela
usa cor, fonte ou componente fora do sistema.

**Acceptance Scenarios**:

1. **Given** que navego entre quaisquer duas telas, **When** comparo as duas,
   **Then** ambas usam a mesma família tipográfica e a mesma paleta.
2. **Given** um botão em qualquer tela, **When** comparo com outro botão de mesma
   função, **Then** eles têm aparência e comportamento idênticos.

---

### User Story 5 - Construir telas sem reinventar componentes (Priority: P3)

Quem desenvolve monta uma tela nova compondo peças que já existem, sem escolher cor
nem tamanho na mão.

**Why this priority**: é o que garante que as histórias 1 a 4 continuem valendo
depois da terceira pessoa mexer no código. Sem isso, a consistência se degrada a
cada tela nova. Está em P3 porque serve às anteriores, não ao usuário final direto.

**Independent Test**: montar uma tela nova sem escrever nenhum valor de cor,
espaçamento ou tamanho literal.

**Acceptance Scenarios**:

1. **Given** que construo uma tela, **When** preciso de um botão, **Then** existe um
   componente pronto que já atende contraste, área de toque e leitor de tela.
2. **Given** que alguém escreve um valor de cor literal, **When** o projeto é
   verificado, **Then** isso é detectado automaticamente.

---

### Edge Cases

- **Texto do sistema em 200% com nome longo**: o layout cresce, nada é cortado.
- **Aparelho em modo escuro do sistema**: o aplicativo acompanha, salvo escolha
  explícita da pessoa.
- **Tela muito pequena ou de baixa densidade**: área de toque mínima é preservada
  mesmo que caibam menos elementos.
- **Pessoa escolhe tema e depois muda o tema do sistema**: a escolha explícita dela
  prevalece.
- **Texto em outro idioma, mais longo que o português**: o layout acomoda sem quebrar.
- **Animação com "reduzir movimento" ativado**: animações são suprimidas.
- **Ícone sem texto**: não deve existir. Se aparecer, é defeito.

---

## Requirements *(mandatory)*

### Tokens — Fundamentos

- **FR-001**: O sistema MUST definir **um único** conjunto de tokens de cor,
  tipografia, espaçamento, raio, elevação e movimento.
- **FR-002**: Nenhum valor visual literal MUST aparecer fora dos tokens.
- **FR-003**: Todo par de cores previsto para texto sobre fundo MUST ser validado
  em contraste **na definição do token**, não na tela.
- **FR-004**: Todo token MUST ter valor definido para tema claro e para tema escuro.
- **FR-005**: A escala tipográfica MUST partir de um tamanho base **maior** que o
  padrão de aplicativos comuns, adequado ao público idoso.
- **FR-006**: A família tipográfica MUST ser sem serifa.
  *(Corrige a fonte serifada usada no Chatbot do protótipo — pior legibilidade em
  baixa visão.)*
- **FR-007**: O espaçamento MUST seguir uma escala regular, sem valores avulsos.

### Componentes

- **FR-008**: O sistema MUST fornecer, no mínimo: botões, campos de texto, cartões,
  diálogos, folhas inferiores, barra superior, navegação inferior, ícones,
  indicadores de carregamento e mensagens de erro.
- **FR-009**: Todo componente interativo MUST garantir área de toque mínima de
  48x48 dp, com 8 dp de separação — **por construção**, não por configuração de quem
  usa.
- **FR-010**: Todo componente interativo MUST expor rótulo e estado a leitores de tela.
- **FR-011**: Todo componente interativo MUST ter aparência distinta nos estados
  normal, foco, pressionado, carregando, desabilitado e erro.
- **FR-012**: O sistema MUST oferecer componentes **visualmente distintos** para
  exibir informação e para disparar ação.
  *(Corrige os campos do Perfil com aparência idêntica aos botões do Hub.)*
- **FR-013**: Botões de ação destrutiva ou irreversível MUST ser visualmente
  distintos e MUST NOT ficar adjacentes a botões de ação comum.
  *(Corrige os botões SIM/NÃO lado a lado do Chatbot.)*
- **FR-014**: Componentes de escolha MUST comunicar a opção por texto e forma, nunca
  apenas por cor.
- **FR-015**: Nenhum componente MUST depender de gesto complexo. Toque simples
  sempre basta.
- **FR-016**: Todo ícone MUST vir acompanhado de rótulo textual visível.
  *(Corrige a navegação inferior do protótipo, hoje só com ícones.)*

### Temas e Personalização

- **FR-017**: O sistema MUST oferecer temas **pré-definidos e validados**, e MUST NOT
  permitir escolha livre de cor.
- **FR-018**: Toda combinação oferecida MUST atender ao contraste mínimo — não pode
  existir escolha que torne o texto ilegível.
- **FR-019**: O sistema MUST permitir ajustar o tamanho do texto **dentro do
  aplicativo**, adicionalmente ao ajuste do sistema operacional.
- **FR-020**: O sistema MUST seguir o tema claro ou escuro do aparelho por padrão, e
  MUST respeitar escolha explícita da pessoa acima disso.
- **FR-021**: As preferências MUST persistir entre usos.
- **FR-022**: O sistema MUST oferecer retorno ao padrão, alcançável em um toque.
- **FR-023**: Toda mudança de aparência MUST ser aplicada imediatamente, com
  pré-visualização antes de confirmar.

### Acessibilidade

- **FR-024**: Contraste mínimo de 4.5:1 para texto normal e 3:1 para texto grande,
  ícones e bordas de componente.
- **FR-025**: Todo componente MUST permanecer utilizável com texto ampliado até 200%.
- **FR-026**: Nenhum contêiner MUST usar altura fixa que impeça o texto de crescer.
- **FR-027**: O sistema MUST respeitar a preferência de **redução de movimento**.
- **FR-028**: Animações MUST ser curtas e MUST NOT ser necessárias para compreender
  a interface.
- **FR-029**: A ordem de leitura por leitor de tela MUST seguir a ordem visual.

### Verificação

- **FR-030**: A conformidade de contraste MUST ser verificada **automaticamente**, e
  MUST falhar a verificação do projeto quando violada.
- **FR-031**: A área de toque MUST ser verificada automaticamente.
- **FR-032**: O uso de valor visual literal fora dos tokens MUST ser detectado
  automaticamente.
- **FR-033**: Todo componente MUST ter exemplo visual navegável, servindo de
  documentação viva.

---

### Key Entities

- **Token**: menor unidade de decisão visual. Possui nome, categoria e valor por
  tema.
- **Tema**: conjunto coerente e validado de valores de token. Possui nome legível,
  variante clara e escura, e resultado de validação de contraste.
- **Componente**: peça reutilizável de interface. Possui estados, rótulos
  semânticos e garantias de acessibilidade embutidas.
- **Preferência de Aparência**: escolhas da pessoa — tema, tamanho de texto e
  idioma. Pertence à pessoa e persiste entre usos.

---

## Success Criteria *(mandatory)*

- **SC-001**: 100% dos pares de cor de texto sobre fundo passam no contraste mínimo,
  verificado automaticamente.
- **SC-002**: 100% dos componentes interativos atendem à área de toque mínima.
- **SC-003**: 100% das telas permanecem utilizáveis com texto a 200%.
- **SC-004**: Zero valores visuais literais fora dos tokens, verificado
  automaticamente.
- **SC-005**: 100% dos componentes interativos expõem rótulo e estado a leitor de tela.
- **SC-006**: Em teste com pessoas de 65+ anos, **nenhuma** aponta um campo de
  informação como se fosse clicável.
- **SC-007**: Nenhuma combinação de tema e tamanho de texto disponível produz
  contraste abaixo do mínimo.
- **SC-008**: Uma tela nova é construída sem escrever nenhum valor visual literal.
- **SC-009**: Toda ação irreversível é distinguível de ação comum em teste com
  usuários.

---

## Assumptions

- O aplicativo é Android; o comportamento segue as convenções da plataforma.
- Os tokens derivam da **intenção visual** do protótipo, não de valores exatos: as
  cores foram amostradas de imagem, não extraídas do Figma. Ver **Q1**.
- Onde o protótipo conflita com acessibilidade, **a acessibilidade vence** — e a
  divergência é registrada.
- Múltiplos idiomas estão **fora de escopo** nesta feature, mas o sistema não deve
  impedir sua adição. O botão "Idiomas" do protótipo depende de **Q3**.
- Nenhum dado pessoal trafega nesta feature; ela não possui superfície de ataque
  própria além da persistência local de preferências.

---

## Threat Model *(obrigatório — Princípio I)*

Esta feature **não processa dado pessoal nem credencial**. A superfície de risco é
indireta, mas existe.

| Dado | Classificação | Observação |
|---|---|---|
| Preferência de aparência | **Interno** | Revela deficiência visual, se exposta |

| Ameaça | Impacto | Mitigação |
|---|---|---|
| Combinação de tema torna a interface ilegível | Pessoa perde acesso ao app e não sabe reverter | FR-017, FR-018, FR-022 |
| Componente sem rótulo semântico | Leitor de tela inutilizável | FR-010, FR-030 |
| Componente novo fora do sistema | Erosão silenciosa da acessibilidade | FR-032, FR-030 |
| Preferência de aparência exposta a terceiros | Inferência sobre saúde da pessoa | Preferência permanece local |

---

## Análise de Engenharia Social *(obrigatório — Princípio II)*

> **"Como um golpista exploraria a aparência do aplicativo?"**

| Vetor | Por que funciona | Contramedida |
|---|---|---|
| Tela falsa imitando o Memora | A pessoa reconhece o app pela aparência, não pela origem | FR-001 e FR-017 — identidade visual consistente e limitada torna a imitação mais difícil de acertar e a divergência mais perceptível |
| Mudança visual brusca entre telas | Ensina a pessoa que "mudar de cara" é normal — e ela deixa de estranhar uma tela falsa | US4, FR-001 |
| Botão perigoso parecendo botão comum | A pessoa confirma algo grave achando que era rotina | FR-013 |
| Ícone sem rótulo interpretado errado | A pessoa aciona o que não queria | FR-016 |

---

## Perguntas em Aberto

### Q1: Como obtemos os valores visuais reais?

**Contexto**: as cores atuais foram amostradas de PNG dentro do `.docx`. Compressão
de imagem altera pixel — os valores são aproximados. Como os tokens são a base de
tudo, errar aqui se propaga para o aplicativo inteiro.

| Opção | Resposta | Implicações |
|---|---|---|
| A | **Exportar tokens do Figma** | Valores exatos de cor, tipografia e espaçamento. Requer alguém com acesso ao arquivo |
| B | **Liberar o link do Figma** | Eu extraio diretamente. Reversível depois |
| C | **Derivar das imagens e validar** | Sem dependência externa. Os tokens serão *inspirados* no protótipo, com contraste corrigido. O resultado diverge visualmente do Figma |

### Q2: Quantos temas oferecer?

**Contexto**: a FR-017 proíbe escolha livre de cor. Resta definir o tamanho do
cardápio — cada tema adicional multiplica a matriz de validação e de teste.

| Opção | Resposta | Implicações |
|---|---|---|
| A | **Claro e escuro apenas** | Mínimo viável, validação simples. Menor sensação de personalização que o protótipo promete |
| B | **Claro, escuro e alto contraste** | Atende quem tem baixa visão severa. Recomendado |
| C | **Quatro ou mais variações de cor** | Mais próximo do "Mexa como quiser". Custo de validação cresce em cada combinação |

### Q3: O botão "Idiomas" entra agora?

**Contexto**: o protótipo exibe "Idiomas" nas configurações de acessibilidade. Não
há requisito de múltiplos idiomas em nenhum documento do projeto.

| Opção | Resposta | Implicações |
|---|---|---|
| A | **Fora de escopo; preparar a estrutura** | O sistema fica pronto para receber idiomas, mas só português é entregue. O botão sai da tela por ora |
| B | **Entregar português e mais um idioma** | Cumpre a promessa do protótipo. Aumenta o escopo de tradução e de teste de layout |

---

## Dependências

- **Bloqueia** a implementação da feature 001 e de todas as seguintes.
- Depende de **Q1** para os valores definitivos dos tokens.
- Não depende de backend, banco ou rede.
