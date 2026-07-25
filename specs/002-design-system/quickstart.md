# Fase 1 — Guia de Validação: Design System

**Feature**: 002-design-system

---

## Pré-requisitos

| Item | Versão |
|---|---|
| Flutter SDK | 3.x estável |
| Python | 3.11+ (para o validador de contraste) |

---

## Validação que já funciona hoje

O portão de contraste é executável **antes de existir qualquer código Flutter**:

```bash
python specs/002-design-system/ferramentas/validar_paleta.py
```

Sai com código 0 se todos os 48 pares passarem, e 1 se algum reprovar — pronto para
entrar na verificação contínua.

Também é possível reproduzir a derivação da paleta:

```bash
python specs/002-design-system/ferramentas/amostrar_cores.py
```

---

## Cenários de validação

### V1 — Contraste em todos os temas

**Cobre**: FR-003, FR-018, FR-024, FR-035 · SC-001, SC-007

1. Rodar o validador de paleta.
2. **Esperado**: 48 pares aprovados; alto contraste ≥ 7:1 no texto.
3. Alterar um token para um valor ruim de propósito.
4. **Esperado**: o validador falha e retorna código 1.

**Falha se**: o validador passar com um token sabidamente ruim. O portão precisa
morder.

---

### V2 — Área de toque

**Cobre**: FR-009 · SC-002

```bash
flutter test test/design_system/area_toque_test.dart
```

Todo componente interativo é verificado contra `androidTapTargetGuideline`.
A `ConfirmacaoMemora` é verificada contra **56 dp**, não 48.

**Falha se**: qualquer componente ficar abaixo. Foi exatamente o defeito medido nos
botões SIM/NÃO do protótipo — 24 px, metade do mínimo.

---

### V3 — Texto em escala 2,0

**Cobre**: FR-025, FR-026 · SC-003

Cada componente é renderizado com escala 1,0 · 1,5 · 2,0.

**Esperado**: nenhum estouro de layout, nenhum texto cortado, área de toque
preservada.

**Falha se**: aparecer aviso de overflow, ou se algum texto sumir. É a quebra mais
comum e a que mais prejudica quem depende dela.

---

### V4 — Semântica para leitor de tela

**Cobre**: FR-010, FR-029 · SC-005

**Esperado**: todo componente interativo expõe rótulo e estado; a ordem de leitura
acompanha a ordem visual.

**Teste manual complementar**: percorrer a galeria inteira com o TalkBack ligado e a
tela desligada. Se não der para navegar às cegas, o componente não está pronto.

---

### V5 — Nenhum valor literal fora dos tokens

**Cobre**: FR-002, FR-032 · SC-004, SC-008

```bash
flutter analyze
```

**Esperado**: cor ou espaçamento literal em código de feature é sinalizado como erro.

**Teste de verdade**: construir uma tela nova sem escrever nenhum valor visual
literal. Se não for possível, falta componente ou falta token.

---

### V6 — Troca de tema

**Cobre**: FR-020, FR-021, FR-022, FR-023 · US3

1. Alternar entre claro, escuro e alto contraste.
2. **Esperado**: aplicação imediata em todo o aplicativo.
3. Fechar e reabrir → **esperado**: escolha preservada.
4. Acionar "voltar ao padrão" → **esperado**: retorno em **um toque**.
5. Mudar o tema do sistema depois de escolher explicitamente → **esperado**: a
   escolha da pessoa prevalece.

---

### V7 — Distinguir informação de ação *(o teste que mais importa)*

**Cobre**: FR-012 · SC-006

**Protocolo**: mostrar a tela de perfil a **5 pessoas de 65+ anos** e pedir que
apontem o que acham que é clicável.

**Meta**: **zero** campos de informação apontados como botão.

**Por que este cenário é especial**: nenhum teste automatizado detecta esta falha. O
código estaria "correto" e a pessoa ainda assim não saberia o que tocar. Era o
defeito mais grave do protótipo e só validação com gente resolve.

---

### V8 — Confirmação sem toque acidental

**Cobre**: FR-013 · SC-009 · Princípio VI

1. Apresentar a `ConfirmacaoMemora` a pessoas do público-alvo.
2. **Esperado**: nenhuma confirmação acidental.
3. **Esperado**: todas identificam qual opção confirma e qual recusa, **sem** ler a
   cor.
4. Na variante irreversível: todas percebem que aquela ação é diferente das demais.

---

### V9 — Redução de movimento

**Cobre**: FR-027, FR-028

Com "reduzir movimento" ativo no sistema, nenhuma animação ocorre — e nenhuma
informação se perde por causa disso.

---

### V10 — Galeria completa

**Cobre**: FR-033

**Esperado**: todo componente da biblioteca aparece na galeria, em todos os estados
e nos três temas.

**Falha se**: existir componente na biblioteca ausente da galeria. Documentação
incompleta é documentação que ninguém confia.

---

## Portão de saída

- [ ] V1 a V6, V9 e V10 passando de forma automatizada
- [ ] V7 e V8 executados com no mínimo 5 pessoas do público-alvo
- [ ] Toda divergência do protótipo registrada com a medição que a justificou (FR-038)
- [ ] Revisões de código, UX, acessibilidade, performance, segurança e arquitetura

**Só depois disso a feature 001 é desbloqueada para implementação.**
