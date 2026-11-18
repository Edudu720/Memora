# Roteiro do Teste com 5 Pessoas de 65+ (T079 — SC-007 / V20)

Este roteiro consolida em uma única sessão prática por participante os portões manuais com pessoas reais de **65 anos ou mais**:

- **Feature 013 (V20 / SC-007)**: após 3 trocas de tela, pelo menos **4 de 5** pessoas sabem onde estão e como voltar.
- **Feature 001 (V10 — portão pendente)**: conclusão autônoma do cadastro em até 4 min (**90%**), zero dúvidas sobre significado de campos (**0**), recuperação de senha na 1ª tentativa (**85%**), sigilo de senha no modo assistido (**100%**).
- **Feature 002 (V7 e V8 — portões pendentes)**: **zero** campos de informação apontados como clicáveis no Perfil (`FR-012`, `SC-006`), nenhum toque acidental na `ConfirmacaoMemora` (`FR-013`, `SC-009`).
- **Features 003 e 004 (H12 / SC-002 a SC-004)**: repetir uma tarefa aprendida sem ajuda (**3/5**), ir da abertura à conversa sem ajuda em até 5 min (**4/5**), completar passo a passo, Ajuda e aumento de texto (**4/5**), média >= **4/5** em facilidade, confiança e estética.

---

## Regras de condução (para o aplicador)

1. **Sem treino prévio e sem dicas durante a tarefa.** Entregue o celular já aberto na tela inicial do aplicativo (ou na tela indicada pela tarefa) e leia apenas o enunciado de cada cenário em voz alta.
2. **Silêncio observador.** Se a pessoa travar por mais de 60 segundos ou pedir ajuda direta para prosseguir, anote o ponto de bloqueio e só então dê o menor empurrão possível — marcando a tarefa como "com ajuda".
3. **Registre toda pergunta feita em voz alta.** Conforme a regra da 001 (`V10`), qualquer pergunta do tipo *"isso aqui é botão?"* ou *"o que eu digito aqui?"* conta como defeito de clareza, mesmo quando a pessoa acerta depois.
4. **Conta de teste e privacidade.** Use dados fictícios de ambiente de validação; se o teste incluir o modo assistido, garanta que o acompanhante **não** enxerga nem digita a senha na etapa da entrega do aparelho.

---

## Materiais necessários

- Smartphone Android com **APK de release** instalado (ex.: Galaxy S20 FE / aparelho de referência).
- Internet ativa (para os cenários de conversa real / Localizador) e contato de teste preparado.
- Cronômetro (celular do aplicador) e cópia desta ficha de registro (uma por participante: `P1` a `P5`).

---

## Bloco de Tarefas (ordem sugerida: ~20–25 min por participante)

### Tarefa 1 — Boas-vindas, Cadastro assistido e Apresentação (`001 V10`, `013 FR-035`)
- **Enunciado**: *"Você acabou de baixar o Memora no celular. Crie sua conta com ajuda do acompanhante até a hora da senha e passe pelas telas iniciais até chegar no Início."*
- **Observar**:
  - Tempo até concluir cadastro (meta 001: <= 4 min).
  - Na tela "Entregar o aparelho", o acompanhante entende que deve passar o celular sem ver a senha (**100%**).
  - Na tela 1 da Apresentação ("O que eu nunca faço"), peça ao final para a pessoa dizer com as próprias palavras: *"Por onde a Memora conversa com você?"* (verificar se captou que **a Memora só fala dentro do aplicativo**, `FR-035`).
  - Registrar se alguma palavra ou campo gerou pergunta em voz alta.

### Tarefa 2 — Reconhecer Informação vs. Ação no Perfil (`002 V7 — SC-006`) e Foto de Perfil (`011`)
- **Enunciado (parte A — antes de tocar em nada)**: abra `Meu perfil` e diga: *"Sem tocar na tela, me aponte com o dedo tudo o que você acha que dá para apertar aqui e tudo o que é só leitura."*
- **Meta rigorosa**: **zero** campos informativos (`Seu nome`, `E-mail ou telefone`, `O que você mais aprendeu`, idade já salva) apontados como botão.
- **Enunciado (parte B)**: *"Agora tente colocar uma imagem sua ou um desenho da Memora para aparecer lá em cima no seu perfil, e depois diga como faria para tirar essa foto."*
- **Observar**: percepção clara das opções (`galeria`, `câmera`, `avatar da Memora`), entendimento do aviso de privacidade e confirmação dupla ao remover (`ConfirmacaoMemora` — **V8**).

### Tarefa 3 — Orientação e 3 trocas seguidas (`013 V20 / SC-007` — critério principal da 013)
- **Enunciado em sequência**:
  1. Partindo de `Início`, peça: *"Vá até onde você ajusta o tamanho da letra do aplicativo."* (Ajustes -> Aparência / Acessibilidade).
  2. Em seguida: *"Agora quero ver tudo o que o Memora faz, onde ficam os guias de aplicativos."* (voltar -> Início -> Ver tudo o que eu faço / Hub).
  3. Em seguida: *"Por último, abra o mapa/lista para procurar uma farmácia aqui perto."* (Localizador).
- **Perguntas de verificação ao final da 3ª troca (SEM ajuda visual do aplicador)**:
  - *"Em que parte do aplicativo você está agora?"*
  - *"O que você faria para voltar para a tela inicial do Memora?"* (pedir que execute o retorno).
- **Meta (`SC-007`)**: **>= 4 de 5 participantes** respondem corretamente onde estão e voltam com confiança (acompanhando a direção das transições e o rótulo do cabeçalho/barra inferior).

### Tarefa 4 — Conversa limpa e autonomia após ensinar (`003 H12`, `FR-051`)
- **Enunciado**: *"Pergunte para a Memora como fazer para mandar um áudio no WhatsApp (pode falar no microfone ou escrever). Depois tente seguir o que ela explicou."*
- **Observar**:
  - Entende o aviso de privacidade antes da primeira mensagem ("Antes de conversarmos", `FR-051`) e o resumo antigolpe no topo?
  - Percebe que a Memora está escrevendo e sabe onde tocar para perguntar?
  - Após fechar ou voltar, lembra os passos básicos sem depender de fazer por ela (`H12`).

### Tarefa 5 — Passo a passo e Ajuda + Ampliação (`004 SC-003`)
- **Enunciado**: *"Ache no Memora onde ele ensina passo a passo a usar um aplicativo e avance duas telas; depois vá em Preciso de ajuda e ache a dica de como agir numa ligação suspeita de golpe."*
- **Observar**: localização de `Avançar` / `Anterior`, resposta à conclusão comemorada pela Memora, clareza dos textos em até 2 frases.

### Tarefa 6 — Segurança: Confirmação irreversível (`002 V8`) e Recuperação / Cuidado
- **Enunciado A (`V8`)**: abra `Ajustes -> Privacidade -> Apagar conversa` (sem executar até o fim se quiser preservar histórico antes de revisar) e pergunte: *"Se você tocar nesse botão agora, o que acontece? Como você cancela sem apagar?"* (verificar leitura do texto acima da cor, zero toque acidental).
- **Enunciado B (`001 V10`)**: na tela de login, pedir *"Como você faria se tivesse esquecido a senha?"* e acompanhar até iniciar a recuperação na 1ª tentativa (meta: **85%**).
- **Enunciado C (`005` / `014`)**: abrir `Cuidado` / verificação simulada e pedir: *"Se essa tela tocar no seu celular quando você estiver bem, onde você toca?"* (avaliar clareza imediata de `"Estou bem"` vs `"Preciso de ajuda"`).

### Encerramento — Avaliação lida em voz alta (`004 SC-004`)
Leia exatamente estas três perguntas e peça nota de **1 (nada) a 5 (muito)**:
1. *"De 1 a 5, o Memora pareceu **fácil de usar**?"*
2. *"De 1 a 5, o Memora pareceu **confiável**?"*
3. *"De 1 a 5, você achou o aplicativo **bonito e agradável de olhar**?"*
4. Espaço aberto: *"Teve alguma palavra ou tela que deixou você na dúvida?"*

---

## Ficha de Registro por Participante (copiar para `P1` a `P5`)

| Campo | P1 | P2 | P3 | P4 | P5 | Meta |
|---|---|---|---|---|---|---|
| Idade | | | | | | 65+ anos |
| T1: Cadastrou sem ajuda? Tempo (min:seg) | | | | | | >= 90%, <= 4 min |
| T1: Perguntas sobre campos (qtd) | | | | | | **0** |
| T1: Entendeu canal único (`FR-035`: só no app)? | | | | | | Sim |
| T2: Campos informativos apontados como botão (`V7`) | | | | | | **0** |
| T2: Conseguiu escolher/trocar/remover foto/avatar? | | | | | | Sim |
| T3: Após 3 trocas, sabe onde está e volta (`V20`)? | | | | | | **>= 4 de 5** |
| T4: Aceite `FR-051` + pergunta + autonomia (`H12`) | | | | | | >= 3 de 5 repete só |
| T5: Passo a passo + Ajuda segurança + zoom (`004`) | | | | | | >= 4 de 5 |
| T6: Zero toque acidental em `ConfirmacaoMemora` (`V8`)? | | | | | | 100% |
| T6: Recupera senha na 1ª tentativa (`001`)? | | | | | | >= 85% |
| Nota — Fácil de usar (1–5) | | | | | | Média >= 4,0 |
| Nota — Confiável (1–5) | | | | | | Média >= 4,0 |
| Nota — Bonito (1–5) | | | | | | Média >= 4,0 |

### Anotações literais de falas e travamentos
- **P1**:
- **P2**:
- **P3**:
- **P4**:
- **P5**:
