# Quickstart & Validation Guide: 006 — Polimento de Acessibilidade, Robustez de Conta e Rastreabilidade

**Feature**: [spec.md](spec.md) | **Data Model**: [data-model.md](data-model.md) | **Contracts**: [contracts/componentes-e-servicos.md](contracts/componentes-e-servicos.md)  
**Date**: 2026-11-13  

---

## Pré-requisitos

- **Flutter SDK**: 3.41+ / 3.47.x (com dependências instaladas via `flutter pub get` em `app/`).
- **Java / Maven**: JDK 21 + Docker ativo (para Testcontainers PostgreSQL nos testes de integração do `backend/`).
- **Python 3**: para os validadores estáticos de paleta e de tokens.

---

## Cenários de Verificação Determinística

### V1 — Segundo sinal visual de foco e toque em `BotaoBase` (`FR-001` a `FR-003`, `SC-001`)

Executar na pasta `app/`:

```powershell
flutter test test/design_system/
```

**Resultado esperado**:
- Todos os testes em `test/design_system/` passam, incluindo os novos casos que verificam que `BotaoPrimario`, `BotaoSecundario`, `BotaoTerciario` e `BotaoPerigo` usam `SuperficieTocavel`, desenham o anel externo `bordaSelecao` quando focados, aplicam `escalaPressionado` (e `cores.destaque` nos transparentes) quando pressionados, respeitam `disableAnimations` e mantêm a semântica do TalkBack.

---

### V2 — Janela de teste com dimensões reais em `cartao_de_porta_test.dart` (`FR-012`, `SC-004`)

Executar na pasta `app/`:

```powershell
flutter test test/design_system/cartao_de_porta_test.dart
```

**Resultado esperado**:
- 100% dos testes de `cartao_de_porta_test.dart` passam e a verificação de `MediaQuery.sizeOf(context)` dentro da árvore montada comprova altura e largura maiores que zero mesmo quando `escala` é `1.5` ou `2.0`.

---

### V3 — Expurgo de conta assistida abandonada após 24h (`T065b`, `FR-004` a `FR-007`, `SC-002`)

Executar na pasta `backend/`:

```powershell
.\mvnw.cmd test -Dtest=ModoAssistidoSemVinculoTest,ExpurgoDeContaPendenteTest
```

**Resultado esperado**:
- Conta criada em `modo_assistido=true` (`PENDENTE_VERIFICACAO`) há menos de 24h continua protegida pelo chamariz da `FR-010` se outra requisição tentar cadastrar o mesmo canal.
- Após avançar o relógio para mais de 24h sem confirmação do canal, um novo cadastro com o mesmo e-mail/telefone expurga a conta pendente antiga e cria a nova conta com sucesso (permitindo confirmar o canal e entrar).
- A rotina de limpeza periódica remove contas `PENDENTE_VERIFICACAO` com mais de 24h sem afetar contas `ATIVA` nem contas pendentes recentes.

---

### V4 — Envio SMTP em produção sem vazamento de código em log (`T065a` e `T068`, `FR-008` a `FR-011`, `SC-003`)

Executar na pasta `backend/`:

```powershell
.\mvnw.cmd test -Dtest=EnviadorDeCodigoPorEmailTest,NotificadorDeContaPorEmailTest
```

**Resultado esperado**:
- O adaptador de produção falha na subida (`@PostConstruct`) se o host SMTP ou remetente estiver em branco.
- Para canais `EMAIL`, envia a mensagem contendo o código (ou o aviso de senha alterada) sem nenhum link clicável e com o lembrete antigolpe.
- Em caso de falha do servidor SMTP ou canal `TELEFONE`, nenhum log nem exceção contém os 6 dígitos do código em claro.

---

### V5 — Portões da Constituição (Tokens, Contraste WCAG 2.2, `flutter analyze` e Suíte Completa)

Executar na raiz do repositório:

```powershell
python scripts/validar_paleta.py --autoteste
python scripts/validar_paleta.py
python scripts/validar_tokens.py --autoteste
python scripts/validar_tokens.py
```

E em `app/` e `backend/`:

```powershell
cd app; flutter analyze; flutter test
cd ../backend; .\mvnw.cmd test
```

**Resultado esperado**:
- Zero avisos no `flutter analyze`, validadores de paleta e de tokens aprovados e 100% dos testes do aplicativo e do backend verdes.
