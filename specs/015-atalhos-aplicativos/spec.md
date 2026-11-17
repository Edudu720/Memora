# Feature 015 — Atalhos Rápidos para Aplicativos

**Feature Branch**: `feature/015-atalhos-aplicativos`  
**Status**: Em Planejamento  
**Origem**: Solicitação do usuário para disponibilizar uma tela dedicada de atalhos diretos para aplicativos cotidianos sem tutoriais ou fluxos guiados.

---

## 1. Objetivo

Oferecer às pessoas idosas uma tela simples, intuitiva e acessível contendo atalhos rápidos para abrir aplicativos comuns do cotidiano diretamente do Memora, eliminando atritos e reduzindo a frustração de procurar ícones na tela inicial do celular. 

Ao tocar em um aplicativo, o Memora solicita uma confirmação simples e clara e redireciona o usuário para o aplicativo nativo instalado, sem passar por guias passo a passo ou tutoriais.

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

- **FR-001**: A tela de Atalhos Rápidos deve ser acessível a partir do Hub Principal e do Início do Memora com título claro: *"Meus Aplicativos"*.
- **FR-002**: A lista de aplicativos comuns suportados nesta tela deve ser composta estritamente por:
  1. WhatsApp (`com.whatsapp`)
  2. YouTube (`com.google.android.youtube`)
  3. Instagram (`com.instagram.android`)
  4. Facebook (`com.facebook.katana`)
  5. Google Fotos (`com.google.android.apps.photos`)
  6. Telegram (`org.telegram.messenger`)
  7. TikTok (`com.zhiliaoapp.musically`)
- **FR-003**: Ao abrir a tela, o sistema deve consultar de forma assíncrona o estado de instalação de cada aplicativo da lista através do serviço `ConsultaDeAplicativos`.
- **FR-004**: A tela deve exibir todos os 7 aplicativos comuns homologados diretamente, indicando em cada cartão se o aplicativo está instalado no aparelho ou disponível para instalação na loja.
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
- **FR-008**: Se por qualquer motivo o sistema operacional falhar em abrir o aplicativo, o Memora deve exibir um aviso amigável: *"Não foi possível abrir o [Nome do App]. Verifique se o aplicativo está atualizado."*
- **FR-009**: Ao tocar em um aplicativo que **não** está instalado, o diálogo de confirmação deve orientar sobre a instalação segura:
  - Título: *"Instalar o [Nome do App]?"*
  - Mensagem: *"O [Nome do App] ainda não está no seu celular. Deseja abrir a loja oficial Google Play Store para instalá-lo?"*
  - Botão de ação primária: *"Ir para a Play Store"*
  - Botão de cancelamento: *"Agora não"*
- **FR-010**: Ao confirmar no diálogo de instalação, o Memora deve abrir com segurança a página oficial do pacote na Google Play Store via URL launcher (`market://details?id={pacote}` ou fallback web oficial).
- **FR-011**: Não deve haver rastreamento, envio de dados de telemetria sobre quais apps o usuário tem instalados para servidores externos, respeitando a privacidade total do idoso (Princípio I e LGPD).

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
  - A verificação dos 7 aplicativos comuns em paralelo não deve bloquear a UI nem ultrapassar `100 ms` no carregamento da tela.
- **NFR-005**: **Resiliência Offline**:
  - A tela deve operar 100% offline, sem requisições de rede ao backend para listar ou abrir aplicativos instalados.

---

## 6. Critérios de Aceitação (AC)

- **AC-001**: O usuário acessa a tela *"Meus Aplicativos"* através do Hub ou Início.
- **AC-002**: A tela exibe diretamente todos os 7 aplicativos comuns homologados, sem ocultar nenhum aplicativo.
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
