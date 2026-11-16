# Phase 1 Data Model: Guias Seccionados de Serviços Sociais

**Feature**: `006-guias-servicos-sociais` | **Data**: 2026-11-13

---

## Entidades do Domínio (`app/lib/features/aprendizado/domain/guia.dart`)

### 1. `SecaoDoGuia` (Nova Entidade Imutável)
Representa um tema específico dentro de um guia extenso (ex.: *"Baixar Certidões"* no Gov.br ou *"Consultar Score"* no Serasa).

| Campo | Tipo | Obrigatório | Regra / Validação |
|---|---|---|---|
| `chave` | `String` | Sim | Identificador único dentro do guia (ex.: `'entrar-conta'`, `'certidoes'`). |
| `titulo` | `String` | Sim | Título curto e literal para o cartão de escolha (ex.: *"Entrar na conta Gov.br"*). |
| `subtitulo` | `String` | Sim | Uma linha explicando o que a pessoa vai aprender (ex.: *"Usar CPF e senha para acessar seus dados"*). |
| `icone` | `IconData` | Sim | Ícone do Material que acompanha o texto (nunca isolado — Constituição III). |
| `passos` | `List<Passo>` | Sim | Entre `Guia.minimoDePassos` (3) e `Guia.maximoDePassos` (7) passos. |
| `precisaTerEmMaos` | `List<String>` | Não | Itens específicos da seção (se vazio, herda `guia.precisaTerEmMaos`). |

### 2. `Guia` (Extensão Compatível com Código Existente)
Mantém todos os campos atuais para **zero regressão** nos 16 guias existentes e nos testes da Feature 004, adicionando `secoes`:

| Campo | Tipo | Padrão | Regra |
|---|---|---|---|
| `secoes` | `List<SecaoDoGuia>` | `const <SecaoDoGuia>[]` | Quando vazio, o guia abre direto em `TelaPassoAPasso` usando `passos`. Quando não vazio, abre `TelaSeletorDeSecao` primeiro. |
| `temSecoes` (getter) | `bool` | `secoes.isNotEmpty` | Indica ao fluxo de navegação se deve exibir `TelaSeletorDeSecao`. |
| `todosOsPassos` (getter) | `List<Passo>` | — | Retorna `passos` ou a união dos `passos` de todas as `secoes`, garantindo que validadores de capturas (`CAPTURAS.md`, `temCampoDeSenha`, `descricaoDaCaptura`) inspecionem **todas** as imagens do guia. |

### 3. `CapturaDoGuia` (Extensão para Múltiplas Capturas de Seção)
Atualmente `CapturaDoGuia` tem `chave`, `numero` e `caminho => 'assets/guias/$chave/passo_$numero.png'`.

- **Decisão**: Manter `caminho` determinístico (`assets/guias/$chave/passo_$numero.$extensao`), adicionando `final String extensao;` com valor padrão `'png'` (permite `'jpg'` caso alguma captura densa precise de compressão JPEG para respeitar o teto de 8 MB, mantendo todas as capturas existentes intactas em `.png`).
- Novas constantes `static const CapturaDoGuia` para:
  - `govBr1..govBr26` (cobrindo os passos únicos das 6 seções)
  - `serasa1..serasa22` (cobrindo os passos únicos das 5 seções)
  - `correios1..correios8` (cobrindo os passos únicos das 2 seções)

---

## Fluxo de Navegação

```mermaid
flowchart LR
    Catalogo["TelaCatalogo (Serviços Sociais)"] -->|Toque em item| VerificaSecoes{"guia.temSecoes?"}
    VerificaSecoes -->|Não (guia curto)| PassoAPasso["TelaPassoAPasso (guia.passos)"]
    VerificaSecoes -->|Sim (Gov.br / Serasa / Correios)| Seletor["TelaSeletorDeSecao (Escolher assunto)"]
    Seletor -->|Toque numa SecaoDoGuia| PassoSecao["TelaPassoAPasso (passos da seção escolhida)"]
    PassoSecao -->|Último passo: Tirar dúvida| Conversa["TelaConversa (com contexto da seção)"]
```

---

## Impacto em `ProgressoDeAprendizado`
- Quando a pessoa conclui uma seção, o progresso é salvo com a chave composta `'${guia.chave}:${secao.chave}'` (e opcionalmente marca a seção como concluída visualmente com um selo de check verde + texto *"Já aprendeu"* no `TelaSeletorDeSecao`, sem quebrar a leitura de progresso dos guias simples).
