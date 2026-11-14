# Capturas dos passo a passo

Uma linha por guia. É ela que diz à revisão **quando refazer**: o aplicativo do
outro lado muda, e a captura envelhece (R6 da feature 004). O teste
`catalogo_e_guias_test.dart` reprova guia sem linha aqui.

## Regras de captura

Resumo de [contracts/guias.md](../../../specs/004-redesenho-das-telas/contracts/guias.md):

1. **Conta de teste**, criada para isso. Nenhum nome, rosto, foto, número ou
   e-mail de pessoa real em captura nenhuma (FR-028).
2. **Um aparelho de referência** para todas as capturas — o **Samsung Galaxy S20 FE** (decisão do Henrique, 2026-11-12) —, em 3x — para o
   destaque, em coordenadas relativas, cair no mesmo lugar em todos os guias.
3. **Sem destaque pintado na imagem.** O anel, o selo "Exemplo" e a moldura são
   desenhados pelo aplicativo. Captura com círculo vermelho é recusada.
4. **Serviço sensível**: a tela de senha é capturada com o campo **vazio**.
5. **Formato e tamanho**: **WebP** (sem perda, ou com qualidade 90 ou mais); **PNG só na captura cujo texto borra ao ampliar** em WebP, declarada na constante dela (`FormatoDaCaptura.png`). O total de `assets/guias/` não passa de 8 MB, e nenhuma imagem fica na pasta sem passo que a use.

## Registro

| Chave | Capturado em | Versão do aplicativo | Aparelho | Quem capturou |
|---|---|---|---|---|
| whatsapp | 2026-10-01 | 2.24.19 | Galaxy A14 | Equipe Memora |
| instagram | 2026-11-13 | a confirmar | Galaxy S20 FE — prints com os dados pessoais trocados por dados fictícios gerados por IA (interface original do aparelho) | Henrique Sandrini |
| youtube | 2026-10-01 | 19.38.0 | Galaxy A14 | Equipe Memora |
| facebook | 2026-10-01 | 480.0.0 | Galaxy A14 | Equipe Memora |
| google-fotos | 2026-10-01 | 6.95.0 | Galaxy A14 | Equipe Memora |
| telegram | 2026-10-01 | 11.1.0 | Galaxy A14 | Equipe Memora |
| tiktok | 2026-10-01 | 36.5.0 | Galaxy A14 | Equipe Memora |
| gov-br | 2026-10-01 | 3.5.0 | Galaxy A14 | Equipe Memora |
| meu-inss | 2026-10-01 | 4.18.0 | Galaxy A14 | Equipe Memora |
| e-titulo | 2026-11-12 | 2026.10.27 | Galaxy S20 FE | Henrique Sandrini |
| serasa | 2026-10-01 | 10.12.0 | Galaxy A14 | Equipe Memora |
| fgts | 2026-11-13 | 5.11.0 | Galaxy S20 FE | Henrique Sandrini |
| poupatempo | 2026-10-01 | 5.2.0 | Galaxy A14 | Equipe Memora |
| carteira-digital | 2026-10-01 | 3.1.2 | Galaxy A14 | Equipe Memora |
| correios | 2026-10-01 | 4.1.0 | Galaxy A14 | Equipe Memora |
| carteira-de-trabalho | 2026-10-01 | 5.8.0 | Galaxy A14 | Equipe Memora |
