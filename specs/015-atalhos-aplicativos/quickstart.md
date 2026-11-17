# Guia de Validação Rápida: Feature 015 — Atalhos Rápidos para Aplicativos

**Feature**: Atalhos Rápidos para Aplicativos  
**Arquivo**: `quickstart.md`  
**Escopo**: Procedimentos de teste automatizados e manuais para validação ponta a ponta da funcionalidade.

---

## 1. Pré-requisitos

1. Flutter SDK instalado (`>= 3.47.7` conforme alinhamento de projeto).
2. Dependências do app atualizadas (`cd app && flutter pub get`).
3. Dispositivo Android físico ou emulador com API 30+ (Android 11 ou superior).

---

## 2. Cenários de Teste Automatizados (Widget Tests)

Os testes são executados com `ConsultaDeAplicativosSimulada` e `AbridorDeAplicativoSimulado`, garantindo determinismo sem depender de apps instalados na máquina do desenvolvedor ou na esteira de CI.

### Cenário 1: Exibição Padrão Apenas de Aplicativos Instalados
- **Configuração**: Simular que apenas `com.whatsapp` e `com.google.android.youtube` estão instalados.
- **Ação**: Montar a `TelaAtalhosAplicativos` e aguardar estabilização dos microtasks.
- **Resultado Esperado**:
  - Exibe exatamente 2 cartões de aplicativo: "WhatsApp" e "YouTube".
  - Não exibe cartões para Instagram, Facebook, TikTok, etc.
  - O filtro "Apenas instalados" está selecionado por padrão.

### Cenário 2: Confirmação de Abertura Preventiva
- **Configuração**: WhatsApp instalado.
- **Ação**: Tocar no cartão do "WhatsApp".
- **Resultado Esperado**:
  - Exibe o diálogo com título *"Abrir o WhatsApp?"*.
  - O abridor **não** foi acionado ainda.
  - Ao tocar no botão *"Sim, abrir agora"*, o diálogo fecha e `AbridorDeAplicativoSimulado.abertos` contém `'com.whatsapp'`.

### Cenário 3: Cancelamento de Abertura Involuntária
- **Configuração**: WhatsApp instalado.
- **Ação**: Tocar no cartão do "WhatsApp", seguido de toque no botão *"Não, continuar no Memora"*.
- **Resultado Esperado**:
  - Diálogo fecha.
  - `AbridorDeAplicativoSimulado.abertos` permanece vazio.
  - Usuário permanece na tela de atalhos.

### Cenário 4: Alternância para Exibir Todos os Recomendados
- **Configuração**: Apenas WhatsApp instalado.
- **Ação**: Tocar no alternador/filtro *"Mostrar recomendados"*.
- **Resultado Esperado**:
  - A lista expande para conter todos os 7 aplicativos comuns do catálogo.
  - WhatsApp aparece com indicador *"Instalado"*.
  - Os demais (Instagram, Facebook, etc.) aparecem com indicador *"Disponível na Play Store"*.

### Cenário 5: Estado Vazio quando Nenhum Aplicativo está Instalado
- **Configuração**: Nenhum pacote instalado (`instalados: {}`).
- **Ação**: Carregar a tela no modo padrão ("Apenas instalados").
- **Resultado Esperado**:
  - Exibe estado vazio acolhedor: *"Nenhum destes aplicativos foi encontrado no seu aparelho"*.
  - Exibe botão para ver os aplicativos recomendados.

---

## 3. Comandos de Execução dos Testes

Para rodar todos os testes automatizados da feature:

```bash
cd app
flutter test test/features/atalhos_aplicativos/
```

Para rodar a verificação de conformidade de acessibilidade e texto:
```bash
flutter test test/features/atalhos_aplicativos/tela_atalhos_aplicativos_test.dart
```

---

## 4. Roteiro de Teste Manual no Aparelho Real

1. Iniciar o Memora no dispositivo Android (`flutter run`).
2. No Início ou Hub, tocar em **"Meus Aplicativos"**.
3. Verificar se os aplicativos exibidos correspondem exatamente aos que você possui instalados no celular.
4. Tocar no WhatsApp:
   - Notar a aparição da caixa de confirmação;
   - Tocar em *"Não, continuar no Memora"* e verificar que nada abriu;
   - Tocar novamente no WhatsApp e tocar em *"Sim, abrir agora"*;
   - Observar o WhatsApp abrindo imediatamente;
   - Pressionar o botão voltar do Android e retornar com segurança ao Memora.
5. Alternar o filtro para *"Mostrar todos os recomendados"*;
6. Tocar em um aplicativo não instalado (ex.: TikTok se não o tiver):
   - Verificar a caixa *"Instalar o TikTok?"*;
   - Tocar em *"Ir para a Play Store"* e verificar a abertura da loja oficial na página do app.
