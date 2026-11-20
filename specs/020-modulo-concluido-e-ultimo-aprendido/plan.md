# Plano de Implementação: Módulo Concluído, Checkbox de Seção e Último Módulo Concluído

**Branch**: `feature/020-modulo-concluido-e-ultimo-aprendido` | **Date**: 2026-11-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/020-modulo-concluido-e-ultimo-aprendido/spec.md`

## Summary

Implementar integralmente o Item 14a da Issue #106 sem quebrar contratos de acessibilidade, privacidade (`FR-042a/b`) nem fluxos existentes:
1. Estender `ProgressoDeAprendizado` (`data`) com stream broadcast `alteracoes` (emitida após gravação em `registrarConclusao` e remoção em `apagar`) e leituras locais `ordensDeConclusao` / `ultimoConcluido`.
2. Criar funções puras de domínio em `app/lib/features/aprendizado/domain/estado_do_modulo.dart` (`moduloConcluido` e `chaveDoUltimoModuloConcluido`) garantindo que módulos divididos em seções só sejam considerados concluídos quando **todas** as seções tiverem conclusão registrada, usando a maior `ordem` entre suas seções para desempate cronológico.
3. Atualizar `TelaCatalogo` (conectada a `progresso` e `idDaConta` em `FluxoAutenticacao._abrirCatalogo`) para exibir o `BadgeDeStatus` informativo `"Concluído"` quando o módulo estiver completo e reagir a `alteracoes`.
4. Atualizar `TelaSeletorDeSecao` para exibir o checkbox verde arredondado construído estritamente com tokens do Design System (`cores.sucesso`, `MemoraDimensoes.iconeDestaque`, `MemoraRaio.balaoPonta`, `Icons.check_rounded` com contraste > 6,5:1 nos três temas), combinado com texto `Já aprendeu`, semântica TalkBack `"Concluído."` e atualização ao vivo via `alteracoes`.
5. Atualizar `TelaPerfil` com o `CampoInformacao` puramente informativo `TelaPerfil.chaveUltimoAprendido` (`"Último aprendizado"`), preservando `TelaPerfil.chaveMaisAprendido`, compartilhando helper de resolução de nome legível e atualizando ao vivo dentro da `CascaInterna`.

## Technical Context

**Language/Version**: Dart 3.13.5 / Flutter 3.47.7
**Primary Dependencies**: Flutter SDK (`flutter/material.dart`), `memora/design_system/design_system.dart`, `dart:async` (`StreamController`, `StreamSubscription`), `dart:convert`, `dart:io`, `path_provider`
**Storage**: Arquivo JSON privado local `progresso_de_aprendizado.json` gerenciado por `ProgressoDeAprendizado` (`DadoLocalDaPessoa`, zero rede)
**Testing**: `flutter test`, `flutter analyze`, `py specs/002-design-system/ferramentas/validar_tokens.py`
**Target Platform**: Android (mobile, matriz `4 × 3` até 200% de escala de fonte, temas Claro, Escuro e Alto Contraste)
**Project Type**: Mobile app Flutter (Feature-First + Clean Architecture)
**Performance Goals**: Atualização reativa em memória após I/O serializado em fila, sem polling, sem rebuild desnecessário de árvore nem bloqueio de thread principal
**Constraints**:
- ZERO valores literais de cor/tamanho/espaçamento/raio em `app/lib/` fora de `tokens/` (`validar_tokens.py`)
- Todos `Icons.<nome>` em `app/lib/` terminando em `_rounded` (`icones_e_toque_test.dart`)
- Todos textos de `app/lib/l10n/` com `<= 2` frases curtas, zero emojis, gênero neutro, zero palavras proibidas (`texto_da_interface_test.dart`, `sem_planos_test.dart`)
- Features importam apenas `design_system/design_system.dart`
- Nenhuma chamada HTTP em `ProgressoDeAprendizado` (`FR-042a`) e apagamento total ao sair (`FR-042b`)

## Constitution Check

*GATE: Checked before Phase 0 and re-checked after Phase 1.*

- **I. Segurança Acima de Tudo**: APROVADO. Threat Model documentado na `spec.md`; histórico permanece 100% local indexado por conta e apagado em toda saída via `LimpezaDeSessao`, agora também limpo reativamente em telas vivas via `alteracoes`.
- **II. Engenharia Social**: APROVADO. Nenhum selo ou campo informativo ganha ação/chevron/InkWell (`002/FR-012`); linguagem literal sem jargão nem termos de plano (`US9`).
- **III. Acessibilidade**: APROVADO. Checkbox verde arredondado (`28 dp`) com contraste > 6,5:1 em todos os 3 temas (`6.6:1` Claro, `10.7:1` Escuro, `13.1:1` Alto Contraste), nunca portador único de estado (combinado com `Já aprendeu` e rótulo TalkBack `Concluído.`), alvos intactos `>= 48 dp`, matriz `4 × 3` até 200% testada.
- **IV. Spec antes de Código**: APROVADO. Fluxo SpecKit completo antes de editar código Dart.
- **V. Arquitetura Limpa & Feature-First**: APROVADO. Lógica pura de conclusão/ordenação isolada em `domain/estado_do_modulo.dart` sem dependências de Flutter UI; persistência encapsulada em `data/progresso_de_aprendizado.dart`; apresentação apenas reage e compõe componentes do Design System.
- **VI & VII. Autonomia & Não-substituição**: APROVADO. Valoriza explicitamente cada etapa concluída pela própria pessoa sem automação oculta.

## Project Structure

### Documentation (this feature)

```text
specs/020-modulo-concluido-e-ultimo-aprendido/
├── spec.md                              # Especificação funcional, Threat Model e Clarifications
├── plan.md                              # Este plano (/speckit-plan)
├── research.md                          # Achados técnicos, contraste e estratégia reativa
├── data-model.md                        # Entidades de progresso e avaliação de conclusão
├── quickstart.md                        # Guia rápido de validação local e matriz
├── contracts/
│   └── progresso-e-modulos.md           # Contrato público entre data, domain, telas e testes
├── checklists/
│   └── requirements.md                  # Checklist de qualidade da spec
└── tasks.md                             # Lista ordenada de tarefas (/speckit-tasks)
```

### Source Code (repository root)

```text
app/
├── lib/
│   ├── features/
│   │   ├── aprendizado/
│   │   │   ├── data/
│   │   │   │   └── progresso_de_aprendizado.dart
│   │   │   ├── domain/
│   │   │   │   └── estado_do_modulo.dart              # [NOVO] regras puras de módulo concluído
│   │   │   └── presentation/
│   │   │       └── tela_seletor_de_secao.dart
│   │   ├── assistente/
│   │   │   └── presentation/telas/
│   │   │       └── tela_catalogo.dart
│   │   ├── autenticacao/
│   │   │   └── presentation/
│   │   │       └── fluxo_autenticacao.dart
│   │   └── perfil/
│   │       └── presentation/
│   │           └── tela_perfil.dart
│   └── l10n/
│       ├── textos_guias.dart
│       └── textos_perfil.dart
└── test/
    └── features/
        ├── aprendizado/
        │   ├── progresso_de_aprendizado_test.dart
        │   └── tela_seletor_de_secao_test.dart
        ├── assistente/
        │   └── catalogo_modulo_concluido_test.dart    # [NOVO]
        └── perfil/
            └── tela_perfil_test.dart
```

**Structure Decision**: Expansão direta na estrutura Feature-First existente de `app/lib/features/{aprendizado,assistente,autenticacao,perfil}` e `app/lib/l10n/`, com criação apenas de `estado_do_modulo.dart` no domínio e `catalogo_modulo_concluido_test.dart` nos testes para manter responsabilidades pequenas e testáveis em isolamento.

## Complexity Tracking

Nenhuma violação à Constituição; zero novas dependências no `pubspec.yaml`; zero novos tokens visuais necessários (reaproveitamento integral de tokens validados do Design System).
