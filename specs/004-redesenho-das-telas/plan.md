# Implementation Plan: Redesenho das telas — o Memora inteiro, e bonito

**Branch**: `004-redesenho-das-telas` | **Date**: 2026-10-01 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/004-redesenho-das-telas/spec.md`

## Summary

A feature é quase toda **aplicativo**. O backend ganha três migrations pequenas, V8 a V10, e
nada mais.

Três movimentos organizam o trabalho:

1. **Tirar o andaime.** A casca de demonstração sai da raiz. Quem está dentro da
   conta passa a viver numa **casca interna** com barra inferior de três
   destinos (Configurações · Início · Perfil), montada *dentro* do
   `FluxoAutenticacao` para herdar, sem reescrever, os portões de inatividade e
   de atividade da revisão de 2026-10-01 ([R1](research.md#r1--a-casca-de-demonstração-sai-e-entra-a-casca-do-aplicativo)).
2. **Dar uma linguagem visual de verdade.** Sete regras verificáveis em vez de
   adjetivos ([R2](research.md#r2--o-que-prático-intuitivo-profissional-e-moderno-quer-dizer-aqui)),
   uma fonte desenhada para baixa visão ([R3](research.md#r3--tipografia-atkinson-hyperlegible-next-embarcada)),
   a Memora redesenhada como personagem e ilustrações de licença aberta
   ([R4](research.md#r4--ilustrações-a-memora-redesenhada-e-um-conjunto-de-licença-aberta)).
   Tudo entra **no Design System da 002**, com os portões de contraste e de
   tokens que ele já tem — não ao lado dele.
3. **Construir as telas que faltam.** Início, apresentação, Ajuda,
   Configurações, Perfil e o passo a passo, que é a peça nova mais importante:
   conteúdo tipado, escrito pela equipe, com capturas reais e destaque desenhado
   pelo aplicativo ([R6](research.md#r6--o-passo-a-passo-conteúdo-tipado-capturas-da-equipe-destaque-desenhado-pelo-app)).

A segurança não perde nada. O que muda é **o tamanho dela na tela**: o aviso
antigolpe vira `AvisoCompacto`, permanente e expansível, e a conversa recupera
pelo menos metade da altura ([R5](research.md#r5--aviso-de-segurança-proporcional)).

## Technical Context

**Language/Version**: Dart 3.11 / Flutter 3.41 (aplicativo) · Kotlin, só no
canal de plataforma novo · Java 21 (backend, só a migration)

**Primary Dependencies**: as que já existem — `flutter_svg`,
`shared_preferences`, `path_provider`, `android_intent_plus`. **Nenhuma
dependência nova de pacote.** Entram como *asset*: a família Atkinson
Hyperlegible Next (OFL 1.1), as ilustrações (licença aberta, registrada) e as
capturas dos guias.

**Storage**: aparelho — `shared_preferences` para a apresentação vista; arquivo
local para o progresso de aprendizado e para o último catálogo recebido (FR-024a),
que é o que deixa "Meus aplicativos", "Serviços sociais" e os passo a passo
funcionando sem internet. Servidor — PostgreSQL 16, só a coluna
`chave` e as linhas novas de `servico_conhecido` (V8 a V10).

**Testing**: `flutter_test` com a matriz de `test/suporte/aparelhos.dart`
(4 aparelhos × 3 escalas) cruzada com os 3 temas · JUnit 5 + Testcontainers
para as migrations (sobre `TesteComBanco`, apagando só o que criar) · os validadores
`validar_paleta.py` e `validar_tokens.py`

**Target Platform**: Android, com o `minSdk` que o projeto já usa
(`flutter.minSdkVersion`, sem mudança); o menor aparelho da matriz é 320×568

**Project Type**: Mobile + API

**Performance Goals**: troca de tela sem espera perceptível; passo a passo abre
o próximo passo imediatamente (as capturas são *assets* locais). O tamanho do
pacote cresce com as capturas: **teto de 8 MB** para `assets/guias/`, medido no
fim da fase de US5.

**Constraints**: nenhuma proteção existente retirada (FR-047); nenhum dado novo
no servidor; nenhuma permissão nova do Android, em especial a de sobreposição
(FR-029); todo valor visual por token (FR-032 da 002, `validar_tokens.py`).

**Scale/Scope**: **20 telas novas ou redesenhadas** de forma visível
(contando as variações de passo como uma tela), mais as 6 telas da 001 e da
003 fora do wireframe que entram no redesenho. ~16 guias de passo a passo, de 3
a 7 passos cada. Backend: 3 migrations.

## Constitution Check

*GATE: avaliado antes da Phase 0 e reavaliado depois da Phase 1.*

| Princípio | Situação | Como este plano cumpre |
|---|---|---|
| **I — Segurança acima de tudo** | ✅ | Threat model na spec. Nenhum endpoint novo: o Perfil usa dado que o aparelho já tem ([R10](research.md#r10--perfil-e-conta-sem-endpoint-novo)), então a sessão-chamariz não ganha caminho novo. As migrations V8 a V10 só acrescentam coluna e linhas, e mantêm `ck_servico_sensivel_nao_abre` |
| **II — Engenharia social** | ✅ | Análise por tela na spec. Decisões que vêm dela: sem permissão de sobreposição (FR-029), sem logotipo oficial no Memora ([R7](research.md#r7--ícone-de-aplicativo-vem-do-aparelho-serviço-sensível-não-usa-logotipo)), sem link para domínio que não é nosso ([R12](research.md#r12--compartilhar-site-de-ajuda-e-login-social-escondidos-até-existirem)), selo "Exemplo" desenhado sobre toda captura (FR-028) e o FR-036a |
| **III — Acessibilidade** | ✅ | Toda tela nova entra na matriz de aparelho × escala × tema (FR-044). A fonte escolhida é a de baixa visão. A ilustração cede espaço antes do texto (regra 7 da R2) |
| **IV — Spec antes de código** | ✅ | Spec com as três clarificações respondidas. Duas interpretações deste plano estão **registradas como tal** para a equipe poder reabrir: o pictograma no lugar do logotipo (R7) e as capturas reais (R6) |
| **V — Arquitetura limpa, feature-first** | ✅ | Features novas em `features/` (ver estrutura). Componentes que servem a mais de uma tela vão para o Design System, nunca para dentro de uma feature |
| **VI — A IA nunca age sozinha** | ✅ | Nenhuma ação nova. O fim do passo a passo **não abre nada**: oferece pedir à Memora, e o pedido vai pela conversa ao `AutorizadorDeAcao`, com a confirmação e o registro da 003 (FR-027). Offline ou com catálogo do aparelho, a oferta não aparece (revisão da #36) |
| **VII — Ensinar, não substituir** | ✅ | É o centro da feature: o passo a passo é ensino puro, e "abrir agora" só aparece **depois** do último passo, para aplicativo cotidiano |

**Nenhuma violação a justificar.** A seção *Complexity Tracking* fica vazia.

### Reavaliação depois da Phase 1

Mantida. O desenho da Phase 1 acrescentou um ponto que vale registrar ao lado do
Princípio I: o **canal de plataforma** `memora/aplicativos` é código nativo novo,
mas só **lê** — instalado ou não, e o ícone — e só para pacotes declarados em
`<queries>`. Ele não abre nada (abrir continua com o `AbridorDeAplicativo`),
não enxerga pacote fora de `<queries>` — o Android não deixa —, e o lado Kotlin
recusa argumento que não tenha forma de pacote antes de consultar o sistema
([contracts/canal-aplicativos.md](contracts/canal-aplicativos.md)).

## Project Structure

### Documentation (this feature)

```text
specs/004-redesenho-das-telas/
├── plan.md              # Este arquivo
├── research.md          # Phase 0 — R1 a R14
├── data-model.md        # Phase 1 — entidades do aparelho e as migrations V8 a V10
├── quickstart.md        # Phase 1 — cenários de validação (V1 a V14)
├── contracts/
│   ├── navegacao.md         # Mapa de telas, destinos e o caminho de volta
│   ├── componentes.md       # Componentes novos do Design System
│   ├── guias.md             # Formato do passo a passo
│   ├── catalogo.md          # V8 a V10 e o campo `chave` no contrato da 003
│   └── canal-aplicativos.md # Canal de plataforma memora/aplicativos
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
app/
├── assets/
│   ├── fontes/atkinson_hyperlegible_next/   # .ttf + OFL.txt          (novo)
│   ├── ilustracoes/                         # + Memora, portas, assuntos; LICENCAS.md
│   └── guias/<chave>/passo_N.png            # capturas, 3x            (novo)
├── android/app/src/main/
│   ├── AndroidManifest.xml                  # <queries> + 6 pacotes
│   └── kotlin/br/fatec/memora/
│       ├── MainActivity.kt                  # registra o canal
│       └── CanalDeAplicativos.kt            # estaInstalado / iconeDe   (novo)
├── lib/
│   ├── main.dart                            # home deixa de ser a casca de demonstração
│   ├── demonstracao/                        # sai
│   ├── design_system/
│   │   ├── tokens/                          # tipografia (fonte, destaque), dimensões de ilustração
│   │   └── componentes/
│   │       ├── avisos/aviso_compacto.dart           (novo)
│   │       ├── cartoes/cartao_de_porta.dart         (novo)
│   │       ├── conversa/balao_de_fala.dart          (novo)
│   │       ├── navegacao/cabecalho_de_tela.dart     (novo)
│   │       ├── guia/passo_ilustrado.dart            (novo)
│   │       ├── guia/indicador_de_passo.dart         (novo)
│   │       └── ilustracao/                          # Memora com expressões, medalhão
│   ├── features/
│   │   ├── casca/            # casca interna, barra inferior, pilhas por destino   (novo)
│   │   ├── apresentacao/     # Olá, Apresentação, Exemplo                          (novo)
│   │   ├── inicio/           # Início                                              (novo)
│   │   ├── hub/              # redesenho
│   │   ├── assistente/       # conversa e catálogos redesenhados
│   │   ├── aprendizado/      # guias, passo a passo, progresso                     (novo)
│   │   ├── ajuda/            # assuntos e a ajuda guiada da conversa               (novo)
│   │   ├── configuracoes/    # Aparência, Privacidade, Conta                       (novo)
│   │   ├── perfil/           # Perfil                                              (novo)
│   │   └── autenticacao/     # telas redesenhadas; FluxoAutenticacao monta a casca
│   ├── l10n/                 # + textos_guias, textos_ajuda, textos_casca
│   └── services/
│       └── aplicativos/      # porta + adaptador do canal memora/aplicativos      (novo)
└── test/
    ├── suporte/aparelhos.dart              # + cruzamento com os 3 temas
    ├── album/album_de_telas_test.dart      # renderiza tudo para a revisão   (novo)
    └── features/...                        # um diretório por feature nova

backend/src/main/resources/db/migration/
└── V8__chave_do_catalogo.sql, V9__aplicativos_do_wireframe.sql, V10__servicos_sociais.sql
```

**Structure Decision**: Mobile + API, na estrutura que as features 001 a 003 já
usam. Cada parte nova do aplicativo é uma feature própria em `features/`,
porque cada uma tem tela, estado e textos próprios; o que mais de uma usa (aviso
compacto, cartão de porta, balão, passo ilustrado) vai para o Design System. A
`TelaPerfil` de hoje (em `autenticacao/`) é substituída pela de `perfil/` e
apagada — resolve a pendência da #35 — e o `saida_limpa_armazenamento_test.dart`
passa a testar a tela de Conta, que é onde sair passa a morar (FR-019).

## Riscos

| Risco | Efeito | Resposta |
|---|---|---|
| A Atkinson, mais larga, estoura telas que hoje passam | Retrabalho nas telas da 001 e da 003 | Primeira tarefa da fundação: trocar a fonte e rodar a matriz **antes** de qualquer tela nova (R3) |
| Hub com 5 cartões ilustrados não cabe sem rolar a 150% no 320×568 | FR-017 reprova | A ilustração cede primeiro (regra 7); se ainda não couber, voltar à spec — não afrouxar o teste |
| Objeção acadêmica às capturas de outros aplicativos | Guias sem imagem | Plano B da R6: esquema vetorial, sem mudar código |
| Produção de conteúdo (~16 guias) ser o gargalo, e não o código | Prazo de novembro | Guias entram por item, junto com a linha do catálogo; o teste da R8 impede item sem guia. A US4 entrega com os guias dos aplicativos do wireframe primeiro |
| A revisão de design reprovar a linguagem tarde | Refazer todas as telas | A US2 vem primeiro e para numa revisão da equipe antes das demais (R14) |
| Pilhas por destino deixarem rota aberta na inatividade | FR-017 da 001 volta a furar | Caso novo em `fluxo_dentro_da_conta.dart`, com rota aberta em cada destino (R1) |

## Complexity Tracking

*Vazio — nenhuma violação da constituição a justificar.*
