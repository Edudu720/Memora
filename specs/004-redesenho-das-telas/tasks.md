---

description: "Task list — Redesenho das telas"
---

# Tasks: Redesenho das telas — o Memora inteiro, e bonito

**Input**: Documentos de design em `specs/004-redesenho-das-telas/`

**Prerequisites**: [spec.md](spec.md) · [plan.md](plan.md) · [research.md](research.md) · [data-model.md](data-model.md) · [contracts/](contracts/) · [quickstart.md](quickstart.md)

**Tests**: **obrigatórios**. A constituição proíbe guarda sem teste, a FR-044
exige a matriz em toda tela, e o [quickstart.md](quickstart.md) define 14
cenários que são portão de saída da feature.

## Format: `[ID] [P?] [Story] Descrição`

- **[P]**: pode ser feito em paralelo (arquivos distintos, sem dependência)
- **[Story]**: a qual história de usuário a tarefa pertence

---

## ⚠️ A ordem desta lista tem um propósito

1. **A fonte vem antes de qualquer tela.** A T009 roda a suíte inteira com a
   família nova e confere que **nada mudou**: a matriz mede com a fonte
   quadrada do `flutter test`, pessimista nas duas direções (R3, corrigida ao
   implementar). Se algum resultado mudar, algum teste passou a carregar fonte,
   e isso se investiga antes de existir tela nova.
2. **A US2 vem antes da US1**, embora as duas sejam P1. O Início e o Hub são as
   telas mais vistas e fixam a linguagem que as outras copiam (R14). A fase da
   US2 **termina numa revisão de design da equipe** (T044): se ela reprovar,
   para tudo e volta à R2.
3. **Conteúdo é trabalho de verdade.** Os guias de passo a passo (capturas,
   texto, revisão) estão listados como tarefas próprias, e não escondidos
   dentro da tela que os mostra. São ~16 guias; é provável que eles, e não o
   código, sejam o caminho crítico.
4. **Uma fase, uma PR**, empilhadas, como nas features anteriores.

---

## Regras que valem para todas as tarefas

1. **Todo valor visual por token.** `validar_tokens.py` precisa passar a cada
   tarefa, e `validar_paleta.py` a cada cor nova.
2. **Todo `Text` usa `escalaTextoLimitada(context)`**, e todo texto dentro de
   `Row` pergunta "e se este texto dobrar de tamanho?" (`Flexible`).
3. **Teto de layout em fração da altura disponível, nunca em pixel.** Vale para
   o aviso aberto, as ilustrações e qualquer `BoxConstraints(maxHeight:)`.
4. **Toda tela nova entra na matriz** de `app/test/suporte/aparelhos.dart` — 4
   aparelhos × 3 escalas × 3 temas —, exigindo zero estouro **e** a ação
   principal alcançável. Teste com `tester.view.physicalSize`, nunca só
   `MediaQuery(size:)`.
5. **Todo portão novo é quebrado de propósito** antes de ser dado como pronto,
   e a quebra é registrada na descrição da PR. **Commite antes de quebrar** —
   `git checkout --` reverte para o HEAD e leva junto o trabalho não commitado.
6. **Teste de widget não espera disco nem `Future.delayed`.** Disco vai para
   `test` puro; teste de widget usa dublê em memória.
7. **Componente que serve a mais de uma tela vai para o Design System**, aparece
   na galeria e é exportado pelo barril — o portão do V10 da 002 reprova o que
   faltar.
8. **Simulado e banco andam juntos.** Toda linha nova de catálogo entra na
   migration **e** no `RepositorioAssistenteSimulado`, na mesma tarefa.

---

## Phase 1: Setup

**Purpose**: assets, declarações e estrutura que todas as fases usam.

- [X] T001 Baixar a família Atkinson Hyperlegible Next (pesos Regular, Medium e Bold) para `app/assets/fontes/atkinson_hyperlegible_next/`, junto com o `OFL.txt` que acompanha o pacote; **conferir a licença no próprio `OFL.txt`** antes de commitar (R3). Confirmar que `.ttf` já está no `.gitattributes` — está, desde a PR #29 — e que `git add` não avisa "LF will be replaced by CRLF"
- [X] T002 Declarar a família em `app/pubspec.yaml` (seção `fonts:`) e as pastas de assets novas. **O Flutter não declara subpastas recursivamente**: cada `assets/guias/<chave>/` precisa da própria linha, e a tarefa de cada guia (fases 6 e 7) acrescenta a sua
- [X] T003 [P] Criar `app/assets/ilustracoes/LICENCAS.md` com a tabela arquivo · origem · licença · alteração feita (R4), preenchendo as três ilustrações que já existem
- [X] T004 [P] Criar `app/assets/guias/CAPTURAS.md` com a tabela chave · data · versão do aplicativo · aparelho de referência, e as regras de captura de [contracts/guias.md](contracts/guias.md)
- [X] T005 [P] Criar os arquivos de texto `app/lib/l10n/textos_casca.dart`, `textos_apresentacao.dart`, `textos_guias.dart` e `textos_ajuda.dart`, seguindo o formato de `textos_autenticacao.dart`
- [X] T006 [P] Estender `app/test/suporte/aparelhos.dart` com um auxiliar que cruza a matriz de aparelhos × escalas com os três temas (`claro`, `escuro`, `altoContraste`), para os testes das fases seguintes não repetirem o laço

---

## Phase 2: Foundational

**Purpose**: fonte, tokens, ilustrações, componentes comuns, casca interna e a
`chave` do catálogo. **Nenhuma história começa antes desta fase terminar.**

### A fonte e os tokens

- [X] T007 Aplicar a família em todos os estilos e criar `MemoraTipografia.destaque` (~36) em `app/lib/design_system/tokens/tipografia.dart`, e ligar a família ao `ThemeData` em `app/lib/design_system/temas/temas_memora.dart`. Criar em `app/test/suporte/fonte.dart` um auxiliar que carrega a Atkinson com `FontLoader` **só para o álbum de telas** (T043); a matriz continua com a fonte quadrada do `flutter test`, que é pessimista nas duas direções (R3)
- [X] T008 [P] Acrescentar a `app/lib/design_system/tokens/dimensoes.dart` os tokens de [contracts/componentes.md](contracts/componentes.md): `ilustracaoCartao`, `ilustracaoCabecalho`, `ilustracaoHeroi`, `pisoDeIlustracao` e as frações `tetoDoAvisoAberto = 0.5` e `alturaMinimaDaTarefa = 0.5`
- [X] T009 Rodar `flutter test` inteiro com a família nova (depois de T007) e **conferir que nenhum resultado mudou** em relação aos 481 de antes: a matriz não carrega fonte, então a troca de família não pode mexer nela (R3). Se algo mudar, investigar qual teste passou a carregar fonte antes de seguir

### Ilustrações e a Memora

- [X] T010 [P] Desenhar a Memora em SVG, a partir do robô do wireframe, com quatro expressões: `app/assets/ilustracoes/memora_neutra.svg`, `memora_falando.svg`, `memora_comemorando.svg` e `memora_preocupada.svg`; registrar em `LICENCAS.md`
- [X] T011 [P] Selecionar e registrar as ilustrações e pictogramas em `app/assets/ilustracoes/` e `app/lib/design_system/componentes/ilustracao/icone_do_aplicativo.dart`: portas do Hub, estados vazio e erro, aplicativo genérico, ajuste de aparência, expressões 3D da Memora, logos de `whatsapp_logo.png` e `telegram_logo.png` e pictogramas dos 9 serviços sociais sem logotipo oficial (R4, R7), garantindo que todo arquivo de `app/assets/ilustracoes/` tenha linha em `app/assets/ilustracoes/LICENCAS.md`
- [X] T012 Acrescentar as ilustrações novas ao enum `Ilustracao` e o **medalhão** claro para os temas escuro e de alto contraste em `app/lib/design_system/componentes/ilustracao/ilustracao_memora.dart`; estender `app/test/design_system/ilustracao_e_destaque_test.dart` para conferir que toda ilustração do enum carrega e que, nos temas escuros, as coloridas estão sobre medalhão
- [X] T013 Criar `MemoraPersonagem` em `app/lib/design_system/componentes/ilustracao/memora_personagem.dart` (expressões, decorativa por padrão, anunciada com `descricao`). **É componente novo**: o `AvatarMemora` que já existe é o retrato do casal no cartão do cadastro e do login, e não o rosto da Memora — ele continua (correção feita ao implementar)

### Componentes comuns

- [X] T014 [P] Teste de `CabecalhoDeTela` em `app/test/design_system/cabecalho_de_tela_test.dart`: título em no máximo duas linhas com o título inteiro no rótulo semântico; "Voltar" com ícone **e** texto, sempre no mesmo canto; sem `aoVoltar`, sem "Voltar"; ilustração some com pouca altura, texto nunca; "Voltar" com os estados normal, foco e pressionado, cada um distinguível por mais de um sinal além da cor (FR-043)
- [X] T015 [P] Implementar `CabecalhoDeTela` em `app/lib/design_system/componentes/navegacao/cabecalho_de_tela.dart`
- [X] T016 [P] Teste de `CartaoDePorta` em `app/test/design_system/cartao_de_porta_test.dart`: o cartão inteiro é alvo de toque; `explicacao` quebra em vez de estourar a 200%; ilustração encolhe antes do texto e some abaixo do piso; no máximo um `principal` por tela; estados normal, foco, pressionado e desabilitado, cada um distinguível por mais de um sinal além da cor (FR-043). Provar quebrando: tirar o estado de foco
- [X] T017 [P] Implementar `CartaoDePorta` em `app/lib/design_system/componentes/cartoes/cartao_de_porta.dart`
- [X] T018 [P] Teste de `AvisoCompacto` em `app/test/design_system/aviso_compacto_test.dart`: título sempre na árvore; texto completo só aberto; aberto **não passa de 50% da altura disponível** em toda a matriz, rolando por dentro; fechado de novo a cada montagem. O controle "Ler o aviso inteiro" com os estados normal, foco e pressionado (FR-043). **Provar quebrando**: tirar o teto e ver reprovar no 360×640 a 200%
- [X] T019 [P] Implementar `AvisoCompacto` em `app/lib/design_system/componentes/avisos/aviso_compacto.dart`, com teto por `LayoutBuilder` e fração (regra 3)
- [X] T020 [P] Teste de `BalaoDeFala` em `app/test/design_system/balao_de_fala_test.dart`: autor muda posição, rosto e nome (não só cor); leitor anuncia "Memora disse:" / "Você disse:"; opções com 56 dp e 16 dp de separação; as opções com os estados normal, foco, pressionado e desabilitado (depois de escolhida), e o balão da Memora com o estado "escrevendo" enquanto a resposta chega (FR-043)
- [X] T021 [P] Implementar `BalaoDeFala` em `app/lib/design_system/componentes/conversa/balao_de_fala.dart`
- [X] T022 Exportar os quatro componentes e o `MemoraPersonagem` em `app/lib/design_system/design_system.dart` e mostrá-los, em todos os estados, em `app/lib/design_system/galeria/galeria_memora.dart`; `app/test/design_system/galeria_completa_test.dart` precisa continuar passando

### A casca interna

- [X] T023 Teste da casca em `app/test/features/casca/casca_interna_test.dart`: três destinos com ícone e nome; destino atual marcado por mais de um sinal além da cor; tocar no destino atual volta à raiz dele; "voltar" do sistema na raiz do Início pergunta antes de sair do Memora; destino inicial é o Início ([contracts/navegacao.md](contracts/navegacao.md))
- [X] T024 Implementar `CascaInterna` em `app/lib/features/casca/casca_interna.dart`, com uma pilha de navegação por destino e a `NavegacaoInferior` existente; textos em `textos_casca.dart`. A raiz de Configurações é **provisória** até a US7: a `TelaAparencia` de hoje, a linha da galeria (só quando `GaleriaMemora.paraDesenvolvimento()` não for `null`) e "Sair" com `SaidaComConfirmacao`
- [X] T025 Fazer o `FluxoAutenticacao` montar a `CascaInterna` quando a pessoa está dentro, em `app/lib/features/autenticacao/presentation/fluxo_autenticacao.dart`: toda rota das três pilhas nasce por `_rota(...)` (com o `Listener` de atividade), e `_fecharRotasAbertas` fecha **as três** pilhas
- [X] T026 Estender `app/test/features/autenticacao/fluxo_dentro_da_conta.dart` e `fluxo_rotas_e_inatividade_test.dart` com rota aberta em **cada** um dos três destinos: a inatividade fecha todas, e toque em tela de qualquer destino conta como atividade. **Provar quebrando**: fechar só a pilha ativa
- [X] T027 Trocar `home:` de `AplicativoMemora` em `app/lib/main.dart` para o `FluxoAutenticacao` e apagar `app/lib/demonstracao/`
- [X] T028 Teste do V1 em `app/test/features/casca/sem_andaime_test.dart`: nenhuma aba "Componentes" ou "Aparência" na raiz; com `paraDesenvolvimento()` devolvendo `null`, nenhuma linha leva à galeria (FR-007)

### A `chave` do catálogo

- [X] T029 Criar `backend/src/main/resources/db/migration/V8__chave_do_catalogo.sql`: coluna `chave VARCHAR(40)`, preenchida para as 8 linhas existentes (`whatsapp`, `facebook`, `instagram`, `youtube`, `google-fotos`, `telegram`, `gov-br`, `meu-inss`), depois `NOT NULL`, `UNIQUE` e `CHECK (chave ~ '^[a-z0-9-]+$')` ([data-model.md](data-model.md#servico_conhecido--migrations-v8-a-v10))
- [X] T030 Acrescentar `chave` a `backend/src/main/java/br/fatec/memora/assistente/dominio/ServicoConhecido.java` e à resposta de `api/ControladorCatalogo.java`; atualizar o schema `Servico` em `specs/003-hub-e-assistente/contracts/openapi.yaml` conforme [contracts/catalogo.md](contracts/catalogo.md). **Atualizar os testes que criam serviço sem `chave`** (revisão da #36): o `inserirServico` em JDBC de `PortoesDoEsquemaDaAssistenteTest.java` e as fábricas `ServicoConhecido.sensivel`/`cotidiano` usadas em `AutorizadorDeAcaoTest`, `ConversaNaoPersisteTest`, `InjecaoNaoViraAcaoTest` e `SugestaoNaoEhAutorizacaoTest`. A `chave` gerada nos testes precisa ser **única por linha** — uma fixa faria o `pacoteEhUnicoEntreAtivos` reprovar pelo `UNIQUE` da `chave`, e não pelo `ux_servico_pacote` que ele existe para provar
- [X] T031 Teste `backend/src/test/java/br/fatec/memora/assistente/ChaveDoCatalogoTest.java` (sobre `TesteComBanco`): as 8 linhas semeadas têm `chave`; inserir sem `chave`, repetida ou com maiúscula é recusado pelo banco; o catálogo devolve `chave`. **Apagar só o que criar.** Provar quebrando: tirar o `UNIQUE` da `V8` localmente e ver o teste reprovar
- [X] T032 Acrescentar `chave` a `ServicoDoCatalogo` em `app/lib/features/assistente/domain/assistente.dart` e as mesmas 8 chaves ao catálogo de `app/lib/features/assistente/data/repositorio_assistente_simulado.dart`
- [X] T033 Teste de ligação em `app/test/features/aprendizado/catalogo_e_guias_test.dart`, que lê `backend/src/main/resources/db/migration/*.sql` e extrai as `chave`s: **reprova se o simulado e as migrations divergirem**, nomeando a chave. A comparação com os guias entra na T063, com uma lista explícita de itens anteriores à 004 ainda sem guia, que precisa chegar a zero na T076. Provar quebrando: tirar uma chave do simulado
- [X] T033a Criar `app/test/suporte/estados_de_tela.dart`: um auxiliar que monta uma tela em **carregando**, **vazio** e **erro** e reprova se alguma ficar sem desenho próprio ou sem frase (FR-006). Os testes de tela das fases seguintes o usam. Provar quebrando: uma tela de teste que mostra só um `SizedBox` enquanto carrega

**Checkpoint**: casca de pé, componentes na galeria, fonte medida, catálogo com
`chave`. A partir daqui as histórias podem começar.

> **Situação em 2026-10-01** (PR da fundação, só o aplicativo):
>
> - **T011 está parcial.** Entraram as ilustrações que a fundação e a US2 usam:
>   as cinco portas do Hub, os estados vazio e erro, o aplicativo genérico e a
>   de aparência. Os pictogramas dos serviços sociais e as ilustrações dos
>   outros grupos de Ajustes nascem nas fases que os usam (US5, US7) —
>   desenhar agora seria desenhar sem a tela que os mostra. A Ajuda (fase 8)
>   reaproveitou ilustrações já existentes: os desenhos próprios dos assuntos
>   da Ajuda são só uma troca opcional (análise de 2026-10-13). Todas são
>   **desenho original da equipe**, e não de banco de licença aberta, como a R4
>   previa: a licença fica mais simples, e o `LICENCAS.md` registra cada uma.
> - **T029-T033 ficaram para a próxima PR.** Três delas são do backend (a V8 e o
>   contrato), e as duas do aplicativo dependem da V8 para ter `chave` a
>   comparar. O pedido desta rodada foi o front-end.
> - **Correções ao implementar**, todas registradas nos documentos:
>   - a matriz mede com a fonte quadrada do `flutter test`, e não com a Roboto
>     (R3 e T009 reescritas);
>   - o `AvatarMemora` é o retrato do casal, e não o rosto da Memora (T013);
>   - as portas são pílulas preenchidas, e não cartões: o `Cartao` não é
>     clicável (R2, contrato);
>   - o destino se chama "Ajustes", e não "Configurações" (ver `TextosCasca`).

---

## Phase 3: User Story 2 — O Início, o Hub e o caminho de volta (Priority: P1) 🎯 Primeira entrega

**Goal**: a pessoa entra e chega ao Início; a barra inferior a acompanha; o Hub
mostra cada parte com ilustração e explicação.

**Independent Test**: a partir de qualquer tela, voltar ao Início; depois, dizer
o que cada parte do Hub faz (US2).

### Tests

- [X] T034 [P] [US2] Teste em `app/test/features/inicio/tela_inicio_test.dart`: cumprimenta pelo `nomeTratamento`; um atalho para conversar e um para o Hub; **nenhum "Sair"** (FR-019); matriz completa; os estados da FR-006 que a tela tiver (carregando, vazio, erro), por `app/test/suporte/estados_de_tela.dart`
- [X] T035 [P] [US2] Consolidar e fechar os testes do Hub em `app/test/features/hub/tela_hub_test.dart`, `app/test/acessibilidade/hub_acessibilidade_test.dart` e `app/test/acessibilidade/hub_cabe_sem_rolar_test.dart` conforme a regra vigente da FR-017 (porta principal sempre à vista e faixa "há mais"; Hub inteiro sem rolar no 360×800 a 100%; exceção medida do 320×568 a 200%), sem "Sair", sem porta sem destino (FR-018) e cobrindo os estados da FR-006 por `app/test/suporte/estados_de_tela.dart`
- [X] T036 [US2] Teste do SC-006 em `app/test/features/casca/profundidade_test.dart`: a partir do Início, cada parte do aplicativo é alcançada em até 3 toques, contando os toques de verdade

### Implementation

- [X] T037 [US2] Criar `TelaInicio` em `app/lib/features/inicio/presentation/tela_inicio.dart`, com `MemoraTipografia.destaque`, `MemoraPersonagem` e os dois atalhos (o de conversar é o principal)
- [X] T038 [US2] Redesenhar `app/lib/features/hub/presentation/telas/tela_hub.dart` com `CabecalhoDeTela` e `CartaoDePorta`, tirando o "Sair"; `PortaDoHub` em `app/lib/features/hub/domain/hub.dart` ganha `ilustracao`
- [X] T039 [US2] Em `_portasConstruidas()` de `fluxo_autenticacao.dart`: tirar "Como eu vejo o Memora" (vai para Configurações); trocar o rótulo `portaServicos` de "Serviços do dia a dia" para **"Serviços sociais"**, como no wireframe, e ajustar a descrição em `app/lib/l10n/textos_assistente.dart` (FR-008); ligar as ilustrações
- [X] T040 [US2] Ligar o Início como raiz do destino Início em `app/lib/features/casca/casca_interna.dart`, com o Hub empilhado sobre ele
- [X] T041 [US2] Mover o portão da FR-025 da 001 de `app/test/features/autenticacao/fluxo_sair_confirma_test.dart` para a saída em Configurações (provisória, T024); a quebra (ligar o botão direto) precisa continuar reprovando
- [X] T042 [US2] Rodar a matriz completa em `tela_inicio_test.dart`, `tela_hub_test.dart`, `hub_acessibilidade_test.dart` e `app/test/features/autenticacao/fluxo_dentro_da_conta.dart`, e corrigir o que reprovar
- [X] T043 [US2] **Criar** `app/test/album/album_de_telas_test.dart` (renderiza cada tela, em cada tema, com a fonte embarcada, e salva em `app/build/album/` sem comparar nada — R13), por enquanto só com o Início e o Hub, e anexar as imagens à PR
- [X] T044 [US2] **Revisão de design da equipe** sobre o Início e o Hub, comparando com o wireframe e com o de hoje (R2, R14). Registrar o veredito, com quem participou e o que mudar, em `specs/004-redesenho-das-telas/revisao-de-design.md` e na PR. **Se reprovar, parar e revisar a R2 antes da fase 4**
  → **Feita em 2026-10-01 pelo Henrique**: direção aprovada, acabamento reprovado. Veredito em [revisao-de-design.md](revisao-de-design.md); as mudanças viraram a **Phase 3b**, abaixo. Falta a revisão dos dois Eduardos.

**Checkpoint**: a linguagem visual está aprovada e as demais telas a copiam.

---

## Phase 3b: O que a revisão da T044 mudou (Priority: P1)

**Goal**: aplicar o veredito da T044 ([revisao-de-design.md](revisao-de-design.md))
**antes** de a fase 4 copiar a linguagem. As tarefas marcadas com outra
história executam na fase daquela história, mas estão aqui para a revisão ter
um lugar só.

**Decisão pendente que esta fase herda da fase 3**: a FR-017 (Hub sem rolar a
150% no 320×568) é **inviável** junto com a FR-016 — a barra sozinha toma 123
dos 568 px a 150%. O teste está escrito e pulado (`hub_cabe_sem_rolar_test.dart`),
e o commit `d5a5031` apertou o cartão para caber a 100%, o oposto do "junto
demais" da revisão. ✅ **Resolvida em 2026-10-02 (Henrique)**: FR-017 reescrita —
porta principal sempre sem rolar e indicação de que há mais, em qualquer
aparelho; Hub inteiro sem rolar só no 360×800, a 100% e 150% (**superada pela
revisão do mesmo dia, logo abaixo: vale a FR-017 atual, só a 100%**). A T113 devolve o
respiro e reescreve o `hub_cabe_sem_rolar_test.dart` para a regra nova.
⚠️ **Revista no mesmo dia**: a T113 mediu o 360×800 a 150% inviável também
(faltam ~170 px de explicação que a FR-016 exige), e a principal não cabe
inteira no 320×568 a 200%. Henrique: Hub inteiro **só a 100%**, e a exceção
do 320×568 a 200% (basta o alvo de toque da principal à vista) entra na
FR-017. Nenhum teste pulado.

### Já, antes da fase 4

- [X] T111 [P] Ícone do aplicativo: a Memora (robô), a partir de `app/assets/ilustracoes/memora_*.svg`, em `app/android/app/src/main/res/mipmap-*` (ícone adaptativo: primeiro plano e fundo), e `android:label="Memora"` no `AndroidManifest.xml`, com maiúscula (FR-009b). Conferir no aparelho real
- [X] T112 [P] Ícones da barra inferior desenhados para ela (FR-015): reconhecíveis sem rótulo, mesmo peso visual entre os três, versão preenchida para o destino atual; contraste validado nos três temas. Teste em `casca_interna_test.dart` continua exigindo nome escrito ao lado
- [X] T113 Acabamento refinado do `CartaoDePorta` (FR-016, R2 regra 3): profundidade que encolhe ao pressionar, contorno, medalhão que se destaca da pílula também no tema claro (o aviso da #38); respiro que **cresce com a altura disponível**, em vez de fixo — revendo o `d5a5031` à luz da decisão da FR-017
- [X] T114 [P] Componente `CaixaDeEtapa` no Design System (`app/lib/design_system/componentes/cartoes/caixa_de_etapa.dart`), exportado e na galeria: uma caixa com a frase de instrução no topo e o conteúdo dentro (FR-002a, R2 regra 8). É informação, não ação: sem pílula nem preenchimento (FR-012 da 002). Teste em `app/test/design_system/caixa_de_etapa_test.dart`, com a matriz
- [X] T115 Rever o Início com a T113 e a T114: a Memora com uma frase de tutorial (R2 regra 9), os atalhos em caixas que dizem para que servem, e o espaço da tela usado — hoje sobra metade dela vazia em 390×844 (álbum da T043)
- [X] T116 Regerar o álbum (T043), reinstalar no aparelho, e **segunda rodada da revisão** do Início e do Hub — agora as telas novas — em `revisao-de-design.md`. **Portão do merge** (clarificação de 2026-10-13): nenhuma PR de tela nova entra na `master` antes desta tarefa. Implementar antes é permitido. As PRs de tela abertas em 2026-10-13 (#45, #46, #47, #55, #56) ficam de fora e são revisadas aqui, no aparelho
- [X] T116b Terceira rodada da revisão no aparelho físico (2026-10-14): resolução de 4 defeitos móveis (ícones vetoriais de apps em `IconeDoAplicativo`, balões de fala refinados, otimização de digitação/ThemeData e ocupação de 100% da altura) e integração dos assets do robô Memora 3D em `revisao-de-design.md`

### Nas fases seguintes

- [X] T117 [US1] Boas-vindas na altura toda, só para quem nunca entrou no aparelho (FR-009); **tela de volta** com a Memora ou uma pessoa idosa de fundo, "Entrar" como ação principal (FR-009a); cadastro e login com `CaixaDeEtapa`, sem mudar campos nem regras (FR-010); cumprir o cenário 5 da US1 ("Esqueci minha senha" e "Primeiro acesso" à vista sem rolar no login, em 100% no 320×568) e **retirar o `skip` do teste da T047** em `tela_login_test.dart` (revisão da #45). Substitui o escopo da T051 e amplia o da T052
- [X] T118 [US3] O aviso da conversa **aberto até a primeira mensagem e, depois, uma linha** com escudo e o núcleo ("senha" e "código"), que se toca para ler (FR-022, R5 revista). Nunca some, nem por gesto. Portão: depois da primeira mensagem, o aviso fechado ainda contém "senha" e "código"; provar quebrando com o aviso removido. Amplia a T055
- [X] T119 [US4] "Meus aplicativos" em **lista**, ícone do aparelho à esquerda e nome ao lado (FR-023 revista). Ajusta a tarefa da tela de aplicativos da fase 6
- [X] T120 [US4] **Captura pendente** (FR-028a): passo sem captura mostra um aviso visível com a chave do guia e o número do passo; teste em `catalogo_e_guias_test.dart` lista as pendentes, e a lista precisa chegar a zero antes da T104 (revisão da #47) O verificador de guias em `catalogo_e_guias_test.dart` hoje **reprova** guia com captura ausente, o que contradiz a FR-028a ("captura pendente"): trocar por uma **lista de pendentes**, não por falha. E conferir também que a pasta das capturas está declarada em `assets` no `pubspec.yaml` — `File(...).existsSync()` passa com PNG em disco que não foi empacotado.
- [X] T121 [US7] Grupo **Acessibilidade** em Ajustes (FR-038, FR-039a): tamanho do texto, reduzir movimento e alto contraste, cada opção com uma frase de para quem serve, com pré-visualização
- [X] T122 [US7] **Paletas prontas** (FR-039, R15) em `app/lib/design_system/tokens/cores.dart`, `app/lib/design_system/preferencias/preferencia_aparencia.dart`, `app/lib/design_system/preferencias/tela_aparencia.dart` e `specs/002-design-system/ferramentas/validar_paleta.py`: seis paletas de destaque (`azul`, `verde`, `roxo`, `coral`, `dourado`, `grafite`) nos temas claro e escuro (não no alto contraste), todas validadas pelo `validar_paleta.py --autoteste`, com pré-visualização e fallback para `azul` quando desconhecida
- [X] T123 [US8] **Data de nascimento opcional** no Perfil (FR-042c, `data-model.md`): só no aparelho, por conta, em `shared_preferences`; não é `DadoLocalDaPessoa`; sai com `esquecerTudo`. A idade é calculada na exibição. Teste de unidade da gravação e da saída; teste de widget do convite e da exibição
- [X] T124 [US5] Carteira Digital é o documento do gov.br (T080, resolvida): a `chave` na V10 é `carteira-digital`, e o guia da T082 segue essa leitura

---

## Phase 4: User Story 1 — O primeiro contato (Priority: P1)

**Goal**: da tela de boas-vindas à primeira conversa, com a Memora se
apresentando.

**Independent Test**: uma pessoa sem conta chega à primeira conversa sozinha (US1).

### Tests

- [X] T045 [P] [US1] Teste em `app/test/features/apresentacao/fluxo_apresentacao_test.dart`: três telas com "Continuar" e "Pular"; aparece depois do cadastro e da primeira entrada; **não** aparece de novo depois de sair e entrar; interrompida no meio, recomeça; a primeira tela diz o que a Memora nunca faz (FR-036a); matriz completa; os estados da FR-006 que a tela tiver (carregando, vazio, erro), por `app/test/suporte/estados_de_tela.dart`
- [X] T046 [P] [US1] Teste de unidade (`test` puro) em `app/test/features/apresentacao/apresentacao_vista_test.dart`: grava ao fim ou ao pular, por conta; outra conta no mesmo aparelho ainda não viu
- [X] T047 [P] [US1] Estender `app/test/features/autenticacao/tela_login_test.dart`: sem botões de Google e Facebook (FR-011); "Esqueci minha senha" e "Primeiro acesso" visíveis sem rolar em 100% no 320×568

### Implementation

- [X] T048 [US1] Criar `ApresentacaoVista` em `app/lib/features/apresentacao/data/apresentacao_vista.dart`, sobre `shared_preferences`; **não** é `DadoLocalDaPessoa` (R11). Sai com `LimpezaDeSessao.executar(esquecerTudo: true)` — aparelho que vai ser vendido não guarda as contas que passaram por ele (R11, revisão da #36)
- [X] T049 [US1] Criar as três telas (Olá, Apresentação, Exemplo) em `app/lib/features/apresentacao/presentation/fluxo_apresentacao.dart`, com `BalaoDeFala` e `MemoraPersonagem`; textos em `textos_apresentacao.dart`
- [X] T050 [US1] Inserir a apresentação em `app/lib/features/autenticacao/presentation/fluxo_autenticacao.dart`, entre a autenticação e a casca, só para conta que não a viu
- [X] T051 [P] [US1] **Substituída pela T117 (análise de 2026-10-13); não se faz.** Redesenhar `app/lib/features/autenticacao/presentation/telas/tela_boas_vindas.dart`: ilustração herói, a frase do que o Memora faz, uma ação principal e "Já tenho conta" (FR-009)
- [X] T052 [P] [US1] Redesenhar `tela_cadastro.dart` e `tela_login.dart` na mesma pasta, sem mudar campos nem regras (FR-010); `cadastro_acessibilidade_test.dart` e `campo_senha_ampliacao_test.dart` continuam passando
- [X] T127 [US1] Teste das duas boas-vindas, decidido pelo identificador do último acesso: a boas-vindas completa **só para quem nunca entrou no aparelho** (FR-009) e a **tela de volta** para quem já entrou (FR-009a); cada uma com a matriz de aparelhos × escalas. Antes da T117 (análise de 2026-10-13)

**Checkpoint**: US1 e US2 juntas são o MVP visível — entrar, ser apresentada e chegar ao Hub.

---

## Phase 5: User Story 3 — Conversar numa tela agradável (Priority: P1)

**Goal**: a conversa com rostos, balões e o aviso compacto.

**Independent Test**: em cinco turnos, a pessoa distingue quem disse o quê e as opções (US3).

### Tests

- [X] T053 [P] [US3] Estender o portão da FR-027 da 003 em `app/test/acessibilidade/conversa_acessibilidade_test.dart`, **sem tirar nada dele**: continua em 100%, 150% **e 200%**, com altura mínima da lista e botão de enviar alcançável. Acrescentar o da **FR-022**: em 100% e 150%, lista + campo de escrever ≥ 50% da altura disponível; o título do aviso sempre presente; o **resumo fechado contém "senha" e "código"** (FR-049); aberto, o aviso ≤ 50%. **Provar quebrando**: voltar o aviso antigo, sempre expandido. (Revisão da #36: a versão anterior trocava o portão por um só em 100% e 150%, e perdia os 200%.) Os estados da FR-006 que a tela tiver, por `app/test/suporte/estados_de_tela.dart`
- [X] T054 [P] [US3] Estender `app/test/features/assistente/tela_conversa_test.dart`: autor por posição, rosto e nome (FR-020); opções com 56 dp e afastadas (FR-021); confirmação e registro da 003 inalterados (`acao_confirmada_test.dart` passando); os estados da FR-006 que a tela tiver (carregando, vazio, erro), por `app/test/suporte/estados_de_tela.dart`

### Implementation

- [X] T055 [US3] Em `app/lib/features/assistente/presentation/telas/tela_conversa.dart`: trocar `_AvisoAntigolpe` e os tetos de 45%/42% pelo `AvisoCompacto`; mensagens em `BalaoDeFala`; Memora com `MemoraPersonagem`
- [X] T056 [US3] Com o teclado aberto, esconder a barra inferior em `app/lib/features/casca/casca_interna.dart` e manter a última mensagem e o campo visíveis; caso de teste em `tela_conversa_test.dart` com o teclado simulado (`viewInsets`)
- [X] T057 [US3] Na `TelaRecuperacao`, **manter o aviso inteiro** de `app/lib/features/autenticacao/presentation/widgets/aviso_antigolpe.dart`, só no visual novo (borda, rosto preocupado da Memora), sem `AvisoCompacto` (FR-049, revisão da #36). Os portões da FR-023 da 001 em `app/test/features/autenticacao/tela_recuperacao_test.dart` **não mudam**, e precisam continuar passando como estão

### A conversa no celular, com a assistente real (clarificação de 2026-10-21)

- [X] T129 [US3] A falha do serviço de fora **não reabre** o aviso: o controlador sabe se já houve pergunta (`jaPerguntou`), e o aviso fica recolhido mesmo com a pergunta devolvida ao campo (FR-022). Portão em `app/test/features/assistente/falhas_da_conversa_test.dart`, que reprovava antes do conserto
- [X] T130 [US3] Depois da primeira pergunta, o aviso vira **só o escudo** num canto (alvo de 48 dp), que abre os avisos inteiros; o rótulo para o leitor de tela leva "senha" e "código" (FR-022, FR-049). Ajustar os portões da T118 que procuravam o resumo escrito
- [X] T131 [P] [US3] **Negrito** na fala da Memora: `**trecho**` vira negrito, sem asterisco na tela nem no leitor de tela; marca sem par fica como texto (FR-020a). Teste de unidade do analisador e de widget do `BalaoDeFala`
- [X] T132 [US3] **Espera e escrita**: tirar o "Estou pensando..." de baixo do campo (fica só o `BalaoDeFala.escrevendo`) e fazer a resposta aparecer aos poucos, letra a letra, por `MemoraMovimento.efetiva` — de uma vez com "reduzir movimento" —, com o leitor de tela recebendo a fala inteira (FR-020b)

---

## Phase 6: User Story 4 — Aprender um aplicativo, passo a passo (Priority: P1)

**Goal**: "Meus aplicativos" em lista (FR-023), com busca, e o passo a passo dentro do Memora.

**Independent Test**: aprender pelo Memora a achar um vídeo num aplicativo
desconhecido, e repetir sozinha sem ele (US4).

### O canal de plataforma

- [X] T058 [P] [US4] Criar `app/android/app/src/main/kotlin/br/fatec/memora/CanalDeAplicativos.kt` (`estaInstalado`, `iconeDe`) e registrá-lo em `MainActivity.kt`, conforme [contracts/canal-aplicativos.md](contracts/canal-aplicativos.md): só lê, recusa argumento sem forma de pacote, nenhuma permissão nova
- [X] T059 [P] [US4] Criar a porta `ConsultaDeAplicativos`, o adaptador do canal e o simulado em `app/lib/services/aplicativos/consulta_de_aplicativos.dart`, com cache de ícone por pacote
- [X] T060 [P] [US4] Teste em `app/test/services/consulta_de_aplicativos_test.dart`: argumento inválido devolve `false`/`null` sem chamar o canal; falha do canal vira `false`/`null`; o segundo pedido do mesmo ícone não atravessa o canal

### O passo a passo

- [X] T061 [US4] Criar `Guia`, `Passo` e `RegiaoRelativa` em `app/lib/features/aprendizado/domain/guia.dart` e o enum das capturas, conforme [data-model.md](data-model.md#guia-conteúdo-embarcado); registro dos guias por `chave` em `app/lib/features/aprendizado/data/guias/guias.dart`
- [X] T062 [US4] Criar `ProgressoDeAprendizado` em `app/lib/features/aprendizado/data/progresso_de_aprendizado.dart` como `DadoLocalDaPessoa`, e incluí-lo em `dadosLocais` de `app/lib/services/ambiente/composicao.dart`
- [X] T063 [US4] Ativar no `catalogo_e_guias_test.dart` (T033) as validações de [contracts/guias.md](contracts/guias.md): chave sem guia, guia sem chave, 3 a 7 passos, captura sem descrição, guia sem linha em `CAPTURAS.md` — com a lista explícita de itens anteriores à 004 ainda sem guia
- [X] T064 [P] [US4] Teste de unidade (`test` puro, disco real) em `app/test/features/aprendizado/progresso_de_aprendizado_test.dart`: conta só no último passo; mais aprendido com empate para o mais recente; ausente quando vazio. Estender `app/test/features/autenticacao/fluxo_limpeza_de_sessao_test.dart`: o progresso sai em toda saída, inclusive por inatividade, **mesmo quando outro dado local falha** (FR-042b). E concluir um guia **não faz nenhuma chamada** a repositório nem ao servidor, provado com dublê espião (FR-042a)
- [X] T065 [P] [US4] Criar `PassoIlustrado` e `IndicadorDePasso` em `app/lib/design_system/componentes/guia/`, exportá-los e pô-los na galeria; teste em `app/test/design_system/passo_ilustrado_test.dart`: selo "Exemplo" sempre presente; contraste do selo e do anel de destaque medido nos três temas; "Passo N de M" em texto; o aviso da FR-032 quando `temCampoDeSenha`, **inteiro, nunca como `AvisoCompacto`** (FR-049); captura ainda carregando e captura que falhou ao carregar, cada uma com desenho próprio (FR-006, FR-043)
- [X] T066 [US4] Criar `TelaPassoAPasso` em `app/lib/features/aprendizado/presentation/tela_passo_a_passo.dart`: a Memora (`MemoraPersonagem`) junto do texto de cada passo (FR-003); "Voltar", "Sair do passo a passo" e "A minha tela está diferente" em todo passo (FR-026), esta última mostrando **primeiro, no próprio guia e sem internet**, o aviso de que tela diferente pedindo senha ou código pode ser golpe, e só depois oferecendo a conversa; último passo com parabéns, "Voltar ao Hub" e, só para cotidiano **e com conexão e catálogo vindo do servidor**, "Peça à Memora para abrir", que leva à conversa com o pedido — o guia **não abre nada**; quem decide é o `AutorizadorDeAcao` (FR-027, revisão da #36); aplicativo não instalado começa por um passo de "baixar na loja oficial" (revisão da #47) Usar `CatalogoGuardado.catalogoComOrigem()`: "Peça à Memora para abrir" só com `OrigemDoCatalogo.servidor`. Descartar o controlador ao sair e garantir que nenhum `registrarConclusao` pendente recrie o arquivo depois do `apagar()` da saída.
- [X] T067 [US4] Teste em `app/test/features/aprendizado/tela_passo_a_passo_test.dart` cobrindo os cenários 3 a 6 da US4, a matriz completa, e um caso que lê `app/android/app/src/main/AndroidManifest.xml` e **reprova se existir `SYSTEM_ALERT_WINDOW`** (FR-029); os estados da FR-006 que a tela tiver (carregando, vazio, erro), por `app/test/suporte/estados_de_tela.dart`

### "Meus aplicativos"

- [X] T068 [P] [US4] Criar a busca em `app/lib/features/aprendizado/domain/busca.dart` (trecho, sem acento, sem diferenciar maiúscula) e o teste `app/test/features/aprendizado/busca_test.dart` com "tik", "TIK", "video" × "Vídeo"
- [X] T069 [US4] Redesenhar o catálogo cotidiano de `app/lib/features/assistente/presentation/telas/tela_catalogo.dart` como **lista** com busca no topo, ícone à esquerda e nome ao lado (FR-023, revista; a T119 ajusta a tarefa): ícone do aparelho quando instalado, ilustração genérica quando não; tocar abre o guia, ou a conversa quando o item não tem guia ([contracts/catalogo.md](contracts/catalogo.md)); `app/test/acessibilidade/catalogo_acessibilidade_test.dart` e `catalogo_leva_a_conversa_test.dart` atualizados; os estados da FR-006 que a tela tiver (carregando, vazio, erro), por `app/test/suporte/estados_de_tela.dart` (revisão da #47) `ServicoDoCatalogo` não tem pacote Android. **Não mapear chave→pacote no app**: seria uma segunda fonte de verdade, território da FR-041. Se o campo for acrescentado ao contrato, `_mapaDe`/`_servicoDe` do `CatalogoGuardado` precisam carregá-lo e o `_defeitoDe` deve exigir `COTIDIANO ⇔ pacote`.
- [X] T069a [US4] Criar o catálogo guardado em `app/lib/features/assistente/data/catalogo_guardado.dart`, envolvendo a consulta de catálogo do `RepositorioAssistente`: guarda em arquivo local a última resposta completa, **substitui** a guardada a cada resposta nova (nunca mescla), ignora resposta malformada e, sem conexão, devolve a guardada. **Não** é `DadoLocalDaPessoa` (FR-024a, [data-model.md](data-model.md#catálogo-guardado-estado-no-aparelho))
- [X] T069b [P] [US4] Teste de unidade (`test` puro, disco real) em `app/test/features/assistente/catalogo_guardado_test.dart`: sem conexão devolve o último recebido; item retirado do servidor some na primeira resposta nova; resposta malformada não apaga o guardado; primeira abertura sem conexão e sem nada guardado diz que precisa de internet; sair da conta **não** apaga o catálogo. Provar quebrando: mesclar em vez de substituir, e ver o item retirado sobreviver

### Conteúdo e catálogo

- [X] T070 [US4] Guia do **TikTok** (Figuras 21-24 do wireframe): capturas em `app/assets/guias/tiktok/`, `app/lib/features/aprendizado/data/guias/tiktok.dart`, textos em `textos_guias.dart`, linha em `CAPTURAS.md`, pasta declarada no `pubspec.yaml`
- [X] T071 [P] [US4] Guias de **WhatsApp**, **Instagram** e **YouTube**, no mesmo formato da T070, em `app/assets/guias/<chave>/` e `app/lib/features/aprendizado/data/guias/<chave>.dart`, com textos em `app/lib/l10n/textos_guias.dart` e linha em `app/assets/guias/CAPTURAS.md`
- [X] T072 [P] [US4] Guias de **Facebook**, **Google Fotos** e **Telegram**, no mesmo formato, em `app/assets/guias/<chave>/` e `app/lib/features/aprendizado/data/guias/<chave>.dart`, com textos em `app/lib/l10n/textos_guias.dart` e linha em `app/assets/guias/CAPTURAS.md`
- [X] T073 [US4] Conferir num aparelho real os pacotes de TikTok, Kwai, Messenger, Gmail, Netflix e Google, descartando o que for instável entre fabricantes, como a V5 fez; registrar o resultado em `data-model.md`
- [X] T074 [US4] Guias dos aplicativos aprovados na T073 (TikTok aprovado e semeado em `backend/src/main/resources/db/migration/V11__tiktok_no_catalogo.sql`; demais candidatos adiados conforme regra de corte de escopo de guias), no formato da T070, em `app/assets/guias/tiktok/` e `app/lib/features/aprendizado/data/guias/tiktok.dart`, com textos em `app/lib/l10n/textos_guias.dart` e linha em `app/assets/guias/CAPTURAS.md`
- [X] T075 [US4] Criar `backend/src/main/resources/db/migration/V11__tiktok_no_catalogo.sql` só com os aplicativos que têm guia, acrescentar os pacotes ao `<queries>` de `app/android/app/src/main/AndroidManifest.xml` e as linhas ao `app/lib/features/assistente/data/repositorio_assistente_simulado.dart`; `CatalogoSemeadoTest` atualizado

---

## Phase 7: User Story 5 — Serviços do governo, com a Memora ensinando (Priority: P2)

**Goal**: os nove serviços sociais, cada um com guia, nenhum aberto pela Memora.

**Independent Test**: depois do passo a passo, a pessoa diz onde se digita a
senha do gov.br e onde nunca se digita (US5).

- [X] T076 [P] [US5] Estender `app/test/features/assistente/servico_sensivel_test.dart`: cada serviço com pictograma e nome; nenhum botão "Abrir"; todo guia sensível com `precisaTerEmMaos`; passo com `temCampoDeSenha` mostra o aviso da FR-032 **inteiro, nunca como `AvisoCompacto`** (FR-049). Fechar a T063: a lista de itens sem guia chega a **zero** e é apagada do teste; os estados da FR-006 que a tela tiver (carregando, vazio, erro), por `app/test/suporte/estados_de_tela.dart`
- [X] T077 [US5] Redesenhar o catálogo sensível (Serviços sociais) em `tela_catalogo.dart`, com a frase de que ali se aprende a acessar os serviços, e pictogramas em vez de logotipos (R7)
- [X] T078 [US5] Guia do **Gov.br** (Figuras 29-36 do wireframe), com o que ter em mãos e o aviso de senha nas telas de entrada; capturas com o campo de senha **vazio**, em `app/assets/guias/<chave>/` e `app/lib/features/aprendizado/data/guias/<chave>.dart`, com textos em `app/lib/l10n/textos_guias.dart` e linha em `app/assets/guias/CAPTURAS.md`
- [X] T079 [P] [US5] Guia do **Meu INSS**, no mesmo formato, em `app/assets/guias/<chave>/` e `app/lib/features/aprendizado/data/guias/<chave>.dart`, com textos em `app/lib/l10n/textos_guias.dart` e linha em `app/assets/guias/CAPTURAS.md`
- [X] T080 [US5] **Confirmar com a equipe** qual "Carteira Digital" o wireframe quis dizer, e registrar a resposta na nota ¹ de `specs/004-redesenho-das-telas/data-model.md`, antes de capturar
  → **Resolvida em 2026-10-01**: é o documento digital do gov.br (Henrique). Nota ¹ do `data-model.md` atualizada.
- [X] T081 [P] [US5] Guias de **e-Título**, **Serasa**, **FGTS** e **Poupatempo**, em `app/assets/guias/<chave>/` e `app/lib/features/aprendizado/data/guias/<chave>.dart`, com textos em `app/lib/l10n/textos_guias.dart` e linha em `app/assets/guias/CAPTURAS.md`
- [X] T082 [P] [US5] Guias de **Carteira Digital** (conforme T080), **Correios** e **Carteira de Trabalho Digital**, em `app/assets/guias/<chave>/` e `app/lib/features/aprendizado/data/guias/<chave>.dart`, com textos em `app/lib/l10n/textos_guias.dart` e linha em `app/assets/guias/CAPTURAS.md`
- [X] T083 [US5] Criar `backend/src/main/resources/db/migration/V10__servicos_sociais.sql` (todas `SENSIVEL`, `identificador_android` nulo) e as mesmas linhas no simulado; teste `backend/src/test/java/br/fatec/memora/assistente/ServicosSociaisTest.java`: inserir uma das novas com pacote é recusado por `ck_servico_sensivel_nao_abre`; apaga só o que criar
- [X] T084 [US5] Medir `app/assets/guias/` e reprovar acima de 8 MB, num caso de `catalogo_e_guias_test.dart`

---

## Phase 8: User Story 6 — Pedir ajuda sobre o próprio Memora (Priority: P2)

**Goal**: a Ajuda do wireframe, com a conversa guiada e as dicas de segurança.

**Independent Test**: achar, pela Ajuda, como se proteger de um golpe por telefone (US6).

- [X] T085 [P] [US6] Teste em `app/test/features/ajuda/tela_ajuda_test.dart`: assuntos com desenho e nome; "Segurança" mostra uma dica por vez, incluindo o que o Memora nunca faz (FR-036a); "Ver a apresentação de novo" funciona; **sem `MEMORA_URL_DOWNLOAD`, "Compartilhar" não existe**; com ele, avisa antes e envia só o endereço oficial; matriz completa; os estados da FR-006 que a tela tiver (carregando, vazio, erro), por `app/test/suporte/estados_de_tela.dart`
- [X] T086 [US6] Criar `AssuntoDeAjuda` em `app/lib/features/ajuda/domain/assunto_de_ajuda.dart` e o conteúdo em `textos_ajuda.dart`, incluindo "Como baixar um aplicativo" com a conferência do desenvolvedor na loja oficial (FR-036)
- [X] T087 [US6] Criar `TelaAjuda` e `TelaAssunto` em `app/lib/features/ajuda/presentation/`
- [X] T088 [US6] Criar a ajuda guiada da conversa (Figuras 15-19) em `app/lib/features/ajuda/presentation/ajuda_guiada_da_conversa.dart`, com `BalaoDeFala` e saída direta para a conversa real (FR-034)
- [X] T089 [US6] Acrescentar `urlDownload` a `app/lib/services/ambiente/ambiente.dart` (de `--dart-define=MEMORA_URL_DOWNLOAD`) e o envio por `ACTION_SEND` do `android_intent_plus` em `app/lib/features/ajuda/data/compartilhar.dart`; caso em `app/test/services/ambiente_test.dart`
- [X] T090 [US6] Pôr a porta "Ajuda" no Hub, em `_portasConstruidas()`, usando `portaAjuda` e `descricaoAjuda` de `textos_assistente.dart`  — fecha a primeira metade da T095 da 003. Com a quinta porta, rodar de novo `app/test/acessibilidade/hub_acessibilidade_test.dart`: a FR-017 atual (porta principal sempre à vista e faixa "há mais"; Hub inteiro sem rolar só no 360×800 a 100%) precisa continuar passando com as 5 portas

---

## Phase 9: User Story 7 — Ajustar o Memora ao meu jeito (Priority: P2)

**Goal**: Configurações com Aparência, Acessibilidade, Privacidade e Conta (FR-038, revista na T044: o texto antigo dizia só três grupos).

**Independent Test**: deixar o texto maior e sair da conta, sem ajuda (US7).

- [X] T091 [P] [US7] Teste em `app/test/features/configuracoes/configuracoes_test.dart`: só Aparência, Acessibilidade, Privacidade e Conta (sem "Notificações" e "Idiomas"); galeria só em depuração; Privacidade apaga a conversa **só depois das duas etapas** da `ConfirmacaoMemora.irreversivel` — um toque só não apaga nada, e o botão de apagar não fica ao lado do de cancelar (FR-040). Provar quebrando: trocar pela confirmação simples; Conta mostra o canal, "Sair" pergunta antes, "Sair e esquecer este aparelho" usa `esquecerTudo`; a Conta diz o que o Memora nunca faz (FR-036a); matriz completa; os estados da FR-006 que a tela tiver (carregando, vazio, erro), por `app/test/suporte/estados_de_tela.dart`
- [X] T092 [US7] Criar `TelaConfiguracoes` em `app/lib/features/configuracoes/presentation/tela_configuracoes.dart`, substituindo a raiz provisória da T024, e apontar `app/test/features/autenticacao/fluxo_sair_confirma_test.dart` para a saída em Conta, mantendo a quebra que ele já prova
- [X] T093 [US7] Acrescentar "reduzir movimento" a `PreferenciaAparencia` (`app/lib/design_system/preferencias/preferencia_aparencia.dart`), persistida pelo repositório de `app/lib/services/preferencias/` e aplicada sobre o `MediaQuery` no `builder` de `MaterialApp` em `main.dart`; redesenhar `tela_aparencia.dart` com pré-visualização e desfazer (FR-039); `app/test/design_system/reducao_de_movimento_test.dart` e `preferencias/tela_aparencia_test.dart` estendidos
- [X] T094 [US7] Criar `TelaPrivacidade` em `app/lib/features/configuracoes/presentation/tela_privacidade.dart`: o que fica no aparelho, em linguagem comum, e apagar a conversa pela `ConfirmacaoMemora.irreversivel`, em duas etapas (FR-040; fecha a T085 da 003)
- [X] T095 [US7] Criar `TelaConta` em `app/lib/features/configuracoes/presentation/tela_conta.dart`, com o canal vindo de `UltimoAcesso` (R10); apontar `app/test/features/autenticacao/saida_limpa_armazenamento_test.dart` para ela, mantendo as quatro quebras que o portão já provou

---

## Phase 10: User Story 8 — Meu perfil (Priority: P3)

**Goal**: o Perfil com o que o Memora já sabe, como informação.

**Independent Test**: dizer, olhando o Perfil, qual canal está ligado à conta (US8).

- [X] T096 [P] [US8] Teste em `app/test/features/perfil/tela_perfil_test.dart`: nome, desenho, canal e o mais aprendido como **informação** (o mesmo critério de `informacao_nao_e_acao_test.dart`); a frase de "vamos aprender juntos" quando vazio; nenhum campo de plano, e a idade só como informação e só se a pessoa a informou, pela `SecaoIdade` da T123 (FR-042, FR-042c); **nenhuma chamada ao repositório** ao abrir (dublê espião); some quando a sessão expira (FR-050); matriz completa; os estados da FR-006 que a tela tiver (carregando, vazio, erro), por `app/test/suporte/estados_de_tela.dart`
- [X] T097 [US8] Criar `TelaPerfil` em `app/lib/features/perfil/presentation/tela_perfil.dart`, ligar como raiz do destino Perfil e **apagar** `app/lib/features/autenticacao/presentation/telas/tela_perfil.dart` (pendência da #35)

---

## Phase 11: User Story 9 — Planos fora (Priority: —)

**Goal**: garantir que não existe plano, assinatura nem pagamento.

- [X] T098 [US9] Teste em `app/test/features/casca/sem_planos_test.dart`: varre os textos de `app/lib/l10n/` e a árvore de cada tela da casca atrás de "plano", "assinatura", "pagamento" e "premium", e reprova ao achar. O mesmo teste procura, nos textos de `l10n/`, os termos técnicos da FR-008 — "Hub", "Chatbot" e "App" como palavra inteira, aceitando "aplicativo" por extenso — e reprova nomeando o texto. Provar quebrando: pôr "Plano" numa porta do Hub

---

## Phase 12: Polish & Cross-Cutting Concerns

### Achados da revisão das #36 a #38 que viraram tarefa (2026-10-01)

- [X] T109 **Atividade pelo leitor de tela e pelo teclado conta como atividade** (FR-017 da 001). O `Listener` da casca só vê `onPointerDown`: o toque duplo do TalkBack chega como `SemanticsAction.tap`, e digitar não gera ponteiro — quem usa leitor de tela é avisado de inatividade a cada 28 minutos mesmo ativo. Contar ações semânticas (por exemplo num `WidgetsFlutterBinding` próprio que sobrescreva `performSemanticsAction`) e mudanças de texto, com teste por `semanticsOwner.performAction` em `app/test/features/casca/atividade_acessivel_test.dart`. Achado da revisão da #38; pré-existente desde a US2 da 001
- [X] T110 Toque **dentro de um diálogo** conta como atividade: hoje os diálogos abertos no `Navigator` de fora ficam fora do `Listener` da casca (o aviso de inatividade se salva porque registra atividade sozinho). Teste em `app/test/features/casca/atividade_acessivel_test.dart`

- [X] T098a Teste em `app/test/features/casca/sem_campo_de_segredo_test.dart`: varre `app/lib/features/` e reprova qualquer uso de `CampoSenha` ou `CampoCodigo` fora de `features/autenticacao/` (FR-048). Provar quebrando: pôr um `CampoSenha` na `TelaPerfil`
- [X] T099 [P] Redesenhar as telas fora do wireframe na mesma linguagem: `tela_confirmar_canal.dart`, `tela_entrega_do_aparelho.dart`, `tela_primeira_entrada.dart` (em `autenticacao/presentation/telas/`), `tela_recuperacao.dart` (em `autenticacao/presentation/telas/`; a spec a lista entre as telas fora do wireframe a redesenhar, e a T057 só cuida do aviso), `tela_registro.dart` (em `assistente/presentation/telas/`) e a `ConfirmacaoMemora`; `fluxo_assistido_test.dart`, `tela_registro_test.dart` e `registro_acessibilidade_test.dart` passando na matriz completa
- [X] T100 [P] Cruzar `app/test/design_system/galeria_test.dart` com os três temas e confirmar que todo componente novo aparece
- [X] T101 **Estender** `app/test/album/album_de_telas_test.dart`, criado na T043, para renderizar e salvar em `app/build/album/<tema>/` todas as telas da Feature 004 (`boas_vindas`, `boas_vindas_de_volta`, `cadastro`, `login`, `apresentacao_1_ola`, `apresentacao_2_conversa`, `apresentacao_3_exemplo`, `inicio`, `hub`, `conversa`, `meus_aplicativos`, `passo_a_passo_tiktok`, `servicos_sociais`, `passo_a_passo_gov_br`, `ajuda`, `ajuda_assunto_seguranca`, `ajuda_guiada_conversa`, `configuracoes`, `aparencia`, `acessibilidade`, `privacidade`, `conta`, `perfil`, `data_de_nascimento`) e as telas fora do wireframe redesenhadas na T099 (`confirmar_canal`, `entrega_do_aparelho`, `primeira_entrada`, `recuperacao`, `registro`) nos 3 temas (`claro`, `escuro`, `altoContraste`)
- [X] T102 Preencher a tabela "Onde cada cenário roda" em `specs/004-redesenho-das-telas/quickstart.md` e conferir a tabela de inventário em `specs/004-redesenho-das-telas/spec.md`: cada uma das 35 telas do wireframe existe no álbum, ou tem a decisão de não existir registrada (SC-001)
- [X] T103 Executar a verificação completa (`flutter analyze`, `flutter test`, `python specs/002-design-system/ferramentas/validar_paleta.py --autoteste`, `python specs/002-design-system/ferramentas/validar_tokens.py --autoteste`) e atualizar as contagens e o estado da Feature 004 em `docs/relatorios/o-que-falta.md` (V11)
- [ ] T104 **Revisão de design** dos três integrantes sobre o álbum completo (`app/build/album/`), tela a tela contra o wireframe e contra o de hoje (SC-005, V13), com o veredito em `specs/004-redesenho-das-telas/revisao-de-design.md`. A revisão confere também, guia por guia, que nenhuma captura tem dado pessoal real (FR-028), que cada tela tem uma só ação principal (FR-002), a FR-005 e a FR-045 (validação humana da equipe)
- [ ] T105 **Teste com 5 pessoas de 65+** (V14, SC-002 a SC-004), com os resultados por tarefa e as notas em `specs/004-redesenho-das-telas/teste-com-pessoas.md` — mesma rodada que a T071 da 003 e a T050 da 002 esperam (validação presencial de campo)
- [ ] T106 Revisões obrigatórias conforme `.specify/memory/constitution.md`: código, UX, acessibilidade e segurança em `specs/004-redesenho-das-telas/revisao-de-design.md` (validação humana de PR)
- [X] T107 Registrar em `docs/referencia/requisitos-atualizados.md` e `docs/design/divergencias-do-prototipo.md` cada divergência do wireframe desta feature, com o motivo: Planos fora, idade opcional e só no aparelho (FR-042c), Acessibilidade como grupo próprio (FR-038), paletas prontas de cor (FR-039), sem "Idiomas" e "Notificações", pictograma em vez de logotipo, sem o site de ajuda externo, passo a passo dentro do Memora. Atualizar também `specs/003-hub-e-assistente/spec.md` (US1, FR-043 e a tabela das duas categorias): a porta passa a se chamar "Serviços sociais", e banco e saúde continuam na mesma categoria SENSIVEL quando entrarem no catálogo
- [X] T125a [P] [US7] Aplicar `CaixaDeEtapa` (`app/lib/design_system/componentes/cartoes/caixa_de_etapa.dart`, FR-002a) em `app/lib/features/configuracoes/presentation/tela_configuracoes.dart`, `app/lib/features/configuracoes/presentation/tela_conta.dart` e `app/lib/features/configuracoes/presentation/tela_privacidade.dart`, mantendo a separação `MemoraEspacamento.xxxl` da FR-041 e a confirmação em duas etapas da FR-040, e validar na matriz em `app/test/features/configuracoes/configuracoes_test.dart`
- [X] T125b [P] [US8] Aplicar `CaixaDeEtapa` (`app/lib/design_system/componentes/cartoes/caixa_de_etapa.dart`, FR-002a) em `app/lib/features/perfil/presentation/tela_data_de_nascimento.dart` (caixa para campos dia/mês/ano + salvar, e caixa separada para remover data quando existente) e validar na matriz em `app/test/features/perfil/tela_perfil_test.dart`
- [X] T125c [P] [US4] Aplicar `CaixaDeEtapa` (`app/lib/design_system/componentes/cartoes/caixa_de_etapa.dart`, FR-002a) em `app/lib/design_system/componentes/guia/passo_ilustrado.dart` e `app/lib/features/aprendizado/presentation/tela_passo_a_passo.dart` (tanto nos passos intermediários quanto no cartão `_Conclusao`), e validar na matriz em `app/test/design_system/passo_ilustrado_test.dart` e `app/test/features/aprendizado/tela_passo_a_passo_test.dart`
- [X] T125d [P] [US6] Aplicar `CaixaDeEtapa` (`app/lib/design_system/componentes/cartoes/caixa_de_etapa.dart`, FR-002a) em `app/lib/features/ajuda/presentation/tela_ajuda.dart`, `app/lib/features/ajuda/presentation/tela_assunto.dart` e `app/lib/features/ajuda/presentation/ajuda_guiada_da_conversa.dart`, e validar na matriz em `app/test/features/ajuda/tela_ajuda_test.dart`
- [X] T125e [US1] Aplicar `CaixaDeEtapa` (`app/lib/design_system/componentes/cartoes/caixa_de_etapa.dart`, FR-002a) às telas fora do wireframe da T099 (`app/lib/features/autenticacao/presentation/telas/tela_confirmar_canal.dart` e `app/lib/features/autenticacao/presentation/telas/tela_recuperacao.dart`)

---

## Dependencies & Execution Order

### Phase dependencies

```text
Setup (1) ─▶ Foundational (2) ─▶ US2 (3) ──revisão T044──▶ US1 (4) ─┐
                                                                    ├─▶ US3 (5)
                                                                    ├─▶ US4 (6) ─▶ US5 (7)
                                                                    ├─▶ US6 (8)
                                                                    ├─▶ US7 (9)
                                                                    ├─▶ US8 (10)
                                                                    └─▶ US9 (11)
                                                         todas ─▶ Polish (12)
```

### User story dependencies

- **US2**: depende só da fase 2. **Bloqueia todas as outras pela revisão T044**,
  e esse bloqueio é o propósito: é ali que a linguagem visual é aprovada.
- **US1**: independente de código depois da T044.
- **US3**: independente; usa o `AvisoCompacto` e o `BalaoDeFala` da fase 2.
- **US4**: independente. **US5 depende da US4**, porque usa a `TelaPassoAPasso`,
  o `PassoIlustrado` e a validação de guias.
- **US6**: independente; a ajuda guiada reusa o `BalaoDeFala`, e "Ver a
  apresentação de novo" precisa da US1.
- **US7** e **US8**: independentes entre si. As duas leem o canal do
  `UltimoAcesso`, sem que uma precise da outra.
- **US9**: independente; roda melhor por último, quando todas as telas existem.

### Within each story

Testes primeiro, depois domínio, depois tela, depois conteúdo. Nos guias, a
migration do catálogo vem **depois** do conteúdo, nunca antes (R8).

---

## Parallel Opportunities

- **Fase 1**: T003 a T006 juntas.
- **Fase 2**: T008 em paralelo com T007; T010 e T011 (ilustrações) em paralelo
  com todo o resto da fase; os quatro pares teste/componente (T014-T021) entre
  si. O bloco do backend (T029-T031) em paralelo com toda a parte do aplicativo.
- **US4**: o canal (T058-T060) em paralelo com o passo a passo (T061-T067); os
  guias T071 e T072 entre si, e com a tela.
- **US5**: T079, T081 e T082 entre si, depois da T080.
- **Entre histórias**, depois da T044: US3, US4, US6 e US7 podem andar em
  paralelo por pessoas diferentes — os arquivos não se cruzam, exceto
  `fluxo_autenticacao.dart` (T039, T050, T090), que precisa de ordem.

### Exemplo — US4 com duas pessoas

```text
Pessoa A: T058 → T059 → T060 → T068 → T069
Pessoa B: T061 → T062 → T063 → T064 → T065 → T066 → T067
Conteúdo: T070 → (T071 ∥ T072) → T073 → T074 → T075
```

### Ordem de Execução — Fechamento Técnico (2026-11-09, Base `develop`)

```text
Bloco Paralelo 1 (Código e Licenças):
  ├── T011  [P] Licenças de ilustrações (LICENCAS.md)
  ├── T035  [P] [US2] Consolidação dos testes do Hub (FR-017)
  ├── T125a [P] [US7] CaixaDeEtapa em Ajustes, Conta e Privacidade
  ├── T125b [P] [US8] CaixaDeEtapa em Data de Nascimento (Perfil)
  ├── T125c [P] [US4] CaixaDeEtapa em PassoIlustrado e TelaPassoAPasso
  └── T125d [P] [US6] CaixaDeEtapa em Ajuda, Assunto e Ajuda Guiada
        │
        ▼
Bloco Sequencial 2 (Álbum Completo):
  └── T101  Extensão do album_de_telas_test.dart (depende de T125a–T125d para capturar o layout final)
        │
        ▼
Bloco Sequencial 3 (Documentação e Verificação Completa):
  ├── T102  Tabela "Onde cada cenário roda" em quickstart.md e conferência do inventário em spec.md
  ├── T107  Divergências em divergencias-do-prototipo.md, requisitos-atualizados.md e specs/003/spec.md
  └── T103  Verificação completa (flutter analyze, flutter test, validar_paleta.py, validar_tokens.py) e o-que-falta.md
```

---

## Implementation Strategy

### MVP — fases 1, 2, 3 e 4

Setup, fundação, **US2** e **US1**. Ao fim delas, a pessoa abre o aplicativo,
vê uma entrada acolhedora, é apresentada à Memora, chega ao Início e ao Hub, e
a barra inferior a acompanha — **sem andaime nenhum**. É o que mais muda a
primeira impressão, que é o que a equipe disse não estar satisfeita.

### Incremental

1. MVP → revisão de design (T044) aprovada.
2. **US3 + US4**: o centro do produto — conversar e aprender. Demonstrável com
   os guias do TikTok e do WhatsApp antes de todos os outros estarem prontos.
3. **US5**: o gov.br, a tela que a banca mais vai querer ver.
4. **US6 + US7 + US8**: o que torna o aplicativo completo.
5. **US9 + Polish**: álbum, revisão final e as 5 pessoas.

### Se o prazo de novembro apertar

O corte menos danoso é **reduzir guias**, nunca telas: um item sem guia abre a
conversa ([contracts/catalogo.md](contracts/catalogo.md)), e a tela continua
existindo. Os guias do wireframe (TikTok e Gov.br) e os quatro mais usados
(WhatsApp, Instagram, YouTube e Meu INSS) são o piso.
