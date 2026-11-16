# Research: Site Tutorial Acolhedor do Memora (`012-site-tutorial-idoso`)

**Branch**: `feature/012-site-tutorial-idoso` | **Date**: 2026-11-16 | **Spec**: [spec.md](file:///c:/Users/Eduardo/Memora/specs/012-site-tutorial-idoso/spec.md)

## Resumo das Decisões Técnicas

### 1. Stack Web Estática Pura (HTML5 Semântico + CSS3 + JavaScript ES6+ sem Build)

- **Decision**: Construir o site em `site/` usando **HTML5 semântico**, **CSS3 modular** (`styles/tokens.css`, `styles/main.css`) e **JavaScript vanilla progressivo** (`scripts/tutorial.js`), sem frameworks front-end, *bundlers* ou dependências CDN externas.
- **Rationale**:
  - Funciona de forma idêntica ao abrir localmente via `file://` no computador/celular ou servido em qualquer hospedagem estática, cumprindo `SC-006` (funcionamento integral offline).
  - Elimina superfície de ataque de scripts de terceiros, fontes externas ou rastreadores (mitigação direta do *Threat Model*).
  - Sem JavaScript (caso bloqueado), todo o conteúdo, sumário por âncoras, ilustrações, mini-telas visuais e `<details>`/`<summary>` continuam 100% navegáveis.
- **Alternatives considered**:
  - React/Vite/Next.js: exigiria `node_modules`, compilação e quebraria abertura direta por `file://` sem servidor, além de adicionar complexidade desnecessária para uma página estática educativa.
  - HTML cru sem folha de estilo elaborada: rejeitado explicitamente pelo usuário; o público idoso exige cartões amplos, contraste calmo, hierarquia clara e espaçamento respirado.

### 2. Reutilização Fiel dos Tokens de Cor do Design System do Memora

- **Decision**: Espelhar diretamente em variáveis CSS (`:root`, `[data-tema="escuro"]`, `[data-tema="alto-contraste"]`) os valores hexadecimais exatos validados de `MemoraCores` em `app/lib/design_system/tokens/cores.dart` (claro, escuro e alto contraste `>= 7.0:1`).
- **Rationale**:
  - Garante unidade visual imediata entre o site tutorial e o aplicativo Android (`FR-003`).
  - Todas as combinações (`fundo`, `superficie`, `superficie-alt`, `destaque`, `medalhao`, `primaria`, `sobre-primaria`, `texto`, `texto-suave`, `borda`, `sucesso`, `perigo`, `sobre-perigo`) já possuem conformidade matemática WCAG 2.2 AA/AAA comprovada no projeto.
  - `medalhao` permanece claro mesmo nos modos Escuro e Alto Contraste para que os desenhos do robô Memora não sumam no fundo escuro (mesmo aprendizado registrado em `cores.dart`).
- **Alternatives considered**:
  - Criar uma paleta nova separada: arriscaria quebrar contraste WCAG 2.2 e dissociar a identidade visual entre o tutorial e o aplicativo.

### 3. Tipografia Sem Dependências Externas e Escala Dinâmica até 200%

- **Decision**: Usar pilha de fontes nativas de alta legibilidade (`system-ui, -apple-system, "Segoe UI", Roboto, "Noto Sans", Arial, sans-serif`) combinada com base `18px` (`1.125rem`), entrelinha generosa (`1.65`) e variável `--escala-fonte` com três níveis selecionáveis (`1` = Padrão, `1.25` = Grande, `1.5` ou `2`? Nota: base `18px` × `1.55` chega a `~28px`, ou botões claros `Padrão (100%)`, `Grande (140%)`, `Muito grande (200%)` sobre base confortável sem quebrar `320px`!). Ajuste exato: base HTML padrão `16px` no `:root` multiplicada por `--escala` (`1.125` = Padrão `18px`, `1.45` = Grande `~23px`, `2.0` = Muito grande `32px`), garantindo `AC-004` (`200%` real!) e que nenhum componente use largura fixa capaz de estourar `320px`.
- **Rationale**:
  - Fontes do sistema carregam em `0ms` offline e respeitam configurações nativas do aparelho.
  - Multiplicar variáveis em `rem` garante que o botão integrado de tamanho de letra faça um incremento real de até `200%` mantendo a proporção entre títulos, parágrafos, mini-telas e botões (`>= 48px`).
- **Alternatives considered**:
  - Google Fonts via `<link>`: criaria dependência externa de rede e violaria carregamento `100%` offline sem fallback garantido.

### 4. Responsividade Desktop-e-Mobile (`320 px` até `1440 px+`)

- **Decision**: Arquitetura *mobile-first* com contêiner de leitura central (`max-width: 1120px`, coluna de texto confortável até `68ch`), grade responsiva com CSS Grid (`grid-template-columns: minmax(0, 1fr)` no celular -> 2 ou 3 colunas no tablet/PC quando há espaço e `--escala < 2.0`), e *breakpoints* fluidos sem largura rígida. Em escala `Muito grande (200%)`, cartões retomam empilhamento amplo quando necessário em telas estreitas para evitar esmagamento de texto.
- **Rationale**:
  - Garante zero rolagem horizontal (`overflow-x: clip` apenas como salvaguarda após layout naturalmente fluido sem estouro) em `320 px`, `390 px`, `768 px` e `1280 px+`.
  - Mantém no computador uma leitura arejada (não estica parágrafos de ponta a ponta em monitores *ultrawide*) e no celular cartões grandes e confortáveis para toque com o dedo.
- **Alternatives considered**:
  - Apenas layout fixo centralizado estreito em PC: desperdiçaria espaço em monitores de desktop para comparar mini-telas ao lado dos passos numerados.

### 5. Ilustrações Oficiais Portáveis e Mini-Telas Declarativas Acessíveis

- **Decision**: Copiar para `site/assets/ilustracoes/` o subconjunto necessário das ilustrações próprias do Memora (originadas e licenciadas em `app/assets/ilustracoes/LICENCAS.md`) e renderizar as mini-telas ilustrativas (`Ajustes / Início / Meu Perfil`, `Balão de conversa e histórico`, `Cartão de aviso antes de app externo`, `Botões Estou bem / Preciso de ajuda` e `Foto/Avatar de perfil`) com HTML/CSS estilizado marcado semanticamente como demonstração visual (ex.: `aria-label` explicando que é um exemplo ilustrativo e controles não interativos/desabilitados para não simular formulário nem conta ativa).
- **Rationale**:
  - Torna `site/` totalmente autônomo e portátil (pode ser publicado isoladamente sem depender de `../app/`).
  - Mini-telas estilizadas em HTML/CSS acompanham instantaneamente as trocas de tema (Claro / Escuro / Alto Contraste) e aumento de fonte (`200%`), superando imagens estáticas que ficariam borradas ou ilegíveis em Alto Contraste.
- **Alternatives considered**:
  - Capturas PNG do aplicativo: não mudam de tema nem acompanham zoom tipográfico limpo no site.

### 6. Controle Local de Leitura em Voz Alta (`SpeechSynthesis`) e Persistência Segura

- **Decision**: Implementar leitura em voz alta usando a API padrão `window.speechSynthesis` do navegador configurada para `pt-BR`, exibindo o botão **"Ouvir este trecho"** / **"Parar leitura"** apenas quando `'speechSynthesis' in window` (permanecendo oculto com `hidden` caso indisponível, cumprindo `FR-013`). Para salvar tamanho de letra e tema entre visitas no mesmo navegador (`FR-010`), encapsular `localStorage` em `try/catch` com fallback silencioso em memória caso o navegador esteja em modo restrito/`file://`.
- **Rationale**:
  - Funciona localmente sem enviar texto pela rede nem expor dados.
  - Garante cancelamento automático de leitura anterior ao iniciar outro capítulo ou clicar em "Parar leitura", evitando duas vozes falando juntas.
  - Fallbacks limpos impedem erros silenciosos de script caso armazenamento local ou síntese de voz estejam desativados.
- **Alternatives considered**:
  - Arquivos MP3 pré-gravados: aumentariam muito o tamanho do site e ficariam dessincronizados a cada revisão textual.

### 7. Estratégia de Verificação Automatizada e Manual

- **Decision**:
  - Suite Python (`site/tests/validar_site.py`): valida integridade estrutural HTML (marcos semânticos, único `<h1>`, sequência de títulos sem saltos, atributo `alt` em todas imagens, ausência de `<form>`, `<input>` de dados sensíveis e ausência de links externos `http(s)://`, existência de todas as ilustrações referenciadas e ausência de requisições de rede externas em HTML/CSS/JS) + verificação matemática de contraste WCAG 2.2 AA/AAA da paleta do `tokens.css`.
  - Suite Node (`site/tests/tutorial.test.mjs` usando `node:test` nativo do Node 24): testa em DOM simulado/lógico as transições de preferência de leitura (claro/escuro/alto contraste, 3 níveis de escala, fallback sem `localStorage`), controle de fala única por vez e alternância de capítulos/FAQ.
  - Inspeção visual no navegador em múltiplos *viewports* (`320x568`, `390x844`, `768x1024`, `1280x800`) a `100%` e `200%`, conferindo ausência de `scrollWidth > clientWidth`.
- **Rationale**: Não exige instalar pacotes externos (`npm install`) mantendo CI simples e reprodutível com as ferramentas já instaladas (`Python 3.13` + `Node 24`).
- **Alternatives considered**: Instalar Playwright/npm no repositório: desnecessário quando `validar_site.py` + `node:test` + navegador local já validam estrutura, lógica, contraste e responsividade sem adicionar centenas de megabytes de dependências.
