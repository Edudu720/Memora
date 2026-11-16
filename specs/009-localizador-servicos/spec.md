# Feature 009 — Localizador de Serviços

**Feature Branch**: `feature/009-localizador-servicos`  
**Status**: Em Revisão — PR #71  
**Nota de Reconciliação (`specs/010-revisao-pr71-localizador`)**: Conforme revisão da PR #71 (`FR-011`/`FR-012`), a interpretação de intenção em linguagem natural no servidor é executada localmente e de forma determinística por palavras-chave em `InterpretadorDeIntencaoPorPalavrasChave`, sem chamadas à API do Google Gemini originalmente prevista em `NFR-005` / `plan.md`.

## Objetivo

Permitir que pessoas idosas encontrem serviços essenciais próximos (saúde, serviços públicos, emergência e conveniências cotidianas), utilizando localização geográfica assistida e autorizada ou pesquisa manual por cidade/bairro/endereço, com apresentação simplificada das informações, total proteção de privacidade e orientação acessível.

---

## Requisitos Funcionais (FR)

- **FR-001**: Disponibilizar um módulo denominado **Localizador de Serviços** acessível a partir do Hub e do Início do Memora.
- **FR-002**: Permitir pesquisa rápida por categorias essenciais iniciais:
  1. *Saúde* (hospitais, UBS/postos de saúde, farmácias, clínicas);
  2. *Serviços públicos* (Poupatempo, INSS, Correios, CRAS/assistência social, cartórios);
  3. *Emergência* (delegacias, bombeiros, pronto-socorro);
  4. *Serviços cotidianos* (bancos/caixas, supermercados, padarias).
- **FR-003**: Permitir pesquisa por necessidade expressa em linguagem natural (ex.: *"Onde tomo vacina perto de mim?", "Preciso achar uma farmácia que entrega", "Onde tiro minha carteira de identidade"*).
- **FR-004**: Solicitar autorização do sistema antes de acessar a localização do dispositivo, explicando de forma prévia e pedagógica o motivo (Princípio II da Constituição).
- **FR-005**: Permitir informar manualmente cidade, bairro ou endereço de referência sem exigir localização automática.
- **FR-006**: Identificar estabelecimentos e pontos de serviço compatíveis com a pesquisa a partir de fontes de dados externas reais e identificáveis.
- **FR-007**: Apresentar nome do local, endereço formatado e distância estimada quando disponíveis.
- **FR-008**: Apresentar telefone de contato e horário de funcionamento quando houver dados confiáveis e verificáveis.
- **FR-009**: Permitir visualizar os estabelecimentos encontrados em mapa interativo e simplificado de alto contraste.
- **FR-010**: Permitir consultar orientações de deslocamento (rotas a pé, ônibus ou carro), abrindo aplicativo externo de mapas mediante confirmação explícita.
- **FR-011**: Informar claramente quando dados de funcionamento não estiverem disponíveis, estiverem incompletos ou não forem recentes (Princípio da Verdade e Transparência).
- **FR-012**: Permitir iniciar uma ligação telefônica para o estabelecimento exclusivamente mediante ação e confirmação explícita do usuário (prevenção contra discagem acidental).
- **FR-013**: Disponibilizar alternativa de pesquisa por texto/bairro sempre que a localização estiver desativada ou for negada.
- **FR-014**: Permitir refazer ou refinar a pesquisa em outra região de forma simples e direta.
- **FR-015**: Preservar a privacidade da localização do usuário: não rastrear em segundo plano, não enviar coordenadas desnecessárias e não persistir localização precisa permanente no servidor.

---

## Requisitos Não Funcionais (NFR)

- **NFR-001**: Respeitar o **Design System 2.0** do Memora (Tokens 2.0, `Cartao`, `TileAcaoRapida`, `BadgeDeStatus`, `PainelHeroi`, `ChipFiltro`, cores semânticas e componentes de toque).
- **NFR-002**: Respeitar as diretrizes de acessibilidade sênior: fonte mínima de `16 sp` (`AtkinsonHyperlegibleNext`), suporte a escala de texto até `200%` sem overflow e alvos de toque `>= 48×48 dp` (`56 dp` em botões de ação primária).
- **NFR-003**: Não condicionar a utilização do recurso à ativação do GPS; a pesquisa manual por cidade/bairro deve ser cidadã de primeira classe.
- **NFR-004**: Utilizar fontes de dados identificáveis e confiáveis (ex.: OpenStreetMap/Overpass API, Google Places, bases abertas governamentais SUS/CNES).
- **NFR-005**: **A IA não inventa estabelecimentos**. A IA (Gemini) interpreta a intenção da necessidade em linguagem natural, mas os estabelecimentos retornados devem provir estritamente de APIs e bases geográficas reais.
- **NFR-006**: Conformidade estrita com a LGPD: não armazenar histórico de coordenadas geográficas precisas vinculadas à pessoa usuária no banco de dados.
- **NFR-007**: Resiliência e degradação suave: tratar indisponibilidade de internet, falhas de GPS ou timeouts dos provedores de mapa com mensagens claras e sem jargões.
- **NFR-008**: Segurança contra ações involuntárias: nenhuma rota ou ligação telefônica pode ser iniciada automaticamente sem confirmação.

---

## Critérios de Aceitação (AC)

- **AC-001**: O usuário consegue pesquisar serviços tocando em chips de categoria (*Saúde*, *Serviços públicos*, *Emergência*, *Serviços cotidianos*).
- **AC-002**: O usuário consegue digitar ou ditar sua necessidade em linguagem natural e o sistema interpreta a categoria e termos de busca corretos.
- **AC-003**: Com autorização prévia concedida, o aplicativo obtém a localização aproximada/atual e ordena os resultados pela menor distância.
- **AC-004**: Quando a permissão de localização é negada ou o GPS está desligado, o aplicativo oferece campo claro para digitar cidade ou bairro sem exibir erro bloqueante.
- **AC-005**: Cada cartão de resultado exibe nome, endereço, categoria em badge tonal e distância em quilômetros/metros.
- **AC-006**: O usuário pode alternar entre a exibição em lista e a visualização em mapa de alto contraste.
- **AC-007**: Ao tocar em *"Como chegar"*, o app avisa que abrirá o mapa do celular e pede confirmação antes de disparar o intent externo.
- **AC-008**: Quando o horário ou telefone do estabelecimento não constar na base, o cartão exibe *"Horário não informado pelo local"* em vez de omitir ou inventar dados.
- **AC-009**: Nenhuma coordenada precisa é salva na tabela de banco de dados do usuário.
- **AC-010**: A interface mantém contraste WCAG 2.2 AA/AAA em todos os temas (Claro, Escuro e Alto Contraste).

---

## Fora do Escopo Inicial

- Agendamento de consultas médicas ou atendimento presencial.
- Integração com prontuários eletrônicos ou sistemas do SUS.
- Reservas de mesas ou vagas.
- Pagamentos, compras ou transações financeiras no app.
- Rastreamento contínuo em segundo plano (background location tracking).
- Garantia de disponibilidade de leitos ou estoque de remédios em tempo real.
