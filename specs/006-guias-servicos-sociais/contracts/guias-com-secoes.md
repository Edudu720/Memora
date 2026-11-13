# Contrato: Guias Seccionados e Censura por Blur

**Feature**: `006-guias-servicos-sociais` | **Data**: 2026-11-13

---

## 1. Contrato de Privacidade e Censura por Blur

Toda imagem incluída em `apps/GOV/`, `apps/Serasa/`, `apps/Correios/` e copiada para `app/assets/guias/<chave>/` deve obedecer:

1. **Backup Seguro**: Originais brutos preservados exclusivamente em `apps/.originais/<pasta>/` (ignorado pelo `.gitignore`).
2. **Desfoque Obrigatório (Gaussian Blur)**:
   - Nomes completos, primeiros nomes, iniciais em avatares (`ET`), fotos de perfil pessoais, números de CPF (`524.957.408-47`), pontuações financeiras pessoais (`653 / 1000`) e códigos de rastreamento devem receber `ImageFilter.GaussianBlur(radius >= 22)` sobre a região exata.
   - **Proibido** manter qualquer texto legível de dado pessoal sob blur fraco (`radius < 18`).
3. **Campo de Senha Vazio (`FR-032`)**: Nenhuma captura pode exibir senha digitada ou sugerida; passos com campo de senha devem usar `temCampoDeSenha: true`.
4. **Orçamento Total de Assets**: O diretório `app/assets/guias/` completo (incluindo WhatsApp, Telegram, Facebook e serviços sociais) **não pode exceder 8 MB** (verificado pelo teste `catalogo_e_guias_test.dart`).

---

## 2. Contrato de Interface: `TelaSeletorDeSecao`

Quando um `Guia` tem `secoes.isNotEmpty`, a transição a partir do catálogo abre `TelaSeletorDeSecao` antes de `TelaPassoAPasso`:

1. **Cabeçalho (`CabecalhoDeTela`)**: Título do serviço (ex.: *"Gov.br"*) e botão **"Voltar"** (seta + palavra "Voltar", alvo >= 48×48 dp).
2. **Acolhimento (`BalaoDeFala`)**: Rosto da Memora na esquerda com a pergunta literal: *"O que você quer aprender no [Nome do Serviço]?"*.
3. **Lista de Seções (`CartaoDePorta` / cartão acessível)**:
   - Cada seção é um botão acessível com área de toque mínima **48×48 dp**, espaçamento mínimo **8 dp** entre cartões.
   - Exibe: **Ícone + Título curto + Subtítulo (1 linha) + Contagem de passos** (ex.: *"4 passos"*), mais selo **"Já aprendeu"** se concluída.
   - Contraste mínimo **WCAG 2.2 AA** (4.5:1 texto normal, 3:1 texto grande e ícones) nos 3 temas (`claro`, `escuro`, `altoContraste`).
   - Sem overflow em **4 aparelhos × 3 escalas (até 200%) × 3 temas**.
4. **Atalho para Conversa Direta**: Ao final da lista, opção clara *"Não achei o que procuro — perguntar à Memora"* levando para `TelaConversa`.
5. **Proibição de Valores Literais**: Nenhum `Color(0x...)`, `EdgeInsets` literal ou `TextStyle` literal fora dos tokens do Design System (`validar_tokens.py`).

---

## 3. Contrato de Testes e Portões de Qualidade

1. `catalogo_e_guias_test.dart` atualizado para validar `g.secoes`:
   - Cada `SecaoDoGuia` deve ter entre `Guia.minimoDePassos` (3) e `Guia.maximoDePassos` (7) passos.
   - Toda captura em `g.todosOsPassos` deve existir em `assets/guias/`, ter `descricaoDaCaptura` não vazia e estar listada em `CAPTURAS.md`.
   - Total de `assets/guias/` <= 8 MB.
2. `tela_seletor_de_secao_test.dart`: Matriz completa de acessibilidade (4 aparelhos × 3 escalas × 3 temas) e leitura semântica (TalkBack).
3. `validar_tokens.py` e `flutter analyze`: 0 violações / 0 erros.
