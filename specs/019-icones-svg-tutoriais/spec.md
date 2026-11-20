# Feature Specification: Ícones SVG para e-Título, FGTS e Instagram (Item 13)

**Feature Branch**: `feature/019-icones-svg-tutoriais`
**Created**: 2026-11-20
**Status**: Draft
**Input**: User description: "Item 13 da Issue #106: Criar ícones vetoriais SVG próprios e reconhecíveis para os tutoriais e-Título, FGTS e Instagram no padrão combinado (`app/assets/icones_apps/<chave>.svg`, `viewBox=\"0 0 48 48\"`) e ligá-los ao `IconeDoAplicativo` substituindo desenhos manuais anteriores."

## Clarifications

### Session 2026-11-20

- Q: Como o `IconeDoAplicativo` deve ajustar o preenchimento dos novos SVGs dentro da moldura quadrada arredondada? → A: Preencher toda a caixa `tamanho × tamanho` (`BoxFit.cover`) com `excludeFromSemantics: true`, eliminando filetes vazios nas bordas ao escalar.
- Q: Os novos arquivos SVG em `app/assets/icones_apps/` precisam de registro de origem/licença? → A: Sim; registrar as três artes vetoriais próprias criadas para reconhecimento visual de catálogo em `app/assets/ilustracoes/LICENCAS.md`.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Exibir ícones SVG nítidos e reconhecíveis para e-Título, FGTS e Instagram (Priority: P1)

Como pessoa usuária navegando no catálogo, atalhos ou seletor de seções do Memora, quero enxergar ícones vetoriais nítidos e imediatamente reconhecíveis para **e-Título**, **FGTS** e **Instagram** em qualquer densidade de tela e ampliação de fonte, para identificar cada aplicativo pelo formato e cores familiares antes de tocar.

**Why this priority**: A skill `memora-ux` exige ícones vetoriais nítidos em qualquer tamanho em vez de formas genéricas ou desenhos improvisados, e a Issue #106 padronizou `app/assets/icones_apps/<chave>.svg` entre os colaboradores.

**Independent Test**: Renderizar `IconeDoAplicativo` para as chaves `e-titulo`, `fgts` e `instagram` em diferentes tamanhos (`48`, `64`, `96`) e nos 3 temas visuais (`claro`, `escuro`, `altoContraste`), comprovando o carregamento de `SvgPicture` correspondente a cada asset SVG.

**Acceptance Scenarios**:

1. **Given** os três arquivos vetoriais (`e-titulo.svg`, `fgts.svg`, `instagram.svg`) estão declarados nos ativos do aplicativo, **When** qualquer tela renderiza `IconeDoAplicativo` para `'e-titulo'`, `'fgts'` ou `'instagram'` (ou variações de nome equivalentes), **Then** o componente exibe o vetor SVG correspondente nítido dentro da moldura arredondada padrão.
2. **Given** os demais aplicativos do catálogo ainda pertencem a outra frente (Item 6 / spec `016`), **When** `IconeDoAplicativo` é atualizado para os três itens do Item 13, **Then** nenhum dos outros aplicativos tem sua renderização alterada ou quebrada.

---

### User Story 2 - Garantir segurança, acessibilidade e compatibilidade vetorial dos SVGs (Priority: P1)

Como revisor de segurança e acessibilidade do Memora, quero ter garantia automatizada de que cada SVG embarcado usa apenas primitivos vetoriais locais compatíveis com o renderizador do aplicativo (sem scripts, sem referências externas, sem `<text>` dependente de fonte do aparelho e sem duplicar leitura no TalkBack), para evitar falhas visuais ou vetores de ataque via XML/SVG.

**Why this priority**: SVGs malformados ou com `<script>` / `<image>` / referências `https://` violam a segurança offline e quebram no `flutter_svg`; além disso, na `memora-ux`, o ícone é decorativo e nunca substitui o texto ao lado.

**Independent Test**: Executar portão automatizado de testes lendo cada arquivo em `app/assets/icones_apps/` verificando `viewBox="0 0 48 48"`, ausência de tags/URLs proibidas e semântica decorativa quando renderizado.

**Acceptance Scenarios**:

1. **Given** a pasta `app/assets/icones_apps/` contém `e-titulo.svg`, `fgts.svg` e `instagram.svg`, **When** o teste de integridade executa, **Then** confirma que todos têm `viewBox="0 0 48 48"` e não contêm `<script`, `javascript:`, `http://`, `https://`, `<image` ou `<text`.
2. **Given** o ícone acompanha texto explícito nos cartões do catálogo e atalhos, **When** o leitor de tela percorre a tela, **Then** o vetor permanece decorativo (`excludeFromSemantics`) e não repete nem polui a leitura da interface.

---

### Edge Cases

- **Tamanhos variados e ampliação de fonte até `200%`**: `IconeDoAplicativo` preserva `MediaQuery.withNoTextScaling` e moldura `ClipRRect`, escalando o SVG uniformemente para `tamanho` sem distorcer ou vazar da caixa.
- **Variações de entrada no `IconeDoAplicativo`**: Tanto `'e-titulo'` quanto `'e-Título'` ou `'FGTS'` / `'fgts'` / `'Instagram'` continuam resolvendo para o SVG correto via normalização já existente.
- **Compatibilidade com `flutter_svg`**: Gradientes (no Instagram) devem usar `<defs>` + `<linearGradient>` / `<radialGradient>` padrão suportados pelo `flutter_svg`, sem filtros `<filter>` pesados nem CSS externo.

---

## Segurança e Análise Anti-Engenharia Social *(Constituição I, II e III)*

### Threat Model

| Aspecto | Análise |
| :--- | :--- |
| **Dados sensíveis envolvidos** | Nenhum dado pessoal; apenas ativos gráficos estáticos embarcados no pacote do aplicativo. |
| **Quem acessa** | Renderização local no dispositivo de todas as pessoas usuárias (inclusive sem internet). |
| **Ameaças possíveis** | 1. **SVG ativo / XSS / XXE**: inclusão acidental de `<script>`, manipuladores `onload=`, `<foreignObject>` ou referências externas `http(s)://` dentro de arquivos SVG.<br>2. **Falsificação visual / confusão de marca**: ícone genérico ou quebrado fazendo o usuário desconfiar ou confundir aplicativos oficiais.<br>3. **Dependência de fonte externa (`<text>`)**: texto em SVG mudando de forma ou sumindo em aparelhos Android distintos. |
| **Impacto potencial** | Falha na renderização offline, confusão visual para pessoa idosa ou introdução de ativo fora do contrato de segurança do projeto. |
| **Mitigação obrigatória** | Apenas caminhos vetoriais puros (`<path>`, `<rect>`, `<circle>`, `<defs>`, gradientes simples) locais, sem `<script>`, `<foreignObject>`, `<image>`, `<text>` ou URLs externas; portão de teste automatizado validando todos os SVGs; ícones sempre decorativos acompanhados de nome escrito em português. |
| **Monitoramento / Verificação** | Suíte de testes `icone_do_aplicativo_svg_test.dart`, `flutter analyze` e `validar_tokens.py`. |

### Análise de Engenharia Social — *"Como um golpista exploraria este elemento?"*

- Ícones reconhecíveis e fiéis ajudam o usuário a associar corretamente os guias do Memora aos aplicativos reais do celular sem criar ambiguidade; nenhum ícone aparece sem o nome escrito do aplicativo nem age como botão isolado sem texto (Constituição III).

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Criar os arquivos vetoriais `app/assets/icones_apps/e-titulo.svg`, `app/assets/icones_apps/fgts.svg` e `app/assets/icones_apps/instagram.svg`, todos com `viewBox="0 0 48 48"`.
- **FR-002**: Cada SVG MUST usar apenas primitivos vetoriais puros e autossuficientes compatíveis com o renderizador SVG do aplicativo, proibindo `<script`, `on*=` (atributos de evento), `<foreignObject`, `<image`, `<text`, `javascript:`, `http://` e `https://`.
- **FR-003**: Declarar a pasta `assets/icones_apps/` na lista de ativos do aplicativo (`app/pubspec.yaml`).
- **FR-004**: Atualizar `IconeDoAplicativo` para renderizar esses três ícones a partir dos arquivos SVG mantendo recorte arredondado proporcional, exclusão semântica (decorativo ao lado do texto) e compatibilidade com variações normalizadas de chave/nome (`e-titulo`, `fgts`, `instagram`).
- **FR-005**: Remover código morto deixado pela migração do ícone do Instagram (`_CameraInstagramPainter` e importações não utilizadas) mantendo os demais ícones do catálogo intactos para evitar conflito com o Item 6.
- **FR-006**: Criar testes automatizados cobrindo integridade estrutural/segurança dos SVGs e renderização nos três temas visuais e diferentes tamanhos.

### Key Entities *(não há persistência)*

- **Ícone SVG do Aplicativo**: Ativo vetorial estático em `app/assets/icones_apps/<chave>.svg` com `viewBox="0 0 48 48"` exibido por `IconeDoAplicativo`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% dos três ícones (`e-titulo`, `fgts`, `instagram`) renderizam via ativo SVG dedicado em `IconeDoAplicativo` sem `CustomPaint` próprio nem ícones substitutos de fonte.
- **SC-002**: 100% dos arquivos em `app/assets/icones_apps/` passam no portão automatizado de `viewBox="0 0 48 48"` e ausência de elementos ativos ou links externos.
- **SC-003**: `flutter analyze`, `flutter test` e `validar_tokens.py` executam com `0` erros e `0` avisos.

## Assumptions

- O padrão acordado na Issue #106 com o responsável pelos demais ícones (`@Du3101`) é `app/assets/icones_apps/<chave>.svg` com `viewBox="0 0 48 48"`.
- O pacote `flutter_svg` já declarado em `app/pubspec.yaml` permanece na versão travada atual.
