# Research: Estabilidade da API do Gemini (Item 12)

## Decisão 1 — Estratégia de modelo principal + reserva (`3.6-flash` → `3.5-flash-lite`)

- **Decisão**: Manter `gemini-3.6-flash` como principal e `gemini-3.5-flash-lite` como reserva automática no Free Tier.
- **Justificativa**: `gemini-3.8-flash` apresentou erros `503` por sobrecarga em testes reais no projeto (registrado em `docs/deploy/render.md`), enquanto `gemini-3.6-flash` respondeu com boa qualidade e ~3,6 s para a primeira palavra no plano gratuito do Render. O `gemini-3.5-flash-lite` possui cota Free Tier separada por modelo (~3× maior RPM típico para a linha Lite), menor disputa de fila e suporte nativo a `systemInstruction`, `streamGenerateContent?alt=sse` e `functionDeclarations`.
- **Alternativas consideradas**:
  - Trocar principal para `3.8-flash`: rejeitado por maior instabilidade/sobrecarga no Free Tier e maior tempo de pensamento antes do primeiro trecho.
  - Trocar direto para `3.5-flash-lite` como principal sem reserva: rejeitado porque a qualidade em português simples da persona ainda não foi medida frente ao `3.6-flash` (ADR-002 R2). A configuração por variável de ambiente permite inverter facilmente no futuro sem recompilar.

## Decisão 2 — Política exata de retentativa e proteção contra duplicação de streaming

- **Decisão**: Rastrear `AtomicBoolean enviouTrecho` por tentativa. Somente enquanto `enviouTrecho.get() == false` é permitido retentar ou acionar o reserva:
  - `FALHA_DO_PROVEDOR` (`5xx`), `REDE` ou `PRAZO`: retenta no principal até `tentativasPrimario` (padrão `2`), aguardando `esperaEntreTentativas` (padrão `500 ms`), e depois tenta `1` vez no modelo reserva.
  - `COTA_ESGOTADA` (`429`): não repete no principal (cota já estourada) e vai direto para `1` tentativa no reserva.
  - `PEDIDO_RECUSADO` (`4xx != 429`), `RESPOSTA_VAZIA`, `RESPOSTA_ILEGIVEL`: falha imediata sem retry e sem reserva.
- **Justificativa**: Se algum trecho já foi entregue ao `Consumer<String> aoReceberTrecho`, o cliente SSE já escreveu texto na tela da pessoa idosa — repetir ou trocar de modelo concatenaria uma segunda resposta em cima da parcial. Antes do primeiro trecho, a tela ainda está em estado de espera e o fallback é 100% transparente.

## Decisão 3 — Compatibilidade do construtor legado de 5 argumentos

- **Decisão**: Preservar o construtor público de 5 parâmetros `ClienteDaAssistenteGemini(chave, modelo, urlBase, conexao, leitura)` delegando para o novo construtor com `modeloReserva = ""`, `tentativasPrimario = 1`, `esperaEntreTentativas = Duration.ZERO`.
- **Justificativa**: Os testes existentes em `ClienteDaAssistenteGeminiTest` assumem comportamento de chamada única (`1` HTTP request por `conversar`). O novo construtor explícito recebe os 8 parâmetros usados por `ConfiguracaoDoProvedorDeIa` e pelos novos testes de resiliência.
