# Contratos Técnicos: Localizador Real, Voz Offline, OpenStreetMap e Higiene Git/CI

**Feature**: `010-revisao-pr71-localizador`  
**Base**: Revisão da PR #71 e especificação [spec.md](spec.md).

---

## 1. Contrato HTTP: Busca de Serviços Próximos

### 1.1 Endpoint e Autenticação

- **Métodos e Rotas no Backend (`LocalizadorController`)**:
  - `POST /v1/servicos/buscar` *(caminho natural quando `Ambiente.urlBasePadrao` termina em `/v1`)*
  - `POST /api/v1/servicos/buscar` *(compatibilidade retroativa explícita para clientes/testes apontando para a raiz do servidor)*
- **Autenticação Obrigatória**: `Authorization: Bearer <jwt>` exigido pela regra `.anyRequest().authenticated()` de `ConfiguracaoDeSegurancaWeb`.
- **Resolução de Caminho no App (`FonteLocalizadorApi`)**:
  - Se `dio.options.baseUrl` terminar com `/v1` ou `/v1/`, chama `/servicos/buscar`.
  - Caso contrário, chama `/api/v1/servicos/buscar`.
  - Toda chamada envia `Options(extra: {'secure': [{'type': 'http', 'scheme': 'bearer'}]})` e passa por `ChamadaComRenovacao` para renovação silenciosa de token expirado antes de falhar a sessão.

### 1.2 Payload de Requisição (`BuscarServicosRequest`)

```json
{
  "consulta": "Onde tomo vacina perto de mim?",
  "categoria": "SAUDE",
  "localizacao": {
    "latitude": -22.7388,
    "longitude": -47.3325
  },
  "regiaoManual": null,
  "raioMetros": 5000
}
```

### 1.3 Respostas Padronizadas (`BuscarServicosResponse` / Erros Transparentes)

- **`200 OK`**: Retorna `consultaInterpretada`, `regiaoOrigem`, `totalEncontrado` e `estabelecimentos` obtidos em tempo real do provedor geográfico externo. Uma lista vazia (`totalEncontrado: 0`) significa ausência real de registros no raio — jamais preenchida com lista fictícia.
- **`400 Bad Request`**: Falta concomitante de `localizacao` e `regiaoManual`, ou `regiaoManual` não reconhecida pelo serviço de geocodificação. Retorna `{ "mensagem": "..." }` legível ao usuário.
- **`401 Unauthorized`**: Token ausente ou inválido; dispara tentativa única de renovação em `ChamadaComRenovacao` no aplicativo.
- **`503 Service Unavailable`**: Falha de comunicação, timeout ou resposta inválida dos serviços externos (Nominatim / Overpass API). Retorna `{ "mensagem": "Não foi possível consultar o serviço de mapas no momento. Tente novamente em instantes." }`. **Proibido retornar `200 OK` com estabelecimentos de contingência.**

---

## 2. Contrato de Consumo Externo OpenStreetMap (Backend & App)

### 2.1 Política de Uso do Nominatim e Overpass (`ProvedorOpenStreetMapOverpass`)

| Requisito | Regra Obrigatória |
|---|---|
| `User-Agent` HTTP | Deve identificar explicitamente o projeto Memora (ex.: `Memora-Fatec/1.0 (+https://github.com/Edudu720/Memora)`), proibindo identificadores genéricos sem vínculo com o repositório/projeto. |
| Taxa de Requisições ao Nominatim | Máximo de **1 requisição por segundo**: requisições concorrentes no processo **aguardam em fila sincronizada** garantindo intervalo mínimo `>= 1000 ms` entre chamadas de geocodificação (sem falha imediata por corrida entre requisições legítimas). |
| Timeouts Externos | Conexão HTTP: `5s`; requisição Nominatim: `5s`; requisição Overpass HTTP: `6s` (com `[timeout:5]` na query Overpass), convertendo excedentes em `503 Service Unavailable`. |
| Fallback de Coordenadas | **Proibido** retornar coordenadas padrão hardcoded (como Americana - SP) quando a geocodificação falhar ou vier vazia. |
| Persistência de Localização | Coordenadas e texto de `regiaoManual` **nunca** são gravados em tabelas JPA/PostgreSQL nem em arquivos locais persistentes. |

### 2.2 Transparência no Aplicativo (`DialogoPermissaoLocalizacao` e Busca Manual)

1. Antes da autorização do GPS, `DialogoPermissaoLocalizacao` deve declarar explicitamente ao usuário idoso:
   - Que a busca utiliza sua posição atual apenas durante aquela consulta;
   - Que os pontos próximos são pesquisados no serviço público **OpenStreetMap**;
   - Que nenhum dado pessoal da conta (nome, e-mail ou histórico de deslocamento) é enviado ao OpenStreetMap ou gravado pelo Memora.
2. No fluxo alternativo de busca manual (`_solicitarRegiaoManual` na `TelaLocalizador`), o modal deve exibir aviso equivalente de forma concisa informando que o bairro ou cidade digitado é consultado no mapa público **OpenStreetMap**, sem dados pessoais da conta nem registro de histórico.

---

## 3. Contrato de Reconhecimento de Voz Offline (`LeitorDeVozSpeechToText`)

| Regra | Comportamento Exigido |
|---|---|
| Execução local estrita | `SpeechListenOptions` deve fixar `onDevice: true` em toda chamada a `_speech.listen(...)`. |
| Proibição de envio à nuvem | Se `onDevice: true` falhar, lançar exceção ou não inicializar reconhecimento offline, é **proibido** repetir a escuta com `onDevice: false`. |
| Degradação gentil (`Q2`) | O botão de microfone (*Falar*) permanece disponível. Ao falhar em modo offline, retorna `ResultadoDitado(estado: EstadoDitado.indisponivel, mensagem: TextosAssistente.vozOfflineIndisponivel)` orientando o uso do teclado ou instalação do pacote offline de português no aparelho. |

---

## 4. Contrato do Modo Demonstração (`RepositorioLocalizadorSimulado`)

| Regra | Comportamento Exigido |
|---|---|
| Identificação explícita | `ResultadoBuscaServicos.ehDemonstracao == true`, `descricaoRegiao` e `avisoTransparencia` informam explicitamente tratar-se de exemplos de demonstração. |
| Segurança telefônica | Todo `EstabelecimentoServico` em `RepositorioLocalizadorSimulado` possui `telefone: null`, mesmo na categoria `emergencia`. |
| Banner na interface (`TelaLocalizador`) | Quando `resultado.ehDemonstracao == true`, renderizar banner informativo claro diferenciando o modo de demonstração da busca real conectada ao servidor. |

---

## 5. Contrato de Repositório, PII e Pipeline de CI

- **Arquivos limpos de PII**: `scripts/censurar_servicos_sociais.py`, `scripts/processar_guias_visuais.py` e os 6 arquivos de `specs/006-guias-servicos-sociais/` livres de CPF real (`[0-9]{3}\.[0-9]{3}\.[0-9]{3}-[0-9]{2}` substituído por `XXX.XXX.XXX-XX`) e dados nominais pessoais de captura.
- **Diretório excluído**: `Memora-Desing-Ideias/` em `.gitignore` e ausente do índice e histórico alcançável da branch.
- **Histórico da PR #71 (`Q3`)**: Exactamente `1` commit limpo em `feature/009-localizador-servicos` diretamente acima de `origin/develop`.
- **Workflow `.github/workflows/verificacao.yml`**:
  - `flutter-version: '3.47.7'` nos jobs `app` e `cliente-gerado`.
  - Comando `flutter analyze` sem a flag `--no-fatal-infos`.
  - Portões Python `validar_paleta.py`, `validar_tokens.py`, testes Dart (`app` e `app/pacotes/memora_api`) e Maven (`backend`).
