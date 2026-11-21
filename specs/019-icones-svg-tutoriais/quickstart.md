# Quickstart de Validação — `019-icones-svg-tutoriais`

```powershell
cd app
flutter pub get
flutter analyze
flutter test test/design_system/icone_do_aplicativo_svg_test.dart
flutter test
cd ..
py specs/002-design-system/ferramentas/validar_tokens.py
```

Resultado esperado:
- `flutter analyze`: zero erros ou avisos;
- `icone_do_aplicativo_svg_test.dart` e toda a suíte `flutter test`: 100% aprovados;
- `validar_tokens.py`: saída `0`.
