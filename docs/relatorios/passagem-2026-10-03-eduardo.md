# Passagem de contexto — 2026-10-03, linha do Eduardo

> Trabalho feito **em paralelo** à fase 3b do Henrique, longe dos arquivos dela.
> **Nada disto está na `master`.** São quatro branches enviadas ao GitHub,
> todas saídas da `master` de **029f9c8** (2026-10-02), **antes** dos merges da
> 3b (T111-T115) e da fase 8 da 003 (Gemini), que o Henrique levou direto à
> `master` (`bd2daf7`).
>
> **Primeira tarefa da próxima sessão: trazer a `master` para estas branches,
> resolver os conflitos e só então abrir as PRs.** Os conflitos esperados estão
> no fim deste arquivo.
>
> Organização do trabalho: Opus orquestrando, planejando e revisando; agentes
> Sonnet escrevendo o código, um por fase, cada um no seu worktree.

## As branches, e como se empilham

```text
master@029f9c8
 └─ feature/004-t123-data-de-nascimento          T123 (+ V9 do quickstart, T096 corrigida)
     ├─ feature/004-fase6-us4-fundacao            Fase 6, fundação sem tela
     └─ feature/004-fase4-us1-apresentacao        Fase 4, a apresentação
         └─ feature/004-fase9-us7-ajustes         Fase 9, Ajustes (este arquivo vive aqui)
```

A 6 e a 4 são **irmãs**: as duas saem da T123 e se tocam só em uma linha da
`composicao.dart`, além de linhas diferentes do `tasks.md`.

| Branch | Tarefas | Testes (app) | Verificado pelo orquestrador |
|---|---|---|---|
| `t123-data-de-nascimento` | T123 | 1028 + 1 pulado | ✅ analyze, test, os dois validadores |
| `fase4-us1-apresentacao` | T045, T046, T048, T049, T050 (T047 pela metade) | 1086 + 2 pulados | ✅ |
| `fase6-us4-fundacao` | T058-T064, T068, T069a, T069b | 1109 + 1 pulado | ✅, e o APK de depuração compilou |
| `fase9-us7-ajustes` | T091-T095, T121 (T122 pela metade) | 1360 + 2 pulados | ✅ (com a correção da resposta em voo, `fd00856`) |

Todo portão novo foi **quebrado de propósito**, com o teste e a mensagem
registrados nos commits e nos relatórios. Três quebras acharam **portão
decorativo**, que foi consertado antes do commit:
- a ligação da data de nascimento na `Composicao`, que nenhum teste prendia;
- a separação entre "Sair" e "Sair e esquecer", que media a coisa errada;
- a confirmação da Privacidade, que era localizada pelo tipo do botão.

## O que cada uma traz

**T123 — data de nascimento opcional no Perfil** (FR-042c). Três campos (Dia,
Mês, Ano), por escolha do Eduardo, em vez do calendário do Android.
`LimpezaDeSessao` ganhou a interface `DadoLocalDoAparelho`, para o que **só**
o `esquecerTudo` leva. Ela é separada de `DadoLocalDaPessoa`, então o
compilador impede pôr a data na lista errada. **Achado na revisão**: o
`RepositorioAutenticacaoApi` usa `id ?? ''`, e com id vazio todas as contas
dividiriam a mesma chave. As duas camadas recusam id vazio.

**Fase 4 — a apresentação** (US1). Três telas entre a autenticação e a casca,
só para conta que não as viu. `ApresentacaoVista` é `DadoLocalDoAparelho`. A
primeira tela diz o que ninguém do Memora faz (FR-036a, literal). Um `Listener`
próprio conta o toque como atividade. **T047 pela metade**: o login de hoje não
tem "Primeiro acesso", e "Esqueci minha senha" começa em y=966 no 320×568; o
caso está com `skip` até a T117.

**Fase 6 — a fundação dos guias** (US4, sem tela). Canal Kotlin
`memora/aplicativos`, que só lê e não pede permissão nova; `ConsultaDeAplicativos`
com cache; `Guia`/`Passo` com o registro **vazio** (as capturas não chegaram);
`ProgressoDeAprendizado` (`DadoLocalDaPessoa`, sai em toda saída); busca sem
acento; `CatalogoGuardado` (FR-024a), que só o `main.dart` liga. **Só
compilado, nunca rodado em aparelho**, e sem os pacotes no `<queries>` do
manifesto o canal responde "não instalado" para tudo (T075).

**Fase 9 — Ajustes** (US7). Quatro grupos: Aparência, Acessibilidade,
Privacidade e Conta. A **FR-038 venceu o texto da T091**, que dizia três; a
tarefa foi corrigida. **"Sair e esquecer este aparelho" existe**, com
confirmação irreversível, e é a primeira tela a chamar `esquecerTudo: true`.
Reduzir movimento entra no `MediaQuery`. **Achado real**: apagar a conversa em
Privacidade era desfeito pela conversa aberta no Início, e depois por uma
resposta em voo. As duas coisas foram fechadas, a segunda em `fd00856`.

## O que ficou aberto

- ⚠️ **O texto da Privacidade promete demais e NÃO foi corrigido.** Ele diz que
  o e-mail ou telefone fica "só neste celular, e não em outro lugar", mas esse
  é o canal da conta, que mora no servidor. Há uma correção começada e **não
  verificada** num `git stash` local (`WIP T094: texto da Privacidade...`), só
  na máquina do Eduardo. Termine-a e teste antes da PR.
- **A Privacidade não lista o progresso de aprendizado.** Ele vem da Fase 6,
  que é irmã: acrescente-o ao juntar as duas.
- **T122 pela metade**: a preferência de paleta e o `validar_paleta.py` estão
  prontos (o `--autoteste` entrou no CI). Faltam as cores em `tokens/` e a
  escolha em Aparência, que estavam travadas pela 3b. A 3b já entrou, então
  isso pode seguir.
- **T124 não sai sozinha**: a V10 nasce na T083 e, pela regra do `tasks.md`,
  a migration vem **depois** do conteúdo dos guias.
- **Ilustrações das portas de Ajustes** usam desenhos que já existiam, até a
  T011 trazer os próprios.

## Para a equipe decidir

- **A Memora fala com a pessoa no feminino** ("consiga sozinha", "Prefiro
  tentar sozinha", "Quero entrar sozinha"), um padrão que vem desde a 001.
  Quem não se reconhece assim lê uma frase que não é para si. Uma forma
  neutra ("sem ajuda") preserva a voz.
- **A ADR-002 escolheu o Gemini gratuito e registra uma violação da FR-051.**
  Ela entrou direto na `master`, sem PR. O `CLAUDE.md` dizia que a escolha do
  provedor era decisão da equipe e que retenção de dados era o critério que mais
  pesava. Vale a equipe ler a ADR junto.

## Conflitos esperados ao trazer a `master`

A 3b mexeu em `casca_interna.dart`, `tela_inicio.dart`, `tela_hub.dart`, nos
tokens, no barril e na galeria. Destes, as nossas branches só tocam o
`fluxo_autenticacao.dart`, a `composicao.dart`, o `main.dart`, o `tasks.md` e o
`fluxo_dentro_da_conta.dart` (o arnês de teste). **Nos dois lados há verdade**:
não resolva escolhendo um lado só. Depois do merge, rode a suíte inteira: o
Início mudou (T115), e testes do fluxo que esperam o Início podem precisar de
ajuste.

Ordem sugerida: `master` → T123 → 4 → 9, e a 6 junto. Depois, uma PR por
branch, empilhadas como de costume.
