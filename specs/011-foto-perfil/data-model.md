# Data Model: Foto de Perfil da Pessoa Usuária (`011-foto-perfil`)

**Date**: 2026-11-16 | **Spec**: [spec.md](file:///c:/Users/Eduardo/Memora/specs/011-foto-perfil/spec.md)

## Visão Geral

Por decisão arquitetural (`Q1: A`), não há alterações no modelo relacional do servidor nem em `PessoaUsuaria` / migrations SQL / `contracts/openapi.yaml`. Toda a modelagem pertence à camada de domínio e persistência local da feature `perfil` no aplicativo Flutter.

## Entidades de Domínio

### 1. `RetratoDePerfil` *(sealed class)*

Representa a escolha salva para a conta atual no aparelho. Pode assumir duas variantes concretas:

#### `FotoPropriaDePerfil`
- **Campos**:
  - `caminhoDoArquivo` (`String`): caminho absoluto no subdiretório privado de suporte do aplicativo (`<appSupportDir>/fotos_perfil/<contaSegura>.jpg`).
  - `atualizadaEm` (`DateTime`): instante UTC de gravação da versão atual (também usado para invalidar cache em memória quando a imagem é trocada no mesmo caminho ou com novo sufixo de versão).
- **Regras de validação / invariantes**:
  - `caminhoDoArquivo` deve apontar para arquivo `.jpg` regular existente no diretório privado de fotos do app.
  - Conteúdo originado exclusivamente pelo `ProcessadorDeImagemDePerfil` (<= 512×512 px, recorte quadrado `1:1`, sem metadados EXIF).
  - Se o arquivo desaparecer ou falhar ao ler no disco, a leitura retorna `null` (recuando ao Retrato Padrão).

#### `AvatarIlustradoDePerfil`
- **Campos**:
  - `avatar` (`AvatarIlustrado`): valor tipado do enum de avatares ilustrados da Memora.
- **Regras de validação / invariantes**:
  - Apenas valores válidos de `AvatarIlustrado` são aceitos; identificadores desconhecidos armazenados localmente recuam para `null` (Retrato Padrão).

---

### 2. `AvatarIlustrado` *(enum)*

Catálogo fechado de ilustrações acolhedoras embarcadas em `app/assets/ilustracoes/` (sem necessidade de permissões nem rede):

| Valor | Caminho do Asset | Rótulo Acessível (PT-BR) |
|---|---|---|
| `memoraAcenando` | `assets/ilustracoes/memora_perfil_robo.png` | Memora acenando |
| `memoraPensando` | `assets/ilustracoes/memora_ajuda_robo.png` | Memora pensando |
| `memoraComemorando` | `assets/ilustracoes/memora_conclusao_robo.png` | Memora comemorando |
| `memoraProtegendo` | `assets/ilustracoes/memora_alerta_robo.png` | Memora protegendo |
| `casalIdoso` | `assets/ilustracoes/casal_idoso.svg` | Casal acolhedor |
| `pessoaComCelular` | `assets/ilustracoes/pessoa_com_celular.svg` | Pessoa com celular |

---

### 3. `RetratoPadrao` *(estado ausente = `null`)*

Quando não há `RetratoDePerfil` salvo para a conta ativa:
- Derivado em memória na apresentação a partir de `nome` da pessoa autenticada (`widget.nome`).
- Exibe iniciais legíveis do nome de tratamento (1 a 2 letras maiúsculas) em círculo contrastado ou ícone humano neutro (`Icons.person_outline`) se `nome` estiver vazio/sem letras, distinto da personagem Memora.

---

### 4. `PoliticaDeImagemDePerfil` *(constantes de validação e sanitização)*

- `tamanhoMaximoEntradaBytes`: `15 * 1024 * 1024` (15 MB) — verificado antes da decodificação completa.
- `dimensaoMaximaPx`: `512` (512×512 px no máximo; imagens menores quadradas são mantidas sem ampliação artificial acima do lado original menor).
- `formatosAceitos`: assinatura binária real JPEG (`FF D8 FF`), PNG (`89 50 4E 47`) ou WebP estático (`RIFF....WEBP` com quadro único; rejeitar explicitamente `HEIC`, `GIF`, SVG externo e WebP animado multi-quadro como `formatoNaoSuportado`).
- `qualidadeJpegSaida`: `88` (re-encode limpo sem nenhum segmento EXIF/APP1/GPS/XMP).

---

## Esquema de Armazenamento Local

1. **Índice por conta (`SharedPreferences`)**:
   - **Chave**: `'memora.foto_perfil.v1.' + contaSegura(idDaConta)`
   - **`contaSegura(idDaConta)`**: derivada exclusivamente por codificação segura `[a-zA-Z0-9_-]` (ex.: hash hex / base64url seguro sem `.` ou `/`, rejeitando `idDaConta.trim().isEmpty` com `ArgumentError`). Impede *path traversal* (`../`).
   - **Valor JSON**:
     - Foto própria: `{"tipo": "foto", "arquivo": "<contaSegura>_<timestampMs>.jpg", "atualizadaEm": "2026-11-16T12:00:00.000Z"}`
     - Avatar ilustrado: `{"tipo": "avatar", "avatar": "memoraAcenando"}`
     - *Nota sobre o nome com `<timestampMs>`*: trocar a foto grava o novo arquivo versionado e remove o arquivo anterior imediatamente, evitando qualquer cache de imagem do `FileImage` no Flutter ao substituir uma foto existente!

2. **Diretório privado de arquivos (`path_provider`)**:
   - `<getApplicationSupportDirectory()>/fotos_perfil/<contaSegura>_<timestampMs>.jpg`
   - Coberto pelas regras de exclusão de backup do Android (`android:allowBackup="false"`, `@xml/backup_rules`, `@xml/data_extraction_rules`).

---

## Máquina de Estados e Transições

```text
[Sem Foto (Retrato Padrão)]
   ├──(tocar "Colocar foto de perfil")──▶ [Folha de Origem (com explicação FR-004)]
   │      ├──("Escolher avatar")──▶ [Grade de Avatares] ──(escolher avatar)──▶ [Salvo: Avatar]
   │      ├──("Escolher da galeria" / "Tirar foto")──▶ [Seletor Nativo]
   │      │      ├──(cancelado)──▶ mantém estado anterior (sem erro)
   │      │      ├──(permissão negada)──▶ [Aviso amigável + Abrir ajustes / Usar avatar]
   │      │      ├──(> 15 MB / formato inválido / corrompido)──▶ [Aviso claro + mantém anterior]
   │      │      └──(imagem válida + EXIF limpo)──▶ [Pré-visualização 1:1]
   │      │             ├──("Escolher outra")──▶ volta à escolha de origem
   │      │             └──("Usar esta foto")──▶ [Salvo: Foto Própria (512x512 sem EXIF)]
   │
[Salvo: Foto Própria ou Avatar]
   ├──("Trocar foto")──▶ [Folha de Origem] (substitui anterior apenas após confirmação final)
   ├──("Remover foto")──▶ [ConfirmacaoMemora ("Sim, tirar a foto" / "Não, manter")]
   │      └──(confirmado)──▶ apaga arquivo + chave local ──▶ [Sem Foto (Retrato Padrão)]
   ├──(Sair comum da conta)──▶ preserva registro e arquivo dessa conta no aparelho
   └──("Sair e esquecer este aparelho" / esquecerTudo)──▶ apaga todas as chaves e o diretório fotos_perfil/
```
