# Especificação: Guias Visuais de Serviços Sociais com Censura por Blur e Navegação por Seções

**Feature Branch**: `006-guias-servicos-sociais`
**Criado em**: 2026-11-13
**Status**: Planejamento
**Relacionamento**: Estende a experiência de passo a passo da feature `004-redesenho-das-telas` para serviços sociais extensos (**Gov.br**, **Serasa** e **Correios**).

---

## Resumo do Pedido

Implementar no Memora os guias visuais completos dos serviços sociais fornecidos em `apps/GOV/`, `apps/Serasa/` e `apps/Correios/`, garantindo:
1. **Análise e Censura por Blur (Desfoque)**: Toda captura de tela é analisada individualmente e tem qualquer dado pessoal, sigiloso ou financeiro censurado via desfoque Gaussiano (Blur), mantendo backup dos originais em `apps/.originais/` (protegido por `.gitignore`).
2. **Navegação por Seções em Serviços Extensos**: Ao selecionar um serviço com muitas telas (como **Gov.br** com 40 capturas e **Serasa** com 29 capturas úteis), a pessoa idosa escolhe primeiro **qual seção/tema deseja aprender** (ex.: *Entrar na conta*, *Baixar certidões*, *Consultar Score*, *Rastrear encomenda*), indo direto ao ponto desejado sem precisar percorrer dezenas de telas irrelevantes.
3. **Logotipos Oficiais**: Integrar as logos oficiais de Gov.br, Serasa e Correios em `IconeDoAplicativo.dart`.

---

## User Stories

### US1 — Escolher uma Seção Específica em Serviços Extensos (Prioridade: P1)
Como pessoa idosa usando o Memora, ao tocar em **Gov.br**, **Serasa** ou **Correios** no catálogo de Serviços Sociais, quero ver uma lista clara de assuntos/seções (ex.: *"Entrar na conta Gov.br"*, *"Baixar certidões"*, *"Consultar meu Score"*) para ir direto ao que preciso aprender sem me perder em 40 telas seguidas.

**Critérios de Aceite**:
- Guias com seções exibem uma tela intermediária acessível (`TelaSeletorDeSecao`) listando cada seção com título claro, descrição curta de 1 linha e quantidade de passos (entre 3 e 7 passos).
- Ao escolher uma seção, abre-se o `TelaPassoAPasso` apenas com os passos daquela seção.
- Guias curtos (sem seções, como WhatsApp, Instagram, etc.) continuam abrindo diretamente no `TelaPassoAPasso` sem nenhuma regressão.

### US2 — Privacidade Garantida por Blur em Todas as Capturas (Prioridade: P1)
Como responsável técnico / usuário que forneceu as capturas, quero que todo dado pessoal ou sigiloso (CPF, nome completo, iniciais, foto de perfil, pontuação do Score, códigos de rastreio pessoais) seja censurado com **Gaussian Blur**, sem exceção, antes de entrar nos assets do aplicativo.

**Critérios de Aceite**:
- Nenhuma informação pessoal real (ex.: CPF `524.957.408-47`, nome `EDUARDO JUNCKER TORAS`, `"Oi, Eduardo"`, iniciais `ET`, Score `653`) permanece legível em `apps/GOV/`, `apps/Serasa/`, `apps/Correios/` ou `app/assets/guias/`.
- Capturas duplicadas ou fora de pasta (ex.: print dos Correios dentro de `apps/Serasa/`) são removidas do guia correspondente.
- O tamanho total de `app/assets/guias/` permanece abaixo do teto de **8 MB** exigido por `catalogo_e_guias_test.dart`.

### US3 — Logos Oficiais e Acolhimento Final com Abertura/Dúvidas (Prioridade: P2)
Como pessoa idosa, quero reconhecer facilmente os serviços sociais pelos seus ícones oficiais no catálogo e, ao concluir uma seção, poder tirar dúvidas específicas com a Memora ou pedir ajuda para abrir o serviço.

**Critérios de Aceite**:
- `IconeDoAplicativo` renderiza `gov_br_logo.png`, `serasa_logo.png` e `correios_logo.png`.
- O último passo de cada seção mantém o acolhimento da Memora e o botão *"Ficou com alguma dúvida? Pode perguntar"*, redirecionando para o chatbot com contexto da seção concluída.

---

## Threat Modeling e Segurança Contra Engenharia Social (Constituição I e II)

| Ameaça / Risco | Dados Envolvidos | Mitigação |
|---|---|---|
| **Vazamento de PII nas capturas embarcadas no APK** | CPF real (`524.957.408-47`), nome completo (`EDUARDO JUNCKER TORAS`), pontuação de crédito (`653/1000`), avatar e iniciais (`ET`), código de rastreio | Pipeline determinístico `scripts/censurar_servicos_sociais.py` aplica Gaussian Blur (`radius >= 24`) em todas as regiões identificadas; revisão visual pós-processamento obrigatória; originais isolados em `apps/.originais/` (`.gitignore`). |
| **Golpista imitando tela de login / pedido de senha** | Senha Gov.br, senha Serasa, senha Meu Correios | Todo passo com tela de login/senha marca `temCampoDeSenha: true`, exibindo o aviso permanente da **FR-032**: *"A sua senha só se digita no aplicativo oficial, nunca no Memora"*, além do botão *"A minha tela está diferente"*. |
| **Confusão ou clique acidental em serviço sensível** | Abertura externa de app/navegador | `TelaPassoAPasso` nunca abre o app externo diretamente; orienta passo a passo dentro do Memora e, quando aplicável, encaminha para a conversa segura com a Memora. |

---

## Requisitos Funcionais

- **FR-001 (Seções no Guia)**: A entidade `Guia` suporta uma lista opcional de `SecaoDoGuia` (`titulo`, `subtitulo`, `icone`, `precisaTerEmMaos`, `passos` entre 3 e 7 itens).
- **FR-002 (Seletor de Seções Acessível)**: Quando `guia.secoes` não está vazio, `TelaSeletorDeSecao` é exibida antes do `TelaPassoAPasso`, utilizando `CabecalhoDeTela` (botão Voltar), `BalaoDeFala` da Memora e `CartaoDePorta` (alvo >= 48x48 dp, TalkBack completo, escala até 200%, sem overflow na matriz 4×3×3).
- **FR-003 (Censura por Blur)**: Todas as capturas em `app/assets/guias/{gov-br,serasa,correios}/` são processadas com Gaussian Blur nas regiões pessoais/sigilosas e otimizadas para manter o total de `app/assets/guias/` <= 8 MB.
- **FR-004 (Logos Oficiais)**: As logos de Gov.br, Serasa e Correios são convertidas para PNG 512×512 limpo em `app/assets/ilustracoes/` e integradas a `IconeDoAplicativo.dart`.
- **FR-005 (Compatibilidade de Testes)**: Todos os portões de `catalogo_e_guias_test.dart`, `servico_sensivel_test.dart`, `validar_tokens.py` e `flutter analyze` permanecem verdes.
