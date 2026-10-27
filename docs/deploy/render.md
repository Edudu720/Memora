# Guia de Implantação do Memora no Render

Este documento descreve como realizar o deploy do backend do Memora no [Render](https://render.com) e compilar o APK conectado ao serviço hospedado.

---

## 🚀 Opção 1: Deploy Automático via Blueprint (`render.yaml`)

O repositório já inclui o arquivo [render.yaml](../../render.yaml) na raiz, que provisiona automaticamente tanto o banco PostgreSQL quanto o Web Service.

1. Acesse o [Dashboard do Render](https://dashboard.render.com).
2. Clique em **New +** no canto superior direito e selecione **Blueprint**.
3. Conecte o repositório do Memora (`Edudu720/Memora`).
4. O Render detectará o `render.yaml` e listará:
   - **Banco de Dados**: `memora-postgres` (PostgreSQL gratuito)
   - **Web Service**: `memora-backend` (Docker)
5. No campo **GEMINI_API_KEY**, informe sua chave de API do Google Gemini.
6. Clique em **Apply**. O Render fará o build do Dockerfile, subirá as migrations do Flyway no banco e iniciará a aplicação.

---

## 🛠️ Opção 2: Deploy Manual pelo Dashboard do Render

Caso prefira criar os serviços individualmente:

### Passo 1: Criar o Banco PostgreSQL
1. No Render, clique em **New +** ➔ **PostgreSQL**.
2. **Name**: `memora-postgres`
3. **Database**: `memora`
4. **User**: `memora`
5. **Plan**: `Free`
6. Clique em **Create Database**.
7. Após a criação, copie a **Internal Database URL** (ou a connection string).

### Passo 2: Criar o Web Service (Backend Docker)
1. Clique em **New +** ➔ **Web Service**.
2. Conecte o repositório `Edudu720/Memora`.
3. Configure:
   - **Name**: `memora-backend`
   - **Language / Runtime**: `Docker`
   - **Dockerfile Path**: `backend/Dockerfile`
   - **Docker Context**: `backend`
   - **Plan**: `Free`
   - **Health Check Path**: `/actuator/health`
4. Na seção **Environment Variables**, adicione:
   - `DATABASE_URL`: Cole a Internal Database URL do banco criado no Passo 1.
   - `MEMORA_ASSISTENTE_PROVEDOR`: `gemini`
   - `MEMORA_ASSISTENTE_GEMINI_MODELO`: `gemini-3.6-flash`
   - `GEMINI_API_KEY`: *(sua chave de API do Gemini)*
   - `MEMORA_TOKEN_SEGREDO`: *(gerar uma string segura base64 com no mínimo 32 bytes / 256 bits)*
   - `MEMORA_CHAVE_ORIGEM`: *(uma string segura aleatória com no mínimo 32 caracteres)*
5. Clique em **Create Web Service**.

---

## 🔍 Como Testar o Backend Hospedado

1. Quando o status mudar para **Live**, acesse o endpoint de saúde no navegador ou via curl:
   ```bash
   curl https://<seu-servico>.onrender.com/actuator/health
   ```
   A resposta deve ser:
   ```json
   {"status":"UP"}
   ```

2. O endpoint `/v1` da API estará pronto em:
   `https://<seu-servico>.onrender.com/v1`

---

## 📱 Gerando o APK Conectado ao Render

Após o backend estar no ar, compile o APK de release passando a URL HTTPS do seu serviço no Render:

```powershell
flutter build apk --release `
  --dart-define=MEMORA_URL_BASE=https://<seu-servico>.onrender.com/v1 `
  --dart-define=MEMORA_SERVIDOR_REAL=true
```

O arquivo gerado em `app/build/app/outputs/flutter-apk/app-release.apk` estará conectado diretamente ao seu backend hospedado na nuvem, permitindo que qualquer pessoa instale o aplicativo e realize cadastro, login e conversas com a IA real pelo celular.

