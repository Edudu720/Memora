# Roteiro de validação — feature 010

Como provar que a 010 está pronta. Cada cenário aponta o requisito e onde ele
roda. Os automatizados entram no CI; os manuais são no celular (S20 FE, APK de
release) e fazem parte da revisão do Henrique (portão da T116 da 004).

## Antes de tudo

```powershell
cd app; flutter analyze; flutter test
py specs/002-design-system/ferramentas/validar_paleta.py
py specs/002-design-system/ferramentas/validar_tokens.py
```

## Cenários

| # | Cenário | Requisitos | Onde roda |
|---|---|---|---|
| **V1** | A Memora aparece em cada expressão, nos 3 temas, com contorno ≥ 3:1 | FR-001, FR-002, FR-007 | `memora_animada_test.dart` + galeria + `validar_paleta.py` |
| **V2** | Com "reduzir movimento", a Memora fica parada e nenhum gesto acontece ao toque | FR-004, FR-005d | `memora_animada_test.dart` |
| **V3** | A Memora não aparece para o leitor de tela, nem o toque nela | FR-005, FR-005b | `memora_animada_test.dart` (árvore de semântica) |
| **V4** | Tocar na Memora acena/pisca, não navega, e toques durante o gesto são ignorados | FR-005a | `memora_animada_test.dart` |
| **V5** | A Memora fica a ≥ 8 dp de qualquer alvo de toque, em cada tela em que aparece | FR-005c | `memora_distancia_test.dart`, na matriz de aparelhos |
| **V6** | Avançar desliza da direita, voltar da esquerda, e a tela que sai não recebe toque | FR-009, FR-014, FR-015 | `rota_memora_test.dart` |
| **V7** | Diálogo e folha surgem por cima sem mover a tela de trás | FR-010 | `dialogo_test.dart`, `folha_inferior_test.dart` (novos) |
| **V8** | Trocar de destino preserva a pilha de cada um e desliza pela posição | FR-011 | `casca_interna_test.dart` |
| **V9** | Com "reduzir movimento", toda transição é instantânea | FR-013 | testes de V6 a V8, com a preferência ligada |
| **V10** | Nenhum bloco com mais de 2 frases, palavra proibida ou emoji fora da IA | FR-016, FR-018, FR-020, FR-022 | `texto_da_interface_test.dart` + `TextoDaInterfaceTest` (backend) |
| **V11** | Resposta da IA com vários emojis mostra só o primeiro | FR-023, FR-024 | `limitar_emoji_test.dart` |
| **V12** | A abertura acena enquanto carrega e sai em até um aceno depois | FR-036 a FR-039, SC-009 | `abertura_memora_test.dart` + medição manual |
| **V13** | Início com a Memora no terço superior; a 200% ela encolhe e as ações ficam | FR-040, FR-041 | `inicio_ocupa_a_altura_test.dart`, matriz de aparelhos |
| **V14** | Conversa só com o essencial; Memora pequena no topo | FR-042, FR-043 | `conversa_acessibilidade_test.dart` + álbum |
| **V15** | Barra inferior: ícone + rótulo, indicador desliza, ícones da mesma família | FR-044 a FR-047 | `navegacao_inferior_test.dart` (novo) |
| **V16** | Ditado só no aparelho; sem suporte, indisponível com motivo | FR-034 | teste do leitor de voz (Fase B) |
| **V17** | A apresentação diz que a Memora só fala dentro do aplicativo | FR-035 | teste da apresentação |
| **V18** | Todas as telas no álbum passam na checagem da memora-ux | FR-031, SC-001 | `album_de_telas_test.dart` + revisão humana |
| **V19** | Sem engasgo em abertura, trocas e gestos (< 5% de quadros acima de 16 ms) | SC-005 | **manual**: `flutter run --profile` no celular |
| **V20** | 4 de 5 pessoas de 65+ sabem onde estão e como voltar após 3 trocas | SC-007 | **manual**: teste com pessoas (portão das 001/002) |

## Quebrar de propósito (regra do projeto)

Antes de dar um portão novo como pronto, quebre-o e confirme que reprova:
- V2/V3: tire o `ExcludeSemantics` ou a checagem de "reduzir movimento";
- V6: deixe a tela que sai aceitar toque;
- V10: acrescente um bloco de três frases, um "idoso" e um emoji;
- V11: devolva o texto sem filtrar.
