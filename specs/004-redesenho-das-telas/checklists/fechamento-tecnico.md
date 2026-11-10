# Fechamento Técnico e Acessibilidade Sênior Checklist: Redesenho das Telas (004)

**Purpose**: Validar a completude, clareza, consistência e mensurabilidade dos requisitos de fechamento técnico da Feature 004 (`FR-002a` `CaixaDeEtapa`, `FR-017` rolagem do Hub, `SC-001` / `R13` álbum completo de telas e rastreabilidade documental `T102`/`T103`/`T107`) antes da geração de tarefas e implementação.
**Created**: 2026-11-09
**Feature**: [spec.md](../spec.md) | [plan.md](../plan.md) | [research.md](../research.md)

**Note**: Este checklist foi gerado pelo comando `/speckit-checklist` com foco na qualidade dos requisitos e decisões técnicas do fechamento da Feature 004 a partir da branch `develop`.

---

## Requirement Completeness (`FR-002a` — `CaixaDeEtapa` e Álbum)

- [x] CHK001 Os requisitos de separação em caixa própria com frase imperativa (`CaixaDeEtapa`) estão especificados para todas as telas restantes que pedem ação em `US7` (`TelaConfiguracoes`, `TelaConta`, `TelaPrivacidade`), `US8` (`TelaDataDeNascimento`), `US4` (`TelaPassoAPasso` / `PassoIlustrado`) e `US6` (`TelaAjuda`, `TelaAssunto`, `AjudaGuiadaDaConversa`)? [Completeness, Spec §FR-002a, Plan §R16.1]
- [x] CHK002 O escopo do álbum automatizado de telas (`album_de_telas_test.dart`) especifica explicitamente a cobertura de todas as telas da Feature 004 e das telas fora do wireframe redesenhadas na `T099` nos três temas validados (`claro`, `escuro`, `altoContraste`)? [Completeness, Spec §SC-001, Plan §R13, Plan §R16.3]
- [x] CHK003 Os requisitos de rastreabilidade e registro de divergências do wireframe especificam todos os artefatos documentais que precisam ser atualizados (`quickstart.md`, `divergencias-do-prototipo.md`, `requisitos-atualizados.md`, `specs/003-hub-e-assistente/spec.md` e `o-que-falta.md`)? [Completeness, Spec §SC-001, Plan §R16.4]

## Requirement Clarity (Semântica, Não-Clicabilidade e Regras de Layout)

- [x] CHK004 A distinção visual e semântica entre um contêiner informativo/agrupador (`CaixaDeEtapa`) e um elemento clicável (`BotaoPrimario`, `CartaoDeAcao`) está claramente definida para evitar falsas affordances de botão para a pessoa idosa? [Clarity, Spec §FR-002a, Spec §FR-042, Plan §R16.1]
- [x] CHK005 O formato das frases de instrução no cabeçalho de cada `CaixaDeEtapa` está definido de forma não ambígua (uma frase curta na voz da Memora dizendo o que fazer naquele grupo, marcada semanticamente como cabeçalho para o TalkBack)? [Clarity, Spec §FR-002a, Spec §FR-008, Plan §R16.1]
- [x] CHK006 A regra vigente de rolagem do Hub (`FR-017` após revisão de 2026-10-02) define com precisão matemática quais combinações de aparelho e escala exigem o Hub inteiro sem rolar (`360×800` a `100%`) versus a porta principal à vista com aviso `"há mais"` e a exceção medida do `320×568` a `200%`? [Clarity, Spec §FR-017, Plan §R16.2]

## Requirement Consistency (Segurança Contra Engenharia Social e Princípio II)

- [x] CHK007 A aplicação de `CaixaDeEtapa` na `TelaConta` mantém a exigência de separação espacial (`MemoraEspacamento.xxxl`) e visual entre a saída comum (`Sair`) e a ação destrutiva irreversível (`Sair e esquecer este aparelho`), sem agrupar ambas na mesma caixa? [Consistency, Spec §FR-002a, Spec §FR-041]
- [x] CHK008 A aplicação de `CaixaDeEtapa` na `TelaPrivacidade` preserva intacto o fluxo de confirmação irreversível em duas etapas (`FR-040`) para apagar a conversa, sem posicionar o botão destrutivo ao lado do botão de cancelar? [Consistency, Spec §FR-002a, Spec §FR-040]
- [x] CHK009 A aplicação de `CaixaDeEtapa` na `TelaDataDeNascimento` permanece consistente com o modelo de ameaças (`FR-042c`), garantindo que o campo de entrada e o botão opcional de remover a data fiquem em grupos distintos e que a data completa nunca seja exibida fora dessa tela? [Consistency, Spec §FR-002a, Spec §FR-042c, Spec §Threat Model]

## Scenario & Edge Case Coverage

- [x] CHK010 Os requisitos de `TelaPassoAPasso` e `PassoIlustrado` cobrem simultaneamente o estado de passo intermediário (instrução + ação de avanço + saída `"A minha tela está diferente"` offline-first) e o estado de conclusão (`concluido`, com parabéns, retorno ao Hub e oferta condicional de abrir pela conversa)? [Coverage, Spec §FR-002a, Spec §FR-025, Spec §FR-026, Spec §FR-027]
- [x] CHK011 O comportamento das telas de Ajuda (`TelaAssunto` e `AjudaGuiadaDaConversa`) especifica como a `CaixaDeEtapa` se comporta tanto em assuntos puramente informativos quanto em assuntos que disparam ação externa ou navegação (`Compartilhar`, `Apresentação inicial`, `A conversa`)? [Coverage, Spec §FR-002a, Spec §FR-033, Spec §FR-034, Spec §FR-035]
- [x] CHK012 O tratamento para texto ampliado a `200%` no menor aparelho suportado (`320×568`) está contemplado quando uma `CaixaDeEtapa` adiciona cabeçalho e preenchimento interno (`MemoraEspacamento.lg`) ao redor de listas ou formulários? [Edge Case, Spec §Edge Cases, Spec §FR-043, Spec §FR-044]

## Non-Functional Requirements & Measurability (Portões da Constituição)

- [x] CHK013 Os critérios de aceitação de acessibilidade para todas as telas alteradas pela `CaixaDeEtapa` são objetivamente mensuráveis na matriz completa (4 aparelhos × 3 escalas × 3 temas = 36 combinações por tela, zero overflow, alvos ≥ 48×48 dp, espaçamento ≥ 8 dp)? [Measurability, Spec §FR-043, Spec §FR-044, Spec §SC-007]
- [x] CHK014 A proibição de literais visuais (`Color(`, `Colors.`, `EdgeInsets`, `TextStyle(`, `BorderRadius`, `SizedBox(height/width:`) fora de `app/lib/design_system/tokens/` é verificável automaticamente por `validar_tokens.py --autoteste` e `validar_paleta.py`? [Measurability, Spec §Assumptions, Plan §Constitution Check]
- [x] CHK015 Os critérios de fechamento de `T035`, `T101`, `T102`, `T103`, `T107` e `T125a`–`T125d` possuem comandos de verificação determinísticos mapeados em `quickstart.md` (`V1` a `V14`) que permitem auditar a convergência completa antes do Pull Request para `develop`? [Measurability, Spec §SC-008, Plan §R16.4]

---

## Notes

- Este checklist avalia a **qualidade e prontidão dos requisitos e do plano técnico** para o fechamento da Feature 004.
- Todos os itens começam desmarcados (`- [ ]`) conforme o protocolo do `/speckit-checklist` e servem como portão de revisão para as etapas seguintes (`/speckit-tasks`, `/speckit-analyze`, `/speckit-implement` e `/speckit-converge`).
