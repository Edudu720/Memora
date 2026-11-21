# Feature Specification: Estabilidade da API do Gemini (Item 12)

**Feature Branch**: `feature/018-estabilidade-gemini`
**Created**: 2026-11-20
**Status**: Draft
**Input**: User description: "Item 12 da Issue #106: Diagnosticar e estabilizar a conversa em produção com a API do Gemini mantendo `gemini-3.6-flash` como modelo principal, adicionando retentativa curta antes do primeiro trecho e modelo reserva configurável (`gemini-3.5-flash-lite`) para contornar sobrecargas (`503`) e estouro de cota (`429`) sem expor dados ou segredos."

## Clarifications

### Session 2026-11-20

- Q: Respostas vazias por bloqueio de segurança (`RESPOSTA_VAZIA`) ou formato JSON inválido (`RESPOSTA_ILEGIVEL`) devem acionar retentativa ou modelo reserva? → A: Não; apenas erros operacionais recuperáveis antes do primeiro trecho (`FALHA_DO_PROVEDOR`, `REDE`, `PRAZO` e `COTA_ESGOTADA`) acionam retentativa/reserva. `PEDIDO_RECUSADO`, `RESPOSTA_VAZIA` e `RESPOSTA_ILEGIVEL` falham imediatamente.
- Q: Qual falha deve ser propagada quando tanto o modelo principal quanto o modelo reserva falham? → A: Propagar o `AssistenteIndisponivel` retornado pela última tentativa executada (do reserva quando acionado, ou do principal quando reserva desabilitado), sempre sem corpo externo nem segredo.
- Q: Retentativas e acionamento do modelo reserva consomem mais de um turno na cota diária da pessoa usuária? → A: Não; a contagem em `LimitePorConta` ocorre uma única vez por turno antes da chamada ao adaptador.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Recuperar automaticamente de instabilidade transitória (`503`/rede) no modelo principal (Priority: P1)

Como pessoa usuária conversando com a Memora em produção, quero que falhas momentâneas de sobrecarga (`503`) ou oscilação inicial antes do início da resposta sejam tentadas novamente de forma rápida e silenciosa, para que eu receba a resposta normalmente sem ver mensagem de erro por um pico passageiro.

**Why this priority**: A principal causa percebida de instabilidade no nível gratuito são erros `503 UNAVAILABLE` esporádicos antes da entrega do primeiro trecho da resposta.

**Independent Test**: Configurar servidor HTTP simulado retornando `503` na primeira tentativa e `200` com streaming SSE válido na segunda tentativa; confirmar que a chamada devolve a resposta completa sem erro e sem duplicação.

**Acceptance Scenarios**:

1. **Given** o modelo principal (`gemini-3.6-flash`) retorna erro transitório (`5xx`, falha inicial de rede ou prazo antes de enviar qualquer trecho), **When** o limite de tentativas no principal ainda não se esgotou, **Then** o adaptador aguarda breve intervalo configurado e realiza nova tentativa automática no modelo principal.
2. **Given** a resposta começa a transmitir o primeiro trecho ao usuário (`enviouTrecho == true`) e falha depois no meio do fluxo, **When** a conexão ou o fluxo interrompe, **Then** o adaptador **não** retenta e **não** troca de modelo, preservando integridade do texto parcial e falhando de forma limpa.

---

### User Story 2 - Acionar modelo reserva (`gemini-3.5-flash-lite`) quando o principal esgotar cota ou falhar (Priority: P1)

Como pessoa usuária que conversa com a Memora pelo nível gratuito da API, quero que o sistema utilize automaticamente o modelo reserva configurado (`gemini-3.5-flash-lite`) quando o modelo principal (`gemini-3.6-flash`) responder cota esgotada (`429`) ou continuar indisponível após as retentativas, para que a conversa siga funcionando com a mesma persona, catálogo e regras de segurança.

**Why this priority**: Cotas RPM/RPD e picos de carga do nível gratuito são isolados por modelo no Google AI Studio; ter reserva configurável elimina quase todas as quedas visíveis ao usuário mantendo o `3.6-flash` como principal.

**Independent Test**: Simular servidor respondendo `429` no caminho do modelo principal e `200` no modelo reserva; confirmar exatamente 1 chamada ao principal (sem insistir em `429`) seguida de 1 chamada ao reserva contendo `systemInstruction`, `tools` e `x-goog-api-key` idênticos.

**Acceptance Scenarios**:

1. **Given** o modelo principal retorna HTTP `429` (cota esgotada) antes de qualquer trecho, **When** um modelo reserva distinto está configurado, **Then** o adaptador **não** insiste no principal e envia imediatamente o pedido ao modelo reserva.
2. **Given** o modelo principal esgotou todas as retentativas com `5xx`, `REDE` ou `PRAZO` sem enviar nenhum trecho, **When** um modelo reserva distinto está configurado, **Then** o adaptador realiza tentativa automática no modelo reserva.
3. **Given** a falha inicial é recusa definitiva de pedido (`4xx` diferente de `429`, ex.: `400`, `401`, `403`), **When** o provedor responde o erro, **Then** o adaptador **não** retenta e **não** aciona o modelo reserva, evitando desperdício e mascaramento de chave ou formato inválido.

---

### User Story 3 - Alinhar defaults e configurar parâmetros de resiliência em código e Blueprint (Priority: P2)

Como mantenedor do Memora em produção e em desenvolvimento, quero que o código e o arquivo de propriedades tenham `gemini-3.6-flash` como padrão oficial (alinhado ao Render e à ADR-002), com modelo reserva (`gemini-3.5-flash-lite`), número de tentativas e intervalo configuráveis por variáveis de ambiente validadas na subida, para evitar divergência silenciosa entre ambientes e barrar configuração inválida no boot.

**Why this priority**: Hoje o código ainda aponta padrão `gemini-3.8-flash` enquanto o `render.yaml` força `gemini-3.6-flash`; alinhar defaults e expor configuração validada reduz erro operacional.

**Independent Test**: Subir o contexto Spring de configuração do provedor com valores válidos, vazios e malformados (ex.: `modelo-reserva` com `..`, `tentativas-primario < 1`, `espera-retentativa-ms < 0`), validando subida ou recusa segura sem vazar segredos.

**Acceptance Scenarios**:

1. **Given** o ambiente não sobrescreve `MEMORA_ASSISTENTE_GEMINI_MODELO` nem `MEMORA_ASSISTENTE_GEMINI_MODELO_RESERVA`, **When** a aplicação sobe com provedor `gemini`, **Then** utiliza `gemini-3.6-flash` como principal e `gemini-3.5-flash-lite` como reserva, registrando ambos os nomes em log sem a chave.
2. **Given** `MEMORA_ASSISTENTE_GEMINI_MODELO_RESERVA` está vazio ou igual ao modelo principal, **When** o provedor é construído, **Then** o fallback fica desativado sem chamadas duplicadas.
3. **Given** `modelo-reserva` possui formato inválido ou `tentativas-primario < 1` ou `espera-retentativa-ms < 0`, **When** a aplicação tenta subir, **Then** o boot falha imediatamente com `IllegalStateException` clara e sem expor `GEMINI_API_KEY`.

---

### Edge Cases

- **Ambos os modelos falham (`3.6-flash` e `3.5-flash-lite`)**: O adaptador lança `AssistenteIndisponivel` com motivo e status seguros da última falha relevante, sem corpo externo de erro do Google, sem chave e sem endereço na mensagem.
- **Tempo de espera total na conversa**: Como o app cancela após `30 s` (`esperaMaxima`), a espera entre retentativas no backend deve ser curta (padrão `500 ms`) e com no máximo `2` tentativas no principal + `1` no reserva para não estourar o prazo percebido no celular.
- **Erro `429` / erro JSON dentro do stream SSE antes do 1º trecho**: Como nenhum trecho chegou ao consumidor, segue exatamente a mesma regra de status (`429` aciona reserva; `5xx` retenta/aciona reserva); após o 1º trecho, nunca retenta.
- **Interrupção de thread durante espera (`Thread.sleep`)**: Restaura o sinal de interrupção (`Thread.currentThread().interrupt()`) e interrompe imediatamente lançando `AssistenteIndisponivel(Motivo.REDE, "interrompido")`.

---

## Segurança e Análise Anti-Engenharia Social *(Constituição I, II e VI)*

### Threat Model

| Aspecto | Análise |
| :--- | :--- |
| **Dados sensíveis envolvidos** | Chave `GEMINI_API_KEY` e conteúdo eventual escrito pela pessoa na conversa (já regido pela Emenda 1 e FR-051, sem qualquer identificador pessoal anexado pelo backend). |
| **Quem acessa** | Endpoint autenticado `/v1/assistente/conversa` com limite diário por conta (`LimitePorConta` e `AutorizadorDeAcao`). |
| **Ameaças possíveis** | 1. **Amplificação de cota / DoS**: retentativas excessivas multiplicarem chamadas em loop contra o provedor.<br>2. **Bypass de segurança no modelo reserva**: o fallback omitir `systemInstruction`, catálogo fechado ou ferramenta única, ou pular `AutorizadorDeAcao`.<br>3. **Vazamento de chave ou detalhe externo em log/resposta**: exceções de falha dupla ou validação imprimirem `GEMINI_API_KEY` ou corpo de erro do Google.<br>4. **Path traversal / SSRF por nome de modelo**: parâmetro `modelo-reserva` com `..`, `/` ou query string manipulando o caminho HTTP. |
| **Impacto potencial** | Esgotamento rápido da cota gratuita para todas as contas, resposta insegura não autorizada ou exposição de erro técnico assustador para a pessoa idosa. |
| **Mitigação obrigatória** | Limitar tentativas no principal (`tentativas-primario` padrão `2`, `429` não retenta no principal, `4xx` não-429 não retenta nem faz fallback, e pós-1º-trecho jamais retenta); validar `modelo-reserva` com regex estrita `[A-Za-z0-9._-]+`; montar exatamente o mesmo `Pedido` (`systemInstruction`, `tools`, `contents`) e cabeçalho `x-goog-api-key` no modelo reserva; manter descarte completo do corpo de erro HTTP externo; manter contagem de turno único no `ServicoDeConversa`. |
| **Monitoramento / Verificação** | Logs `WARN` registrando apenas nome do modelo, motivo e status HTTP (sem corpo/chave); testes automatizados validando path, cabeçalho, `systemInstruction`, ferramentas e não-vazamento. |

### Análise de Engenharia Social — *"Como um golpista ou erro operacional exploraria esta mudança?"*

- Se o provedor falhar após esgotar principal e reserva, a pessoa idosa não pode receber códigos técnicos (`503`, `429`, nome de modelo ou mensagem externa em inglês), que geram medo ou abrem brecha para falso suporte técnico. A camada de controle continua exibindo exclusivamente a frase acolhedora fixa da Memora (`ASSISTENTE_INDISPONIVEL`).
- O modelo reserva (`gemini-3.5-flash-lite`) nunca recebe privilégio diferente do principal: qualquer tentativa do modelo de sugerir aplicativo continua barrada pelo catálogo ativo em `AutorizadorDeAcao`.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O modelo padrão principal do adaptador Gemini MUST ser `gemini-3.6-flash` em `application.properties`, `ConfiguracaoDoProvedorDeIa` e `render.yaml`.
- **FR-002**: O adaptador MUST aceitar modelo reserva configurável via `memora.assistente.gemini.modelo-reserva` (`MEMORA_ASSISTENTE_GEMINI_MODELO_RESERVA`) com padrão `gemini-3.5-flash-lite` (definido também em `render.yaml`), permitindo string vazia (ou igual ao principal) para desativar o fallback.
- **FR-003**: O adaptador MUST aceitar `memora.assistente.gemini.tentativas-primario` (padrão `2`, mínimo `1`) e `memora.assistente.gemini.espera-retentativa-ms` (padrão `500`, mínimo `0`).
- **FR-004**: Antes do envio de qualquer trecho de texto ao consumidor (`enviouTrecho == false`):
  - Erros `5xx` (`FALHA_DO_PROVEDOR`), `REDE` ou `PRAZO` MUST retentar no modelo principal até o limite de `tentativas-primario`, respeitando `espera-retentativa-ms` entre tentativas; se todas falharem e houver reserva distinto, tentar uma vez no modelo reserva.
  - Erro `429` (`COTA_ESGOTADA`) MUST pular novas tentativas no modelo principal e acionar imediatamente uma tentativa no modelo reserva (quando habilitado).
  - Erro `4xx` diferente de `429` (`PEDIDO_RECUSADO`) MUST falhar imediatamente sem retentativa e sem modelo reserva.
- **FR-005**: Após qualquer trecho já entregue ao consumidor (`enviouTrecho == true`), o adaptador MUST falhar imediatamente sem retentativa nem troca de modelo.
- **FR-006**: A validação na subida MUST rejeitar `modelo-reserva` não vazio fora do padrão `[A-Za-z0-9._-]+`, `tentativas-primario < 1` ou intervalo negativo com `IllegalStateException`, sem expor `GEMINI_API_KEY`.
- **FR-007**: A chamada ao modelo reserva MUST usar exatamente a mesma `systemInstruction`, declarações de ferramentas, histórico normalizado e cabeçalho `x-goog-api-key` (nunca na URL), mantendo a compatibilidade da assinatura legada nos testes unitários existentes.
- **FR-008**: Documentação viva (`docs/architecture/adr-002-provedor-de-ia.md`, `docs/deploy/render.md` e `CHANGELOG.md`) MUST ser atualizada na mesma entrega explicando a política `3.6-flash` → `3.5-flash-lite`.

### Key Entities *(não há persistência nova em banco)*

- **Política de Resiliência do Provedor Gemini**: Configuração imutável carregada na inicialização composta por modelo principal, modelo reserva opcional, limite de tentativas no principal e intervalo de espera entre retentativas.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% dos cenários de falha transitória recuperável (`503` intermitente no principal, `503` persistente coberto pelo reserva e `429` no principal coberto pelo reserva) completam a conversa com sucesso em testes automatizados contra servidor HTTP local.
- **SC-002**: 100% dos cenários de erro não elegível (`400`/`403` e falha após 1º trecho) encerram sem chamada extra indevida e sem duplicação de texto.
- **SC-003**: 100% da suíte de testes do backend (`mvnw.cmd test`) passa após a alteração sem regressões de contrato, segurança ou vazamento de chave/texto externo.

## Assumptions

- O endpoint `/v1beta/models/{modelo}:streamGenerateContent?alt=sse` e o formato de corpo/SSE são idênticos entre `gemini-3.6-flash` e `gemini-3.5-flash-lite`.
- O teto de turnos por conta (`LimitePorConta` em `ServicoDeConversa`) continua contando uma única vez por turno do usuário, independentemente de retentativa ou fallback interno do adaptador.
