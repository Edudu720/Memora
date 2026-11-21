# Checklist de Revisão Pré-PR (Qualidade dos Requisitos): Ajustes Pós-Redesenho — Issue #106

**Purpose**: Validar completude, clareza, consistência, mensurabilidade e cobertura de segurança, acessibilidade (`WCAG 2.2` / `memora-ux`) e integração entre equipe nos requisitos da feature antes de gerar tarefas e abrir PR para a `develop`.  
**Created**: 2026-11-19  
**Feature**: [spec.md](../spec.md) · [plan.md](../plan.md)

**Ownership & Lifecycle Note**: Este checklist é um artefato de revisão da qualidade dos **requisitos** (não é lista de testes manuais nem de execução de código), pertencente ao autor e aos revisores da PR (`@Edudu720` / `@Henrique-Sandrini`). O marcador `[x]` indica que o critério de qualidade dos requisitos foi avaliado e aprovado pelo revisor — nunca que o código está pronto. O comando `/speckit-implement` apenas consulta este estado sem alterar marcações.

---

## Segurança, Privacidade e Engenharia Social

- [x] CHK001 Os critérios de aceitação e rejeição do endereço oficial em `https://` na tela Ajuda (incluindo recusa a `http://`, espaços, credenciais embutidas no endereço, ausência de domínio ou URL dinâmica) estão completamente especificados sem lacunas? [Completeness, Spec §FR-017, Contract §ajuda-e-perfil]
- [x] CHK002 A exigência de exibir explicitamente o endereço de destino oficial dentro do diálogo de confirmação antes de deixar o aplicativo na Ajuda é consistente entre a especificação e o contrato de interface? [Consistency, Spec §FR-019, Contract §ajuda-e-perfil]
- [x] CHK003 A ambiguidade entre "executar localmente a verificação" versus "informar indisponibilidade" quando o dispositivo físico de cuidado está desconectado durante o teste de queda foi resolvida de forma determinística entre a especificação e as decisões do plano? [Ambiguity, Spec §FR-002, Research §R1]
- [x] CHK004 Os critérios de higienização de dados pessoais e campos de senha em branco cobrem objetivamente todas as 66 capturas reais dos 7 guias (incluindo telas de entrada por biometria/CPF e notificações) sem brechas interpretativas? [Completeness, Spec §FR-009, Contract §icones-e-guias]
- [x] CHK005 As restrições de ausência de tráfego externo na abertura de Meu Perfil e preservação do armazenamento estritamente local para dados pessoais opcionais são consistentes entre requisitos, critérios de sucesso e modelo de dados? [Consistency, Spec §FR-014, §FR-016, §SC-005]
- [x] CHK006 O comportamento exigido quando o armazenamento local traz um identificador de retrato aposentado ou corrompido define claramente a preservação dos demais dados da conta e ausência de erro exposto? [Completeness, Spec §FR-006, Edge Cases]

## UX Sênior, Acessibilidade (`WCAG 2.2` + `memora-ux`) e Linguagem Clara

- [x] CHK007 Os requisitos dimensionais de acessibilidade (alvos mínimos de toque, espaçamento, contraste `4,5:1`/`3:1` e adaptação a `200%` de fonte em telas pequenas) contemplam também o diálogo modal do site na Ajuda em `320×568` sem corte? [Coverage, Spec §AC-001..AC-003, Research §R7]
- [x] CHK008 O conceito de "melhoria visual e otimização de hierarquia em cartões mais claros" para Meu Perfil (após `Q1: A`) está traduzido em critérios objetivos e verificáveis (agrupamento por tema, unicidade visual do nome e campos informativos não clicáveis)? [Clarity, Spec §FR-015, Contract §ajuda-e-perfil]
- [x] CHK009 Os anúncios semânticos para leitores de tela cobrem todas as novas regiões e transições de estado (erro amigável ao abrir o site na Ajuda, botão oculto vs visível, seção de aprendizado em Meu Perfil e alerta/indisponibilidade na simulação de queda)? [Gap, Spec §AC-004]
- [x] CHK010 Os requisitos de contraste (`>= 3:1`) e independência de cor para os 7 novos ícones vetoriais e cartões de Meu Perfil especificam comportamento esperado tanto no tema claro quanto nos temas escuro e alto contraste? [Completeness, Spec §AC-002, §AC-005, Contract §icones-e-guias]
- [x] CHK011 A restrição de linguagem simples (`<= 2` frases curtas por bloco, gênero neutro, zero emojis e ausência de termos técnicos, Wokwi ou palavras sobre planos/assinaturas) está aplicada de maneira uniforme a todos os fluxos tocados? [Consistency, Spec §FR-004, §FR-021, Contract §ajuda-e-perfil]
- [x] CHK012 O requisito de respeito à preferência por redução de movimento define claramente se abrange também novas aberturas de verificação de queda e transições/diálogos em Meu Perfil e Ajuda? [Clarity, Spec §AC-006]

## Qualidade dos 7 Guias Reais e Ícones Vetoriais

- [x] CHK013 Os critérios que distinguem guias lineares (3–7 passos) de guias seccionados (> 7 capturas, com 3–7 passos por seção e identificadores únicos) estão definidos de forma exata para cada um dos 7 guias do escopo? [Completeness, Spec §FR-008, §FR-010, DataModel §3]
- [x] CHK014 As regras de alinhamento da área de destaque e proibição de marcações pintadas na imagem estão objetivamente especificadas junto à obrigatoriedade de descrição acessível em 100% dos passos? [Measurability, Spec §FR-009, §SC-004]
- [x] CHK015 Os requisitos dos 7 ícones vetoriais definem critérios mensuráveis de compatibilidade (proporção quadrada autocontida, ausência de scripts ou fontes externas, substituição de desenhos manuais sem alterar ativos de terceiros)? [Completeness, Spec §FR-012, Contract §icones-e-guias]
- [x] CHK016 O conflito entre o teto herdado de `8 MB` para o conjunto de capturas e a soma real medida (`~10,94 MB` com os 16 guias em qualidade preservada) está explicitamente documentado e justificado entre especificação, plano e contrato legado? [Conflict, Spec §Assumptions, Plan §Complexity Tracking, Contract §icones-e-guias]

## Cobertura de Cenários de Exceção e Recuperação

- [x] CHK017 Os cenários de falha externa ao confirmar saída para o site tutorial na Ajuda (aparelho sem navegador compatível ou falha de abertura) definem recuperação clara sem travar nem fechar a tela atual? [Coverage, Spec §FR-020, Edge Cases]
- [x] CHK018 Os requisitos do Dispositivo de Cuidado tratam explicitamente cenários de toque duplo rápido no teste de queda e cancelamento seguro (*"Estou bem"*) com o dispositivo físico desconectado? [Coverage, Spec §FR-003, Edge Cases, Contract §ajuda-e-perfil]
- [x] CHK019 O comportamento durante leitura assíncrona inicial ou troca rápida de conta ativa na tela Meu Perfil (ausência de aviso provisório ruidoso antes dos dados locais carregarem e descarte de leituras antigas) está devidamente especificado? [Gap, Research §R6]
- [x] CHK020 O caminho de recuperação completo após retorno automático para o retrato padrão neutro garante seleção e persistência de qualquer retrato válido restante ou foto própria sem resíduos da preferência aposentada? [Coverage, Spec §FR-007, Spec §US2]

## Fronteiras de Escopo e Integração com a Equipe (Issue #106)

- [x] CHK021 O contrato de nomenclatura e pasta compartilhada para os ícones vetoriais fornece definição estável suficiente para que o Item 13 (`e-Título`, `FGTS` e `Instagram`) se integre depois sem conflito nos arquivos modificados agora? [Dependency, Plan §Summary, Contract §icones-e-guias]
- [x] CHK022 A reserva estrutural em Meu Perfil para o indicador futuro *"último módulo concluído"* (Item 14) está especificada de modo a não exibir textos vazios ou enganosos enquanto o indicador ainda não existir? [Consistency, Spec §FR-016, DataModel §4]
- [x] CHK023 A premissa de manter intactas as ilustrações homônimas usadas fora da escolha de retrato em Meu Perfil (Ajuda, Conta e galeria do Design System) está validada para evitar regressões em fluxos de outros colaboradores? [Assumption, Research §R2]
- [x] CHK024 Todas as exclusões resultantes das decisões `Q1: A, Q2: A, Q3: A` (nenhum novo aplicativo no catálogo, sem edição de nome em Meu Perfil, sem URL publicada antes do deploy do Item 14b e exclusão dos itens de `@Edudu720`/`@Henrique-Sandrini`) possuem rastreabilidade completa até a Issue #106? [Traceability, Spec §Clarifications, §Assumptions]

---

## Notes

- Marque os itens concluídos pelos revisores substituindo `[ ]` por `[x]`.
- Registre eventuais achados, lacunas ou ajustes diretamente abaixo do item correspondente antes de iniciar `/speckit-implement`.
- Itens enumerados sequencialmente (`CHK001`–`CHK024`) para facilitar referências em comentários da PR na `develop`.
- Artefatos relacionados: [spec.md](../spec.md) · [plan.md](../plan.md) · [research.md](../research.md) · [data-model.md](../data-model.md) · [contracts/icones-e-guias.md](../contracts/icones-e-guias.md) · [contracts/ajuda-e-perfil.md](../contracts/ajuda-e-perfil.md) · [checklists/requirements.md](requirements.md)

### Registro da revisão (2026-11-19)

Todos os **24 critérios (`CHK001`–`CHK024`)** foram auditados como pertinentes ao projeto e marcados após quatro ajustes redacionais aplicados diretamente em [spec.md](../spec.md) e [ajuda-e-perfil.md](../contracts/ajuda-e-perfil.md):

1. **`CHK002` (`FR-019`)**: explicitada na `spec.md` a exibição visível do endereço oficial de destino dentro do diálogo modal de confirmação na Ajuda antes de sair do aplicativo.
2. **`CHK003` (`US1` Cenário 3, `FR-002`, `SC-001`, `Edge Cases`)**: eliminada a ambiguidade *"ou informar claramente o motivo"* com o dispositivo físico desconectado — ficou determinístico que o ensaio de queda inicia sempre localmente em menos de 1 s de forma cancelável e com proteção contra duplo toque.
3. **`CHK009` (`AC-004` e `Contract §ajuda-e-perfil §3`)**: explicitada cobertura semântica para cabeçalhos das seções de Meu Perfil e anúncio em leitor de tela (`liveRegion: true`) nos avisos de erro amigável da Ajuda.
4. **`CHK019` (`Edge Cases` e `Contract §ajuda-e-perfil §2`)**: documentados o descarte de leituras locais obsoletas em troca rápida de conta e a ausência de marcadores provisórios ruidosos na carga inicial de Meu Perfil.
