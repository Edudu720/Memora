# Research: 006 — Polimento de Acessibilidade, Robustez de Conta e Rastreabilidade

**Feature**: [spec.md](spec.md)  
**Date**: 2026-11-13  

---

## R1 — Unificação de `BotaoBase` com `SuperficieTocavel` (FR-001 a FR-003)

- **Decision**: Refatorar `BotaoBase` (`app/lib/design_system/componentes/botoes/botao_base.dart`) para delegar sua superfície interativa, semântica (`Semantics` / `ExcludeSemantics`), animação de foco/pressão e `InkWell` diretamente ao componente interno `SuperficieTocavel` (`app/lib/design_system/componentes/toque/superficie_tocavel.dart`), preservando o `ConstrainedBox` (`minHeight: alturaMinima`, `minWidth: MemoraDimensoes.alvoMinimo`), a largura (`larguraTotal ? double.infinity : null`) e o preenchimento interno (`MemoraEspacamento.xl` horizontal, `MemoraEspacamento.md` vertical) em torno do conteúdo.
- **Rationale**:
  1. `SuperficieTocavel` já foi criada na Feature 004 exatamente para suprir o segundo sinal visual exigido pelo Princípio III (`FR-043` da 004): desenha o anel externo de foco (`MemoraDimensoes.bordaSelecao` com `BorderSide.strokeAlignOutside` em `cores.primaria`) em `foregroundDecoration` e reduz a escala para `MemoraMovimento.escalaPressionado` (`0.97`) enquanto pressionada, aplicando `cores.destaque` quando o fundo em repouso é transparente (`Colors.transparent`, caso de `EstiloBotao.secundario` e `EstiloBotao.terciario`).
  2. Mantém compatibilidade integral com `semantica_test.dart` (que inspeciona `Semantics` com `label`, `isButton`, `isEnabled`, `hasTapAction`), `reducao_de_movimento_test.dart` (que inspeciona `AnimatedContainer` com `MemoraMovimento.efetiva` e ` portão de código-fonte`) e `decisao_e_entrada_test.dart` / `area_toque_test.dart` (que validam `alturaMinima`).
  3. Elimina duplicação de `Semantics` + `ExcludeSemantics` + `AnimatedContainer` + `Material` + `InkWell` em `BotaoBase`.
- **Alternatives considered**:
  - *Implementar controle de estado `_focada`/`_pressionada` separado dentro de `BotaoBase`*: rejeitado porque duplicaria `SuperficieTocavel` e violaria o Princípio V (componente reutilizável como regra).

---

## R2 — Expurgo de Contas Assistidas Abandonadas em `PENDENTE_VERIFICACAO` (`T065b`, FR-004 a FR-007)

- **Decision**:
  1. Definir o prazo de expiração de contas `PENDENTE_VERIFICACAO` em **24 horas** (`Duration.ofHours(24)`), centralizado em um serviço de aplicação dedicado (`ServicoDeExpurgoDeContaPendente`) e/ou método de domínio em `PessoaUsuaria` (`estaPendenteExpirada(Instant agora, Duration prazo)`).
  2. **Expurgo sob demanda no cadastro (`ServicoDeCadastro.cadastrar`)**: após executar o hash Argon2id da senha e o hash do canal (mantendo o custo constante antes da decisão), quando `canais.findByValorHash(valorHash)` encontrar um canal existente:
     - Buscar a `PessoaUsuaria` dona daquele canal.
     - Se a conta estiver em `EstadoDaConta.PENDENTE_VERIFICACAO` e `criadaEm.plus(PRAZO_EXPIRACAO).isBefore(agora)` (ou `!criadaEm.plus(PRAZO_EXPIRACAO).isAfter(agora)`): expurgar atomicamente a conta pendente expirada na mesma transação (`DELETE` em `evento_autenticacao` daquela `pessoaId` + `DELETE` em `pessoa_usuaria` com `flush`, o que remove em cascata `canal_contato`, `codigo_verificacao` e `sessao`) e prosseguir com `criar(...)` normalmente.
     - Caso contrário (conta `ATIVA`, `BLOQUEADA_TEMPORARIAMENTE`, `DESATIVADA` ou `PENDENTE_VERIFICACAO` criada há menos de 24 horas): manter o retorno `chamariz(...)` indistinguível (`FR-010`).
  3. **Expurgo periódico agendado**: expor em `ServicoDeExpurgoDeContaPendente` uma rotina `@Scheduled` (ex.: a cada hora, configurável) e invocável diretamente nos testes de integração que localiza todas as contas em `PENDENTE_VERIFICACAO` com `criadaEm <= agora - 24h`, remove seus registros em `evento_autenticacao` e apaga as contas em `pessoa_usuaria`, registrando em log apenas a contagem expurgada.
- **Rationale**:
  - Na migration `V1__esquema_inicial.sql`, `canal_contato`, `sessao` e `codigo_verificacao` possuem `ON DELETE CASCADE` para `pessoa_usuaria`, mas `evento_autenticacao` possui `CONSTRAINT fk_evento_pessoa FOREIGN KEY (pessoa_id) REFERENCES pessoa_usuaria (id)` **sem** `ON DELETE CASCADE` (e um gatilho `tg_evento_somente_insercao` que bloqueia `BEFORE UPDATE`, mas permite explicitamente `DELETE`). Portanto, apagar primeiro os eventos de `evento_autenticacao` da conta pendente expirada e em seguida a `pessoa_usuaria` funciona sem necessidade de nova migration Flyway e sem violar integridade referencial.
  - Uma conta em `PENDENTE_VERIFICACAO` é barrada em todos os endpoints da assistente (`PessoaAutenticada.estaPendenteDeVerificacao()`), portanto nunca possui registros em `evento_da_assistente` nem `uso_da_assistente`.
- **Alternatives considered**:
  - *Substituir imediatamente qualquer conta `PENDENTE_VERIFICACAO` sem aguardar 24h*: rejeitado na clarificação (Q2) pois permitiria interromper um cadastro assistido legítimo que está acontecendo naquele exato momento.
  - *Criar migration Flyway V12 alterando `fk_evento_pessoa`*: desnecessário, pois `DELETE FROM evento_autenticacao WHERE pessoa_id = ...` já é permitido pelo esquema V1 (documentado na linha 227 de `V1__esquema_inicial.sql`).

---

## R3 — Adaptador SMTP de Produção para `EnviadorDeCodigo` e `NotificadorDeConta` (`T065a` e `T068`, FR-008 a FR-011)

- **Decision**:
  1. Adicionar `spring-boot-starter-mail` ao `backend/pom.xml`.
  2. Criar propriedades tipadas/configuração de envio (`ConfiguracaoDeEnvioPorEmail` / `memora.envio.email.*` mapeadas para `MEMORA_EMAIL_REMETENTE` e variáveis padrão `SPRING_MAIL_HOST`, `SPRING_MAIL_PORT`, `SPRING_MAIL_USERNAME`, `SPRING_MAIL_PASSWORD`).
  3. Implementar `EnviadorDeCodigoPorEmail` e `NotificadorDeContaPorEmail` anotados com `@Component` e `@Profile("producao")`:
     - Na subida (`@PostConstruct`), validar que o host SMTP e o remetente estão configurados e não estão em branco; se ausentes, lançar `IllegalStateException` com mensagem clara explicando quais variáveis faltam (cumprindo `FR-011`).
     - Em `enviar(CanalContato canal, String codigoEmClaro)`:
       - Se `canal.getTipo() != TipoDeCanal.EMAIL`, recusar com `FalhaDoMemora` (`CodigoDeErro.SERVICO_INDISPONIVEL` ou equivalente de domínio) e registrar aviso técnico com `canal.getId()` e `canal.getTipo()`, **sem tocar em `codigoEmClaro`**.
       - Para `EMAIL`, enviar `SimpleMailMessage` (ou `MimeMessage` texto puro UTF-8) com assunto claro (`"Seu código de verificação do Memora"`), corpo acolhedor na voz da Memora contendo os 6 dígitos, prazo de 10 minutos e aviso antigolpe explícito (*"O Memora nunca pede sua senha por mensagem nem envia links para clicar"*), sem nenhum link (`http://` ou `https://`).
       - Capturar `MailException` registrando apenas `canal.getId()` e a classe do erro, nunca a mensagem bruta se houver risco ou o código em claro, e traduzir para falha controlada.
     - Em `avisarSenhaAlterada(CanalContato canal, String nomeTratamento)`:
       - Para `EMAIL`, enviar mensagem informando a `nomeTratamento` que a senha da conta no Memora foi alterada, sem links e com o lembrete antigolpe.
- **Rationale**:
  - Cumpre `T065a` e `T068` usando o padrão oficial do ecossistema Spring Boot (`JavaMailSender`), permitindo testar com mock/captura de `JavaMailSender` em testes automatizados e permitindo que o perfil `producao` suba quando configurado com qualquer servidor SMTP padrão.
- **Alternatives considered**:
  - *Provedor HTTP proprietário (Resend/SendGrid)*: rejeitado na clarificação (Q3) para não amarrar o backend a um fornecedor específico.

---

## R4 — Preservação das Dimensões da Janela em `cartao_de_porta_test.dart` (FR-012) e Atualização de `o-que-falta.md` (FR-013)

- **Decision**:
  1. Em `app/test/design_system/cartao_de_porta_test.dart` (linhas 28–34), substituir:
     ```dart
     home: MediaQuery(
       data: MediaQueryData(textScaler: TextScaler.linear(escala)),
       child: Scaffold(body: Center(child: filho)),
     ),
     ```
     por um `Builder` que copia o `MediaQueryData` existente da janela de teste:
     ```dart
     home: Builder(
       builder: (BuildContext context) => MediaQuery(
         data: MediaQuery.of(context).copyWith(
           textScaler: TextScaler.linear(escala),
         ),
         child: Scaffold(body: Center(child: filho)),
       ),
     ),
     ```
  2. Atualizar `docs/relatorios/o-que-falta.md` e `specs/001-autenticacao-acessivel/tasks.md` (`T065a` e `T065b`) refletindo o fechamento dessas dívidas e os números reais verificados de testes do aplicativo e do backend.
- **Rationale**:
  - `MediaQueryData(...)` construído do zero tem `size: Size.zero` (`0.0 × 0.0`), como apontado em `docs/relatorios/o-que-falta.md` (linha 180). Usar `MediaQuery.of(context).copyWith(...)` preserva o `size` real da view de teste (`800×600` padrão do `WidgetTester` ou o tamanho configurado no teste) e altera apenas o `textScaler`.
