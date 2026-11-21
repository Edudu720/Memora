# Contrato Compartilhado: Ícones Vetoriais SVG e Capturas Reais dos Guias

**Feature**: `016-ajustes-pos-redesenho` | **Issue**: [#106 (Itens 5, 6 e 13)](https://github.com/Edudu720/Memora/issues/106)  
**Spec**: [spec.md](../spec.md)

---

## 1. Contrato de Ícones Vetoriais (`app/assets/icones_apps/`)

Convenção definida em comum acordo entre `@Du3101` (Item 6) e `@Henrique-Sandrini` (Item 13):

1. **Diretório e declaração**:
   - Todos os ícones vetoriais oficiais dos aplicativos ficam em `app/assets/icones_apps/<chave>.svg`.
   - `app/pubspec.yaml` declara `- assets/icones_apps/` na seção `flutter.assets`.
2. **Nomenclatura estrita**:
   - `<chave>` corresponde exatamente ao campo `ServicoDoCatalogo.chave` e `Guia.chave` (padrão `^[a-z0-9-]+$`).
   - **Entrega desta feature (`@Du3101`, Item 6)**:
     - `app/assets/icones_apps/meu-inss.svg`
     - `app/assets/icones_apps/tiktok.svg`
     - `app/assets/icones_apps/carteira-digital.svg`
     - `app/assets/icones_apps/carteira-de-trabalho.svg`
     - `app/assets/icones_apps/poupatempo.svg`
     - `app/assets/icones_apps/youtube.svg`
     - `app/assets/icones_apps/google-fotos.svg`
   - **Reservados para o Item 13 (`@Henrique-Sandrini`)**: `e-titulo.svg`, `fgts.svg`, `instagram.svg` (a resolução manual atual desses 3 em `IconeDoAplicativo` permanece intacta até ele adicioná-los).
3. **Requisitos técnicos e visuais do SVG**:
   - `viewBox` quadrado (`0 0 48 48`), com bordas e formas autocontidas adaptáveis ao arredondamento de `ClipRRect` do `IconeDoAplicativo`.
   - Somente elementos vetoriais estáticos (`<svg>`, `<rect>`, `<path>`, `<circle>`, `<g>`, `<defs>`, `<linearGradient>` simples); **proibido** `<script>`, `<image>` externo, `<foreignObject>`, referências HTTP/HTTPS ou `<text>` dependente de fonte local do aparelho.
   - Contraste mínimo de **3:1** dos elementos principais do símbolo sobre o fundo da marca, testado nos temas claro, escuro e alto contraste.
4. **Resolução no widget `IconeDoAplicativo` e catálogo de licenças**:
   - Mapa constante explícito `_iconesSvgPorChave` de chave normalizada (`youtube`, `tiktok`, `googlefotos`/`foto`, `meuinss`, `poupatempo`, `carteiradigital`, `carteiradetrabalho`) para o respectivo asset SVG, renderizado via `SvgPicture.asset` com `excludeFromSemantics: true` (em paridade com o Item 13).
   - Registro obrigatório de origem, licença e padronização dos 7 SVGs compartilhados em `app/assets/ilustracoes/LICENCAS.md`.
   - Nenhuma alteração nos 6 PNGs existentes (`whatsapp`, `facebook`, `telegram`, `gov_br`, `serasa`, `correios`).

---

## 2. Contrato de Capturas Reais e Guias (`app/assets/guias/` e `features/aprendizado`)

Complementa [contracts/guias.md](../../004-redesenho-das-telas/contracts/guias.md) para os 7 guias atualizados (`meu-inss`, `tiktok`, `carteira-digital`, `carteira-de-trabalho`, `poupatempo`, `youtube`, `google-fotos`):

1. **Formato e conversão**:
   - Origem exclusiva nos arquivos higienizados de `apps/<Pasta>/` (total de 66 imagens).
   - Saída obrigatoriamente em `app/assets/guias/<chave>/passo_<N>.webp`, codificada em **WebP qualidade >= 92**, sem distorção nem *upscale* além da largura nativa/máxima de `1080 px`.
   - Proibido deixar qualquer `passo_N` ou arquivo antigo/não referenciado em `app/assets/guias/<chave>/`.
2. **Privacidade, segurança e semântica (Princípios I, II e III)**:
   - Zero dados pessoais reais (CPF, nome, rosto, foto de pessoa real, telefone ou e-mail).
   - Telas de autenticação com campo de senha sempre vazio e `temCampoDeSenha: true` no `Passo`.
   - Zero marcações/círculos pintados sobre o arquivo WebP: o destaque (`RegiaoRelativa`) é medido sobre a captura limpa usando grade visual e desenhado pelo Memora.
   - Toda `Passo` possui `descricaoDaCaptura` não vazia e texto com no máximo 2 frases curtas, posição na tela explícita e zero emojis.
3. **Estrutura linear vs. seções (`SecaoDoGuia`)**:
   - Guias com até 7 telas (`tiktok`: 6, `youtube`: 7, `google-fotos`: 4) permanecem em fluxo linear com `passos` entre 3 e 7 itens.
   - Guias com mais de 7 telas (`meu-inss`: 19, `carteira-digital`: 10, `carteira-de-trabalho`: 10, `poupatempo`: 10) adotam `secoes` temáticas com `passos` raiz vazio (`[]`), cada seção contendo `3` a `7` passos e `chave` única dentro do guia.
4. **Registro e teto de tamanho em pacote**:
   - Cada um dos 7 guias tem sua linha atualizada na tabela de `app/assets/guias/CAPTURAS.md` (chave, data real de registro, versão real correspondente e aparelho das capturas).
   - O teto global de `app/assets/guias/` passa de **8 MB para 12 MB** (`12 * 1024 * 1024` bytes) em `catalogo_e_guias_test.dart`, `CAPTURAS.md` e `specs/004-redesenho-das-telas/contracts/guias.md`, comportando os 16 guias com capturas reais (~10,94 MB medidos) sem alterar ativos de outros colaboradores.
5. **Paridade do catálogo (Q2: A)**:
   - A lista de serviços no banco/migrations e em `RepositorioAssistenteSimulado.catalogoDaDemonstracao` permanece inalterada, preservando as declarações `<queries>` do `AndroidManifest.xml` para abertura de apps cotidianos já cadastrados (`youtube`, `tiktok`, `google-fotos`).
