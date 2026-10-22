# Plano de Remediação e Ajustes — `/speckit-analyze` (Feature 004)

> **Documento de Registro**: Este arquivo documenta os achados do `/speckit-analyze` executado em 2026-10-14 sobre a feature `specs/004-redesenho-das-telas`, detalhando as edições exatas a serem aplicadas via `/speckit-specify`, `/speckit-tasks` ou edição direta alinhada com a equipe.

---

## 1. Ajuste Crítico em `tasks.md`: Restauração da Fase 9 (D1, U1)

### Problema Identificado
Na seção `## Phase 9: User Story 7 — Ajustar o Memora ao meu jeito (Priority: P2)` em [`tasks.md`](tasks.md#L351), o texto das tarefas da Fase 8 (`T085` a `T090`, sobre Ajuda) foi duplicado por engano de colagem/merge, apagando as tarefas reais `T091` a `T095` da Fase 9 (Ajustes, Aparência, Privacidade, Conta).

### Correção Proposta
Substituir o bloco duplicado pelo bloco original da Fase 9 (cujas implementações já foram inclusive entregues via PR #46/#52):

```markdown
## Phase 9: User Story 7 — Ajustar o Memora ao meu jeito (Priority: P2)

**Goal**: Configurações com Aparência, Acessibilidade, Privacidade e Conta (FR-038).

**Independent Test**: deixar o texto maior e sair da conta, sem ajuda (US7).

- [X] T091 [P] [US7] Teste em `app/test/features/configuracoes/configuracoes_test.dart`: só Aparência, Acessibilidade, Privacidade e Conta (sem "Notificações" e "Idiomas"); galeria só em depuração; Privacidade apaga a conversa **só depois das duas etapas** da `ConfirmacaoMemora.irreversivel` — um toque só não apaga nada, e o botão de apagar não fica ao lado do de cancelar (FR-040). Provar quebrando: trocar pela confirmação simples; Conta mostra o canal, "Sair" pergunta antes, "Sair e esquecer este aparelho" usa `esquecerTudo`; a Conta diz o que o Memora nunca faz (FR-036a); matriz completa; os estados da FR-006 que a tela tiver (carregando, vazio, erro), por `app/test/suporte/estados_de_tela.dart`
- [X] T092 [US7] Criar `TelaConfiguracoes` em `app/lib/features/configuracoes/presentation/tela_configuracoes.dart`, substituindo a raiz provisória da T024, e apontar `app/test/features/autenticacao/fluxo_sair_confirma_test.dart` para a saída em Conta, mantendo a quebra que ele já prova
- [X] T093 [US7] Acrescentar "reduzir movimento" a `PreferenciaAparencia` (`app/lib/design_system/preferencias/preferencia_aparencia.dart`), persistida pelo repositório de `app/lib/services/preferencias/` e aplicada sobre o `MediaQuery` no `builder` de `MaterialApp` em `main.dart`; redesenhar `tela_aparencia.dart` com pré-visualização e desfazer (FR-039); `app/test/design_system/reducao_de_movimento_test.dart` e `preferencias/tela_aparencia_test.dart` estendidos
- [X] T094 [US7] Criar `TelaPrivacidade` em `app/lib/features/configuracoes/presentation/tela_privacidade.dart`: o que fica no aparelho, em linguagem comum, e apagar a conversa pela `ConfirmacaoMemora.irreversivel`, em duas etapas (FR-040; fecha a T085 da 003)
- [X] T095 [US7] Criar `TelaConta` em `app/lib/features/configuracoes/presentation/tela_conta.dart`, com o canal vindo de `UltimoAcesso` (R10); apontar `app/test/features/autenticacao/saida_limpa_armazenamento_test.dart` para ela, mantendo as quatro quebras que o portão já provou
```

---

## 2. Ajuste Formal em `spec.md`: Status da Especificação (I1, C1)

### Problema Identificado
A especificação [`spec.md`](spec.md#L5) ainda consta com `Status: Draft`, embora tenha sido formalmente aprovada na sessão de 2026-10-13 pelo Eduardo (clarificação aprovada) e ratificada com a validação da PR #58 e do teste físico de APK pelo Henrique (T116).

### Correção Proposta
No cabeçalho de `spec.md`:
- Trocar `Status: Draft` por `Status: Approved`.
- Adicionar registro de aprovação/ratificação:
  `Approved by: Eduardo Juncker Toras (2026-10-13) | Ratified: Henrique Moreira Sandrini (2026-10-14, T116)`.

---

## 3. Racionalização de Rastreio em `tasks.md`: Fase 3b vs Fases 4 a 10 (D2, I2)

### Problema Identificado
A Phase 3b possui uma seção intitulada "Nas fases seguintes" contendo as tarefas `T117` a `T124`. Isso cria duplo rastreamento:
- `T117` listada em Phase 3b e na Phase 4.
- `T118` listada em Phase 3b e na Phase 5.
- `T119` listada em Phase 3b e na Phase 6 (onde `T069` também a descreve).
- `T121`/`T122` listadas em Phase 3b e na Phase 9.
- `T123` listada em Phase 3b e na Phase 10.
- `T124` listada em Phase 3b e na Phase 7.

### Correção Proposta
- Em Phase 3b, manter apenas o resumo das decisões tomadas no veredito da T044 e apontar para as respectivas fases executoras (US1 a US8), eliminando itens de checkbox duplicados.
- Na Phase 6, consolidar `T119` diretamente dentro do escopo de `T069`.

---

## 4. Padronização de Terminologia: Ajustes vs Configurações (I3)

### Problema Identificado
O terceiro destino da barra inferior é chamado de "Ajustes" no código e na UI (`TextosCasca.destinoAjustes`, wireframe e R2), mas em diversos trechos de `spec.md` e `plan.md` é referido como "Configurações".

### Correção Proposta
- Padronizar nos textos descritivos: "Ajustes (anteriormente Configurações)".
- Manter o nome técnico da classe `TelaConfiguracoes` para compatibilidade com o histórico do código, ou planejar renomeação consistente em refatoração futura.

---

## 5. Detalhamento da Tarefa `T125`: Aplicação de `CaixaDeEtapa` (U2)

### Problema Identificado
A tarefa `T125` agrupa muitas telas em um único item genérico: *"Aplicar a CaixaDeEtapa às telas que pedem ação e ainda não a têm — Ajustes, Conta e Privacidade, a tela de data de nascimento, o passo a passo, a Ajuda e as telas da T099"*.

### Correção Proposta
Subdividir `T125` em subtarefas ou checklist explícito:
- [ ] `T125a`: `CaixaDeEtapa` em Ajustes, Conta e Privacidade
- [ ] `T125b`: `CaixaDeEtapa` na tela de data de nascimento (Perfil)
- [ ] `T125c`: `CaixaDeEtapa` no passo a passo
- [ ] `T125d`: `CaixaDeEtapa` nas telas fora do wireframe (`T099`)

---

## 6. Tarefas Remanescentes Específicas a Executar

1. **`T120` [US4]**: Ajustar `catalogo_e_guias_test.dart` para registrar **lista de pendentes** em vez de reprovar na ausência de PNGs locais (conforme FR-028a).
2. **`T122` [US7]**: Implementar o seletor visual de paletas em Aparência (o validador Python e a preferência em storage já existem).
3. **`T109` & `T110` [Polish]**: Garantir registro de atividade semântica no leitor de tela (TalkBack) e dentro de diálogos.
4. **`T104` & `T105` [Final]**: Álbum completo e teste presencial com 5 pessoas idosas (65+).
