# PR Review Checklist: Foto de Perfil da Pessoa Usuária (`011-foto-perfil`)

**Purpose**: Revisão formal da qualidade, clareza, segurança, acessibilidade e consistência dos requisitos antes da implementação e do Pull Request  
**Created**: 2026-11-16  
**Feature**: [spec.md](file:///c:/Users/Eduardo/Memora/specs/011-foto-perfil/spec.md) | [plan.md](file:///c:/Users/Eduardo/Memora/specs/011-foto-perfil/plan.md) | [data-model.md](file:///c:/Users/Eduardo/Memora/specs/011-foto-perfil/data-model.md)  
**Audience**: Autor e revisores no PR (pré-`/speckit-implement`) | **Depth**: Padrão (18 itens críticos)

> **Nota de ciclo de vida**: Este checklist avalia a qualidade da **especificação e do desenho técnico**, e não a execução do código. A marcação `[x]` indica que o revisor validou o critério nos documentos; `/speckit-implement` lê este estado sem alterar os marcadores.

## Segurança, Privacidade e Ciclo de Vida Local

- [x] CHK001 Os critérios de validação de formato em [Spec §FR-005](file:///c:/Users/Eduardo/Memora/specs/011-foto-perfil/spec.md#L145) e [Data Model](file:///c:/Users/Eduardo/Memora/specs/011-foto-perfil/data-model.md#L56) especificam de forma inequívoca a recusa por assinatura binária real e o comportamento para variantes como WebP animado ou HEIC? [Clarity, Spec §FR-005, Data Model]
- [x] CHK002 Os tetos numéricos de entrada (`15 MB`) e saída normalizada (`512×512 px`) estão definidos de modo consistente entre requisitos, casos de borda e critérios mensuráveis? [Consistency, Spec §FR-005, Spec §SC-003]
- [x] CHK003 O requisito de remoção obrigatória de metadados EXIF contempla explicitamente a preservação da orientação visual correta antes do descarte das tags de câmera/GPS? [Completeness, Spec §FR-005, Plan §R2]
- [x] CHK004 As regras de isolamento por identificador de conta e prevenção contra travessia de caminho na gravação local estão completamente documentadas nos contratos de persistência? [Completeness, Spec §FR-007, Data Model]
- [x] CHK005 Os gatilhos de preservação na saída comum versus expurgo definitivo em "Sair e esquecer este aparelho" ou exclusão de conta são consistentes entre a especificação e o fluxo existente do aplicativo? [Consistency, Spec §FR-009, Plan]

## UX, Linguagem Clara e Acessibilidade (65+ anos)

- [x] CHK006 A regra de seleção do Retrato Padrão ("silhueta acolhedora ou iniciais do nome") está objetivamente definida para quando há nome válido versus quando o nome está ausente? [Clarity, Spec §FR-001, Data Model]
- [x] CHK007 Todos os estados de interação (colocar, folha de escolha, pré-visualização, troca, confirmação de remoção e grade de avatares) definem controles com ícone + rótulo textual explícito, área mínima de toque (≥ 48×48 dp) e espaçamento mínimo (≥ 8 dp)? [Completeness, Spec §FR-002]
- [x] CHK008 Os requisitos visuais de contraste (WCAG 2.2 AA nos três temas), borda de destaque do círculo e integridade de layout até 200% de fonte cobrem também a tela de pré-visualização e a grade de avatares? [Coverage, Spec §Acessibilidade, Contracts §4]
- [x] CHK009 As descrições semânticas para leitores de tela distinguem claramente o estado com retrato pessoal, o estado com avatar ilustrado e o Retrato Padrão sem ruído redundante? [Clarity, Spec §Acessibilidade, Contracts §4]
- [x] CHK010 O posicionamento e o texto da explicação integrada de privacidade na folha de escolha de origem evitam sobreposição com outros diálogos antes da abertura de galeria/câmera? [Consistency, Spec §FR-004, Plan §R5]

## Cobertura de Cenários, Permissões e Falhas

- [x] CHK011 O fluxo de negação permanente ou temporária de permissão define alternativas acessíveis imediatas (abertura de configurações do aparelho e opção de avatar sem permissão) para ambas as origens de mídia? [Coverage, Spec §FR-011, Plan §R5]
- [x] CHK012 O comportamento esperado quando a pessoa cancela na pré-visualização ("Escolher outra") versus quando cancela no seletor nativo do sistema está claramente especificado sem perda do retrato anterior? [Coverage, Spec §US1, Spec §FR-011]
- [x] CHK013 Os requisitos de recuperação tratam explicitamente o cenário de arquivo local ausente ou corrompido no disco sem expor mensagem técnica nem quebrar a tela de Perfil? [Coverage, Spec §FR-007, Spec §Edge Cases]
- [x] CHK014 O tratamento de concorrência contra múltiplos toques durante seleção, processamento em lote/isolado e remoção está especificado com regras objetivas de bloqueio? [Completeness, Spec §FR-012, Contracts §4]
- [x] CHK015 O comportamento caso a sessão expire por inatividade enquanto a pessoa utiliza a câmera ou galeria externa do sistema operacional está documentado como fluxo de exceção/recuperação? [Gap, Exception Flow]

## Consistência Arquitetural e Contratos

- [x] CHK016 Os limites de escopo ("apenas armazenamento local no aparelho" e "exibição apenas em Meu Perfil") mantêm consistência estrita em todas as seções, preservando intactos os contratos OpenAPI e o cabeçalho da tela de Início? [Consistency, Spec §FR-006, Spec §FR-010, Plan]
- [x] CHK017 A coleção fechada de avatares ilustrados reutilizados no plano está totalmente mapeada para ativos licenciados existentes sem introdução de dependências ou licenças externas não documentadas? [Dependencies, Research §R4, Data Model §2]
- [x] CHK018 Os critérios mensuráveis de sucesso (`SC-001` a `SC-006`) possuem referências rastreáveis aos cenários automatizáveis definidos no guia de validação? [Measurability, Spec §SC-001..SC-006, Quickstart]

## Notes

- Checklist revisado em `2026-11-16`: `18/18` itens validados e marcados (`[x]`) após o ajuste das 3 lacunas identificadas inicialmente (`CHK001`, `CHK005` e `CHK015`) em `spec.md` e `data-model.md`.
