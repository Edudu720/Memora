# Changelog

Todas as mudanças notáveis do aplicativo **Memora** são documentadas neste arquivo.

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
