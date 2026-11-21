# Modelo de Dados e Estado: Ajustes Pós-Redesenho (`016`)

**Feature**: `016-ajustes-pos-redesenho` | **Branch**: `feature/016-ajustes-pos-redesenho` | **Data**: 2026-11-19  
**Referências**: [spec.md](spec.md) · [research.md](research.md)

---

## 1. Dispositivo de Cuidado e Simulação de Queda (`features/cuidado`)

### Entidades e Estado do Controlador
- **`DispositivoCuidado`**: preserva `id`, `nome`, `modoOperacao` (`ModoOperacaoIot.mqtt` | `ModoOperacaoIot.simulado`), `statusConexao`, `brokerHost`, `topicoBase`, `ultimaTelemetria`.
  - **Atualização textual/doc**: comentários que mencionavam `Wokwi` em `ModoOperacaoIot`, `ProvedorDeTelemetria` e `ControladorDispositivoCuidado` passam a referenciar exclusivamente o ESP32 físico via MQTT e o simulador local.
- **`ControladorDispositivoCuidado`**:
  - Mantém `_quedaAtiva: EventoQueda?` e `_provedorAtual: ProvedorDeTelemetria`.
  - **Regra de transição `simularQuedaTeste()`**:
    1. Se `_quedaAtiva != null`, retorna imediatamente (guarda anti-reentrância para duplo toque).
    2. Se `_provedorAtual is ProvedorDeTelemetriaSimulado`, chama `(_provedorAtual as ProvedorDeTelemetriaSimulado).simularQueda()` (emite evento pelo stream e atualiza `_quedaAtiva`).
    3. Caso contrário (ex.: `ProvedorDeTelemetriaMqtt`, conectado ou desconectado), cria `EventoQueda.novo(bpm: _dispositivo.ultimaTelemetria?.bpm ?? 72, aceleracao: 2.8)`, atribui `_quedaAtiva` e chama `notifyListeners()`.
- **Estado da UI (`TelaDispositivoCuidado`)**:
  - Adiciona trava `_verificacaoQuedaAberta: bool` ao empilhar `TelaVerificacaoQueda` com `Navigator.push(...).whenComplete(() => _verificacaoQuedaAberta = false)` para evitar empilhamento múltiplo se houver duas notificações sequenciais.
  - Cancelar tocando *"Estou bem"* chama `ControladorVerificacaoQueda.confirmarEstouBem()` -> `provedor.enviarComandoCessarAlarme()` (seguro como *no-op* quando o MQTT está desconectado) e fecha a verificação sem acionar `DispararSocorroEmergencia`.

---

## 2. Retrato de Perfil e Fallback Seguro (`features/perfil`)

### `AvatarIlustrado` (Catálogo fechado de avatares selecionáveis)
Permanece restrito às **4 ilustrações oficiais da Memora**:
1. `memoraAcenando` (`chave: 'memora_acenando'`)
2. `memoraPensando` (`chave: 'memora_pensando'`)
3. `memoraComemorando` (`chave: 'memora_comemorando'`)
4. `memoraProtegendo` (`chave: 'memora_protegendo'`)

- **Removidos de `AvatarIlustrado`**: `casalIdoso` (`'casal_idoso'`) e `pessoaComCelular` (`'pessoa_com_celular'`).
- **Preservados no Design System**: `Ilustracao.casalIdoso` e `Ilustracao.pessoaComCelular` continuam intactos para telas alheias (`TelaConta`, `AssuntoDeAjuda`).

### Regras de Leitura, Fallback e Transição de Estado (`FotoDePerfilLocal` + `RetratoDoPerfil`)
- Payload JSON salvo no `SharedPreferences` sob `memora.foto_perfil.v1.<contaSegura>`:
  - `{"tipo": "avatar", "avatar": "<chave>"}` ou `{"tipo": "foto", "arquivo": "<nome>.jpg", "atualizadaEm": "<ISO-8601>"}`.
- **Invariante de compatibilidade retroativa**:
  - `AvatarIlustrado.porChave('casal_idoso')` -> `null`
  - `AvatarIlustrado.porChave('pessoa_com_celular')` -> `null`
  - `FotoDePerfilLocal.ler(idDaConta)` ao receber `null` de `porChave` retorna `null` sem lançar exceção e sem corromper outras chaves da conta.
  - `RetratoDoPerfil` ao receber `retrato == null` exibe `_padraoNeutro` (iniciais do nome da pessoa ou ícone humano neutro) com semântica `TextosPerfil.semanticaSemFoto`, mantendo a ação de escolher outro retrato ativo liberada.

---

## 3. Guias Passo a Passo, Capturas e Ícones Vetoriais (`features/aprendizado`, `design_system`)

### Mapeamento dos 7 Guias Atualizados (66 capturas reais de `apps/`)

| Chave do guia (`Guia.chave`) | Pasta origem (`apps/`) | Qtd. capturas | Estrutura (`Guia`) | Sensível (`precisaTerEmMaos` + senha vazia?) | Arquivo SVG do ícone |
|---|---|---|---|---|---|
| `meu-inss` | `apps/INSS/` | 19 | **Seções (`SecaoDoGuia`)** — 4 seções (3–7 passos cada) | Sim (CPF + senha Gov.br) | `assets/icones_apps/meu-inss.svg` |
| `tiktok` | `apps/TikTok/` | 6 | **Linear (`passos`)** — 6 passos | Não | `assets/icones_apps/tiktok.svg` |
| `carteira-digital` | `apps/CNH/` | 10 | **Seções (`SecaoDoGuia`)** — 2 seções (3–7 passos cada) | Sim (CPF + senha Gov.br) | `assets/icones_apps/carteira-digital.svg` |
| `carteira-de-trabalho` | `apps/CLT/` | 10 | **Seções (`SecaoDoGuia`)** — 2 seções (3–7 passos cada) | Sim (CPF + senha Gov.br) | `assets/icones_apps/carteira-de-trabalho.svg` |
| `poupatempo` | `apps/Poupatempo/` | 10 | **Seções (`SecaoDoGuia`)** — 2 seções (3–7 passos cada) | Sim (CPF + senha gov.br/Poupatempo; passo de login vazio) | `assets/icones_apps/poupatempo.svg` |
| `youtube` | `apps/YouTube/` | 7 | **Linear (`passos`)** — 7 passos | Não | `assets/icones_apps/youtube.svg` |
| `google-fotos` | `apps/GoogleFotos/` | 4 | **Linear (`passos`)** — 4 passos | Não | `assets/icones_apps/google-fotos.svg` |

### Invariantes de `CapturaDoGuia`, `Guia` e Orçamento
- Cada captura ganha constante `static const CapturaDoGuia` nomeada (`meuInss1..19`, `tiktok1..6`, `carteiraDigital1..10`, `carteiraDeTrabalho1..10`, `poupatempo1..10`, `youtube1..7`, `googleFotos1..4`) apontando para `assets/guias/<chave>/passo_<N>.webp`.
- Guias com `secoes` preenchido mantêm `passos` vazio (`const <Passo>[]`); cada `SecaoDoGuia` possui `chave` única dentro do guia, `titulo` não vazio, `subtitulo`, `icone` e entre `Guia.minimoDePassos` (3) e `Guia.maximoDePassos` (7) passos.
- Cada `Passo` traz `RegiaoRelativa` dentro de `[0, 1]` alinhada à imagem limpa, `texto` claro (<= 2 frases curtas, posição na tela, zero emojis) e `descricaoDaCaptura` não vazia; telas com campo de senha têm `temCampoDeSenha: true` e campo em branco na imagem.
- **`CAPTURAS.md`**: todas as 7 linhas atualizadas com data real, versão do app e origem/aparelho das capturas sanitizadas; orçamento total de `app/assets/guias/` ajustado para **`12 MB`** (`12 * 1024 * 1024` bytes) com zero arquivos não referenciados nas pastas.
- **`IconeDoAplicativo`**: mapa estático constante `_iconesSvgPorChave` mapeando as 7 chaves para `assets/icones_apps/<chave>.svg`, carregados por `SvgPicture.asset`, preservando os PNGs existentes e os 3 ramos de `@Henrique-Sandrini` (`instagram`, `e-titulo`, `fgts`).

---

## 4. Tela Meu Perfil (`features/perfil/presentation/tela_perfil.dart`)

### Campos e Estrutura da Tela
- **Entradas da tela**:
  - `nome: String` (exibido uma única vez em `TelaPerfil.chaveNome` para manter unicidade semântica/teste)
  - `canal: Future<String?>` (lido localmente do último acesso)
  - `progresso: ProgressoDeAprendizado?` (leitura estritamente local; nunca envia à rede)
  - `dataDeNascimento: ArmazenamentoDaDataDeNascimento?` (estritamente local)
  - `fotoDePerfil: ArmazenamentoDeFotoDePerfil?` (estritamente local)
  - `ultimoModuloConcluido: String?` *(novo parâmetro opcional reservado para integração direta com o Item 14 de `@Henrique-Sandrini`)*
- **Organização em cartões preservando todas as chaves existentes**:
  1. Cabeçalho `TituloComSos(titulo: TextosPerfil.tituloPerfil)`
  2. Cartão **"Seu retrato"**: envolve `SecaoFotoPerfil` (com `TelaPerfil.chaveDesenho`) ou `RetratoDoPerfil`
  3. Cartão **"Sua conta"**: `ListaInformacao` com `TelaPerfil.chaveNome` e `TelaPerfil.chaveCanal`
  4. Cartão **"Seu aprendizado"** (`TelaPerfil.chaveSecaoAprendizado`): `ListaInformacao` com `TelaPerfil.chaveMaisAprendido` e, **exclusivamente quando `ultimoModuloConcluido` não for nulo/vazio**, linha informativa `TelaPerfil.chaveUltimoModulo` (evita "porta vazia" enquanto o Item 14 não estiver ligado)
  5. `SecaoIdade` (cartão próprio de preferência local)
- **Resolução otimizada de nome de guia**: índice estático em memória `Map<String, String>` (`chave -> nomeExibido`), com descarte de resposta assíncrona se `idDaConta` mudou durante a leitura.

---

## 5. Botão Seguro do Site Oficial na Ajuda (`services/ambiente`, `features/ajuda`)

### `Ambiente` (`app/lib/services/ambiente/ambiente.dart`)
- Novo campo imutável: `final String? urlSiteTutorial;`
- Populado em `Ambiente.doAmbiente()` a partir de `String.fromEnvironment('MEMORA_URL_SITE_TUTORIAL')` após passar obrigatoriamente por `Ambiente.enderecoOficial(...)`:
  - Aceita apenas `https://`;
  - Exige `host.isNotEmpty`;
  - Rejeita `userInfo.isNotEmpty` e espaços em branco;
  - Qualquer outro valor (incluindo vazio por padrão antes do deploy) resolve para `null`.

### `AbridorDeSiteTutorial` (`app/lib/features/ajuda/data/abridor_site_tutorial.dart`)
- **`abstract interface class AbridorDeSiteTutorial`**:
  - `String get endereco;` (sempre uma URL já validada)
  - `Future<bool> abrir();` (sem parâmetros livres de entrada)
  - `static AbridorDeSiteTutorial? doAmbiente(Ambiente ambiente)` -> retorna `null` se `Ambiente.enderecoOficial(ambiente.urlSiteTutorial) == null`.
- **`AbridorDeSiteTutorialUrlLauncher`**: usa `url_launcher` com `LaunchMode.externalApplication` após revalidar `Ambiente.enderecoOficial(endereco)`, capturando exceções e retornando `false` em falha.
- **`AbridorDeSiteTutorialSimulado`**: implementa contador/registro `abertos` e flag `falharNoProximo` para testes determinísticos sem navegador.

### Fluxo de Estados na `TelaAjuda`
- Se `abridorSiteTutorial == null`: o cartão do site **não é construído** na árvore (botão oculto até a configuração de URL `https://`).
- Se `abridorSiteTutorial != null`:
  1. Exibe `_CartaoSiteTutorial` abaixo do único `CaixaDeEtapa` dos assuntos, com botão `Key('ajuda.site_tutorial')`;
  2. Ao tocar no botão -> **não** chama `abrir()`; abre diálogo modal rolável (`AlertDialog(scrollable: true)`) mostrando o endereço oficial e explicando em até 2 frases que a pessoa sairá do Memora para o navegador oficial;
  3. Ao cancelar (`Key('ajuda.site_tutorial.cancelar')`) -> fecha o diálogo e mantém estado inalterado;
  4. Ao confirmar (`Key('ajuda.site_tutorial.confirmar')`) -> fecha o diálogo e invoca `abridor.abrir()`. Se retornar `false`, exibe aviso amigável (`Key('ajuda.site_tutorial.erro')`) na tela sem encerrar nem travar.
