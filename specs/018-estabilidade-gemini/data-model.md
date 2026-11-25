# Data Model: Configuração de Resiliência Gemini

Nenhuma tabela de banco de dados é criada ou alterada. As entidades abaixo representam a configuração imutável em memória do adaptador `ClienteDaAssistenteGemini`:

| Campo / Propriedade | Tipo | Padrão | Variável de Ambiente | Regra de Validação |
|---|---|---|---|---|
| `memora.assistente.gemini.modelo` | `String` | `gemini-3.6-flash` | `MEMORA_ASSISTENTE_GEMINI_MODELO` | Não vazio, regex `[A-Za-z0-9._-]+` |
| `memora.assistente.gemini.modelo-reserva` | `String` | `gemini-3.5-flash-lite` | `MEMORA_ASSISTENTE_GEMINI_MODELO_RESERVA` | Se não vazio, regex `[A-Za-z0-9._-]+`; se vazio ou igual ao principal, fallback desativado |
| `memora.assistente.gemini.tentativas-primario` | `int` | `2` | `MEMORA_ASSISTENTE_GEMINI_TENTATIVAS_PRIMARIO` | Inteiro `>= 1` |
| `memora.assistente.gemini.espera-retentativa-ms` | `long` | `500` | `MEMORA_ASSISTENTE_GEMINI_ESPERA_RETENTATIVA_MS` | Longo `>= 0` (convertido em `Duration.ofMillis(...)`) |
| `memora.assistente.gemini.timeout-conexao-segundos` | `long` | `10` | `memora.assistente.gemini.timeout-conexao-segundos` | Mantido |
| `memora.assistente.gemini.timeout-leitura-segundos` | `long` | `60` | `memora.assistente.gemini.timeout-leitura-segundos` | Mantido |
