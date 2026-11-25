# Quickstart de Validação: Avatares no Chat (`022-avatares-no-chat`)

**Pré-requisito**: Estar na branch `feature/022-avatares-no-chat` com alterações implementadas a partir do `tasks.md`.

---

## 1. Portões obrigatórios do Design System e Análise Estática

Executar a partir da raiz do repositório:

```powershell
python specs/002-design-system/ferramentas/validar_tokens.py
python specs/002-design-system/ferramentas/validar_paleta.py
cd app
flutter analyze
```

**Resultado esperado**:
- `validar_tokens.py` → `Nenhum literal encontrado` (`exit 0`).
- `validar_paleta.py` → todos os pares de contraste aprovados (`exit 0`).
- `flutter analyze` → `No issues found!` (`exit 0`).

---

## 2. Testes direcionados da Feature

Executar dentro de `app/`:

```powershell
flutter test test/design_system/balao_de_fala_test.dart test/design_system/icones_e_toque_test.dart test/design_system/memora_distancia_test.dart test/features/perfil/foto_de_perfil_local_test.dart test/features/assistente/memora_no_topo_da_conversa_test.dart test/features/assistente/tela_conversa_test.dart test/features/assistente/avatares_da_conversa_test.dart test/acessibilidade/conversa_acessibilidade_test.dart
```

**Cenários cobertos obrigatoriamente**:
1. Balões da conversa em `100%` e `150%` exibem rosto mini estático da Memora à esquerda (`convite`, `escrevendo…`, resposta em streaming e histórico) e retrato circular da pessoa à direita (`Você`).
2. Apenas a Memora do cabeçalho (`BarraSuperior`) permanece animada/falando; os rostos dos balões têm `reageAoToque: false` e movimento desativado (`disableAnimations: true`).
3. Todos os estados de `RetratoDePerfil` no chat espelham Meu Perfil: foto própria (`FotoPropriaDePerfil` — via bytes ou arquivo local), os 4 avatares (`AvatarIlustrado`), iniciais do nome, ícone neutro quando sem letras e recuo seguro quando o arquivo local é inválido/apagado.
4. Alteração ou remoção da foto/avatar via `ArmazenamentoDeFotoDePerfil` notifica `alteracoes` e atualiza a conversa aberta na mesma sessão; troca de conta ou `esquecerDoAparelho()` descarta imediatamente a imagem anterior.
5. Matriz `4 × 3` (inclusive `320×568` a `200%`) passa com `0` overflows (`>= 175%` oculta os avatares laterais dos balões), três temas com contraste OK e TalkBack sem nós semânticos duplicados para as ilustrações decorativas.

---

## 3. Suíte Completa do Aplicativo

```powershell
cd app
flutter test
```

**Resultado esperado**: 100% dos testes aprovados (sem regressões nem testes pulados indevidamente).

---

## 4. Checklist Visual Comparativo (Dispositivo / Emulador Android)

1. Abrir **Meu Perfil** e selecionar uma foto própria da galeria ou câmera (ou um dos avatares da Memora).
2. Navegar para **Conversar com a Memora** e enviar uma pergunta:
   - Verificar que o balão à direita (`"Você"`) exibe o círculo com exatamente a mesma foto/avatar escolhido no perfil.
   - Verificar que o balão à esquerda (`"Memora"`) exibe o ícone mini estático da Memora, alinhado ao padrão da tela de ajuda (*Passo 2 de 5*), enquanto a Memora do cabeçalho superior move a boca ao responder.
3. Voltar ao **Meu Perfil**, trocar a foto por outro avatar ou remover a foto (voltando às iniciais) e reabrir/retornar à conversa:
   - Confirmar atualização imediata nos balões `"Você"` sem reiniciar o app.
4. Alterar nas configurações do app o tamanho de texto para **Muito grande (`200%`)** e temas **Escuro** e **Alto contraste**, confirmando legibilidade plena sem corte nem sobreposição.
