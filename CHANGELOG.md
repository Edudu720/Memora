# Changelog

Todas as mudanças notáveis do aplicativo **Memora** são documentadas neste arquivo.

## [Unreleased] — Feature `021-analise-golpes`

### Adicionado
- **Análise antigolpes de links e mensagens estranhas (`specs/021-analise-golpes/`, `POST /v1/golpes/analisar`, `TelaAnaliseGolpe`)**:
  - Tela dedicada acessível em 1 toque a partir da `TelaInicio` (`TelaInicio.chaveVerificarGolpe`) e pela `TelaAjuda` (`TelaAjuda.chaveVerificarGolpe`), mantendo o Hub com 7 portas (`FR-017`).
  - Endpoint autenticado `POST /v1/golpes/analisar` no backend com motor heurístico determinístico (`AnalisadorDeterministicoDeGolpes`), integração Gemini REST (`ClienteAnaliseGolpeGemini`), sanitizador pós-IA com piso monotônico (`SanitizadorRespostaAntigolpe`) e limitador de taxa por conta (`LimitadorAnaliseGolpe`).
  - Fallback local offline automático no aplicativo (`AnalisadorLocalDeGolpes` e `RepositorioAnaliseGolpeApi`) quando sem conexão ou diante de indisponibilidade do servidor.
- **Passo 5 do guia do WhatsApp (`CapturaDoGuia.whatsapp5`, `whatsappPasso5`)**:
  - Nova captura higienizada e anotada dentro da conversa do WhatsApp com 4 regiões numeradas e textos explicativos.

### Alterado
- **Guias visuais anotados em azul Memora acessível (`#1040F8`) e espaçamento de legendas (`scripts/processar_guias_visuais.py`, `PassoIlustrado`, `TelaPassoAPasso`)**:
  - Círculos e selos numerados nos guias legados passam a utilizar o azul acessível `#1040F8` com posicionamento anti-colisão e folga ampliada entre imagem e legenda na tela passo a passo.

## [Unreleased] — Feature `020-modulo-concluido-e-ultimo-aprendido`

### Adicionado
- **Módulo concluído no Catálogo (`TelaCatalogo`, `estado_do_modulo.dart`)**:
  - Função pura de domínio `moduloConcluido` que marca módulos com selo informativo `"Concluído"` (`BadgeDeStatus` `readOnly`) somente após todas as seções (em guias seccionados) ou o guia inteiro (em guias diretos) serem concluídos.
  - Integração de `progresso` e `idDaConta` em `FluxoAutenticacao._abrirCatalogo` com atualização ao vivo via `ProgressoDeAprendizado.alteracoes`.
- **Checkbox verde arredondado no seletor de seções (`TelaSeletorDeSecao`)**:
  - Cada seção concluída passa a exibir um checkbox verde arredondado à direita construído exclusivamente com tokens do Design System (`cores.sucesso`, `MemoraDimensoes.iconeDestaque`, `MemoraRaio.balaoPonta`, `Icons.check_rounded`), combinado com o texto `"Já aprendeu"` e anúncio `"Concluído."` no TalkBack (`secaoConcluidaDescrita`).
- **Ligação de progresso na subida do app (`main.dart`)**:
  - `AplicativoMemora` passa a repassar `progresso: composicao.progresso` diretamente para `FluxoAutenticacao`, habilitando em produção o selo `"Concluído"` no catálogo e os indicadores locais de aprendizado no Perfil.
- **Campo `"Último aprendizado"` em Meu Perfil (`TelaPerfil`)**:
  - Novo `CampoInformacao` puramente informativo (`TelaPerfil.chaveUltimoAprendido`) calculado 100% localmente a partir de `ProgressoDeAprendizado.ordensDeConclusao` e `chaveDoUltimoModuloConcluido`, respeitando `FR-042a` (zero rede) e `FR-042b` (limpeza ao sair), com atualização reativa dentro da `CascaInterna`.
  - Conciliado com o redesenho semântico da feature `016` dentro da seção dedicada *Seu aprendizado* (`TelaPerfil.chaveSecaoAprendizado`, `Semantics(header: true)`), substituindo o slot provisório (`chaveUltimoModulo` / `ultimoModuloConcluido`), usando busca de nomes em `O(1)` (`_nomesDoCatalogo`), guarda de corrida `_versaoCarga`, tratamento `try/catch` e carregamento acessível (`TextosPerfil.carregandoAprendizado` em vez de `'...'`).

## [Unreleased] — Feature `019-icones-svg-tutoriais`

### Alterado
- **Ícones SVG de aplicativos (`specs/019-icones-svg-tutoriais/`, `#106` Item 13)**: criados os ícones vetoriais `app/assets/icones_apps/e-titulo.svg`, `fgts.svg` e `instagram.svg` (`viewBox="0 0 48 48"`), unificados no mapa de SVGs de `IconeDoAplicativo` (com dobra de acentos para `e-Título`) e documentados em `LICENCAS.md`.

## [Unreleased] — Feature `018-estabilidade-gemini`

### Melhorado
- **Estabilidade da API do Gemini (`specs/018-estabilidade-gemini/`, `#106` Item 12)**:
  - Alinhado o modelo principal padrão para `gemini-3.6-flash` no código (`ConfiguracaoDoProvedorDeIa`, `application.properties`) e no `render.yaml`.
  - Adicionada retentativa curta configurável (`tentativas-primario=2`, `espera-retentativa-ms=500`) para falhas transitórias (`5xx`, rede, prazo) e modelo reserva automático configurável (`MEMORA_ASSISTENTE_GEMINI_MODELO_RESERVA=gemini-3.5-flash-lite`) acionado apenas antes da entrega do primeiro trecho em `429` ou esgotamento de tentativas do principal, preservando `systemInstruction`, ferramentas, cabeçalho seguro e descarte de erros externos.

## [Unreleased] — Feature `017-site-no-render`

### Adicionado
- **Site tutorial no Render (`specs/017-site-no-render/`, `#106` Item 14b)**: declarado o serviço estático `memora-site` no `render.yaml` (`runtime: static`, `staticPublishPath: site`, filtro de caminhos isolado e cabeçalhos `Content-Security-Policy`, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy` e `Permissions-Policy`), além da atualização de `docs/deploy/render.md` com instruções de publicação e repasse da URL `https://` ao Item 11.

## [Unreleased] — Feature `016-ajustes-pos-redesenho`

### Adicionado
- **Site oficial de tutoriais na Ajuda (`US5`, `#106` Item 11)**: configuração opcional por `--dart-define=MEMORA_URL_SITE_TUTORIAL` validada via `Ambiente.enderecoOficial` (exclusivo `https://`), `AbridorDeSiteTutorial` e cartão dedicado com diálogo modal rolável de confirmação anti-phishing em `TelaAjuda`, mantido oculto enquanto não houver URL oficial configurada.
- **Ícones vetoriais compartilhados (`US3`, `#106` Item 6)**: criação de 7 SVGs autocontidos em `app/assets/icones_apps/` (`meu-inss`, `tiktok`, `carteira-digital`, `carteira-de-trabalho`, `poupatempo`, `youtube`, `google-fotos`) carregados via `SvgPicture.asset` em `IconeDoAplicativo`.
- **Slot de progresso em Meu Perfil (`US4`, `#106` Item 14)**: suporte opcional `ultimoModuloConcluido` com campo informativo acessível em `TelaPerfil`.

### Alterado
- **Dispositivo de Cuidado (`US1`, `#106` Itens 7 e 8)**: `ControladorDispositivoCuidado.simularQuedaTeste()` passa a disparar a verificação local de queda com segurança também no modo ESP32 físico via MQTT (conectado ou desconectado), com ciclo de vida proprietário em `_DonoDoDispositivoCuidado` (descarte garantido ao sair da conta/expirar sessão), guarda `_descartado` pós-`await`, trava contra toques repetidos e limpeza completa de referências residuais ao Wokwi em `app/`.
- **Guias passo a passo com capturas reais (`US3`, `#106` Item 5)**: atualização de 7 guias (`meu-inss`, `tiktok`, `carteira-digital`, `carteira-de-trabalho`, `poupatempo`, `youtube`, `google-fotos`) com 66 capturas reais higienizadas em WebP qualidade 92, destaques `RegiaoRelativa` medidos sobre as imagens limpas, divisão em seções `SecaoDoGuia` para guias com mais de 7 telas, atualização de `CAPTURAS.md` e revisão do teto global de `app/assets/guias/` para `12 MB`.
- **Meu Perfil (`US4`, `#106` Item 10)**: reorganização semântica por seções em cartões (*Seu retrato*, *Sua conta*, *Seu aprendizado* e `SecaoIdade`), busca de títulos do catálogo em `O(1)`, tratamento resiliente de erro local (`try/catch`), descarte de leituras assíncronas obsoletas em troca de conta e eliminação do marcador provisório `'...'`.

### Removido
- **Retratos descontinuados (`US2`, `#106` Item 9)**: remoção de `casalIdoso` e `pessoaComCelular` da seleção de retrato de perfil com recuo seguro para o retrato padrão neutro caso o armazenamento local ainda traga chaves antigas.

## [0.7.0] — Feature `007-redesenho-visual-profissional`

### Adicionado
- **Tokens 2.0 no Design System (`app/lib/design_system/tokens/`)**:
  - Novas cores semânticas por tema e paleta (`superficieSutil`, `superficieBarra`, `bordaSutil`, `gradienteHeroiInicio`/`Fim`, `sobreGradienteHeroi`, `gradienteSaudeInicio`/`Fim`, `sobreGradienteSaude`, `saudeSuave`, `sucessoTexto`).
  - Novas dimensões e raios para grades responsivas e superfícies (`badgeAtalhoRapido`, `espessuraBordaSutil`, `indicadorAtivoBarra`, `escalaColapsoGrade`, `larguraMinimaGrade`, `MemoraRaio.cartaoMedio`, `MemoraRaio.cartaoDestaque`, `MemoraRaio.badge`).
  - Auxiliares de elevação `MemoraElevacao.listaSombrasCartao` e `MemoraElevacao.listaSombrasBarra` (com contorno reforçado no tema Alto Contraste e zero sombras soltas).
- **Novos componentes padronizados (`app/lib/design_system/componentes/`)**:
  - `PainelHeroi`: painel informativo com algarismos tabulares e **sem** callback de toque (`002/FR-012`).
  - `CartaoHeroi`: cartão interativo em destaque para a ação principal de uma tela.
  - `TileAcaoRapida`: atalho de grade com badge de `48 dp` (`VarianteBadge`) e pista explícita de toque.
  - `ChipFiltro`: pastilha de filtro interativa em formato pílula com alvo mínimo `48 dp` e duplo sinal visual de seleção.
  - `BadgeDeStatus`: selo compacto estritamente informativo (`TomBadgeStatus.positivo`, `atencao`, `informativo`, `neutro`).
  - `LinhaDeLista`: linha de lista padronizada com separação estrita entre modo informativo (`aoTocar == null`) e navegável (`aoTocar != null`).
- **Mascote unificado (`MemoraPersonagem` / `ExpressaoDaMemora`)**:
  - Adição das expressões `ExpressaoDaMemora.dica` (`memora_dica_robo.png`) e `ExpressaoDaMemora.mini` (`memora_mini_robo.png`), unificando o uso das 6 artes oficiais em alta resolução em `assets/ilustracoes/`.
- **Ditado por voz na Conversa (`FR-013`, `app/lib/features/assistente/`)**:
  - Contrato de domínio `LeitorDeVoz`, estados `EstadoDitado` / `ResultadoDitado` e implementação nativa `LeitorDeVozSpeechToText` via `speech_to_text` com preferência `pt_BR`.
  - Diálogo prévio explicando a permissão de microfone na primeira tentativa, faixa acessível de estado (`liveRegion`) e transcrição exclusiva para o rascunho sem envio automático nem gravação em disco.

### Alterado
- **Redesenho visual completo mantendo WCAG 2.2 AA/AAA e `002/FR-012`**:
  - `Cartao`, `CaixaDeEtapa`, `BarraSuperior` e `NavegacaoInferior` evoluídos com fundo canvas `#F4F6FA` (modo Claro), superfícies elevadas `#FFFFFF`, separação por elevação/espaçamento em vez de bordas pesadas de wireframe, mantendo contornos `>= 3:1` automáticos no Alto Contraste.
  - **Início & Hub (`TelaHub`)**: saudação com o robô Memora, `CartaoHeroi` para conversa, grade responsiva 2x2 de `TileAcaoRapida` e colapso automático para 1 coluna em fontes ampliadas (`>= 1.5x`) ou telas estreitas (`320 dp`), além de suporte ao menu de atalhos.
  - **Conversa (`TelaConversa`), Catálogo (`TelaCatalogo`), Registro (`TelaRegistro`) e Guias (`TelaGuia`, `SecaoGuiasSociais`)**: grade `2x2` de sugestões após o aceite obrigatório (`Emenda 1`), `BalaoDeFala` com mini-robô, barra elevada com ditado por voz, `ChipFiltro` nos filtros e selos informativos padronizados.
  - **Saúde & Cuidado (`TelaDispositivoCuidado`, `TelaVerificacaoQueda`, `MedidorBpm`, `IndicadorMovimento`, `CronometroRegressivoQueda`)**: `PainelHeroi` não clicável com BPM tabular, leitura visual limpa com `BadgeDeStatus`, acesso rápido ao contato de emergência e tela de queda com botões de decisão separados (`>= 56 dp`).
  - **Apresentação, Autenticação, Ajuda, Ajustes, Aparência e Perfil**: `FluxoApresentacao` com indicadores em pílula e CTA no rodapé; `AvisoAntigolpe` e `RegrasDeSenha` com `BadgeDeStatus`; `TelaAjuda`, `TelaConfiguracoes`, `TelaConta`, `TelaPrivacidade`, `TelaPerfil` e `SecaoIdade` agrupados em cartões limpos com `LinhaDeLista`; `TelaAparencia` com pré-visualização ao vivo dos 3 temas × 6 paletas.

### Verificado
- Portões automáticos de design system: `validar_tokens.py` (`FR-032`) e `validar_paleta.py` (WCAG 2.2 nos 3 temas × 6 paletas).
- Documentação viva atualizada em `docs/design/como-usar-o-design-system.md`.
