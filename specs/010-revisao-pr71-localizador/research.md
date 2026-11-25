# Pesquisa e Decisões Técnicas: Correções da Revisão da PR #71

**Feature**: `010-revisao-pr71-localizador`  
**Branch**: `feature/009-localizador-servicos`  
**Data**: 2026-11-15  
**Base**: Revisão da PR #71 (`CHANGES_REQUESTED`), especificação [spec.md](spec.md) e inspeção direta do código-fonte nas camadas Flutter, Spring Boot, scripts de documentação e CI.

---

## R1 — Expurgo de PII, Remoção de `Memora-Desing-Ideias/` e Reescrita Limpa do Histórico Git

- **Decisão**:
  1. Substituir todas as ocorrências de CPF real (`\d{3}\.\d{3}\.\d{3}-\d{2}` referente ao titular das capturas) e menções nominais pessoais nos comentários, docstrings, tabelas de captura e contratos dos 8 arquivos identificados (`scripts/censurar_servicos_sociais.py`, `scripts/processar_guias_visuais.py` e os 6 arquivos de `specs/006-guias-servicos-sociais/`: `spec.md`, `plan.md`, `research.md`, `quickstart.md`, `tasks.md`, `contracts/guias-com-secoes.md`) por placeholders sintéticos (`XXX.XXX.XXX-XX` e rótulos genéricos de titular), preservando o funcionamento dos scripts.
  2. Adicionar `Memora-Desing-Ideias/` ao `.gitignore` e remover a pasta do índice de controle de versão (`git rm -r --cached Memora-Desing-Ideias/`) para que as imagens de protótipo/referência deixem de trafegar no repositório remoto.
  3. **Estratégia de Histórico (Clarificação Q3 — Opção A)**: Após validar todos os testes e portões na árvore final limpa, consolidar (`squash`) todas as entregas legítimas da branch `feature/009-localizador-servicos` em **1 único commit limpo diretamente sobre `origin/develop`**, garantindo que o CPF e os objetos de `Memora-Desing-Ideias/` não existam em nenhum commit alcançável pela PR #71, e atualizar a PR via `git push --force-with-lease`.
- **Justificativa**: Um commit corretivo incremental (`git commit` comum) deixaria o CPF real permanente nos blobs e diffs dos commits anteriores da PR #71, mantendo a violação de privacidade ativa no histórico público do GitHub. O `squash` limpo sobre `origin/develop` elimina também commits intermediários de merge (`8809211`) e regressões de workflow trazidas antes da convergência.
- **Alternativas descartadas**:
  - *Commit adicional de correção sem reescrita*: rejeitado por preservar PII no histórico alcançável.
  - *Rebase interativo commit a commit*: rejeitado por introduzir conflitos desnecessários em commits intermediários em comparação à consolidação em 1 commit único acordada na clarificação Q3.

---

## R2 — Ditado por Voz Estritamente Local (`onDevice: true`) e Retorno Educativo

- **Decisão**:
  1. Configurar `onDevice: true` de forma obrigatória em `SpeechListenOptions` dentro de `LeitorDeVozSpeechToText` (`app/lib/features/assistente/data/leitor_de_voz_nativo.dart`), mantendo `partialResults: true`, `listenMode: ListenMode.dictation`, `cancelOnError: true` e `localeId` em português do Brasil.
  2. Proibir qualquer fallback silencioso ou nova tentativa automática com `onDevice: false` caso o reconhecimento local falhe ou seja recusado pelo sistema operacional.
  3. **UX de Indisponibilidade (Clarificação Q2 — Opção A)**: Manter o botão *"Falar"* acessível na barra de entrada da conversa (`ControladorConversa` / `TelaConversa`) com o diálogo pedagógico prévio de microfone. Caso o aparelho não tenha pacote de fala offline em português ou recuse reconhecimento `onDevice`, retornar imediatamente `ResultadoDitado(estado: EstadoDitado.indisponivel, mensagem: ...)` com orientação clara em `TextosAssistente` indicando que o ditado offline não está disponível no aparelho e orientando a digitar pelo teclado ou baixar o pacote offline de português nas configurações do dispositivo.
  4. Manter `<uses-permission android:name="android.permission.RECORD_AUDIO"/>` no `AndroidManifest.xml` vinculada exclusivamente ao modo `onDevice: true`, sem persistência de áudio em disco nem envio de voz a terceiros.
- **Justificativa**: Atende ao Princípio I (Privacidade e Segurança Acima de Tudo) e à LGPD, impedindo envio implícito de áudio da pessoa idosa à nuvem ao mesmo tempo em que evita confundir a usuária com o desaparecimento repentino do botão de voz antes da tentativa explícita.
- **Alternativas descartadas**:
  - *Ocultar o botão de microfone na inicialização quando metadados de locale não garantirem offline*: rejeitado na clarificação Q2 porque metadados de pacotes variam entre fabricantes Android e esconderiam a explicação útil à pessoa idosa.
  - *Retentar em nuvem com aviso*: rejeitado por violar `FR-004`.

---

## R3 — Conexão do Localizador ao Backend Real, Reconciliação de Rotas e Segurança Contra Dados Inventados

- **Diagnóstico Técnico no Código Atual**:
  1. **Desconexão de composição**: `FluxoAutenticacao` (`app/lib/features/autenticacao/presentation/fluxo_autenticacao.dart`) instancia diretamente `RepositorioLocalizadorSimulado()`, enquanto `Composicao` (`app/lib/services/ambiente/composicao.dart`) ainda não resolve um `RepositorioLocalizador` e `AplicativoMemora` (`app/lib/main.dart`) não injeta essa dependência.
  2. **Divergência de caminho `/v1` vs `/api/v1` e ausência de renovação Bearer**: `Ambiente.urlBasePadrao` é `'http://10.0.2.2:8080/v1'` (já termina em `/v1`). Entretanto, `FonteLocalizadorApi` (`app/lib/features/localizador/data/fontes/fonte_localizador_api.dart`) envia `POST '/api/v1/servicos/buscar'` (resultando em `/v1/api/v1/servicos/buscar` quando usado contra `urlBasePadrao`) e não envia `Options(extra: {'secure': [{'type': 'http', 'scheme': 'bearer'}]})` nem utiliza `ChamadaComRenovacao` para renovar tokens expirados (ao contrário de `RepositorioAssistenteApi`).
  3. **Fallbacks silenciosos em duas camadas e telefones fictícios**: `RepositorioLocalizadorApi` captura exceções e retorna `RepositorioLocalizadorSimulado`, e `ProvedorOpenStreetMapOverpass` no backend retorna `obterBaseDeContingencia(...)` (Americana - SP) além de coordenada padrão fixa (`-22.7388, -47.3325`) se o Nominatim/Overpass falharem. Além disso, `RepositorioLocalizadorSimulado` possui telefones discáveis inventados (`(19) 3461-1234`, `193`, etc.).
- **Decisão**:
  1. **Reconciliação de Rotas e Autenticação**:
     - No backend (`LocalizadorController`), aceitar ambas as rotas via `@RequestMapping({"/v1/servicos", "/api/v1/servicos"})` protegidas por JWT Bearer em `ConfiguracaoDeSegurancaWeb`.
     - No app (`FonteLocalizadorApi`), normalizar o caminho relativo de `buscar`: utilizar `'/servicos/buscar'` quando `dio.options.baseUrl` terminar com `'/v1'` (ou `'/v1/'`), e `'/api/v1/servicos/buscar'` caso contrário; enviar `Options(extra: {'secure': [{'type': 'http', 'scheme': 'bearer'}]})` encapsulado opcionalmente por `ChamadaComRenovacao`.
  2. **Composição por Ambiente**:
     - Expor `RepositorioLocalizador localizador` em `Composicao` (`composicao.dart`), instanciando `RepositorioLocalizadorApi` com `api.dio` + `ChamadaComRenovacao` quando `ambiente.usaServidorReal == true` e `RepositorioLocalizadorSimulado` quando `ambiente.usaServidorReal == false`.
     - Adicionar parâmetro opcional `final RepositorioLocalizador? localizador;` em `FluxoAutenticacao`, repassar `localizador: composicao.localizador` em `AplicativoMemora` (`main.dart`), e manter `RepositorioLocalizadorSimulado()` em `FluxoAutenticacao` somente como fallback interno para testes de widget isolados que não fornecem `localizador`.
  3. **Remoção Completa de Contingência Fictícia (Clarificação Q1 — Opção A)**:
     - Remover o bloco `catch` com retorno simulado de `RepositorioLocalizadorApi`, propagando falha legível para `ControladorLocalizador.mensagemErro` com ação *"Tentar novamente"* e busca manual visíveis na `TelaLocalizador`.
     - Remover `obterBaseDeContingencia(...)` e o fallback de coordenadas fixas de Americana - SP (`-22.7388, -47.3325`) em `ProvedorOpenStreetMapOverpass`, lançando exceção explícita tratada em `LocalizadorController` como `400 Bad Request` (região não encontrada/inválida) ou `503 Service Unavailable` (provedor geográfico indisponível).
  4. **Segurança no Modo Simulado (`FR-008`)**:
     - Adicionar `final bool ehDemonstracao` (padrão `false`) em `ResultadoBuscaServicos`.
     - Em `RepositorioLocalizadorSimulado`, definir `ehDemonstracao: true`, marcar `descricaoRegiao` e `avisoTransparencia` explicitamente como demonstração/exemplo e definir `telefone: null` em todos os 5 estabelecimentos (incluindo emergência), impedindo a exibição do botão *"Ligar"* em `CartaoEstabelecimento`.
     - Exibir banner destacado e não interativo de aviso de demonstração na `TelaLocalizador` sempre que `ehDemonstracao == true`.
     - Ajustar `app/test/features/localizador/acoes_seguras_test.dart` para usar uma fixture explícita de `EstabelecimentoServico` com telefone no teste do diálogo de ligação, mantendo a cobertura da confirmação segura sem reintroduzir telefone discável no `RepositorioLocalizadorSimulado`.
- **Alternativas descartadas**:
  - *Manter base de contingência marcada com flag em servidor real*: descartado na clarificação Q1 e proibido pela revisão para evitar apresentar Americana - SP a usuárias de outras cidades.
  - *Alterar `Ambiente.urlBasePadrao` para remover `/v1`*: rejeitado porque `MemoraApi` (OpenAPI client) depende de `urlBasePadrao` terminando em `/v1`.

---

## R4 — Transparência OpenStreetMap, Nomenclatura Honesta, Status das Specs e CI

- **Decisão**:
  1. **Consentimento Transparente (`FR-009`)**: Atualizar tanto o texto de `DialogoPermissaoLocalizacao` (`dialogo_permissao_localizacao.dart`) quanto a orientação do modal `_solicitarRegiaoManual` (`tela_localizador.dart`) para explicar em linguagem simples que a localização ou região digitada é enviada apenas durante a consulta para pesquisar pontos públicos no **OpenStreetMap**, sem gravar histórico no Memora e sem enviar nome, e-mail ou dados pessoais da conta.
  2. **Conformidade Nominatim/Overpass (`FR-010`)**: Em `ProvedorOpenStreetMapOverpass.java`:
     - Configurar header `User-Agent` identificável e específico do projeto (ex.: `Memora-Fatec/1.0 (+https://github.com/Edudu720/Memora)`).
     - Introduzir limitador de taxa thread-safe em fila sincronizada para chamadas ao Nominatim garantindo espaçamento mínimo de `1000 ms` (`<= 1 req/s`), com abstração/relógio injetável para testes unitários determinísticos e rápidos, preservando timeouts explícitos (`5s` conexão/Nominatim e `6s` HTTP / `5s` query Overpass).
     - Tornar as URLs base (Nominatim e Overpass) configuráveis/injetáveis no construtor para testes unitários sem dependência de rede externa real.
  3. **Nomenclatura Honesta (`FR-011`)**: Renomear `InterpretadorDeIntencaoComGemini` (`InterpretadorDeIntencaoComGemini.java` e `InterpretadorDeIntencaoComGeminiTest.java`) para `InterpretadorDeIntencaoPorPalavrasChave`, atualizando as injeções em `ServicoLocalizador.java` e `ServicoLocalizadorTest.java` (zero referências restantes ao nome antigo no backend e nas novas referências ativas).
  4. **Higiene de Specs (`FR-012`)**: Atualizar explicitamente os metadados de `Status` nos arquivos `specs/006-guias-servicos-sociais/spec.md`, `specs/007-redesenho-visual-profissional/spec.md` (`Implementado — mesclado em develop`) e `specs/009-localizador-servicos/spec.md` (`Em Revisão — PR #71`), incluindo nesta última nota de reconciliação declarando que o classificador por palavras-chave (`FR-011`) substituiu as citações originais ao Gemini.
  5. **Integridade do CI (`.github/workflows/verificacao.yml`, `FR-013`)**: Manter `flutter-version: '3.47.7'` nos jobs `app` e `cliente-gerado` (corrigindo eventual chave YAML duplicada herdada), executar `flutter analyze` estrito (removendo `--no-fatal-infos`), manter `dart analyze` + `dart test` em `cliente-gerado`, bem como os portões `validar_paleta.py`, `validar_tokens.py` e `./mvnw --batch-mode test`.
