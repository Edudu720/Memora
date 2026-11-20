# Feature Specification: Publicação do Site Tutorial no Render (Item 14b)

**Feature Branch**: `feature/017-site-no-render`
**Created**: 2026-11-20
**Status**: Draft
**Input**: User description: "Item 14b da Issue #106: Configurar e deixar pronto o Blueprint do Render (`render.yaml`) e a documentação de implantação para publicar o site tutorial estático (`site/`) em HTTPS com segurança e sem interferir no serviço do backend, fornecendo o caminho para passar a URL oficial ao Item 11 (link na Ajuda do aplicativo)."

## Clarifications

### Session 2026-11-20

- Q: O serviço estático do site deve usar reescrita global de rotas para `index.html` ou servir os arquivos estáticos diretamente? → A: Servir arquivos estáticos diretamente sem reescrita global (`/* -> /index.html`), mantendo 404 real para recursos inexistentes e preservando o comportamento de página única (`index.html`).
- Q: Qual política mínima de origem deve valer nos cabeçalhos do site considerando os estilos internos do Web Component da Memora? → A: Bloquear scripts, conexões, objetos, formulários e enquadramento externo, restringindo fontes de conteúdo à própria origem e permitindo estilos internos apenas para o funcionamento do componente local.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Publicar o site tutorial pelo Blueprint único do repositório (Priority: P1)

Como responsável pela implantação do Memora, quero que o Blueprint do projeto inclua o serviço do site tutorial estático ao lado do backend já configurado, para que a aplicação do Blueprint no painel da hospedagem publique automaticamente a página educativa em endereço `https://` dedicado sem passos manuais frágeis.

**Why this priority**: Desbloqueia o link oficial do site na tela de Ajuda do aplicativo (Item 11 da Issue #106) e permite acesso público contínuo ao manual educativo.

**Independent Test**: Validar a sintaxe e estrutura do arquivo de Blueprint confirmando a presença de dois serviços independentes (`memora-backend` preservado e `memora-site` estático publicando `site/`), sem segredos hardcoded e com filtros de reconstrução isolados.

**Acceptance Scenarios**:

1. **Given** o repositório possui a pasta estática `site/` validada e o serviço `memora-backend` no Blueprint, **When** o Blueprint é sincronizado na plataforma de hospedagem, **Then** um serviço web estático dedicado ao site tutorial é criado e servido em `https://` mantendo o backend intacto.
2. **Given** uma alteração futura é feita apenas no aplicativo móvel (`app/`) ou apenas no backend (`backend/`), **When** um commit entra na branch configurada, **Then** o serviço estático do site não precisa ser reconstruído desnecessariamente (e commits apenas em `site/` não derrubam nem reconstroem o backend).

---

### User Story 2 - Proteger visitantes com cabeçalhos de segurança e orientação clara de entrega da URL (Priority: P1)

Como pessoa usuária ou familiar que acessa o site educativo publicado na internet, quero acessar o guia sempre por conexão segura (`https://`) com proteções de navegador contra incorporação indevida, alteração de conteúdo ou injeção externa, para que ninguém possa sequestrar ou adulterar a página educativa em trânsito ou em molduras ocultas.

**Why this priority**: Pessoas idosas são o público mais visado por engenharia social e clickjacking; cabeçalhos restritivos em produção garantem integridade da página oficial (Constituição I e II).

**Independent Test**: Inspecionar as regras de cabeçalhos declaradas no Blueprint confirmando políticas restritivas para origens externas, formulários, incorporação em quadros e sniffing de MIME, sem quebrar os scripts, estilos e vetores locais do site.

**Acceptance Scenarios**:

1. **Given** o site estático é servido pela plataforma, **When** o navegador recebe qualquer recurso do site, **Then** a resposta inclui cabeçalhos de proteção bloqueando incorporação em quadros de terceiros, detecção automática insegura de tipo de conteúdo, envio excessivo de referência e carregamento de scripts/conexões/formulários externos.
2. **Given** os testes locais do site tutorial já garantem execução 100% offline sem requisições externas, **When** os cabeçalhos entram em vigor, **Then** todas as funcionalidades educativas do site (troca de fonte, contraste, redução de movimento, leitura em voz local e mascote animada) continuam operando normalmente.

---

### User Story 3 - Guiar a publicação e a passagem da URL oficial para o aplicativo (Priority: P2)

Como membro da equipe que aplica o Blueprint no painel de hospedagem após o merge, quero instruções diretas passo a passo na documentação de implantação dizendo como sincronizar o serviço do site, conferir os cabeçalhos em produção e registrar a URL `https://` final na Issue #106, para que o responsável pelo Item 11 finalize o botão na tela de Ajuda sem dúvidas.

**Why this priority**: Garante rastreabilidade e coordenação entre quem publica o Blueprint e quem configura a URL fixa no aplicativo (spec `012` / Item 11).

**Independent Test**: Ler a documentação de implantação atualizada verificando que contempla o serviço do site, comandos de conferência e checklist de repasse da URL oficial sem depender de configuração não documentada.

**Acceptance Scenarios**:

1. **Given** a PR entra na `develop`, **When** um mantenedor segue o guia de implantação, **Then** sabe exatamente como aplicar o Blueprint no painel, verificar `https://` e cabeçalhos e informar a URL final na Issue #106 para desbloquear o Item 11.

---

### Edge Cases

- **Serviço de site estático vs. servidor backend gratuito**: Diferente do backend em contêiner que dorme após 15 minutos sem tráfego, o site estático servido por CDN não dorme e não exige ping externo — o guia de implantação deve deixar isso claro para evitar criação de monitores desnecessários.
- **Compatibilidade dos cabeçalhos com os componentes do site**: O componente `<memora-personagem>` injeta regras de estilo internas isoladas em Shadow DOM sem requisições externas; a política de segurança de conteúdo precisa permitir estilos internos do próprio documento/componente sem abrir brecha para scripts inline, URLs externas ou envio de formulários.
- **Preservação do serviço `memora-backend`**: Nenhuma variável de ambiente, filtro de caminho ou comando do `memora-backend` pode ser removida ou alterada por esta entrega.

---

## Segurança e Análise Anti-Engenharia Social *(Constituição I e II)*

### Threat Model

| Aspecto | Análise |
| :--- | :--- |
| **Dados sensíveis envolvidos** | Nenhum dado pessoal, credencial ou token transita pelo serviço do site estático (apenas arquivos HTML, CSS, JS e SVG públicos e educativos). |
| **Quem acessa** | Público geral, pessoas idosas, familiares e equipe acadêmica via navegador em `https://`. |
| **Ameaças possíveis** | 1. **Clickjacking**: site falso embutindo o guia oficial em `<iframe>` transparente para enganar o visitante.<br>2. **MIME sniffing / XSS residual**: interpretação incorreta de ativos ou injeção de scripts/estilos de origens externas.<br>3. **Vazamento de URL de origem ou abuso de formulários**: se futuramente algo tentar abrir formulário ou enviar dados para fora.<br>4. **Quebra do backend existente**: edição descuidada do Blueprint alterando variáveis ou build do `memora-backend`. |
| **Impacto potencial** | Comprometimento da confiança do público idoso, exposição a fraudes por sobreposição de tela ou indisponibilidade da API principal do aplicativo. |
| **Mitigação obrigatória** | Cabeçalhos `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: no-referrer` (ou `strict-origin-when-cross-origin`), `Permissions-Policy` restritiva e `Content-Security-Policy` bloqueando origens externas, formulários (`form-action 'none'`), objetos e enquadramento (`frame-ancestors 'none'`). Preservar integralmente a definição do `memora-backend`. |
| **Monitoramento / Verificação** | Validação sintática automática do YAML na esteira local + execução da suíte `site/tests/validar_site.py` e `site/tests/tutorial.test.mjs` + procedimento de conferência `curl -I` pós-deploy documentado. |

### Análise de Engenharia Social — *"Como um golpista exploraria esta tela/publicação?"*

- Um golpista poderia clonar visualmente o endereço ou incorporar o site oficial dentro de um iframe em domínio malicioso adicionando um aviso falso por cima (*"Atualize seu cadastro aqui"*).
- Bloquear incorporação (`X-Frame-Options: DENY` e `frame-ancestors 'none'`) impede que o site oficial do Memora sirva como disfarce dentro de páginas falsas, e o domínio oficial `https://` publicado serve de referência única e verificável para o botão da tela de Ajuda (Item 11).

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O arquivo de Blueprint da raiz do repositório DEVE declarar um serviço web estático dedicado (`memora-site`) publicando o conteúdo da pasta `site/` sem etapa de compilação externa.
- **FR-002**: A definição do serviço `memora-site` DEVE isolar reconstruções com filtro de caminhos cobrindo a pasta do site e o próprio Blueprint, evitando reconstruções quando apenas código de aplicativo ou servidor mudar.
- **FR-003**: O serviço `memora-site` DEVE configurar cabeçalhos HTTP de segurança em todas as rotas (`/*`): política de segurança de conteúdo bloqueando scripts externos, conexões de rede, objetos embutidos, formulários e enquadramento por terceiros (permitindo apenas ativos próprios e estilos compatíveis com o componente local da Memora), além de proteção contra MIME sniffing, clickjacking e política restrita de `Referrer-Policy` / `Permissions-Policy`.
- **FR-004**: O serviço `memora-backend` existente no Blueprint DEVE permanecer integralmente preservado sem alteração de variáveis de ambiente, filtros de caminho, porta, runtime ou health check.
- **FR-005**: A documentação de implantação no Render DEVE ser atualizada cobrindo: publicação do serviço estático do site junto ao Blueprint, ausência de hibernação em plano estático gratuito, conferência da URL `https://` e cabeçalhos após o deploy, e instrução explícita para comunicar a URL oficial na Issue #106 (destravando o Item 11).
- **FR-006**: Os ativos e testes do site tutorial (`site/`) DEVEM continuar passando integralmente sem exigir alterações de conteúdo, formulários ou conexões externas.

### Key Entities *(não há persistência de dados)*

- **Serviço Estático no Blueprint (`memora-site`)**: Declaração declarativa de hospedagem estática em `https://` mapeada para `site/` com filtro de build e cabeçalhos de segurança.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: O arquivo de Blueprint valida sintaticamente sem erros e declara exatamente 2 serviços independentes (`memora-backend` intacto e `memora-site` estático apontando para `site/`).
- **SC-002**: 100% dos cabeçalhos obrigatórios de proteção (`Content-Security-Policy`, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`) estão configurados para todas as rotas (`/*`) do serviço estático.
- **SC-003**: 100% das verificações existentes do site (`validar_site.py` e testes Node do tutorial) continuam aprovadas sem regressões.
- **SC-004**: A documentação de deploy permite que qualquer membro da equipe obtenha e valide a URL `https://` do site após o merge em menos de 5 minutos, registrando o repasse para o Item 11.

## Assumptions

- O repositório permanece conectado ao painel do Render via Blueprint (`render.yaml`) na conta do dono (`Edudu720`), aplicando mudanças após o merge na branch configurada (`develop`).
- O site estático em `site/` já atende integralmente às especificações da feature `012-site-tutorial-idoso` e ao portão `memora-ux`, não necessitando alterações de HTML/CSS/JS nesta entrega.
