# Quickstart de Validação — `017-site-no-render`

## 1. Validar estrutura do `render.yaml` (local)

Verificar com Python que:
- `memora-backend` manteve todas as chaves, filtros e variáveis originais;
- `memora-site` possui `type: web`, `runtime: static`, `staticPublishPath: site`, `buildFilter.paths` e os 5 headers obrigatórios em `/*`.

## 2. Validar integridade do site estático

```powershell
py site/tests/validar_site.py
node --test site/tests/tutorial.test.mjs
```

Resultado esperado: `OK:` no validador Python e `11` testes aprovados no Node.

## 3. Conferência pós-merge no Render (após Apply no Blueprint)

```powershell
curl.exe -I https://<site-memora>.onrender.com/
```

Conferir status `200 OK`, HTTPS válido e presença dos cabeçalhos `content-security-policy`, `x-frame-options: DENY`, `x-content-type-options: nosniff`, `referrer-policy: no-referrer` e `permissions-policy`. Em seguida, comentar a URL oficial na Issue #106 para desbloquear o Item 11 (`specs/012-site-tutorial-idoso`).
