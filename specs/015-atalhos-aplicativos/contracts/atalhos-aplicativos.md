# Contrato de Interfaces: Feature 015 — Atalhos Rápidos para Aplicativos

**Feature**: Atalhos Rápidos para Aplicativos  
**Arquivo**: `contracts/atalhos-aplicativos.md`  
**Escopo**: Contratos de plataforma (MethodChannels), intents de sistema e contratos de interface do usuário (UI).

---

## 1. Contratos de Plataforma (Android ↔ Flutter)

Como esta funcionalidade é 100% executada no cliente mobile sem dependência de rede, os contratos externos consistem nas trocas de mensagens via canais de plataforma (`MethodChannel`).

### 1.1 Canal de Consulta (`memora/aplicativos`)

- **Identificador**: `const String ConsultaDeAplicativosPorCanal.nomeDoCanal = 'memora/aplicativos'`
- **Propósito**: Consulta somente-leitura de pacotes instalados e obtenção de ícones em cache.

#### Método `estaInstalado`
- **Argumento**: `pacote: String` (nome completo do pacote Android; deve satisfazer `^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$`).
- **Retorno**: `bool` (`true` se instalado e visível em `<queries>`, `false` caso contrário ou em erro).
- **Tratamento de Exceções**: Qualquer falha retorna `false`, nunca lança exceção para a camada Flutter.

#### Método `iconeDe`
- **Argumento**: `pacote: String`
- **Retorno**: `Uint8List?` (array de bytes em formato PNG 192×192 com canal alfa ou `null` se não encontrado).

---

### 1.2 Canal de Abertura (`memora/abridor`)

- **Identificador**: `const String AbridorDeAplicativoPorCanal.nomeDoCanal = 'memora/abridor'`
- **Propósito**: Execução segura do lançamento de atividade de outro aplicativo.

#### Método `abrir`
- **Argumento**: `identificadorAndroid: String` (nome do pacote Android).
- **Comportamento Kotlin**:
  ```kotlin
  val intent = contexto.packageManager.getLaunchIntentForPackage(pacote)
  intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
  contexto.startActivity(intent)
  ```
- **Retorno**: `bool` (`true` se a Activity foi disparada com sucesso, `false` se o intent foi nulo ou ocorreu erro de sistema).
- **Pré-condição Inegociável**: O canal só deve ser invocado após a confirmação afirmativa e explícita do usuário no diálogo modal.

---

### 1.3 Contrato de Abertura da Google Play Store (Aplicativos Não Instalados)

- **Propósito**: Direcionamento seguro para a página oficial do aplicativo na loja de aplicativos para idosos que desejam instalar um app recomendado.
- **URI Primária**: `market://details?id={pacote}`
- **URI de Fallback (Web)**: `https://play.google.com/store/apps/details?id={pacote}`
- **Validação de Segurança**: O parâmetro `{pacote}` deve satisfazer `pareceUmPacote` e estar presente na lista cotidiana autorizada pelo servidor (`RepositorioAssistente.catalogo()` com `categoria == CategoriaDoServico.cotidiano && memoraPodeAbrir`). Nunca abrir URLs dinâmicas ou pacotes de serviços sensíveis.

---

## 2. Contratos de Apresentação (UI)

### 2.1 Diálogo de Confirmação de Abertura (`DialogoConfirmacaoAbertura`)

Contrato visual de segurança contra toques involuntários (Princípio II da Constituição):

| Elemento | Conteúdo | Rótulo Semântico / Acessibilidade |
| :--- | :--- | :--- |
| **Título** | *"Abrir o [Nome]?"* | Cabeçalho acessível (`Semantics(header: true)`) |
| **Corpo** | *"Você vai sair do Memora e entrar no [Nome]. Para voltar depois, basta tocar no botão voltar do celular."* | Leitura completa em linguagem simples |
| **Botão Primário** | *"Sim, abrir agora"* | Altura mínima 56 dp, contraste 4.5:1, foco prioritário |
| **Botão Secundário** | *"Não, continuar no Memora"* | Altura mínima 48 dp, cancelamento seguro |

### 2.2 Diálogo de Sugestão de Instalação (`DialogoInstalacaoPlayStore`)

| Elemento | Conteúdo | Ação |
| :--- | :--- | :--- |
| **Título** | *"Instalar o [Nome]?"* | Alerta pedagógico |
| **Corpo** | *"O [Nome] ainda não está no seu celular. Deseja abrir a loja oficial Google Play Store para instalá-lo?"* | Esclarece o destino da navegação |
| **Botão Primário** | *"Ir para a Play Store"* | Dispara intent da Play Store oficial |
| **Botão Secundário** | *"Agora não"* | Fecha diálogo sem ação |

### 2.3 Cartão de Aplicativo (`CartaoAtalhoAplicativo`)

- **Área Mínima de Toque**: Largura 100% da coluna, altura mínima `72 dp`.
- **Feedback Tátil/Visual**: Elevação em repouso de 2 dp, destaque tonal ao toque e foco visual para TalkBack.
- **Hierarquia Visual**:
  - Ícone de 56×56 dp à esquerda;
  - Coluna central com Nome (`AtkinsonHyperlegibleNext` Bold 18 sp) e Descrição (`14 sp`, máximo 2 linhas);
  - Indicador à direita: Ícone de seta para frente / "Abrir" ou Badge "Instalar".
