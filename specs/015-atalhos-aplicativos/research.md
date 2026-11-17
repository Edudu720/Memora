# Pesquisa Técnica e Decisões de Arquitetura: Feature 015

**Feature**: Atalhos Rápidos para Aplicativos  
**Data**: 2026-11-16  
**Status**: Concluído

---

## 1. Viabilidade Técnica: Exibir Apenas Aplicativos Instalados no Dispositivo

### 1.1 O Desafio no Android Moderno (Android 11 / API 30+)
A partir do Android 11, o Google implementou a política restritiva de **Package Visibility** (Visibilidade de Pacotes).
Um aplicativo comum não consegue mais invocar `PackageManager.getInstalledPackages()` ou `getInstalledApplications()` para inspecionar todos os aplicativos arbitrários instalados no smartphone do usuário.

Existem duas abordagens possíveis:

| Abordagem | Mecanismo | Viabilidade Técnica | Conformidade com Google Play e Constituição |
| :--- | :--- | :--- | :--- |
| **Abordagem A: Lista Branca via `<queries>` (Recomendada)** | Declarar cada aplicativo suportado na tag `<queries>` do `AndroidManifest.xml` e verificar instalação com `packageManager.getApplicationInfo()` ou `getLaunchIntentForPackage()`. | **100% Viável e Imediata**. Nenhuma nova permissão necessária. | **Total conformidade**. Respeita o Princípio I (Privacidade e Segurança) e não gera rejeição na loja. |
| **Abordagem B: Varredura Completa com `QUERY_ALL_PACKAGES`** | Declarar `<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />`. | Funciona tecnicamente no dispositivo. | **PROIBIDA / INVIÁVEL EM PRODUÇÃO**. As políticas do Google Play restringem esta permissão estritamente a launchers substitutos de tela inicial (home apps), gerenciadores de arquivos e antivírus. Aplicativos assistivos são **rejeitados no upload** no Play Console. Além disso, viola o Princípio I da Constituição Memora. |

### 1.2 Situação Atual no Código do Memora
O `AndroidManifest.xml` do Memora já contém as declarações explícitas necessárias em `<queries>` (linhas 34 a 41):
```xml
<queries>
    <package android:name="com.whatsapp"/>
    <package android:name="com.facebook.katana"/>
    <package android:name="com.instagram.android"/>
    <package android:name="com.google.android.youtube"/>
    <package android:name="com.google.android.apps.photos"/>
    <package android:name="org.telegram.messenger"/>
    <package android:name="com.zhiliaoapp.musically"/>
    ...
</queries>
```

Além disso, o Memora já possui:
1. `CanalDeAplicativos.kt` / `ConsultaDeAplicativos`: Método `estaInstalado(pacote)` implementado e testado.
2. `CanalDoAbridor.kt` / `AbridorDeAplicativo`: Método `abrir(pacote)` usando `context.packageManager.getLaunchIntentForPackage(pacote)` com `Intent.FLAG_ACTIVITY_NEW_TASK`.

### 1.3 Decisão de Implementação
- **Decisão**: A tela apresenta diretamente todos os 7 aplicativos comuns cadastrados no catálogo seguro, sem filtros ou ocultação de itens não instalados.
- **Comportamento**: Cada cartão exibe o nome, ícone e status de instalação (`Instalado` ou `Disponível para baixar`).
- **Ações**:
  - Se instalado: toca para abrir com diálogo de confirmação.
  - Se não instalado: toca para abrir a página oficial na Google Play Store.

---

## 2. Exclusão de Serviços Sociais e Governamentais

### 2.1 Contexto
Na Feature 006 e em etapas anteriores, o Memora introduziu guias para serviços como Gov.br, Meu INSS, Carteira de Trabalho Digital, Poupatempo e Serasa.

### 2.2 Por que NÃO incluir serviços sociais nesta tela de atalhos diretos?
- **Golpes e Engenharia Social**: Aplicativos de serviços públicos e governamentais lidam com dados altamente sensíveis (CPF, senhas gov.br, benefícios previdenciários, dados bancários). Um clique acidental ou redirecionamento direto sem o contexto protetivo pode expor a pessoa idosa a riscos ou confusão.
- **Foco Pedagógico**: Serviços sociais exigem tutoriais e explicações passo a passo (já oferecidos na Feature 006) para ensinar como agendar, emitir certidões e evitar fraudes.
- **Propósito da Feature 015**: Prover atalhos cotidianos para ferramentas do dia a dia (conversar com a família, assistir a vídeos, ver fotos de netos, navegar em redes).
- **Decisão**: Exclusão estrita e total de serviços governamentais, bancários e de saúde desta tela.

---

## 3. Catálogo Seguro de Aplicativos Comuns

| Chave | Nome Exibido | Pacote Android | Categoria | Descrição Curta |
| :--- | :--- | :--- | :--- | :--- |
| `whatsapp` | WhatsApp | `com.whatsapp` | Comunicação | Conversas, áudios e chamadas de vídeo com familiares |
| `youtube` | YouTube | `com.google.android.youtube` | Mídia / Vídeo | Vídeos, músicas, receitas e programas favoritos |
| `instagram` | Instagram | `com.instagram.android` | Redes Sociais | Fotos, vídeos e histórias de amigos e criadores |
| `facebook` | Facebook | `com.facebook.katana` | Redes Sociais | Publicações, fotos e grupos de amigos e parentes |
| `google_fotos` | Google Fotos | `com.google.android.apps.photos` | Fotos e Memórias | Todas as suas fotos, vídeos e lembranças organizadas |
| `telegram` | Telegram | `org.telegram.messenger` | Comunicação | Mensagens rápidas, canais informativos e grupos |
| `tiktok` | TikTok | `com.zhiliaoapp.musically` | Vídeos Curtos | Vídeos divertidos, dicas do dia a dia e receitas rápidas |

---

## 4. Segurança na Abertura Externa (Princípio II da Constituição)

### 4.1 Ameaça Analisada (Threat Modeling)
- **Ameaça**: Abertura involuntária de outro aplicativo por toque acidental do idoso com tremores ou perda de destreza motora.
- **Impacto**: O idoso é subitamente retirado do Memora, o celular muda de contexto visual sem aviso prévio, gerando pânico, sensação de descontrole e desorientação ("O que aconteceu com meu celular?").
- **Mitigação**: Diálogo modal bloqueante com confirmação explícita de duas opções claras e inequívocas:
  1. *"Sim, abrir agora"* (botão primário, ação deliberada).
  2. *"Não, continuar no Memora"* (botão secundário de cancelamento sem consequências).

### 4.2 Falha na Abertura do Aplicativo
- Caso o sistema Android falhe ao lançar o pacote (ex.: app travado, desativado pelo usuário no sistema), o retorno booleano `false` do `AbridorDeAplicativo` deve disparar uma mensagem compreensível em `SnackBar` acessível: *"Não foi possível abrir o [App]. Verifique se o aplicativo está instalado e atualizado."*

---

## 5. Padrão de Arquitetura de Software (Clean Architecture + Feature-First)

A implementação no Flutter seguirá a estrutura modular do Memora:
```text
lib/features/atalhos_aplicativos/
├── data/
│   ├── catalogo_aplicativos_comuns.dart   # Definição estática e imutável dos 7 apps
│   └── repositorio_atalhos_aplicativos.dart # Consulta estado e monta entidades
├── domain/
│   ├── entidades/
│   │   └── atalho_aplicativo.dart         # Modelo com nome, pacote, status
│   └── repositorios/
│       └── i_repositorio_atalhos.dart     # Interface abstrata para testes
└── presentation/
    ├── controllers/
    │   └── atalhos_aplicativos_controller.dart # Gerencia estado (carregando, lista, filtro)
    └── widgets/
        ├── tela_atalhos_aplicativos.dart   # Tela principal
        ├── cartao_atalho_aplicativo.dart   # Cartão com ícone, descrição e botão
        └── dialogo_confirmacao_abertura.dart # Confirmação segura antes de abrir
```

---

## 6. Conclusão

A feature é perfeitamente exequível, segura e elegante.
Ao restringir a lista aos 7 aplicativos comuns já homologados e declarados no `<queries>`, garantimos compatibilidade total com o Android 11+, respeito irrevogável à privacidade dos idosos e segurança contra toques involuntários.
