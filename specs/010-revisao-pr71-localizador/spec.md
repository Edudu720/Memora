# Feature Specification: 010 — Correções da Revisão da PR #71 (Privacidade, Voz Local e Localizador Real)

**Feature Branch**: `feature/009-localizador-servicos`  
**Created**: 2026-11-15  
**Status**: Implementado — pronto para revisão final na PR #71  
**Input**: User description: "Resolver os apontamentos da revisão da PR #71 na branch feature/009-localizador-servicos: 1. Privacidade e expurgo de PII em texto e histórico Git; 2. Ditado por voz estritamente local (onDevice: true); 3. Localizador de Serviços conectado ao backend real e segurança no modo simulado; 4. Transparência OpenStreetMap, nomenclatura do interpretador e higiene de CI/Specs."

---

## Contexto e Motivação

Durante a revisão técnica e de segurança da **PR #71**, foram identificados apontamentos bloqueantes e melhorias estruturais que impedem a integração direta na branch `develop` no estado atual:

1. **Vazamento de CPF real em arquivos de texto e histórico de commits**: oito arquivos de especificação e scripts auxiliares da entrega de guias sociais mencionam em texto claro o CPF real usado nas capturas originais e nomes completos nos comentários; além disso, existe uma pasta de referências visuais externas na raiz do repositório contendo material de terceiros não licenciável para redistribuição. Como o histórico da branch preserva esses dados em commits anteriores, a correção exige higienização tanto nos arquivos atuais quanto reescrita limpa do histórico antes de atualizar o Pull Request.
2. **Privacidade do ditado por voz no assistente**: o ditado por voz atual aceita processamento em nuvem quando solicitado no aparelho, contrariando a decisão de privacidade do projeto de processar comandos de voz exclusivamente no dispositivo, sem transmitir áudio falado por pessoas idosas a servidores externos.
3. **Veracidade e segurança do Localizador de Serviços**: a navegação principal ainda conecta o Localizador exclusivamente a dados simulados locais, exibindo estabelecimentos fictícios de uma única cidade com números de telefone inventados (passíveis de pertencerem a terceiros reais) e acionamento real do discador do aparelho — inclusive na categoria de emergência. Além disso, falhas na busca remota caem silenciosamente nesses mesmos dados fictícios em vez de comunicar indisponibilidade com transparência.
4. **Transparência com fontes públicas de mapa, nomenclatura honesta e higiene de pipeline/especificações**: o diálogo de localização afirma que nenhuma coordenada é compartilhada externamente, omitindo que a busca consulta mapas públicos do OpenStreetMap; a integração de geocodificação precisa identificar adequadamente o projeto e respeitar limites de taxa de uso; um componente de classificação de intenção por palavras-chave carrega o nome de um modelo de IA inexistente no fluxo; e documentos de especificação e configuração de integração contínua divergem do padrão estabelecido em `develop`.

### Alinhamento com a Constituição do Memora

- **Princípio I (Segurança Acima de Tudo)**: expurga integralmente CPF real em arquivos e histórico de versão, assegura processamento estritamente local da voz e impede qualquer reutilização de dados fictícios como se fossem reais.
- **Princípio II (Segurança Contra Engenharia Social e Princípio da Verdade)**: proíbe números telefônicos inventados discáveis em exemplos, identifica claramente dados ilustrativos quando fora do servidor real e informa explicitamente quando uma consulta envia localização aproximada para o serviço público de mapas.
- **Princípio III (Acessibilidade como Requisito)**: mantém retorno textual acolhedor e sem jargões quando o reconhecimento de voz offline não estiver disponível no aparelho ou quando a consulta de serviços estiver indisponível.
- **Princípio IV (Especificação Antes de Código e Documentação Viva)**: reconcilia os status das especificações envolvidas e mantém o pipeline de verificação contínua alinhado à versão oficial da plataforma no projeto.

---

## Clarifications

### Session 2026-11-15

- Q: Quando o aplicativo estiver conectado ao servidor real e a busca de serviços próximos (backend ou OpenStreetMap/Nominatim) falhar ou ficar indisponível, como o Localizador deve se comportar diante da pessoa usuária? (FR-007) → A: Nunca exibir estabelecimentos inventados nem coordenadas padrão de outra cidade quando conectado ao servidor real; exibir estado honesto de indisponibilidade/sem conexão com botão *"Tentar novamente"* e busca manual, removendo os fallbacks silenciosos para dados simulados tanto no aplicativo quanto no servidor.
- Q: O que o aplicativo deve fazer quando a pessoa tocar no microfone do bate-papo em um celular que não possui reconhecimento de voz offline em português instalado ou disponível? (FR-004, FR-005) → A: Manter o botão de microfone disponível com explicação prévia; se o aparelho recusar ou falhar com `onDevice: true`, abortar imediatamente sem fallback na nuvem e exibir aviso acolhedor na interface orientando a usar o teclado ou baixar o pacote de voz português offline nas configurações do celular.
- Q: Como você prefere reescrever o histórico Git da branch `feature/009-localizador-servicos` para apagar o CPF real dos commits antigos e resolver os conflitos com `develop` antes de atualizar a PR #71? (FR-003) → A: Consolidar todas as alterações limpas (já sem CPF, sem `Memora-Desing-Ideias/`, com correções de voz/Localizador e Spec 010) em um único commit limpo (`squash`) diretamente sobre a `origin/develop` atual e atualizar a PR #71 com `--force-with-lease`.

---

## Threat Modeling (Princípio I)

| Ativo / Fluxo | Ameaça Potencial | Impacto | Mitigação Obrigatória |
|---|---|---|---|
| **CPF e dados pessoais nos scripts e especificações** | Exposição permanente de CPF real no histórico público do repositório ao realizar o merge para `develop`. | Violação severa da LGPD e exposição de dados reais de membro da equipe no histórico do projeto. | Substituir todas as ocorrências por marcadores genéricos (`XXX.XXX.XXX-XX`), manter apenas coordenadas numéricas de borrão nos scripts e reescrever o histórico da branch para erradicar os dados dos commits anteriores. |
| **Captura de áudio pelo microfone no ditado** | Envio silencioso de áudio da pessoa idosa (que pode conter senhas, dados bancários ou relatos familiares) para reconhecimento em nuvem de terceiros. | Vazamento de fala sensível fora do aparelho sem consentimento coberto pela política local. | Exigir reconhecimento estritamente offline no aparelho (`onDevice`), bloqueando qualquer fallback automático para nuvem e oferecendo alternativa clara de digitação quando o idioma offline faltar. |
| **Números telefônicos no Localizador simulado / contingência** | Pessoa idosa toca em "Ligar" em um estabelecimento de exemplo e o aparelho abre o discador com um número inventado que pode pertencer a um cidadão real ou serviço errado, inclusive em emergência. | Ligação indesejada para desconhecido ou atraso crítico em situação de socorro real. | Remover todos os números telefônicos discáveis dos dados de demonstração (`telefone` ausente), sinalizar visualmente o modo exemplo e conectar o aplicativo real ao serviço de busca verdadeiro sem fallback silencioso para dados fictícios. |
| **Material visual externo em `Memora-Desing-Ideias/`** | Redistribuição indevida de ativos licenciados de terceiros no repositório público. | Risco jurídico/licença e poluição do histórico Git com binários pesados de referência. | Remover a pasta do rastreamento e incluí-la na lista de exclusão do controle de versão. |

---

## Proteção contra Engenharia Social e Transparência (Princípio II)

1. **Permissão de Localização e Uso de Mapa Público**:
   - *Risco de engano*: prometer que "nada sai do celular" enquanto o servidor consulta um provedor externo de mapas cria falsa percepção de isolamento completo.
   - *Mitigação*: explicar com clareza no aviso prévio que apenas a localização necessária da busca (sem nome, e-mail ou vínculo da conta) é usada para consultar estabelecimentos públicos no OpenStreetMap e nunca é salva em histórico.
2. **Distinção Clara entre Serviços Reais e Demonstração Offline**:
   - *Risco de engano*: apresentar dados fixos de demonstração como resultados reais da vizinhança da pessoa.
   - *Mitigação*: quando conectado ao servidor real, o aplicativo consulta apenas estabelecimentos reais retornados pelo serviço e exibe indisponibilidade honesta se houver falha; no modo exclusivamente demonstrativo offline, a tela informa que os cartões são apenas exemplos e desabilita ligações telefônicas.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Garantir Ausência Total de CPF Real e Materiais Não Licenciados no Repositório e no Histórico (Priority: P1)

Como integrante responsável pela privacidade e governança do projeto, quero que nenhum CPF real ou dado pessoal identificável das capturas permaneça em arquivos de texto ou em commits antigos da branch da PR #71, e que referências visuais não licenciadas fiquem fora do controle de versão, para que a integração na `develop` respeite integralmente a LGPD e as licenças do projeto.

**Why this priority**: Dados pessoais reais em histórico Git propagam-se permanentemente ao fazer o merge e representam bloqueio absoluto de segurança e conformidade.

**Independent Test**: Varrer toda a árvore de trabalho atual e todo o histórico de commits da branch procurando pelo padrão do CPF real, por menções pessoais em comentários de borrão e pela pasta de referências de design externa, comprovando zero ocorrências em todos os arquivos e commits da branch.

**Acceptance Scenarios**:

1. **Given** os scripts de processamento de capturas e os documentos das especificações de guias sociais, **When** inspecionados em texto completo, **Then** não exibem nenhum CPF real nem nome pessoal usado nas capturas, utilizando apenas marcadores genéricos (como `XXX.XXX.XXX-XX`) e coordenadas de recorte/desfoque.
2. **Given** a pasta de referências externas de design na raiz do repositório, **When** verificada no índice de versão, **Then** ela não está versionada em nenhum arquivo ativo e permanece listada nas regras de exclusão local do repositório.
3. **Given** o histórico de commits desta feature em relação à base de integração, **When** auditado o conteúdo histórico dos commits da branch antes da atualização remota, **Then** o CPF real removido não aparece em nenhum diff histórico da branch pronta para merge.

---

### User Story 2 - Ditar Perguntas com Voz Processada Apenas no Aparelho (Priority: P1)

Dona Maria, 71 anos, toca no microfone do bate-papo para ditar sua dúvida em português. Seu áudio é transcrito exclusivamente dentro do próprio celular, sem ser enviado para servidores externos na internet. Caso o aparelho dela não tenha o pacote de voz offline em português instalado ou disponível, o aplicativo explica de maneira gentil e simples o que fazer — permitindo que ela digite normalmente — em vez de enviar sua voz pela rede em segundo plano.

**Why this priority**: Protege áudios espontâneos de pessoas idosas (que frequentemente citam nomes, sintomas ou senhas em voz alta) contra vazamento não autorizado em nuvem.

**Independent Test**: Acionar o mecanismo de ditado em condição simulada ou real com suporte offline disponível e com ausência/falha de suporte offline, verificando que o reconhecimento em nuvem nunca é acionado como alternativa e que o usuário recebe mensagem clara de orientação no caso de indisponibilidade local.

**Acceptance Scenarios**:

1. **Given** um aparelho com pacote de reconhecimento de voz offline em português disponível, **When** a pessoa inicia o ditado por voz no assistente, **Then** a captura solicita estritamente reconhecimento local no dispositivo (`onDevice`) e preenche o campo de texto apenas com palavras reconhecidas localmente.
2. **Given** um aparelho sem pacote de reconhecimento offline instalado ou que recuse o modo estritamente local, **When** a pessoa tenta iniciar o ditado, **Then** o sistema bloqueia qualquer alternância silenciosa para reconhecimento em nuvem e exibe feedback claro orientando o uso do teclado ou a ativação do pacote de idioma offline nas configurações do celular.
3. **Given** a conversa em execução, **When** a pessoa digita no campo ou utiliza o microfone apenas no aparelho, **Then** nenhum áudio gravado é salvo em disco ou enviado para provedores externos de transcrição.

---

### User Story 3 - Consultar Serviços Reais no Localizador e Tornar Seguro o Modo Demonstração (Priority: P1)

Quando o Memora está conectado ao servidor real, Seu Antônio, 74 anos, abre o Localizador de Serviços, escolhe uma categoria ou pesquisa sua cidade/bairro e visualiza exclusivamente estabelecimentos reais obtidos da rede pública de mapas. Se o serviço externo ou a conexão falhar, o aplicativo avisa com honestidade para ele tentar novamente, sem inventar endereços ou telefones falsos. Em demonstrações exclusivamente offline (sem servidor real), os exemplos são identificados claramente como ilustrativos e não permitem disparar ligações telefônicas para números inventados.

**Why this priority**: Números de telefone fictícios colocam em risco cidadãos comuns que receberiam ligações inesperadas e podem comprometer pedidos de ajuda em situações de emergência.

**Independent Test**: Executar o Localizador no modo conectado a servidor real (com transporte simulado/stub respondendo a API de busca e com falha simulada de rede) e no modo offline de demonstração, verificando que o modo real consulta a API verdadeira sem exibir estabelecimentos fictícios em falhas e que o modo demonstração exibe aviso explícito e nenhum número discável.

**Acceptance Scenarios**:

1. **Given** o aplicativo configurado para operar com o servidor real, **When** a pessoa abre o Localizador de Serviços e realiza uma busca por categoria, texto ou região, **Then** a consulta é enviada ao serviço real de busca do backend usando a sessão autenticada, exibindo exclusivamente estabelecimentos reais retornados por ele.
2. **Given** o aplicativo conectado ao servidor real cujo serviço de busca externa falha, expira ou retorna indisponível, **When** o resultado é processado pelo servidor ou pelo aplicativo, **Then** nenhuma lista inventada de estabelecimentos é exibida como se fosse real; o usuário vê uma mensagem clara de indisponibilidade com opção de tentar novamente ou ajustar a região.
3. **Given** o aplicativo em modo de demonstração offline (sem servidor real ativo), **When** o usuário visualiza os estabelecimentos ilustrativos do Localizador, **Then** a tela exibe um aviso visível informando que se tratam de exemplos ilustrativos e nenhum item apresenta telefone discável (sem opção de ligação ativa).

---

### User Story 4 - Transparência no Uso do OpenStreetMap, Nomenclatura Honesta e Alinhamento de Especificações e CI (Priority: P2)

Antes de aceitar compartilhar a localização atual no Localizador, Dona Maria lê claramente no diálogo que apenas a localização necessária da busca será consultada no mapa público OpenStreetMap, sem registrar dados pessoais ou histórico. Ao mesmo tempo, o servidor aplica boas práticas de consulta pública de geocodificação, nomeia honestamente seu classificador por palavras-chave e mantém o fluxo de verificação automática alinhado com a versão de trabalho da equipe.

**Why this priority**: Garante coerência entre discurso de privacidade, comportamento técnico real, conformidade com termos de uso do provedor de mapas e aprovação automática do pipeline de testes da PR.

**Independent Test**: Inspecionar o diálogo de permissão de localização quanto à transparência do uso do OpenStreetMap, verificar os testes de limite de taxa e cabeçalho na geocodificação e validar o status das especificações e a passagem completa das verificações de qualidade estática e automatizada.

**Acceptance Scenarios**:

1. **Given** o diálogo prévio de autorização de localização no Localizador, **When** exibido à pessoa usuária, **Then** explica de forma clara e acessível que a localização aproximada será usada apenas durante a busca na base pública do OpenStreetMap, sem enviar identificação pessoal nem salvar histórico de onde ela esteve.
2. **Given** solicitações sequenciais de geocodificação manual no servidor, **When** encaminhadas ao serviço público de mapas (Nominatim/Overpass), **Then** incluem identificador legítimo do projeto (`User-Agent` específico do Memora) e garantem espaçamento mínimo de 1 segundo entre consultas ao Nominatim para respeitar sua política de uso.
3. **Given** o classificador local de intenção de busca no servidor, **When** auditado no código e nos testes, **Then** utiliza nomenclatura fiel ao algoritmo determinístico por palavras-chave (sem referência enganosa a modelos de IA generativa).
4. **Given** as especificações das entregas recentes e o arquivo de integração contínua do repositório, **When** validados para o merge da PR #71, **Then** as especificações atualizam seu cabeçalho de status conforme o ciclo de aprovação e o pipeline mantém a versão padronizada da plataforma da `develop` sem flexibilizar alertas de análise estática.

---

### Edge Cases

- **Tentativa de buscar região manual sem correspondência ou com serviço externo offline**: em vez de substituir silenciosamente por coordenadas padrão de outra cidade (ex.: Americana/SP), a consulta manual deve sinalizar falha de localização da região para que o aplicativo informe que não foi possível localizar o endereço digitado e peça nova tentativa ou ajuste do nome do bairro/cidade.
- **Dispositivo Android sem mecanismo offline de reconhecimento de fala em português**: o serviço nativo deve reportar estado de indisponibilidade local sem erro não tratado, permitindo ao bate-papo comunicar que o ditado offline não está disponível no aparelho e manter o campo de texto totalmente utilizável.
- **Falha no carregamento inicial ou subsequente do Localizador com servidor real**: enquanto o diálogo inicial de permissão estiver aguardando decisão (`precisaExplicarPermissao == true`), o controlador não deve disparar busca remota prematura nem centrar o mapa em Americana - SP por padrão; além disso, se uma nova busca falhar após resultados anteriores válidos, o controlador deve limpar os cartões anteriores, ocultar a mensagem de lista vazia e exibir somente o aviso de indisponibilidade com pesquisa manual ou *"Tentar novamente"*.
- **Reescrita de histórico em branch já enviada para Pull Request**: os dados já removidos no estado atual dos arquivos precisam estar ausentes também na árvore de cada commit da branch reformulada antes da atualização da PR remota.

---

## Requirements *(mandatory)*

### Functional Requirements

#### Privacidade e Higiene do Repositório (Bloqueador 1 & Item 9)

- **FR-001**: O sistema e seus artefatos de documentação e automação NÃO PODEM conter CPF real ou dados pessoais identificáveis das capturas originais em comentários de código, scripts ou documentos de especificação (`scripts/censurar_servicos_sociais.py`, `scripts/processar_guias_visuais.py` e todos os documentos de `specs/006-guias-servicos-sociais/`), devendo substituí-los por marcadores genéricos (`XXX.XXX.XXX-XX`, `"Usuário Exemplo"`, etc.) preservando as coordenadas de desfoque.
- **FR-002**: A pasta de referências visuais externas (`Memora-Desing-Ideias/`) MUST ser removida do rastreamento do repositório e adicionada às regras de exclusão local (`.gitignore`).
- **FR-003**: O histórico da branch de entrega (`feature/009-localizador-servicos`) MUST ser consolidado em um único commit limpo (`squash`) diretamente sobre a `origin/develop` atual antes da atualização da PR #71 via `--force-with-lease`, erradicando integralmente o CPF real e os ativos de `Memora-Desing-Ideias/` de todo o histórico da branch e eliminando conflitos com as PRs #68 e #70.

#### Ditado por Voz Local (Bloqueador 2)

- **FR-004**: O serviço nativo de transcrição de voz MUST configurar explicitamente o processamento exclusivamente local no aparelho (`onDevice: true`), proibindo que o áudio da pessoa usuária seja enviado a serviços externos ou de nuvem como alternativa automática em qualquer erro ou falha de inicialização.
- **FR-005**: O botão de microfone permanece acessível com a explicação prévia habitual; quando o dispositivo não possuir pacote de idioma offline em português ou recusar o reconhecimento local (`onDevice: true`), o fluxo de conversa MUST interromper a escuta imediatamente sem fallback externo e exibir mensagem acolhedora e clara orientando a pessoa a digitar pelo teclado ou ativar o pacote de voz offline nas configurações do aparelho.

#### Localizador de Serviços Conectado ao Servidor e Modo Demonstração Seguro (Bloqueador 3)

- **FR-006**: Quando o aplicativo operar com servidor real ativado (`usaServidorReal == true`), a composição de dependências e o fluxo de entrada MUST fornecer ao Localizador de Serviços o repositório conectado ao servidor real autenticado, consultando o endpoint oficial de busca de serviços (`/v1/servicos/buscar`, com compatibilidade para `/api/v1/servicos/buscar` conforme a normalização da URL base `/v1`).
- **FR-007**: Tanto o cliente remoto do aplicativo quanto o provedor geográfico no servidor MUST operar sem fallback silencioso para estabelecimentos inventados ou coordenadas padrão fixas de uma cidade específica (inclusive removendo coordenadas fixas de Americana - SP do centro padrão inicial do mapa); diante de falha de conexão, timeout ou indisponibilidade do Nominatim/Overpass, o aplicativo MUST limpar resultados anteriores da sessão de erro, suprimir a mensagem de lista vazia e exibir um estado claro e acolhedor de indisponibilidade com opção de *"Tentar novamente"* ou ajuste manual da região, sem disparar busca remota antes de a pessoa responder ao diálogo inicial de permissão.
- **FR-008**: Quando o Localizador operar em modo de demonstração simulada offline (quando o servidor real não estiver ativo ou em pré-visualizações de teste), todos os estabelecimentos ilustrativos MUST ter o campo de telefone nulo/indisponível (`telefone: null`) para impedir abertura do discador para números inventados — inclusive em emergência — e a tela do Localizador MUST exibir um aviso visível indicando que os resultados mostrados são exemplos ilustrativos.

#### Transparência OpenStreetMap, Nomenclatura Honesta e Alinhamento de Specs/CI (Itens 4, 5, 7 e 8)

- **FR-009**: Tanto o diálogo educativo prévio de permissão de localização quanto o modal de pesquisa manual por cidade/bairro no Localizador MUST informar explicitamente em linguagem simples que a localização ou região pesquisada é usada momentaneamente para consultar a base pública OpenStreetMap, sem enviar dados da conta pessoal e sem gravar histórico de deslocamento.
- **FR-010**: O cliente de acesso ao OpenStreetMap (Nominatim e Overpass) no servidor MUST utilizar um cabeçalho `User-Agent` identificável do projeto Memora (incluindo identificação do projeto/versão e endereço público do repositório) e MUST impor controle de frequência sincronizado no processo enfileirando chamadas concorrentes com intervalo mínimo garantido de `1000 ms` (máximo de 1 requisição por segundo) para o serviço Nominatim.
- **FR-011**: A classe `InterpretadorDeIntencaoComGemini` no servidor (e suas referências em testes e injeção de dependências) MUST ser renomeada para `InterpretadorDeIntencaoPorPalavrasChave`, refletindo exatamente sua implementação determinística por palavras-chave.
- **FR-012**: Os documentos de especificação envolvidos (`specs/006-guias-servicos-sociais/spec.md`, `specs/007-redesenho-visual-profissional/spec.md` e `specs/009-localizador-servicos/spec.md`) MUST ter seus metadados de status atualizados e coerentes com o estado de revisão/implementação (`Implementado — mesclado em develop` para `006`/`007` e `Em Revisão — PR #71` para `009`), incluindo em `specs/009-localizador-servicos/spec.md` nota explícita de reconciliação registrando que `FR-011` substituiu o classificador por palavras-chave locais sem chamadas ao Gemini.
- **FR-013**: A definição de pipeline de verificação contínua (`.github/workflows/verificacao.yml`) MUST manter a versão do SDK fixada conforme o padrão vigente em `develop` (`3.47.7`) e executar a análise estática estrita sem supressão de avisos informativos (`--no-fatal-infos`).

### Escopo e Assunções Documentadas

- **Itens fora desta entrega (mantidos para etapa/PR separada)**: conforme indicado pelo revisor da PR #71 (*"Depois dos três primeiros pontos, eu aprovo. Os outros podem ir em PR própria"*), a eventual conversão em lote das 76 capturas anotadas de `JPG` com marcadores embutidos para `WebP` com destaque dinâmico sobreposto (`CapturaComDestaque`, Item 6 da revisão) e a revisão presencial de telas no aparelho (`T116`) serão tratadas em etapa própria sem atrasar o desbloqueio da PR #71, exceto quando houver conflito técnico direto resolvido em acordo com a `develop`.
- **Assunção sobre infraestrutura de verificação**: todas as suítes automatizadas de análise estática, testes unitários/de widget no aplicativo e testes no servidor devem passar integralmente no pipeline da PR após o ajuste.
- **Assunção sobre disponibilidade do OpenStreetMap**: o servidor respeita o limite de 1 req/s por processo com fila sincronizada para geocodificação manual no Nominatim e aplica timeouts explícitos (`5s` de conexão HTTP e chamada Nominatim; `6s` na chamada HTTP Overpass com `[timeout:5]` na query) para evitar bloqueio prolongado da pessoa idosa em caso de lentidão de rede externa.
- **Documentação Viva**: nesta PR #71 são atualizadas as especificações `006`, `007`, `009` e `010` (status final atualizado na conclusão da implementação); `CHANGELOG.md` e `ROADMAP.md` permanecem para fechamento de release após o merge em `develop`.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: **Zero exposições residuais de dados pessoais**: auditoria automatizada na árvore final e em todos os commits reescritos da branch retorna 0 ocorrências do CPF real e 0 arquivos rastreados na pasta externa de referências de design.
- **SC-002**: **100% de processamento local no ditado por voz**: testes automatizados comprovam que toda chamada ao motor de reconhecimento vocal exige processamento local no dispositivo (`onDevice` ativado) e que indisponibilidade offline resulta em aviso claro ao usuário em 100% dos casos testados, sem envio de áudio à nuvem.
- **SC-003**: **Separação rigorosa entre dados reais e exemplos seguros**: 100% das buscas realizadas com servidor real ativo acionam o endpoint oficial de busca de serviços e devolvem erro/indisponibilidade honesta quando offline; 100% dos itens em modo de demonstração offline não possuem número telefônico discável e exibem indicação explícita de modo de exemplo.
- **SC-004**: **Conformidade explícita de uso e transparência do mapa público**: tanto o diálogo prévio de localização quanto o modal de busca manual exibem explicitamente o uso da base pública OpenStreetMap, os testes do servidor comprovam o espaçamento mínimo de 1 segundo entre requisições consecutivas de geocodificação com identificação adequada do projeto e nenhuma referência a classificador de intenção alega erroneamente uso de modelo generativo externo.
- **SC-005**: **Pipeline de qualidade 100% aprovado**: análise estática rigorosa (zero erros e zero avisos), suíte completa de testes do aplicativo, validadores do sistema de design e suíte de testes do servidor (incluindo os novos testes de transparência, ditado local e conexão real do Localizador) executam com 100% de aprovação na branch pronta para revisão final.
