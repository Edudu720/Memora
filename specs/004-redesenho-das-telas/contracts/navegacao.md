# Contrato: navegação

O mapa de telas do aplicativo depois desta feature, e as regras de ir e voltar.
É o contrato que a Figura 1 do Arquivo X (diagrama de estados) representava, com
o que as features 001 a 004 acrescentaram.

## Fora da conta

```text
Boas-vindas ──▶ Cadastro ──▶ (assistido?) Entrega do aparelho ─▶ Confirmar canal
     │              │                                                 │
     │              └──────────────────────────────┐                  │
     └──▶ Login ──▶ Recuperação                     ▼                  ▼
            │                                 Apresentação ◀── Primeira entrada
            └───────────────────────────────▶ (se não vista)
                                                    │
                                                    ▼
                                             [ dentro da conta ]
```

- **Sem barra inferior.** Fora da conta não há para onde a barra levar.
- A apresentação (Olá → Apresentação → Exemplo) aparece **entre** a autenticação
  e o Início, só para conta que não a viu (FR-012, FR-013).

## Dentro da conta — a casca

Três destinos fixos na barra inferior, cada um com pilha própria:

| Destino | Raiz da pilha | O que se empilha sobre ela |
|---|---|---|
| **Configurações** | Lista de grupos | Aparência · Acessibilidade · Privacidade · Conta · (galeria, só em depuração) |
| **Início** | Início | Hub → Conversa · Meus aplicativos · Serviços sociais · Ajuda · O que eu fiz por você → passo a passo |
| **Perfil** | Perfil | — |

**Regras**:

1. **Destino inicial**: Início, sempre, ao entrar e ao voltar da apresentação.
2. **Tocar no destino em que já se está** volta à raiz dele. É o "me tira daqui"
   de quem se perdeu numa pilha funda.
3. **"Voltar" do cabeçalho** desempilha uma tela. Na raiz de um destino, ele não
   aparece — a barra inferior basta.
4. **O botão "voltar" do sistema** faz o mesmo que o "Voltar" do cabeçalho; na
   raiz do Início, pergunta se a pessoa quer sair do Memora, em vez de fechar em
   silêncio.
5. **Profundidade máxima**: Início → Hub → catálogo → passo a passo. Qualquer
   parte está a no máximo **3 toques** do Início (SC-006).
6. **Barra inferior em todas as telas internas**, inclusive a conversa e o passo
   a passo (FR-015). Com o teclado aberto, ela se esconde, e volta quando o
   teclado fecha.

## Inatividade e atividade

Valem para **as três pilhas**, não só para a ativa:

- **Toque em qualquer tela da casca** conta como atividade. Toda rota empilhada
  nasce pelo mesmo construtor de rota do `FluxoAutenticacao`, que já envolve o
  `Listener` (achado 8 da revisão de 2026-10-01).
- **Quando a sessão expira**, todas as rotas das três pilhas são fechadas antes
  de o login aparecer. Nenhuma tela interna fica por baixo do login (achado 7).

## Diálogos

`DialogoMemora.mostrar` abre o diálogo **no `Navigator` que o contexto de quem
chama encontra** (`useRootNavigator: false`). Com um `Navigator` por destino,
o padrão do `showDialog` — o de fora — fazia "Entendi" fechar a tela de trás e
deixar o diálogo aberto (revisão da #38). O aviso de inatividade e a pergunta
"Fechar o Memora?" são abertos com contexto acima das pilhas, e por isso ficam
no de fora — e é o `popUntil` do fluxo que os tira na expiração.

## Saída

- "Sair" existe **só** em Configurações → Conta (FR-019), sempre com a
  confirmação da FR-025 da 001.
- "Sair e esquecer este aparelho" **não fica ao lado** do "Sair": é a mais
  destrutiva das duas, e o Princípio II proíbe ação destrutiva adjacente à
  comum. Fica separada, abaixo, com uma frase dizendo para que serve
  (aparelho compartilhado ou que vai ser vendido), e usa
  `LimpezaDeSessao.executar(esquecerTudo: true)`.

## O que sai do aplicativo

Toda saída do Memora é anunciada **antes**, com o destino escrito (Princípio
II): abrir aplicativo cotidiano (sempre pela conversa, FR-027) e
compartilhar. A assistente usa o mesmo aviso.

**O Memora não abre a loja oficial**: ele **ensina** a abri-la, pelo assunto
"Como baixar um aplicativo" e pelo passo de baixar do guia de um aplicativo
não instalado (FR-036). Abrir a loja pela pessoa treinaria o gesto que o
golpe "instale este aplicativo" precisa (revisão da #36).
