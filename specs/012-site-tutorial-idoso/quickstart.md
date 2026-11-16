# Quickstart de Validação: Site Tutorial do Memora (`012-site-tutorial-idoso`)

**Branch**: `feature/012-site-tutorial-idoso` | **Date**: 2026-11-16 | **Spec**: [spec.md](file:///c:/Users/Eduardo/Memora/specs/012-site-tutorial-idoso/spec.md)

Este guia descreve como abrir, inspecionar e validar o site estático de tutorial após a implementação, sem alterar nem depender do aplicativo Android (`app/`) ou do servidor (`backend/`).

---

## 1. Pré-requisitos

- **Navegador moderno** (Chrome, Edge ou Firefox no Windows/macOS/Android) — funciona tanto abrindo diretamente o arquivo `site/index.html` quanto por servidor estático local.
- **Python 3.11+** (para o validador estrutural, anti-engenharia social e WCAG 2.2) e **Node.js 20+** (para testes unitários da lógica cliente de preferências e voz).

---

## 2. Como Executar Localmente (PC e Celular)

### Modo arquivo local (offline puro)
Abra diretamente no navegador: `site/index.html`.

### Modo servidor estático local (recomendado para testar no emulador/celular da rede)
Na raiz do repositório:

```powershell
python -m http.server 8080 --directory site
```

Acesse `http://localhost:8080` no navegador do computador (e utilize o modo responsivo DevTools em `320×568`, `390×844`, `768×1024` e `1280×800`).

---

## 3. Portões Automatizados Esperados

1. **Validador estrutural, offline, anti-phishing e contraste WCAG 2.2**:
   ```powershell
   python site/tests/validar_site.py
   ```
   - Verifica ausência de `<form>`, `<input>` sensíveis, links externos `http(s)://`, dependências de rede externas, `alt` em todas as imagens, presença dos arquivos em `site/assets/ilustracoes/`, hierarquia de títulos e razão de contraste WCAG 2.2 AA/AAA em `site/styles/tokens.css`.
2. **Testes lógicos em Node.js (`node --test`)**:
   ```powershell
   node --test site/tests/tutorial.test.mjs
   ```
   - Valida troca de escala (`padrao`, `grande`, `muito-grande`), troca de tema (`claro`, `escuro`, `alto-contraste`), fallback limpo sem `localStorage` e exclusividade de leitura em voz alta (um capítulo por vez + ocultação quando `speechSynthesis` não existe).
3. **Não regressão dos portões já existentes no repositório**:
   ```powershell
   python specs/002-design-system/ferramentas/validar_paleta.py
   python specs/002-design-system/ferramentas/validar_tokens.py
   ```

---

## 4. Checklist Rápido de Conferência Visual e Manual

- [ ] **PC (`1280×800`)**: abertura acolhedora com ilustração da Memora, sumário legível no topo, cartões bem espaçados em grade confortável, mini-telas visuais claras e retorno rápido ao topo.
- [ ] **Celular estreito (`320×568`) a `100%` e `200%` (`Letra muito grande`)**: coluna única fluida, **zero** rolagem horizontal (`scrollWidth <= clientWidth`), botões amplos (`>= 48×48 px`) e sem texto cortado.
- [ ] **Temas visuais**: `Fundo claro`, `Fundo escuro` e `Alto contraste` alternam imediatamente preservando leitura nítida nas mini-telas e medalhões das ilustrações.
- [ ] **Leitura em voz alta**: botão `"Ouvir este trecho"` lê em português brasileiro, troca para `"Parar leitura"` e interrompe automaticamente ao iniciar outro trecho.
- [ ] **Teclado e leitor de tela**: pressionar `Tab` revela `"Ir direto para o conteúdo principal"`, foco é sempre visível e todos os `<details>` das Dúvidas Frequentes abrem com `Enter`/`Espaço`.
