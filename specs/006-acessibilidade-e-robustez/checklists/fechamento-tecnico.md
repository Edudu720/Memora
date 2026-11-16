# Checklist de Fechamento Técnico: Polimento de Acessibilidade, Robustez de Conta e Rastreabilidade

**Purpose**: Gate de pré-implementação e revisão de PR para validar a completude, clareza, consistência, mensurabilidade e cobertura dos requisitos de acessibilidade do Design System (`BotaoBase`), robustez de contas assistidas (`T065b`), entrega SMTP em produção (`T065a`/`T068`) e higiene de testes/documentação.
**Created**: 2026-11-13
**Feature**: [spec.md](../spec.md) | [plan.md](../plan.md) | [data-model.md](../data-model.md) | [contracts/componentes-e-servicos.md](../contracts/componentes-e-servicos.md)

**Note**: Este checklist foi gerado pelo comando `/speckit-checklist` como "testes unitários para requisitos" (validando a qualidade da especificação e dos contratos técnicos).

## Acessibilidade e Design System (`BotaoBase` / Feature 002)

- [x] CHK001 Os requisitos para o segundo sinal visual de foco e toque em `BotaoBase` especificam explicitamente o reuso de `SuperficieTocavel` e seus tokens exatos (`MemoraDimensoes.bordaSelecao`, `BorderSide.strokeAlignOutside` e `MemoraMovimento.escalaPressionado`) para todas as 4 variantes (`primario`, `secundario`, `terciario`, `perigo`)? [Clarity, Spec §FR-001, §FR-002]
- [x] CHK002 O comportamento esperado sob preferência de redução de movimento (`MediaQuery.disableAnimations`) está definido sem ambiguidade quanto à supressão da escala (`1.0`) mantendo o anel de foco externo intacto? [Coverage, Spec §US1-Scenario 2, Plan §R1]
- [x] CHK003 Os estados inativos (`aoPressionar == null` ou `carregando == true`) possuem requisitos claros que proíbem a exibição indevida de anel de foco, escala de toque ou disparo de callback, preservando a semântica de botão desabilitado (`enabled: false`)? [Completeness, Spec §FR-003, Edge Cases]
- [x] CHK004 As restrições arquiteturais de Design System (proibição de literais visuais de cor/dimensão/duração fora de `tokens/`, contraste WCAG 2.2 AA/AAA e altura mínima de `56dp` escalável até `200%`) estão quantificadas e alinhadas com a Constituição? [Consistency, Spec §FR-002, §SC-001, Constitution §I, §IV]

## Robustez de Contas Assistidas Abandonadas (`T065b` / Feature 001)

- [x] CHK005 O limiar temporal de expiração de contas em `PENDENTE_VERIFICACAO` (`24 horas` a partir de `criado_em`) e os dois gatilhos de expurgo (sob demanda no cadastro e rotina agendada em background) estão especificados de forma inequívoca? [Clarity, Spec §FR-004, §FR-006]
- [x] CHK006 A especificação exige que o expurgo sob demanda ocorra estritamente **após** o cálculo em tempo constante do hash Argon2id da senha recebida, preservando a simetria temporal exigida por `FR-010`? [Consistency, Spec §FR-004, Data-Model §2]
- [x] CHK007 Os requisitos distinguem com precisão o tratamento de contas `PENDENTE_VERIFICACAO` recentes (`<= 24 horas`) ou `ATIVA` (manutenção da resposta decoy anti-enumeração sem expurgo) do tratamento de contas expiradas (`> 24 horas`)? [Coverage, Spec §FR-005, §US2-Scenario 2]
- [x] CHK008 A ordem de exclusão para satisfazer a integridade referencial do banco (`DELETE FROM evento_autenticacao` antes da remoção de `pessoa_usuaria`, já que `fk_evento_pessoa` não possui `ON DELETE CASCADE`) está documentada nos artefatos de modelo de dados e contratos? [Completeness, Data-Model §1, Contracts §2]

## Entrega SMTP em Produção e Sigilo (`T065a` e `T068` / Feature 001)

- [x] CHK009 A separação de perfis do Spring Boot entre `@Profile("producao")` (adaptadores reais `EnviadorDeCodigoPorEmail` e `NotificadorDeContaPorEmail`) e `@Profile("!producao")` (adaptadores em log para dev/test/Render sem SMTP) está especificada sem sobreposição de beans? [Consistency, Spec §FR-008, §FR-010, Plan §R3]
- [x] CHK010 O requisito de validação *fail-fast* na inicialização do perfil `producao` define claramente quais propriedades são obrigatórias (`spring.mail.host` e remetente `memora.email.remetente`) e o diagnóstico esperado em caso de omissão? [Clarity, Spec §FR-008, §US3-Scenario 3]
- [x] CHK011 As regras de segurança e proteção contra golpes no conteúdo dos e-mails (ausência total de links clicáveis, linguagem simples e proscritiva na voz da Memora e proibição absoluta de registrar `codigoEmClaro` ou senhas SMTP em logs de qualquer nível) estão explicitadas? [Completeness, Spec §FR-009, §FR-011, Constitution §V]
- [x] CHK012 O comportamento de contorno para canais `TELEFONE` no perfil `producao` (enquanto não há gateway SMS contratado) e o tratamento de falhas transitórias de rede SMTP estão especificados sem exposição de stacktraces ou códigos em claro? [Coverage, Spec §FR-009, Edge Cases, Contracts §2]

## Higiene de Testes e Rastreabilidade Documental

- [x] CHK013 O requisito de correção de `app/test/design_system/cartao_de_porta_test.dart` especifica o uso de `MediaQuery.of(context).copyWith(textScaler: ...)` para preservar as dimensões reais da janela de teste em vez de instanciar `MediaQueryData` do zero com `Size.zero`? [Clarity, Spec §FR-012, Plan §R4]
- [x] CHK014 Os critérios de atualização de `docs/relatorios/o-que-falta.md` e `specs/001-autenticacao-acessivel/tasks.md` listam objetivamente todas as referências defasadas que devem ser reconciliadas (PRs #44–#58, Fase 11 da 003, permissão `INTERNET`, Docker/Render e fechamento de `T065a`/`T065b`/`T068`)? [Measurability, Spec §FR-013, §SC-005]
- [x] CHK015 Todos os 5 critérios de sucesso (`SC-001` a `SC-005`) possuem comandos ou verificações determinísticas correspondentes no guia `quickstart.md` (`V1` a `V5`)? [Measurability, Spec §SC-001..SC-005, Quickstart §V1..V5]

## Notes

- Marque os itens como concluídos (`[x]`) durante a revisão de requisitos ou validação final da PR.
- Adicione comentários ou evidências inline caso alguma decisão de design seja refinada.
