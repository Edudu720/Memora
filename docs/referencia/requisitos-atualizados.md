# Requisitos Atualizados — Memora

**Última atualização**: 2026-07-24
**Base**: *Arquivo X 2S 2025* (documento acadêmico original)

> Este documento registra **o que mudou** em relação ao levantamento de requisitos
> original e **por quê**. Ele existe para que a documentação acadêmica e o código
> não contem histórias diferentes.

---

## 1. Alterações em requisitos existentes

### RNF007 — Hardware e Software *(alterado)*

| | Texto |
|---|---|
| **Original** | O sistema deve ser desenvolvido no Android Studio, utilizando Java e bibliotecas nativas do Android (SDK), com compatibilidade para dispositivos de entrada. |
| **Atualizado** | O aplicativo deve ser desenvolvido em **Flutter com Dart**, e o backend em **Java com Spring Boot**, mantendo compatibilidade com dispositivos Android de entrada. |

**Motivo da alteração**:

O documento original previa Android nativo em Java. A migração para Flutter atende
a dois pontos que o próprio documento levanta:

1. A Tabela 1 lista **"Ser multiplataforma"** como característica do Memora. Android
   nativo em Java não entrega isso; Flutter entrega.
2. O controle fino sobre acessibilidade — escala de texto, semântica para leitor de
   tela, área de toque — é mais direto e mais testável em Flutter, e acessibilidade
   é o requisito central deste produto.

O **Java permanece no projeto**, no backend, onde o Spring Security oferece o
ecossistema de segurança mais maduro disponível. A justificativa completa, com as
alternativas avaliadas e descartadas, está em
[ADR 001](../architecture/adr-001-linguagem-do-backend.md).

---

### RNF004 — Segurança *(ampliado)*

| | Texto |
|---|---|
| **Original** | As comunicações devem ocorrer via HTTPS e os dados do usuário devem ser armazenados de forma segura e criptografada. |
| **Atualizado** | Mantém o original e acrescenta: o sistema deve seguir **Security by Design**, com modelagem de ameaças documentada antes da implementação de cada funcionalidade, classificação de sensibilidade por campo, hash de senha com Argon2id, sessão com token curto e refresh rotativo com detecção de reuso, e proteção explícita contra as classes de ataque listadas na Constituição do projeto. |

**Motivo**: o público-alvo é o mais visado por golpes digitais no Brasil. "HTTPS e
criptografia" é insuficiente como requisito de segurança para esse contexto.

---

### RNF006 — Padrões *(ampliado)*

| | Texto |
|---|---|
| **Original** | O sistema deve seguir os padrões de desenvolvimento Android (Material Design e boas práticas de acessibilidade). |
| **Atualizado** | Mantém o original e torna verificável: conformidade **WCAG 2.2 nível AA** — contraste mínimo de 4.5:1 para texto e 3:1 para elementos gráficos, área de toque mínima de 48 dp, utilização integral com texto ampliado até 200%, e rótulos semânticos para leitores de tela. Todos verificados por **teste automatizado**. |

**Motivo**: "boas práticas de acessibilidade" não é verificável. Um requisito que não
pode ser testado não pode ser cobrado — e acessibilidade que depende de disciplina se
degrada a cada tela nova.

---

## 2. Requisitos funcionais adicionados

O levantamento original não contemplava autenticação, embora as telas de Cadastro e
Login existam no protótipo.

| ID | Requisito | Prioridade |
|---|---|---|
| **RF007** | Cadastro de conta com o mínimo de dados, concluindo já autenticado | Essencial |
| **RF008** | Autenticação por e-mail ou telefone, e por provedor externo (Google e Facebook) | Essencial |
| **RF009** | Recuperação de acesso sem intervenção humana | Essencial |
| **RF010** | Encerramento de sessão com remoção de dados do aparelho | Essencial |
| **RF011** | Cadastro assistido por familiar, preservando o sigilo da senha | Importante |
| **RF012** | Personalização de aparência entre temas validados e tamanho de texto | Importante |

**Observação sobre o RF011**: na prática, a maior parte dos idosos terá o aplicativo
configurado por um filho ou neto. Não desenhar esse caminho não o elimina — apenas
faz com que aconteça com o familiar conhecendo a senha, criando a dependência que o
produto existe para quebrar.

---

## 3. Contradições identificadas no documento original

Levantadas na análise inicial e ainda **pendentes de correção no Arquivo X**.

| # | Contradição | Encaminhamento |
|---|---|---|
| 1 | A Tabela 1 afirma que o Memora possui *"Executar comandos por voz"* e *"Reconhecimento de fala otimizado para idosos"*, mas o **RF001 define comandos por texto** | Voz está **fora do escopo atual**. Ou a Tabela 1 é corrigida, ou um RF de voz é criado |
| 2 | A Tabela 1 afirma *"Suporte offline parcial"*, sem nenhum requisito que o sustente | Sem requisito. Uso offline está fora do escopo atual |
| 3 | O texto cita **Firebase** para autenticação e armazenamento | Substituído por backend próprio com PostgreSQL (ADR 001) |
| 4 | O diagrama de estados (Figura 1) não prevê **logout, recuperação de senha, erro nem offline** | Coberto pela spec 001, histórias US3 e US4 |
| 5 | O RNF002 exige disponibilidade de 99% sem definir como medir | Pendente de definição |

---

## 4. Divergências entre protótipo e implementação

Registradas com a medição que as justificou. Detalhamento em
[plan.md da feature 002](../../specs/002-design-system/plan.md).

| Protótipo | Implementação | Motivo |
|---|---|---|
| Botões SIM/NÃO de 24 px, lado a lado | Empilhados, 56 dp, com frase completa | **Medido**: 24 px é metade do mínimo de 48 dp |
| Fonte serifada no Chatbot | Sem serifa | Legibilidade em baixa visão |
| Navegação inferior apenas com ícones | Ícone **e** rótulo | Ícone isolado é ambíguo |
| Dados do Perfil como pílulas azuis | Componente de informação distinto de botão | Impossível distinguir dado de ação |
| Cadastro pedia e-mail, nome e nome de usuário | Apenas nome e um canal de contato | Carga cognitiva desnecessária |
| Após cadastrar, ia para o Login | Entra direto no aplicativo | Pedir a senha recém-criada causa desistência |
| *"Mexa como quiser"* nas cores | Três temas curados e validados | Escolha livre quebra a garantia de contraste |
| Botão "Idiomas" | Removido enquanto houver um idioma | Opção que não faz nada desgasta a confiança |
| Azul `#7090E8` | Removido da paleta | **Medido**: 3,07:1 com branco, reprova como texto |
| Azul `#1040F8` | **Mantido** | **Medido**: 6,75:1, aprovado |

---

## 5. O que foi confirmado, e não alterado

Registro igualmente importante — nem tudo precisou mudar:

- **A paleta do protótipo atende à WCAG.** O azul `#1040F8` mede 6,75:1 com texto
  branco. A identidade visual do projeto foi preservada.
- **Os botões SIM/NÃO passam em contraste** (14,98:1 e 7,55:1). A avaliação inicial
  de que reprovavam estava **errada** — era impressão visual, corrigida por medição.
  O defeito real era a altura.
- **A estrutura de navegação do diagrama de estados** é coerente e foi mantida.
- **A metodologia Scrum** permanece; o SDD organiza o trabalho *dentro* das sprints,
  não as substitui.
