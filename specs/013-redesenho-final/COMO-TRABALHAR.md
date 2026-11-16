# Como trabalhar na `redesign-final`

**Para**: Eduardo Juncker, Eduardo Trevisan e Henrique.
**Desde**: 2026-11-16.

O redesenho final do Memora (spec **013**) vai ser feito em três frentes ao
mesmo tempo, sobre uma branch comum: **`redesign-final`**. Ela já tem tudo o
que está na `develop` (as PRs #71 a #77) mais o trabalho do redesenho feito
até agora: a Memora vetorial 2.5D animada, a spec, o plano e as tarefas.

---

## 1. Antes de começar (todos)

1. **Atualize o Flutter para 3.47.7**, a mesma versão do CI. A `develop` exige
   Flutter 3.47 ou mais novo desde a #73 (foto de perfil); com uma versão mais
   velha o projeto não compila. Se o Flutter for um clone do git:
   `git -C <pasta-do-flutter> fetch --tags` e depois
   `git -C <pasta-do-flutter> checkout 3.47.7`.
2. **Leia, nesta ordem:**
   - `.claude/skills/memora-ux/SKILL.md` — as regras de UI/UX de qualquer tela
     (e do site): blocos de no máximo duas frases, nunca "idoso", nenhum
     emoji na interface, a Memora, as transições, "reduzir movimento";
   - `specs/013-redesenho-final/spec.md` — o que o redesenho faz e por quê;
   - `specs/013-redesenho-final/tasks.md` — as tarefas, já divididas (seção
     "Divisão e forma de trabalho").
3. **Ratifique a spec 013.** Ela foi aprovada pelo Henrique; a constituição
   pede a aprovação de todos. Se tiver objeção, fale antes de implementar.

## 2. Quem faz o quê

Todas as tarefas foram **redistribuídas** em 2026-11-16. A tabela completa
está no `tasks.md`; o resumo:

| Quem | Frente | Tarefas |
|---|---|---|
| **Henrique** | A Memora e o movimento: a anfitriã do Início (Memora que se mexe sozinha e conta dicas), as animações e transições, a abertura com a Memora acenando, a Memora no Início, na conversa e nos estados de tela, a barra inferior, desempenho e fechamento | T083–T090, T019–T027, T035–T039, T047–T057, T059, T072, T073, T076, T078, T043–T046 |
| **Eduardo Juncker** | Texto e conteúdo: reescrever os textos em blocos de duas frases (inclusive os guias), tirar o emoji das mensagens, a conversa limpa, a voz, os 128 ícones, as telas do Localizador e da foto de perfil, o álbum e a validação final | T029–T034, T040–T042, T058, T060–T071, T074, T075, T077, T079, T081 |
| **Eduardo Trevisan** | **O site** inteiro (spec 012): a Memora 2.5D animada no lugar das imagens antigas, a anfitriã do site, a Memora falando junto com o "Ouvir", CSS moderno, "reduzir movimento", qualidade no CI | S01–S13 em `specs/012-site-tutorial-idoso/tarefas-do-redesenho.md` |

## 3. Como trabalhar

1. **Saia da `redesign-final`** numa branch sua, com o número das tarefas:
   `git fetch origin; git switch -c redesign/T029-textos origin/redesign-final`.
2. **Uma PR por grupo de tarefas, para a `redesign-final`** (não para a
   `develop`).
3. **Quem revisa é outra pessoa da equipe**, nunca quem escreveu.
4. **Antes de pedir revisão**, rode os quatro portões:
   ```powershell
   cd app; flutter analyze; flutter test
   py specs/002-design-system/ferramentas/validar_paleta.py
   py specs/002-design-system/ferramentas/validar_tokens.py
   ```
5. **Todo portão novo é provado quebrando**: commite, quebre de propósito,
   veja reprovar, desfaça. Está no `tasks.md` de cada tarefa de teste.
6. **Marque a tarefa com `[X]` no `tasks.md`** na mesma PR que a entrega.
7. **Traga a `redesign-final` para a sua branch com frequência**
   (`git merge origin/redesign-final`), para os conflitos ficarem pequenos.
8. No fim, a `redesign-final` vai para a `develop` numa PR só.

## 4. ⚠️ O CI começa vermelho, de propósito

A `redesign-final` nasce com **5 testes reprovando**, todos no
`app/test/design_system/texto_da_interface_test.dart`. É o portão de texto
novo: ele encontrou **15 textos** que passam de duas frases ou têm "😊" (em
ajuda, apresentação, autenticação, configurações e perfil). Não é defeito: é
o trabalho da **T029–T031**, do Eduardo Juncker.

- **Eduardo**: comece por elas. São textos curtos, e quando elas entrarem o CI
  fica verde para todo mundo.
- **Todos**: até lá, esses 5 testes vão aparecer vermelhos na sua PR. Qualquer
  **outra** falha é sua.
- **Ninguém afrouxa o portão** para deixar o CI verde: foi assim que este
  projeto já teve portão decorativo.

## 5. Onde as frentes se tocam (combine antes)

- **Conversa**: a T058 (conversa limpa, Eduardo) vem **antes** da T059
  (a Memora pequena na conversa, Henrique) — mesma tela.
- **Início**: a T053/T054 (Henrique) só depois da anfitriã aprovada (T090).
- **`l10n/`**: o Eduardo reescreve textos (T029–T031, T066–T067); o Henrique
  cria `textos_anfitria.dart` (T086) e os textos da abertura (T036) —
  arquivos diferentes, sem conflito.
- **Site × aplicativo**: o Trevisan usa a Memora exportada do aplicativo (S02,
  combinar com o Henrique, dono dos pintores) e a lista de dicas da anfitriã
  (T086) — nunca uma segunda Memora nem uma segunda lista.

## 6. Dúvida de requisito

**Não suponha**: se a spec não responde, a pergunta vira `/speckit-clarify` e
a resposta entra na spec antes do código (Princípio IV).
