# Implantação do Memora: Render + Neon

Como pôr o backend no ar e gerar um APK que fale com ele, com a assistente
real (Gemini). Escrito em 2026-10-27, depois de rodar a imagem do
`backend/Dockerfile` limitada como o plano gratuito do Render (512 MB e 0,1 de
CPU) e medir.

| Peça | Onde | Custo |
|---|---|---|
| Backend (Docker) | Render, plano **Free**, região **Virginia** | US$ 0 |
| Site tutorial (`site/`) | Render, **Static Site** (CDN, não dorme) | US$ 0 |
| Banco PostgreSQL | **Neon**, plano Free, região **AWS us-east-1** | US$ 0 |
| Manter acordado | ping externo a cada 10 min (apenas no backend) | US$ 0 |
| IA | Gemini, nível gratuito (ADR-002, Emenda 1) | US$ 0 |

---

## O que medimos, e por que o guia é assim

| | 1 CPU | 0,1 CPU (Free do Render) |
|---|---|---|
| Subida do servidor | 9 s | **~207 s** |
| Cadastro ou entrada (um Argon2) | 0,8 s | **~8 s** (o primeiro, ~20 s) |
| Primeira palavra do Gemini (`gemini-3.6-flash`) | — | 3,6 s |

- **O Free dorme após 15 min sem tráfego**, e acordar é subir de novo: ~3,5 min.
  O app desiste da conversa em 30 s (`esperaMaxima`). Por isso existe o
  **ping**: as 750 h gratuitas por mês cobrem um serviço ligado o mês inteiro.
- **Cada hash Argon2 aloca 64 MiB.** Com 512 MB, 10 cadastros simultâneos
  derrubavam a JVM (`OutOfMemoryError`). Hoje há um teto de hashes simultâneos
  (`memora.senha.hashes-simultaneos`, calculado pela memória: 3 no Render), e
  os demais esperam na fila.
- **O banco não é o do Render** porque o Postgres gratuito de lá expira 30 dias
  depois de criado, perto da entrega. O do Neon não expira, mas **dorme após
  5 min** e cobra tempo de computação. Por isso o health check do Render e o
  ping usam **`/actuator/health/liveness`**, que não toca no banco. O
  `/actuator/health` consulta o banco e o manteria acordado o mês inteiro.
- **Conexão aberta também mantém o Neon acordado.** Em 2026-11-17 o primeiro
  projeto gastou as **100 CU-hora gratuitas do mês em ~16 dias** e foi
  suspenso, com o ping certo no `/liveness`: o Hikari mantinha as 20 conexões
  do pool abertas o tempo todo (`minimum-idle` padrão = máximo), e o Neon nunca
  dormia. O gráfico de RAM do Monitoring mostrava o compute **Active** a hora
  inteira com CPU perto de zero. Hoje `minimum-idle=0` e `idle-timeout=60000`
  (no `application.properties`) deixam as conexões paradas fecharem em 1 min, e
  a limpeza de contas pendentes roda a cada 6 h. **Conferir depois de cada
  implantação:** uns 10 min sem uso, o Monitoring deve mostrar a faixa
  hachurada de "Endpoint inactive". Se a cota acabar de novo, o limite é **por
  projeto** (o plano gratuito permite vários): um projeto novo na mesma conta
  volta a funcionar, ao custo dos dados.
- **Virginia + us-east-1**: as duas peças na mesma região. Cada requisição faz
  várias consultas, e banco longe do servidor multiplica a latência.

---

## 1. Banco no Neon

1. Crie a conta em [neon.tech](https://neon.tech) e um projeto: **Postgres 16**,
   região **AWS US East (N. Virginia)**.
2. Em **Connect**, desligue **Connection pooling** e copie a URL **direta**
   (sem `-pooler` no host). O PgBouncer em modo transação atrapalha o Flyway.
   A URL tem a forma
   `postgresql://usuario:senha@ep-...us-east-1.aws.neon.tech/neondb?sslmode=require`.
3. Não crie tabela nenhuma: o Flyway cria tudo na primeira subida.

⚠️ A URL contém a senha do banco. Ela vai **só** para o painel do Render, nunca
para o git, o chat ou um print.

## 2. Backend no Render

O repositório é privado e pertence ao **Edudu720**. Para o Render enxergá-lo, o
aplicativo do Render no GitHub precisa estar instalado na conta do dono, então
este passo pode exigir o Eduardo.

1. No [painel do Render](https://dashboard.render.com): **New + → Blueprint**,
   e escolha `Edudu720/Memora`. O Render lê o [`render.yaml`](../../render.yaml).
2. Ele vai pedir os valores marcados `sync: false`:
   - `DATABASE_URL`: a URL direta do Neon do passo 1;
   - `GEMINI_API_KEY`: a chave do Gemini.
3. **Apply.** O build leva alguns minutos, e a primeira subida, ~3,5 min. O
   Flyway aplica as migrations no Neon.

O que o `render.yaml` já define, e não precisa de mão:

| Variável | Valor | Por quê |
|---|---|---|
| `MEMORA_TOKEN_SEGREDO` | `generateValue` (256 bits, base64) | Fixa entre reinícios; sem ela, cada reinício derruba a sessão de todo mundo |
| `MEMORA_CHAVE_ORIGEM` | `generateValue` | Fixa entre reinícios; sem ela, a contagem por origem da R4 zera |
| `MEMORA_ASSISTENTE_PROVEDOR` | `gemini` | Vazio cairia no simulado |
| `MEMORA_ASSISTENTE_GEMINI_MODELO` | `gemini-3.6-flash` | O `3.8` deu 503 por sobrecarga em 2026-10-21 (ADR-002) |
| `MEMORA_ASSISTENTE_GEMINI_MODELO_RESERVA` | `gemini-3.5-flash-lite` | Reserva automática antes do 1º trecho quando o principal sofre `429` ou `5xx` persistente |

⚠️ **Não ponha `SPRING_PROFILES_ACTIVE=producao`.** Esse perfil não tem
`EnviadorDeCodigo` (T065a) e a aplicação não sobe, de propósito. Sem ele, os
códigos de verificação e de "Esqueci minha senha" vão para o **log do Render**.
Avise quem testar que recuperar a senha só funciona com alguém da equipe lendo
o log.

⚠️ **Não apague nem regenere as duas chaves geradas.** Trocar
`MEMORA_TOKEN_SEGREDO` desconecta todo mundo.

### Conferir

```powershell
curl.exe https://<servico>.onrender.com/actuator/health/liveness
```

Deve responder `{"status":"UP"}`. O `/actuator/health` (com o banco) também
responde, mas não o use para o ping.

## 2b. Site tutorial estático (`memora-site`)

O mesmo [`render.yaml`](../../render.yaml) declara o serviço `memora-site`
(`runtime: static`, `staticPublishPath: site`, sem etapa de build). Por ser
hospedagem estática no Render, **ele não dorme** e não precisa de ping externo;
além disso, possui `buildFilter` próprio (`site/**` e `render.yaml`) para não
reconstruir quando apenas o backend ou o app mudarem.

1. Depois do merge na branch configurada do Blueprint (`develop`), confirme no
   painel do Render se o serviço `memora-site` foi criado/sincronizado.
2. URL oficial publicada em produção:
   **`https://memora-site-thf2.onrender.com/`**
   (**atenção**: o subdomínio exato `https://memora-site.onrender.com` pertence
   a outro projeto externo no Render e não deve ser usado).
3. Confira que os cabeçalhos de segurança estão ativos:

```powershell
curl.exe -I https://memora-site-thf2.onrender.com/
```

Deve responder `200 OK` com `Content-Security-Policy`, `X-Frame-Options: DENY`,
`X-Content-Type-Options: nosniff`, `Referrer-Policy: no-referrer` e
`Permissions-Policy`.

4. A URL oficial `https://memora-site-thf2.onrender.com/` já está configurada
   como padrão em `Ambiente.urlSiteTutorialPadrao` (`MEMORA_URL_SITE_TUTORIAL`)
   para habilitar o botão do site na tela de Ajuda (**Issue #106 — Item 11**).

## 3. Ping a cada 10 minutos

Em [cron-job.org](https://cron-job.org) ou [UptimeRobot](https://uptimerobot.com),
um monitor HTTP `GET` para
`https://<servico>.onrender.com/actuator/health/liveness`, a cada **10 min**
(menos que os 15 min em que o Render dorme).

O ping mantém o servidor acordado e deixa o Neon dormir: o liveness não toca no
banco, então o Neon só acorda quando alguém usa o app (~0,5 s a mais na
primeira requisição).

## 4. APK de release

Pendências antes de mandar o APK para alguém de fora:

- **Chave de assinatura própria** (`app/android/app/build.gradle.kts` ainda
  assina com a de depuração da máquina de quem gera). APK de outra máquina não
  instala por cima, e reinstalar apaga os dados do aparelho. A chave não vai
  para o git.
- **`usesCleartextTraffic="true"`** no app inteiro, trazido pela 005 (issue
  #43). O app já recusa `http://` fora de depuração
  (`Ambiente.exigirTlsForaDeDepuracao`), mas o manifesto continua liberando.

```powershell
$env:TEMP="C:\memora-tmp"; $env:TMP="C:\memora-tmp"; cd app; flutter build apk --release --dart-define=MEMORA_URL_BASE=https://<servico>.onrender.com/v1 --dart-define=MEMORA_SERVIDOR_REAL=true
```

*(O endereço oficial do site de tutoriais `https://memora-site-thf2.onrender.com/`
já é assumido por padrão via `Ambiente.urlSiteTutorialPadrao`, podendo ser
sobrescrito com `--dart-define=MEMORA_URL_SITE_TUTORIAL=...` se necessário.)*

Na máquina do Henrique, reverta `app/pubspec.lock` e
`app/android/gradle.properties` depois do build.

O APK sai em `app/build/app/outputs/flutter-apk/app-release.apk`.

---

## Quando trocar de plano

- **Lentidão de ~8 s para entrar incomoda no teste com as 5 pessoas** → o
  Starter (US$ 7/mês, 0,5 de CPU, não dorme) deve levar isso para ~1,6 s
  (estimado, não medido). A memória continua 512 MB, então o teto de hashes
  continua necessário.
- **O Neon esgota a cota gratuita** → olhe se algo está consultando o banco
  sem parar (o health check errado é o suspeito número um).
