# Data Model: Avatares da Memora e da Pessoa Usuária no Chat

**Feature**: `022-avatares-no-chat` | **Date**: 2026-11-22

---

## 1. Modelo de Retrato Local (Reutilizado de `011` / `016`)

Nenhum esquema relacional (PostgreSQL/Flyway) ou contrato OpenAPI é criado ou alterado. Toda a informação de retrato reside exclusivamente no aparelho:

### `RetratoDePerfil` (`app/lib/features/perfil/domain/retrato_de_perfil.dart`)

União selada com três representações suportadas no chat para o balão `"Você"`:

1. **`FotoPropriaDePerfil`**:
   - `caminhoDoArquivo: String` (JPEG `<= 512×512 px`, proporção `1:1`, metadados EXIF/GPS removidos na captura/seleção);
   - `atualizadaEm: DateTime` (timestamp UTC utilizado na `ValueKey` da imagem para invalidar cache em substituições);
   - `bytesEmMemoria: List<int>?` (preenchido apenas pela implementação em memória nos testes de widget).
2. **`AvatarIlustradoDePerfil`**:
   - `avatar: AvatarIlustrado` (catálogo fechado da feature `016`: `memoraAcenando`, `memoraPensando`, `memoraComemorando`, `memoraProtegendo`).
3. **`null` (Retrato Padrão Neutro)**:
   - Quando a conta nunca escolheu foto/avatar, removeu o retrato ou o arquivo JPEG referenciado está ausente/ilegível no disco (`errorBuilder` do `Image`), exibe círculo neutro com as iniciais derivadas de `nomeTratamento` ou o ícone `Icons.person_outline_rounded` / `_RostoDaPessoa`.

---

## 2. Canal Reativo Local (`ArmazenamentoDeFotoDePerfil`)

Extensão compatível da interface em `app/lib/features/perfil/data/foto_de_perfil_local.dart`:

| Membro | Tipo | Papel | Emissões |
|---|---|---|---|
| `ler(idDaConta)` | `Future<RetratoDePerfil?>` | Lê preferência JSON em `SharedPreferences` + valida existência do `.jpg` em `fotos_perfil/`. | — |
| `salvarFoto(...)` | `Future<FotoPropriaDePerfil>` | Persiste JPEG sanitizado e índice JSON da conta. | Emite evento em `alteracoes` |
| `salvarAvatar(...)` | `Future<AvatarIlustradoDePerfil>` | Persiste chave do avatar escolhido e remove foto anterior. | Emite evento em `alteracoes` |
| `apagar(idDaConta)` | `Future<void>` | Remove índice da conta e eventual arquivo `.jpg`. | Emite evento em `alteracoes` |
| `esquecerDoAparelho()` | `Future<void>` | Limpa todas as chaves `memora.foto_perfil.v1.*` e apaga o diretório `fotos_perfil/`. | Emite evento em `alteracoes` |
| `alteracoes` *(novo)* | `Stream<void>` (`broadcast`) | Notifica ouvintes ativos na sessão (ex.: `TelaConversa`) quando houver qualquer mudança ou limpeza de retrato. | — |

---

## 3. Estado Visual Transitório em `TelaConversa`

| Campo em `_TelaConversaState` | Tipo | Inicialização e Ciclo de Vida |
|---|---|---|
| `_retrato` | `RetratoDePerfil?` | Inicia como `null` (padrão neutro imediato, sem placeholder travado), atualizado após `ler(idDaConta)`. Zerado imediatamente quando `idDaConta` fica nulo/vazio ou muda. |
| `_versaoRetrato` | `int` | Incrementado a cada chamada de `_carregarRetrato()`; descarta respostas assíncronas antigas caso a conta ou o retrato tenham mudado durante o `await`. |
| `_assinaturaFoto` | `StreamSubscription<void>?` | Inscrita em `widget.fotoDePerfil?.alteracoes` no `initState`, re-inscrita no `didUpdateWidget` e cancelada no `dispose`. |

---

## 4. Fluxo de Estado e Isolamento

```text
[Perfil: salvarFoto / salvarAvatar / apagar]
         │
         ▼
FotoDePerfilLocal / FotoDePerfilEmMemoria
   ├── Atualiza SharedPreferences / fotos_perfil/ (local)
   └── Emite notificação no broadcast `alteracoes`
         │
         ▼
_TelaConversaState (_carregarRetrato com _versaoRetrato)
   ├── idDaConta nulo/vazio ──► `_retrato = null`
   └── idDaConta válido     ──► lê `ler(idDaConta)` localmente
                                 ├── OK   ──► aplica novo `RetratoDePerfil`
                                 └── Erro ──► mantém `_retrato = null` (padrão neutro seguro)
```
