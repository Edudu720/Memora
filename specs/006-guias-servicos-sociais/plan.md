# Implementation Plan: Guias Visuais de Serviços Sociais (Censura por Blur + Seções)

**Branch**: `006-guias-servicos-sociais` | **Date**: 2026-11-13 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/006-guias-servicos-sociais/spec.md`

---

## Summary

Implementar os guias visuais completos dos serviços sociais fornecidos em `apps/GOV/` (40 capturas), `apps/Serasa/` (29 capturas úteis) e `apps/Correios/` (8 capturas), resolvendo dois desafios centrais:

1. **Privacidade Absoluta por Blur (`scripts/censurar_servicos_sociais.py`)**: Backup seguro dos originais em `apps/.originais/` e aplicação de **Gaussian Blur (`radius >= 22`)** em todas as informações pessoais e sigilosas identificadas na inspeção visual (CPF `XXX.XXX.XXX-XX`, nome completo do titular, saudação nominal `"Oi, [Titular]"`, iniciais do avatar, Serasa Score pessoal, código de rastreio e remoção do arquivo duplicado dos Correios dentro de `apps/Serasa/`), otimizando as imagens para respeitar o teto de **8 MB** em `app/assets/guias/`.
2. **Navegação por Seções em Serviços Extensos (`SecaoDoGuia` + `TelaSeletorDeSecao`)**: Evitar que a pessoa idosa tenha que avançar por 40 telas no Gov.br ou 29 no Serasa. Ao tocar em um guia seccionado no catálogo, o app exibe primeiro `TelaSeletorDeSecao` (usando `CabecalhoDeTela`, `BalaoDeFala` e `CartaoDePorta`), permitindo escolher exatamente o assunto desejado (entre 3 e 7 passos por seção) e ir direto ao `TelaPassoAPasso`, além de integrar as 3 logos oficiais em `IconeDoAplicativo.dart`.

---

## Technical Context

**Language/Version**: Dart 3.11 / Flutter 3.41 (aplicativo) · Python 3.11+ com Pillow (pipeline de processamento e censura de imagens)

**Primary Dependencies**: Apenas dependências já existentes (`flutter_svg`, `shared_preferences`, `path_provider`, `android_intent_plus`). **Nenhuma dependência nova de pacote.**

**Storage**: Assets locais embarcados em `app/assets/guias/{gov-br,serasa,correios}/` e `app/assets/ilustracoes/`; progresso de aprendizado local por seção (`chaveGuia:chaveSecao`) via `ProgressoDeAprendizado`.

**Testing**: `flutter_test` (matriz 4 aparelhos × 3 escalas até 200% × 3 temas), `catalogo_e_guias_test.dart`, `servico_sensivel_test.dart`, `validar_tokens.py`.

**Target Platform**: Android (`flutter.minSdkVersion`), menor aparelho da matriz 320×568.

**Project Type**: Mobile App (Flutter Clean Architecture / Feature-First) + Script Pipeline Python.

**Performance Goals**: Abertura instantânea das seções e capturas a partir de assets locais; orçamento total de `app/assets/guias/` abaixo de **8 MB** (~4,5 MB estimados após otimização).

**Constraints**: Zero literais visuais fora dos tokens (`validar_tokens.py`); campos de senha sempre vazios com aviso `FR-032`; área de toque mínima 48×48 dp; contraste WCAG 2.2 AA; nenhuma permissão Android nova.

**Scale/Scope**: 3 serviços sociais extensos (Gov.br: 6 seções · Serasa: 5 seções · Correios: 2 seções), 1 nova tela (`TelaSeletorDeSecao`), atualização de `Guia`/`CapturaDoGuia`/`IconeDoAplicativo`/`FluxoAutenticacao`, 3 logos oficiais 512×512.

---

## Constitution Check

*GATE: avaliado antes da Phase 0 e reavaliado após a Phase 1.*

| Princípio | Situação | Como este plano cumpre |
|---|---|---|
| **I. Segurança Acima de Tudo** | Aprovado | Threat modeling documentado na `spec.md`; todo CPF, nome, score e foto pessoal censurado por Gaussian Blur (`r >= 22`) com revisão visual pós-processamento; originais isolados em `apps/.originais/` (`.gitignore`). |
| **II. Segurança Contra Engenharia Social** | Aprovado | Passos com login/CPF/senha mantêm `temCampoDeSenha: true` e aviso permanente da `FR-032`; botão *"A minha tela está diferente"* mantido em toda seção; nenhuma abertura externa automática. |
| **III. Acessibilidade como Requisito** | Aprovado | `TelaSeletorDeSecao` evita fadiga cognitiva de 40 telas; usa `CartaoDePorta` (>= 48dp, ícone + texto + subtítulo), contraste WCAG 2.2 AA, TalkBack completo e suporte a 200% sem overflow. |
| **IV. Especificação Antes de Código** | Aprovado | `spec.md`, `research.md`, `data-model.md`, `contracts/` e `quickstart.md` produzidos antes de qualquer edição em `app/lib/`. |
| **V. Arquitetura Limpa e Feature-First** | Aprovado | Entidade `SecaoDoGuia` em `features/aprendizado/domain/guia.dart`; UI em `features/aprendizado/presentation/tela_seletor_de_secao.dart`; roteamento isolado em `FluxoAutenticacao._abrirGuia`; zero regra de negócio em widget. |
| **VI. A IA Nunca Age Sozinha** | Aprovado | Passo a passo 100% educativo; botão final redireciona para `TelaConversa` apenas se a pessoa tocar e confirmar. |

---

## Project Structure

### Documentation (this feature)

```text
specs/006-guias-servicos-sociais/
├── spec.md                              # Requisitos, Threat Modeling e UX Review
├── plan.md                              # Este plano (/speckit-plan)
├── research.md                          # Phase 0: Inventário das 77 capturas, mapa de Blur e orçamento 8MB
├── data-model.md                        # Phase 1: SecaoDoGuia, Guia, CapturaDoGuia e fluxo de navegação
├── quickstart.md                        # Phase 1: Cenários de validação e comandos
└── contracts/
    └── guias-com-secoes.md              # Phase 1: Contrato de censura por Blur e UI de seções
```

### Source Code (repository root)

```text
scripts/
└── censurar_servicos_sociais.py         # Backup em .originais, Gaussian Blur nas PII, logos 512x512 e otimização <= 8MB

app/
├── assets/
│   ├── ilustracoes/
│   │   ├── gov_br_logo.png              # Logo oficial Gov.br 512x512
│   │   ├── serasa_logo.png              # Logo oficial Serasa 512x512
│   │   └── correios_logo.png            # Logo oficial Correios 512x512
│   └── guias/
│       ├── CAPTURAS.md                  # Registro atualizado das capturas (data, versão, aparelho)
│       ├── gov-br/                      # Capturas censuradas e otimizadas (passo_1..passo_N)
│       ├── serasa/                      # Capturas censuradas e otimizadas (passo_1..passo_N)
│       └── correios/                    # Capturas censuradas e otimizadas (passo_1..passo_N)
├── lib/
│   ├── design_system/componentes/ilustracao/
│   │   └── icone_do_aplicativo.dart     # Carrega gov_br_logo.png, serasa_logo.png e correios_logo.png
│   ├── features/
│   │   ├── aprendizado/
│   │   │   ├── domain/guia.dart         # SecaoDoGuia, extensões de Guia e CapturaDoGuia
│   │   │   ├── data/guias/
│   │   │   │   ├── gov_br.dart          # 6 seções temáticas (3 a 7 passos cada)
│   │   │   │   ├── serasa.dart          # 5 seções temáticas (4 a 6 passos cada)
│   │   │   │   └── correios.dart        # 2 seções temáticas (4 passos cada)
│   │   │   └── presentation/
│   │   │       ├── tela_seletor_de_secao.dart  # Nova tela de escolha de seção acessível
│   │   │       └── tela_passo_a_passo.dart     # Suporte a título/contexto de seção e progresso
│   │   └── autenticacao/presentation/
│   │       └── fluxo_autenticacao.dart  # _abrirGuia decide entre TelaSeletorDeSecao e TelaPassoAPasso
│   └── l10n/
│       └── textos_guias.dart            # Textos das seções, passos e descrições de captura (TalkBack)
└── test/
    └── features/aprendizado/
        ├── catalogo_e_guias_test.dart   # Validação de seções (3..7 passos), capturas e teto 8MB
        └── tela_seletor_de_secao_test.dart # Testes de acessibilidade e matriz 4x3x3
```

**Structure Decision**: Reaproveitamento integral da arquitetura Feature-First existente em `app/lib/features/aprendizado/` e do pipeline Python em `scripts/`, mantendo compatibilidade total com os 13 guias não seccionados já existentes.

---

## Complexity Tracking

Nenhuma violação à Constituição identificada. Todas as adições seguem os padrões do Design System (002), Catálogo/Assistente (003) e Guias (004).
