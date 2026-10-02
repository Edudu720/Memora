# Quickstart: validar o redesenho

Cenários que provam que a feature funciona. Cada um diz **como rodar**, **o que
esperar** e qual requisito cobre. A tabela "Onde cada cenário roda", no fim,
aponta o teste automatizado de cada um, e é preenchida durante a implementação,
como nas features 002 e 003.

## Pré-requisitos

```powershell
cd app; flutter pub get
```

Para os cenários no aparelho, o emulador Pixel_6 de pé (ver seção 5.1 do
`CLAUDE.md`). Para o V12, o Docker rodando.

## Verificação completa

```powershell
cd app; flutter analyze; flutter test
```

```powershell
py specs/002-design-system/ferramentas/validar_paleta.py; py specs/002-design-system/ferramentas/validar_tokens.py; py specs/002-design-system/ferramentas/validar_tokens.py --autoteste
```

```powershell
$env:JAVA_HOME = "C:\Program Files\Java\jdk-21"; cd backend; .\mvnw clean test
```

---

## Cenários

### V1 — A pessoa não vê o andaime (FR-007, SC-009)

`flutter run` sem `--dart-define`. **Espera-se**: a primeira tela é a de
boas-vindas, sem aba "Componentes" nem "Aparência". Em build de release, nenhum
caminho leva à galeria.

### V2 — Do convite à primeira conversa (US1, FR-009 a FR-013)

Criar uma conta nova no emulador. **Espera-se**: depois do cadastro, três telas
de apresentação com "Continuar" e "Pular"; ao fim, o Início. Sair, entrar de
novo: a apresentação **não** volta. Ajuda → "Ver a apresentação de novo": volta.
Fechar o aplicativo no meio da apresentação de uma conta nova: ela recomeça.

### V3 — Início, Hub e o caminho de volta (US2, FR-014 a FR-019, SC-006)

**Espera-se**: o Início cumprimenta pelo nome. A barra inferior aparece em toda
tela interna, com desenho e nome nos três destinos. O Hub mostra as cinco portas
sem rolar, em 100% e 150%, no 320×568. Nenhuma tela está a mais de 3 toques do
Início. "Sair" não aparece no Hub nem no Início.

### V4 — A conversa recupera espaço (US3, FR-020 a FR-022, R5)

Na matriz de aparelhos, em 100% e 150%. **Espera-se**: lista de mensagens +
campo de escrever ≥ 50% da altura disponível; o título do aviso sempre
presente; "Ler o aviso inteiro" expande e o aviso aberto não passa de 50%.
**Provar quebrando**: devolver o aviso antigo (expandido sempre) e ver o portão
reprovar.

### V5 — Aprender um aplicativo (US4, FR-023 a FR-029)

Em "Meus aplicativos", buscar "tik" e "TIK". **Espera-se**: o TikTok aparece nas
duas. Tocar: passo a passo com "Passo 1 de N", selo "Exemplo" na captura,
destaque no ponto a tocar, "Voltar" e "A minha tela está diferente" em todo
passo; "A minha tela está diferente" mostra o aviso de golpe **antes** da
conversa, mesmo sem internet. Último passo: parabéns, "Voltar ao Hub" e, com
conexão, "Peça à Memora para abrir o TikTok", que vai pela conversa, com a
confirmação e o aviso de saída de sempre. Sem conexão, essa oferta não
aparece. Com o TikTok **não instalado**: o guia
começa pela loja oficial. Em nenhum momento o Android pede permissão de
sobreposição.
Com o modo avião ligado depois de uma abertura com internet, "Meus aplicativos"
e "Serviços sociais" mostram a última lista, e o passo a passo abre (FR-024a).

### V6 — Serviços sociais só se ensinam (US5, FR-030 a FR-032)

**Espera-se**: os nove serviços, com pictograma e nome, nenhum logotipo oficial
na lista. No guia do Gov.br: o primeiro passo diz o que ter em mãos; o passo da
tela de senha mostra o aviso de que a senha só se digita no aplicativo oficial.
Nenhum botão "Abrir" em serviço sensível.

### V7 — Ajuda (US6, FR-033 a FR-037)

**Espera-se**: os assuntos com desenho e nome; "A conversa" abre o exemplo
guiado com saída para a conversa real; "Segurança" mostra as dicas uma por vez,
incluindo o que o Memora nunca faz (FR-036a). **Sem** `MEMORA_URL_DOWNLOAD`,
"Compartilhar" não aparece. Com ele, aparece e avisa antes de abrir a folha de
compartilhamento, que leva só o endereço oficial.

### V8 — Configurações (US7, FR-038 a FR-041)

**Espera-se**: Aparência, Privacidade e Conta, e nada de "Notificações" nem
"Idiomas". Aparência pré-visualiza antes de confirmar. Privacidade apaga a
conversa **só depois das duas etapas** da confirmação irreversível — um toque
não apaga nada. Conta mostra o canal, e "Sair" pergunta antes.

### V9 — Perfil sem dado novo (US8, FR-042 a FR-042b)

Conta nova: a linha do aplicativo mais aprendido diz que ainda vão aprender
juntos. Concluir o guia do TikTok duas vezes e o do WhatsApp uma: aparece o
TikTok. **Sair e entrar de novo**: a linha volta a dizer que ainda vão aprender
— o progresso saiu com a conta. Nenhum campo de idade ou plano. Nenhuma
requisição nova ao servidor ao abrir o Perfil.

### V10 — Nada estoura, em nenhum lugar (FR-043 a FR-046, SC-007)

```powershell
cd app; flutter test test/features
```

**Espera-se**: toda tela nova passa na matriz de 4 aparelhos × 3 escalas × 3
temas, com a ação principal alcançável. Com "reduzir movimento" ligado, nenhuma
animação nova roda.

### V11 — Os portões antigos continuam de pé (FR-047, SC-008)

A verificação completa, acima. **Espera-se**: os 481 testes do aplicativo e os
361 do backend que existiam em 2026-10-01 continuam passando — os que mudaram
de forma (procurar o título do aviso em vez do texto inteiro, R5; testar a
saída na tela de Conta em vez da `TelaPerfil`) estão listados no PR, com o
motivo.

### V12 — A V8 e a ponte entre catálogo e guias (R8, contrato do catálogo)

```powershell
$env:JAVA_HOME = "C:\Program Files\Java\jdk-21"; cd backend; .\mvnw clean test
```

**Espera-se**: a V8 sobe, as 8 linhas antigas têm `chave`, as novas sensíveis
estão sem pacote. **Provar quebrando**: acrescentar uma `chave` ao
`RepositorioAssistenteSimulado` sem a migration correspondente (ou o
contrário) e ver o teste de ligação do aplicativo reprovar com o nome da chave.
O teste lê só `backend/src/main/resources/db/migration/` — não existe
"migration de teste".

### V13 — A revisão de design (SC-005)

```powershell
cd app; flutter test test/album
```

Gera `app/build/album/`, com cada tela em cada tema. **Espera-se**: os três
integrantes comparam o álbum, tela a tela, com o de hoje e com o wireframe, e
aprovam. Registrar a aprovação no PR da fase.

### V14 — Cinco pessoas de 65+ (SC-002 a SC-004)

Sem instrução e sem ajuda: chegar à primeira conversa; aprender um aplicativo
pelo passo a passo; achar uma dica de segurança; aumentar o texto. Depois, as
três notas de 1 a 5, lidas em voz alta. **Espera-se**: 4 de 5 completam cada
tarefa, e a média de cada nota é ≥ 4.

---

## Onde cada cenário roda

*Preenchido durante a implementação.*

| Cenário | Teste | Situação |
|---|---|---|
| V1 | — | — |
| V2 | — | — |
| V3 | — | — |
| V4 | — | — |
| V5 | — | — |
| V6 | — | — |
| V7 | — | — |
| V8 | — | — |
| V9 | — | — |
| V10 | — | — |
| V11 | Verificação completa | — |
| V12 | — | — |
| V13 | `test/album/album_de_telas_test.dart` | — |
| V14 | Pessoas | — |
