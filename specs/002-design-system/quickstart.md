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

Sai com código 0 se todos os 51 pares passarem, e 1 se algum reprovar — pronto para
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
2. **Esperado**: 51 pares aprovados; alto contraste ≥ 7:1 no texto.
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
py specs/002-design-system/ferramentas/validar_tokens.py
```

**Esperado**: cor, espaçamento, raio ou tamanho literal em `app/lib/` sai com
código 1 e o arquivo:linha de cada um.

⚠️ **Este comando era `flutter analyze` até 2026-09-15, e `flutter analyze` nunca
detectou isso** — não há lint do Dart para "valor visual fora do token". Enquanto o
cenário dizia isso, o V5 estava sendo dado como automatizado sem nada o
automatizando. A T046 escreveu a ferramenta; o portão está no CI como job próprio.

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

---

## Onde cada cenário roda (T049, 2026-09-15)

Mesmo mapa que o `quickstart.md` da feature 003 ganhou na T069: "executar de
forma automatizada" só é verificável se dá para apontar **qual teste é qual
cenário**.

| Cenário | Onde | Automatizado? |
|---|---|---|
| **V1** contraste | `ferramentas/validar_paleta.py` (17 pares × 3 temas = 51, job de CI) + `test/design_system/contraste_test.dart` (os mesmos 51 no lado Dart) | ✅ |
| **V2** área de toque | `test/design_system/area_toque_test.dart` | ✅ |
| **V3** texto em 2,0 | `test/design_system/escala_texto_test.dart`, `galeria_test.dart` e `test/acessibilidade/` | ✅ |
| **V4** semântica | `test/design_system/informacao_nao_e_acao_test.dart` e os `isSemantics` espalhados | 🟡 **parcial** — o passo do TalkBack com a tela desligada é manual e **não foi feito** |
| **V5** nenhum literal | `ferramentas/validar_tokens.py` (job de CI) | ✅ **desde 2026-09-15** |
| **V6** troca de tema | `test/design_system/preferencias/aparencia_test.dart` | ✅ |
| **V7** informação × ação | 5 pessoas de 65+ | ❌ **não automatizável** |
| **V8** confirmação | 5 pessoas de 65+ | ❌ **não automatizável** |
| **V9** redução de movimento | `test/design_system/reducao_de_movimento_test.dart` | ✅ **desde 2026-09-15** |
| **V10** galeria completa | `test/design_system/galeria_completa_test.dart` | ✅ **desde 2026-09-15** |

Rodar todos:

```powershell
cd app; flutter analyze; flutter test
```

```powershell
py specs/002-design-system/ferramentas/validar_paleta.py; py specs/002-design-system/ferramentas/validar_tokens.py
```

### O que a T049 encontrou

**1. O V5 estava sendo dado como automatizado e não era.** Ver o aviso no
próprio cenário, acima.

**2. O V9 e o V10 não tinham teste nenhum.** Os dois agora têm, e os dois foram
escritos contra o problema de amanhã, não o de hoje:

- o do **V9** é um portão de **código-fonte**: toda animação em `app/lib/`
  precisa passar por `MemoraMovimento.efetiva`. A primeira versão varria a
  galeria montada e **não servia** — a `ListView` é preguiçosa e os componentes
  animados nem chegavam à árvore. Um portão que olha para uma árvore incompleta
  aprova o errado;
- o do **V10** compara o barril `design_system.dart` com a galeria. Provado
  quebrando: tirei o `CampoCodigo` da galeria e ele reprovou nomeando o
  componente e o arquivo.

**3. Animação do Material não obedece à preferência, e não é nossa.** Montar um
botão traz seis `ImplicitlyAnimatedWidget` do Flutter (`AnimatedTheme`,
`AnimatedPhysicalModel`, `AnimatedDefaultTextStyle`, `_MaterialInterior`), todos
em 200 ms, nenhum consultando `disableAnimations`. O V9 vale para o que é nosso;
o que o Material anima sozinho está fora do nosso alcance, e o que importa — que
nenhuma informação dependa **só** do movimento — tem caso próprio.
