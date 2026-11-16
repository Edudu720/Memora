# Checklist de Qualidade de Requisitos: Site Tutorial Acolhedor do Memora (`012-site-tutorial-idoso`)

**Purpose**: Avaliar clareza, completude, consistência, mensurabilidade e cobertura de riscos nos requisitos antes da geração de tarefas (`/speckit-tasks`) e na revisão final pré-PR.  
**Created**: 2026-11-16  
**Feature**: [spec.md](file:///c:/Users/Eduardo/Memora/specs/012-site-tutorial-idoso/spec.md)  
**Focus / Depth / Timing**: Revisão completa combinada (UX acolhedora, acessibilidade, responsividade, segurança anti-golpes e offline) · Padrão (`20` itens) · Autor pré-tarefas e revisão pré-PR

**Note**: Esta checklist testa a **qualidade dos requisitos escritos** (e não a execução do código). Marcar `[x]` cabe ao revisor ao aprovar cada critério de especificação; `/speckit-implement` lê este arquivo sem marcar itens automaticamente.

---

## Completude dos Requisitos e Cobertura Editorial

- [x] CHK001 Os 9 capítulos do tutorial especificados cobrem integralmente todas as funcionalidades voltadas ao usuário final descritas nos documentos do produto (Frase Secreta, Modo Assistido, 3 toques, conversa e histórico, apps externos com aviso, Ajustes/foto local, pulseira de queda e proteção contra golpes)? [Completeness, Spec §FR-007, Data Model §3]
- [x] CHK002 A separação de protagonismo entre o público principal (pessoa idosa 60+) e o público secundário (familiar/cuidador) está explicitamente delimitada na especificação sem gerar conflito de tom textual? [Completeness, Spec §User Story 1, Spec §User Story 5]
- [x] CHK003 O critério para proibir jargões técnicos e termos em inglês está claramente definido com exemplos explícitos do que evitar e como substituir no texto educativo? [Clarity, Spec §FR-002]
- [x] CHK004 Os requisitos definem o comportamento completo das mini-telas ilustrativas de exemplo (como diferenciá-las visual e semanticamente de uma conta real ativa para evitar frustração ao tocar nelas)? [Completeness, Spec §FR-003, Contract §3]

## Clareza, Design Acolhedor e Responsividade (`PC` e `Mobile`)

- [x] CHK005 O requisito de "design acolhedor e visualmente estruturado" (em oposição a visual cru) está traduzido em propriedades objetivas verificáveis (cartões espaçados, cantos suaves, hierarquia de títulos, ilustrações em medalhões e largura confortável de leitura)? [Clarity, Spec §FR-003, Plan §Summary]
- [x] CHK006 Todas as faixas de largura de tela para desktop e dispositivos móveis estão especificadas com limites mensuráveis (`320 px` até `1280 px+`) e regra explícita de ausência de rolagem horizontal? [Measurability, Spec §FR-004, Spec §SC-002]
- [x] CHK007 A relação entre ampliação via controle interno do site (`padrao`, `grande`, `muito-grande`) e ampliação do próprio navegador até `200%` está especificada sem ambiguidade sobre qual base de cálculo e expectativa de empilhamento se aplica? [Ambiguity, Spec §AC-004, Research §3]
- [x] CHK008 O comportamento do sumário de página única e do botão de retorno ao topo está claramente especificado para telas estreitas de celular e telas largas de computador? [Clarity, Spec §FR-005, Spec §SC-005]

## Acessibilidade Estrutural, Voz Local e Fallbacks

- [x] CHK009 As razões mínimas de contraste WCAG 2.2 estão quantificadas separadamente para os modos Claro, Escuro e Alto Contraste (`>= 4.5:1` / `>= 3.0:1` e `>= 7.0:1`), incluindo verificação de que as ilustrações mantêm legibilidade sobre fundo escuro? [Measurability, Spec §AC-001, Contract §2]
- [x] CHK010 Os requisitos de área de toque mínima (`48 x 48 px`) e espaçamento (`>= 8 px`) cobrem uniformemente todos os elementos interativos previstos (sumário, controles de letra/tema, botões de voz, perguntas frequentes e botão voltar ao topo)? [Consistency, Spec §AC-002, Contract §4]
- [x] CHK011 A exigência de zero ícones isolados sem legenda em português é consistente entre os requisitos de texto, as mini-telas ilustrativas e os botões de controle da própria página? [Consistency, Spec §AC-003, Contract §3]
- [x] CHK012 O requisito opcional de leitura em voz alta (**"Ouvir este trecho / Parar leitura"**) especifica claramente: (a) exclusividade de um capítulo falando por vez, (b) ausência de envio de texto pela rede e (c) ocultação silenciosa quando o navegador não suportar voz local? [Completeness, Spec §FR-013, Data Model §2]
- [x] CHK013 Os requisitos definem o comportamento esperado quando o usuário possui preferência de redução de movimento ativa no sistema operacional? [Edge Case, Spec §Edge Cases & Estados]

## Segurança Anti-Engenharia Social, Offline e Consistência

- [x] CHK014 Os requisitos anti-engenharia social e de privacidade estão consistentes ao proibir integralmente formulários, campos de entrada sensíveis e links externos (`zero` formulários e `zero` links para fora da página), sem exceções contraditórias remanescentes em outras seções? [Consistency, Spec §FR-011, Spec §FR-012, Spec §SC-006]
- [x] CHK015 Todas as ameaças levantadas no *Threat Model* (páginas falsas/phishing, dependências externas indisponíveis em offline, redirecionamentos e confusão entre guia e app real) possuem requisitos correspondentes rastreáveis? [Traceability, Spec §Threat Model, Contract §4]
- [x] CHK016 O comportamento de falha e degradação está definido para todos os cenários sem rede ou restritos: abertura local sem internet (`offline`), falha no carregamento de imagem ilustrativa e bloqueio de `localStorage` no navegador? [Coverage, Spec §Edge Cases & Estados, Spec §FR-010]

## Limites de Escopo, Suposições e Critérios de Aceite

- [x] CHK017 A fronteira de independência do site em relação ao aplicativo Android (`app/`), ao servidor (`backend/`) e aos portões de CI existentes está explícita para impedir alterações indevidas nesses módulos? [Completeness, Spec §Assumptions, Plan §Structure Decision]
- [x] CHK018 Os limites explícitos da assistente do Memora descritos no tutorial refletem com fidelidade a Constituição VI (nunca age sem confirmação, nunca acessa dados bancários, nunca envia mensagens ocultas)? [Consistency, Spec §Papel e Limites da Assistente, Spec §FR-008]
- [x] CHK019 Todos os critérios mensuráveis de sucesso (`SC-001` a `SC-006`) podem ser validados de maneira objetiva sem depender de suposições sobre backend ou ferramentas proprietárias? [Measurability, Spec §Success Criteria]
- [x] CHK020 Existe alguma suposição implícita sobre armazenamento do histórico de leitura ou reprodução de voz que conflite com a restrição de zero dados pessoais coletados? [Assumption, Spec §FR-010, Spec §FR-011]

---

## Notes

- Revisão realizada em 2026-11-16 comparando [spec.md](file:///c:/Users/Eduardo/Memora/specs/012-site-tutorial-idoso/spec.md), [plan.md](file:///c:/Users/Eduardo/Memora/specs/012-site-tutorial-idoso/plan.md), [data-model.md](file:///c:/Users/Eduardo/Memora/specs/012-site-tutorial-idoso/data-model.md) e [estrutura-e-acessibilidade.md](file:///c:/Users/Eduardo/Memora/specs/012-site-tutorial-idoso/contracts/estrutura-e-acessibilidade.md) com [MEMORA_SOBRE.txt](file:///c:/Users/Eduardo/Memora/MEMORA_SOBRE.txt) e [constitution.md](file:///c:/Users/Eduardo/Memora/.specify/memory/constitution.md).
- Ajuste aplicado durante a revisão em `CHK007`: detalhamento explícito em `AC-004` da [spec.md](file:///c:/Users/Eduardo/Memora/specs/012-site-tutorial-idoso/spec.md) definindo a equivalência exata de `200%` (`Letra muito grande >= 32 px` sobre base `16 px` e zoom `200%` do navegador sobre `Letra normal`).
- Resultado: **20/20** critérios de qualidade de requisitos aprovados; fase pronta para `/speckit-tasks`.
