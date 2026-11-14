# Contrato de Padronização Tela a Tela — Feature 007

Cada módulo e tela do Memora segue os templates estruturais definidos abaixo a partir das 6 imagens de `Memora-Desing-Ideias/`, das decisões do `/speckit-clarify` e da Constituição.

---

## 1. Casca Principal e Navegação (`features/casca/`, `inicio/`, `hub/`)

| Tela / Arquivo | Composição Atual (Problema) | Novo Padrão Unificado | Chaves / Invariantes Preservados |
| :--- | :--- | :--- | :--- |
| `CascaInterna` (`casca_interna.dart`) | Barra inferior cinza chapada `#D8D8D8`, fundo `#F8F8F8` | Canvas `cores.fundo` (`#F4F6FA`) + `NavegacaoInferior` branca elevada com indicador e pílula ativa mantendo **exatamente os 3 destinos fixos (`Ajustes`, `Início`, `Meu perfil`)** | `CascaInterna.chaveDaBarra`, `DestinoDaCasca` intacto, ícone + texto sempre visíveis |
| `TelaInicio` (`tela_inicio.dart`) | Pilha de caixas bordadas `#6B6B6B` e blocos sequenciais pesados | Saudação `"Oi, [Nome]!"` + `ExpressaoDaMemora.mini` -> Balão acolhedor -> `CartaoHeroi` `"Conversar com a Memora"` com pista explícita `"Começar conversa"` -> Grade `2x2` responsiva (`2->1` col) de `TileAcaoRapida` (`Meus aplicativos`, `Serviços sociais`, `Cuidado`, `Ajuda`) -> atalho para histórico | `inicio_ocupa_a_altura_test.dart`, alvos `>= 48 dp`, escala até `200%` |
| `TelaHub` (`tela_hub.dart`) | Cartões de porta bordados com SVGs mistos | `CartaoHeroi` de entrada + Grade `2x2` limpa com badges vetoriais/robô e pista de ação + ações secundárias | **`hub_cabe_sem_rolar_test.dart` MUST passar em `360×800 @ 1.0x`** |

---

## 2. Assistente & Aprendizado (`features/assistente/`, `features/aprendizado/`)

| Tela / Arquivo | Novo Padrão Unificado (Base: `fkhvix`, `design-1`, `design-2`, `covid-19`) | Chaves / Invariantes Preservados |
| :--- | :--- | :--- |
| `TelaConversa` (`tela_conversa.dart`) | **1) Se `precisaDoAceite == true`**: exibe obrigatoriamente `_ExplicacaoDoAceite` com o novo visual limpo sem bordas pesadas (Emenda 1 ao Princípio I). **2) Após aceite, antes da 1ª mensagem**: cabeçalho limpo com `ExpressaoDaMemora.mini` + `AvisoCompacto` no topo + recepção com `ExpressaoDaMemora.falando` + grade `2x2` responsiva de sugestões rápidas. **3) Conversa ativa**: `AvisoCompacto` em pílula compacta no topo (expansível ao toque, nunca dispensável), balões sem borda pesada (`mini` à esquerda, `superficieSutil` à direita) e barra inferior elevada (`superficieBarra`) com `CampoTexto` + botão pílula `"Perguntar"` + botão de **ditado por voz** (`"Falar"` / `"Parar"`, `>= 48 dp`, ícone + texto, explicação prévia antes da permissão de microfone, preenchendo rascunho sem envio automático). | `chaveAceite`, `chaveAceitar`, `chaveRecusarAceite`, `chaveCampo`, `chaveEnviar`, `conversa_acessibilidade_test.dart`, `sem_campo_de_segredo_test.dart`, escrita gradual preservada |
| `TelaCatalogo` (`tela_catalogo.dart`) | Campo de busca limpo + `ChipFiltro` segmentado (`Apps do celular` \| `Serviços sociais`) + cartões brancos com badge da logo oficial, `BadgeDeStatus` `"✓ Eu te ensino e posso abrir"` (não clicável) e ações explícitas de ensinar/abrir | `catalogo_acessibilidade_test.dart`, confirmação ao abrir app externo |
| `TelaRegistro` (`tela_registro.dart`) | Lista de conversas anteriores agrupada em cartões brancos com `LinhaDeLista`, sem bordas `#6B6B6B` | `registro_acessibilidade_test.dart` |
| `TelaSeletorDeSecao` (`tela_seletor_de_secao.dart`) | Cabeçalho do aplicativo/serviço com `BadgeDeStatus` de progresso + lista de módulos em `LinhaDeLista` com badges numéricos tonais + `ExpressaoDaMemora.dica` | Progresso de aprendizado preservado |
| `TelaPassoAPasso` (`tela_passo_a_passo.dart`) | `IndicadorDePasso` em barra limpa + `PassoIlustrado` com captura anotada da feature 006 em cartão elevado + conclusão com `ExpressaoDaMemora.comemorando` + rodapé em `superficieBarra` (`"Anterior"` / `"Próximo"`) | `passo_ilustrado_test.dart`, ampliação até `200%` |

---

## 3. Cuidado & Saúde IoT (`features/cuidado/`)

| Tela / Widget | Novo Padrão Unificado (Base: `7fe4db...webp` + `covid-19...avif`) | Chaves / Invariantes Preservados |
| :--- | :--- | :--- |
| `TelaDispositivoCuidado` | **`PainelHeroi` informativo em Gradiente de Saúde (não clicável)** com `BadgeDeStatus` do vínculo, leitura tabular grande de BPM e resumo de movimento; abaixo, **grade `2x2` de vitais e ações explícitas** (`Medir BPM`, `Movimento`, `Contato de Emergência`, `Histórico Recente`); detalhes técnicos de MQTT movidos para seção colapsável `"Detalhes técnicos do aparelho"` | Chaves existentes do controlador, emergência e vitais preservadas |
| `MedidorBpm` & `IndicadorMovimento` | Sem `Border.all(color: cores.borda)` no Claro/Escuro (revertendo no Alto Contraste); `Cartao` limpo com badge tonal `saudeSuave` e algarismos tabulares | Leituras `-- BPM` e alertas semânticos preservados |
| `TelaVerificacaoQueda` & `CronometroRegressivoQueda` | Layout centrado de alto impacto (`covid-19...avif` + `ExpressaoDaMemora.preocupada`), contador regressivo em destaque e botões em pílula grandes (`>= 56 dp`, `"Estou bem"` / `"Pedir ajuda agora"`) | Regressiva, emergência e contraste `>= 4.5:1` / `7.0:1` |

---

## 4. Onboarding, Autenticação, Ajuda, Configurações e Perfil

| Módulo / Telas | Novo Padrão Unificado (Base: `design-1`, `design-2`, `ou3uja`) | Chaves / Invariantes Preservados |
| :--- | :--- | :--- |
| `TelaBoasVindas` & `FluxoApresentacao` | Composição editorial generosa com `ExpressaoDaMemora.neutra` / `.dica`, indicadores de página em pílula e botão primário ancorado no rodapé | `tela_boas_vindas_test.dart`, cabe em `320×568` e `360×800` |
| `TelaLogin`, `TelaCadastro`, `TelaRecuperacao`, `TelaConfirmarCanal`, `TelaDeVolta`, `TelaEntregaDoAparelho`, `TelaPrimeiraEntrada` | Cartões brancos limpos sobre canvas suave com `CaixaDeEtapa` evoluída (sem blocos cinzas `#D8D8D8`), instrução literal acima de cada campo e avisos de senha/segurança claros (`AvisoAntigolpe`, `RegrasDeSenha`, `SaidaComConfirmacao`) | `fluxo_autenticacao_test.dart`, `tela_login_test.dart`, `tela_cadastro_test.dart`, `tela_recuperacao_test.dart`, `campo_senha_ampliacao_test.dart` |
| `TelaAjuda`, `TelaAssunto`, `AjudaGuiadaDaConversa` | Banner acolhedor com `ExpressaoDaMemora.falando` + lista limpa (`LinhaDeLista`) sem caixas aninhadas + leitura limpa | Navegação de ajuda preservada |
| `TelaConfiguracoes`, `TelaConta`, `TelaPrivacidade`, `TelaAparencia`, `TelaPerfil`, `TelaDataDeNascimento`, `SecaoIdade` | Seções tipográficas claras com `Cartao` agrupando `LinhaDeLista` + `ExpressaoDaMemora.neutra` no Perfil + preview atualizado de `TelaAparencia` nos 3 temas × 6 paletas | `configuracoes_test.dart`, `aparencia_test.dart`, `tela_aparencia_test.dart`, `tela_perfil_test.dart`, `data_de_nascimento_test.dart`, `fluxo_sair_confirma_test.dart` |
| `GaleriaMemora` & `album_de_telas_test.dart` | Exibe todos os componentes evoluídos e novos (`PainelHeroi`, `CartaoHeroi`, `TileAcaoRapida`, `ChipFiltro`, `BadgeDeStatus`, `LinhaDeLista`) + todas as **6 expressões PNG do robô** | `galeria_completa_test.dart`, `galeria_test.dart`, `album_de_telas_test.dart` |
