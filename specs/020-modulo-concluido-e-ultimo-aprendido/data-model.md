# Modelo de Dados: Feature 020

## 1. Persistência Local (`ProgressoDeAprendizado`)

Arquivo privado: `<ApplicationDocumentsDirectory>/progresso_de_aprendizado.json`

```json
{
  "contas": {
    "<idDaConta>": {
      "<chave>": {
        "vezes": 1,
        "ordem": 42
      }
    }
  }
}
```

- **Chave simples** (guia sem seções, ex.: `whatsapp`, `tiktok`, `youtube`, `e-titulo`, `fgts`): `<guia.chave>`.
- **Chave composta** (guia com seções, ex.: `gov-br`, `instagram`, `facebook`, `telegram`, `serasa`, `correios`): `<guia.chave>:<secao.chave>`.
- **`ordem`**: inteiro monotônico global em todo o arquivo (`1 + _maiorOrdem(tudo)`), permitindo comparação cronológica determinística mesmo dentro do mesmo milissegundo em testes.

### Novos membros em `ProgressoDeAprendizado`
- `Stream<void> get alteracoes`: stream broadcast emitida após cada conclusão salva (`registrarConclusao`) e após limpeza (`apagar`).
- `Future<Map<String, int>> ordensDeConclusao(String idDaConta)`: retorna `{chave: ordem}` para a conta (vazio se `idDaConta` em branco ou ausente).
- `Future<String?> ultimoConcluido(String idDaConta)`: retorna a chave de entrada com maior `ordem` para `idDaConta` (ou `null` quando vazia).

## 2. Regras de Domínio (`app/lib/features/aprendizado/domain/estado_do_modulo.dart`)

### `moduloConcluido(Guia guia, Map<String, int> concluidos) -> bool`
- Se `guia.temSecoes`:
  - Retorna `true` somente se `guia.secoes.isNotEmpty` e **toda** `secao` em `guia.secoes` satisfizer `(concluidos['${guia.chave}:${secao.chave}'] ?? 0) > 0`.
- Caso contrário (guia sem seções):
  - Retorna `(concluidos[guia.chave] ?? 0) > 0`.

### `chaveDoUltimoModuloConcluido(Map<String, int> ordens, Iterable<Guia> guias) -> String?`
- Mantém `Set<String> chavesConhecidas` ao iterar `guias`:
  - Se `guia.temSecoes`: verifica se `guia.secoes.isNotEmpty` e se toda seção tem `(ordens['${guia.chave}:${s.chave}'] ?? 0) > 0`. Quando completo, calcula `maiorOrdem = max(ordens['${guia.chave}:${s.chave}'])` sobre as seções e torna `guia.chave` elegível com essa `maiorOrdem`.
  - Se `!guia.temSecoes`: quando `(ordens[guia.chave] ?? 0) > 0`, torna `guia.chave` elegível com `ordens[guia.chave]!`.
- Percorre também entradas em `ordens.entries` onde `!chave.contains(':') && !chavesConhecidas.contains(chave) && ordem > 0` (permite chaves de guias diretos não listados em `guias`), comparando sua `ordem`.
- Retorna a `chave` elegível de maior `ordem`, ou `null` caso nenhuma seja elegível.

## 3. Resolução de Nome Exibido (Perfil)
- Helper compartilhado em `TelaPerfil`: `_nomeExibidoDoModulo(String? chave)`:
  1. Se `chave == null`, retorna `null`.
  2. Busca correspondência em `RepositorioAssistenteSimulado.catalogoDaDemonstracao` por `s.chave == chave` e retorna `s.nomeExibido`.
  3. Senão busca `guiaDe(chave)` e retorna `guia.titulo`.
  4. Fallback final: retorna a própria `chave`.
