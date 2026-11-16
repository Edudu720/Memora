# Feature Specification: 006 — Polimento de Acessibilidade, Robustez de Conta e Rastreabilidade

**Feature Branch**: `feature/006-acessibilidade-e-robustez`  
**Created**: 2026-11-13  
**Status**: Draft  
**Input**: User description: "A partir da branch develop, criar uma feature de polimento técnico, acessibilidade e robustez fechando as seguintes pendências do projeto: 1. Acessibilidade em botões (Design System / Feature 002): Atualizar BotaoBase para exibir um segundo sinal visual além da cor do InkWell nos estados de foco e toque, mantendo todos os tokens do design system, contraste WCAG 2.2, altura mínima de toque e sem literais visuais fora de tokens/. 2. Robustez em contas assistidas abandonadas (Backend / T065b): Tratar o caso de contas assistidas que permanecem indefinidamente em PENDENTE_VERIFICACAO bloqueando o e-mail/canal contra novo cadastro, definindo uma política segura de expiração/expurgo ou liberação que preserve o fluxo anti-enumeração (FR-010) e os testes do backend. 3. Envio real de código de verificação e recuperação (Backend / T065a e T068): Implementar um adaptador de produção para EnviadorDeCodigo (e NotificadorDeConta se aplicável), via SMTP/API configurável por variáveis de ambiente para o perfil producao, mantendo o EnviadorDeCodigoEmLog no perfil padrão/desenvolvimento para não quebrar testes nem o ambiente gratuito atual do Render quando não configurado. 4. Dívidas técnicas pontuais: Corrigir cartao_de_porta_test.dart para não construir MediaQueryData do zero com altura zero ao aplicar textScaler, e atualizar docs/relatorios/o-que-falta.md refletindo o estado real atual do repositório."

---

## Contexto

O Memora aproxima-se da etapa de validação presencial com pessoas idosas (65+ anos) e da implantação em nuvem. As funcionalidades centrais de autenticação acessível (001), sistema de desenho visual (002), hub e assistente (003), redesenho das telas (004) e cuidado por sensores (005) já estão construídas, mas restam quatro lacunas transversais de acessibilidade, ciclo de vida de conta e higiene documental que precisam ser fechadas de ponta a ponta:

1. **Duplo sinal visual nos botões de ação via `SuperficieTocavel`**: os componentes introduzidos na Feature 004 já delegam sua interação à `SuperficieTocavel`, exibindo um segundo sinal além da cor (anel externo no foco e redução de escala / preenchimento de destaque no toque). Já os botões compartilhados da Feature 002 (`BotaoBase`) ainda sinalizam foco e toque apenas pela camada de cor do `InkWell`, prejudicando pessoas com baixa visão ou discromatopsia e quem navega por teclado ou leitor de tela.
2. **Destravamento de canais presos por cadastro assistido abandonado**: quando um cadastro iniciado em modo assistido é interrompido antes da confirmação de posse do canal de contato, a conta permanece indefinidamente pendente de verificação. Como o sistema protege contra enumeração de contas devolvendo uma resposta chamariz para canais já registrados, a pessoa idosa (ou seu acompanhante em nova tentativa legítima) fica impedida para sempre de concluir o cadastro com aquele mesmo e-mail ou telefone.
3. **Entrega real de códigos de verificação e avisos de segurança em produção**: até aqui, apenas o adaptador de desenvolvimento (que escreve em registro interno) existia, impedindo a subida do perfil de produção e impossibilitando que códigos de confirmação ou recuperação e avisos de alteração de senha cheguem de verdade à pessoa usuária quando um provedor de mensageria estiver configurado.
4. **Fidelidade de medição nos testes de cartões e atualização do relatório de pendências**: a suíte de validação do cartão de porta substituía os dados de dimensão da janela por uma tela de altura zero ao testar ampliação de fonte, e o relatório consolidado do que falta para entrega ainda refletia o estado de outubro de 2026.

### Alinhamento com a Constituição do Memora

- **Princípio I (Segurança Acima de Tudo)**: códigos de verificação nunca são gravados em registros de produção; a liberação de contas pendentes abandonadas preserva o tempo constante e a proteção contra enumeração de contas.
- **Princípio II (Segurança Contra Engenharia Social)**: mensagens reais enviadas à pessoa usuária (código de verificação e aviso de senha alterada) usam linguagem literal, nunca incluem links clicáveis nem solicitam senhas ou transferências.
- **Princípio III (Acessibilidade como Requisito)**: todo botão passa a oferecer feedback visual por mais de um sinal além da cor (anel externo de seleção no foco e escala/preenchimento de destaque no toque via `SuperficieTocavel`), mantendo contraste WCAG 2.2 AA, área mínima de 48×48 dp e suporte a texto escalado até 200%.
- **Princípio IV e Documentação Viva**: a especificação antecede a implementação e o relatório vivo de pendências do projeto passa a espelhar fielmente o estado real do repositório.

---

## Clarifications

### Session 2026-11-13

- Q: Como o `BotaoBase` deve implementar o segundo sinal visual de foco e de toque para alinhar os botões da Feature 002 ao restante do aplicativo? (FR-001, FR-002, FR-003) → A: Reusar `SuperficieTocavel` no `BotaoBase`: o foco desenha o anel externo (`MemoraDimensoes.bordaSelecao` por fora via `strokeAlignOutside`) e o estado pressionado aplica `MemoraMovimento.escalaPressionado` (`0.97`, respeitando `disableAnimations`) + preenchimento `cores.destaque` nos botões de fundo transparente (`secundario` e `terciario`).
- Q: Qual deve ser o prazo de validade e o gatilho de remoção de uma conta criada em modo assistido (`PENDENTE_VERIFICACAO`) que nunca teve seu canal confirmado? (FR-004, FR-005, FR-006, FR-007) → A: Expiração em 24 horas sem confirmação do canal, removendo a conta pendente expirada tanto sob demanda (no instante em que chegar um novo cadastro para o mesmo canal após 24h) quanto por limpeza periódica agendada no servidor, mantendo a resposta chamariz (`FR-010`) enquanto a conta tiver menos de 24h.
- Q: Como o adaptador real de envio (`EnviadorDeCodigo` e `NotificadorDeConta`) deve operar quanto ao protocolo de envio, suporte aos tipos de canal (`EMAIL` vs. `TELEFONE`) e ativação entre perfis? (FR-008, FR-009, FR-010, FR-011) → A: SMTP padrão no perfil `producao` + falha rápida na subida se o host SMTP não estiver configurado; envia e-mails reais via SMTP (`SPRING_MAIL_*` / `MEMORA_EMAIL_*`), trata `TELEFONE` de forma explícita sem jamais gravar código em claro no log e mantém `EnviadorDeCodigoEmLog` / `NotificadorDeContaEmLog` restritos a `@Profile("!producao")`.

---

## Threat Modeling (Princípio I)

| Elemento / Ativo | Ameaça Potencial | Impacto | Mitigação Obrigatória |
|---|---|---|---|
| **Canal de contato em conta assistida abandonada** | Negação de serviço permanente ("bloqueio de e-mail/telefone"): terceiro ou tentativa interrompida cria conta assistida sem confirmar o canal e trava o identificador para sempre. | A pessoa idosa legítima nunca consegue se cadastrar nem recuperar acesso com seu próprio e-mail ou telefone. | Contas em estado pendente de verificação que ultrapassarem o prazo de validade são expurgadas (ou substituídas de forma transparente quando expiradas), liberando o canal sem expor se havia tentativa anterior. |
| **Fluxo de cadastro diante de conta pendente recente vs. expirada** | Enumeração de usuários por diferença de resposta ou de tempo entre conta ativa, conta pendente recente e conta pendente expirada. | Atacante descobre quais e-mails ou telefones estão cadastrados no Memora para aplicar golpes direcionados. | Manter resposta idêntica (mesmo código de retorno e estrutura) e executar o cálculo de hash de senha antes da decisão em todos os caminhos. |
| **Código de verificação em trânsito para o provedor de envio** | Vazamento do código de 6 dígitos em logs de erro, métricas ou mensagens de exceção quando o envio externo falha. | Sequestro de conta durante recuperação de senha ou confirmação de canal. | O adaptador de produção nunca inclui o código em claro em logs, exceções ou rastros; falhas de comunicação registram apenas o identificador interno do evento e o tipo de canal. |
| **Aviso de alteração de senha enviado por canal externo** | Golpista imita o aviso do Memora incluindo links maliciosos de "cancelar troca de senha". | Phishing contra a pessoa idosa. | O aviso legítimo é estritamente informativo, sem links externos nem pedidos de dados, orientando a pessoa a abrir diretamente o aplicativo Memora no celular. |

---

## Proteção contra Engenharia Social (Princípio II)

1. **Botões de Ação em Todo o Aplicativo**:
   - *Como um golpista ou erro acidental prejudicaria a pessoa idosa?* Um botão cujo estado pressionado ou focado só muda levemente de tom deixa a pessoa em dúvida se o toque funcionou, levando a múltiplos toques repetidos ou confusão ao usar navegação assistiva.
   - *Mitigação*: O segundo sinal visual provido pela `SuperficieTocavel` (anel externo no foco e redução sutil de escala + preenchimento `destaque` em botões transparentes no toque) confirma inequivocamente onde está o foco e quando o toque foi recebido.

2. **Mensagens de Verificação e Aviso de Troca de Senha**:
   - *Como um golpista tentaria explorar?* Enviando e-mail ou mensagem falsa dizendo *"Sua senha do Memora mudou, clique neste link ou responda com sua senha antiga"*.
   - *Mitigação*: Toda mensagem enviada pelo Memora traz texto curto, acolhedor, sem jargão técnico, **sem nenhum link clicável** e com lembrete explícito: *"O Memora nunca pede sua senha por mensagem nem envia links para clicar."*

3. **Retomada ou Novo Cadastro após Abandono do Modo Assistido**:
   - *Como um familiar mal-intencionado ou golpista tentaria explorar?* Iniciando um cadastro assistido com o e-mail da pessoa idosa e abandonando-o de propósito para impedi-la de criar sua própria conta depois, ou tentando assumir uma conta pendente sem confirmar o canal.
   - *Mitigação*: A conta pendente nunca concede acesso às funcionalidades do aplicativo antes da confirmação do canal e, após expirar sem confirmação, libera o canal para que a pessoa titular possa concluir seu cadastro normalmente.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Perceber Foco e Toque em Qualquer Botão por Mais de um Sinal Visual (Priority: P1)

Seu Jorge, 73 anos, tem baixa sensibilidade a variações sutis de cor e utiliza tanto o toque direto quanto a navegação assistiva no celular. Ao interagir com qualquer botão do Memora (primário, secundário, terciário ou de ação destrutiva), ele percebe imediatamente quando o botão está focado (pelo anel externo de seleção) ou pressionado (pela leve resposta de escala da superfície e preenchimento de destaque nos botões transparentes), sem depender apenas da camada de cor do `InkWell`.

**Why this priority**: Os botões são o principal elemento de decisão em todas as telas do aplicativo. Reutilizar a `SuperficieTocavel` no `BotaoBase` fecha a dívida de acessibilidade entre a fundação do sistema visual (002) e os componentes da Feature 004.

**Independent Test**: Renderizar cada uma das quatro variações de botão nos três temas (claro, escuro e alto contraste) e nas escalas de texto de 100% a 200%, acionando foco por teclado/leitor e pressão por toque, e comprovar a presença do anel externo de foco (`bordaSelecao`) e da resposta de pressão (`escalaPressionado` e `cores.destaque` em fundo transparente) sem quebra de layout.

**Acceptance Scenarios**:

1. **Given** qualquer botão habilitado na tela, **When** ele recebe foco de navegação (teclado ou leitor de tela), **Then** exibe o anel de seleção externo (`MemoraDimensoes.bordaSelecao` desenhado por fora com `strokeAlignOutside`) ao redor do botão, além da indicação de cor.
2. **Given** qualquer botão habilitado na tela, **When** a pessoa mantém o dedo pressionado sobre ele, **Then** a superfície aplica a redução de escala (`MemoraMovimento.escalaPressionado`, respeitando `disableAnimations`) — e, nos botões de fundo transparente (`secundario` e `terciario`), recebe o preenchimento `cores.destaque` — retornando ao estado normal ao soltar ou cancelar o gesto.
3. **Given** um botão desabilitado ou em estado de carregamento, **When** a pessoa tenta tocar ou focar nele, **Then** a superfície permanece inativa (`aoTocar: null`), sem encolher nem disparar ação, e a altura mínima de toque (≥ 48 dp) e a legibilidade em 200% permanecem preservadas.

---

### User Story 2 - Concluir Cadastro Mesmo Após Tentativa Assistida Abandonada no Passado (Priority: P1)

Dona Helena, 69 anos, começou um cadastro com ajuda do neto no fim de semana, mas o celular descarregou antes de confirmarem o código enviado ao e-mail dela. Dias depois, ela tenta se cadastrar novamente com o mesmo e-mail. Em vez de ficar bloqueada para sempre pela tentativa incompleta anterior, o sistema expurga a tentativa pendente já expirada e permite que Dona Helena crie sua conta e receba seu novo código normalmente.

**Why this priority**: Sem o expurgo de contas assistidas abandonadas, qualquer interrupção na etapa de verificação inutiliza permanentemente o e-mail ou telefone da pessoa idosa no Memora.

**Independent Test**: Criar uma conta em modo assistido (que nasce pendente de verificação), avançar o tempo além do prazo de expiração de abandono sem confirmar o canal e realizar um novo cadastro com o mesmo canal, verificando que a conta antiga não confirmada é removida e a nova conta é criada com sucesso.

**Acceptance Scenarios**:

1. **Given** uma conta criada em modo assistido que permaneceu pendente de verificação além do prazo máximo de confirmação (24 horas), **When** um novo cadastro é solicitado com o mesmo canal de contato, **Then** o registro pendente expirado e seus vínculos temporários são removidos e o novo cadastro prossegue normalmente como conta nova.
2. **Given** uma conta ativa (ou uma conta pendente criada há menos de 24 horas ainda dentro da janela legítima de confirmação), **When** um terceiro tenta cadastrar o mesmo canal de contato, **Then** o sistema mantém a conta existente intacta e devolve a resposta chamariz indistinguível (preservando a proteção contra enumeração).
3. **Given** contas pendentes de verificação abandonadas há mais de 24 horas no banco de dados, **When** a rotina periódica de limpeza é executada, **Then** essas contas pendentes expiradas são removidas com segurança sem afetar nenhuma conta ativa.

---

### User Story 3 - Receber Códigos de Verificação e Avisos de Segurança em Produção (Priority: P2)

Quando o Memora opera em ambiente de produção com serviço de envio configurado, Dona Helena recebe no seu e-mail o código de 6 dígitos para confirmar seu canal ou recuperar sua senha esquecida, bem como um aviso claro e sem links caso sua senha seja alterada. Enquanto isso, em ambientes de desenvolvimento ou de demonstração sem credenciais de mensageria, o sistema continua funcionando de forma previsível sem expor segredos em produção.

**Why this priority**: Viabiliza a execução do perfil de produção e o teste completo de recuperação de senha e confirmação de canal por pessoas reais fora do cabo USB.

**Independent Test**: Executar o envio de código de verificação e o aviso de senha alterada com o adaptador de produção ativo apontando para um servidor de e-mail/mensageria de teste (ou mock de transporte), verificando a entrega da mensagem formatada sem links, a ausência do código em claro nos logs e a falha rápida na subida de produção se o envio real estiver exigido sem configuração válida.

**Acceptance Scenarios**:

1. **Given** o ambiente configurado para envio real de mensagens, **When** um código de verificação ou recuperação é solicitado para um canal de e-mail, **Then** a pessoa recebe a mensagem contendo os 6 dígitos, o prazo de validade e o aviso antigolpe, e nenhum log do servidor contém os 6 dígitos em claro.
2. **Given** o ambiente configurado para envio real de mensagens, **When** a senha da conta é alterada, **Then** a pessoa recebe no seu canal verificado uma notificação informativa com seu nome de tratamento e orientação antigolpe, sem nenhum link clicável.
3. **Given** uma falha de rede ou indisponibilidade temporária do servidor de envio externo durante o disparo em produção, **When** o erro é capturado e registrado, **Then** o log registra a falha técnica sem revelar o código de verificação nem dados sensíveis da pessoa.

---

### User Story 4 - Auditar Fielmente a Altura dos Cartões e o Relatório de Pendências do Projeto (Priority: P3)

Um integrante da equipe executa a suíte de testes de interface e consulta o relatório de pendências do projeto antes da entrega final. Os testes do cartão de porta medem o componente dentro de uma janela com dimensões reais em todas as escalas de texto, e o documento de pendências reflete com exatidão o que já foi concluído e o que realmente resta para a banca.

**Why this priority**: Elimina falsos positivos nos testes de layout do cartão principal e garante que a equipe tome decisões com base em documentação atualizada.

**Independent Test**: Executar a suíte de testes do cartão de porta verificando que a altura da janela de teste é preservada ao variar a escala de texto, e inspecionar o relatório `o-que-falta.md` confirmando que todas as referências, contagens de testes e status das funcionalidades 001 a 006 batem com o repositório atual.

**Acceptance Scenarios**:

1. **Given** o ambiente de teste do cartão de porta com ampliação de texto configurada (ex.: 100%, 150%, 200%), **When** o widget de teste é montado, **Then** as dimensões reais da tela simulada são preservadas (nunca zeradas) e todos os testes de estado, contraste e alvo mínimo passam.
2. **Given** o relatório `docs/relatorios/o-que-falta.md`, **When** revisado contra o estado atual da branch, **Then** não lista PRs já encerradas como abertas, reflete as entregas concluídas (manifesto Android, infraestrutura de deploy, fechamento da 004, segurança da 005 e esta feature 006) e apresenta números de testes verificados.

---

### Edge Cases

- **Botão com fundo escuro/colorido (primário ou perigo) focado**: como a `SuperficieTocavel` desenha o anel `bordaSelecao` pelo lado de fora (`BorderSide.strokeAlignOutside`), o anel não invade o preenchimento interno e não faz o layout "pular" quando o foco chega.
- **Tentativa de uso de token de sessão de uma conta assistida já expirada e expurgada**: se o aplicativo tentar confirmar o canal ou renovar sessão com o token emitido mais de 24 horas antes para uma conta pendente que já foi expurgada, o sistema recusa com erro de autenticação limpo, orientando a iniciar novamente.
- **Solicitação de envio para canal do tipo telefone quando apenas provedor de e-mail estiver configurado**: o adaptador de produção deve tratar o canal de forma explícita e segura (sem gravar o código em claro no log e sem travar silenciosamente).
- **Tentativa de subir o perfil `producao` sem credenciais do provedor de envio configuradas**: o sistema deve recusar a inicialização com mensagem clara de configuração ausente, mantendo a garantia de nunca cair silenciosamente no adaptador que grava códigos em log em produção.

---

## Requirements *(mandatory)*

### Functional Requirements

#### Acessibilidade nos Botões (Design System)

- **FR-001**: O componente `BotaoBase` (`primario`, `secundario`, `terciario` e `perigo`) MUST delegar sua superfície interativa à `SuperficieTocavel`, exibindo um segundo sinal visual além da camada de cor do `InkWell` nos estados **focado** e **pressionado**, em conformidade com o Princípio III da Constituição.
- **FR-002**: Quando um botão habilitado estiver **focado**, a `SuperficieTocavel` MUST desenhar o anel de seleção externo (`MemoraDimensoes.bordaSelecao` com `BorderSide.strokeAlignOutside` em `cores.primaria`); quando estiver **pressionado**, MUST aplicar a redução de escala (`MemoraMovimento.escalaPressionado`, respeitando `MediaQuery.disableAnimationsOf`) e, para botões de fundo transparente (`secundario` e `terciario`), preencher o fundo com `cores.destaque`.
- **FR-003**: Todo botão baseado em `BotaoBase` MUST preservar a altura mínima configurada (nunca inferior a `MemoraDimensoes.alvoMinimo` de 48 dp), a semântica de botão para leitores de tela (`Semantics`) e a capacidade de crescer verticalmente com texto ampliado até 200% sem truncar o rótulo e sem usar literais visuais fora de `tokens/`.

#### Ciclo de Vida de Contas Assistidas Abandonadas (`T065b`)

- **FR-004**: Uma conta criada em modo assistido (`PENDENTE_VERIFICACAO`) que não tiver a posse do seu canal confirmada dentro do prazo máximo de **24 horas** a partir da criação MUST ser considerada **abandonada e expirada**.
- **FR-005**: Quando um novo cadastro for solicitado informando um canal de contato vinculado a uma conta `PENDENTE_VERIFICACAO` já expirada (> 24 horas), o sistema MUST remover de forma atômica a conta pendente expirada (junto com seu canal não verificado, códigos, sessões e registros vinculados) e concluir o novo cadastro normalmente.
- **FR-006**: Quando um novo cadastro for solicitado informando um canal vinculado a uma conta `ATIVA` ou a uma conta `PENDENTE_VERIFICACAO` ainda dentro do prazo de 24 horas, o sistema MUST preservar a conta existente e retornar a resposta chamariz indistinguível (FR-010 da Feature 001).
- **FR-007**: O sistema MUST dispor de limpeza periódica automatizada (e acionável em teste) para expurgar contas `PENDENTE_VERIFICACAO` expiradas há mais de 24 horas, registrando apenas a quantidade expurgada sem expor dados pessoais em log.

#### Envio Real de Códigos e Notificações de Conta (`T065a` e `T068`)

- **FR-008**: O sistema MUST disponibilizar uma implementação de produção (`@Profile("producao")`) para envio de códigos de verificação (`EnviadorDeCodigo`) e avisos de alteração de senha (`NotificadorDeConta`) via protocolo SMTP padrão configurável por variáveis de ambiente (`SPRING_MAIL_*` / `MEMORA_EMAIL_*`), mantendo os adaptadores em log restritos a `@Profile("!producao")`.
- **FR-009**: Nenhuma implementação ativa no perfil `producao` MUST registrar o código de verificação em claro em arquivos de log, console, métricas ou mensagens de exceção, sob nenhuma circunstância (sucesso, falha de entrega ou tentativa em canal `TELEFONE` sem gateway SMS).
- **FR-010**: O texto enviado nas mensagens reais de verificação de canal, recuperação de senha e aviso de senha alterada MUST seguir a persona da Memora (português claro, acolhedor, sem jargão), informar o prazo de validade (quando houver código) e incluir aviso explícito contra golpes, sem conter nenhum link externo clicável.
- **FR-011**: Se o perfil `producao` estiver ativo e o host SMTP obrigatório não tiver sido configurado, o sistema MUST falhar imediatamente na subida (`@PostConstruct` / validação de propriedades) com diagnóstico claro, impedindo execução em produção sem canal de entrega funcional.

#### Qualidade de Testes e Documentação Viva

- **FR-012**: A suíte de testes do cartão de porta (`cartao_de_porta_test.dart`) MUST preservar as dimensões da tela simulada do ambiente de teste ao aplicar fatores de escala de texto (`TextScaler`), eliminando a medição em tela de altura zero.
- **FR-013**: O relatório `docs/relatorios/o-que-falta.md` (e a lista de tarefas `specs/001-autenticacao-acessivel/tasks.md` referente a `T065a` e `T065b`) MUST ser atualizado na mesma entrega para refletir com exatidão as tarefas concluídas, o estado das branches/PRs e as contagens reais de testes verificadas.

### Key Entities

- **Conta Pendente de Verificação (`PessoaUsuaria` em estado `PENDENTE_VERIFICACAO`)**: Conta criada durante o fluxo de cadastro assistido cuja posse do canal de contato ainda não foi confirmada. Possui instante de criação (`criadoEm`) usado para determinar sua expiração após 24 horas sem confirmação.
- **Mensagem de Segurança Transacional**: Comunicação enviada à pessoa usuária contendo ou um código de verificação de 6 dígitos (uso único e prazo curto) ou um aviso informativo de alteração de senha, sempre isenta de links externos.
- **Estado Interativo do Botão (`BotaoBase` + `SuperficieTocavel`)**: Conjunto de propriedades visuais e semânticas do botão nos estados normal, focado (anel externo `bordaSelecao`), pressionado (escala `escalaPressionado` + fundo `destaque` quando transparente), carregando e desabilitado, governado por tokens do sistema visual.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% das quatro variantes de botões do sistema (`primario`, `secundario`, `terciario` e `perigo`) utilizam `SuperficieTocavel` e exibem o anel externo de foco (`bordaSelecao`) e a resposta de pressão (`escalaPressionado` e preenchimento `destaque` quando transparente) nos três temas (claro, escuro e alto contraste), comprovado por testes automatizados de componentes.
- **SC-002**: 100% das tentativas de novo cadastro utilizando um canal cujo cadastro assistido anterior foi abandonado há mais de 24 horas concluem com sucesso a criação da nova conta, enquanto 100% das tentativas contra contas ativas ou pendentes recentes (< 24 horas) continuam recebendo resposta indistinguível anti-enumeração.
- **SC-003**: 0 ocorrências de códigos de verificação de 6 dígitos em claro nos logs gerados pelo adaptador de produção em cenários de sucesso e de falha de entrega.
- **SC-004**: 100% dos testes automatizados do aplicativo (incluindo `cartao_de_porta_test.dart` com dimensões reais de janela e os validadores de paleta WCAG 2.2 e de tokens) e 100% dos testes automatizados do backend passam sem avisos ou regressões.

---

## Assumptions

- **Prazo de expiração de conta assistida abandonada (24 horas)**: O cadastro assistido ocorre presencialmente com um acompanhante; se a confirmação do canal não foi concluída em até 24 horas (quando todos os códigos emitidos de 10 minutos já expiraram há muito tempo), a tentativa foi abandonada. O prazo de 24 horas é longo o suficiente para não interromper nenhuma tentativa em andamento no mesmo dia e curto o bastante para destravar a pessoa no dia seguinte.
- **Canal prioritário de envio real em produção (E-mail / SMTP)**: O envio real em produção utiliza protocolo padrão de e-mail (SMTP configurável por variáveis de ambiente como host, porta, usuário, senha e remetente), compatível com qualquer provedor gratuito ou institucional (Gmail App Password, Brevo, Resend SMTP, etc.) sem acoplar o domínio a um fornecedor proprietário. Para canais do tipo SMS/telefone sem gateway contratado, o adaptador de produção rejeita ou sinaliza indisponibilidade de forma limpa sem jamais vazar o código em log.
- **Preservação do perfil padrão no Render gratuito**: Enquanto a variável `SPRING_PROFILES_ACTIVE=producao` não for ativada no ambiente de demonstração gratuita (conforme documentado em `docs/deploy/render.md`), o adaptador de desenvolvimento permanece disponível como fallback explícito de homologação, mas basta configurar as variáveis SMTP e ativar o envio real para operar com entrega completa de e-mails.
