# Feature 015 — Atalhos Rápidos para Aplicativos

**Feature Branch**: `feature/015-atalhos-aplicativos`  
**Status**: Aprovado  
**Origem**: Solicitação do usuário para disponibilizar abertura direta e segura de aplicativos cotidianos sem exigir tutoriais, convivendo com o catálogo do servidor.

---

## Clarifications

### Session 2026-11-17 (Revisão PR #85 / Clarify com Usuário)

- **Q: Como os atalhos diretos da Feature 015 devem se relacionar com o Catálogo do servidor (`TelaCatalogo`), preservando R6 (003) e o Princípio VII?**  
  **A: Convivência com separação de papéis sobre o Catálogo do servidor.** A porta *"Meus aplicativos"* no Início e no Hub continua abrindo o `TelaCatalogo` alimentado por `RepositorioAssistente.catalogo()`, que permanece sendo o lugar de aprender (*"Ensinar passo a passo"*, *"Pedir para a Memora abrir"* e conversa), sem duplicar dois botões de abrir no mesmo cartão. Na aba cotidiana do catálogo fica disponível o botão *"Abrir um aplicativo direto"* para acessar a tela dedicada `TelaAtalhosAplicativos` (*"Abrir aplicativos"*), onde quem já sabe usar abre diretamente com confirmação segura (`DialogoConfirmacaoAbertura` / `DialogoInstalacaoPlayStore`). A tela dedicada também consome exclusivamente `RepositorioAssistente.catalogo()`, preservando **R6** sem lista paralela.
- **Q: Sobre o Registro de Ações (D1 da Feature 003), abrir um aplicativo diretamente pela própria pessoa gera registro no servidor?**  
  **A: Não gera registro.** O registro da trilha de auditoria (`003/D1`) audita exclusivamente ações executadas pela assistente de IA a pedido da pessoa. Quando a própria pessoa toca manualmente no atalho e confirma a saída no diálogo modal, não há intervenção da assistente nem envio ao endpoint `/assistente/registro`.
- **Q: Como ficam o `TelaInicio` e os textos diante do conflito e do portão da Feature 013?**  
  **A: Preservação integral do Início e conformidade com o portão da 013.** O `TelaInicio` mantém a chave, o rótulo `TextosAssistente.portaAplicativos` (*"Meus aplicativos"*) e o destino original (`TelaCatalogo`), evitando conflitos com a `MemoraAnfitria` (`013`). Todos os textos em `textos_atalhos_aplicativos.dart` seguem limite de até duas frases curtas por bloco, zero emojis e ausência de termos proibidos pela 013.

---

## 1. Objetivo

Oferecer às pessoas usuárias do Memora uma experiência simples, intuitiva e acessível para abrir aplicativos comuns do cotidiano diretamente, convivendo com o catálogo educativo sem obrigar quem já sabe usar o aplicativo a passar por tutoriais. 

Ao tocar para abrir diretamente (no cartão do catálogo ou na tela dedicada *"Abrir aplicativos"*), o Memora solicita uma confirmação simples e clara e redireciona para o aplicativo nativo instalado, sem abrir guias passo a passo.

---

## 2. Escopo e Restrições de Negócio

1. **Apenas Aplicativos Comuns Cotidianos**:
   - Estão contemplados exclusivamente aplicativos populares de comunicação, mídia e redes sociais: **WhatsApp**, **YouTube**, **Instagram**, **Facebook**, **Google Fotos**, **Telegram** e **TikTok**.
   - **Exclusão Estrita de Serviços Sociais / Governamentais**: Não entram nesta tela serviços públicos, governamentais ou financeiros (como Gov.br, Meu INSS, Carteira de Trabalho, Poupatempo, Serasa, Caixa Tem, bancos). Tais serviços requerem cuidados pedagógicos e contexto de segurança diferenciados presentes nos guias educativos da Feature 006.

2. **Apresentação Direta de Todos os Aplicativos Comuns**:
   - A tela apresenta a lista completa de aplicativos comuns homologados (WhatsApp, YouTube, Instagram, Facebook, Google Fotos, Telegram, TikTok).
   - Não há filtro para esconder aplicativos não instalados. Todos os aplicativos da lista aparecem de forma clara e visível.
   - O estado de instalação (`instalado: true/false`) é detectado para orientar a ação de toque: se instalado, oferece abertura imediata; se não instalado, oferece ida à Google Play Store para download oficial.

---

## 3. Histórias de Usuário (User Stories)

### US1 — Visualizar Aplicativos Comuns e seus Status (P1)
> **Como** uma pessoa idosa usando o Memora,  
> **Quero** acessar uma tela que mostre os aplicativos comuns em cartões grandes, limpos e com indicação se já estão instalados no meu celular,  
> **Para que** eu encontre meus aplicativos facilmente em um único lugar sem me perder na tela inicial do aparelho.

### US2 — Abrir o Aplicativo Instalado com Confirmação Segura (P1)
> **Como** uma pessoa idosa,  
> **Quero** tocar em um aplicativo instalado e receber uma confirmação simples antes de sair do Memora,  
> **Para que** eu tenha certeza de para onde estou indo e nunca saia do Memora por um toque acidental.

### US3 — Instalar Aplicativo Não Instalado via Google Play Store (P2)
> **Como** uma pessoa idosa que deseja usar um aplicativo que ainda não está no meu celular,  
> **Quero** tocar nele e ser orientada com segurança a abrir a loja oficial Google Play Store para instalá-lo,  
> **Para que** eu saiba exatamente como obtê-lo sem cair em sites suspeitos ou golpes.

---

## 4. Requisitos Funcionais (FR)

- **FR-001**: A porta *"Meus aplicativos"* no Início e no Hub abre o `TelaCatalogo` (`CategoriaDoServico.cotidiano`), que exibe na aba cotidiana o botão *"Abrir um aplicativo direto"* para acessar a tela dedicada `TelaAtalhosAplicativos` (*"Abrir aplicativos"*), mantendo os cartões do catálogo exclusivamente com as ações educativas (*"Ensinar passo a passo"*, *"Perguntar na conversa"* e *"Pedir para a Memora abrir"*).
- **FR-002**: A lista de aplicativos exibida na `TelaAtalhosAplicativos` e os pacotes elegíveis para abertura direta devem vir exclusivamente do catálogo oficial do servidor (`RepositorioAssistente.catalogo()`, filtrando `CategoriaDoServico.cotidiano` com `memoraPodeAbrir == true` e `identificadorAndroid` válido), espelhando o banco (`WhatsApp`, `YouTube`, `Instagram`, `Facebook`, `Google Fotos`, `Telegram`, `TikTok`) e preservando integralmente o requisito **R6** da 003.
- **FR-003**: Ao abrir a tela, o sistema deve consultar de forma assíncrona o estado de instalação de cada aplicativo liberado pelo servidor através do serviço `ConsultaDeAplicativos`.
- **FR-004**: A tela deve exibir todos os aplicativos cotidianos liberados pelo catálogo do servidor diretamente, indicando em cada cartão se o aplicativo está instalado no aparelho ou disponível para instalação na loja, tratando falhas de carregamento e lista vazia conforme `FR-006` (004).
- **FR-005**: Cada item da lista de aplicativos deve ser exibido como um cartão de alta legibilidade contendo:
  - Ícone real do aplicativo (PNG extraído via canal nativo) ou ícone vetorial de alta definição com cores oficiais;
  - Nome amigável em destaque (`AtkinsonHyperlegibleNext`, peso semibold, `>= 18 sp`);
  - Breve descrição de uma frase em linguagem simples (ex.: *"Mensagens e chamadas com a família"*);
  - Indicador visual e textual de status (*"Instalado — Toque para abrir"* ou *"Não instalado — Toque para baixar"*);
  - Alvo de toque mínimo de `56 dp` de altura.
- **FR-006**: Ao tocar em um aplicativo instalado, o Memora **não deve abrir tutoriais nem guias**. O sistema deve exibir um diálogo de confirmação claro e acolhedor (Princípio II da Constituição):
  - Título: *"Abrir o [Nome do App]?"*
  - Mensagem: *"Você vai sair do Memora e entrar no [Nome do App]. Para voltar depois, basta tocar no botão voltar do celular."*
  - Botão de ação primária: *"Sim, abrir agora"* (destaque, cor primária).
  - Botão de cancelamento: *"Não, continuar no Memora"* (neutro).
- **FR-007**: Ao confirmar, o Memora deve invocar o serviço `AbridorDeAplicativo` para disparar a `Intent` de inicialização do aplicativo nativo.
- **FR-008**: Se por qualquer motivo o sistema operacional falhar em abrir o aplicativo, o Memora deve exibir um aviso amigável na voz da Memora: *"Não consegui abrir o [Nome do App] agora. Confira se ele está atualizado na loja."*
- **FR-009**: Ao tocar em um aplicativo que **não** está instalado, o diálogo de confirmação deve orientar sobre a instalação segura:
  - Título: *"Instalar o [Nome do App]?"*
  - Mensagem: *"O [Nome do App] ainda não está no seu celular. Deseja abrir a loja oficial Google Play Store para instalá-lo?"*
  - Botão de ação primária: *"Ir para a Play Store"*
  - Botão de cancelamento: *"Agora não"*
- **FR-010**: Ao confirmar no diálogo de instalação, o Memora deve abrir com segurança a página oficial do pacote na Google Play Store via URL launcher (`market://details?id={pacote}` ou fallback web oficial).
- **FR-011**: Não deve haver telemetria sobre aplicativos instalados nem envio ao registro da assistente (`003/D1`) quando a própria pessoa realiza abertura direta manual, respeitando a privacidade (Princípio I e LGPD).

---

## 5. Requisitos Não Funcionais (NFR)

- **NFR-001**: **Design System 2.0**: A tela deve utilizar rigorosamente os componentes e tokens oficiais do Memora (`Cartao`, `BotaoPrimario`, `BotaoSecundario`, `BadgeDeStatus`, tipografia `AtkinsonHyperlegibleNext`).
- **NFR-002**: **Acessibilidade Sênior (WCAG 2.2 AA/AAA)**:
  - Contraste de cor mínimo de `4.5:1` para textos normais e `3:1` para elementos gráficos e ícones;
  - Altura mínima de área de toque de `56 dp` em botões e cartões;
  - Suporte a ampliação de texto de até `200%` sem quebra ou sobreposição de layout;
  - Rótulos semânticos completos para leitores de tela (`Semantics` / TalkBack).
- **NFR-003**: **Privacidade e Permissões Android**:
  - Proibido solicitar a permissão sensível `QUERY_ALL_PACKAGES`;
  - A verificação de pacotes deve se ater exclusivamente às tags `<queries>` pré-declaradas no `AndroidManifest.xml`.
- **NFR-004**: **Desempenho**:
  - A verificação em paralelo não deve bloquear a UI nem exceder o orçamento de carregamento fluido da lista.
- **NFR-005**: **Resiliência e R6 (Fonte Única da Verdade)**:
  - A lista obedece ao catálogo retornado por `RepositorioAssistente` (preservando R6 para desativação remota pelo banco) e apresenta `MensagemErro` com nova tentativa ou `EstadoVazio` amigável em caso de indisponibilidade.

---

## 6. Critérios de Aceitação (AC)

- **AC-001**: O usuário acessa *"Meus aplicativos"* pelo Início ou Hub (no `TelaCatalogo`) e toca em *"Abrir um aplicativo direto"* para entrar na `TelaAtalhosAplicativos`, sem duplicidade de botões de abertura nos cartões do catálogo.
- **AC-002**: A tela exibe diretamente os aplicativos cotidianos ativos no catálogo do servidor (`RepositorioAssistente`), refletindo desativações remotas (R6) e sem ocultar apps ausentes do aparelho.
- **AC-003**: Ao tocar em um aplicativo instalado, surge a caixa de confirmação *"Abrir o [Nome do App]?"*.
- **AC-004**: Ao tocar em *"Sim, abrir agora"*, o aplicativo externo abre imediatamente e o Memora fica em segundo plano.
- **AC-005**: Ao tocar em *"Não, continuar no Memora"*, a caixa fecha e o usuário permanece na mesma tela sem nenhuma ação externa.
- **AC-006**: Ao tocar em um aplicativo não instalado, surge a caixa *"Instalar o [Nome do App]?"* com opção de ir para a Google Play Store.
- **AC-007**: Ao confirmar a ida para a Play Store, a loja oficial abre na página exata do aplicativo.
- **AC-008**: Nenhum serviço social ou governamental (Gov.br, INSS, Poupatempo, etc.) aparece nesta tela.
- **AC-009**: A tela mantém legibilidade perfeita em modo claro e escuro, respeitando a escala de acessibilidade de até 200%.
- **AC-010**: Todos os testes unitários e de widget com `ConsultaDeAplicativosSimulada` e `AbridorDeAplicativoSimulado` passam com 100% de sucesso.

---

## 7. Fora do Escopo

- Tutoriais passo a passo ou simulação guiada de uso de aplicativos (já atendidos pelas Features 004 e 006).
- Desinstalação ou gerenciamento de armazenamento de aplicativos.
- Consulta a aplicativos bancários, carteiras digitais ou serviços governamentais.
- Varredura geral de todos os aplicativos do celular (`QUERY_ALL_PACKAGES`).
- Execução autônoma de ações dentro de aplicativos externos.
