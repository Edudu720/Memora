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
   **Exceção temporária e declarada**: as capturas JPG da #71 (feature 006:
   whatsapp, facebook, telegram, gov-br, serasa e correios) já vêm com a
   marcação pintada e entram como legado (`FormatoDaCaptura.jpg`); o aplicativo
   não desenha um segundo destaque sobre elas, e cada uma será substituída por
   um print com o destaque desenhado pelo app.
4. **Serviço sensível**: a tela de senha é capturada com o campo **vazio**.
5. **Formato e tamanho**: **WebP** (sem perda, ou com qualidade 90 ou mais); **PNG só na captura cujo texto borra ao ampliar** em WebP, declarada na constante dela (`FormatoDaCaptura.png`). **JPG só no legado da #71** (ver a regra 3), declarado como `FormatoDaCaptura.jpg`. O total de `assets/guias/` não passa de 12 MB (revisado na spec 016 para comportar os 16 guias completos com capturas reais legíveis), e nenhuma imagem fica na pasta sem passo que a use.

## Registro

| Chave | Capturado em | Versão do aplicativo | Aparelho | Quem capturou |
|---|---|---|---|---|
| whatsapp | 2026-11-13 | 2026.11 | Android (JPG + Blur + Numerado) — legado #71: marcação pintada na imagem, substituir | Equipe Memora (5 capturas) |
| instagram | 2026-11-13 | a confirmar | Galaxy S20 FE — prints com os dados pessoais trocados por dados fictícios gerados por IA (interface original do aparelho) | Henrique Sandrini |
| youtube | 2026-11-19 | 19.38.0 | Galaxy A14 (capturas higienizadas sem PII) | Equipe Memora (@Du3101, 7 capturas) |
| facebook | 2026-11-13 | 2026.11 | Android (JPG + Blur + Numerado) — legado #71: marcação pintada na imagem, substituir | Equipe Memora (10 capturas) |
| google-fotos | 2026-11-19 | 6.95.0 | Galaxy A14 (capturas higienizadas sem PII) | Equipe Memora (@Du3101, 4 capturas) |
| telegram | 2026-11-13 | 2026.11 | Android (JPG + Blur + Numerado) — legado #71: marcação pintada na imagem, substituir | Equipe Memora (8 capturas) |
| tiktok | 2026-11-19 | 36.5.0 | Galaxy A14 (capturas higienizadas sem PII) | Equipe Memora (@Du3101, 6 capturas) |
| gov-br | 2026-11-13 | 2026.11 | Web/Android (JPG + Blur + Numerado) — legado #71: marcação pintada na imagem, substituir | Equipe Memora (24 capturas) |
| meu-inss | 2026-11-19 | 4.18.0 | Galaxy A14 (capturas higienizadas sem PII) | Equipe Memora (@Du3101, 19 capturas) |
| e-titulo | 2026-11-12 | 2026.10.27 | Galaxy S20 FE | Henrique Sandrini |
| serasa | 2026-11-13 | 2026.11 | Web/Android (JPG + Blur + Numerado) — legado #71: marcação pintada na imagem, substituir | Equipe Memora (22 capturas) |
| fgts | 2026-11-13 | 5.11.0 | Galaxy S20 FE | Henrique Sandrini |
| poupatempo | 2026-11-19 | 5.2.0 | Galaxy A14 (capturas higienizadas sem PII) | Equipe Memora (@Du3101, 10 capturas) |
| carteira-digital | 2026-11-19 | 3.1.2 | Galaxy A14 (capturas higienizadas sem PII) | Equipe Memora (@Du3101, 10 capturas) |
| correios | 2026-11-13 | 2026.11 | Web/Android (JPG + Blur + Numerado) — legado #71: marcação pintada na imagem, substituir | Equipe Memora (8 capturas) |
| carteira-de-trabalho | 2026-11-19 | 8.11.0 | Galaxy A14 (capturas higienizadas sem PII) | Equipe Memora (@Du3101, 10 capturas) |
