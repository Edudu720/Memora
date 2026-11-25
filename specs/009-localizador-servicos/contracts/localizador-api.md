# Contrato da API: Localizador de Serviços

## Endpoint Principal: Buscar Serviços Próximos

- **Método**: `POST`
- **Caminho**: `/api/v1/servicos/buscar`
- **Autenticação**: Bearer Token JWT (usuário autenticado no Memora)
- **Content-Type**: `application/json`

---

### 1. Request Payload (`BuscarServicosRequest`)

```json
{
  "consulta": "Preciso achar um posto de saúde para tomar vacina",
  "categoria": "SAUDE",
  "localizacao": {
    "latitude": -22.7388,
    "longitude": -47.3325
  },
  "regiaoManual": null,
  "raioMetros": 5000
}
```

#### Definição dos Campos da Requisição

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `consulta` | `String` | Não | Texto livre digitado ou ditado pelo usuário em linguagem natural. |
| `categoria` | `String` | Não | Identificador da categoria (`SAUDE`, `SERVICOS_PUBLICOS`, `EMERGENCIA`, `COTIDIANO`). |
| `localizacao` | `Object` | Não* | Objeto com latitude e longitude numéricas (`Double`). |
| `regiaoManual` | `String` | Não* | Nome da cidade, bairro ou endereço informado manualmente quando o GPS estiver desligado. |
| `raioMetros` | `Integer` | Não | Raio máximo de busca em metros (padrão: 5000 m; expansível até 15000 m). |

*\*Regra de Validação*: Pelo menos um entre `localizacao` ou `regiaoManual` deve ser fornecido.

---

### 2. Response Payload (`BuscarServicosResponse`)

#### 2.1. Cenário de Sucesso (`200 OK`)

```json
{
  "consultaInterpretada": {
    "categoriaIdentificada": "SAUDE",
    "termoChave": "posto de saúde",
    "mensagemExplicativa": "Buscando postos de saúde e vacinação próximos a você"
  },
  "regiaoOrigem": {
    "descricao": "Americana - SP",
    "latitude": -22.7388,
    "longitude": -47.3325,
    "modo": "GPS_DISPOSITIVO"
  },
  "totalEncontrado": 2,
  "estabelecimentos": [
    {
      "id": "osm:node:10293847",
      "nome": "UBS Jardim Boer - Dr. Sérgio Pássaro",
      "categoria": "SAUDE",
      "subtituloTipo": "Unidade Básica de Saúde (Posto de Saúde)",
      "endereco": {
        "logradouro": "Rua das Amoras",
        "numero": "120",
        "bairro": "Jardim Boer",
        "cidade": "Americana",
        "estado": "SP",
        "cep": "13470-000",
        "textoFormatado": "Rua das Amoras, 120 - Jardim Boer, Americana - SP"
      },
      "latitude": -22.7410,
      "longitude": -47.3340,
      "distanciaMetros": 320.5,
      "distanciaFormatada": "320 metros",
      "telefone": "(19) 3461-1234",
      "horarioFuncionamento": "Segunda a Sexta, das 07:00 às 16:30",
      "horarioConfirmado": true,
      "fonte": "OPEN_STREET_MAP",
      "avisoTransparencia": null
    },
    {
      "id": "osm:node:59384712",
      "nome": "Farmácia Popular de Americana",
      "categoria": "SAUDE",
      "subtituloTipo": "Farmácia e Medicamentos",
      "endereco": {
        "logradouro": "Avenida Cillos",
        "numero": "1500",
        "bairro": "Jardim Ipiranga",
        "cidade": "Americana",
        "estado": "SP",
        "cep": "13468-580",
        "textoFormatado": "Avenida Cillos, 1500 - Jardim Ipiranga, Americana - SP"
      },
      "latitude": -22.7480,
      "longitude": -47.3400,
      "distanciaMetros": 1400.0,
      "distanciaFormatada": "1,4 km",
      "telefone": null,
      "horarioFuncionamento": null,
      "horarioConfirmado": false,
      "fonte": "OPEN_STREET_MAP",
      "avisoTransparencia": "Telefone e horário não informados pelo local"
    }
  ]
}
```

---

### 3. Tratamento de Erros e Casos de Borda

| Código HTTP | Cenário | Formato de Resposta (`ProblemaAcessivel`) |
|---|---|---|
| `400 Bad Request` | Nem localização nem região manual foram informadas. | `{"erro": "REGIAO_NAO_INFORMADA", "mensagem": "Por favor, ative a localização ou digite o nome do seu bairro ou cidade."}` |
| `404 Not Found` | Nenhum estabelecimento encontrado no raio especificado. | `{"erro": "NENHUM_LOCAL_ENCONTRADO", "mensagem": "Não encontramos nenhum local próximo nessa categoria. Tente aumentar a busca ou digitar outra cidade."}` |
| `503 Service Unavailable` | Provedor de mapas/OSM fora do ar ou sem resposta. | `{"erro": "SERVICO_MAPA_INDISPONIVEL", "mensagem": "Não foi possível carregar os locais no momento. Verifique sua conexão ou tente novamente em instantes."}` |
