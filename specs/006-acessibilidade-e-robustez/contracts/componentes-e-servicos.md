# Contracts: Componentes Visuais e Serviços de Autenticação (006)

**Feature**: [spec.md](../spec.md) | **Data Model**: [data-model.md](../data-model.md)  
**Date**: 2026-11-13  

---

## 1. Contrato de Interface Pública Rest (Inalterado na Superfície, Reforçado no Comportamento)

O contrato OpenAPI (`specs/001-autenticacao-acessivel/contracts/openapi.yaml`) **não sofre quebra nem mudança de schema JSON**, pois a proteção contra enumeração (`FR-010`) exige que `POST /v1/autenticacao/cadastro` continue devolvendo `201 Created` com `SessaoDeCadastro` idêntica em todos os cenários:

| Cenário em `POST /v1/autenticacao/cadastro` | Estado anterior do canal no banco | Comportamento após a Feature 006 | Resposta HTTP |
|---|---|---|---|
| Canal inédito | Não existe | Cria `PessoaUsuaria` (`ATIVA` ou `PENDENTE_VERIFICACAO`) e `CanalContato` | `201 Created` (sessão real) |
| Canal pertence a conta `ATIVA`, `BLOQUEADA_TEMPORARIAMENTE` ou `DESATIVADA` | Existe | Não altera a conta existente; devolve sessão chamariz | `201 Created` (sessão chamariz) |
| Canal pertence a conta `PENDENTE_VERIFICACAO` recente (`<= 24h`) | Existe (`criadaEm > agora - 24h`) | Não altera a conta em andamento; devolve sessão chamariz | `201 Created` (sessão chamariz) |
| Canal pertence a conta `PENDENTE_VERIFICACAO` abandonada (`> 24h`) | Existe (`criadaEm <= agora - 24h`) | Expurga atomicamente a conta pendente expirada e cria a nova conta solicitada | `201 Created` (sessão real da nova conta) |

---

## 2. Contrato das Portas de Envio Transacional (`EnviadorDeCodigo` e `NotificadorDeConta`)

### 2.1 `EnviadorDeCodigoPorEmail` (`@Profile("producao")`)

- **Entrada**: `CanalContato canal`, `String codigoEmClaro` (6 dígitos numéricos).
- **Pré-condições na subida (`@PostConstruct`)**:
  - `spring.mail.host` e `memora.envio.email.remetente` devem estar preenchidos. Caso contrário, lança `IllegalStateException` impedindo a subida do perfil `producao`.
- **Regras de execução**:
  1. Se `canal.getTipo() == TipoDeCanal.EMAIL`:
     - Envia e-mail em texto puro para `canal.getValor()` com remetente `memora.envio.email.remetente`.
     - O corpo contém os 6 dígitos, informa a validade de 10 minutos, não contém nenhum `http://` ou `https://` e inclui o aviso antigolpe da Memora.
  2. Se `canal.getTipo() == TipoDeCanal.TELEFONE`:
     - Lança `FalhaDoMemora` informando que o envio por SMS/telefone não está disponível neste servidor e sugerindo usar e-mail, registrando em log apenas o `canal.getId()` e o tipo `TELEFONE`.
  3. **Invariante de segurança (FR-009)**: `codigoEmClaro` **jamais** é passado a `Logger`, nem concatenado em mensagens de exceção.

### 2.2 `NotificadorDeContaPorEmail` (`@Profile("producao")`)

- **Entrada**: `CanalContato canal`, `String nomeTratamento`.
- **Regras de execução**:
  1. Se `canal.getTipo() == TipoDeCanal.EMAIL`:
     - Envia e-mail informativo a `canal.getValor()` cumprimentando `nomeTratamento`, avisando que a senha do Memora acabou de ser alterada e orientando a abrir diretamente o aplicativo caso não reconheça a alteração (sem links clicáveis).
  2. Se `canal.getTipo() == TipoDeCanal.TELEFONE`:
     - Registra em `WARN` apenas o `canal.getId()` por ausência de gateway SMS, sem interromper a revogação de sessões nem a troca de senha já concluída.

---

## 3. Contrato do Componente `BotaoBase` (`app/lib/design_system/componentes/botoes/botao_base.dart`)

- **Assinatura pública**: permanece 100% compatível (`rotulo`, `estilo`, `alturaMinima`, `aoTocar`, `icone`, `carregando`, `larguraTotal`).
- **Invariantes visuais e semânticas**:
  1. Compõe `SuperficieTocavel(rotulo: rotulo, aoTocar: _habilitado ? aoTocar : null, fundo: fundo, raio: BorderRadius.circular(MemoraRaio.pilula), borda: corDaBorda, child: ...)`.
  2. `AnimatedScale` da `SuperficieTocavel` reduz para `MemoraMovimento.escalaPressionado` (`0.97`) quando pressionado (ou `Duration.zero` com `disableAnimations: true`).
  3. `foregroundDecoration` da `SuperficieTocavel` desenha `Border.all(color: cores.primaria, width: MemoraDimensoes.bordaSelecao, strokeAlign: BorderSide.strokeAlignOutside)` quando focado.
  4. Quando `estilo` é `secundario` ou `terciario` (`fundo == Colors.transparent`), pressionar preenche temporariamente com `cores.destaque`.
