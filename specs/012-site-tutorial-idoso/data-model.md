# Data Model: Site Tutorial Acolhedor do Memora (`012-site-tutorial-idoso`)

**Branch**: `feature/012-site-tutorial-idoso` | **Date**: 2026-11-16 | **Spec**: [spec.md](file:///c:/Users/Eduardo/Memora/specs/012-site-tutorial-idoso/spec.md)

Não há banco de dados, servidor nem persistência de dados pessoais. Este modelo documenta a estrutura semântica dos conteúdos da página e o estado local efêmero de preferências de leitura.

---

## 1. Preferência de Leitura Local (`PreferenciaDeLeitura`)

Armazenada opcionalmente em `localStorage` sob chaves isoladas não sensíveis (com fallback transparente em memória se o navegador bloquear `localStorage`):

| Campo | Chave Local | Valores Permitidos | Padrão Inicial | Regra de Validação |
| :--- | :--- | :--- | :--- | :--- |
| `tamanhoFonte` | `memora.tutorial.escala_fonte` | `'padrao'` \| `'grande'` \| `'muito-grande'` | `'padrao'` | Valor fora da enumeração volta silenciosamente para `'padrao'`. Equivalências visuais: `1.125rem` (`18px`), `1.45rem` (`~23px`) e `2.0rem` (`32px`, `200%` sobre `16px`). |
| `modoVisual` | `memora.tutorial.modo_visual` | `'claro'` \| `'escuro'` \| `'alto-contraste'` | `'claro'` | Valor fora da enumeração volta para `'claro'`. Refletido no atributo `data-tema` da raiz do documento (`<html>`). |

**Nota de privacidade**: Nenhum dado de identificação, nome, CPF, telefone, senha ou histórico de navegação pessoal é gravado ou transmitido.

---

## 2. Estado de Leitura em Voz Alta (`EstadoLeituraEmVoz`)

Gerenciado exclusivamente em memória durante a sessão aberta na página:

| Campo | Tipo | Valores / Estado | Regras de Transição |
| :--- | :--- | :--- | :--- |
| `suportado` | `boolean` | `'speechSynthesis' in window` | Se `false`, todos os botões `"Ouvir este trecho"` permanecem com atributo `hidden`. |
| `secaoAtivaId` | `string \| null` | ID da seção em leitura ou `null` | Apenas uma seção pode estar ativa por vez. Iniciar nova seção chama `speechSynthesis.cancel()` antes de iniciar a nova fala e atualiza o rótulo anterior de volta para `"Ouvir este trecho"`. |
| `estado` | `'ocioso' \| 'lendo'` | `'ocioso'` inicialmente | Botão ativo alterna `aria-pressed="true"` e texto visível para `"Parar leitura"`. Ao concluir naturalmente (`onend`) ou dar erro (`onerror`), retorna silenciosamente para `'ocioso'` sem pop-ups alarmistas. |

---

## 3. Catálogo Estrutural de Capítulos do Tutorial (`CapituloDoTutorial`)

Cada capítulo da página única contínua segue contrato uniforme para navegação no sumário (`FR-005`), acessibilidade (`AC-005`) e leitura em voz alta (`FR-013`):

| ID da Âncora | Rótulo no Sumário | Objetivo Pedagógico | Elementos Visuais Associados |
| :--- | :--- | :--- | :--- |
| `#boas-vindas` | Início e Propósito | Apresentar o Memora, tirar o medo de errar e exibir o lema *"Eu mostro o caminho e você faz..."*. | Ilustração `memora_falando.svg` em medalhão + cartão de compromisso de respeito. |
| `#primeiros-passos` | Primeiros Passos | Explicar Frase Secreta, Modo Assistido familiar e saída segura em 2 confirmações. | Mini-tela ilustrativa da Frase Secreta e apoio em dois passos (`pessoa_com_celular.svg`). |
| `#navegacao-3-toques` | Os 3 Botões Principais | Explicar a barra inferior simples (`Ajustes`, `Início` e `Meu perfil`) e a regra de até 3 toques. | Mini-tela ilustrativa da barra inferior com os 3 botões legendados em português. |
| `#conversa-e-historico` | Conversar e Histórico | Ensinar como tirar dúvidas com a Memora sem jargões e conferir *"O que eu fiz por você"*. | Ilustração `porta_conversa.svg` + `porta_registro.svg` + exemplo visual de diálogo educativo. |
| `#aplicativos-e-servicos` | Aplicativos do Dia a Dia | Mostrar como abrir WhatsApp, Telefone, Fotos, Gov.br e Saúde com aviso amigável prévio. | Ilustrações `porta_aplicativos.svg` + `porta_servicos.svg` + exemplo da tela de aviso antes de sair do app. |
| `#ajustes-e-foto` | Ajustes e Foto de Perfil | Ensinar a mudar tamanho de letra/cores em Ajustes e colocar foto/avatar guardado só no aparelho em Meu perfil. | Ilustrações `ajuste_aparencia.svg` + `memora_perfil_robo.png` + mini-tela das 3 opções de retrato. |
| `#pulseira-cuidado` | Pulseira de Cuidado | Explicar de forma acolhedora o acompanhamento de batimentos e a checagem de queda em 45s (`Estou bem` / `Preciso de ajuda`). | Ilustração `casal_idoso.svg` / `memora_ajuda_robo.png` + mini-tela calma com os dois botões grandes. |
| `#protecao-golpes` | Proteção contra Golpes | Destacar o que o Memora NUNCA faz e orientar reação calma diante de ligações ou links suspeitos. | Ilustração `memora_alerta_robo.png` + quadro de alerta claro em `perigo` e escudo de garantia. |
| `#duvidas-frequentes` | Dúvidas Frequentes | Responder de forma paciente e tranquilizadora às dúvidas mais comuns do dia a dia (incluindo câmera negada e modo offline). | Blocos expansíveis nativos (`<details>`/`<summary>`) + dica rápida para familiares/cuidadores. |
