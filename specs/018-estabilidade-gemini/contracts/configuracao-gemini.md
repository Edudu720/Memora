# Contrato Interno: Política de Tentativas e Fallback (`ClienteDaAssistenteGemini`)

## Assinaturas Públicas

1. **Construtor legado (compatível com testes de chamada única)**:
   - `ClienteDaAssistenteGemini(String chave, String modelo, String urlBase, Duration conexao, Duration leitura)`
   - Configura `modeloReserva = ""`, `tentativasPrimario = 1`, `esperaEntreTentativas = Duration.ZERO`.
2. **Construtor completo (usado por `ConfiguracaoDoProvedorDeIa`)**:
   - `ClienteDaAssistenteGemini(String chave, String modelo, String modeloReserva, String urlBase, Duration conexao, Duration leitura, int tentativasPrimario, Duration esperaEntreTentativas)`

## Regras de Decisão por Resultado

| Condição na tentativa | `enviouTrecho` | Ação no Modelo Principal | Ação no Modelo Reserva |
|---|---|---|---|
| Sucesso `200` com texto/função | — | Retorna `Resposta` | — |
| `FALHA_DO_PROVEDOR` (`5xx`), `REDE` ou `PRAZO` | `false` | Retenta até `tentativasPrimario`, esperando `esperaEntreTentativas` entre tentativas | Após esgotar tentativas do principal, faz `1` tentativa se `enderecoReserva != null` |
| `COTA_ESGOTADA` (`429`) | `false` | **Não** retenta no principal | Faz `1` tentativa imediata se `enderecoReserva != null` |
| `PEDIDO_RECUSADO`, `RESPOSTA_VAZIA`, `RESPOSTA_ILEGIVEL` | `false` | Falha imediata | Não aciona reserva |
| Qualquer erro após entrega do 1º trecho | `true` | Falha imediata | Não aciona reserva |

## Garantias de Segurança (Invariantes)

- `x-goog-api-key` trafega apenas no cabeçalho HTTP em ambas as rotas (`principal` e `reserva`).
- Corpo de resposta de erro do provedor continua não sendo lido nem repassado em exceção ou log.
- Nenhuma mensagem de validação (`IllegalStateException`) ou log inclui a chave da API.
- O corpo JSON enviado ao modelo reserva é idêntico ao do principal (`systemInstruction`, `tools`, `toolConfig`, `contents`).
