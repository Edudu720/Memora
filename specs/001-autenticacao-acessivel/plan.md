# Implementation Plan: Autenticação Acessível

**Branch**: `feature/001-autenticacao-acessivel` | **Date**: 2026-07-24 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-autenticacao-acessivel/spec.md`

---

## Summary

Autenticação completa do Memora — cadastro, entrada, recuperação de acesso, saída e
cadastro assistido por familiar — para pessoas idosas com pouca familiaridade
digital.

**Abordagem técnica**: aplicativo Flutter consumindo uma API REST em Spring Boot
([ADR 001](../../docs/architecture/adr-001-linguagem-do-backend.md)). Segurança
delegada ao Spring Security com **parâmetros explícitos**, nunca padrões de
biblioteca. Contrato definido em OpenAPI, com o cliente Dart **gerado** a partir
dele — decisão que fecha a fragilidade registrada no ADR.

A tensão central desta feature é entre **segurança** e **simplicidade para o
usuário**, e ela foi resolvida em favor das duas: sessão de acesso curta com
refresh longo e rotativo mantém a pessoa conectada sem sacrificar revogabilidade.

---

## Technical Context

**Language/Version**: Dart 3.x (Flutter 3.x) no aplicativo · Java 21 LTS no backend

**Primary Dependencies**:
- Backend — Spring Boot, Spring Security, Spring Data JPA, BouncyCastle (exigido
  pelo Argon2), Bucket4j, springdoc-openapi
- Aplicativo — `flutter_secure_storage`, cliente gerado via OpenAPI Generator
  (`dart-dio`), `flutter_appauth` para o fluxo social

**Storage**: PostgreSQL 16+

**Testing**: JUnit 5 + Testcontainers no backend · `flutter_test` com
`meetsGuideline` para acessibilidade no aplicativo

**Target Platform**: Android (público-alvo usa Android) · API em contêiner Linux

**Project Type**: Aplicativo móvel + API

**Performance Goals**:
- Resposta de autenticação abaixo de 2 s (RNF003 do documento acadêmico)
- Hash de senha entre 250 ms e 500 ms — **abaixo disso significa parâmetro fraco**

**Constraints**:
- Interface utilizável com texto a 200% e área de toque de 48 dp
- Contraste mínimo WCAG 2.2 AA
- Nenhuma credencial em armazenamento comum, log ou cache

**Scale/Scope**: escala acadêmica (centenas de contas). 9 endpoints, 6 entidades,
5 telas.

---

## Constitution Check

*GATE: precisa passar antes da Fase 0. Reavaliado após a Fase 1.*

| Princípio | Como o plano atende | Antes | Depois |
|---|---|---|---|
| **I — Segurança acima de tudo** | Argon2id acima do mínimo OWASP (R1); rotação com detecção de reuso (R2); resposta uniforme em tempo (R3); rate limiting em duas camadas (R4) | ✅ | ✅ |
| **II — Engenharia social** | Código em vez de link (R5); WebView proibida no login social (R6); nenhum campo de senha de terceiro no app | ✅ | ✅ |
| **III — Acessibilidade** | Verificação **automatizada** com matchers do Flutter (R9), não inspeção visual | ✅ | ✅ |
| **IV — Spec antes de código** | Nenhuma linha escrita. Spec aprovada e clarificada precede este plano | ✅ | ✅ |
| **V — Arquitetura limpa** | Feature-First no app; camadas no backend; sem lógica de negócio em widget | ✅ | ✅ |
| **VI — IA nunca age sozinha** | A assistente não participa deste fluxo. FR-047 proíbe qualquer contato com credencial | ✅ | ✅ |
| **VII — Ensinar, não substituir** | Modo assistido devolve o aparelho na etapa da senha e conduz a primeira entrada sozinha (FR-059 a FR-063) | ✅ | ✅ |

**Resultado**: nenhuma violação. Nenhuma justificativa necessária em Complexity Tracking.

### Padrão técnico obrigatório verificado

| Regra da Constituição | Situação |
|---|---|
| Token apenas em `flutter_secure_storage` | ✅ R7 |
| Nenhum secret hardcoded | ✅ Chaves de provedor ficam no backend |
| Senha com Argon2id | ✅ R1, com parâmetro acima do padrão da biblioteca |
| Toda validação repetida no servidor | ✅ Garantido por construção pelo cliente gerado (R8) |
| API com versionamento, auditoria, timeout, tratamento padronizado de erro | ✅ Contrato em `/v1`, esquema `Erro` único |
| Classificação de sensibilidade por campo | ✅ [data-model.md](data-model.md) |
| Nunca expor ID interno desnecessário | ✅ UUID em vez de sequencial |

---

## Project Structure

### Documentation (this feature)

```text
specs/001-autenticacao-acessivel/
├── spec.md              # O quê e por quê (aprovado)
├── plan.md              # Este arquivo
├── research.md          # Fase 0 — 10 decisões técnicas
├── data-model.md        # Fase 1 — 6 entidades classificadas
├── contracts/
│   └── openapi.yaml     # Fase 1 — fonte da verdade do contrato
├── quickstart.md        # Fase 1 — 10 cenários de validação
└── checklists/
    └── requirements.md  # Validação de qualidade da spec
```

### Source Code (repository root)

```text
backend/
├── src/main/java/br/fatec/memora/
│   ├── autenticacao/
│   │   ├── api/                 # Controllers e DTOs do contrato
│   │   ├── dominio/             # Entidades e regras de negócio
│   │   ├── infra/               # Repositórios, envio de código, provedores
│   │   └── seguranca/           # Argon2, rotação de token, rate limiting
│   ├── comum/                   # Tratamento de erro, auditoria, trace
│   └── MemoraApplication.java
├── src/main/resources/
│   └── db/migration/            # Migrations versionadas
└── src/test/java/               # JUnit 5 + Testcontainers

app/
├── lib/
│   ├── core/                    # Erros, constantes, utilitários
│   ├── design_system/           # Tokens e componentes (dependência bloqueante)
│   ├── features/
│   │   └── autenticacao/
│   │       ├── data/            # Repositórios sobre o cliente gerado
│   │       ├── domain/          # Entidades e casos de uso
│   │       └── presentation/    # Telas e controllers
│   ├── services/
│   │   └── api/                 # Cliente gerado — NÃO editar à mão
│   ├── shared/
│   ├── l10n/
│   └── app.dart
└── test/
    ├── acessibilidade/          # Testes com meetsGuideline
    ├── integracao/
    └── unidade/
```

**Structure Decision**: estrutura de aplicativo móvel + API, em dois diretórios de
primeiro nível (`backend/` e `app/`), refletindo as duas linguagens do ADR 001. No
aplicativo, a organização é **Feature-First** conforme o Princípio V — a
autenticação é um módulo isolado com suas três camadas. O cliente da API vive em
`services/api/` porque é infraestrutura compartilhada, não pertence a nenhuma
feature, e é **gerado**.

---

## Complexity Tracking

> Preenchido apenas quando o Constitution Check aponta violação a justificar.

**Não se aplica.** Nenhuma violação identificada, antes ou depois do desenho.

---

## Dependência bloqueante

**O Design System não existe.** Ele é pré-requisito de implementação — não dá para
construir telas acessíveis sem tokens de cor e tipografia validados em contraste.

O R10 levantou quatro problemas do protótipo que os tokens precisam corrigir: duas
linguagens visuais concorrentes, fonte serifada no chatbot, campos de dado com
aparência de botão no perfil, e botões SIM/NÃO reprovando em contraste e área de
toque.

**Recomendação**: tratar o Design System como **feature 002**, especificada e
planejada separadamente, e não como tarefa embutida aqui. Ele serve todas as
features seguintes, não apenas a autenticação.

---

## Riscos conhecidos

| Risco | Impacto | Mitigação |
|---|---|---|
| Módulo de auth do Spring Security não cobrir rotação de refresh como precisamos | Reescrita de parte da sessão | Rotação é implementada por nós sobre o Spring Security, não delegada a ele. Já previsto em R2 |
| `flutter_secure_storage` quebrar em build ofuscado | Credencial exposta ou app quebrado | V8 exige validação em release com ofuscação, não em debug |
| Cliente gerado divergir por edição manual | Volta o problema que o ADR 001 registrou | Regra de processo em R8: cliente é versionado e nunca editado à mão |
| Custo de SMS inviabilizar telefone como canal | Recuperação incompleta | D1 permite e-mail como alternativa; nenhum caminho depende só de SMS |
| Teste com pessoas idosas não acontecer por prazo | SC-001 a SC-004 não verificáveis | V10 é portão de saída explícito. Sem ele a feature não é dada como pronta |

---

## Fase seguinte

`/speckit-tasks` — quebrar este plano em tarefas acionáveis e ordenadas, respeitando
a dependência do Design System.
