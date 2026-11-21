# Implementation Plan: Análise Antigolpes de Links e Mensagens Estranhas

**Branch**: `feature/016-analise-golpes` | **Date**: 2026-11-21 | **Spec**: [spec.md](./spec.md)

**Input**: Especificação da funcionalidade em `/specs/016-analise-golpes/spec.md`

## Summary

Implementar no aplicativo Memora (Flutter) e na API (Spring Boot) uma funcionalidade dedicada de análise de links e mensagens estranhas contra golpes (`016-analise-golpes`). A entrega combina uma tela acessível em 1 toque a partir do Início (e também pela Ajuda, preservando o Hub com 7 portas), um endpoint autenticado `POST /v1/golpes/analisar` com motor heurístico determinístico, integração com Gemini REST (`ADR 002`) protegida por sanitizador pós-IA de piso monotônico e limite de taxa por conta, além de fallback local offline automático no aplicativo (`AnalisadorLocalDeGolpes`) quando não há conexão ou o servidor está indisponível.

## Technical Context

**Language/Version**: Dart 3.13.5 / Flutter 3.47.7 (Frontend) · Java 21 / Spring Boot 4.1.0 (Backend)

**Primary Dependencies**:
- **Flutter**: `flutter/material.dart`, `flutter/services.dart` (`Clipboard`), `dio`, `memora_api`, Design System Memora (`design_system/design_system.dart`), `ChamadaComRenovacao`, `SessaoPerdida`.
- **Backend**: `spring-boot-starter-webmvc`, `spring-boot-starter-security`, `spring-boot-starter-validation`, JDK `java.net.http.HttpClient` (`ADR 002`), Jackson 3 (`tools.jackson.databind.json.JsonMapper`).

**Storage**: N/A (Efêmero por design — nenhuma mensagem analisada é persistida em banco de dados ou disco local; o controle de taxa por conta `LimitadorAnaliseGolpe` opera em memória com `ConcurrentHashMap<UUID, Deque<Instant>>`).

**Testing**:
- **Flutter**: `flutter_test` (testes unitários de domínio/repositório/controlador, testes de widget, testes de acessibilidade WCAG e matriz 4×3×3, `profundidade_test.dart`, `texto_da_interface_test.dart`, `validar_tokens.py`).
- **Backend**: JUnit 5, Mockito, Spring `MockMvc`, `@WebMvcTest`, JDK `HttpServer` local para testes do cliente Gemini e `TextoDaInterfaceTest` (sem necessidade de Docker).

**Target Platform**: Android (aplicativo móvel Flutter) e servidor Linux/JVM (API REST Spring Boot).

**Project Type**: Mobile App + REST API (`app/` + `backend/`).

**Performance Goals**:
- Análise local offline (`AnalisadorLocalDeGolpes`): `< 15 ms` no aparelho.
- Pré-check determinístico no backend (`AnalisadorDeterministicoDeGolpes`): `< 10 ms`.
- Chamada Gemini com *timeout* configurável e fallback determinístico imediato em caso de erro ou lentidão do provedor externo.

**Constraints**:
- Zero literais visuais fora dos tokens (`validar_tokens.py`).
- Textos da interface e do backend restritos a `<= 2` frases curtas por bloco, zero emojis na UI, zero palavras proibidas (`memora-ux`).
- `TelaHub` mantida em 7 portas para cumprir `FR-017` (`hub_cabe_sem_rolar_test.dart` em `Size(360, 880)`).
- Profundidade máxima de navegação `<= 3` toques a partir da `TelaInicio` (`profundidade_test.dart`).

**Scale/Scope**: 1 nova feature Flutter (`app/lib/features/antigolpe/` com 7 arquivos de produção + `textos_antigolpe.dart` + 4 arquivos de teste) e 1 novo módulo backend (`br.fatec.memora.antigolpe` com 16 arquivos de produção + 7 arquivos de teste).

## Constitution Check

*GATE: Verificado antes da implementação e revalidado após os testes automatizados.*

| Princípio da Constituição (v1.1.0) | Status | Evidência na Implementação |
|---|---|---|
| **I. Segurança Acima de Tudo & Emenda 1** | APROVADO | Endpoint `POST /v1/golpes/analisar` protegido por JWT (`FiltroDeTokenDeAcesso`) e verificação de conta ativa; `LimitadorAnaliseGolpe` por conta (20/h, 60/dia); zero persistência ou log de `conteudo`; zero envio de PII da pessoa ao Gemini. |
| **II. Segurança Contra Engenharia Social** | APROVADO | Nenhum link colado ou retornado na análise é clicável; linguagem literal e direta em `TextosAntigolpe`; aviso explícito quando o resultado vem do modo local sem internet (`TextosAntigolpe.avisoOffline`). |
| **III. Acessibilidade como Requisito** | APROVADO | Contraste WCAG 2.2 AA via tokens `MemoraCores`; alvos `>= 48x48 dp`; risco comunicado por cor + ícone + selo + expressão da Memora; `Semantics(liveRegion: true)` no resultado; aprovado na matriz 4×3×3 (até 200%). |
| **IV. Especificação Antes de Código** | APROVADO | Especificação, Threat Model, contrato JSON e tarefas documentados em `specs/016-analise-golpes/{spec.md,plan.md,tasks.md}`. |
| **V. Arquitetura Limpa e Feature-First** | APROVADO | Separação estrita `domain/` (entidades, contrato de repositório, `AnalisadorLocalDeGolpes`), `data/` (`RepositorioAnaliseGolpeApi`, `RepositorioAnaliseGolpeSimulado`) e `presentation/` (`ControladorAnaliseGolpe`, `TelaAnaliseGolpe`), injetados via `Composicao.resolver()`. |
| **VI. A IA Nunca Age Sozinha** | APROVADO | A IA apenas classifica e explica; `AnalisadorDeterministicoDeGolpes` roda antes da IA e `SanitizadorRespostaAntigolpe` impõe piso monotônico `max(preCheck, ia)` e sanitização de texto. |
| **VII. Ensinar, Não Substituir** | APROVADO | Cada análise explica **quais sinais** chamaram atenção ("O que chamou atenção") e **como agir** com segurança ("O que fazer agora"), ensinando a pessoa a reconhecer padrões de golpe. |

## Project Structure

### Documentation (this feature)

```text
specs/016-analise-golpes/
├── spec.md              # Especificação da feature, histórias de usuário, requisitos e Threat Model
├── plan.md              # Plano técnico, arquitetura, contratos e Constitution Check
└── tasks.md             # Lista de tarefas ordenada por dependências com status de execução
```

### Source Code (repository root)

```text
backend/
├── src/main/java/br/fatec/memora/antigolpe/
│   ├── api/
│   │   ├── ControladorAnaliseGolpe.java
│   │   └── dto/
│   │       ├── AnalisarGolpeRequest.java
│   │       └── AnalisarGolpeResponse.java
│   ├── aplicacao/
│   │   ├── AnalisadorDeterministicoDeGolpes.java
│   │   ├── SanitizadorRespostaAntigolpe.java
│   │   └── ServicoAnaliseGolpe.java
│   ├── dominio/
│   │   ├── NivelRiscoGolpe.java
│   │   └── ResultadoAnaliseGolpe.java
│   ├── infra/
│   │   ├── ClienteAnaliseGolpe.java
│   │   ├── ClienteAnaliseGolpeGemini.java
│   │   ├── ClienteAnaliseGolpeSimulado.java
│   │   ├── CondicaoProvedorAntigolpe.java
│   │   ├── ConfiguracaoAnaliseGolpeIa.java
│   │   └── PersonaAntigolpe.java
│   └── seguranca/
│       ├── LimitadorAnaliseGolpe.java
│       └── LimiteAnaliseGolpeExcedido.java
└── src/test/java/br/fatec/memora/antigolpe/
    ├── api/
    │   ├── ControladorAntigolpeTest.java
    │   └── SegurancaAntigolpeWebMvcTest.java
    ├── aplicacao/
    │   ├── AnalisadorDeterministicoDeGolpesTest.java
    │   └── ServicoAnaliseGolpeTest.java
    ├── infra/
    │   ├── ClienteAnaliseGolpeGeminiTest.java
    │   └── ConfiguracaoAnaliseGolpeIaTest.java
    └── seguranca/
        └── LimitadorAnaliseGolpeTest.java

app/
├── lib/
│   ├── l10n/
│   │   └── textos_antigolpe.dart
│   ├── features/
│   │   ├── antigolpe/
│   │   │   ├── domain/
│   │   │   │   ├── entidades/analise_golpe.dart
│   │   │   │   ├── repositorios/repositorio_analise_golpe.dart
│   │   │   │   └── servicos/analisador_local_de_golpes.dart
│   │   │   ├── data/
│   │   │   │   └── repositorios/
│   │   │   │       ├── repositorio_analise_golpe_api.dart
│   │   │   │       └── repositorio_analise_golpe_simulado.dart
│   │   │   └── presentation/
│   │   │       ├── controladores/controlador_analise_golpe.dart
│   │   │       └── telas/tela_analise_golpe.dart
│   │   ├── inicio/presentation/tela_inicio.dart
│   │   ├── ajuda/presentation/tela_ajuda.dart
│   │   └── autenticacao/presentation/fluxo_autenticacao.dart
│   ├── services/ambiente/composicao.dart
│   └── main.dart
└── test/
    ├── features/
    │   ├── antigolpe/
    │   │   ├── analisador_local_de_golpes_test.dart
    │   │   ├── controlador_analise_golpe_test.dart
    │   │   ├── repositorio_analise_golpe_api_test.dart
    │   │   └── tela_analise_golpe_test.dart
    │   └── casca/profundidade_test.dart
    ├── design_system/texto_da_interface_test.dart
    └── services/ambiente_test.dart
```

**Structure Decision**: Arquitetura Mobile + API seguindo o padrão Feature-First Clean Architecture existente no repositório (`app/lib/features/antigolpe/{domain,data,presentation}` no Flutter e pacote vertical `br.fatec.memora.antigolpe.{dominio,aplicacao,api,infra,seguranca}` no Spring Boot). Para respeitar o portão `FR-017` (`hub_cabe_sem_rolar_test.dart` em `Size(360, 880)`), o Hub permanece com suas 7 portas e a `TelaAnaliseGolpe` é exposta diretamente na `TelaInicio` (atalho de 1 toque) e na `TelaAjuda` (porta "Verificar golpe").

## Contrato de Interface (`POST /v1/golpes/analisar`)

- **Autenticação**: `Authorization: Bearer <tokenDeAcesso>` (`FiltroDeTokenDeAcesso`).
- **Request (`application/json`)**:
  ```json
  {
    "conteudo": "string (@NotBlank, @Size(max = 2000))"
  }
  ```
- **Response `200 OK` (`application/json`)**:
  ```json
  {
    "risco": "BAIXO | MEDIO | ALTO",
    "titulo": "string (máx. 2 frases curtas, sem emojis, sem termos proibidos)",
    "explicacao": "string (máx. 2 frases curtas, linguagem comum)",
    "orientacoes": ["string", "..."],
    "sinaisDetectados": ["string", "..."],
    "analisadoPorIa": true
  }
  ```
- **Respostas de Erro**:
  - `400 Bad Request`: `conteudo` em branco ou acima de 2000 caracteres.
  - `401 Unauthorized`: token ausente, inválido ou conta não ativa (`CodigoDeErro.SESSAO_EXPIRADA`).
  - `429 Too Many Requests`: limite de análises por conta excedido (`CodigoDeErro.LIMITE_DE_CONVERSAS` + cabeçalho `Retry-After`).

## Complexity Tracking

Nenhuma violação à Constituição v1.1.0. Não foram adicionadas dependências externas novas nem tabelas de banco de dados.
