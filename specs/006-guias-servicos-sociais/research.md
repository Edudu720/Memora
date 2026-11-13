# Phase 0 Research: Serviços Sociais (Gov.br, Serasa, Correios)

**Feature**: `006-guias-servicos-sociais` | **Data**: 2026-11-13

---

## R1 — Inventário Visual e Mapa de Censura por Blur (Gaussian Blur)

Todas as 77 capturas de tela e 3 logotipos fornecidos em `apps/` foram inspecionados visualmente por folhas de contato antes do planejamento.

### 1. Gov.br (`apps/GOV/` — 40 capturas + `logo.png`)

| Arquivo / Índice | Tela | Dados Sensíveis Detectados | Ação de Censura (Blur) |
|---|---|---|---|
| `[36]` (`10.54.39 (36).jpeg`) | Digite sua senha (`sso.acesso.gov.br`) | **CPF real completo** (`524.957.408-47`) | **Gaussian Blur (`r=26`)** sobre a linha inteira do número do CPF (`y ~ 350..420`). Campo de senha já está vazio (atende FR-032). |
| `[37]` (`10.54.39 (37).jpeg`) | Menu Atalhos `gov.br` | **Nome completo** (`EDUARDO JUNCKER TORAS`) e **foto de perfil** (círculo central e miniatura topo direito) | **Gaussian Blur (`r=26`)** no nome completo e nas duas fotos de perfil. |
| `[39]` (`10.54.39 (39).jpeg`) | Minha área `gov.br` | **Nome completo** (`Olá, EDUARDO JUNCKER TORAS`), **foto de perfil** e **miniatura topo direito** | **Gaussian Blur (`r=26`)** sobre o nome após `"Olá,"`, foto de perfil e miniatura do cabeçalho. |
| `[1..35, 38, 40]` | Portal, Perfis, Categorias, Certidões, Agenda, Galeria de Apps, Ouvidoria, Tela inicial CPF vazio | Telas públicas/institucionais sem dados pessoais identificáveis | Manter nítidas; otimizar resolução/peso. |
| `logo.png` | Logotipo oficial `gov.br` | Nenhum | Converter para PNG quadrado 512×512 (`app/assets/ilustracoes/gov_br_logo.png`). |

### 2. Serasa (`apps/Serasa/` — 29 capturas úteis + 1 duplicata + `serasa_logo.jfif`)

| Arquivo / Índice | Tela | Dados Sensíveis Detectados | Ação de Censura (Blur) |
|---|---|---|---|
| `[4], [5], [6]` (`18.53.36 (4)-(6).jpeg`) | Tela Início autenticada | **Primeiro nome** (`Oi, Eduardo`) e **iniciais no avatar** (`ET` no círculo rosa superior direito) | **Gaussian Blur (`r=24`)** sobre `"Eduardo"` e sobre o círculo de iniciais `"ET"`. |
| `[8], [9]` (`18.53.36 (8)-(9).jpeg`) | Serasa Score | **Pontuação pessoal de crédito** (`653 / 1000` e barra/status) e **iniciais `ET`** em `[9]` | **Gaussian Blur (`r=26`)** sobre o número `653` e sobre o círculo `"ET"`. |
| `[13]` (`18.53.36 (13).jpeg`) | Meu CPF | **Primeiro nome** (`Olá, Eduardo`) e **iniciais `ET`** | **Gaussian Blur (`r=24`)** sobre `"Eduardo"` e sobre o círculo `"ET"`. |
| `[22]` (`18.53.36 (22).jpeg`) | Serviços | **Iniciais `ET`** no avatar superior direito | **Gaussian Blur (`r=24`)** sobre o círculo `"ET"`. |
| `[28]` (`18.53.36 (28).jpeg`) | Print do "Melhor Rastreio / Correios" | Arquivo colocado por engano na pasta `Serasa/` (duplicata do `[1]` dos Correios) | **Excluir** do guia do Serasa (mantido apenas o backup em `apps/.originais/`). |
| `[1..3, 7, 10..12, 14..21, 23..27, 29]` | Landing page, Menu, Empréstimos, Saúde financeira, Dívidas/Acordos (sem dívidas), Serviços | Sem dados identificadores pessoais | Manter nítidas; otimizar resolução/peso. |
| `serasa_logo.jfif` | Logotipo oficial Serasa | Nenhum | Converter para PNG 512×512 (`app/assets/ilustracoes/serasa_logo.png`). |

### 3. Correios (`apps/Correios/` — 8 capturas + `correios-perfil-facebook.png`)

| Arquivo / Índice | Tela | Dados Sensíveis Detectados | Ação de Censura (Blur) |
|---|---|---|---|
| `[1]` (`18.53.09 (1).jpeg`) | Rastreamento detalhado | **Código de rastreio** no topo e **nomes de cidades/unidades** (`RIO DE JANEIRO`, `SOROCABA`, `SAO ROQUE`) / datas específicas | **Gaussian Blur (`r=22`)** sobre o código de rastreio e cabeçalho de origem/atualização, preservando a leitura didática da linha do tempo de entrega. |
| `[2]..[8]` | Portal `correios.com.br`, Menu, Acompanhe seu Objeto, Calcular Frete, Rastreamento, Login Meu Correios, Captcha web | Campos de entrada vazios; nenhum dado pessoal | Manter nítidas; otimizar resolução/peso. |
| `correios-perfil-facebook.png` | Logotipo oficial Correios | Nenhum | Converter para PNG 512×512 (`app/assets/ilustracoes/correios_logo.png`). |

---

## R2 — Orçamento de Assets (`<= 8 MB` em `app/assets/guias/`)

- **Decisão**: O teste `catalogo_e_guias_test.dart` impõe um teto estrito de **8 MB** para toda a pasta `app/assets/guias/`. Atualmente a pasta ocupa **2,12 MB** (com os guias de WhatsApp, Telegram, Facebook e os placeholders anteriores), restando **5,88 MB** de margem.
- **Estratégia**:
  1. Redimensionar as capturas de serviços sociais para largura máxima de **480 px** (mantendo proporção 9:20, nítidas em qualquer celular dentro da caixa de captura do `PassoIlustrado`).
  2. Comprimir como **PNG quantizado (256 cores, `optimize=True`)** ou permitir **`.jpg` (qualidade 80)** para capturas fotográficas/densas caso o PNG ultrapasse ~70 KB por imagem.
  3. **Estimativa**: ~45–55 capturas selecionadas nas seções × ~45 KB = **~2,4 MB** adicionais. Total final estimado: **~4,5 MB** (< 60% do limite de 8 MB).
- **Alternativas consideradas**: Incluir todas as 77 capturas em resolução original 720×1600 PNG (~180 KB cada = ~14 MB), o que violaria o teto de 8 MB e tornaria o APK pesado e redundante (especialmente as 16 telas repetidas da Galeria de Apps do Gov.br `[19..34]`).

---

## R3 — Organização em Seções para Guias Extensos

- **Decisão**: Manter a regra de ouro do `Guia` (`3 <= passos <= 7` por fluxo percorrido) introduzindo **seções temáticas (`SecaoDoGuia`)** dentro de um `Guia`.
- **Justificativa**:
  - Pessoas idosas se cansam e abandonam fluxos longos (> 7 passos).
  - Quem abre o **Gov.br** normalmente quer resolver **uma tarefa específica** (ex.: *entrar na conta*, *baixar uma certidão*, *ver documentos*), nunca ler 40 telas seguidas.
- **Estrutura de Seções Planejada**:
  - **Gov.br** (6 seções, 3 a 7 passos cada):
    1. *Entrar na sua conta Gov.br* (CPF e senha oficial — FR-032 ativo)
    2. *Minha Área e Carteira de Documentos*
    3. *Baixar Certidões e Consultar Agenda*
    4. *Buscar Serviços por Perfil e Categoria*
    5. *Aplicativos Oficiais do Governo (Meu INSS, SUS, Carteira de Trabalho, Cadastro Único)*
    6. *Ouvidoria (Fazer Elogio, Reclamação ou Denúncia)*
  - **Serasa** (5 seções, 4 a 6 passos cada):
    1. *Conhecer a Tela Inicial e o Menu*
    2. *Consultar seu Serasa Score*
    3. *Ver Dívidas e Negociar Acordos*
    4. *Proteger seu CPF e Ver Vazamentos*
    5. *Outros Serviços (Validador de Boleto, Cadastro Positivo e Ajuda)*
  - **Correios** (2 seções, 4 passos cada):
    1. *Rastrear uma Encomenda*
    2. *Calcular Frete e Acessar o Meu Correios*

---

## R4 — Logotipos no Design System

- **Decisão**: Converter `logo.png` (Gov.br), `serasa_logo.jfif` (Serasa) e `correios-perfil-facebook.png` (Correios) para PNGs quadrados 512×512 limpos em `app/assets/ilustracoes/`, carregando-os em `IconeDoAplicativo.dart` seguindo exatamente o padrão já validado para `whatsapp` e `facebook`.
