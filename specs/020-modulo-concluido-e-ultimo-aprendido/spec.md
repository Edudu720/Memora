# Especificação da Feature: Módulo Concluído, Checkbox de Seção e Último Módulo Concluído

**Feature Branch**: `feature/020-modulo-concluido-e-ultimo-aprendido`
**Created**: 2026-11-20
**Status**: Approved (Clarified via recommended options)
**Input**: Item 14a da Issue #106 (`Edudu720/Memora`): "14a (Em paralelo no código): Módulos já aprendidos marcados como concluídos na lista de módulos; campo do último módulo aprendido em Meu Perfil. Quando todas as seções forem terminadas, após terminar uma sessão, aparecer um checkbox verde arredondado ao lado."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Marcar módulo como concluído na lista de aplicativos/serviços (Priority: P1)

Como pessoa usuária do Memora, ao abrir a lista de aplicativos do celular ou serviços sociais no catálogo, quero ver claramente marcados como **"Concluído"** apenas os módulos cujo passo a passo eu já finalizei por completo (todas as seções concluídas nos guias divididos por seção, ou o guia inteiro nos guias diretos), para reconhecer o que já dominei sem me confundir com o que ainda falta.

**Why this priority**: Dá visibilidade imediata de conquista na porta de entrada dos tutoriais sem exigir memória da pessoa usuária, respeitando a regra de módulos parcialmente aprendidos não serem declarados concluídos antes da hora.

**Independent Test**: Montar `TelaCatalogo` com um `ProgressoDeAprendizado` local contendo: (a) um guia direto concluído (`whatsapp`), (b) um guia seccionado concluído apenas em parte (`gov-br:entrar`), e (c) um guia seccionado com todas as seções concluídas (`telegram`). Verificar que o selo `"Concluído"` aparece em `whatsapp` e `telegram`, e NÃO aparece em `gov-br` até a última seção restante ser concluída.

**Acceptance Scenarios**:

1. **Given** uma conta que chegou ao último passo de um guia sem seções (ex.: `whatsapp`), **When** ela abre `TelaCatalogo`, **Then** o cartão do item exibe o selo informativo `BadgeDeStatus` `"Concluído"` (`Icons.check_circle_rounded`, tom positivo) junto ao selo de capacidade, sem alterar nem quebrar o layout nem confundir selo com botão.
2. **Given** uma conta que concluiu apenas parte das seções de um guia seccionado (ex.: 1 de 6 seções do `gov-br` ou 4 de 5 seções do `instagram`), **When** ela visualiza `TelaCatalogo`, **Then** o módulo **não** exibe o selo `"Concluído"`.
3. **Given** uma conta que conclui a última seção restante de um guia seccionado no passo a passo e retorna pela pilha até `TelaCatalogo` já aberta, **When** `ProgressoDeAprendizado` persiste a conclusão e notifica `alteracoes`, **Then** `TelaCatalogo` atualiza o estado automaticamente sem precisar sair e abrir a tela de novo, passando a exibir `"Concluído"` naquele módulo.
4. **Given** uma saída da conta (`LimpezaDeSessao` -> `ProgressoDeAprendizado.apagar()`) ou usuário sem conclusões, **When** outra conta abre `TelaCatalogo`, **Then** nenhum item aparece marcado como `"Concluído"`.

---

### User Story 2 - Checkbox verde arredondado ao lado de cada seção concluída (Priority: P1)

Como pessoa usuária do Memora percorrendo um módulo dividido em seções (`TelaSeletorDeSecao`), quero ver um **checkbox verde arredondado** ao lado de cada seção que eu já terminei — sempre acompanhado de texto e anúncio claro para leitor de tela — e vê-lo aparecer imediatamente ao terminar uma seção e voltar ao seletor, para saber exatamente quais assuntos daquele aplicativo ainda faltam.

**Why this priority**: Atende diretamente ao pedido explícito do autor da demanda (*"após terminar uma sessão, aparecer um checkbox verde arredondado ao lado"*) e garante conformidade simultânea com `memora-ux` (cor nunca sozinha; combinação de checkbox verde arredondado + texto `Já aprendeu` + TalkBack `"Concluído"`).

**Independent Test**: Abrir `TelaSeletorDeSecao` para um guia seccionado com uma seção concluída (`gov-br:certidoes`) e verificar que apenas o cartão dessa seção exibe o checkbox verde arredondado à direita, mantendo o texto `Já aprendeu`, anunciando `"Concluído"` na semântica TalkBack e reagindo ao vivo quando outra seção é concluída em `ProgressoDeAprendizado`.

**Acceptance Scenarios**:

1. **Given** um guia seccionado onde a seção `certidoes` foi concluída e `entrar` e `perfil` não foram, **When** `TelaSeletorDeSecao` é exibida, **Then** somente `certidoes` renderiza o widget visual de checkbox verde arredondado (`TelaSeletorDeSecao.chaveCheckDaSecao('certidoes')`), usando tokens `cores.sucesso`, borda arredondada `MemoraRaio.balaoPonta` (`6 dp`), borda de ênfase em alto contraste e ícone `Icons.check_rounded`.
2. **Given** uma seção concluída, **When** o TalkBack lê o cartão (`LinhaDeLista`), **Then** o rótulo semântico anuncia título, subtítulo, contagem com `"Já aprendeu"` e `"Concluído."` sem depender apenas da cor verde nem adicionar nó de toque duplicado (o checkbox é envolvido em `ExcludeSemantics`).
3. **Given** a pessoa na tela `TelaSeletorDeSecao` que abre `TelaPassoAPasso` de uma seção, chega ao último passo e volta para `TelaSeletorDeSecao` ainda montada na pilha, **When** `ProgressoDeAprendizado.registrarConclusao` termina e emite em `alteracoes`, **Then** `TelaSeletorDeSecao` recarrega `_concluidas` automaticamente e passa a mostrar o checkbox verde arredondado e o contador atualizado de progresso no topo.
4. **Given** escalas de fonte de até 200% e largura a partir de `320 dp` nos temas claro, escuro e alto contraste, **When** uma ou todas as seções estão concluídas, **Then** não há overflow nem sobreposição com a seta de navegação do `LinhaDeLista`.

---

### User Story 3 - Campo informativo "Último módulo concluído" em Meu Perfil (Priority: P2)

Como pessoa usuária do Memora, ao abrir a aba **Meu perfil**, quero ver um campo puramente informativo mostrando qual foi o **último módulo concluído** (ou uma frase acolhedora quando ainda não concluí nenhum completo), mantendo intacta toda a privacidade local e o campo já existente "O que você mais aprendeu", para acompanhar minha conquista mais recente sem nenhuma aparência de botão nem risco de vazamento entre contas.

**Why this priority**: Complementa o acompanhamento de aprendizado no perfil sem quebrar contratos existentes da US8/FR-042 (`chaveMaisAprendido`) e mantendo compatibilidade limpa com a arquitetura de perfil e `casca_interna`.

**Independent Test**: Abrir `TelaPerfil` com `ProgressoDeAprendizado` local e validar que `TelaPerfil.chaveUltimoAprendido` existe como `CampoInformacao` não clicável, exibe `TextosPerfil.ultimoAprendidoVazio` quando vazio ou quando apenas parte das seções de um módulo foi concluída, passa a exibir o nome legível do módulo quando concluído por completo (mesmo que diferente do mais aprendido), atualiza ao vivo pela aba em `CascaInterna`, não faz chamadas de rede (`FR-042a`) e é limpo na saída (`FR-042b`).

**Acceptance Scenarios**:

1. **Given** uma conta sem módulos concluídos por completo (vazio ou apenas com parte das seções de `gov-br` concluída), **When** ela abre `TelaPerfil`, **Then** `TelaPerfil.chaveUltimoAprendido` exibe `"Último módulo concluído"` com valor `"Ainda vamos concluir o primeiro!"`, enquanto `TelaPerfil.chaveMaisAprendido` continua funcional e independente.
2. **Given** uma conta que concluiu `WhatsApp` duas vezes e depois concluiu `YouTube` uma vez, **When** ela abre `TelaPerfil`, **Then** `O que você mais aprendeu` exibe `"WhatsApp"` e `Último módulo concluído` exibe `"YouTube"`.
3. **Given** uma conta que concluiu todas as 2 seções do `Telegram` em momentos distintos, **When** a última seção restante do `Telegram` é finalizada, **Then** a ordem efetiva de conclusão do módulo `Telegram` passa a ser a maior `ordem` entre suas seções, e se essa for a conclusão completa mais recente, `Último módulo concluído` exibe `"Telegram"`.
4. **Given** a tela `TelaPerfil` já montada dentro da `CascaInterna` enquanto a pessoa alterna para `Início` para terminar um guia, **When** o guia termina e a pessoa volta à aba `Perfil`, **Then** a inscrição em `ProgressoDeAprendizado.alteracoes` já atualizou o estado para o último módulo concluído sem exigir reconstrução manual.
5. **Given** o campo `TelaPerfil.chaveUltimoAprendido`, **When** inspecionada a árvore semântica e de widgets, **Then** possui `isButton: false`, `hasTapAction: false`, zero `InkWell`, zero termos de plano/assinatura/pagamento e zero chamadas HTTP (`FR-042a`).

---

### Edge Cases

- **Módulo com seções parcialmente concluídas**: em `gov-br` (6 seções), `serasa` (4 seções), `instagram` (5 seções), `facebook` (3 seções), `telegram` (2 seções) e `correios` (2 seções), concluir 1..N-1 seções NÃO marca o módulo como `"Concluído"` em `TelaCatalogo` e NÃO o elege como `"Último módulo concluído"` em `TelaPerfil` (apenas o contador `X de Y assuntos aprendidos` e o checkbox verde individual em `TelaSeletorDeSecao` mudam).
- **Refazer seção após já ter concluído o módulo**: se a pessoa concluiu todas as seções do módulo A, depois concluiu o módulo B, e em seguida refaz uma seção do módulo A, a maior `ordem` das seções completas de A passa a superar a de B e A volta a ser o módulo concluído por último.
- **Conta vazia / `idDaConta` nulo ou em branco / `progresso` nulo**: telas degradam graciosamente sem exceção, exibindo estados não concluídos em catálogo/seletor e a frase acolhedora em `TelaPerfil`.
- **Arquivo local ausente ou corrompido / erro de leitura**: leitura retorna mapa vazio sem travar navegação nem quebrar telas; gravações/leituras permanecem serializadas via `_naFila`.
- **Módulo cujo serviço aparece no catálogo vs apenas na lista de guias**: resolução de nome legível reutiliza `RepositorioAssistenteSimulado.catalogoDaDemonstracao`, com fallback para `guiaDe(chave)?.titulo` e depois `chave`, sem duplicar lógica.
- **Limpeza ao sair ou apagar**: após `ProgressoDeAprendizado.apagar()`, a emissão em `alteracoes` limpa listas/estados em memória de quaisquer telas ainda montadas antes da destruição da árvore.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `ProgressoDeAprendizado` MUST expor uma stream broadcast `alteracoes` emitindo notificação após a conclusão persistida em `registrarConclusao` e após a remoção completa em `apagar`.
- **FR-002**: `ProgressoDeAprendizado` MUST expor `Future<Map<String, int>> ordensDeConclusao(String idDaConta)` e `Future<String?> ultimoConcluido(String idDaConta)` baseados no contador monotônico `ordem` já persistido no arquivo local `progresso_de_aprendizado.json`.
- **FR-003**: O domínio de aprendizado MUST fornecer função pura `moduloConcluido(Guia guia, Map<String, int> concluidos)` que retorne `true` apenas quando todas as seções (em guias com `temSecoes == true` e `secoes.isNotEmpty`) ou a chave direta do guia (em guias sem seções) possuírem contagem `> 0`.
- **FR-004**: O domínio de aprendizado MUST fornecer função pura `chaveDoUltimoModuloConcluido(Map<String, int> ordens, Iterable<Guia> guias)` que considere apenas módulos integralmente concluídos (usando a maior `ordem` entre suas seções quando seccionado) além de eventuais chaves avulsas sem `:` para compatibilidade com guias/testes fora do catálogo fixo.
- **FR-005**: `TelaCatalogo` MUST aceitar parâmetros opcionais `progresso` e `idDaConta` (mantendo compatibilidade com chamadas existentes e sendo conectada no `FluxoAutenticacao._abrirCatalogo`), exibindo o `BadgeDeStatus` informativo `"Concluído"` (chave `TelaCatalogo.chaveConcluidoDoItem(servico.chave)`) apenas para módulos com `moduloConcluido(guia, _concluidos) == true` e reagindo a `progresso.alteracoes`.
- **FR-006**: `TelaSeletorDeSecao` MUST exibir um checkbox verde arredondado (`TelaSeletorDeSecao.chaveCheckDaSecao(secao.chave)`) ao lado direito de cada seção concluída em `LinhaDeLista(direita: ...)`, construído exclusivamente com tokens do Design System (`MemoraCores.sucesso`, `MemoraDimensoes.iconeDestaque`, `MemoraDimensoes.iconePequeno`, `MemoraRaio.balaoPonta`, `MemoraDimensoes.bordaEnfase` em alto contraste, ícone `Icons.check_rounded` em `cores.superficie` no tema claro ou `cores.fundo` nos temas escuros), envolvido em `ExcludeSemantics`.
- **FR-007**: `TelaSeletorDeSecao` MUST manter o texto `Já aprendeu` no rodapé da seção concluída e anunciar `"Concluído."` via `TextosGuias.secaoConcluidaDescrita(...)` para leitores de tela, preservando intacto `TextosGuias.secaoDescrita(...)` para seções ainda não concluídas.
- **FR-008**: `TelaSeletorDeSecao` MUST assinar `widget.progresso?.alteracoes`, atualizar corretamente ao mudar props (`didUpdateWidget`), limpar marcações quando `apagar()` ocorrer e cancelar a assinatura em `dispose`.
- **FR-009**: `TelaPerfil` MUST adicionar o campo `CampoInformacao` puramente informativo `TelaPerfil.chaveUltimoAprendido` (`Key('perfil.ultimo_aprendido')`) com rótulo `"Último módulo concluído"` (`TextosPerfil.rotuloUltimoAprendido`), valor resolvido por `chaveDoUltimoModuloConcluido(ordens, todosOsGuias)` ou `"Ainda vamos concluir o primeiro!"` (`TextosPerfil.ultimoAprendidoVazio`) quando vazio/nulo, preservando `TelaPerfil.chaveMaisAprendido` intacto.
- **FR-010**: Todos os textos visíveis ou semânticos adicionados em `app/lib/l10n/` MUST cumprir o portão `texto_da_interface_test.dart` (<= 2 frases curtas, zero emojis, linguagem neutra em gênero e zero palavras proibidas) e `sem_planos_test.dart` (zero termos de plano/assinatura/pagamento e zero jargões da `FR-008`).
- **FR-011**: Todos os ícones adicionados em `app/lib/` MUST terminar em `_rounded` (`icones_e_toque_test.dart`), e nenhuma cor, raio, largura, altura ou espaçamento literal pode existir fora de `tokens/` (`validar_tokens.py`).
- **FR-012**: As novas interfaces no catálogo e no seletor de seções MUST permanecer livres de estouro e totalmente alcançáveis na matriz `4 × 3` (`aparelhos.dart`) até 200% de escala de fonte e em tema de alto contraste.

### Threat Model, Privacidade e Engenharia Social *(Constituição Princípios I e II)*

- **Ativo protegido**: histórico local de quais aplicativos e serviços a pessoa concluiu ou ainda tem dificuldade, além da lista do que acabou de aprender (`progresso_de_aprendizado.json`).
- **Ameaça 1 — Vazamento em aparelho compartilhado**: após sair da conta ou expirar sessão por inatividade, outra pessoa abrir o perfil, seletor ou catálogo e inferir quais serviços a pessoa usa/desconhece.
  - *Mitigação*: armazenamento continua 100% local indexado por `idDaConta`, implementado como `DadoLocalDaPessoa` apagado em toda saída pela `LimpezaDeSessao`, e agora `alteracoes` limpa UI viva quando `apagar()` executa.
- **Ameaça 2 — Exfiltração / telemetria não autorizada**: envio desse histórico ao servidor ou serviço de terceiros.
  - *Mitigação*: `ProgressoDeAprendizado` não recebe cliente HTTP nem repositório remoto (`FR-042a`); provado por teste com `HttpOverrides` bloqueando criação de `HttpClient`.
- **Ameaça 3 — Engenharia social / confusão entre selo e botão ("Como um golpista exploraria esta tela?")**: transformar o selo `"Concluído"`, o checkbox verde ou o campo `"Último módulo concluído"` em controle ambíguo ou falso botão interativo para induzir toques enganosos.
  - *Mitigação*: `"Concluído"` usa `BadgeDeStatus` (`button: false, readOnly: true`), o checkbox fica em `ExcludeSemantics` acompanhado de texto explícito no próprio cartão tocável da seção, e `"Último módulo concluído"` usa `CampoInformacao` (`button: false, hasTapAction: false`), nunca `InkWell` nem chevron. Linguagem literal sem jargão nem promessa falsa.

### Key Entities *(include if feature involves data)*

- **RegistroDeProgressoPorChave**: entrada local `{vezes: int, ordem: int}` associada a uma `chave` (`<guia>` ou `<guia>:<secao>`) dentro da conta `idDaConta`.
- **EstadoDeConclusaoDoModulo**: avaliação booleana derivada de `Guia` + mapa `concluidos` indicando se o módulo está integralmente concluído, usada tanto para o selo `"Concluído"` quanto para eleger o último módulo concluído.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% dos testes novos e existentes de `progresso_de_aprendizado_test.dart`, `tela_seletor_de_secao_test.dart`, `catalogo_modulo_concluido_test.dart`, `catalogo_acessibilidade_test.dart`, `catalogo_leva_a_conversa_test.dart` e `tela_perfil_test.dart` passam com 0 falhas.
- **SC-002**: `py specs/002-design-system/ferramentas/validar_tokens.py` acusa 0 literais proibidos em `app/lib/`.
- **SC-003**: `flutter analyze` finaliza com `No issues found!`, e toda a suíte `flutter test` (incluindo portões de texto, ícones e planos) passa integralmente.
- **SC-004**: Contraste medido entre o fundo `cores.sucesso` e o ícone de check no checkbox verde arredondado excede `4.5:1` nos três temas (`claro` 6,6:1, `escuro` 10,7:1, `altoContraste` 13,1:1), combinado com texto explícito.

## Clarifications

### Session 2026-11-20

*Nota: Conforme diretriz deste Goal (`/speckit-clarify` autônomo), todas as ambiguidades foram resolvidas adotando a opção recomendada alinhada à especificação do usuário e à Constituição.*

- **Q1: Quando um guia seccionado deve aparecer como "Concluído" na lista de módulos e contar como "Último módulo concluído" no Perfil?**
  - **Opção adotada (Recomendada)**: Somente quando **todas** as seções do guia tiverem sido concluídas pelo menos uma vez (para guias sem seções, basta concluir o guia inteiro). Se o usuário refizer uma seção de um módulo anteriormente já completo, a conclusão mais recente desse módulo passa a usar a maior `ordem` entre suas seções.
- **Q2: Como deve ser exibido o checkbox verde arredondado no seletor de seções sem violar acessibilidade (`memora-ux`)?**
  - **Opção adotada (Recomendada)**: Renderizar o checkbox verde arredondado usando apenas tokens (`cores.sucesso`, `MemoraDimensoes.iconeDestaque`, borda `MemoraRaio.balaoPonta`, ícone `Icons.check_rounded` em `cores.superficie` no claro / `cores.fundo` no escuro/alto contraste) na posição `direita` do `LinhaDeLista` (à esquerda do chevron), envolvido em `ExcludeSemantics`, mantendo no cartão o texto `'Já aprendeu'` e incluindo `'Concluído.'` em `rotuloDoLeitor`.
- **Q3: Como integrar "Último módulo concluído" em `TelaPerfil` preservando testes existentes e compatibilidade com a branch de `@Du3101` (`016`)?**
  - **Opção adotada (Recomendada)**: Manter intacto `TelaPerfil.chaveMaisAprendido` (`O que você mais aprendeu`) exigido por US8/FR-042 e adicionar imediatamente abaixo dele, dentro de `ListaInformacao`, o campo `TelaPerfil.chaveUltimoAprendido` (`Key('perfil.ultimo_aprendido')`, rótulo `'Último módulo concluído'`, vazio `'Ainda vamos concluir o primeiro!'`), alimentado 100% pelo mesmo `ProgressoDeAprendizado` local com atualização reativa via stream `alteracoes`.
