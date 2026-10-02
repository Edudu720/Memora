# Data Model: Redesenho das telas

**Feature**: [spec.md](spec.md) · **Plano**: [plan.md](plan.md)

Esta feature cria **pouco dado**, e quase todo ele vive no aparelho. O servidor
ganha uma coluna e algumas linhas no catálogo, e nenhum dado sobre a pessoa.

---

## No aparelho

### Guia (conteúdo, embarcado)

O caminho de aprendizado de um item do catálogo. É **conteúdo escrito pela
equipe**, compilado no aplicativo; não é dado da pessoa e não muda em uso.

| Campo | Tipo | Regra |
|---|---|---|
| `chave` | texto | Igual à `chave` de um item de `servico_conhecido` (ver abaixo). Única entre os guias |
| `titulo` | texto | "Aprender a usar o TikTok". Vem de `l10n/textos_guias.dart` |
| `precisaTerEmMaos` | lista de textos | Obrigatória para serviço sensível (FR-032); pode ser vazia para cotidiano |
| `passos` | lista de **Passo**, ordenada | De 3 a 7 passos. Menos de 3 não é caminho; mais de 7 cansa e vira dois guias |
| `capturadoEm` | data | Quando as capturas foram feitas (R6) |
| `versaoCapturada` | texto | Versão do aplicativo do outro lado, como aparece na loja |

**Validação** (verificada por teste, não em uso): toda `chave` de
`servico_conhecido` nas migrations tem um Guia; todo Guia tem uma `chave` que
existe nas migrations; todo guia de serviço sensível tem `precisaTerEmMaos` não
vazio e, em todo passo com `temCampoDeSenha`, o aviso da FR-032.

### Passo (conteúdo, embarcado)

Uma tela do passo a passo.

| Campo | Tipo | Regra |
|---|---|---|
| `captura` | enum de imagem | Arquivo em `assets/guias/<chave>/`. **Imagem inexistente não compila** (R6) |
| `destaque` | região relativa (`x`, `y`, `largura`, `altura`, de 0 a 1) | Onde tocar. Desenhada pelo aplicativo, por cima da captura |
| `texto` | texto | Uma ou duas frases, no imperativo gentil da voz da Memora |
| `temCampoDeSenha` | sim/não | Quando sim, o passo mostra o aviso "a senha só se digita no aplicativo oficial" (FR-032) |
| `descricaoDaCaptura` | texto | O que a imagem mostra, para o leitor de tela (FR-045) |

### Assunto de ajuda (conteúdo, embarcado)

| Campo | Tipo | Regra |
|---|---|---|
| `chave` | enum | `aplicativo`, `memora`, `conversa`, `servicos`, `baixarAplicativo`, `compartilhar`, `seguranca`, `reverApresentacao` |
| `ilustracao` | enum `Ilustracao` | — |
| `telas` | lista de textos, ou guia | `conversa` aponta para a ajuda guiada (FR-034); os outros são textos curtos, uma ideia por tela |
| `disponivel` | regra | `compartilhar` só existe com `MEMORA_URL_DOWNLOAD` definido (R12) |

### Apresentação vista (estado, no aparelho)

| Campo | Tipo | Regra |
|---|---|---|
| `idDaConta` | texto | O `id` de `PessoaAutenticada`. Não é credencial |
| `vistaEm` | instante | Gravado ao chegar ao fim **ou** ao pular (FR-013) |

**Onde**: `shared_preferences`, como conjunto de contas que já viram.
**Sai ao sair da conta?** Não na saída comum; **sim** com
`LimpezaDeSessao.executar(esquecerTudo: true)`, para aparelho que vai ser
vendido (R11).

**Transições**:

```text
não vista ──(chegou ao fim | pulou)──▶ vista
não vista ──(fechou o aplicativo no meio)──▶ não vista   (recomeça do início)
```

### Progresso de aprendizado (estado, no aparelho)

| Campo | Tipo | Regra |
|---|---|---|
| `idDaConta` | texto | — |
| `concluidos` | mapa `chave` → quantas vezes concluiu | Incrementa só ao chegar ao **último** passo |
| `aplicativoMaisAprendido` | derivado | A `chave` com maior contagem; empate fica com o mais recente. Ausente quando o mapa está vazio (US8, cenário 3) |

**Onde**: arquivo local, por conta. **Sai ao sair da conta?** **Sim** — é um
`DadoLocalDaPessoa`, apagado pela `LimpezaDeSessao` em toda saída, inclusive a
por inatividade (FR-042b).
**Vai ao servidor?** Nunca (FR-042a).

### Catálogo guardado (estado, no aparelho)

| Campo | Tipo | Regra |
|---|---|---|
| `servicos` | lista de `ServicoDoCatalogo` | A última resposta completa do catálogo, como veio |
| `recebidoEm` | instante | Quando foi recebida |

**Onde**: arquivo local, **não** por conta — o catálogo é o mesmo para todo
mundo. **Sai ao sair da conta?** Não: não é dado da pessoa (FR-024a).

**Regras**:
- Com conexão, a resposta nova **substitui** a guardada inteira. Nunca se mescla:
  mesclar manteria vivo um item que o servidor tirou do ar.
- Sem conexão e sem catálogo guardado (primeira abertura offline), a tela diz
  que precisa de internet uma vez, em vez de mostrar grade vazia.
- Resposta malformada não substitui a guardada.

### Dados que já existem e passam a ser exibidos

| Dado | De onde vem | Onde aparece |
|---|---|---|
| Nome de tratamento | `PessoaAutenticada.nomeTratamento` (sessão) | Início, Perfil |
| Canal de contato | Identificador do último acesso (FR-012 da 001) | Perfil, Conta (R10) |
| Preferência de aparência | `PreferenciaAparencia` (002) | Configurações → Aparência |

---

## No servidor

### `servico_conhecido` — migrations V8 a V10

| Coluna | Mudança | Regra |
|---|---|---|
| `chave` | **nova na V8**, `VARCHAR(40) NOT NULL UNIQUE` | ASCII minúsculo, números e hífen: `^[a-z0-9-]+$` (`CHECK`). Preenchida para as 8 linhas existentes na mesma migration |
| demais | sem mudança | `ck_servico_sensivel_nao_abre` continua valendo para as linhas novas |

**Linhas novas da V10** — todas `SENSIVEL`, `identificador_android IS NULL`:

| `chave` | `nome_exibido` |
|---|---|
| `e-titulo` | e-Título |
| `serasa` | Serasa |
| `fgts` | FGTS |
| `poupatempo` | Poupatempo |
| `carteira-digital-de-transito` | Carteira Digital de Trânsito ¹ |
| `correios` | Correios |
| `carteira-de-trabalho` | Carteira de Trabalho Digital |

¹ O wireframe diz só "Carteira Digital". A leitura aqui é a Carteira Digital de
Trânsito, a mais usada com esse nome; se a equipe quis outra (a de identidade
do gov.br, por exemplo), troca-se a linha antes da migration.

**Linhas novas da V9** — `COTIDIANO`, com pacote declarado em `<queries>`:

| `chave` | `nome_exibido` | `identificador_android` |
|---|---|---|
| `tiktok` | TikTok | `com.zhiliaoapp.musically` |
| `kwai` | Kwai | `com.kwai.video` |
| `messenger` | Messenger | `com.facebook.orca` |
| `gmail` | Gmail | `com.google.android.gm` |
| `netflix` | Netflix | `com.netflix.mediaclient` |
| `google` | Google | `com.google.android.googlequicksearchbox` |

⚠️ **Cada pacote acima precisa ser conferido num aparelho real antes da
migration**, como a V5 fez — a V5 descartou candidatos óbvios por pacote
instável entre fabricantes.

⚠️ **Uma linha só entra junto com o guia dela** (R8). Por isso são três migrations, e a V9 e a V10 podem se dividir em
várias migrations, uma por lote de guias prontos; o que não pode é linha sem
guia.

**`chave` das linhas existentes**: `whatsapp`, `facebook`, `instagram`,
`youtube`, `google-fotos`, `telegram`, `gov-br`, `meu-inss`.

O contrato muda junto: ver [contracts/catalogo.md](contracts/catalogo.md).
