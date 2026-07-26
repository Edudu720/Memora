# Fase 0 — Pesquisa: Autenticação Acessível

**Feature**: 001-autenticacao-acessivel
**Data**: 2026-07-24
**Objetivo**: resolver todas as incógnitas técnicas antes do desenho da solução.

---

## R1 — Hash de senha

**Decisão**: Argon2id via `Argon2PasswordEncoder` do Spring Security, com
**parâmetros explícitos**, nunca os padrões da biblioteca.

| Parâmetro | Valor adotado | Padrão do Spring | Mínimo OWASP |
|---|---|---|---|
| Memória | **19.456 KiB (19 MiB)** | 16.384 KiB (16 MiB) | 19.456 KiB |
| Iterações | **2** | 2 | 2 |
| Paralelismo | **1** | 1 | 1 |
| Salt | 16 bytes | 16 bytes | — |
| Hash | 32 bytes | 32 bytes | — |

**Rationale**: o construtor `defaultsForSpringSecurity_v5_8()` usa memória de
16 MiB, **abaixo do mínimo recomendado pela OWASP (19 MiB)**. Aceitar o padrão
seria uma escolha silenciosamente mais fraca. Como o Princípio I proíbe trocar
segurança por conveniência, os parâmetros são declarados explicitamente e
versionados.

**Dependência**: `Argon2PasswordEncoder` exige **BouncyCastle** no classpath.

**Alternativas consideradas**:
- *bcrypt* — aceito pela Constituição, mas sem resistência a ataque por GPU
  comparável. Descartado por existir opção melhor sem custo relevante.
- *Configuração "recomendada" da OWASP (46 MiB, t=1)* — segurança equivalente com
  mais memória por requisição. Descartada porque a instância de estudo do TCC pode
  ter memória limitada; 19 MiB é o piso seguro.

**Verificação executada em 2026-07-26 (T017)** — e ela mudou a decisão:

| Parâmetros | Tempo medido |
|---|---|
| 19.456 KiB, t=2 (mínimo OWASP) | **42 ms** |
| 32.768 KiB, t=3 | 84 ms |
| 47.104 KiB, t=3 | 121 ms |
| 65.536 KiB, t=3 | 172 ms |
| **65.536 KiB, t=4** | **249 ms** ✅ |
| 98.304 KiB, t=3 | 298 ms |

O mínimo da OWASP produz hash de 42 ms neste hardware — muito abaixo do alvo de
250 a 500 ms. **Hash barato para nós é hash barato para o atacante.**

**Parâmetros finais: 65.536 KiB (64 MiB), t=4, p=1.** Preferido a 98.304 KiB com
t=3, que também atingia o alvo, porque cada hash concorrente consome a memória
inteira — 96 MiB por login simultâneo inviabiliza um servidor modesto.

Esta é a razão de a tarefa T017 existir: parâmetro que parece forte no papel pode
estar fraco na máquina onde roda.

---

## R2 — Sessão: token de acesso e refresh rotativo

**Decisão**: token de acesso curto (**15 minutos**) + refresh token opaco,
rotativo, com **detecção de reuso**.

**Como funciona**:
1. O refresh token é um valor aleatório opaco, armazenado **hasheado** no banco.
2. A cada uso, o token antigo é invalidado e um novo é emitido (rotação).
3. Se um token **já usado** for apresentado de novo, isso indica roubo: toda a
   família de tokens daquela sessão é revogada e o usuário é avisado.

**Rationale**: rotação com detecção de reuso é o que transforma o roubo de token de
"acesso permanente e silencioso" em "sessão derrubada e usuário notificado".
Atende FR-021 (encerrar sessões após troca de senha) e FR-017 (expiração).

**Tensão com acessibilidade, e como foi resolvida**: 15 minutos de token de acesso
NÃO significa pedir senha a cada 15 minutos. O refresh é longo (**60 dias**) e
renovado a cada uso — a pessoa idosa permanece conectada indefinidamente enquanto
usar o app, satisfazendo FR-016. A expiração de FR-017 conta **inatividade**, não
tempo absoluto.

**Alternativa considerada**: JWT auto-contido como refresh. Descartado — não é
revogável sem lista de bloqueio, o que anula o benefício.

---

## R3 — Proteção contra enumeração de contas

**Decisão**: resposta uniforme em conteúdo **e em tempo**.

- Mensagem idêntica para identificador inexistente e senha errada (FR-013).
- Mesma resposta no cadastro para identificador já existente (FR-010).
- Mesma resposta na recuperação, exista a conta ou não (FR-019).
- **Executar o hash mesmo quando a conta não existe**, comparando contra um hash
  fictício, para que o tempo de resposta não denuncie a existência da conta.

**Rationale**: mensagens genéricas sozinhas não bastam. Sem o hash fictício, a
resposta para conta inexistente volta muito mais rápido e a diferença é medível —
é o *timing attack* citado na Constituição.

**Custo aceito**: gasta CPU em tentativas inválidas. Mitigado pelo rate limiting (R4).

---

## R4 — Rate limiting e proteção contra força bruta

**Decisão**: duas camadas independentes.

| Camada | Alvo | Limite | Ação |
|---|---|---|---|
| Por identificador | Conta específica | 5 falhas consecutivas | Bloqueio progressivo: 1, 5, 15, 60 min |
| Por origem | Endereço de rede | Janela deslizante | Recusa temporária |

**Biblioteca**: Bucket4j (algoritmo *token bucket*), com estado compartilhado no
banco ou em cache — nunca em memória local, sob risco de o limite sumir a cada
reinício.

**Requisito de UX que não pode ser esquecido**: a FR-015 exige que a mensagem de
bloqueio seja **acolhedora**, explique o motivo, diga quando será possível tentar
de novo e ofereça a recuperação. Um bloqueio tecnicamente correto com texto
punitivo reprova na revisão de UX.

---

## R5 — Verificação de posse do canal (e-mail e telefone)

**Decisão**: código numérico de **6 dígitos**, validade de **10 minutos**, uso único,
com limite de tentativas.

**Rationale**: código curto é preferível a link clicável para este público —
a FR-046 desaconselha links de autenticação em canais imitáveis, e clicar em links
recebidos por mensagem é exatamente o comportamento que os golpistas exploram.
Digitar um número em uma tela que a pessoa **já abriu** é mais seguro e mais fácil
de ensinar: *"nunca clique, sempre digite"*.

**Armazenamento**: o código é guardado **hasheado**, com a mesma lógica de segredo.

**Onde isso é crítico**: FR-062 — no cadastro assistido, o canal precisa ter posse
confirmada antes de o cadastro terminar. Sem isso, o acompanhante pode cadastrar o
próprio contato e manter controle da conta.

---

## R6 — Login social (Google e Facebook)

**Decisão**: fluxo *Authorization Code* com **PKCE**, executado pelo aplicativo, e
**validação do token no backend**.

**Fluxo**:
1. O app abre o provedor em aba segura do sistema (*Custom Tabs*), nunca em WebView.
2. O provedor devolve um código; o app troca por um token de identidade.
3. O app envia esse token ao backend, que **valida assinatura, emissor, audiência e
   expiração** antes de aceitar.
4. O backend emite as próprias credenciais de sessão (R2).

**Por que WebView está proibido**: em WebView o aplicativo consegue ler o que a
pessoa digita na tela do provedor. Além de violar FR-055, remove a barra de
endereço — justamente o único sinal que permitiria identificar uma tela falsa.
Para um público que não sabe validar uma tela de login, isso é decisivo.

**Vinculação de contas (FR-057)**: se o identificador devolvido pelo provedor já
existir como conta com senha, os acessos são vinculados à mesma pessoa. A resposta
não pode revelar que a conta já existia.

**Escopos solicitados** (FR-056 — mínimo necessário): identificador da conta,
e-mail e nome. Nada além.

**Ressalva registrada (D2)**: o Facebook agrega pouco alcance em Android e é vetor
recorrente de golpe com pessoas idosas. Decisão de produto tomada com a ressalva
conhecida.

---

## R7 — Armazenamento de credenciais no aplicativo

**Decisão**: `flutter_secure_storage`, apoiado no Android Keystore.

- Tokens **nunca** em `SharedPreferences` (regra explícita da Constituição).
- Nenhuma credencial em log, cache ou cópia de tela.
- Ao sair da conta (FR-026), limpeza completa do armazenamento seguro.

**Ponto de atenção**: o `flutter_secure_storage` no Android usa
`EncryptedSharedPreferences` por baixo. É necessário confirmar em build de release
com ofuscação ativa, pois é onde esse tipo de integração costuma quebrar sem aviso.

---

## R8 — Contrato entre aplicativo e API

**Decisão**: **OpenAPI como fonte da verdade**, com o cliente Dart **gerado** a
partir da especificação.

**Rationale**: este foi o ponto fraco registrado no [ADR 001](../../docs/architecture/adr-001-linguagem-do-backend.md).
Com duas linguagens, os DTOs do Flutter divergem da API com o tempo. Gerar o cliente
elimina a divergência por construção e sustenta a FR-038 — a interface não consegue
inventar um campo que o servidor não conhece.

**Ferramenta**: OpenAPI Generator, gerador `dart-dio`.

**Regra de processo**: o cliente gerado **não é editado à mão** e é versionado. Se o
contrato mudar, regenera-se.

---

## R9 — Acessibilidade no Flutter

**Decisão**: acessibilidade verificada por **teste automatizado**, não por inspeção
visual.

| Requisito | Como implementar | Como verificar |
|---|---|---|
| Toque de 48 dp (FR-027) | Tamanho mínimo nos componentes do Design System | `meetsGuideline(androidTapTargetGuideline)` |
| Contraste (FR-028) | Tokens validados na origem | `meetsGuideline(textContrastGuideline)` |
| Texto a 200% (FR-029) | Layouts sem altura fixa; `MediaQuery.textScalerOf` | Teste de widget com escala forçada |
| Leitor de tela (FR-031) | `Semantics` com rótulo e estado | `SemanticsTester` |
| Erro não só por cor (FR-032) | Ícone + texto sempre juntos | Revisão de componente |

**Rationale**: os critérios SC-005 a SC-007 exigem 100% de conformidade. Verificação
manual não escala e não sobrevive a refatoração. O Flutter oferece os *matchers*
prontos — usá-los transforma acessibilidade em teste que quebra o build.

---

## R10 — Design System: origem dos tokens

**Situação**: o Figma não está acessível. As 38 telas do protótipo estão em
`docs/design/prototipo/`, mas as cores foram **amostradas de imagem**, não extraídas
do arquivo original.

**Decisão**: construir os tokens a partir da intenção visual do protótipo,
**validando contraste na origem** e corrigindo o que reprovar.

**Problemas do protótipo que os tokens precisam corrigir** (já levantados na
análise inicial):

1. Duas linguagens visuais distintas — onboarding em azul com cards brancos,
   contra Hub e Chatbot em cinza com fonte serifada. Precisa convergir para uma.
2. Fonte serifada no título do Chatbot — pior legibilidade em baixa visão. Trocar
   por sem serifa.
3. Campos de dado no Perfil com aparência idêntica a botões — falha grave de
   affordance. Resolver com estilos distintos para informação e ação.
4. Botões SIM/NÃO pequenos, pastel, lado a lado — reprovam em contraste, em área de
   toque e em confirmação acidental.

**Consequência**: o Design System **não é entregável desta feature**, mas é
dependência bloqueante da implementação. Deve ser tratado como feature própria
(002) ou como primeira tarefa do `/speckit-tasks`.

---

## Incógnitas resolvidas

| Incógnita | Resolvida em |
|---|---|
| Algoritmo e parâmetros de hash | R1 |
| Estratégia de sessão e revogação | R2 |
| Proteção contra enumeração | R3 |
| Rate limiting | R4 |
| Verificação de posse de canal | R5 |
| Integração com provedores externos | R6 |
| Armazenamento seguro no aplicativo | R7 |
| Contrato app↔API | R8 |
| Verificação de acessibilidade | R9 |
| Origem dos tokens visuais | R10 |

**Nenhuma incógnita permanece aberta.** Liberado para a Fase 1.

---

## Fontes

- [OWASP Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)
- [Spring Security — Argon2PasswordEncoder](https://docs.spring.io/spring-security/reference/api/java/org/springframework/security/crypto/argon2/Argon2PasswordEncoder.html)
- [Spring Security — Password Storage](https://docs.spring.io/spring-security/reference/features/authentication/password-storage.html)
