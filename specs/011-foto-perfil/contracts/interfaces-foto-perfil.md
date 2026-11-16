# Contratos Internos e de Interface: Foto de Perfil (`011-foto-perfil`)

**Date**: 2026-11-16 | **Spec**: [spec.md](file:///c:/Users/Eduardo/Memora/specs/011-foto-perfil/spec.md)

Como a persistência da foto de perfil é exclusivamente local no aparelho (`Q1: A`), `contracts/openapi.yaml` **não sofre alterações**. Este documento define os contratos entre camadas do aplicativo Flutter para manter testabilidade, isolamento de plataforma e conformidade com o Design System.

---

## 1. Contrato do Processador de Imagem (`ProcessadorDeImagemDePerfil`)

- **Local previsto**: `app/lib/features/perfil/domain/processador_de_imagem.dart`
- **Responsabilidade**: Validar, recortar e sanitizar bytes brutos vindos de galeria/câmera antes de qualquer exibição ou persistência.
- **Entrada**: `Uint8List bytesBrutos` (ou stream/comprimento pré-verificado `<= 15 * 1024 * 1024` bytes).
- **Saída (`ResultadoDoProcessamento` — sealed)**:
  - `ImagemProcessada(Uint8List bytesJpegSemExif, int largura, int altura)`: sempre quadrada (`largura == altura <= 512`), codificada em JPEG limpo sem nenhum metadado EXIF/GPS/XMP/IPTC e já rotacionada conforme orientação original.
  - `ImagemRejeitada(MotivoRejeicaoImagem motivo)`:
    - `arquivoMuitoGrande`: ultrapassa 15 MB.
    - `formatoNaoSuportado`: assinatura real diferente de JPEG, PNG ou WebP (ex.: arquivo renomeado).
    - `imagemCorrompida`: falha ao decodificar dimensões ou pixels válidos.

---

## 2. Contrato do Seletor do Aparelho (`SeletorDeImagemDoAparelho`)

- **Local previsto**: `app/lib/features/perfil/data/seletor_de_imagem.dart`
- **Responsabilidade**: Abstrair `image_picker` e `android_intent_plus` para que a UI e os testes nunca dependam de canais nativos reais.
- **Enum de origem**: `OrigemDaFoto { galeria, camera }`
- **Métodos**:
  - `Future<ResultadoDaSelecao> selecionar(OrigemDaFoto origem)`:
    - `SelecaoConfirmada(Uint8List bytesBrutos)` *(a implementação real apaga de forma best-effort o arquivo temporário bruto criado em cache pelo `image_picker` imediatamente após ler `bytesBrutos` em memória, impedindo permanência de imagem com EXIF em cache)*
    - `SelecaoCancelada()`
    - `SelecaoSemPermissao(OrigemDaFoto origem)`
    - `SelecaoExcedeuLimite()` *(quando `XFile.length() > 15 MB` antes de carregar tudo em memória; também apaga o arquivo temporário em cache se aplicável)*
    - `SelecaoComFalha(String detalhe)`
  - `Future<bool> abrirConfiguracoesDoAparelho()`: abre a tela de permissões do Memora no Android (usando `android_intent_plus` com `try/catch` e retorno seguro `false` caso a plataforma ou intent não esteja disponível; injetável em testes).

---

## 3. Contrato de Armazenamento (`ArmazenamentoDeFotoDePerfil` & `FotoDePerfilDoAparelho`)

- **Local previsto**: `app/lib/features/perfil/data/foto_de_perfil_local.dart`
- **Contrato de sessão**:
  - `abstract interface class ArmazenamentoDeFotoDePerfil`
  - `abstract interface class FotoDePerfilDoAparelho implements ArmazenamentoDeFotoDePerfil, DadoLocalDoAparelho`
- **Métodos**:
  - `Future<RetratoDePerfil?> ler(String idDaConta)`: retorna `null` se `idDaConta` vazio, ausente ou se o arquivo `.jpg` apontado não existir/não puder ser lido.
  - `Future<FotoPropriaDePerfil> salvarFoto(String idDaConta, Uint8List bytesJpegSanitizados)`: grava arquivo único versionado no diretório privado da conta, atualiza a chave da conta no índice e remove arquivo antigo da mesma conta. Lança `ArgumentError` se `idDaConta` vazio/só de espaços.
  - `Future<AvatarIlustradoDePerfil> salvarAvatar(String idDaConta, AvatarIlustrado avatar)`: grava escolha de avatar e apaga eventual arquivo `.jpg` antigo daquela conta.
  - `Future<void> apagar(String idDaConta)`: apaga índice e eventual arquivo `.jpg` apenas da conta informada.
  - `Future<void> esquecerDoAparelho()` *(herdado de `DadoLocalDoAparelho`)*: remove **todas** as chaves `memora.foto_perfil.v1.*` e remove todos os arquivos dentro do diretório privado `fotos_perfil/`.
- **Implementações**:
  - `FotoDePerfilLocal`: usa `SharedPreferences` + `Directory` privado (`path_provider`, injetável em testes).
  - `FotoDePerfilEmMemoria`: implementação síncrona/assíncrona leve para testes de widget e fluxo.

---

## 4. Contrato da Camada de Apresentação (`SecaoFotoPerfil` / `TelaPerfil`)

- **Componentes**:
  - `RetratoDoPerfil` (`app/lib/features/perfil/presentation/widgets/retrato_do_perfil.dart`): renderiza foto própria (`Image.file` ou `Image.memory` em fallback de teste), avatar ilustrado (`Image.asset` / `IlustracaoMemora`) ou retrato padrão neutro (iniciais/ícone humano), sempre em círculo com borda `MemoraDimensoes.bordaAvatar` e `Semantics` clara (`"Sua foto de perfil"` vs `"Nenhuma foto de perfil escolhida"`).
  - `SecaoFotoPerfil` (`app/lib/features/perfil/presentation/secao_foto_perfil.dart`): controla leitura por conta (`didUpdateWidget`), guarda contra dupla operação (`_ocupado`), folha de origem com explicação `FR-004` integrada, grade acessível de avatares, navegação para `TelaPreVisualizacaoFoto`, diálogo `ConfirmacaoMemora` de remoção e painel amigável de permissão negada / arquivo inválido.
  - `TelaPreVisualizacaoFoto` (`app/lib/features/perfil/presentation/tela_pre_visualizacao_foto.dart`): tela simples de confirmação antes de salvar ("Ficou boa assim?") com botões explícitos **"Usar esta foto"** e **"Escolher outra"**, altura ≥ 48 dp, respeito a `reduzirMovimento` (`disableAnimations`), suporte a 200% e aos 3 temas.
- **Chaves estáveis para testes automatizados**:
  - `TelaPerfil.chaveDesenho` *(chave única aplicada ao `RetratoDoPerfil` renderizado no cabeçalho de `TelaPerfil` via `SecaoFotoPerfil`)*
  - `SecaoFotoPerfil.chaveBotaoColocarOuTrocar` (`"Colocar foto de perfil"` / `"Trocar foto"`)
  - `SecaoFotoPerfil.chaveBotaoRemover`
  - `SecaoFotoPerfil.chaveConfirmacaoRemover`
  - `SecaoFotoPerfil.chaveAvisoErroOuPermissao`
  - `SecaoFotoPerfil.chaveOpcaoGaleria`, `chaveOpcaoCamera`, `chaveOpcaoAvatares`
  - `TelaPreVisualizacaoFoto.chaveConfirmar`, `TelaPreVisualizacaoFoto.chaveEscolherOutra`
