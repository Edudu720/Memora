# Research: Foto de Perfil da Pessoa Usuária (`011-foto-perfil`)

**Date**: 2026-11-16 | **Branch**: `feature/011-foto-perfil` | **Spec**: [spec.md](file:///c:/Users/Eduardo/Memora/specs/011-foto-perfil/spec.md)

## R1 — Seleção de imagem na galeria e na câmera sem acesso amplo à mídia

- **Decision**: Utilizar o plugin oficial `image_picker` encapsulado atrás de uma interface de domínio/aplicação (`SeletorDeImagemDoAparelho`), usando `ImageSource.gallery` (que aciona o Android Photo Picker no Android 13+, sem precisar de `READ_MEDIA_IMAGES` nem acesso amplo à galeria) e `ImageSource.camera` apenas quando a pessoa escolher explicitamente tirar uma foto.
- **Rationale**:
  - No Android 13+ (API 33+), `image_picker` delega `ImageSource.gallery` ao Photo Picker do sistema, garantindo acesso restrito apenas ao arquivo escolhido pela pessoa (`Threat Modeling` / Princípio I).
  - Não declarar `READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE` evita alertas invasivos na Play Store e no sistema.
  - Declarar `CAMERA` no `AndroidManifest.xml` (com `android:required="false"` em `<uses-feature android:name="android.hardware.camera" android:required="false"/>`) permite que o fluxo de câmera solicite permissão somente sob demanda quando a pessoa toca em "Tirar foto agora", mantendo compatibilidade com aparelhos sem câmera ou pessoas que só usam galeria/avatares.
  - Encapsular `ImagePicker` em `SeletorDeImagemDoAparelho` permite testar todos os cenários (seleção válida, cancelamento, permissão negada, falha de leitura) deterministicamente em `flutter test` sem canais nativos reais.
- **Alternatives considered**:
  - `file_picker`: abre seletor genérico de documentos/pastas (UX confusa para público 65+ e sem captura direta de câmera).
  - `camera` plugin embutido: exigiria gerenciar preview de câmera, ciclo de vida de hardware e superfície própria, aumentando risco e complexidade sem ganho real frente à câmera nativa do sistema.

## R2 — Validação real de arquivo, recorte quadrado `512×512` e remoção garantida de EXIF

- **Decision**: Processar os bytes escolhidos com o pacote puro Dart `image` (`ProcessadorDeImagemDePerfil`), em `Isolate.run` para não travar a thread de UI:
  1. Verificar tamanho bruto em bytes **antes** de decodificar (`<= 15 MB = 15 * 1024 * 1024` bytes).
  2. Validar assinatura real (magic bytes / formato JPEG, PNG ou WebP suportado — rejeitando arquivos renomeados como `.jpg` ou corrompidos).
  3. Decodificar com proteção contra dimensões abusivas (ex.: limitar decodificação / rejeitar imagens corrompidas), aplicar normalização de orientação EXIF (`bakeOrientation`) antes de descartar o EXIF (para a foto não ficar deitada!) e recortar um quadrado centralizado (`copyResizeCropSquare` com tamanho máximo `min(512, menorLado)`).
  4. Re-encodar os pixels limpos como novo JPEG (`encodeJpg`, qualidade 88) sem copiar nenhum bloco `APP1`/EXIF/GPS/XMP/IPTC.
- **Rationale**:
  - Como é Dart puro, executa de forma idêntica em produção (Android/iOS) e em testes unitários (`flutter test` no Windows/Linux CI), permitindo provar por teste automatizado com JPEG sintético contendo tags EXIF GPS que **100% dos metadados EXIF desaparecem** no arquivo gravado (`SC-003`).
  - `bakeOrientation` antes do re-encode garante que selfies e fotos em retrato não fiquem rotacionadas em 90° após remover a tag `Orientation` do EXIF.
  - Executar em `Isolate.run` mantém 60 fps na interface mesmo com fotos de 12–48 MP até 15 MB.
- **Alternatives considered**:
  - `flutter_image_compress`: depende de código nativo por plataforma (inviável rodar de verdade no `flutter test` da VM Dart do CI).
  - `image_cropper`: exigiria tela externa de pinça/arraste (rejeitada na clarificação `Q1` de UX em favor do enquadramento automático centralizado com pré-visualização simples).

## R3 — Armazenamento local privado isolado por conta e ciclo de vida (`LimpezaDeSessao`)

- **Decision**: Persistir em duas peças coordenadas atrás de `FotoDePerfilDoAparelho` (implementando `ArmazenamentoDeFotoDePerfil` + `DadoLocalDoAparelho`):
  - **Metadado de escolha** em `SharedPreferences`, com chave prefixada `memora.foto_perfil.v1.<contaHash>`: registra o modo selecionado (`avatar:<id>` ou `foto:<nomeArquivoLocal>`).
  - **Arquivo binário da foto própria** no diretório privado de suporte do aplicativo (`getApplicationSupportDirectory()` / subdiretório `fotos_perfil/`, injetável nos testes), com nome derivado de hash SHA-256 ou sanitização estrita do `idDaConta` + sufixo único (`.jpg`) para impedir *path traversal* mesmo diante de ids malformados, nunca exposto em galeria compartilhada nem cache externo.
  - **Ciclo de vida na sessão**: implementa `DadoLocalDoAparelho` (como `DataDeNascimentoLocal`, FR-042c):
    - **Saída comum** (`esquecerTudo: false`): mantém o retrato local da conta para que a pessoa idosa não perca sua foto ao sair e entrar de novo no próprio celular.
    - **Remoção explícita pelo usuário** (`apagar(idDaConta)`): remove a chave em `SharedPreferences` e exclui o arquivo `.jpg` do disco.
    - **Sair e esquecer este aparelho** (`esquecerTudo: true`): remove **todas** as chaves com o prefixo `memora.foto_perfil.v1.` e limpa o subdiretório `fotos_perfil/` inteiro de todas as contas.
    - **Troca de conta no mesmo aparelho**: leitura e gravação são indexadas por `idDaConta` (`didUpdateWidget` recarrega imediatamente ao trocar `idDaConta`), impossibilitando vazamento entre contas.
- **Rationale**:
  - Segue exatamente o padrão já auditado e aprovado em `DataDeNascimentoLocal` (`FR-042c`) e `ConversaLocal` (`path_provider`), reaproveitando o contrato estático `DadoLocalDoAparelho` em `LimpezaDeSessao` e `Composicao`.
  - Guardar metadados estruturados + fallback seguro: se o arquivo `.jpg` no diretório privado não existir ou estiver ilegível na leitura, o repositório recua silenciosamente para `null` (exibindo o retrato padrão sem erro).
- **Alternatives considered**:
  - Salvar imagem em Base64 dentro do `SharedPreferences`: inflaria o XML/JSON de preferências síncronas em memória (~100–250 KB por conta), degradando o boot do app.
  - Salvar no `flutter_secure_storage`: reservado exclusivamente a credenciais (regra do projeto verificada no cenário V8 da spec `001`).

## R4 — Avatares ilustrados sem permissão e Retrato Padrão neutro

- **Decision**: Definir enum `AvatarIlustrado` dentro de `features/perfil/domain/retrato_de_perfil.dart` reutilizando ilustrações existentes e licenciadas do app em `app/assets/ilustracoes/`:
  - `memoraAcenando` (`memora_perfil_robo.png` — "Memora acenando")
  - `memoraPensando` (`memora_ajuda_robo.png` — "Memora pensando")
  - `memoraComemorando` (`memora_conclusao_robo.png` — "Memora comemorando")
  - `memoraProtegendo` (`memora_alerta_robo.png` — "Memora com escudo")
  - `casalIdoso` (`casal_idoso.svg` — "Casal acolhedor")
  - `pessoaComCelular` (`pessoa_com_celular.svg` — "Pessoa com celular")
  Quando nenhuma foto nem avatar foi escolhido (`RetratoDePerfil == null`), o componente `RetratoDoPerfil` exibe o **Retrato Padrão neutro**: círculo com borda `MemoraDimensoes.bordaAvatar`, fundo `cores.superficieAlt` / `cores.destaque`, e as iniciais do nome da pessoa (ou ícone de pessoa `Icons.person_outline` se o nome estiver vazio), mantendo contraste WCAG 2.2 AA nos 3 temas.
- **Rationale**:
  - Atende exatamente à clarificação sobre o destaque dedicado à pessoa usuária (`FR-001`): enquanto não houver escolha, não exibe a mascote como se fosse o rosto da pessoa; se a pessoa optar conscientemente por um dos avatares ilustrados da coleção da Memora na escolha (`FR-003`), passa a vê-lo no retrato.
  - Zero dependências de rede, zero assets novos não licenciados (`LICENCAS.md` já cobre todas as ilustrações listadas) e zero permissões de aparelho necessárias.
- **Alternatives considered**:
  - Baixar pacote novo de avatares ilustrados de rede ou assets externos: adicionaria risco de licença/estilo visual inconsistente fora do Design System.

## R5 — Fluxo UX acessível (65+ anos), pré-visualização e permissões negadas

- **Decision**:
  1. **Na `TelaPerfil`**: o cabeçalho atual com `TextoMemora.tituloTela('Meu perfil')` passa a incorporar o bloco de retrato pessoal centralizado ou em destaque limpo (`SecaoFotoPerfil` usando `RetratoDoPerfil` + botões rotulados `BotaoSecundario` / `BotaoTerciario` com ícone + texto, área `>= 48 dp` e espaçamento `>= 8 dp`, substituindo `MemoraPersonagem` do cabeçalho de Perfil).
  2. **Ao tocar em "Colocar foto de perfil" (ou "Trocar foto")**: abre uma `FolhaInferior` (`Escolher foto de perfil`) com:
     - Cabeçalho explicativo integrado (`FR-004`): texto acolhedor visível logo no topo dizendo *"O Memora só vê a foto que você escolher, e ela fica guardada só neste aparelho. Se preferir, escolha um avatar sem usar câmera nem fotos."*
     - Três botões grandes (`OpcaoDeFoto` / `BotaoSecundario` com ícone + texto e `>= 48 dp`): **"Escolher da galeria"**, **"Tirar foto agora"** e **"Escolher avatar da Memora"**.
     - Botão escrito **"Fechar"** (nativo da `FolhaInferior`, evitando depender de arrastar para baixo).
  3. **Ao selecionar foto de Galeria ou Câmera**: processa com feedback visual não bloqueante; se válido, abre `TelaPreVisualizacaoFoto` simples mostrando o círculo em pré-visualização real ("Ficou boa assim?") e exatamente dois botões claros com ícone e texto: **"Usar esta foto"** (`BotaoPrimario`) e **"Escolher outra"** (`BotaoSecundario`).
  4. **Ao escolher "Remover foto"**: exibe `ConfirmacaoMemora` embutida (mesmo padrão da `SecaoIdade`) com dois botões distintos explicando que o perfil voltará ao retrato padrão e a pessoa pode colocar outra quando quiser.
  5. **Ao negar permissão ou selecionar arquivo inválido (`FR-011`)**: exibe quadro de aviso acessível em português claro com opção de abrir configurações do aparelho (via `android_intent_plus` com ação `android.settings.APPLICATION_DETAILS_SETTINGS`, injetável/testável) **ou** escolher um avatar da Memora na hora.
  6. **Bloqueio de concorrência (`FR-012`) & segurança em inatividade**: flag de estado em andamento (`_processando`) ignora toques repetidos enquanto seleção/processamento/remoção ocorre; se o widget for desmontado enquanto o seletor nativo esteve aberto (ex.: bloqueio por inatividade no `FluxoAutenticacao`), verifica `mounted` e o `idDaConta` original antes de gravar ou atualizar UI, descartando qualquer seleção pendente se a sessão tiver mudado.
- **Alternatives considered**:
  - Ícone flutuante de câmera sem texto sobre o avatar: rejeitado pelo Princípio II (baixa visibilidade para idosos) e Princípio III (ícones devem acompanhar texto).
  - Pop-up extra separado antes de cada abertura da galeria/câmera: rejeitado na clarificação `Q3` (`FR-004`) para reduzir cliques desnecessários.
