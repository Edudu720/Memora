# Guia Rápido e Manual de Verificação: Feature 009 (Localizador de Serviços)

## 1. Visão Geral para o Desenvolvedor

Esta funcionalidade adiciona a capacidade de encontrar serviços públicos e de saúde essenciais próximos ao usuário, com total foco na autonomia de idosos e segurança contra fraudes.

---

## 2. Cenários de Uso e Testes Ponta a Ponta

### Cenário 1: Busca por Categoria com Localização Concedida
1. No Início ou Hub, toque no novo cartão de atalho *"Serviços Próximos"*.
2. Na primeira abertura, o Memora exibe o diálogo explicativo: *"Para te mostrar postos e farmácias perto da sua casa, a Memora precisa da sua localização"*.
3. Toque em *"Permitir localização"*.
4. O sistema exibe chips de categoria: toque em *"Saúde"*.
5. A tela carrega a lista ordenada de postos de saúde, farmácias e hospitais mais próximos com a distância exata em metros ou quilômetros.
6. Toque no botão de alternância *"Ver no mapa"* para visualizar os marcadores grandes em alto contraste.

### Cenário 2: Busca Manual Sem Conceder Localização (GPS Negado)
1. Na tela do Localizador, recuse a permissão de localização no Android.
2. O aplicativo não deve travar nem exibir alerta de erro; em vez disso, apresenta um campo claro e amplo: *"Digite sua cidade ou bairro"*.
3. Digite *"Jardim Ipiranga, Americana"* e toque em *"Buscar"*.
4. O sistema geocodifica o bairro e exibe os estabelecimentos locais da mesma forma.

### Cenário 3: Busca em Linguagem Natural
1. No campo de pesquisa superior, digite ou dite: *"Onde tomo vacina perto de mim?"*.
2. A IA (Gemini) classifica a intenção como `SAUDE`, com subfiltro de postos de vacinação/UBS.
3. Os postos de saúde da região são exibidos no topo da listagem.

### Cenário 4: Prevenção contra Ações Involuntárias (Rotas e Ligações)
1. No cartão do estabelecimento, toque em *"Como chegar"*.
2. **Validação**: O Memora **não abre** diretamente o aplicativo externo; exibe uma folha/diálogo com o botão primário: *"Abrir aplicativo de mapas para ver o caminho"* e botão secundário *"Voltar"*.
3. No mesmo cartão, caso haja telefone, toque em *"Ligar para o local"*.
4. **Validação**: Exibe confirmação com o número em destaque antes de acionar o discador nativo do telefone.

---

## 3. Comandos de Validação Automatizada

```powershell
# 1. Auditoria de tokens visuais e ausência de literais fora do DS 2.0
python specs/002-design-system/ferramentas/validar_tokens.py --autoteste
python specs/002-design-system/ferramentas/validar_tokens.py

# 2. Auditoria de contraste WCAG 2.2 em 13 combinações
python specs/002-design-system/ferramentas/validar_paleta.py --autoteste
python specs/002-design-system/ferramentas/validar_paleta.py

# 3. Análise estática do Flutter
cd app
flutter analyze

# 4. Suíte de testes automatizados do Localizador
flutter test test/features/localizador/
```
