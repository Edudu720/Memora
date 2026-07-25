---

description: "Task list — Design System do Memora"
---

# Tasks: Design System

**Input**: Documentos de design em `specs/002-design-system/`

**Prerequisites**: [spec.md](spec.md) · [plan.md](plan.md) · [research.md](research.md) · [data-model.md](data-model.md) · [contracts/componentes.md](contracts/componentes.md)

**Tests**: **obrigatórios**. A spec exige 100% de conformidade em contraste, área de
toque, semântica e escala de texto (SC-001 a SC-005). Isso só sobrevive a
refatoração se estiver automatizado.

## Format: `[ID] [P?] [Story] Descrição`

- **[P]**: pode ser feito em paralelo (arquivos distintos, sem dependência)
- **[Story]**: a qual história de usuário a tarefa pertence

---

## Phase 1: Setup

**Purpose**: criar o projeto e a estrutura definida no plano.

- [x] **T001** Criar o projeto Flutter em `app/`, pacote `br.fatec.memora`, apenas
      plataforma Android
- [x] **T002** Criar a árvore de pastas de `app/lib/design_system/` conforme a
      Structure Decision do plano
- [x] **T003** [P] Configurar `analysis_options.yaml` com lints estritos
- [x] **T004** [P] Adicionar `.gitignore` do Flutter em `app/`
- [x] **T005** Configurar verificação contínua no GitHub Actions rodando
      `flutter analyze`, `flutter test` e
      `python specs/002-design-system/ferramentas/validar_paleta.py`

---

## Phase 2: Foundational — Tokens e Temas

> **BLOQUEIA TODAS AS HISTÓRIAS.** Nenhum componente pode ser escrito antes.

- [x] **T006** Criar `app/lib/design_system/tokens/cores.dart` espelhando exatamente
      os valores de `ferramentas/validar_paleta.py`
- [x] **T007** [P] Criar `tokens/tipografia.dart` — escala de R4, piso de 16 sp
- [x] **T008** [P] Criar `tokens/espacamento.dart` — escala base 4
- [x] **T009** [P] Criar `tokens/raio.dart` e `tokens/elevacao.dart`
- [x] **T010** [P] Criar `tokens/movimento.dart` — durações de R5
- [x] **T011** [P] Criar `tokens/dimensoes.dart` — `alvo_minimo` 48, `alvo_decisao`
      56, `separacao_alvo` 8, `escala_texto_max` 2.0
- [x] **T012** Criar `temas/memora_theme_extension.dart` — `ThemeExtension` tipada
      expondo todos os tokens (R6)
- [x] **T013** Criar `temas/tema_claro.dart`, `tema_escuro.dart` e
      `tema_alto_contraste.dart`
- [x] **T014** Criar `design_system.dart` como ponto único de exportação
- [x] **T015** Escrever `test/design_system/contraste_test.dart` — porta o validador
      de paleta para o Dart, garantindo que os valores no código não divirjam dos
      valores validados

**Portão da fase**: `validar_paleta.py` e `contraste_test.dart` passando, com os
mesmos 48 pares.

> ✅ **Fases 1 e 2 concluídas em 2026-07-24.** 52 testes passando, `flutter analyze`
> limpo, validador de paleta aprovado. O portão foi verificado contra regressão:
> injetando `#7090E8`, o teste falha acusando 3,07:1 — o mesmo valor previsto pela
> amostragem em Python.

---

## Phase 3: US1 — Distinguir informação de ação (P1)

> A falha mais grave do protótipo. Ver FR-012.

- [ ] **T016** [US1] Criar `componentes/informacao/campo_informacao.dart` — sem
      fundo preenchido, sem forma de pílula, **sem aceitar callback de toque**
- [ ] **T017** [P] [US1] Criar `componentes/informacao/lista_informacao.dart`
- [ ] **T018** [P] [US1] Criar `componentes/informacao/destaque_informacao.dart`
- [ ] **T019** [US1] Criar `componentes/botoes/botao_primario.dart` — 56 dp,
      preenchido, rótulo textual obrigatório
- [ ] **T020** [P] [US1] Criar `botao_secundario.dart` e `botao_terciario.dart`
- [ ] **T021** [US1] Criar `componentes/botoes/botao_perigo.dart` — cor `perigo`,
      ícone obrigatório, nunca adjacente a outro botão
- [ ] **T022** [US1] Escrever `test/design_system/area_toque_test.dart` cobrindo
      todos os botões com `androidTapTargetGuideline`
- [ ] **T023** [US1] Escrever teste garantindo que os componentes de informação
      **não expõem** semântica de botão a leitores de tela

**Portão da fase**: um componente de informação não pode ser confundido com botão,
nem visualmente nem semanticamente.

---

## Phase 4: US2 — Ler com a letra do meu tamanho (P1)

- [ ] **T024** [US2] Criar `componentes/texto/texto_memora.dart` aplicando a escala
      tipográfica e o teto de escala 2.0
- [ ] **T025** [US2] Revisar todos os componentes das fases anteriores eliminando
      qualquer altura fixa (FR-026)
- [ ] **T026** [US2] Escrever `test/design_system/escala_texto_test.dart` — cada
      componente renderizado em 1.0, 1.5 e 2.0, sem estouro de layout
- [ ] **T027** [US2] Escrever `test/design_system/semantica_test.dart` — rótulo e
      estado expostos em todos os componentes interativos

**Portão da fase**: nenhum aviso de overflow em escala 2.0, em nenhum componente.

---

## Phase 5: US3 — Personalizar sem estragar a leitura (P2)

- [ ] **T028** [US3] Criar a entidade de preferência de aparência conforme
      [data-model.md](data-model.md)
- [ ] **T029** [US3] Implementar persistência local da preferência
      (**armazenamento simples — não é dado sensível**)
- [ ] **T030** [US3] Implementar troca de tema em tempo de execução, com
      `sistema` como padrão
- [ ] **T031** [US3] Implementar ajuste de tamanho de texto no app, multiplicando a
      escala do sistema, limitado a 2.0
- [ ] **T032** [US3] Implementar "voltar ao padrão" alcançável em **um toque**
      (FR-022)
- [ ] **T033** [US3] Implementar pré-visualização antes de confirmar a mudança
      (FR-023)
- [ ] **T034** [US3] Escrever teste cobrindo persistência e precedência da escolha
      explícita sobre o tema do sistema

---

## Phase 6: US4 — Consistência e componentes de decisão (P2)

- [ ] **T035** [US4] Criar `componentes/confirmacao/confirmacao_memora.dart` —
      vertical, largura total, 56 dp, frases completas, ícone + texto (R3)
- [ ] **T036** [US4] Criar a variante `irreversivel` — ação destrutiva separada,
      exigindo segunda confirmação (FR-013)
- [ ] **T037** [P] [US4] Criar `componentes/campos/campo_texto.dart` — rótulo acima
      e sempre visível, com `textoAjuda` obrigatório
- [ ] **T038** [P] [US4] Criar `campo_senha.dart` — controle de revelar rotulado em
      texto, desativável para o modo assistido da feature 001
- [ ] **T039** [P] [US4] Criar `campo_codigo.dart` — 6 dígitos, teclado numérico
- [ ] **T040** [P] [US4] Criar `componentes/cartoes/cartao.dart`
- [ ] **T041** [P] [US4] Criar `componentes/dialogos/dialogo.dart` e
      `folha_inferior.dart`
- [ ] **T042** [US4] Criar `componentes/navegacao/barra_superior.dart` — voltar
      sempre com rótulo textual
- [ ] **T043** [US4] Criar `componentes/navegacao/navegacao_inferior.dart` —
      **ícone + rótulo** em todos os itens (FR-016)
- [ ] **T044** [P] [US4] Criar `componentes/feedback/carregando.dart`,
      `mensagem_erro.dart` e `estado_vazio.dart` — ícone **e** texto, nunca só cor

---

## Phase 7: US5 — Sistema que não se degrada (P3)

- [ ] **T045** [US5] Criar `galeria/` — todos os componentes, todos os estados, três
      temas; disponível apenas em build de desenvolvimento (R9)
- [ ] **T046** [US5] Configurar regra de análise estática que sinaliza cor,
      espaçamento ou tamanho literal fora dos tokens (FR-032)
- [ ] **T047** [US5] Adicionar essa regra ao portão da verificação contínua
- [ ] **T048** [US5] Escrever o guia de uso do Design System em
      `docs/design/como-usar-o-design-system.md`

---

## Phase 8: Validação final

- [ ] **T049** Executar V1 a V6, V9 e V10 de [quickstart.md](quickstart.md)
- [ ] **T050** Executar **V7** — 5 pessoas de 65+ anos apontando o que acham
      clicável na tela de perfil. Meta: **zero** campos de informação apontados
- [ ] **T051** Executar **V8** — confirmação sem toque acidental, com o mesmo grupo
- [ ] **T052** Registrar em `docs/design/divergencias-do-prototipo.md` cada
      divergência com a medição que a justificou (FR-038)
- [ ] **T053** Revisões obrigatórias: código, UX, acessibilidade, performance,
      segurança e arquitetura

---

## Dependências

```
Setup (T001-T005)
   ↓
Foundational — Tokens e Temas (T006-T015)   ← BLOQUEIA TUDO
   ↓
   ├── US1 (T016-T023)  ← comece por aqui: corrige a falha mais grave
   ├── US2 (T024-T027)  ← depende de US1 existir para revisar altura fixa
   ├── US3 (T028-T034)  [P] independente das demais
   ├── US4 (T035-T044)  ← depende dos botões de US1
   └── US5 (T045-T048)  ← depende de todos os componentes existirem
        ↓
   Validação final (T049-T053)
```

---

## Ordem sugerida de entrega

1. **T001-T015** — projeto de pé e tokens validados. *Primeiro código do Memora.*
2. **T016-T023** — resolve a confusão entre dado e ação
3. **T024-T027** — garante leitura em fonte ampliada
4. **T035-T044** — componentes de decisão e entrada, que a feature 001 precisa
5. **T028-T034** — personalização
6. **T045-T048** — galeria e proteção contra degradação
7. **T049-T053** — validação com pessoas reais

**A feature 001 é desbloqueada ao final da fase 6** — a partir dali existem
componentes suficientes para construir as telas de autenticação.

---

## Observações

- **T050 e T051 não são opcionais.** São os únicos itens que nenhum teste
  automatizado substitui, e cobrem justamente o defeito mais grave encontrado no
  protótipo.
- **T006 é a única fonte de verdade das cores.** Qualquer alteração ali exige rodar
  o validador de paleta antes do commit.
- **T046 é o que impede a erosão do sistema.** Sem análise estática, valores
  literais reaparecem na terceira tela e a consistência se perde silenciosamente.
