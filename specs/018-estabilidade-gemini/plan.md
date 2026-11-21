# Implementation Plan: Estabilidade da API do Gemini (Item 12)

**Branch**: `feature/018-estabilidade-gemini` | **Date**: 2026-11-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/018-estabilidade-gemini/spec.md`

## Summary

Alinhar o modelo padrão do adaptador Gemini para `gemini-3.6-flash` (em `ConfiguracaoDoProvedorDeIa`, `application.properties` e `render.yaml`) e adicionar resiliência controlada antes do primeiro trecho de resposta em `ClienteDaAssistenteGemini`: retentativa curta no principal (`tentativas-primario=2`, `espera-retentativa-ms=500`) para `5xx`/`REDE`/`PRAZO`, mais acionamento imediato de modelo reserva configurável (`modelo-reserva=gemini-3.5-flash-lite`) em `429` ou após esgotar as tentativas do principal — sem nunca retentar após o 1º trecho nem vazar segredos/erros externos.

## Technical Context

**Language/Version**: Java 21, Spring Boot 4.1.0 (`spring-boot-starter-webmvc`, `java.net.http.HttpClient`, Jackson 3 `tools.jackson.*`)
**Primary Dependencies**: JDK `HttpClient`, JUnit 5, AssertJ, `com.sun.net.httpserver.HttpServer` (testes sem rede)
**Storage**: N/A (configuração por variáveis de ambiente / `application.properties`)
**Testing**: `./mvnw.cmd test` (testes unitários de infra + contexto Spring via `ApplicationContextRunner`)
**Target Platform**: Linux container no Render (0,1 CPU / 512 MB RAM) e desenvolvimento local
**Project Type**: Backend REST/SSE Java (`backend/`) + Blueprint (`render.yaml`) + documentação (`docs/`)
**Performance Goals**: Manter latência abaixo do timeout de `30 s` do app (`esperaMaxima`); backoff padrão curto (`500 ms`) e `gemini-3.5-flash-lite` com menor latência no fallback
**Constraints**: Nunca expor `GEMINI_API_KEY` ou corpo de erro do Google; compatibilidade com construtor de 5 argumentos; nunca duplicar trechos após iniciar streaming
**Scale/Scope**: 3 arquivos de produção (`ClienteDaAssistenteGemini.java`, `ConfiguracaoDoProvedorDeIa.java`, `application.properties`), `render.yaml`, 2 suítes de teste e 3 arquivos de documentação (`adr-002`, `render.md`, `CHANGELOG.md`)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Princípio I (Segurança Acima de Tudo)**: PASS — `modelo-reserva` validado com regex `[A-Za-z0-9._-]+`; `x-goog-api-key` continua só no cabeçalho; corpo externo descartado; `tentativas-primario >= 1` e `espera >= 0` evitam loop infinito / amplificação de cota.
- **Princípio II (Engenharia Social)**: PASS — Falha final continua traduzida para frase acolhedora da Memora em `ControladorConversa`.
- **Princípio IV (Spec Antes de Código)**: PASS — Ciclo SpecKit completo.
- **Princípio VI (IA nunca age sozinha)**: PASS — Chamada ao modelo reserva usa exatamente o mesmo `Pedido` (`systemInstruction`, `tools`) e continua passando pelo `AutorizadorDeAcao`.
- **Documentação Viva**: PASS — `adr-002-provedor-de-ia.md`, `render.md` e `CHANGELOG.md` atualizados juntos.

## Project Structure

### Documentation (this feature)

```text
specs/018-estabilidade-gemini/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/
│   └── requirements.md
├── contracts/
│   └── configuracao-gemini.md
└── tasks.md
```

### Source Code (repository root)

```text
backend/src/main/java/br/fatec/memora/assistente/infra/
├── ClienteDaAssistenteGemini.java       # Retry antes do 1º trecho + fallback configurável
└── ConfiguracaoDoProvedorDeIa.java      # Defaults alinhados (3.6-flash / 3.5-flash-lite) e injeção
backend/src/main/resources/
└── application.properties               # Novas propriedades configuráveis por env
backend/src/test/java/br/fatec/memora/assistente/infra/
├── ClienteDaAssistenteGeminiTest.java   # Cenários de retry, fallback 429/503, 400 e pós-1º-trecho
└── ConfiguracaoDoProvedorDeIaTest.java  # Subida com modelo-reserva e validações de boot
render.yaml                              # MEMORA_ASSISTENTE_GEMINI_MODELO_RESERVA=gemini-3.5-flash-lite
docs/architecture/adr-002-provedor-de-ia.md
docs/deploy/render.md
CHANGELOG.md
```

**Structure Decision**: Toda a lógica de provedor continua encapsulada em `ClienteDaAssistenteGemini` e `ConfiguracaoDoProvedorDeIa`, preservando o isolamento arquitetural da ADR-002.

## Complexity Tracking

Nenhuma violação da constituição ou abstração especulativa adicionada.
