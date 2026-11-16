# Implementation Plan: Redesenho final — a Memora ganha corpo, movimento e voz

**Branch**: `feature/013-redesenho-final` | **Date**: 2026-11-15 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/013-redesenho-final/spec.md`

## Summary

A 013 continua a 007 (Design System 2.0, PR #71). Ela dá à Memora um corpo
vetorial em 2.5D, animado pelo próprio aplicativo; faz toda troca de tela
deslizar com direção; põe a Memora acenando na abertura e no topo do Início;
limpa a conversa; refaz a barra inferior; e prende o texto da interface em
blocos de duas frases, sem palavras que diminuam a pessoa e sem emoji fora da
fala da IA. Nada muda em regra de negócio, servidor ou dado guardado — só a
apresentação, mais dois ajustes de texto no servidor (persona e mensagens de
erro).

A implementação vem em duas fases (pesquisa, R12): a **Fase A** independe da
#71 e pode ir para a `develop` já; a **Fase B** espera a #71 entrar, porque
toca os mesmos arquivos.

## Technical Context

**Language/Version**: Dart 3.11 / Flutter 3.41.6 (CI fixado em 3.47.7 na
`develop`; a máquina do Henrique roda 3.44.8). Java 21 no backend (só texto).

**Primary Dependencies**: as que já existem — `flutter_svg` (ilustrações
atuais), Material Icons do SDK (variante arredondada). **Nenhuma dependência
nova.**

**Storage**: N/A. A preferência "reduzir movimento" já existe
(`PreferenciaAparencia`).

**Testing**: `flutter test` (widget e unidade), matriz de aparelhos
(`test/suporte/aparelhos.dart`, 4 × 3), álbum de telas, `validar_tokens.py`,
`validar_paleta.py`; JUnit para o portão de texto do backend.

**Target Platform**: Android (o projeto é só Android). Abertura nativa com
recursos `res/` (claro e escuro; Android 12+ com a tela de abertura do sistema).

**Project Type**: aplicativo móvel + API (a API só muda texto).

**Performance Goals**: transição ≤ 500 ms (SC-004); < 5% de quadros acima de
16 ms na abertura, trocas e gestos (SC-005); abertura ≤ carregamento + um
aceno (~1,5 s, SC-009).

**Constraints**: WCAG 2.2 AA, 48 dp, texto a 200%, "reduzir movimento" (V9),
nenhum literal visual fora de tokens (FR-032 da 002), aparelho de entrada.

**Scale/Scope**: ~30 telas (25 de hoje + Localizador, 3 diálogos e o seletor de
seções da #71); 16 guias; 8 arquivos de texto em `l10n/`.

## Constitution Check

*GATE: antes da pesquisa e de novo depois do desenho.*

| Princípio | Como a 013 cumpre | Situação |
|---|---|---|
| **I. Segurança** | Voz só no aparelho (FR-034); nenhum dado novo; animação nunca esconde aviso (FR-033) | ✅ |
| **II. Engenharia social** | Tabela "como um golpista exploraria" na spec; FR-035 contra a Memora falsa no WhatsApp; toque não se desvia durante transição (FR-014) | ✅ |
| **III. Acessibilidade** | "Reduzir movimento" em tudo; Memora fora do leitor de tela; 8 dp entre a Memora e alvos; texto vence a Memora a 200% (FR-041) | ✅ |
| **IV. Spec antes de código** | Spec com clarify registrado. **Status Draft**: precisa de aprovação da equipe antes do `implement`, e tela nova só entra na `master` depois da revisão do Henrique no celular (T116 da 004) | ⚠️ aprovar |
| **V. Arquitetura** | Componentes novos no Design System (`componentes/`, `navegacao/`); a abertura como feature própria; `limitarEmoji` no domínio da assistente | ✅ |
| **VI. A IA nunca age sozinha** | Sem ação nova da IA; o limite de emoji é defesa no aplicativo, não depende do modelo | ✅ |
| **VII. Ensinar** | Nada passa a ser feito pela pessoa; a direção das transições ensina a navegação | ✅ |
| **Design System** | Cores da Memora em tokens nos 3 temas; animação por `MemoraMovimento` | ✅ |

**Re-check pós-desenho**: sem violações. Nada a justificar em Complexity
Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/013-redesenho-final/
├── spec.md
├── plan.md
├── research.md          # R1–R12
├── data-model.md        # estado de interface
├── quickstart.md        # V1–V20
├── contracts/
│   └── componentes.md
├── checklists/
│   └── requirements.md
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
app/lib/
├── main.dart                                   # runApp antes de carregar (A)
├── design_system/
│   ├── tokens/
│   │   ├── cores_da_memora.dart                # novo (A); integra em cores.dart (B)
│   │   └── movimento.dart                      # durações de gesto e transição
│   ├── componentes/ilustracao/
│   │   ├── memora_animada/                     # novo (A)
│   │   │   ├── memora_animada.dart
│   │   │   ├── poses.dart
│   │   │   └── pintores/                       # uma camada por arquivo
│   │   └── memora_personagem.dart              # passa a usar a MemoraAnimada (B)
│   ├── componentes/dialogos/                   # transições de diálogo e folha (A)
│   ├── componentes/navegacao/navegacao_inferior.dart   # barra refeita (B)
│   ├── navegacao/                              # novo (A)
│   │   ├── rota_memora.dart
│   │   └── troca_de_destino.dart
│   └── temas/temas_memora.dart                 # transição no tema (B)
├── features/
│   ├── abertura/presentation/abertura_memora.dart     # novo (A)
│   ├── casca/casca_interna.dart                # TrocaDeDestino + RotaMemora (A)
│   ├── assistente/domain/limitar_emoji.dart    # novo (A)
│   ├── inicio/…                                # Memora no topo (B)
│   ├── assistente/presentation/telas/tela_conversa.dart  # conversa limpa (B)
│   └── aprendizado/data/guias/                 # textos reescritos (B)
└── l10n/                                       # textos revistos (A e B)

app/android/app/src/main/res/                   # abertura nativa (A)
app/test/
├── design_system/texto_da_interface_test.dart  # portão (A)
├── design_system/memora_animada_test.dart      # (A)
└── design_system/rota_memora_test.dart         # (A)

backend/src/main/java/br/fatec/memora/
├── assistente/infra/PersonaDaMemora.java       # regra do emoji (A)
└── autenticacao/api/, assistente/api/          # mensagens sem emoji (A)
```

**Structure Decision**: aplicativo + API já existentes. Tudo o que é visual e
reutilizável vai para o Design System; a abertura é uma feature própria
(`features/abertura/`) porque tem fluxo e falha próprios.

## Fases de implementação

| Fase | Conteúdo | Depende de |
|---|---|---|
| **A** | Memora vetorial + tokens dela; rota, troca de destino, diálogo e folha; abertura (nativa e do aplicativo); portão de texto e revisão de `l10n/` que a #71 não toca; `limitarEmoji`; persona e erros do backend | nada |
| **B** | Ligar a `MemoraPersonagem`; tema; Início com a Memora no topo; conversa limpa; barra inferior; voz no aparelho; FR-035; guias reescritos; Localizador e diálogos; álbum e revisão final | #71 na `develop` |

## Riscos

| Risco | Mitigação |
|---|---|
| O desenho da Memora em código não ficar à altura da folha de referência | Ela entra primeiro na galeria e no álbum; o Henrique aprova no celular antes de a Fase B trocar as imagens |
| Desempenho em aparelho de entrada (só há um S20 FE) | Camada de repintura própria, parar fora da tela; medir em perfil; emulador com CPU limitada se ninguém tiver Galaxy A |
| A #71 mudar antes de entrar | As tarefas da Fase B são revistas quando ela entrar (decisão do Henrique) |
| Reescrever textos quebrar testes que procuram texto | Os testes localizam por chave (regra do projeto); os que procuram frase são atualizados junto, na mesma tarefa |
