# Contrato: o formato do passo a passo

O que um guia precisa ter para entrar no aplicativo. As entidades estão em
[data-model.md](../data-model.md#guia-conteúdo-embarcado); aqui ficam as regras
de **produção** do conteúdo, que é trabalho da equipe e não do código.

## Onde mora cada parte

| Parte | Caminho |
|---|---|
| Estrutura do guia | `app/lib/features/aprendizado/data/guias/<chave>.dart` |
| Textos | `app/lib/l10n/textos_guias.dart` |
| Capturas | `app/assets/guias/<chave>/passo_<N>.webp` (ou `.png`, na exceção da regra 5) |
| Registro das capturas | `app/assets/guias/CAPTURAS.md` — chave, data, versão do aplicativo, aparelho |

## Regras de captura

1. **Conta de teste**, criada para isso. Nenhum nome, rosto, foto, número ou
   e-mail de pessoa real em nenhuma captura (FR-028).
2. **Aparelho de referência único** para todas as capturas, em 3x, para o
   destaque relativo cair no mesmo lugar em todos os guias.
3. **Sem o destaque desenhado na imagem.** O destaque, o selo "Exemplo" e a
   moldura são do aplicativo (R6). Captura com círculo vermelho pintado é
   recusada na revisão.
4. **Serviço sensível**: a captura da tela de senha mostra o campo **vazio**.
5. **Formato e tamanho**: **WebP** (sem perda, ou com qualidade 90 ou mais); **PNG só na captura cujo texto borra ao ampliar** em WebP, declarada na constante dela (`FormatoDaCaptura.png`). O total de `assets/guias/` não passa de 8 MB, e nenhuma imagem fica na pasta sem passo que a use.

## Regras de texto

1. Uma ação por passo. "Toque no botão + embaixo, no meio" — não "toque no + e
   depois escolha a câmera".
2. Diz **onde** está, com posição na tela ("embaixo, no meio"), e não só o nome
   do botão: a pessoa não sabe que o ícone de casinha se chama "Início".
3. Último passo: parabéns e o que a pessoa já sabe fazer agora, na voz da
   Memora.
4. Serviço sensível, no primeiro passo: o que ter em mãos. Em todo passo com
   campo de senha: "A sua senha só se digita no aplicativo oficial, nunca no
   Memora" (FR-032).

## O que o teste confere

Um teste do aplicativo reprova quando:

- existe `chave` em `servico_conhecido` (nas migrations) sem guia, ou guia sem
  `chave` nas migrations (R8);
- um guia tem menos de 3 ou mais de 7 passos;
- um guia de serviço sensível não tem `precisaTerEmMaos`;
- um passo `temCampoDeSenha` não mostra o aviso da FR-032;
- uma captura não tem `descricaoDaCaptura`;
- **Captura pendente (FR-028a)**: a captura que ainda não existe **não reprova a
  construção**: o passo mostra um aviso visível de captura pendente, com a chave
  do guia e o número do passo, e o texto continua funcionando. O teste lista as
  pendentes, e a lista precisa chegar a zero antes da revisão de design final;
- `CAPTURAS.md` não tem linha para um guia.

## Ordem de produção

Primeiro os guias do wireframe e dos mais usados, porque a US4 e a US5 só se
demonstram com eles: **TikTok** e **Gov.br** (as Figuras 21-24 e 29-36),
**WhatsApp**, **Instagram**, **YouTube** e **Meu INSS**. Os demais entram por
lote, cada lote com a sua migration.
