# ADR 001 — Linguagem e framework do backend

- **Status:** Aceito
- **Data:** 2026-07-24
- **Decisores:** Equipe NewXz (Eduardo Juncker Toras, Eduardo Moraes Trevisan, Henrique Moreira Sandrini)
- **Contexto normativo:** [Constituição do Projeto](../../.specify/memory/constitution.md) — Princípio I (Segurança Acima de Tudo)

---

## Contexto

O frontend do Memora será desenvolvido em **Flutter + Dart**, alterando a decisão
original do Arquivo X, que previa Android nativo com Java.

Essa mudança reabriu a questão do backend. O documento acadêmico original citava
**Firebase**; o direcionamento atual exige **backend próprio, REST, PostgreSQL,
JWT com refresh token rotativo**. Era necessário decidir a linguagem e o framework.

A decisão é relevante porque o público-alvo — pessoas idosas com baixa familiaridade
digital — é o alvo preferencial de golpes no Brasil. A Constituição estabelece
segurança como princípio inegociável, com prioridade sobre prazo, performance e
conveniência de implementação.

## Decisão

**Backend em Java com Spring Boot.**

Stack complementar:

| Item | Escolha |
|---|---|
| Linguagem | Java (LTS) |
| Framework | Spring Boot |
| Segurança | Spring Security |
| Banco | PostgreSQL |
| Acesso a dados | Spring Data JPA |
| Autenticação | JWT curto + Refresh Token rotativo |
| Hash de senha | Argon2id (via Spring Security `Argon2PasswordEncoder`) |

## Alternativas consideradas

### A. Dart + Serverpod

Backend em Dart, unificando a linguagem em todo o stack.

**A favor:**
- Uma única linguagem para todo o time — sem troca de contexto.
- Cliente Flutter tipado gerado automaticamente; o contrato app↔API não diverge.
- Módulo de autenticação incluído, reduzindo código de segurança escrito à mão.
- ORM, migrations e code generation integrados.

**Contra:**
- Paradigma **RPC**, não REST. O web server para rotas REST customizadas ainda é
  experimental — conflita com o requisito de API REST versionada.
- Ecossistema de segurança consideravelmente menor. Parte das proteções exigidas
  pela Constituição (rate limiting, hardening específico) precisaria ser escrita
  pela equipe.
- Poucos desenvolvedores experientes na tecnologia; suporte comunitário limitado.
- Framework fortemente opinativo — sair dele depois é caro.

### B. Dart + Dart Frog

Backend em Dart com framework minimalista, estilo Express.

**A favor:** REST nativo, leve, linguagem única no stack.
**Contra:** autenticação, ORM e todas as proteções de segurança seriam
implementadas pela equipe. Inaceitável sob o Princípio I.

### C. Node.js + NestJS

**A favor:** arquitetura em camadas imposta pelo framework, ecossistema de
segurança maduro, farta documentação.
**Contra:** introduz um terceiro ecossistema (TypeScript) que **nenhum membro da
equipe domina**, somado ao aprendizado simultâneo de Flutter.

### D. Java + Spring Boot — *escolhida*

## Justificativa

### 1. A equipe já conhece Java

O Arquivo X registra que o projeto seria desenvolvido em Java. A migração para
Flutter já impõe o aprendizado de Dart no frontend. Colocar Dart também no backend
significaria a equipe aprender **tudo** simultaneamente, sem base de conhecimento
prévio em nenhuma camada.

Manter Java no backend preserva um domínio técnico existente e concentra o esforço
de aprendizado em uma única frente: o Flutter.

### 2. Spring Security é o ecossistema mais maduro disponível

A Constituição exige mitigação explícita de: SQL Injection, XSS, CSRF, SSRF, IDOR,
Path Traversal, Command Injection, Mass Assignment, Enumeração de Usuários,
Session Fixation, Clickjacking e Timing Attacks — além de Argon2id, rate limiting,
proteção contra brute force e revogação de sessão.

No Spring Security, a maior parte disso é **configuração de um framework auditado
há duas décadas**. Nas alternativas em Dart, uma parcela relevante seria código
autoral da equipe.

> Autenticação escrita à mão é a falha mais comum e mais grave em projetos
> acadêmicos. Num aplicativo cujo público é o mais visado por golpes digitais,
> esse risco é inaceitável sob o Princípio I.

### 3. A integração IoT exige REST

O sensor de queda (ESP32) comunicará com a API via REST puro. Spring é REST-nativo
e versionável. O modelo RPC do Serverpod criaria uma exceção arquitetural já na
primeira integração externa.

### 4. Coerência com a documentação acadêmica

O RNF007 do Arquivo X já especifica Java. Com esta decisão, a emenda necessária ao
documento se restringe à camada de frontend (Java/Android → Flutter), sem
contradizer a camada de backend.

## Consequências

### Positivas

- Proteções de segurança majoritariamente delegadas a framework auditado.
- Reaproveitamento do conhecimento existente da equipe.
- REST versionado nativo, pronto para o cliente Flutter e para o dispositivo IoT.
- Decisão defensável academicamente, com trade-offs registrados.

### Negativas

- **Duas linguagens no repositório** (Dart e Java). Custo de verbosidade e de
  manutenção de dois toolchains.
- **Sem cliente tipado gerado.** Os DTOs do Flutter podem divergir do contrato da
  API. *Mitigação:* especificação OpenAPI como fonte da verdade, com geração do
  cliente Dart a partir dela.
- Setup inicial e consumo de memória maiores que os das alternativas em Dart.

### Neutras

- A Constituição menciona "REST API" — esta decisão **mantém** esse requisito
  intacto, diferentemente da alternativa Serverpod, que exigiria emenda.

## Validação pendente

A ser confirmado durante o `/speckit-plan` da primeira feature de autenticação:

- [ ] Configuração de `Argon2PasswordEncoder` com parâmetros adequados
- [ ] Estratégia de rotação e revogação de refresh token
- [ ] Rate limiting e proteção contra brute force no endpoint de login
- [ ] Proteção contra enumeração de usuários nas mensagens de erro
- [ ] Pipeline de geração do cliente Dart a partir do OpenAPI

## Revisão

Esta decisão deve ser reavaliada se:

- A equipe concluir que manter dois toolchains inviabiliza o prazo; **ou**
- A integração IoT for removida do escopo **e** o requisito de REST for flexibilizado
  — cenário no qual o Serverpod voltaria a ser competitivo pela unificação de linguagem.
