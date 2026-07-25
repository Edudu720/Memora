# Fase 1 — Guia de Validação: Autenticação Acessível

**Feature**: 001-autenticacao-acessivel

> Este documento descreve **como provar que a feature funciona**. Não contém código
> de implementação — isso pertence a `tasks.md` e à fase de implementação.

---

## Pré-requisitos

| Item | Versão | Verificar |
|---|---|---|
| JDK | 21 (LTS) | `java -version` |
| PostgreSQL | 16+ | via Docker |
| Flutter SDK | 3.x estável | `flutter --version` |
| Docker | atual | `docker --version` |

---

## Subir o ambiente

```bash
docker compose up -d
```

```powershell
cd backend; .\mvnw spring-boot:run
```

```powershell
cd app; flutter run
```

---

## Cenários de validação

Cada cenário mapeia direto para um critério de aceite da [spec](spec.md).

### V1 — Cadastro conclui já autenticado

**Cobre**: US1 cenário 3 · FR-009

1. Criar conta com nome, um canal e senha.
2. **Esperado**: resposta `201` já contendo `token_acesso` e `refresh_token`.
3. **Esperado**: o aplicativo vai direto para a tela inicial, sem passar pelo login.

**Falha se**: o app pedir login logo após o cadastro.

---

### V2 — Nenhuma resposta revela se a conta existe

**Cobre**: FR-010, FR-013, FR-019 · SC-008

| Ação | Resposta esperada |
|---|---|
| Cadastrar com canal já existente | `201`, idêntica ao cadastro novo |
| Entrar com identificador inexistente | `401 CREDENCIAIS_INVALIDAS` |
| Entrar com identificador válido e senha errada | `401 CREDENCIAIS_INVALIDAS`, **byte a byte igual** |
| Recuperar acesso de conta inexistente | `202`, texto idêntico |

**Também medir o tempo**: a diferença de latência entre "conta existe" e "conta não
existe" deve ficar dentro do ruído. Se a resposta para conta inexistente voltar
sistematicamente mais rápido, o hash fictício (R3) não está sendo executado.

**Falha se**: qualquer diferença observável em corpo, código de status ou tempo.

---

### V3 — Detecção de reuso de refresh token

**Cobre**: R2 · FR-021

1. Autenticar e guardar `refresh_token` **A**.
2. Renovar com **A** → recebe **B**. Sucesso esperado.
3. Renovar novamente com **A** (simulando token roubado).
4. **Esperado**: `401`, **toda a família revogada**, e **B** também deixa de valer.
5. **Esperado**: evento `reuso_token_detectado` registrado e pessoa notificada.

**Falha se**: **B** continuar funcionando após o reuso de **A**.

---

### V4 — Canal não verificado não recupera acesso

**Cobre**: FR-052, FR-062 — *a defesa contra o acompanhante que retém controle*

1. Criar conta em modo assistido informando um canal.
2. **Não** confirmar a posse.
3. Solicitar recuperação de acesso.
4. **Esperado**: nenhum código é enviado para canal não verificado.
5. **Esperado**: o cadastro assistido **não conclui** sem posse confirmada.

**Falha se**: um canal não verificado receber código de recuperação. Este é o
cenário em que o familiar controla a conta permanentemente.

---

### V5 — Troca de senha derruba todas as sessões

**Cobre**: FR-021

1. Autenticar em dois aparelhos distintos.
2. Trocar a senha pelo fluxo de recuperação.
3. **Esperado**: ambas as sessões anteriores param de funcionar.
4. **Esperado**: notificação enviada (FR-022).

---

### V6 — Bloqueio progressivo com texto acolhedor

**Cobre**: FR-014, FR-015

1. Errar a senha 5 vezes seguidas.
2. **Esperado**: `429` com `tentar_novamente_em_segundos`.
3. **Esperado**: bloqueio cresce — 1, 5, 15, 60 minutos.

**Revisão de UX obrigatória**: a mensagem precisa explicar o motivo, dizer quando
será possível tentar de novo e oferecer a recuperação — **sem tom de punição**.
Bloqueio tecnicamente correto com texto ríspido **reprova** neste cenário.

---

### V7 — Acessibilidade automatizada

**Cobre**: FR-027 a FR-034 · SC-005, SC-006, SC-007

```powershell
cd app; flutter test test/acessibilidade/
```

Cada tela desta feature é verificada contra:

| Verificação | Matcher |
|---|---|
| Área de toque mínima | `androidTapTargetGuideline` |
| Contraste de texto | `textContrastGuideline` |
| Rótulos para leitor de tela | `SemanticsTester` |
| Texto a 200% sem quebra | Teste de widget com escala forçada |

**Falha se**: qualquer tela reprovar. Os critérios SC-005 a SC-007 exigem **100%**.

---

### V8 — Nenhuma credencial no aparelho

**Cobre**: FR-036 · SC-009

1. Autenticar no aplicativo.
2. Inspecionar `shared_prefs`, bancos locais e arquivos de log do app.
3. **Esperado**: nenhum token, senha ou código localizável.
4. Sair da conta e repetir a inspeção — nada deve restar (FR-026).

**Executar em build de release com ofuscação.** É onde o armazenamento seguro
costuma quebrar sem aviso (R7).

---

### V9 — Login social não expõe senha de terceiro

**Cobre**: FR-054, FR-055 · R6

1. Iniciar entrada com Google.
2. **Esperado**: aviso explícito de saída do Memora **antes** do redirecionamento.
3. **Esperado**: abre em aba segura do sistema, **nunca** em WebView.
4. **Esperado**: nenhum campo de senha do provedor dentro do Memora.
5. Repetir com Facebook.

**Falha se**: aparecer WebView. Ela remove a barra de endereço — o único sinal que
permitiria a pessoa identificar uma tela falsa.

---

### V10 — Teste com pessoas reais

**Cobre**: SC-001, SC-002, SC-003, SC-004, SC-011, SC-012

Nenhum teste automatizado substitui este.

**Protocolo**: 5 pessoas com 65+ anos, sem instrução prévia, sem ajuda durante a
tarefa. Observar em silêncio e cronometrar.

| Métrica | Meta |
|---|---|
| Conclui o cadastro sozinha | 90%, em até 4 min |
| Volta ao app | 95%, em até 15 s |
| Pergunta o significado de algum campo | **Zero** |
| Recupera a senha sozinha na 1ª tentativa | 85% |
| No modo assistido, o acompanhante **não** vê a senha | 100% |
| Após cadastro assistido, entra sozinha na 1ª tentativa | 80% |

**Registrar toda pergunta feita em voz alta.** Cada uma é um defeito de clareza,
mesmo que a tarefa tenha sido concluída.

---

## Portão de saída

A feature só é considerada pronta quando:

- [ ] V1 a V9 passam de forma automatizada
- [ ] V10 executado com no mínimo 5 pessoas do público-alvo
- [ ] Revisões de código, UX, acessibilidade, performance, segurança e arquitetura
      concluídas, conforme a Constituição
- [ ] Nenhum item do checklist da Pull Request em aberto
