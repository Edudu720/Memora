# Contrato de Infraestrutura: Blueprint `memora-site` no Render

## Serviço Declarado (`render.yaml`)

| Campo | Valor Obrigatório | Regra |
|---|---|---|
| `type` | `web` | Tipo padrão Render Blueprint para site web estático |
| `name` | `memora-site` | Identificador estável distinto de `memora-backend` |
| `runtime` | `static` | Hospedagem estática gerenciada sem contêiner/hibernação |
| `buildCommand` | `""` | Nenhum passo de build ou instalação de pacotes |
| `staticPublishPath` | `site` | Publica a pasta `site/` da raiz do repositório |
| `buildFilter.paths` | `site/**`, `render.yaml` | Isola rebuilds de commits exclusivos de `app/` ou `backend/` |

## Cabeçalhos HTTP obrigatórios (`path: /*`)

| Cabeçalho | Valor | Objetivo |
|---|---|---|
| `Content-Security-Policy` | `default-src 'none'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'; object-src 'none'` | Bloqueia rede externa, scripts injetados, formulários e enquadramento mantendo Shadow DOM funcional |
| `X-Frame-Options` | `DENY` | Proteção legada contra clickjacking |
| `X-Content-Type-Options` | `nosniff` | Impede MIME sniffing pelo navegador |
| `Referrer-Policy` | `no-referrer` | Não vaza origem em navegação |
| `Permissions-Policy` | `camera=(), microphone=(), geolocation=(), payment=(), usb=()` | Bloqueia permissões sensíveis de hardware |

## Invariantes

1. O serviço `memora-backend` no mesmo `render.yaml` permanece inalterado campo a campo.
2. Nenhum segredo ou chave é incluído em `memora-site`.
3. Após o deploy do Blueprint na conta proprietária do repositório, a URL `https://memora-site*.onrender.com` (ou domínio atribuído pelo Render) deve ser validada com `curl.exe -I` e registrada na Issue #106 para habilitar o botão da Ajuda (Item 11).
