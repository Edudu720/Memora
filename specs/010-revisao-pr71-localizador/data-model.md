# Modelo de Dados e Invariantes: Correções da Revisão da PR #71

**Feature**: `010-revisao-pr71-localizador`  
**Escopo**: Ajustes de contratos de domínio, estado de apresentação e invariantes de privacidade/segurança sobre os módulos `localizador`, `assistente` e controle de versão.

---

## 1. Domínio Flutter — Localizador (`app/lib/features/localizador/domain/`)

### 1.1 `ResultadoBuscaServicos` (`domain/repositorios/repositorio_localizador.dart`)

Entidade de retorno da consulta de serviços próximos.

| Campo | Tipo | Padrão | Regra / Invariante |
|---|---|---|---|
| `categoriaIdentificada` | `String?` | `null` | Código da categoria resolvida (`SAUDE`, `SERVICOS_PUBLICOS`, `EMERGENCIA`, `COTIDIANO`). |
| `termoChave` | `String?` | `null` | Termo normalizado usado na busca. |
| `mensagemExplicativa` | `String?` | `null` | Explicação amigável da busca executada. |
| `descricaoRegiao` | `String` | — | Nome da região utilizada; no simulado deve sinalizar claramente ambiente de demonstração. |
| `estabelecimentos` | `List<EstabelecimentoServico>` | — | Lista vazia permitida apenas quando a região foi consultada com sucesso e não possui registros no raio; indisponibilidade externa **lança exceção**. |
| `ehDemonstracao` *(novo)* | `bool` | `false` | `true` exclusivamente em resultados produzidos por `RepositorioLocalizadorSimulado`; sempre `false` em `RepositorioLocalizadorApi`. |

### 1.2 `EstabelecimentoServico` (`domain/entidades/estabelecimento_servico.dart`)

| Campo relevante | Regra no Modo Real (`RepositorioLocalizadorApi`) | Regra no Modo Simulado (`RepositorioLocalizadorSimulado`) |
|---|---|---|
| `telefone` | Opcional (`String?`), vindo exclusivamente de dados retornados pelo provedor real. | **Obrigatoriamente `null`** em todos os itens (incluindo categoria `emergencia`), fazendo `temTelefone == false` e ocultando o botão *Ligar*. |
| `avisoTransparencia` | Opcional (`String?`), preservado do backend. | Indica explicitamente tratar-se de dado fictício de demonstração/exemplo. |
| `fonte` | Identificador da fonte retornada pela API (ex.: `OPEN_STREET_MAP`). | Identificador explícito de demonstração simulada local. |

---

## 2. Estado de Apresentação — Localizador (`ControladorLocalizador` e `TelaLocalizador`)

### Máquina de Estados da Busca no `ControladorLocalizador`

```text
[Inicial / Aguardando Permissão (precisaExplicarPermissao == true)]
   ├─(não dispara busca remota automática; exibe convite neutro sem centro fixo de Americana - SP)
   ├─(usuário recusa GPS sem região manual)──▶ [Aguardando Região Manual (lista vazia com convite claro)]
   └─(usuário autoriza GPS ou informa região manual)──▶ [Carregando (carregando = true, mensagemErro = null)]
          ├─(Sucesso: API retorna HTTP 200 ou modo simulado)──▶ [Resultado exibido]
          │      ├─ se resultado.ehDemonstracao == true  ──▶ Renderiza Banner de Demonstração na TelaLocalizador (lista e mapa)
          │      └─ se resultado.ehDemonstracao == false ──▶ Renderiza resultados reais e centraliza mapa na região retornada
          └─(Falha de rede / HTTP 4xx ou 5xx / timeout / sem JSON válido)──▶ [Indisponível (mensagemErro != null)]
                 └─ limpa estabelecimentos anteriores, suprime texto de lista vazia e exibe "Tentar novamente" + busca manual
```

**Invariantes críticos (`Q1` / `FR-007` / `CHK004` / `CHK025`)**:
- Em modo servidor real (`usaServidorReal == true`), falhas na camada remota **nunca** transitam para o estado `Resultado exibido` nem preservam estabelecimentos de uma busca anterior abaixo do aviso de erro.
- Em `TelaLocalizador`, o modo mapa sem busca concluída nem posição GPS não pode usar coordenadas fixas de Americana - SP (`-22.7388, -47.3325`) como centro padrão — deve orientar a escolha de região ou usar a região carregada no último resultado válido.

---

## 3. Domínio Flutter — Voz Local (`app/lib/features/assistente/domain/leitor_de_voz.dart`)

### Contrato de `LeitorDeVozSpeechToText` -> `ResultadoDitado`

| Evento | Estado Resultante (`EstadoDitado`) | Regra |
|---|---|---|
| Aparelho aceita `SpeechListenOptions(onDevice: true)` | `EstadoDitado.ouvindo` | Captura streaming em português para rascunho em memória; zero gravação em disco, zero envio em nuvem. |
| Aparelho recusa `onDevice: true` / falta pacote offline `pt-BR` / permissão negada | `EstadoDitado.indisponivel` | **Aborto imediato** sem retry com `onDevice: false`. `mensagem` orienta digitação pelo teclado ou download do pacote de voz offline em português no aparelho. |
| Erro durante escuta local já iniciada | `EstadoDitado.erro` | Mantém eventual rascunho parcial e exibe orientação amigável sem fallback remoto. |

---

## 4. Domínio Backend — Localizador (`backend/src/main/java/br/fatec/memora/localizador/`)

| Componente | Responsabilidade Atualizada | Exceções / Erros Explicitados |
|---|---|---|
| `InterpretadorDeIntencaoPorPalavrasChave` | Classifica texto livre do usuário por palavras-chave locais nas categorias `SAUDE`, `SERVICOS_PUBLICOS`, `EMERGENCIA`, `COTIDIANO`. Nenhuma chamada ao Gemini. | N/A |
| `ProvedorOpenStreetMapOverpass` | Consulta Nominatim (com `User-Agent` identificável do projeto e rate limit `<= 1 req/s`) e Overpass API (com `User-Agent` identificável). | `IllegalArgumentException` quando região manual não puder ser geocodificada; exceção de provedor indisponível (`ProvedorGeograficoIndisponivelException` -> HTTP `503`) em erros HTTP/I/O. Sem contingência Americana - SP. |
| `LocalizadorController` | Expõe `/v1/servicos/buscar` e `/api/v1/servicos/buscar` sob autenticação Bearer JWT. | `400 Bad Request` para entrada ausente/região não localizada; `503 Service Unavailable` para falha externa transparente. |

---

## 5. Invariantes de Privacidade, Repositório e CI

- **Zero PII na branch e no histórico**: Nenhuma ocorrência de CPF real (`[0-9]{3}\.[0-9]{3}\.[0-9]{3}-[0-9]{2}`) nem de nomes civis reais ligados às capturas em `HEAD` ou em qualquer commit alcançável de `feature/009-localizador-servicos`.
- **Exclusão de assets não versionáveis**: `Memora-Desing-Ideias/` ausente de `git ls-files` e listada em `.gitignore`.
- **Topologia de Commit (`Q3`)**: Exatamente 1 commit limpo sobre `origin/develop`.
- **CI (`.github/workflows/verificacao.yml`)**: `flutter-version: '3.47.7'` e `flutter analyze` sem `--no-fatal-infos`.
