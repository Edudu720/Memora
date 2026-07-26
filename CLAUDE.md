# Contexto do Projeto Memora

> Leia este arquivo inteiro antes de qualquer ação. Ele existe para que uma nova
> sessão consiga continuar o trabalho sem repetir decisões já tomadas nem refazer
> análises já feitas.

**Última sessão**: 2026-07-25
**Estado**: Design System em implementação. Tokens, temas e componentes de
informação e ação prontos e validados.

---

## 1. O que é o Memora

Aplicativo Android que **ensina pessoas idosas a usar o smartphone**. Não é um
assistente que faz as coisas pelo usuário — ele mostra o caminho, para que da
próxima vez a pessoa consiga sozinha.

Projeto Integrador da FATEC Americana. Equipe NewXz: Eduardo Juncker Toras,
Eduardo Moraes Trevisan e Henrique Moreira Sandrini (Scrum Master).

A pergunta que valida qualquer decisão: **"Um idoso conseguiria usar isso sozinho?"**

---

## 2. Regras que não se negociam

Estão em [`.specify/memory/constitution.md`](.specify/memory/constitution.md).
**Leia antes de propor qualquer coisa.** Resumo:

1. **Segurança acima de tudo** — vence prazo, performance e conveniência
2. **Proteção contra engenharia social** — toda tela responde *"como um golpista
   exploraria isto?"*
3. **Acessibilidade é requisito** — WCAG 2.2 AA, toque de 48 dp, texto a 200%
4. **Especificação antes de código** — sem spec aprovada, não se implementa
5. **Arquitetura limpa, Feature-First**
6. **A IA nunca age sozinha** — toda ação crítica exige confirmação e gera log
7. **Ensinar, não substituir** — o objetivo é autonomia

---

## 3. Como se trabalha aqui: Spec Driven Development

```
constitution → specify → clarify → plan → checklist → tasks → analyze → implement
```

### ⚠️ Armadilha conhecida

As skills do Spec Kit estão em `.claude/skills/speckit-*` e **normalmente estão
registradas** na ferramenta `Skill` em sessões novas.

**Se `Skill(speckit-plan)` falhar com "Unknown skill"** — acontece quando são
instaladas no meio da sessão: leia `.claude/skills/speckit-<nome>/SKILL.md` e
execute as instruções manualmente. O resultado é idêntico.

**Ao usar `/speckit-implement`, limite o escopo a uma fase por vez.** Cada fase do
`tasks.md` tem portão próprio e vira uma PR separada.

### Regras de fase

- **Na spec não se fala de tecnologia.** Comportamento e valor, não widgets.
- **No plano não se escreve código.** Estrutura, contratos e decisões.
- **Na implementação não se inventa requisito.** Faltou algo? Volta para a spec.
- **Ambiguidade vira pergunta, nunca suposição.**

---

## 4. Estado atual

| Feature | Spec | Plano | Tarefas | Código |
|---|---|---|---|---|
| **001 — Autenticação Acessível** | ✅ | ✅ | ⬜ | ⬜ bloqueada |
| **002 — Design System** | ✅ | ✅ | ✅ | 🟡 T001-T027 feitas |

### O que já existe em código

`app/lib/design_system/`:
- **tokens/** — cores (3 temas), tipografia, espaçamento, raio, elevação,
  movimento, dimensões
- **temas/** — `ThemeExtension` tipada; um token inexistente **não compila**
- **design_system.dart** — ponto único de exportação

- **componentes/informacao/** — `CampoInformacao`, `DestaqueInformacao`,
  `ListaInformacao`. **Nenhum aceita callback de toque** — é ausência de API
- **componentes/botoes/** — `BotaoPrimario`, `BotaoSecundario`, `BotaoTerciario`,
  `BotaoPerigo`, sobre um `BotaoBase` que concentra as garantias
- **componentes/texto/** — `TextoMemora` e `escalaTextoLimitada(context)`

`app/test/design_system/` — 96 testes.

### Regra de texto

**Todo `Text` usa `escalaTextoLimitada(context)`.** Sem isso o componente diverge
dos demais em ampliação extrema e o layout quebra de forma imprevisível.

### Regra visual que separa dado de ação

**Ação usa pílula e preenchimento. Informação nunca usa nenhum dos dois.**
Não invente uma terceira linguagem sem revisar a FR-012.

### Próxima tarefa: **T028**

Fase 5 (`specs/002-design-system/tasks.md`): preferências de aparência —
troca de tema, ajuste de tamanho de texto e persistência.

Alternativa: fase 6 (T035-T044), que contém a `ConfirmacaoMemora` e os campos
de entrada de que a feature 001 precisa.

**A feature 001 é desbloqueada ao final da fase 6** (T044).

---

## 5. Ambiente — atalhos que economizam tempo

Ferramentas **não estão no PATH** do shell. Exporte antes de usar:

```bash
export PATH="/c/flutter_windows_3.41.6-stable/flutter/bin:/c/Program Files/GitHub CLI:$PATH"
```

Para o Spec Kit (`uv`):
```bash
export PATH="/c/Users/Edu/AppData/Roaming/Python/Python314/Scripts:$PATH"
```

| Item | Valor |
|---|---|
| Flutter | 3.41.6 · Dart 3.11.4 |
| Java | 21 LTS (backend, ainda não iniciado) |
| Scripts do Spec Kit | **PowerShell** (`.ps1`) — use a ferramenta PowerShell |
| Identidade git | `Eduardo Juncker <eduardojunckertorasl@gmail.com>` |
| **Shell do usuário** | **Windows PowerShell 5.1** |
| Repositório | `Edudu720/Memora` (privado) |

---

## 6. Verificação — rode antes de dizer que terminou

```powershell
cd app; flutter analyze; flutter test
```

```powershell
python specs/002-design-system/ferramentas/validar_paleta.py
```

Os três precisam passar. O CI (`.github/workflows/verificacao.yml`) roda os mesmos.

### ⚠️ Sintaxe de comando

O usuário roda **Windows PowerShell 5.1**, que **não aceita `&&`** — é erro de
parser, não apenas incompatibilidade. Ao entregar comandos a ele:

- Use `;` como separador: `cd app; flutter test`
- Para encadear só em caso de sucesso: `cd app; if ($?) { flutter test }`
- `&&`, `||`, ternário e `??` não existem nessa versão

Você (agente) pode usar bash pela ferramenta Bash, mas **o que for colado para o
usuário precisa ser PowerShell**.

### Princípio de verificação adotado aqui

**Teste que passa não prova que o portão funciona.** Nesta sessão, o portão de
contraste foi validado *injetando um valor ruim de propósito* e confirmando que ele
falha. Faça o mesmo ao criar qualquer novo portão.

---

## 7. Decisões já tomadas — não reabra sem motivo novo

| Decisão | Escolha | Onde está justificada |
|---|---|---|
| Backend | **Java + Spring Boot** | [ADR 001](docs/architecture/adr-001-linguagem-do-backend.md) |
| Identificador de login | E-mail **ou** telefone; só um no cadastro | spec 001, D1 |
| Login social | Google **e** Facebook | spec 001, D2 |
| Cadastro assistido | Modo assistido explícito | spec 001, D3 |
| Origem dos tokens | Amostragem das imagens do protótipo | spec 002, D1 |
| Temas | Claro, escuro e alto contraste | spec 002, D2 |
| Idiomas | Fora de escopo; estrutura preparada | spec 002, D3 |

---

## 8. Achados que valem lembrar

- **A paleta do protótipo passa na WCAG.** O azul `#1040F8` mede 6,75:1 com texto
  branco. A identidade visual foi preservada — não a altere sem medir.
- **O padrão do Spring Security é fraco demais.** `Argon2PasswordEncoder` usa 16 MiB
  de memória; a OWASP exige no mínimo 19 MiB. Os parâmetros precisam ser explícitos.
- **Os botões SIM/NÃO não reprovavam em contraste** (14,98:1 e 7,55:1). A primeira
  avaliação estava errada — era impressão visual. O defeito real é a **altura de
  24 px contra 48 dp**. Meça antes de afirmar.
- **`@immutable` vem de `foundation`**, não de `painting`. Custou um erro de
  compilação.
- **`containsSemantics` está obsoleto** no Flutter 3.41. Use `isSemantics`.
- **Não acesse o tema por reflexão.** Use `context.memora` — a extensão já existe
  em `temas/memora_theme_extension.dart`.
- **`Semantics(button: true)` não basta**: sem `onTap` na própria `Semantics`, o
  TalkBack anuncia o botão mas o duplo-toque não ativa nada. Custou um defeito real.
- **Não use `Opacity` para estado desabilitado.** Derruba o contraste do rótulo
  para 2,79:1. Use `superficieAlt` com `textoSuave`, que mede 6,22:1.
- **`.specify/feature.json`** aponta a feature ativa e **conflita** quando duas
  branches o alteram. Resolva mantendo a feature em que você está.

---

## 9. Coisas que NÃO se faz neste projeto

- ❌ Escrever cor, espaçamento ou tamanho literal fora dos tokens
- ❌ Criar componente dentro de `features/` quando ele serve a mais de uma tela
- ❌ Editar cliente de API gerado à mão
- ❌ Guardar token em `SharedPreferences` — apenas `flutter_secure_storage`
- ❌ Implementar sem spec aprovada
- ❌ Afirmar que algo passa sem ter rodado a verificação
- ❌ Supor requisito quando a spec é ambígua — pergunte

---

## 10. Pendências que dependem de pessoas

| Pendência | Com quem | Bloqueia? |
|---|---|---|
| Aceitar convite do repositório | Henrique-Sandrini e Du3101 | Não |
| GitHub Student Pack aprovado | Eduardo (enviado) | Não — libera proteção de branch |
| Corrigir contradições do Arquivo X (voz, offline) | Equipe | Não — ver [requisitos-atualizados.md](docs/referencia/requisitos-atualizados.md) |
| Teste com 5 pessoas de 65+ anos | Equipe | **Sim** — portão de saída das features 001 e 002 |

> A proteção da branch `master` **não está ativa** — o GitHub exige plano Pro em
> repositório privado. A regra de não commitar direto vale por acordo da equipe.

---

## 11. Como falar com o usuário

- **Em português.**
- Explique o que está fazendo e por quê — ele pediu isso explicitamente.
- **Meça antes de afirmar.** Este projeto tem ferramentas para isso; use-as.
- **Corrija-se em voz alta** quando errar. Já aconteceu nesta sessão e foi útil.
- Ao recomendar algo, diga também **o que o faria mudar de ideia**.
- Não trate o SDD como burocracia: cada etapa evitou retrabalho concreto aqui.
