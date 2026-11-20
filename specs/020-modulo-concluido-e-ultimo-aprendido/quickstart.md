# Quickstart: Validação da Feature 020

Execute na raiz do repositório em Windows PowerShell 5.1:

## 1. Portão de Tokens do Design System (zero literais)
```powershell
py specs/002-design-system/ferramentas/validar_tokens.py
```

## 2. Análise estática e suíte completa de testes Flutter
```powershell
Set-Location app
if ($?) { flutter analyze }
if ($?) { flutter test }
```

## 3. Execução direcionada durante desenvolvimento
```powershell
Set-Location app
flutter test test/features/aprendizado/progresso_de_aprendizado_test.dart test/features/aprendizado/tela_seletor_de_secao_test.dart test/features/assistente/catalogo_modulo_concluido_test.dart test/features/perfil/tela_perfil_test.dart test/design_system/texto_da_interface_test.dart test/design_system/icones_e_toque_test.dart
```

## 4. Critérios esperados
- `validar_tokens.py`: código de saída `0`, 0 literais reportados.
- `flutter analyze`: `No issues found!`.
- `flutter test`: todos os testes verdes, sem overflow na matriz `4 × 3` (até 200%), contraste e TalkBack validados.
