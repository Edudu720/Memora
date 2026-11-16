# Phase 0: Research & Technical Feasibility

## Contexto e Desafios de Engenharia

O módulo **Localizador de Serviços** precisa atender a idosos brasileiros com limitações visuais e motoras, operando sob conexões móveis variáveis e garantindo total respeito à privacidade conforme a LGPD e a Constituição do Memora.

### Questões Críticas Resolvidas:

1. **Seleção de Provedor de Dados Geográficos e Estabelecimentos**:
   - **Opção A: Google Places API / Google Maps SDK**:
     - *Prós*: Cobertura ampla no Brasil, riqueza de horários e telefones.
     - *Contras*: Custo por requisição elevado (Places Details + Geocoding), dependência de chaves de API pagas e SDK proprietário pesado.
   - **Opção B: OpenStreetMap (Nominatim para geocodificação + Overpass API para POIs) + Flutter Map (Leaflet / flutter_map)**:
     - *Prós*: 100% de código aberto, sem custos por chave de API comercial no ambiente acadêmico, privacidade total (sem rastreamento de perfil Google), suporte nativo a tiles OpenStreetMap / CartoDB Voyager de alto contraste, compatível com o ecossistema Flutter.
     - *Decisão*: **Estratégia Híbrida / Adapter Pattern no Backend**:
       - O backend define uma porta (`ProvedorGeografico`) com implementação padrão baseada em **OpenStreetMap / Nominatim / Overpass API** (com cache de POIs em memória para evitar sobrecarga) e suporte opcional a Google Places via configuração de profile (`application-googlemaps.properties`).
       - No frontend Flutter: utilização do pacote maduro e acessível **`flutter_map`** com tiles em camadas de alto contraste, sem dependências nativas binárias fechadas.

2. **Interpretação de Linguagem Natural vs Alucinação de Dados (NFR-005 & Princípio VI)**:
   - *Desafio*: O usuário pode digitar: *"Onde tomo a vacina da gripe?"* ou *"Preciso de uma farmácia com remédio de pressão"*.
   - *Solução Arquitetural*:
     - O backend aciona o **Gemini API (`gemini-3.8-flash`)** estritamente na etapa de **NLU (Natural Language Understanding) / Extração de Intenção**:
       - Input: Consulta em linguagem natural do usuário.
       - Output JSON Estruturado: Categoria normalizada (`SAUDE`, `SERVICOS_PUBLICOS`, `EMERGENCIA`, `COTIDIANO`) + Termo/Tag OSM de busca (ex.: `amenity=pharmacy`, `amenity=clinic`, `amenity=hospital`, `healthcare=yes`) + Raio de busca sugerido.
     - **Nunca** a IA gera a lista de estabelecimentos, telefones ou endereços. Os estabelecimentos retornados ao usuário provêm exclusivamente da consulta geoespacial direta feita aos dados do provedor externo.

3. **Consentimento e Privacidade de Localização (FR-004, FR-015, LGPD)**:
   - *Desafio*: Permissões de GPS no Android costumam assustar pessoas idosas se disparadas de forma abrupta.
   - *Solução*:
     - **Diálogo Pedagógico Prévio**: Antes de invocar a permissão do sistema (`geolocator`), o Memora exibe uma tela/modal acolhedor explicando: *"Para achar os postos e farmácias perto da sua casa, a Memora precisa saber sua localização aproximada. Se preferir não ativar, basta digitar o nome do seu bairro ou cidade."*
     - **Pesquisa Manual Cidadã de Primeira Classe**: Se a pessoa recusar, a busca manual por cidade/bairro calcula o centróide via Nominatim geocoding e exibe os estabelecimentos com a mesma facilidade.
     - **Zero Persistência de Localização**: As coordenadas `(lat, lon)` viajam no payload POST apenas para o cálculo dos estabelecimentos mais próximos e a resposta da rota. Nenhuma tabela do banco de dados armazena a localização histórica ou o rastro do usuário.

4. **Acessibilidade e Usabilidade Sênior na Visualização de Mapa (NFR-001, NFR-002)**:
   - *Desafio*: Mapas comuns de celular possuem ícones minúsculos e gestos de pinça difíceis para mãos com tremor ou artrite.
   - *Solução*:
     - **Lista como Visualização Padrão**: Os resultados sempre abrem primeiro como **lista de cartões amplos**, ordenados por proximidade.
     - **Alternância Simples**: Botão de alternância em pílula destacada: *"Ver em lista"* e *"Ver no mapa"*.
     - **Controles de Zoom Grandes**: Botões dedicados `+` e `-` com alvos táteis de `56×56 dp` no canto do mapa, dispensando o gesto de pinça com dois dedos.
     - **Marcadores Gigantes com Ícone Temático**: Marcadores visuais com cores da categoria (ex.: Cruz vermelha para Saúde, Brasão azul para Serviços Públicos) e balão expandido ao tocar.
     - **Abertura de Rotas Externa Segura**: Ao tocar em *"Como chegar"*, exibe diálogo de confirmação: *"A Memora vai abrir o aplicativo de mapas do seu celular para te mostrar o caminho até [Nome do Local]. Deseja continuar?"* disparando um `geo:lat,lon?q=...` ou `Intent` seguro.
