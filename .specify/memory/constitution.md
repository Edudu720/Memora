# Constituição do Projeto Memora

> Este documento é a **fonte da verdade** do projeto. Nenhuma especificação, plano,
> tarefa ou linha de código pode contrariá-lo. Em caso de conflito entre este
> documento e qualquer outra instrução, **a Constituição vence**.

**Produto:** Memora — companheiro digital que ensina pessoas idosas a usar smartphones Android.
**Equipe:** NewXz — Eduardo Juncker Toras, Eduardo Moraes Trevisan, Henrique Moreira Sandrini.
**Contexto acadêmico:** Projeto Integrador — FATEC Americana, CST em Análise e Desenvolvimento de Sistemas.

---

## Princípios Fundamentais

### I. Segurança Acima de Tudo (INEGOCIÁVEL)

Segurança tem prioridade **maior** que velocidade de desenvolvimento, facilidade de
implementação, performance, prazo e conveniência. Havendo conflito entre
funcionalidade e segurança, a segurança sempre vence.

- Nenhuma funcionalidade começa sem **Threat Modeling** documentado na spec:
  quais dados sensíveis existem, quem acessa, quais ataques são possíveis, qual o
  impacto, como mitigar, como monitorar, como registrar em log.
- Todo endpoint é considerado **público e hostil** até ser explicitamente protegido.
- Qualquer integrante (humano ou agente de IA) tem **autoridade para bloquear**
  uma implementação insegura e exigir alternativa.

**Por quê:** o público-alvo é o mais visado por golpes digitais no Brasil. Uma falha
aqui não gera bug — gera vítima.

### II. Segurança Contra Engenharia Social (INEGOCIÁVEL)

Para **cada tela**, a spec deve responder: *"Como um golpista tentaria explorar esta tela?"*

- Nunca usar mensagens ambíguas. Linguagem literal, curta, sem jargão.
- Sempre avisar, de forma explícita, quando: um link externo for aberto, outro
  aplicativo for iniciado, o usuário sair do Memora, dados forem compartilhados.
- Sempre explicar **o motivo** de cada permissão solicitada, em linguagem comum.
- Ações irreversíveis devem ser **deliberadamente difíceis**: confirmação em duas
  etapas, sem botão destrutivo adjacente ao botão comum.
- Confirmações acidentais devem ser estruturalmente impossíveis.

### III. Acessibilidade como Requisito, Não como Ajuste

*"Um idoso conseguiria usar isso sozinho?"* — se a resposta não for um sim confiante,
a funcionalidade não está pronta.

Todo componente entregue deve ter, sem exceção:
- Contraste mínimo **WCAG 2.2 AA** (4.5:1 texto normal, 3:1 texto grande e ícones).
- Área de toque mínima de **48x48 dp**, com espaçamento mínimo de 8 dp entre alvos.
- Suporte a texto escalável até **200%** sem quebra de layout ou perda de conteúdo.
- Rótulos semânticos para **TalkBack/VoiceOver** em todo elemento interativo.
- Feedback visual explícito para todo estado (normal, foco, pressionado, carregando,
  erro, sucesso, desabilitado).
- Ícones acompanhados de texto — **nunca ícone isolado** como única affordance.
- Cor nunca é o único portador de significado.

### IV. Especificação Antes de Código (INEGOCIÁVEL)

Nenhuma implementação começa sem especificação aprovada. O código apenas
**implementa** a especificação; ele nunca a define.

Fluxo obrigatório, sem pular etapas:
1. **Compreensão** — ler documentação, arquitetura, requisitos, dependências, impacto.
2. **Análise de Design** — extrair do Figma/protótipo. Nunca inventar telas ou supor componentes.
3. **UX Review** — ação principal, carga informacional, orientação, risco de erro,
   recuperação, confirmação, feedback, leitura por um idoso.
4. **Especificação** — user story, objetivo, fluxo, critérios de aceite, regras de
   negócio, estados, edge cases, erros, validações, permissões, dependências, threat model.
5. **Arquitetura** — widgets, controllers, repositories, services, use cases,
   entidades, banco, APIs.
6. **Implementação** — somente após aprovação explícita.

Ambiguidade encontrada = pergunta feita, nunca suposição registrada.

### V. Arquitetura Limpa e Feature-First

- **Clean Architecture** com separação estrita: `domain` não conhece `data` nem `presentation`.
- **Feature-First**: cada funcionalidade isolada em seu próprio módulo.
- **Repository Pattern** para todo acesso a dados.
- **SOLID** aplicado; **MVVM** onde fizer sentido.
- Proibido: God Classes, código duplicado, lógica de negócio dentro de widgets.
- Componente reutilizável é a regra; componente local é a exceção justificada.

### VI. A IA Nunca Age Sozinha (INEGOCIÁVEL)

A IA Memora é um agente **educador**, não um executor autônomo.

- A IA **nunca** executa ação sem confirmação clara e específica do usuário.
- Ações que sempre exigem confirmação: enviar mensagem, apagar dados, realizar
  pagamento, abrir link externo, compartilhar localização, ligar para alguém,
  alterar configurações do aparelho, acessar contas.
- A IA **jamais** possui permissões administrativas.
- Toda ação executada pela IA gera **log auditável**.
- Nunca confiar apenas na saída do modelo: toda ação crítica passa por validação
  determinística no backend.

**Persona (obrigatória em todo texto da IA):** paciente, acolhedora, didática.
Nunca usa termos técnicos. Nunca culpa o usuário. Explica cada passo. Incentiva autonomia.
Prefere *"Vamos fazer isso juntos 😊"* a *"Pronto."*

### VII. Ensinar, Não Substituir

O Memora existe para gerar **autonomia**, não dependência. Toda funcionalidade que
executa algo pelo usuário deve oferecer o caminho de **ensinar o passo a passo**.
Se uma feature apenas resolve sem ensinar, ela precisa de justificativa explícita na spec.

---

## Padrões Técnicos Obrigatórios

### Stack

| Camada | Tecnologia |
|---|---|
| Frontend | Flutter + Dart |
| Backend | REST API própria |
| Banco | PostgreSQL (relacional) |
| Autenticação | JWT curto + Refresh Token rotativo |
| Storage | Cloud Storage |

### Segurança — Flutter

- Tokens **apenas** em `flutter_secure_storage`. **Nunca** em `SharedPreferences`.
- Nenhum secret, API key ou URL sensível hardcoded — chaves vêm do backend.
- Sem dados sensíveis em cache ou em logs de produção.
- Builds de produção obfuscadas; logs removidos.
- Bloqueio de screenshot em telas críticas.
- Detecção de root/jailbreak quando aplicável.
- Validação no Flutter é conveniência de UX; **toda validação crítica é refeita no backend**.

### Segurança — Backend e API

- HTTPS obrigatório. Nada sensível em texto puro, em trânsito ou em repouso.
- Senhas com **Argon2id** (preferencial) ou bcrypt. Tokens nunca em texto simples.
- Rate limiting, proteção contra brute force e replay.
- Mitigação obrigatória: SQL Injection, XSS, CSRF, SSRF, IDOR, Path Traversal,
  Command Injection, Mass Assignment, Enumeração de Usuários, Session Fixation,
  Clickjacking, Timing Attacks.
- Toda API possui: versionamento, autenticação, autorização, auditoria, logs,
  Trace ID, Request ID, timeout, retry, circuit breaker, validação de entrada e saída,
  tratamento padronizado de erros.
- **Nunca** retornar stack trace, erro interno, estrutura do banco ou ID interno desnecessário.

### Segurança — Banco de Dados

Todo campo é classificado como **Público**, **Interno**, **Confidencial** ou **Sensível**.
Campos sensíveis exigem criptografia em repouso. Senhas, tokens, OTP e códigos
nunca são armazenados em texto puro. Backup, auditoria, versionamento e recuperação
são previstos desde a modelagem.

### Design System

Gerado e centralizado, nunca improvisado por tela: Typography, Colors, Spacing,
Radius, Elevation, Animations, Buttons, Cards, Dialogs, BottomSheets, TextFields,
AppBar, Icons — em **tema claro e tema escuro**.

### Estrutura de Pastas (Flutter)

```
lib/
  core/           # erros, constantes, utilitários transversais
  shared/         # widgets e helpers compartilhados
  features/       # uma pasta por feature (data / domain / presentation)
  design_system/  # tokens e componentes visuais
  l10n/           # internacionalização
  services/       # integrações externas
  app.dart
```

---

## Fluxo de Trabalho e Qualidade

### Ciclo SDD (Spec Kit)

`/speckit-constitution` → `/speckit-specify` → `/speckit-clarify` → `/speckit-plan`
→ `/speckit-checklist` → `/speckit-tasks` → `/speckit-analyze` → `/speckit-implement`

Cada feature vive em um branch próprio com sua pasta de specs versionada.

### Git e Colaboração

- **Nunca** commitar direto na branch principal.
- Um branch por feature: `feature/<numero>-<slug>`.
- Commits em **Conventional Commits** (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`).
- Toda Pull Request passa por **revisão de segurança** obrigatória.
- Specs e código andam juntos no mesmo PR — spec desatualizada bloqueia o merge.

### Revisão Obrigatória ao Fim de Cada Feature

Código · UX · Acessibilidade · Performance · Segurança · Arquitetura.
Cada revisão registra melhorias futuras identificadas.

### Documentação Viva

`/specs`, `/docs`, `/docs/architecture`, `CHANGELOG.md` e `ROADMAP.md` são
atualizados **na mesma PR** que altera o comportamento. Documentação defasada é tratada como defeito.

---

## Governança

Esta Constituição **supersede** qualquer outra prática, preferência individual ou
pressa de prazo.

- Emendas exigem: justificativa escrita, aprovação da equipe e registro de versão.
- Toda PR deve verificar conformidade com estes princípios.
- Complexidade adicionada precisa ser justificada — na dúvida, escolha o simples.
- Princípios marcados **(INEGOCIÁVEL)** não admitem exceção; admitem apenas
  emenda formal com aprovação unânime da equipe.

**Versão**: 1.0.0 | **Ratificada**: 2026-07-24 | **Última alteração**: 2026-07-24
