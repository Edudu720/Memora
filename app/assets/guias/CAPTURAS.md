# Capturas dos passo a passo

Uma linha por guia. É ela que diz à revisão **quando refazer**: o aplicativo do
outro lado muda, e a captura envelhece (R6 da feature 004). O teste
`catalogo_e_guias_test.dart` reprova guia sem linha aqui.

## Regras de captura

Resumo de [contracts/guias.md](../../../specs/004-redesenho-das-telas/contracts/guias.md):

1. **Conta de teste**, criada para isso. Nenhum nome, rosto, foto, número ou
   e-mail de pessoa real em captura nenhuma (FR-028).
2. **Um aparelho de referência** para todas as capturas, em 3x — para o
   destaque, em coordenadas relativas, cair no mesmo lugar em todos os guias.
3. **Sem destaque pintado na imagem.** O anel, o selo "Exemplo" e a moldura são
   desenhados pelo aplicativo. Captura com círculo vermelho é recusada.
4. **Serviço sensível**: a tela de senha é capturada com o campo **vazio**.
5. **Tamanho**: PNG otimizado; o total de `assets/guias/` não passa de 8 MB.

## Registro

| Chave | Capturado em | Versão do aplicativo | Aparelho | Quem capturou |
|---|---|---|---|---|
| — | — | — | — | — |
