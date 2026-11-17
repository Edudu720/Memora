# Feature 014 — Botão SOS Persistente
# Implementation Plan

## 1. Arquitetura

### Flutter (`app/lib/features/cuidado/` e `app/lib/features/casca/`)
- Criar componente compartilhado `BotaoSosPersistente` usando `SuperficieTocavel` e tokens do Design System 2.0 (`cores.perigo`, `cores.sobrePerigo`, `MemoraDimensoes.alvoMinimo`, `Icons.sos_rounded` e texto explícito `"SOS Ajuda"`), sem usar literais visuais fora de `tokens/`.
- Integrar `BotaoSosPersistente` na `CascaInterna` de maneira persistente durante toda a navegação dentro da conta, ocultando apenas quando o teclado estiver aberto e mantendo compatibilidade total com `ProfundidadeTest`, `MatrizDentroDaContaTest` e `HubCabeSemRolarTest`.
- Criar `DialogoSosEmergencia` com confirmação explícita antes do envio, estado de processamento bloqueando cliques repetidos, feedback verdadeiro do resultado (`ENVIADO`, `FALHA`, `falhaConexao`) e orientação alternativa (`192` e acionamento direto via `DispararSocorroEmergencia` já existente).
- Criar `ControladorSosEmergencia` e repositório (`RepositorioEmergenciaSos`, `RepositorioEmergenciaSosApi`, `RepositorioEmergenciaSosSimulado`) reutilizando `RepositorioContatoEmergencia` da feature 005.
- Definir textos em `app/lib/l10n/textos_sos.dart` respeitando `memora-ux` (até 2 frases curtas por bloco, zero emojis, zero palavras proibidas) e cobri-los no portão `texto_da_interface_test.dart`.

### Spring Boot (`backend/src/main/java/br/fatec/memora/emergencia/`)
- Migration Flyway `V12__evento_emergencia_sos.sql` criando a tabela `evento_emergencia` com chave primária `id` (`UUID` usado como chave de idempotência `eventoId`), vínculo com `pessoa_usuaria`, `tipo`, `status`, localização opcional com `expira_localizacao_em`, contato e metadados de entrega técnica.
- Entidade JPA `EventoEmergencia`, enums `TipoEventoEmergencia` (`SOS_MANUAL`, `QUEDA_AUTOMATICA`) e `StatusEventoEmergencia` (`PENDENTE`, `PROCESSANDO`, `ENVIADO`, `FALHA`, `CONFIRMADO_PELO_DESTINATARIO`), repositório `RepositorioEventoEmergencia` e expurgo agendado de coordenadas expiradas (24h).
- Serviço de notificação `NotificadorDeEmergencia` com implementação de desenvolvimento (`NotificadorDeEmergenciaEmLog`, `@Profile("!producao")`) e de produção via Spring Mail (`NotificadorDeEmergenciaPorEmail`, `@Profile("producao")`), sem links clicáveis e sem SMS pago automático.
- `ServicoEmergenciaSos` com proteção de idempotência por `eventoId`, distinção entre solicitação manual e queda automática, registro do status técnico sem vazar detalhes internos na resposta e mensagem transparente.
- `EmergenciaSosController` expondo `POST /api/v1/emergencias/sos` e `/v1/emergencias/sos` protegido pelo filtro de token de acesso (`PessoaAutenticada`, recusando usuários não autenticados ou pendentes).

## 2. Contrato da API (`POST /api/v1/emergencias/sos` e `/v1/emergencias/sos`)

### Request
```json
{
  "tipo": "SOS_MANUAL",
  "eventoId": "uuid",
  "localizacao": {
    "latitude": -22.7392,
    "longitude": -47.3314
  },
  "contatoNome": "Maria Silva",
  "contatoDestino": "maria@email.com"
}
```
A `localizacao` é opcional e só enviada quando autorizada no dispositivo.

### Response (`200 OK`)
```json
{
  "eventoId": "uuid",
  "tipo": "SOS_MANUAL",
  "status": "ENVIADO",
  "mensagem": "Sua solicitação foi encaminhada. Isso indica que o alerta foi aceito pelo sistema, mas não confirma o recebimento pelo contato.",
  "ocorridoEm": "2026-11-16T18:20:00Z"
}
```

## 3. Prevenção de Duplicidade & Privacidade
- Cada tentativa confirmada no cliente gera um `UUID` único (`eventoId`), reutilizado em caso de retentativa de rede e recusado/bloqueado contra cliques repetidos enquanto o envio está em processamento.
- No backend, a chave primária da tabela `evento_emergencia` é o próprio `eventoId`. Reenvios com o mesmo `eventoId` e o mesmo usuário retornam o registro existente sem disparar nova notificação; `eventoId` pertencente a outro usuário é rejeitado.
- Localização só é persistida quando explicitamente fornecida e recebe prazo de expiração (`expira_localizacao_em = ocorrido_em + 24h`), sendo removida em expurgo periódico.

## 4. Testes
- Presença persistente do botão SOS nas telas principais durante navegação entre módulos da `CascaInterna`.
- Alvo de toque $\ge 48 \times 48\text{ dp}$, texto explícito (`"SOS Ajuda"`) e semântica acessível.
- Cancelamento antes da confirmação sem gerar evento.
- Acionamento manual com contato cadastrado -> evento `SOS_MANUAL` enviado com feedback honesto.
- Compartilhamento de localização condicional à autorização.
- Indisponibilidade de internet e contato inexistente/não alcançado -> tratamento claro e orientação alternativa (`192` e acionamento local).
- Idempotência contra acionamentos duplicados (UI e backend).
- Diferenciação `SOS_MANUAL` vs `QUEDA_AUTOMATICA`.
- Autenticação obrigatória (`401 Unauthorized` sem token).
- Portões de texto (`texto_da_interface_test.dart`, `TextoDaInterfaceTest`), tokens (`validar_tokens.py`) e paleta (`validar_paleta.py`).
