# Contexto do Projeto Memora

> Leia este arquivo inteiro antes de qualquer ação. Ele existe para que uma nova
> sessão consiga continuar o trabalho sem repetir decisões já tomadas nem refazer
> análises já feitas.

**Última sessão**: 2026-07-24
**Estado**: Design System em implementação. Tokens e temas prontos e validados.

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

As skills do Spec Kit estão em `.claude/skills/speckit-*`, mas **podem não estar
registradas na ferramenta `Skill`** se foram instaladas depois do início da sessão.

**Se `Skill(speckit-plan)` falhar com "Unknown skill"**: leia
`.claude/skills/speckit-<nome>/SKILL.md` e execute as instruções manualmente. O
resultado é idêntico. Já foi feito assim nesta sessão inteira.

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
| **002 — Design System** | ✅ | ✅ | ✅ | 🟡 T001-T015 feitas |

### O que já existe em código

`app/lib/design_system/`:
- **tokens/** — cores (3 temas), tipografia, espaçamento, raio, elevação,
  movimento, dimensões
- **temas/** — `ThemeExtension` tipada; um token inexistente **não compila**
- **design_system.dart** — ponto único de exportação

`app/test/design_system/contraste_test.dart` — 52 testes.

### Próxima tarefa: **T016**

Componentes de informação e ação (`specs/002-design-system/tasks.md`, fase 3).
Resolve a falha mais grave do protótipo: campos de dado que pareciam botões.

**Detalhe de projeto que importa**: `CampoInformacao` **não aceita callback de
toque**. É proibição estrutural, não convenção — assim o erro não tem como voltar.

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
| Repositório | `Edudu720/Memora` (privado) |

---

## 6. Verificação — rode antes de dizer que terminou

```bash
cd app && flutter analyze && flutter test
```

```bash
python specs/002-design-system/ferramentas/validar_paleta.py
```

Os três precisam passar. O CI (`.github/workflows/verificacao.yml`) roda os mesmos.

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
