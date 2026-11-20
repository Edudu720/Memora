# Quickstart e Guia de Validação: Ajustes Pós-Redesenho (`016`)

**Feature**: `016-ajustes-pos-redesenho` | **Branch**: `feature/016-ajustes-pos-redesenho`  
**Pré-requisitos**: Flutter SDK 3.47+ (Dart 3.11+), Python 3.11+ (para auditoria de tokens), trabalhando a partir da raiz do repositório (`c:\Users\Eduardo\Memora`).

---

## 1. Portões Obrigatórios (Issue #106 + Constituição)

Executar após concluir a implementação (e antes de abrir PR para `develop`):

```powershell
# 1) Análise estática e suíte completa do aplicativo
Set-Location app
flutter analyze
flutter test
Set-Location ..

# 2) Auditoria rigorosa de tokens do Design System (zero cores/tamanhos/espaços literais)
py specs/002-design-system/ferramentas/validar_tokens.py

# 3) Verificar ausência de menções residuais ao Wokwi no código e configuração do app
git grep -in "wokwi" -- app/
```

**Resultados esperados**:
- `flutter analyze`: zero erros ou warnings (`No issues found!`).
- `flutter test`: 100% dos testes aprovados, com cobertura das regressões abaixo.
- `validar_tokens.py`: saída `0` (`Nenhum literal encontrado`).
- `git grep -in "wokwi" -- app/`: saída vazia (código de saída `1`, zero ocorrências).

---

## 2. Cenários Focados de Validação Funcional

### Cenário A — Simulação de queda no Dispositivo de Cuidado com ESP32/MQTT (Itens 7 e 8)
```powershell
Set-Location app
flutter test test/features/cuidado/presentation/tela_dispositivo_cuidado_test.dart
Set-Location ..
```
- **O que deve aprovar**:
  - Com o controlador em `ModoOperacaoIot.mqtt` (`ProvedorDeTelemetriaMqtt` inicializado, conectado ou desconectado), tocar em *"Simular queda"* aciona `simularQuedaTeste()` e abre `TelaVerificacaoQueda` com a contagem regressiva.
  - Tocar rapidamente duas vezes não empilha duas telas de verificação.
  - Tocar em *"Estou bem"* fecha a verificação sem disparar emergência.
  - Em `ModoOperacaoIot.simulado`, o comportamento segue idêntico.
- **No aparelho/emulador** *(opcional para conferência visual)*: abrir **Início → Dispositivo de Cuidado**, alternar para **ESP32 (MQTT)** e tocar em **Simular queda**; validar abertura da tela "Você está bem?" e retorno limpo ao confirmar bem-estar.

### Cenário B — Retratos removidos com fallback seguro e melhoria de Meu Perfil (Itens 9 e 10)
```powershell
Set-Location app
flutter test test/features/perfil/
Set-Location ..
```
- **O que deve aprovar**:
  - A folha *"Escolher avatar da Memora"* lista exatamente 4 avatares (`memora_acenando`, `memora_pensando`, `memora_comemorando`, `memora_protegendo`) e não mostra `"Casal acolhedor"` nem `"Pessoa com celular"`.
  - Conta com JSON persistido contendo `"casal_idoso"` ou `"pessoa_com_celular"` no `SharedPreferences` abre `TelaPerfil` e `SecaoFotoPerfil` sem exceção, exibindo o retrato padrão neutro (`semanticaSemFoto`) e permitindo escolher novo avatar ou foto.
  - `TelaPerfil` realiza 0 chamadas à rede ao abrir (`_RepositorioEspiao`), mantém organização em cartões claros, exibe `ultimoModuloConcluido` apenas quando fornecido (preservando a ausência quando nulo), passa sem overflow a `200%` de escala em `320×568` e não contém termos proibidos.

### Cenário C — Guias reais, registro `CAPTURAS.md`, teto 12 MB e ícones SVG (Itens 5 e 6)
```powershell
Set-Location app
flutter test test/features/aprendizado/
Set-Location ..
```
- **O que deve aprovar**:
  - Todos os 7 guias (`meu-inss`, `tiktok`, `carteira-digital`, `carteira-de-trabalho`, `poupatempo`, `youtube`, `google-fotos`) passam nas regras de produção: seções válidas (3–7 passos), `precisaTerEmMaos` em serviços sensíveis, aviso de senha nos passos com `temCampoDeSenha`, `descricaoDaCaptura` não vazia em 100% dos passos, linha em `CAPTURAS.md`, zero arquivos não usados em `assets/guias/` e tamanho total dentro de `12 MB`.
  - Testes de renderização de `IconeDoAplicativo` carregam os 7 novos arquivos em `app/assets/icones_apps/<chave>.svg` sem erro de asset tanto no tema claro quanto no escuro e alto contraste.

### Cenário D — Botão seguro `https://` do site de tutoriais na Ajuda (Item 11)
```powershell
Set-Location app
flutter test test/features/ajuda/tela_ajuda_test.dart
Set-Location ..
```
- **O que deve aprovar**:
  - Sem `MEMORA_URL_SITE_TUTORIAL` (padrão atual) — ou com URL `http://`, com espaço ou `https://golpe@site` — `Ambiente.enderecoOficial` retorna `null` e o botão do site **não aparece** em `TelaAjuda`.
  - Com `abridorSiteTutorial` configurado com URL `https://` válida:
    - O botão aparece abaixo do `CaixaDeEtapa` dos assuntos;
    - Tocar nele exibe o diálogo modal com a URL e exige confirmação (0 chamadas antes de confirmar);
    - *"Agora não"* fecha o diálogo com 0 chamadas a `abrir()`;
    - *"Sim, abrir o site"* chama `abrir()` uma única vez; em caso de falha (`false`), mostra mensagem amigável sem travamento.
- **Execução interativa simulando site publicado em produção**:
  ```powershell
  Set-Location app
  flutter run --dart-define=MEMORA_URL_SITE_TUTORIAL=https://exemplo-oficial-memora.example/tutoriais
  ```
  Abrir **Hub → Preciso de ajuda**, tocar no botão do site oficial e validar o diálogo de confirmação e o comportamento de abertura/cancelamento ( inclusive com tamanho de fonte ampliado nas opções de acessibilidade do aparelho).
