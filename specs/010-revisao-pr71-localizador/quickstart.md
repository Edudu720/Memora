# Quickstart de Verificação: Correções da Revisão da PR #71

Use este guia durante e ao término da etapa `/speckit-implement` para comprovar todos os requisitos (`FR-001` a `FR-013` e `SC-001` a `SC-005`) na branch `feature/009-localizador-servicos`.

---

## V1 — Auditoria de PII, Exclusão de `Memora-Desing-Ideias/` e Histórico Git

Execute na raiz do repositório (`c:\Users\Eduardo\Memora`):

```powershell
# 1. Zero ocorrências de CPF numérico (padrão NNN.NNN.NNN-NN) ou nomes pessoais de captura nos arquivos rastreados
git grep -nE "[0-9]{3}\.[0-9]{3}\.[0-9]{3}-[0-9]{2}" -- scripts/ specs/006-guias-servicos-sociais/ specs/010-revisao-pr71-localizador/
git grep -niE "<nome-civil-expurgado>|nome completo.*:" -- scripts/ specs/006-guias-servicos-sociais/

# 2. Zero ocorrências do CPF real expurgado em TODO o histórico alcançável da branch após a consolidação (squash)
git log origin/develop..feature/009-localizador-servicos -G "[0-9]{3}\.[0-9]{3}\.[0-9]{3}-[0-9]{2}" --oneline -- scripts/ specs/006-guias-servicos-sociais/
git ls-files Memora-Desing-Ideias/
git rev-list --objects feature/009-localizador-servicos ^origin/develop | Select-String "Memora-Desing-Ideias"

# 3. Exatamente 1 commit limpo sobre origin/develop
git rev-list --count origin/develop..feature/009-localizador-servicos
```

**Critério de aprovação**: todos os greps e buscas por objetos retornam vazio (`0` ocorrências), e a contagem de commits acima de `origin/develop` é `1`.

---

## V2 — Backend Java / Spring Boot (Nomenclatura, Osm/Nominatim, Ausência de Contingência)

Execute dentro de `backend/`:

```powershell
./mvnw --batch-mode test
```

Verificar explicitamente:
- Existência de `InterpretadorDeIntencaoPorPalavrasChave.java` e `InterpretadorDeIntencaoPorPalavrasChaveTest.java` e ausência de `InterpretadorDeIntencaoComGemini*` via `git grep InterpretadorDeIntencaoComGemini -- backend/`.
- Novo teste unitário de `ProvedorOpenStreetMapOverpass` cobrindo:
  1. Envio do `User-Agent` identificável do projeto Memora;
  2. Espaçamento mínimo `>= 1000 ms` garantido em fila sincronizada entre chamadas consecutivas/concorrentes ao Nominatim e timeouts explícitos (`5s` Nominatim/conexão; `6s` Overpass HTTP);
  3. Falha transparente (sem retornar lista de contingência ou coordenadas fixas de Americana - SP) quando Nominatim/Overpass falham ou não encontram a região;
  4. `LocalizadorController` respondendo `503 Service Unavailable` em falha externa e `200 OK` tanto em `/v1/servicos/buscar` quanto em `/api/v1/servicos/buscar`.

---

## V3 — Aplicativo Flutter (Voz Offline, Localizador Real & Modo Simulado Seguro)

Execute dentro de `app/`:

```powershell
flutter analyze
flutter test test/features/assistente/ditado_por_voz_test.dart test/features/localizador/
flutter test
```

Verificar cobertura obrigatória nos testes:
- **`test/features/assistente/`**: teste comprovando `onDevice: true` em `SpeechListenOptions`, ausência de fallback para `onDevice: false` e emissão de `EstadoDitado.indisponivel` com orientação ao teclado / pacote offline de português.
- **`test/features/localizador/`**:
  - `RepositorioLocalizadorApi` + `FonteLocalizadorApi`: monta cabeçalho Bearer via opção `'secure'`, resolve corretamente `/servicos/buscar` com `baseUrl` terminando em `/v1`, e propaga erro em falha sem acionar `RepositorioLocalizadorSimulado`.
  - `Composicao.resolver`: instancia `RepositorioLocalizadorApi` quando `usaServidorReal == true` e `RepositorioLocalizadorSimulado` quando `usaServidorReal == false`.
  - `RepositorioLocalizadorSimulado`: todos os itens em `todosOsEstabelecimentos` possuem `telefone == null` e resultado retorna `ehDemonstracao == true`.
  - `ControladorLocalizador` e `TelaLocalizador`: não disparam busca remota automática antes da resposta ao diálogo inicial de permissão, limpam lista anterior ao falhar em busca subsequente, não centralizam mapa em coordenadas fixas de Americana - SP quando sem busca, exibem banner de demonstração (`ehDemonstracao == true`) em lista e mapa, exibem erro com *"Tentar novamente"*, e declaram consulta pública ao OpenStreetMap tanto em `DialogoPermissaoLocalizacao` quanto no modal `_solicitarRegiaoManual`.
  - `acoes_seguras_test.dart`: valida diálogo de confirmação de ligação usando fixture explícita de teste com número fictício isolado.

---

## V4 — Portões de Design System, Pacote Gerado e CI

Execute na raiz e no pacote gerado:

```powershell
python specs/002-design-system/ferramentas/validar_paleta.py --autoteste
python specs/002-design-system/ferramentas/validar_paleta.py
python specs/002-design-system/ferramentas/validar_tokens.py --autoteste
python specs/002-design-system/ferramentas/validar_tokens.py
```

E dentro de `app/pacotes/memora_api/`:

```powershell
dart analyze
dart test
```

Conferir `.github/workflows/verificacao.yml`:
- `flutter-version: '3.47.7'` (sem chaves duplicadas nem `3.41.6`);
- `flutter analyze` estrito (sem `--no-fatal-infos`).
- Status atualizados nos cabeçalhos de `specs/006-guias-servicos-sociais/spec.md`, `specs/007-redesenho-visual-profissional/spec.md` e `specs/009-localizador-servicos/spec.md` (incluindo nota de reconciliação na `009` sobre o interpretador por palavras-chave sem Gemini).
