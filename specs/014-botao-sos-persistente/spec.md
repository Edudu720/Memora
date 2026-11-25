# Feature Specification: Feature 014 — Botão SOS Persistente

**Feature Branch**: `feature/014-botao-sos-persistente`
**Created**: 2026-11-16
**Status**: Aprovada para implementação (Feature 014 — solicitação manual de ajuda integrada à CascaInterna)

> Renumerada de `010` para `014` em `2026-11-16`, pois `010` (`specs/010-revisao-pr71-localizador`), `011` (`foto-perfil`), `012` (`site-tutorial-idoso`) e `013` (`redesenho-final`) já existem no repositório.

---

## Clarifications

### Session 2026-11-18

- Q: Como o botão SOS aparece na tela? A versão do APK 1.0.6 mostra três textos (o ícone "sos", "SOS" e "Ajuda") numa pílula, e a casca gasta uma linha inteira no topo de toda tela só para ele. → A: Decisão do Henrique ao testar o APK 1.0.6 no celular: **uma bolinha vermelha (a cor de perigo do tema) com "SOS" escrito em negrito**, igual em todas as telas; sem ícone e sem a palavra "Ajuda". Círculo de 48 dp, que cresce com a letra ampliada (diâmetro = o maior entre 48 dp e o que o texto "SOS" ocupa), sem encolher a letra. O leitor de tela continua anunciando o mesmo de antes ("SOS Ajuda", botão, com a descrição de emergência).
- Q: Onde a bolinha fica? → A: **A faixa do topo sai**; nenhuma tela perde uma linha para o SOS. A bolinha fica **no canto superior direito do cabeçalho de cada tela, na altura do título**: no Início (à direita de "Oi, <nome>!"), em Meu perfil, em Ajuda e nos demais cabeçalhos sem nada à direita. Em **Ajustes**, a paleta que ocupava o canto passa para **antes da palavra "Ajustes"**, menor, e a bolinha fica onde a paleta estava (a regra vale para todo cabeçalho com figura: a figura vai para antes do título). Nas telas com a **barra "Voltar"**, a bolinha fica na própria barra, à direita. Quando o título não cabe ao lado da bolinha (letra muito ampliada em aparelho estreito), a bolinha sobe para a linha do "Voltar" e o título fica com a largura toda: o título nunca é cortado por causa dela. Tela sem cabeçalho nenhum mostra a bolinha flutuando no canto superior direito, dentro da área segura.
- Q: O que continua valendo? → A: o SOS some com o teclado aberto; alvo de toque ≥ 48 dp; nenhum estouro na matriz de aparelhos (4 × 3); a bolinha nunca cobre botão, título ou texto e fica a pelo menos 8 dp de qualquer outro alvo de toque.

---

## 1. Objetivo

Disponibilizar um mecanismo de solicitação manual de ajuda, acessível em todas as telas principais do Memora, permitindo que a pessoa usuária notifique rapidamente seu contato de emergência.

---

## 2. Problema identificado

O mecanismo atual de detecção de quedas contempla situações em que o sistema identifica automaticamente um evento suspeito.

Entretanto, existem situações em que a pessoa necessita de ajuda sem que uma queda tenha ocorrido:

- Mal-estar.
- Sensação de insegurança.
- Dificuldade para realizar uma atividade.
- Necessidade de assistência imediata.
- Situações em que não consegue navegar normalmente pelo aplicativo.

---

## 3. Requisitos funcionais

- **FR-001**: Disponibilizar um botão SOS persistente nas telas principais do aplicativo (`CascaInterna`), **no canto superior direito do cabeçalho de cada tela, na altura do título** — sem faixa própria no topo (nenhuma tela perde uma linha para o SOS). Em Ajustes, a figura que ocupava o canto (a paleta) passa para antes do título, menor, e o mesmo vale para todo cabeçalho com figura; nas telas com a barra "Voltar", a bolinha fica na barra, à direita. Se o título não couber ao lado da bolinha, ela sobe para a linha do "Voltar" (ou para uma linha só dela, à direita, sem "Voltar"); tela sem cabeçalho mostra a bolinha flutuando no canto superior direito, dentro da área segura, sem cobrir nada. (Revisto em 2026-11-18.)
- **FR-002**: O botão é uma **bolinha na cor de perigo do tema com o texto "SOS" em negrito**, sem ícone e sem a palavra "Ajuda": o texto escrito é a identificação explícita (Princípio III). O leitor de tela anuncia o nome "SOS Ajuda", que começa pela palavra escrita (WCAG 2.5.3), e a descrição de emergência. (Revisto em 2026-11-18; antes: ícone mais o texto "SOS Ajuda".)
- **FR-003**: O botão deve permanecer acessível durante a navegação entre módulos dentro da conta autenticada.
- **FR-004**: O acionamento deve apresentar uma confirmação simples e clara antes do envio.
- **FR-005**: O usuário deve conseguir confirmar ou cancelar a solicitação antes do envio ao servidor.
- **FR-006**: Após confirmação, o sistema deve gerar um evento de emergência manual (`SOS_MANUAL`) com `eventoId` único.
- **FR-007**: O sistema deve notificar o contato de emergência previamente cadastrado.
- **FR-008**: A notificação deve identificar o usuário e o horário da solicitação.
- **FR-009**: O sistema deve permitir anexar a localização atual quando disponível e autorizada pelo usuário.
- **FR-010**: O sistema deve informar com clareza e transparência o resultado da tentativa de envio.
- **FR-011**: O sistema deve tratar indisponibilidade de internet e falhas de entrega.
- **FR-012**: O sistema deve evitar notificações duplicadas causadas por acionamentos repetidos (chave de idempotência `eventoId` no cliente e no servidor).
- **FR-013**: O sistema deve registrar o status técnico do evento, sem expor informações internas desnecessárias na interface.
- **FR-014**: O sistema deve permitir distinguir alertas manuais (`SOS_MANUAL`) dos alertas automáticos de queda (`QUEDA_AUTOMATICA`).
- **FR-015**: O sistema deve preservar a integração com o módulo de contato de emergência já existente (`RepositorioContatoEmergencia`).
- **FR-016**: O sistema deve oferecer orientação alternativa quando o contato de emergência não estiver cadastrado ou não puder ser alcançado (acionamento local ou ligação explícita para emergência pública `192`).

---

## 4. Requisitos não funcionais

- **NFR-001**: O botão deve respeitar os alvos de toque definidos na Constituição ($\ge 48 \times 48\text{ dp}$): a bolinha tem no mínimo 48 dp de diâmetro e cresce com a letra ampliada até caber o "SOS" inteiro (a letra nunca encolhe para caber), e fica a pelo menos 8 dp de qualquer outro alvo de toque.
- **NFR-002**: O componente deve possuir contraste elevado (conformidade WCAG 2.2 AA/AAA com tokens do Design System 2.0).
- **NFR-003**: O botão deve possuir semântica acessível completa para leitores de tela.
- **NFR-004**: O envio deve ocorrer por comunicação segura autenticada por token Bearer.
- **NFR-005**: A operação deve possuir tratamento de falhas sem perda silenciosa de estado.
- **NFR-006**: A localização somente poderá ser compartilhada conforme autorização e política de privacidade (retenção máxima de 24h no servidor e nulidade quando não autorizada).
- **NFR-007**: A interface deve apresentar feedback claro de confirmação, processamento, envio e falha (em blocos de até duas frases curtas, sem jargões nem emojis, conforme `memora-ux`).
- **NFR-008**: O sistema não deve afirmar que a ajuda foi recebida pelo contato sem confirmação real do destinatário — o estado `ENVIADO` informa apenas que o sistema encaminhou a solicitação.
- **NFR-009**: A funcionalidade deve preservar o funcionamento e o layout dos demais módulos e matrizes de acessibilidade.

---

## 5. Regras de negócio

- **BR-001**: O botão SOS deve estar disponível nas telas principais dentro da casca autenticada, sempre no mesmo lugar (o canto superior direito do cabeçalho), e some enquanto o teclado está aberto.
- **BR-002**: O usuário deve confirmar explicitamente a solicitação antes do envio.
- **BR-003**: O alerta manual (`SOS_MANUAL`) deve ser identificado separadamente do alerta automático de queda (`QUEDA_AUTOMATICA`).
- **BR-004**: A localização não deve ser compartilhada sem autorização adequada.
- **BR-005**: A notificação deve utilizar o contato de emergência previamente cadastrado.
- **BR-006**: A indisponibilidade de internet deve ser informada claramente.
- **BR-007**: O sistema não deve afirmar que uma notificação foi recebida pelo contato apenas porque foi aceita pelo servidor.
- **BR-008**: O sistema não deve substituir serviços públicos de emergência (`192`), oferecendo a discagem explícita apenas como orientação alternativa mediante ação do usuário.
- **BR-009**: O acionamento deve possuir mecanismo de proteção contra duplicidade.
- **BR-010**: A solicitação não deve ser cancelada automaticamente depois de enviada ao servidor.
- **BR-011**: No perfil `producao`, o envio remoto pelo servidor atualmente requer contato de emergência com e-mail cadastrado; contatos apenas com telefone recebem orientação imediata para acionamento local (WhatsApp/SMS/discador `192`).
- **BR-012**: Para impedir abuso do servidor como disparador de e-mails e esgotamento da cota SMTP compartilhada (Princípio II), o servidor aplica limite de envios por conta e por destinatário (`429 LIMITE_DE_SOS` com espera), valida estritamente o formato do e-mail e não retém `contato_nome`/`contato_destino` após o despacho. Opt-in prévio de confirmação pelo destinatário fica registrado no `/speckit-clarify` como evolução obrigatória antes de ampliar o envio remoto.
- **BR-013**: A classificação `QUEDA_AUTOMATICA` permanece reservada apenas no modelo de dados e contrato; nenhum envio autônomo ocorre sem confirmação explícita da pessoa (Princípio VI).

---

## 6. Dados da notificação e estados do evento

- **Dados**: identificação do usuário (`pessoaId` / `nomeTratamento`), `tipo` (`SOS_MANUAL`), data/horário (`ocorridoEm`), localização opcional (`latitude`, `longitude`), identificador único (`eventoId`), `contato` e `status`.
- **Estados do evento**:
  - `PENDENTE`
  - `PROCESSANDO`
  - `ENVIADO`
  - `FALHA`
  - `CONFIRMADO_PELO_DESTINATARIO` (reservado para confirmação real do canal)

---

## 7. Como um golpista exploraria isto? (Princípio II)

| Superfície | Risco | Mitigação |
|---|---|---|
| **Acionamento acidental ou induzido** | Falso pedido de socorro ou pânico por toque involuntário | Confirmação explícita em modal antes de enviar (`FR-004`, `BR-002`) com botão de cancelar separado do confirmar |
| **Falsa sensação de socorro garantido** | Pessoa acreditar que o contato ou ambulância já estão a caminho | Texto explícito informando que `ENVIADO` significa encaminhamento pelo sistema, oferecendo discagem `192` ou WhatsApp local (`BR-007`, `BR-008`, `NFR-008`) |
| **Vazamento de localização** | Captura indevida de coordenadas sem consentimento ou retenção permanente | Coordenadas opcionais apenas se permissão já estiver concedida no dispositivo e expurgo automático em 24 horas no banco (`NFR-006`) |
| **Replay ou rajada de requisições** | Esgotamento do canal do cuidador | Chave de idempotência `eventoId` (`UUID`) única por solicitação e travamento de toque repetido na UI (`FR-012`, `BR-009`) |

---

## 8. Critérios de aceitação

- **AC-001**: O botão está acessível nas telas principais.
- **AC-002**: O usuário consegue solicitar ajuda manualmente.
- **AC-003**: O usuário consegue cancelar antes da confirmação.
- **AC-004**: O contato cadastrado recebe a notificação quando o serviço está disponível.
- **AC-005**: A localização é compartilhada somente quando autorizada.
- **AC-006**: A interface apresenta o resultado do envio de forma verdadeira.
- **AC-007**: Falhas de rede são tratadas com orientação alternativa.
- **AC-008**: Eventos duplicados são evitados.
- **AC-009**: Alertas manuais (`SOS_MANUAL`) são diferenciados de alertas de queda (`QUEDA_AUTOMATICA`).
- **AC-010**: Acessibilidade e navegação permanecem funcionais.

---

## 9. Fora do escopo inicial

- Central de atendimento humano 24 horas.
- Monitoramento contínuo ou rastreamento em segundo plano.
- Ligação automática para serviços públicos.
- Aplicativo independente para cuidadores.
- Garantia de atendimento emergencial ou envio de SMS pago.
