# Especificação da Feature: Redesenho Visual e Padronização Profissional do Memora

**Branch da Feature**: `feature/007-redesenho-visual-profissional`  
**Criada em**: 2026-11-13  
**Status**: Implementado — mesclado em develop  
**Entrada**: Solicitação do usuário (`/speckit-plan`): cruzar todas as 6 imagens da pasta `Memora-Desing-Ideias` e refazer todo o design e padronização do aplicativo, eliminando a aparência amadora e elevando a qualidade visual sem perder a acessibilidade sênior, a segurança antigolpe nem a compatibilidade com o Design System existente.

---

## 1. Diagnóstico Visual Atual e Cruzamento das Referências (`Memora-Desing-Ideias/`)

### 1.1 Por que o aplicativo atual parece amador
Auditoria direta no Design System (`app/lib/design_system/`) e nas telas das features `001`–`006`:
1. **Excesso de bordas de wireframe (`0xFF6B6B6B`) em cartões informativos**: `Cartao`, `CaixaDeEtapa` e widgets de `Cuidado` (`MedidorBpm`, etc.) desenham contornos sólidos escuros ao redor de praticamente todo bloco branco, criando poluição visual de protótipo de baixa fidelidade em vez de hierarquia por fundo, elevação e espaçamento.
2. **Barra de navegação inferior pesada e opaca (`0xFFD8D8D8`)**: `NavegacaoInferior` pinta toda a barra com `superficieAlt` (`0xFFD8D8D8`), deixando o rodapé cinza e datado em contraste com o restante da tela.
3. **Uso excessivo de `CaixaDeEtapa` e pílulas monolíticas em cadeia**: telas como `TelaInicio`, `TelaAjuda`, `TelaConfiguracoes` e formulários repetem caixas cinza-e-borda empilhadas com baixa variação de ritmo visual, pouco respiro e densidade monótona.
4. **Linguagem de ilustrações fragmentada**: `app/assets/ilustracoes/` já possui 6 ilustrações 3D/vetorizadas consistentes do robô Memora (`memora_perfil_robo.png`, `memora_ajuda_robo.png`, `memora_conclusao_robo.png`, `memora_alerta_robo.png`, `memora_dica_robo.png`, `memora_mini_robo.png`), porém `ExpressaoDaMemora` não mapeia `dica` nem `mini`, e várias telas (`TelaBoasVindas`, `TelaHub`, `TelaAjuda`, `TelaConfiguracoes`, `CartaoDePorta`) ainda misturam SVGs antigos planos (`casal_idoso.svg`, `porta_*.svg`, `memora_neutra.svg`).
5. **Despadronização entre módulos**: `Cuidado` (`tela_dispositivo_cuidado.dart`, `medidor_bpm.dart`), `Catálogo` (`tela_catalogo.dart`), `Conversa` (`tela_conversa.dart`) e `Apresentação/Auth` não compartilham uma grade visual unificada de cards heróis, atalhos em 2 colunas, chips de status e cabeçalhos editoriais.

### 1.2 Matriz de Cruzamento das 6 Imagens de `Memora-Desing-Ideias/`

| Arquivo em `Memora-Desing-Ideias/` | O que a referência demonstra | Onde e como será aplicada no Memora (mantendo WCAG 2.2 AA & Constituição) |
| :--- | :--- | :--- |
| `Gemini_Generated_Image_fkhvixfkhvixfkhv.jfif` | Mockups conceituais nativos do Memora: saudação `"Oi, edu!"`, Card Herói azul `"Conversar com a Memora"`, balão de fala da Memora com mini-robô, faixa colapsável `"Eu nunca peço sua senha nem código"`, barra inferior branca limpa com pill ativo e indicador superior, chat com botão `"Perguntar"`, lista `"Meus aplicativos"` com selo `"✓ Eu te ensino e posso abrir"`. | **Estrutura principal do Início, Conversa, Catálogo de Apps e Navegação Inferior.** Define a espinha dorsal visual da marca Memora. |
| `Gemini_Generated_Image_ou3ujaou3ujaou3u.jfif` | Folha de expressões padronizada do robô azul amigável: acenando (Perfil/Boas-vindas), pensativo/falando (Ajuda/Conversa), lendo livro (Dica/Aprendizado), comemorando (Conclusão/Sucesso), com escudo metálico (Alerta/Segurança) e cabeça reduzida (Versão Mini para cabeçalhos e balões). | **Unificação completa de `MemoraPersonagem` e `ExpressaoDaMemora`** (incluindo `dica` e `mini`), substituindo misturas amadoras de estilos. |
| `design-1.jpg` | Interface moderna de assistente IA: card herói com gradiente suave, ações em destaque em 2 colunas + grade de categorias com badges quadrados tonais, sugestões em grid 2x2 na conversa vazia, dock inferior branco arredondado e barra de prompt com botão de envio/microfone bem definido. | **Hierarquia do Início/Hub, Grade 2x2 de Sugestões de Pergunta na Conversa e Barra de Entrada do Chat.** |
| `design-2.jpg` | Composição editorial `Leafora`: fundo canvas suave (`#F4F6FA`) separando-se naturalmente dos cartões `#FFFFFF` sem depender de contorno pesado, generoso respiro (`20–24 dp`), onboarding limpo com paginação e CTA bem ancorado no rodapé, listas horizontais organizadas. | **Tokens de Superfície/Canvas, Espaçamento Editorial, Onboarding/Boas-vindas, Configurações, Perfil e Seletor de Módulos.** |
| `7fe4db2010c74184691991ae79b7dca6.webp` | Dashboard de Saúde & Cuidado: card herói com gradiente azul-petróleo, métrica principal em algarismos tabulares grandes, indicadores secundários integrados (`bpm · movimento · estado`), grade 2x2 de ações rápidas com ícones em badges pastel de alto contraste e pills de status (`Normal`, `Hoje`). | **Redesenho completo da feature `Cuidado`** (`TelaDispositivoCuidado`, `MedidorBpm`, `IndicadorMovimento`, histórico resumido para cuidador/pessoa idosa). |
| `covid-19-tracking-application-template-mobile-screen_53876-117346.avif` | Banners em gradiente com textura ilustrativa sutil de fundo, fila de 4 atalhos rápidos horizontais/em grid, telas de alerta/orientação centradas (ilustração + título colorido de destaque + texto curto + CTA único em pílula) e abas/filtros segmentados limpos. | **Telas de Alerta/Queda, Banner de Orientação nos Guias/Serviços Sociais, Filtros Segmentados do Catálogo/Registro e Estados de Erro/Vazio.** |

---

## Clarifications

### Session 2026-11-13

- Q: Quantas e quais abas fixas devem existir na barra de navegação inferior (`NavegacaoInferior` / `CascaInterna`) após o redesenho? (FR-004) → A: Manter as 3 abas atuais (`Ajustes`, `Início`, `Meu perfil`) na barra inferior (`CascaInterna`); `Conversa`, `Aplicativos`, `Cuidado` e `Ajuda` permanecem acessíveis a partir do `Início`.
- Q: Como os novos blocos visuais em destaque (`CartaoHeroi` e grade `2x2` de atalhos) devem separar visualmente o que é informação do que é ação, sem tornar o `Cartao` comum clicável? (FR-007) → A: `Cartao` e painéis de leitura (como o resumo/BPM em `Cuidado`) permanecem não clicáveis; cards interativos (`CartaoHeroi`, `TileAcaoRapida`, `LinhaDeLista`) exibem pista explícita de ação (pílula/botão ou seta) e semântica de botão no TalkBack.
- Q: Como a etapa obrigatória de consentimento da IA (`_ExplicacaoDoAceite`, Emenda 1 ao Princípio I) deve conviver com a nova tela inicial de Conversa (`US4`) e sua grade `2x2` de sugestões? (FR-009) → A: Preservar `_ExplicacaoDoAceite` primeiro (com visual limpo atualizado) enquanto `precisaDoAceite == true`; exibir a grade `2x2` de sugestões e a barra de mensagem somente após o aceite.
- Q: O botão de microfone/ditado por voz mostrado na referência `design-1.jpg` deve ser implementado nesta feature ou ficar fora de escopo do redesenho visual? (`US4`) → A: Incluir ditado por voz completo nesta feature (`US4`), com explicação prévia da permissão de microfone (Princípio II), preenchimento do campo de texto sem envio automático e testes dedicados.
- Q: Como deve ser validado o critério visual final do APK de release (`SC-006`) nos modos Claro, Escuro e Alto Contraste ao concluir a implementação? (`SC-006`) → A: Validação visual nos 3 temas pelas capturas atualizadas do `album_de_telas_test.dart`, 100% de aprovação na suíte automatizada e compilação limpa de `app-release.apk` (instalação em celular físico como conferência manual pelo usuário).

---

## 2. Revisão de UX e Modelo de Ameaças (Constituição — Princípios I e II)

Toda alteração estética desta feature preserva ou fortalece as barreiras contra erro sênior e engenharia social:
1. **Distinção visual inequívoca entre Informação e Ação (`002/FR-012` / `FR-007` / Princípio III)**: `Cartao`, `PainelHeroi`, `BadgeDeStatus`, `MedidorBpm` e `IndicadorMovimento` permanecem **estritamente não clicáveis** (sem API de toque), usando fundo branco ou gradiente informativo sem pistas de clique. Em contrapartida, ações usam botões em pílula (`MemoraRaio.pilula`) ou cards de ação dedicados (`CartaoHeroi` com CTA, `TileAcaoRapida`, `LinhaDeLista` com `aoTocar`) com pista visual explícita de toque (pílula/rótulo de ação ou ícone + seta) e semântica de botão no TalkBack, enquanto campos mantêm borda `>= 3:1` de contraste no estado padrão e reforçada no foco.
2. **Avisos antigolpe inegociáveis (Princípio II)**:
   - O aviso `"Eu nunca peço sua senha nem código"` na conversa continua **visível e não dispensável por deslize**. Antes da primeira mensagem (após aceitar o termo da Emenda 1) aparece completo em cartão de alerta suave com escudo do robô (`memora_alerta_robo.png`); após a primeira mensagem, recolhe para a pílula/barra compacta no topo (como mostrado no mockup `fkhvix`), mantendo o texto-chave ou rótulo semântico completo no TalkBack e abrindo o texto completo ao tocar.
   - Em `Boas-vindas`, `Login`, `Cadastro`, `Recuperação`, `Confirmação de Canal` e `Cuidado (Queda/Emergência)`, avisos críticos de segurança e privacidade permanecem explícitos e legíveis a até 200% de ampliação.
3. **Sem atalhos perigosos nem engano visual**: Banners com gradiente e cards interativos usam exclusivamente rótulos claros com ícone + texto e respeitam o tamanho mínimo de toque (`>= 48x48 dp`, botões principais `>= 56 dp`).

### 2.1 Threat Modeling por Área Redesenhada (Princípio I & II)

| Tela / Área | Dados sensíveis envolvidos | Quem acessa | Como um golpista tentaria explorar esta tela? | Impacto | Mitigação visual & técnica | Monitoramento / Log |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Início & Hub** | Nome curto da pessoa | Usuário autenticado | Falsos banners urgentes imitando suporte ou botões confusos levando a app/link fora do Memora | Alto (engenharia social) | `CartaoHeroi` só abre a conversa interna; atalhos usam texto literal + ícone sem urgência artificial | Auditoria de navegação mantém rotas internas restritas a `CascaInterna` |
| **Conversa + Ditado por Voz** | Perguntas da pessoa, áudio captado no microfone em tempo real | Usuário autenticado + provedor externo de IA (Emenda 1) + STT do SO | Convencer o idoso a aceitar em branco, falar senhas/códigos no microfone ou enviar texto mal-reconhecido por acidente | Crítico (exposição de credenciais/dados) | `_ExplicacaoDoAceite` obrigatória antes de conversar; `AvisoCompacto` não dispensável; explicação simples antes de pedir permissão de microfone; voz **nunca auto-envia** (preenche rascunho para conferência em `"Perguntar"`); zero gravação em disco | Sem log de áudio nem de transcrição em produção; bloqueio de campos secretos preservado em testes |
| **Catálogo & Guias** | Lista de apps/serviços e progresso | Usuário autenticado | Abrir aplicativo errado ou falso clone fora do Memora sem perceber saída | Médio/Alto | Selo `"✓ Eu te ensino e posso abrir"` meramente informativo; abertura de app externo continua exigindo diálogo explícito de confirmação | Sem envio de dados ao abrir pacote declarado no `AndroidManifest.xml` |
| **Cuidado & Queda** | Batimentos (BPM), status de movimento, contato de emergência | Usuário monitorado / Cuidador | Falso alarme ou toque acidental que chame emergência/dispare contato ou oculte falha de conexão | Crítico (pânico ou falta de socorro) | `PainelHeroi` não clicável; detalhes técnicos MQTT ocultos em painel recolhível sem bloquear alertas reais de desconexão; botões de `"Estou bem"` e `"Pedir ajuda agora"` grandes (`>= 56 dp`) e separados | Eventos críticos preservados pelo `ControladorDispositivoCuidado` sem expor tokens |
| **Autenticação & Configurações** | E-mail/telefone, senha, data de nascimento | Usuário | Induzir digitação em tela parecida ou exclusão/saída acidental da conta | Crítico (sequestro de conta) | `CaixaDeEtapa` mantém instrução literal acima do campo + regras explícitas de senha + saída/ações irreversíveis com diálogo em duas etapas (`ConfirmacaoMemora`) | Token guardado apenas em `flutter_secure_storage`; limpeza na saída testada |
| **Apresentação, Perfil (`SecaoIdade`), Aparência & Ajuda** | Data de nascimento, preferências visuais (`tema`/`paleta`) | Usuário autenticado | Induzir contraste ilegível ou alterar idade/dados pessoais por engano | Baixo/Médio (erro de uso ou baixa legibilidade) | Pré-visualização com contraste WCAG garantido por `validar_paleta.py` (`>= 4.5:1` / `7.0:1`), edição explícita em `TelaDataDeNascimento` sem atalho destrutivo, navegação limpa sem links externos ocultos | Nenhum dado novo persistido além de preferências locais existentes |

---

## 3. Histórias de Usuário & Cenários de Teste

### User Story 1 — Identidade Visual Profissional, Hierarquia Limpa e Tokens 2.0 (Prioridade: P1)

Como pessoa usuária ou cuidadora, quero que o aplicativo inteiro utilize uma paleta refinada, superfícies brancas limpas sobre fundo suave, sombras sutis, navegação inferior elegante e tipografia bem hierarquizada — nos modos Claro, Escuro e Alto Contraste — para que o app passe confiança e profissionalismo sem sacrificar a legibilidade.

**Por que esta prioridade**: A base do aspecto amador vem diretamente de tokens de superfície, borda e navegação. Sem corrigir o Design System primeiro, cada tela continuaria parecendo um wireframe.

**Critérios de Aceitação**:
1. **Dado** o modo Claro padrão, **Quando** qualquer cartão informativo (`Cartao`, `CartaoComAvatar`, `DestaqueInformacao`) é renderizado, **Então** ele usa fundo elevado branco (`#FFFFFF`) sobre canvas suave (`#F4F6FA`), borda sutil tonal (ou zero borda pesada no modo padrão, mantendo contorno `>= 3:1` automaticamente no modo Alto Contraste e nos controles interativos/inputs) e sombra suave em duas camadas sem aparência de caixa de wireframe.
2. **Dado** o rodapé de navegação (`NavegacaoInferior`), **Quando** exibido em qualquer um dos **3 destinos fixos** da `CascaInterna` (`Ajustes`, `Início`, `Meu perfil`), **Então** a barra usa superfície elevada limpa (`superficieBarra` branca no claro, grafite elevada no escuro, preta com borda `>= 3:1` no alto contraste), indicador visual claro do item ativo com pílula tonal + ícone e rótulo escrito juntos, nunca barra cinza chapada `#D8D8D8`.
3. **Dado** todos os 3 modos (`Claro`, `Escuro`, `Alto Contraste`) e todas as 6 paletas (`azul`, `verde`, `roxo`, `laranja-terra`, `rosa`, `grafite`), **Quando** o script `validar_paleta.py` e os testes de contraste forem executados, **Então** todos os pares texto/fundo e componente/fundo atingem WCAG 2.2 AA (`>= 4.5:1` / `>= 3.0:1`) e Alto Contraste AAA (`>= 7.0:1`).

---

### User Story 2 — Mascote Memora Unificado e Ilustrações Coesas (Prioridade: P1)

Como pessoa usuária, quero ver o mesmo mascote robô amigável da Memora em todo o aplicativo (boas-vindas, início, conversa, dicas de estudo, alertas de segurança e conclusões), em vez de desenhos misturados de estilos diferentes.

**Por que esta prioridade**: A mistura de SVGs simples com PNGs detalhados do robô quebra imediatamente a percepção de marca profissional.

**Critérios de Aceitação**:
1. **Dado** `ExpressaoDaMemora` em `MemoraPersonagem`, **Quando** uma tela solicita uma expressão (mantendo retrocompatibilidade de `neutra`, `falando`, `comemorando`, `preocupada` e acrescentando `dica` e `mini`), **Então** o componente renderiza a arte PNG oficial correspondente do robô Memora (`memora_perfil_robo.png`, `memora_ajuda_robo.png`, `memora_dica_robo.png`, `memora_conclusao_robo.png`, `memora_alerta_robo.png`, `memora_mini_robo.png`) com moldura/medalhão limpo em contraste seguro nos modos Claro, Escuro e Alto Contraste.
2. **Dado** telas que ainda exibiam SVGs antigos desconexos do robô ou ícones amadores de porta, **Quando** redesenhadas, **Então** passam a adotar o mascote unificado ou badges com ícones vetoriais limpos da família `Material Symbols / Rounded`.

---

### User Story 3 — Tela Inicial (`Início`) e `Hub` Modernos, Acolhedores e Sem Poluição (Prioridade: P1)

Como pessoa idosa recém-chegada ou recorrente, quero abrir o aplicativo e ver uma saudação acolhedora (`"Oi, [Nome]!"`), um cartão herói principal muito claro para `"Conversar com a Memora"` e uma grade organizada de atalhos rápidos (`Meus aplicativos`, `Serviços sociais`, `Cuidado`, `Ajuda`), sem rolagem desnecessária e sem caixas cinzas empilhadas.

**Por que esta prioridade**: O `Início` e o `Hub` são a vitrine do aplicativo; alinhá-los aos mockups `fkhvix`, `design-1` e `design-2` transforma a primeira impressão.

**Critérios de Aceitação**:
1. **Dado** um telefone padrão (`360×800`) com escala de texto `1.0`, **Quando** o usuário abre `TelaInicio` ou `TelaHub`, **Então** vê o cabeçalho com avatar/mini-robô e saudação personalizada, o **Card Herói primário** (`Conversar com a Memora`) com alto contraste, a **grade 2x2 de ações rápidas** com badges tonais + ícone + texto completo e o resumo de último uso/acesso, **sem overflow** e respeitando ampliação até `200%` com rolagem segura.
2. **Dado** o teste de regressão existente `hub_cabe_sem_rolar_test.dart`, **Quando** executado após o redesenho, **Então** `TelaHub` continua cabendo confortavelmente nos limites de acessibilidade sem truncar rótulos nem quebrar alvos de `>= 48 dp`.

---

### User Story 4 — Conversa com a Memora e Sugestões em Grade (Prioridade: P1)

Como pessoa usuária que quer tirar uma dúvida, quero uma tela de conversa moderna com o cabeçalho limpo da Memora, faixa de segurança compacta antigolpe, cartões de sugestão em 2x2 antes de começar e balões de conversa bem espaçados com barra inferior elegante para perguntar por texto ou voz.

**Por que esta prioridade**: A conversa é o núcleo do produto Memora e a tela mais usada pelos usuários.

**Critérios de Aceitação**:
1. **Dado** uma pessoa que ainda não aceitou o termo de uso da assistente (`precisaDoAceite == true`), **Quando** abre `TelaConversa`, **Então** vê primeiro a etapa `_ExplicacaoDoAceite` com o novo visual limpo sem bordas pesadas e o robô Memora, mantendo a opção clara de aceitar ou recusar sem bloquear o uso do restante do aplicativo.
2. **Dado** uma conversa já autorizada (`precisaDoAceite == false`) e recém-iniciada (sem mensagens enviadas), **Quando** a tela abre, **Então** exibe a recepção com o robô Memora, o aviso antigolpe visível sem cobrir toda a tela e os botões/cards de sugestão rápida organizados em layout limpo (2 colunas quando couber na largura útil, empilhado em `320 px` / `200%`).
3. **Dado** uma conversa ativa após a primeira pergunta, **Quando** novas mensagens entram, **Então** o aviso antigolpe assume forma de barra compacta no topo (expansível ao toque), os balões da Memora (esquerda, fundo branco elevado + mini-robô) e da Pessoa (direita, fundo tonal suave da paleta) têm tipografia limpa sem borda pesada de wireframe, e a barra de digitação inferior destaca claramente o campo + botão em pílula `"Perguntar"` + ação acessível de microfone (`"Falar"` / `"Parar"`, com ícone + texto e alvo `>= 48 dp`).
4. **Dado** o primeiro toque na ação de microfone, **Quando** a permissão do sistema ainda não foi concedida, **Então** o aplicativo exibe antes uma explicação simples em português explicando que o microfone serve apenas para transformar a fala em texto naquela pergunta (Princípio II); após o ditado, a transcrição preenche o campo para a pessoa revisar e enviar tocando em `"Perguntar"` (nunca envia automaticamente), e se a permissão for negada ou o serviço estiver indisponível a digitação por texto continua funcionando normalmente com feedback claro.

---

### User Story 5 — Catálogo de Apps, Serviços Sociais, Módulos e Passo a Passo Editorial (Prioridade: P2)

Como pessoa que está aprendendo a usar WhatsApp, Gov.br, Caixa Tem ou SUS, quero navegar pelos catálogos, módulos e guias ilustrados com cartões limpos, chips de filtro claros, badges de status (`"✓ Eu te ensino e posso abrir"`) e um leitor passo a passo elegante onde a imagem guiada com marcações numeradas é a protagonista.

**Por que esta prioridade**: A feature 006 acabou de corrigir todas as 76 capturas de tela; agora a moldura das telas de Catálogo, Seletor de Módulos e Passo a Passo precisa acompanhar a mesma qualidade profissional.

**Critérios de Aceitação**:
1. **Dado** `TelaCatalogo`, **Quando** lista aplicativos e serviços sociais, **Então** exibe campo de busca limpo, chips segmentados de categoria (Apps do celular / Serviços sociais) inspirados em `design-2` e `covid-19`, e cartões horizontais padronizados com ícone/logo oficial em badge suave, descrição curta, selo `"✓ Eu te ensino e posso abrir"` e botão claro de ação/abertura.
2. **Dado** `TelaSeletorDeSecao` e `TelaPassoAPasso`, **Quando** o usuário percorre um módulo e seus passos, **Então** os módulos usam numeração em badge circular limpa (sem caixas cinzas duplicadas) e o `PassoIlustrado` integra o indicador de progresso linear + pílula de etapa + cartão de imagem sem borda pesada + barra de navegação `"Anterior / Próximo"` bem ancorada.

---

### User Story 6 — Dashboard Profissional de Cuidado & Saúde IoT (Prioridade: P1)

Como pessoa monitorada ou familiar cuidador, quero ver o painel de Cuidado (BPM, detecção de movimento/queda, status da pulseira e contato de emergência) organizado como um dashboard moderno de saúde (`7fe4db` + `covid-19`), ocultando detalhes técnicos como broker/tópico MQTT atrás de área discreta, e destacando alertas críticos com extrema clareza.

**Por que esta prioridade**: A tela atual de `Cuidado` tem layout cru em caixas brancas bordadas e contrasta fortemente com o nível profissional esperado para monitoramento de saúde.

**Critérios de Aceitação**:
1. **Dado** `TelaDispositivoCuidado`, **Quando** conectada ou em monitoramento ativo, **Então** apresenta um **Painel Herói informativo em Gradiente de Saúde** (não clicável) no topo com status geral em pílula (`Conectado`, `Atenção`, `Desconectado`), BPM em destaque tabular grande (`72 BPM`), e resumo integrado de movimento/sinal; seguido de uma **grade 2x2 de ações e vitais** (`Medir / Pulso`, `Movimento`, `Contato de emergência`, `Histórico de eventos`).
2. **Dado** informações técnicas de conexão (porta, tópico MQTT), **Quando** o usuário abre o painel padrão, **Então** elas não poluem a tela principal (ficando acessíveis apenas em detalhe técnico expansível se necessário para suporte).
3. **Dado** um alerta de queda (`TelaVerificacaoQueda`), **Quando** disparado, **Então** segue o padrão de alerta de alto impacto de `covid-19` + `memora_alerta_robo.png`: foco central no contador regressivo, título direto e dois botões grandes e inconfundíveis (`"Estou bem"` e `"Pedir ajuda agora"`).

---

### User Story 7 — Boas-Vindas, Autenticação, Ajuda, Configurações e Perfil Padronizados (Prioridade: P2)

Como pessoa usando o app pela primeira vez ou ajustando conta, aparência e privacidade, quero que as telas de boas-vindas, login/cadastro/recuperação, ajuda, perfil e configurações sigam exatamente a mesma linguagem editorial limpa (`design-1` e `design-2`), sem blocos cinza-e-borda repetitivos.

**Critérios de Aceitação**:
1. **Dado** `TelaBoasVindas` e `FluxoApresentacao`, **Quando** exibidos, **Então** usam composição editorial generosa com o robô Memora em destaque, indicadores de passo limpos e botão primário ancorado no rodapé sem aperto em telas de `320×568` ou `360×800`.
2. **Dado** telas de formulário (`TelaLogin`, `TelaCadastro`, `TelaRecuperacao`, `TelaConfirmarCanal`, `TelaDeVolta`, `TelaEntregaDoAparelho`, `TelaPrimeiraEntrada`) e telas de ajuste/ajuda/perfil (`TelaConfiguracoes`, `TelaConta`, `TelaPrivacidade`, `TelaAparencia`, `TelaPerfil`, `TelaDataDeNascimento`, `SecaoIdade`, `TelaAjuda`, `TelaAssunto`, `AjudaGuiadaDaConversa`), **Quando** renderizadas, **Então** substituem caixas pesadas repetidas por cabeçalhos de seção tipográficos limpos, agrupamentos em cartões brancos sutis com divisores `1 px` quase invisíveis no modo Claro (e contraste forte no Alto Contraste) e orientação textual preservada exatamente acima de cada campo/controle para manter acessibilidade TalkBack.

---

## 4. Requisitos Funcionais (FR)

- **FR-001 (Tokens Visuais 2.0 em Lugar Único)**: Toda cor, gradiente, sombra, borda sutil, raio e espaçamento novo MUST residir exclusivamente em `app/lib/design_system/tokens/` e passar por `validar_tokens.py` sem nenhuma literal visual fora de `tokens/`.
- **FR-002 (Hierarquia de Superfícies & Eliminação de Wireframe)**: `MemoraCores` MUST diferenciar `fundo` (canvas suave `#F4F6FA` no claro), `superficie` (`#FFFFFF`), `superficieSutil` (realce/balão suave), `superficieBarra` (barra elevada limpa), `bordaSutil` (divisores/contornos leves não-interativos `#E2E8F0` no claro) e `borda` (contorno `>= 3.0:1` obrigatório em campos de entrada, estados de foco e modo Alto Contraste).
- **FR-003 (Gradientes Acessíveis com Token)**: `MemoraCores` MUST expor tokens `gradienteHeroiInicio` / `gradienteHeroiFim` e `gradienteSaudeInicio` / `gradienteSaudeFim` (com pares equivalentes para modo escuro e versão sólida de altíssimo contraste no modo Alto Contraste) garantindo contraste `>= 4.5:1` com o texto sobreposto em todas as paletas.
- **FR-004 (Navegação Inferior Elevada)**: `NavegacaoInferior` MUST manter os 3 destinos fixos da `CascaInterna` (`Ajustes`, `Início`, `Meu perfil`) e substituir o fundo cinza `#D8D8D8` por superfície limpa elevada (`superficieBarra`), separador superior sutil, indicador superior e pílula tonal no item selecionado, preservando obrigatoriamente **ícone + rótulo escrito** e alvo `>= 48x48 dp`.
- **FR-005 (Cabeçalho de Tela Modernizado)**: `CabecalhoDeTela` e `BarraSuperior` MUST adotar composição limpa com botão `"Voltar"` acessível (ícone + texto), título em tipografia `tituloSecao`/`tituloTela` e apoio opcional do `memora_mini_robo.png` sem caixas redundantes.
- **FR-006 (Mascote Unificado)**: `ExpressaoDaMemora` MUST incluir `dica` (`memora_dica_robo.png`) e `mini` (`memora_mini_robo.png`) ao lado das demais expressões PNG oficiais, eliminando a mistura visual de SVGs antigos em todas as telas principais.
- **FR-007 (Novos Componentes Reutilizáveis no DS)**: O Design System MUST incorporar componentes padronizados reutilizados pelas features mantendo a separação entre informação e ação: `Cartao`, `PainelHeroi` (para leitura de saúde) e `BadgeDeStatus` permanecem estritamente não clicáveis; `CartaoHeroi` (exige pista visual explícita de ação e semântica de botão), `TileAcaoRapida` (para grids 2x2 com pista visual de ação), `ChipFiltro`, evolução direta do `AvisoCompacto` em estilo pílula expansível e `LinhaDeLista`.
- **FR-008 (Preservação Semântica de `CaixaDeEtapa` Sem Peso de Wireframe)**: `CaixaDeEtapa` MUST manter intacta sua árvore semântica (instrução de cabeçalho lida antes do `child` no TalkBack) enquanto evolui seu visual para cartão limpo com barra/cabeçalho tonal sutil (sem faixa `#D8D8D8` nem borda `#6B6B6B` no modo Claro/Escuro padrão).
- **FR-009 (Padronização Completa das 35+ Telas)**: Todas as features (`apresentacao`, `autenticacao`, `inicio`, `hub`, `casca`, `assistente`, `aprendizado`, `cuidado`, `ajuda`, `configuracoes`, `perfil` e `galeria_memora`) MUST migrar para os componentes atualizados do Design System.
- **FR-010 (Invariantes de Acessibilidade Sênior)**: Fonte mínima `16 sp` (`AtkinsonHyperlegibleNext`), suporte total a escala até `200%` (`escalaTextoLimitada`) sem `RenderFlex overflow`, alvos mínimos `48×48 dp` (`56 dp` em botões de ação), e `Semantics` preservadas para leitores de tela.
- **FR-011 (Compatibilidade de Chaves e Contratos de Teste)**: Todas as `Key`s existentes de widgets usadas pelos fluxos automatizados e testes de segurança/acessibilidade MUST ser preservadas ou explicitamente migradas com atualização coordenada nos testes da respectiva feature.
- **FR-012 (Validação Automática de Contraste Across-Palettes)**: `specs/002-design-system/ferramentas/validar_paleta.py` e `app/test/design_system/contraste_test.dart` MUST cobrir também todos os novos tokens (gradientes, badges, superfícies de barra e divisores interativos) nas 3 temáticas × 6 paletas.
- **FR-013 (Ditado por Voz Seguro e Acessível na Conversa)**: `TelaConversa` MUST oferecer botão de ditado por voz (`>= 48 dp`, ícone + texto `"Falar"` / `"Parar"` + indicação visual e semântica de escuta ativa), explicação prévia em linguagem simples antes de pedir permissão de microfone ao sistema (Princípio II), fallback amigável quando negado/indisponível mantendo a digitação sempre livre, e preenchimento apenas do rascunho de texto (exigindo toque explícito em `"Perguntar"` para enviar, prevenindo envios acidentais).

---

## 5. Critérios de Sucesso (SC)

- **SC-001**: `python specs/002-design-system/ferramentas/validar_tokens.py` retorna código `0` (zero valores visuais literais em `app/lib` fora de `tokens/`).
- **SC-002**: `python specs/002-design-system/ferramentas/validar_paleta.py` retorna código `0` em todos os pares de contraste (Claro, Escuro, Alto Contraste e paletas derivadas).
- **SC-003**: `flutter analyze` em `app/` passa com `0` erros e `0` avisos novos nas telas e componentes redesenhados.
- **SC-004**: 100% da suíte `flutter test` em `app/` passa sem regressões, incluindo `contraste_test.dart`, `area_toque_test.dart`, `escala_texto_test.dart`, `informacao_nao_e_acao_test.dart`, `hub_cabe_sem_rolar_test.dart`, `inicio_ocupa_a_altura_test.dart`, `sem_campo_de_segredo_test.dart`, `album_de_telas_test.dart` e `galeria_completa_test.dart`.
- **SC-005**: Todas as telas capturadas no `album_de_telas_test.dart` demonstram visualmente alinhamento coeso com os 6 padrões extraídos de `Memora-Desing-Ideias/`, sem bordas pesadas em excesso, sem barra inferior cinza chapada e com o robô Memora unificado.
- **SC-006**: Um APK de release (`flutter build apk --release`) é compilado sem erros ao final da implementação, com verificação visual nos 3 temas (Claro, Escuro e Alto Contraste) comprovada pelas capturas regeneradas de `album_de_telas_test.dart` e pela suíte completa de contraste/acessibilidade (ficando a instalação no celular físico para conferência final do usuário).
