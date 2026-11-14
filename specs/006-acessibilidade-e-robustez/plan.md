# Implementation Plan: 006 — Polimento de Acessibilidade, Robustez de Conta e Rastreabilidade

**Branch**: `feature/006-acessibilidade-e-robustez` | **Date**: 2026-11-13 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/006-acessibilidade-e-robustez/spec.md`

---

## Summary

Fechar quatro pendências técnicas e de acessibilidade do Memora antes da entrega final:
1. **Design System (`BotaoBase`, Feature 002)**: delegar a superfície interativa do `BotaoBase` para a `SuperficieTocavel` (Feature 004), garantindo um segundo sinal visual além da cor do `InkWell` em todas as 4 variantes de botão (`primario`, `secundario`, `terciario`, `perigo`) — anel externo `MemoraDimensoes.bordaSelecao` no foco e escala `MemoraMovimento.escalaPressionado` + fundo `cores.destaque` nos botões transparentes quando pressionados.
2. **Ciclo de Vida de Contas Assistidas Abandonadas (`T065b`, Feature 001)**: expurgar contas em estado `PENDENTE_VERIFICACAO` que ultrapassarem **24 horas** sem confirmação de posse do canal, tanto sob demanda durante novo cadastro com o mesmo canal quanto por rotina agendada (`ServicoDeExpurgoDeContaPendente`), preservando a resposta chamariz (`FR-010`) e o tempo constante para contas ativas ou pendentes recentes (`<= 24h`).
3. **Envio Real de Códigos e Avisos de Conta em Produção (`T065a` e `T068`, Feature 001)**: implementar `EnviadorDeCodigoPorEmail` e `NotificadorDeContaPorEmail` sob `@Profile("producao")` via SMTP padrão (`spring-boot-starter-mail`), com validação rápida na subida (`@PostConstruct`), mensagens sem links na voz da Memora e garantia de zero código em claro em logs ou exceções.
4. **Higiene de Testes e Documentação Viva (`FR-012` e `FR-013`)**: corrigir `app/test/design_system/cartao_de_porta_test.dart` para usar `MediaQuery.of(context).copyWith(...)` preservando o tamanho real da janela de teste, e atualizar `docs/relatorios/o-que-falta.md` e `specs/001-autenticacao-acessivel/tasks.md` com o estado atual verificado do projeto.

---

## Technical Context

**Language/Version**: Dart `^3.11.4` / Flutter `3.47.x` (Frontend) e Java `21` / Spring Boot `4.1.0` (Backend)

**Primary Dependencies**:
- Frontend: `flutter/material.dart`, Design System próprio (`tokens/`, `SuperficieTocavel`, `BotaoBase`).
- Backend: `spring-boot-starter-webmvc`, `spring-boot-starter-data-jpa`, `spring-boot-starter-security`, `spring-boot-starter-mail` (adicionado nesta feature), `spring-boot-starter-flyway`, `bcprov-jdk18on`.

**Storage**: PostgreSQL 16 (esquema Flyway `V1`–`V11` existente; sem necessidade de nova migration SQL).

**Testing**: `flutter test` (`WidgetTester`, testes de acessibilidade/semântica/contraste) + JUnit 5 / Spring Boot Test / Testcontainers PostgreSQL (`mvnw test`) + `validar_paleta.py` e `validar_tokens.py`.

**Target Platform**: Android (API 24+, smartphones de pessoas 65+) e Servidor Linux/Docker (Render + Neon PostgreSQL).

**Project Type**: Mobile App (`app/`) + REST API Backend (`backend/`).

**Performance Goals**:
- Animações de foco/toque em botões a 60 fps (`MemoraMovimento.rapido` = 150 ms, ou `0 ms` com `disableAnimations`).
- Custo de tempo constante no cadastro (Argon2id executado antes da verificação de canal tanto no caminho novo, quanto no expurgo de pendente expirada, quanto no chamariz).

**Constraints**:
- Zero literais visuais (`Color(`, `Colors.`, `EdgeInsets`, `TextStyle(`, `BorderRadius`, `SizedBox(width/height:`) fora de `app/lib/design_system/tokens/` (verificado por `validar_tokens.py`).
- Contraste WCAG 2.2 AA verificado por `validar_paleta.py`.
- Zero código de verificação em claro em logs/exceções no perfil `producao`.

**Scale/Scope**: 4 variantes de botão no Design System, 2 adaptadores de produção SMTP + 1 serviço de expurgo no módulo `autenticacao` do backend, 1 arquivo de teste ajustado + novos testes unitários/integração e 2 documentos de rastreabilidade atualizados.

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio da Constituição | Status Pré-Pesquisa | Status Pós-Design (Fase 1) | Evidência / Justificativa |
|---|---|---|---|
| **I. Segurança Acima de Tudo** | ✅ PASS | ✅ PASS | Threat Modeling na `spec.md`; Argon2id executado antes da decisão em `ServicoDeCadastro`; `EnviadorDeCodigoPorEmail` nunca loga `codigoEmClaro`. |
| **II. Segurança Contra Engenharia Social** | ✅ PASS | ✅ PASS | E-mails de código e de senha alterada não possuem links clicáveis e trazem o lembrete antigolpe explícito da Memora. |
| **III. Acessibilidade como Requisito** | ✅ PASS | ✅ PASS | `BotaoBase` passa a usar `SuperficieTocavel`, entregando anel externo `bordaSelecao` no foco e escala/destaque no toque, mantendo ≥ 48 dp e escala até 200%. |
| **IV. Especificação Antes de Código** | ✅ PASS | ✅ PASS | `spec.md`, `clarify`, `research.md`, `data-model.md`, `contracts/` e `quickstart.md` concluídos antes da implementação. |
| **V. Arquitetura Limpa e Feature-First** | ✅ PASS | ✅ PASS | Portas `EnviadorDeCodigo` e `NotificadorDeConta` permanecem em `aplicacao/` e os adaptadores SMTP entram em `infra/`; `BotaoBase` reutiliza `SuperficieTocavel`. |
| **VI. A IA Nunca Age Sozinha** | ✅ N/A | ✅ N/A | Esta feature não altera o comportamento autônomo da assistente de IA. |
| **VII. Ensinar, Não Substituir** | ✅ PASS | ✅ PASS | Preserva a autonomia da pessoa idosa ao destravar seu canal após abandono do modo assistido e dar feedback visual claro nos botões. |

---

## Project Structure

### Documentation (this feature)

```text
specs/006-acessibilidade-e-robustez/
├── plan.md                                  # Este plano de implementação
├── research.md                              # Decisões técnicas R1 a R4 (Fase 0)
├── data-model.md                            # Ciclo de vida de PessoaUsuaria, config SMTP e estados de BotaoBase (Fase 1)
├── quickstart.md                            # Roteiro de verificação V1 a V5 (Fase 1)
├── contracts/
│   └── componentes-e-servicos.md            # Contratos de BotaoBase, EnviadorDeCodigoPorEmail, NotificadorDeContaPorEmail e cadastro (Fase 1)
├── checklists/
│   └── requirements.md                      # Checklist de qualidade da especificação (16/16 aprovados)
└── tasks.md                                 # Gerado na Fase 2 pelo comando /speckit-tasks
```

### Source Code (repository root)

```text
app/
├── lib/
│   └── design_system/
│       └── componentes/
│           ├── botoes/
│           │   └── botao_base.dart                  # Delega superfície interativa para SuperficieTocavel
│           └── toque/
│               └── superficie_tocavel.dart          # Reutilizada pelo BotaoBase
└── test/
    └── design_system/
        ├── cartao_de_porta_test.dart                # Preserva dimensões da tela com MediaQuery.of(context).copyWith
        └── decisao_e_entrada_test.dart              # Novos testes do segundo sinal de foco e toque nos 4 botões

backend/
├── pom.xml                                          # Adiciona spring-boot-starter-mail
└── src/
    ├── main/
    │   ├── java/br/fatec/memora/autenticacao/
    │   │   ├── aplicacao/
    │   │   │   ├── ServicoDeCadastro.java           # Expurga conta PENDENTE_VERIFICACAO expirada (>24h) antes de criar nova
    │   │   │   └── ServicoDeExpurgoDeContaPendente.java # Limpeza sob demanda e agendada (@Scheduled) de contas pendentes >24h
    │   │   ├── dominio/
    │   │   │   └── PessoaUsuaria.java               # Método estaPendenteExpirada(Instant, Duration)
    │   │   └── infra/
    │   │       ├── ConfiguracaoDeEnvioPorEmail.java # Propriedades e validação @PostConstruct para SMTP em produção
    │   │       ├── EnviadorDeCodigoPorEmail.java    # Adaptador @Profile("producao") para EnviadorDeCodigo
    │   │       ├── NotificadorDeContaPorEmail.java  # Adaptador @Profile("producao") para NotificadorDeConta
    │   │       ├── RepositorioEventoAutenticacao.java # deleteByPessoaId para limpeza segura antes de excluir conta pendente
    │   │       └── RepositorioPessoaUsuaria.java    # findByEstadoAndCriadaEmBefore para expurgo agendado
    │   └── resources/
    │       └── application.properties               # Propriedades SMTP / remetente / prazo de expurgo documentadas
    └── test/
        └── java/br/fatec/memora/autenticacao/
            ├── api/
            │   └── ExpurgoDeContaPendenteTest.java  # Testes integrados do destravamento de canal após 24h e limpeza agendada
            └── infra/
                ├── EnviadorDeCodigoPorEmailTest.java    # Testes unitários/contexto do envio SMTP e não-vazamento em log
                └── NotificadorDeContaPorEmailTest.java  # Testes unitários/contexto do aviso de troca de senha via SMTP

docs/
└── relatorios/
    └── o-que-falta.md                               # Atualizado com o estado real das PRs, features 001-006 e contagens de testes

specs/
└── 001-autenticacao-acessivel/
    └── tasks.md                                     # Marca T065a e T065b como concluídas
```

**Structure Decision**: Mantida a arquitetura multi-projeto existente (`app/` em Flutter Feature-First + Design System centralizado e `backend/` em Spring Boot seguindo separação `api` / `aplicacao` / `dominio` / `infra` / `seguranca`), sem criar novos módulos de topo.

---

## Complexity Tracking

Nenhuma violação da Constituição. Tabela não aplicável.
