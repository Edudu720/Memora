# Quickstart e Portões de Verificação — Feature 007

Execute estes portões nesta ordem a partir da raiz `c:\Users\Edu\Documents\Memora` durante a implementação da feature `007-redesenho-visual-profissional`:

---

## 1. Portões Estáticos de Tokens e Contraste (Antes e Depois das Telas)

```powershell
# 1. Zero literais visuais fora de app/lib/design_system/tokens/ + autoteste
python specs/002-design-system/ferramentas/validar_tokens.py
python specs/002-design-system/ferramentas/validar_tokens.py --autoteste

# 2. WCAG 2.2 AA (>= 4.5:1 / >= 3.0:1) e AAA (>= 7.0:1 no Alto Contraste)
#    em todas as 13 combinacoes (3 temas x 6 paletas), incluindo gradientes
python specs/002-design-system/ferramentas/validar_paleta.py
python specs/002-design-system/ferramentas/validar_paleta.py --autoteste
```

---

## 2. Análise Estática e Suíte do Design System

```powershell
cd app
flutter pub get
flutter analyze
flutter test test/design_system/
```

Verificações obrigatórias em `test/design_system/`:
- `contraste_test.dart` (inclui `sobreGradienteHeroi`, `sobreGradienteSaude`, `superficieSutil`, `superficieBarra`, `saudeSuave`/`sucessoTexto`)
- `area_toque_test.dart` (`>= 48×48 dp` e `>= 56 dp` nos botões principais + alvo do botão `"Falar"`)
- `escala_texto_test.dart` (zero `RenderFlex overflow` até `200%`)
- `informacao_nao_e_acao_test.dart` (`Cartao`, `PainelHeroi`, `BadgeDeStatus`, `CaixaDeEtapa` e `LinhaDeLista` sem `aoTocar` continuam não-tocáveis)
- `aviso_compacto_test.dart`, `balao_de_fala_test.dart`, `cabecalho_de_tela_test.dart`, `galeria_completa_test.dart`

---

## 3. Acessibilidade, Voz Segura e Features

```powershell
# Acessibilidade das telas principais (inclui hub_cabe_sem_rolar_test em 360x800)
flutter test test/acessibilidade/

# Regressões por feature + novos testes de ditado por voz (mockado via LeitorDeVoz)
flutter test test/features/casca/
flutter test test/features/inicio/
flutter test test/features/hub/
flutter test test/features/assistente/
flutter test test/features/aprendizado/
flutter test test/features/cuidado/
flutter test test/features/apresentacao/
flutter test test/features/autenticacao/
flutter test test/features/ajuda/
flutter test test/features/configuracoes/
flutter test test/features/perfil/

# Suíte completa sem falhas
flutter test
```

---

## 4. Validação Visual Final (`SC-005`, `SC-006`) & APK Release

```powershell
# Gera capturas completas nos 3 temas (Claro, Escuro, Alto Contraste) para inspeção visual
flutter test test/album/album_de_telas_test.dart

# Compila APK de release atualizado para instalação e conferência no celular físico
flutter build apk --release
```
