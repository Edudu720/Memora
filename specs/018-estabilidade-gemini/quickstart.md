# Quickstart de Validação — `018-estabilidade-gemini`

## 1. Testes unitários do provedor Gemini e suíte sem banco

```powershell
cd backend
.\mvnw.cmd test "-Dtest=ClienteDaAssistenteGeminiTest,ConfiguracaoDoProvedorDeIaTest,AutorizadorDeAcaoTest,EventoDaAssistenteTest,UsoDaAssistenteTest,PersonaDaMemoraTest,ClienteDaAssistenteSimuladoTest"
```

Resultado esperado: 100% dos testes aprovados, incluindo:
- Recuperação automática após `503` transitório;
- Fallback automático para `gemini-3.5-flash-lite` em `503` persistente e `429` imediato;
- Bloqueio de retentativa/fallback em `400`/`403` e após entrega do 1º trecho;
- Recusa no boot para `modelo-reserva` malformado, `tentativas-primario < 1` ou `espera-retentativa-ms < 0` sem vazar `GEMINI_API_KEY`.

## 2. Suíte completa (quando Docker Desktop estiver ativo)

```powershell
cd backend
.\mvnw.cmd test
```

## 3. Conferência no Render após merge

No log de subida do `memora-backend`, confirmar a linha:
`Provedor de IA: gemini, modelo gemini-3.6-flash (reserva: gemini-3.5-flash-lite).`
