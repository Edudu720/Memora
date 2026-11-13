# Quickstart & Validação: Guias de Serviços Sociais

**Feature**: `006-guias-servicos-sociais` | **Data**: 2026-11-13

---

## Pré-requisitos
- Python 3.11+ com `Pillow` (`pip install pillow`) para execução do pipeline de censura por Blur.
- Flutter 3.41+ / Dart 3.11+ configurado no ambiente Windows.
- Originais das imagens preservados em `apps/.originais/{Correios,GOV,Serasa}`.

---

## Cenários de Validação

### 1. Pipeline de Censura por Blur e Logos
```powershell
python scripts/censurar_servicos_sociais.py
```
**Resultado esperado**:
- Originais movidos/copiados para `apps/.originais/`.
- Todas as regiões sensíveis (CPF `524.957.408-47`, nomes `EDUARDO JUNCKER TORAS`, `"Oi, Eduardo"`, iniciais `ET`, Score `653`, código de rastreio) censuradas com Gaussian Blur em `apps/{Correios,GOV,Serasa}/` e `app/assets/guias/{correios,gov-br,serasa}/`.
- Logos 512×512 geradas em `app/assets/ilustracoes/{gov_br,serasa,correios}_logo.png`.
- Orçamento de `app/assets/guias/` inferior a 8,00 MB.

### 2. Conformidade de Tokens e Análise Estática
```powershell
python specs/002-design-system/ferramentas/validar_tokens.py
Set-Location app; flutter analyze
```
**Resultado esperado**:
- `validar_tokens.py`: Nenhum literal encontrado.
- `flutter analyze`: `No issues found!`.

### 3. Portões de Catálogo, Guias Seccionados e Acessibilidade
```powershell
Set-Location app
flutter test test/features/aprendizado/catalogo_e_guias_test.dart
flutter test test/features/aprendizado/tela_seletor_de_secao_test.dart
flutter test test/acessibilidade/
```
**Resultado esperado**:
- Todos os testes de `catalogo_e_guias_test.dart` aprovados (incluindo teto de 8 MB e validação de seções entre 3 e 7 passos).
- `tela_seletor_de_secao_test.dart` aprovado sem overflow na matriz 4 aparelhos × 3 escalas (100%, 150%, 200%) × 3 temas (`claro`, `escuro`, `altoContraste`).

### 4. Validação Ponta a Ponta no Fluxo do App
1. Abrir o Memora e entrar em **Serviços sociais**.
2. Tocar em **Gov.br** → Verifica-se que abre `TelaSeletorDeSecao` com as 6 seções temáticas (em vez de 40 telas seguidas).
3. Selecionar **Baixar Certidões e Agenda** → Abre `TelaPassoAPasso` apenas com os 3–4 passos dessa seção.
4. Voltar e selecionar **Entrar na conta Gov.br** → Verifica-se o aviso permanente da **FR-032** no passo com campo de senha e o CPF censurado por Blur na captura.
5. Repetir para **Serasa** (5 seções) e **Correios** (2 seções).
