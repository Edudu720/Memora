# Implementation Plan: Design System

**Branch**: `feature/002-design-system` | **Date**: 2026-07-24 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-design-system/spec.md`

---

## Summary

Sistema de design do Memora: tokens, três temas validados e biblioteca de
componentes com acessibilidade garantida **por construção**, não por disciplina.

A paleta foi **derivada por medição**, não por escolha estética: 2,9 milhões de
pixels amostrados das 38 telas do protótipo, seguidos de validação de contraste de
51 pares nos três temas. O resultado preserva a identidade visual do projeto — o
azul `#1040F8` do protótipo já atendia à WCAG.

Esta feature **desbloqueia** a 001 e todas as seguintes.

---

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x

**Primary Dependencies**: apenas SDK do Flutter. Nenhuma biblioteca de UI de
terceiros — um Design System que depende de outro sistema de design não é nosso.

**Storage**: preferência de aparência em armazenamento local simples. **Não é dado
sensível** e não exige armazenamento seguro.

**Testing**: `flutter_test` com `meetsGuideline` · validador de contraste em Python
(já executável)

**Target Platform**: Android

**Project Type**: biblioteca interna dentro do aplicativo móvel

**Performance Goals**: troca de tema aplicada sem atraso perceptível; nenhuma
reconstrução de árvore completa a cada mudança de token

**Constraints**:
- Contraste ≥ 4,5:1 (≥ 7:1 no tema de alto contraste)
- Área de toque ≥ 48 dp; 56 dp em pontos de decisão
- Texto utilizável até escala 2,0
- Texto nunca menor que 16 sp

**Scale/Scope**: 3 temas · ~40 tokens · ~12 famílias de componentes

---

## Constitution Check

*GATE: precisa passar antes da Fase 0. Reavaliado após a Fase 1.*

| Princípio | Como o plano atende | Antes | Depois |
|---|---|---|---|
| **I — Segurança** | Superfície mínima. A única ameaça real — tema ilegível trancando a pessoa fora do app — é eliminada por temas curados (FR-017) e retorno ao padrão em um toque (FR-022) | ✅ | ✅ |
| **II — Engenharia social** | Identidade visual única e estável torna app clonado mais difícil de imitar e divergência mais perceptível. Ação irreversível visualmente distinta (R3) | ✅ | ✅ |
| **III — Acessibilidade** | Razão de ser da feature. Três portões automatizados capazes de falhar o build (R8) | ✅ | ✅ |
| **IV — Spec antes de código** | Nenhuma linha escrita. Spec clarificada precede este plano | ✅ | ✅ |
| **V — Arquitetura limpa** | Tokens tipados; nenhum valor literal em widget de feature (FR-002, R6) | ✅ | ✅ |
| **VI — IA nunca age sozinha** | R3 desenha a confirmação da assistente como decisão deliberada, não toque entre dois botões iguais | ✅ | ✅ |
| **VII — Ensinar, não substituir** | Personalização preservada, mas nenhuma escolha pode prejudicar a pessoa sem que ela entenda ou saiba reverter | ✅ | ✅ |

**Resultado**: nenhuma violação. Complexity Tracking vazio.

---

## Project Structure

### Documentation (this feature)

```text
specs/002-design-system/
├── spec.md
├── plan.md                    # Este arquivo
├── research.md                # Fase 0 — 10 decisões, com medições
├── data-model.md              # Fase 1 — estrutura dos tokens
├── contracts/
│   └── componentes.md         # Fase 1 — inventário e contrato dos componentes
├── quickstart.md              # Fase 1 — validação
├── ferramentas/
│   ├── amostrar_cores.py      # Amostragem do protótipo (executável)
│   ├── (medir_botoes.py não está no repositório: a medição dos botões SIM/NÃO não é reexecutável)
│   └── validar_paleta.py      # Portão de contraste (executável, passando)
└── checklists/requirements.md
```

### Source Code (repository root)

```text
app/lib/design_system/
├── tokens/
│   ├── cores.dart             # Espelha validar_paleta.py
│   ├── tipografia.dart
│   ├── espacamento.dart
│   ├── raio.dart
│   ├── elevacao.dart
│   └── movimento.dart
├── temas/
│   ├── tema_claro.dart
│   ├── tema_escuro.dart
│   ├── tema_alto_contraste.dart
│   └── memora_theme_extension.dart
├── componentes/
│   ├── botoes/
│   ├── campos/
│   ├── cartoes/
│   ├── dialogos/
│   ├── confirmacao/           # ConfirmacaoMemora (R3)
│   ├── navegacao/
│   ├── feedback/              # Carregando, erro, vazio
│   └── informacao/            # Exibir dado SEM parecer botão (FR-012)
├── galeria/                   # Documentação viva (R9), só em desenvolvimento
└── design_system.dart         # Ponto único de exportação

app/test/design_system/
├── contraste_test.dart
├── area_toque_test.dart
├── semantica_test.dart
└── escala_texto_test.dart
```

**Structure Decision**: o Design System vive em `design_system/`, fora de
`features/`, porque não pertence a nenhuma feature — todas dependem dele. A
separação entre `componentes/informacao/` e `componentes/botoes/` é **deliberada e
estrutural**: ela materializa a FR-012 e torna difícil repetir o erro do Perfil, em
que dado e ação tinham a mesma aparência.

---

## Complexity Tracking

**Não se aplica.** Nenhuma violação identificada.

---

## Sequência de implementação

A ordem importa: cada etapa depende da anterior estar verificada.

1. **Tokens** — cores, tipografia, espaçamento, raio, elevação, movimento.
   *Portão*: `validar_paleta.py` passando (já está).
2. **Temas** — os três, sobre `ThemeExtension` tipada.
   *Portão*: troca de tema sem valor literal em lugar nenhum.
3. **Componentes de base** — botão, campo, cartão, texto.
   *Portão*: testes de área de toque e semântica.
4. **Componentes de decisão** — `ConfirmacaoMemora` e diálogos.
   *Portão*: revisão de UX específica; é aqui que o toque acidental acontece.
5. **Componentes de informação** — o oposto de botão (FR-012).
   *Portão*: teste com pessoas — ninguém pode apontá-los como clicáveis.
6. **Navegação e feedback** — barra inferior com rótulo, carregando, erro, vazio.
7. **Galeria** — todos os componentes, todos os estados, três temas.
8. **Preferências** — escolha de tema e tamanho de texto, com persistência.

---

## Riscos conhecidos

| Risco | Impacto | Mitigação |
|---|---|---|
| Alguém escrever cor literal numa tela | Erosão silenciosa do sistema | FR-032 com análise estática falhando o build |
| Layout quebrar em escala 2,0 | Inutilizável para quem mais precisa | Proibição de altura fixa (R7) + teste automatizado |
| Componente novo nascer sem semântica | Leitor de tela inutilizável | Teste de semântica obrigatório por componente |
| Tokens divergirem do Figma | Questionamento na defesa | FR-038: toda divergência documentada com a medição que a justificou |
| Galeria ser abandonada | Documentação morta | Faz parte do portão da etapa 7, não é opcional |
| Componente de confirmação parecer estranho à equipe | Rejeição do redesenho | R3 explica cada mudança com o defeito medido que ela corrige |

---

## Divergências deliberadas do protótipo

Registro para a defesa acadêmica, conforme FR-038.

| Protótipo | Design System | Motivo |
|---|---|---|
| Botões SIM/NÃO de 24 px, lado a lado | Empilhados, 56 dp, rótulo completo | 24 px é metade do mínimo de 48 dp (medido) |
| Fonte serifada no Chatbot | Sem serifa | Legibilidade em baixa visão |
| Navegação inferior só com ícones | Ícone + rótulo | Ícone isolado é ambíguo |
| Dados do Perfil como pílulas azuis | Componente de informação distinto | Impossível distinguir dado de ação |
| "Mexa como quiser" nas cores | Três temas curados | Escolha livre quebra a garantia de contraste |
| Botão "Idiomas" | Removido por ora | Opção que não faz nada desgasta a confiança |
| `#7090E8` | Removido da paleta | 3,07:1 sobre branco — reprova como texto; sem papel na paleta |
| `#1040F8` | **Mantido** | 6,75:1 — aprovado, identidade preservada |

---

## Fase seguinte

`/speckit-tasks` — quebrar em tarefas acionáveis seguindo a sequência acima.
