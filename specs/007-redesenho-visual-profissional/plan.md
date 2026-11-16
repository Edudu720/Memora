# Plano de Implementação: Redesenho Visual, Padronização Profissional e Voz na Conversa

**Branch**: `feature/007-redesenho-visual-profissional` | **Data**: 2026-11-13 (revisado pós-Clarify & Analyze) | **Spec**: [spec.md](file:///c:/Users/Edu/Documents/Memora/specs/007-redesenho-visual-profissional/spec.md)  
**Input**: Especificação esclarecida em `specs/007-redesenho-visual-profissional/spec.md`, referências em `Memora-Desing-Ideias/` e decisões de `research.md`.

---

## Resumo Executivo

Transformar completamente a identidade visual do aplicativo Memora para um padrão profissional, acolhedor e altamente coeso — cruzando todas as 6 referências de `Memora-Desing-Ideias/` — e incorporar **ditado por voz seguro (`FR-013`)** na conversa com a Memora, mantendo 100% dos invariantes constitucionais de acessibilidade sênior, proteção antigolpe e arquitetura Clean/Feature-First:

1. **Fundação no Design System (Tokens 2.0 + Componentes)**: substituir superfícies cinzas (`#D8D8D8`) e bordas de wireframe (`#6B6B6B`) em cartões passivos por canvas frio suave (`#F4F6FA`) + cartões brancos elevados (`#FFFFFF`) com sombras difusas, expor tokens de gradiente auditáveis pela suíte WCAG nas 6 paletas, estender retrocompatibilmente `ExpressaoDaMemora` adicionando `dica` e `mini` aos 4 membros já existentes, manter `Cartao` e `PainelHeroi` estritamente não clicáveis (`002/FR-012`), e criar `CartaoHeroi`, `TileAcaoRapida`, `ChipFiltro`, `BadgeDeStatus` e `LinhaDeLista`.
2. **Ditado por Voz Seguro na Conversa (`FR-013`)**: integrar `speech_to_text: ^7.3.0` sob abstração Clean Architecture (`LeitorDeVoz`), declarar `RECORD_AUDIO` e `<queries>` `RecognitionService` no `AndroidManifest.xml`, explicar o uso do microfone antes da permissão do sistema (Princípio II), e preencher apenas o rascunho de mensagem para conferência e envio manual em `"Perguntar"`.
3. **Padronização Tela a Tela (35+ telas)**: migrar todas as features preservando os **3 destinos fixos** da `CascaInterna` (`Ajustes`, `Início`, `Meu perfil`), a etapa constitucional prévia `_ExplicacaoDoAceite` em `TelaConversa` (Emenda 1), todas as `Key`s e testes existentes, documentação viva (`CHANGELOG.md` / `docs/`) e validação final via `album_de_telas_test.dart` nos 3 temas + `flutter build apk --release`.

---

## Contexto Técnico

**Linguagem / Versão**: Dart SDK `^3.11.4` / Flutter (`app/`), Python 3 (`specs/002-design-system/ferramentas/validar_tokens.py` e `validar_paleta.py`)  
**Dependências Principais**: Design System interno (`app/lib/design_system/`), `AtkinsonHyperlegibleNext`, `flutter_svg`, `speech_to_text: ^7.3.0` (nova dependência direta em `app/pubspec.yaml` para `FR-013`).  
**Android Manifest**: Declaração de `android.permission.RECORD_AUDIO` + `<queries><intent><action android:name="android.speech.RecognitionService"/></intent></queries>` em `app/android/app/src/main/AndroidManifest.xml`.  
**Armazenamento / Backend**: Sem alterações no backend Spring Boot nem em banco de dados; zero áudio persistido em disco.  
**Testes & Portões**: `validar_tokens.py`, `validar_paleta.py`, `flutter analyze`, `flutter test` (inclui novo teste de ditado por voz com `FakeLeitorDeVoz`), `album_de_telas_test.dart` nos 3 temas e `flutter build apk --release`.  
**Plataforma Alvo**: Android (resoluções padrão `320×568` e `360×800`, escalas `1.0x` até `2.0x`).  
**Escopo**: Tokens/componentes DS (`app/lib/design_system/`) + serviço e UI de ditado por voz (`app/lib/features/assistente/`) + padronização de todas as features (~35 telas/widgets) + documentação viva.

---

## Constitution Check (Verificação de Portões)

*Avaliado antes da Fase 0 e revalidado após a Fase 1 revisada com Clarify & Analyze.*

| Princípio da Constituição | Status Pre-Design | Status Pós-Fase 1 | Como é garantido no Plano |
| :--- | :--- | :--- | :--- |
| **I. Segurança e Privacidade (Emenda 1)** | Aprovado | Aprovado | `_ExplicacaoDoAceite` permanece obrigatória antes da primeira mensagem em `TelaConversa`; zero gravação ou log de áudio do microfone; Threat Modeling por tela documentado em `spec.md` §2.1. |
| **II. Proteção contra Engenharia Social** | Aprovado | Aprovado | Explicação clara em linguagem simples antes de pedir permissão `RECORD_AUDIO`; voz preenche apenas rascunho sem envio automático; `AvisoCompacto` permanece não dispensável no topo da conversa. |
| **III. Acessibilidade Sênior & WCAG 2.2** | Aprovado | Aprovado | `Cartao`, `PainelHeroi` e `BadgeDeStatus` estritamente não clicáveis (`002/FR-012`); cards de ação exigem pista visual explícita; 3 abas mantidas na barra inferior para caber em `320 px` a `200%`; botão `"Falar"`/`"Parar"` com ícone+texto `>= 48 dp`; gradientes validados em ambos os stops em `validar_paleta.py`. |
| **IV. Spec-Driven & Contratos Primeiro** | Aprovado | Aprovado | `spec.md` esclarecida (5 Q→A) + `research.md` + `data-model.md` + `contracts/` sincronizados com todas as correções do `/speckit-analyze`. |
| **V. Clean Architecture & Feature-First** | Aprovado | Aprovado | Zero literais visuais fora de `tokens/`; interface de domínio `LeitorDeVoz` isolada da implementação `speech_to_text` em `data/`; widgets novos isolados no Design System via `design_system.dart`. |
| **VI & VII. IA Segura / Ensinar sem Substituir** | Aprovado | Aprovado | Sugestões iniciais e ditado nunca disparam ações nem mensagens sem toque explícito da pessoa; selo `"✓ Eu te ensino e posso abrir"` e guias da feature 006 destacados. |

**Resultado**: Nenhum desvio da Constituição.

---

## Estrutura do Projeto

### Documentação da Feature (`specs/007-redesenho-visual-profissional/`)

```text
specs/007-redesenho-visual-profissional/
├── spec.md                              # Diagnóstico, 6 referências, Clarifications (5 Q->A), Threat Model, US1–US7, FR-001–FR-013, SCs
├── plan.md                              # Este arquivo
├── research.md                          # Decisões D1–D6 (Tokens, Gradientes, Mascote, FR-012, Voz STT, Responsividade)
├── data-model.md                        # MemoraCores/Raio/Elevacao/Dimensoes, ExpressaoDaMemora, EstadoDitado & LeitorDeVoz
├── quickstart.md                        # Portões estáticos, testes unitários/voz/acessibilidade, album nos 3 temas e APK release
└── contracts/
    ├── design-system-redesign.md        # Contratos DS (Cartao sem aoTocar, PainelHeroi vs CartaoHeroi, tipografia U3)
    └── telas-padronizacao.md            # Blueprint tela a tela (3 abas na Casca, _ExplicacaoDoAceite + voz na Conversa, Cuidado, etc.)
```

### Código-Fonte e Documentação Impactados

```text
specs/002-design-system/ferramentas/
└── validar_paleta.py                    # Validação dos novos tokens e stops de gradiente nas 13 combinações

app/pubspec.yaml                         # Adiciona dependência `speech_to_text: ^7.3.0`
app/android/app/src/main/AndroidManifest.xml # RECORD_AUDIO + <queries> RecognitionService

app/lib/design_system/
├── tokens/
│   ├── cores.dart                       # fundo #F4F6FA, superficieSutil, superficieBarra, bordaSutil, gradientes + 6 paletas
│   ├── raio.dart                        # Mantém cartao (24.0), adiciona cartaoDestaque (24.0), cartaoMedio (20.0), badge (14.0)
│   ├── elevacao.dart                    # Sombras difusas duas camadas + barra (zero sombra em altoContraste)
│   └── dimensoes.dart                   # badgeAtalhoRapido, espessuraBordaSutil, indicadorAtivoBarra
├── componentes/
│   ├── ilustracao/memora_personagem.dart# Mantém neutra/falando/comemorando/preocupada + adiciona dica e mini
│   ├── informacao/
│   │   ├── painel_heroi.dart            # [NOVO] Herói informativo não clicável (Cuidado Saúde)
│   │   ├── badge_de_status.dart         # [NOVO] Selo informativo sem ação
│   │   ├── linha_de_lista.dart          # [NOVO] Item horizontal (informativo se aoTocar == null; chevron se clicável)
│   │   └── destaque_informacao.dart / lista_informacao.dart
│   ├── cartoes/
│   │   ├── cartao.dart                  # Sem borda pesada no Claro; estritamente não clicável (sem aoTocar)
│   │   ├── caixa_de_etapa.dart          # Visual editorial limpo mantendo Semantics intacta
│   │   ├── cartao_heroi.dart            # [NOVO] Herói clicável com pista explícita de ação (Início / Hub)
│   │   ├── tile_acao_rapida.dart        # [NOVO] Card de grade 2x2 com badge tonal + pista explícita de ação
│   │   └── cartao_de_porta.dart / cartao_com_avatar.dart
│   ├── selecao/chip_filtro.dart         # [NOVO] Pílulas segmentadas acessíveis
│   ├── navegacao/                       # navegacao_inferior.dart (3 destinos elevados), cabecalho_de_tela.dart, barra_superior.dart
│   ├── conversa/balao_de_fala.dart      # Balões limpos com mini-robô
│   └── avisos/aviso_compacto.dart       # Pill expansível no topo da conversa
├── galeria/galeria_memora.dart          # Inclui novos componentes + 6 poses PNG do robô
└── design_system.dart                   # Reexporta os novos componentes

app/lib/features/
├── casca/casca_interna.dart             # 3 destinos mantidos + integração limpa com NavegacaoInferior
├── inicio/presentation/tela_inicio.dart # Saudação + CartaoHeroi + grade 2x2 TileAcaoRapida
├── hub/presentation/telas/tela_hub.dart # Grid limpo mantendo hub_cabe_sem_rolar_test
├── assistente/
│   ├── domain/leitor_de_voz.dart        # [NOVO] Interface LeitorDeVoz & EstadoDitado (FR-013)
│   ├── data/leitor_de_voz_nativo.dart   # [NOVO] Implementação speech_to_text (pt_BR)
│   ├── presentation/controladores/controlador_conversa.dart # Orquestração opcional do ditado no rascunho
│   └── presentation/telas/              # tela_conversa (_ExplicacaoDoAceite + sugestões 2x2 + voz segura), tela_catalogo, tela_registro
├── aprendizado/presentation/            # tela_seletor_de_secao.dart, tela_passo_a_passo.dart
├── cuidado/presentation/                # tela_dispositivo_cuidado (PainelHeroi + MQTT recolhido), tela_verificacao_queda, widgets/
└── apresentacao/, autenticacao/, ajuda/, configuracoes/, perfil/

app/lib/l10n/textos_assistente.dart        # Novos rótulos do Início e ditado por voz (FR-013)
CHANGELOG.md / docs/                     # Atualização da documentação viva (Constituição)
```

---

## Fases de Execução (Base para `/speckit-tasks`)

1. **Fase 1 — Tokens 2.0 & Portões de Contraste**: atualizar `cores.dart` (3 modos × 6 paletas), `raio.dart`, `elevacao.dart`, `dimensoes.dart`, `temas_memora.dart`, estender `validar_paleta.py` e `contraste_test.dart`.
2. **Fase 2 — DS 2.0 & Mascote Unificado**: evoluir componentes existentes (`Cartao` não clicável, `CaixaDeEtapa`, `NavegacaoInferior` em 3 destinos, `CabecalhoDeTela`, `ExpressaoDaMemora` + `dica`/`mini`), criar `PainelHeroi`, `CartaoHeroi`, `TileAcaoRapida`, `ChipFiltro`, `BadgeDeStatus`, `LinhaDeLista`, expor em `design_system.dart` e atualizar `GaleriaMemora` com os novos blocos e todas as 6 poses do robô.
3. **Fase 3 — Core P1 (`CascaInterna`, `Início`, `Hub`, `Conversa + Ditado por Voz FR-013`, `Cuidado`)**: configurar `speech_to_text` + `AndroidManifest.xml`, implementar `LeitorDeVoz` / `FakeLeitorDeVoz`, redesenhar Início/Hub, Conversa (preservando `_ExplicacaoDoAceite` + pílula `AvisoCompacto` + sugestões 2x2 + ditado com explicação de permissão sem auto-envio) e Cuidado (`PainelHeroi` não clicável + grade + alerta de queda).
4. **Fase 4 — Cobertura P2 (`Catálogo`, `Aprendizado`, `Apresentação`, `Autenticação`, `Ajuda`, `Configurações`, `Perfil`)**: padronizar todas as demais telas seguindo `contracts/telas-padronizacao.md`.
5. **Fase 5 — Auditoria Global, Documentação Viva & APK Release (`SC-001`–`SC-006`)**: `validar_tokens.py`, `validar_paleta.py`, `flutter analyze`, `flutter test`, atualizar `CHANGELOG.md`/docs, regenerar e inspecionar `album_de_telas_test.dart` nos 3 temas e compilar `flutter build apk --release`.

---

## Complexidade / Exceções à Constituição

Nenhuma exceção solicitada: todas as evoluções de UI e a inclusão do ditado por voz (`FR-013`) seguem estritamente os Princípios I–VII, Emenda 1 e WCAG 2.2 AA/AAA.
