import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/elevacao.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../texto/texto_memora.dart';

/// Uma caixa por etapa: a frase que diz o que fazer, e embaixo o que se toca
/// (FR-002a e a regra 8 da R2 da feature 004).
///
/// ## Por que existe
///
/// A revisão de design da T044 achou as telas "juntas demais": campos,
/// explicação e botões num bloco só, e a pessoa idosa sem saber por onde
/// começar. A instrução precisa estar escrita **ao lado do que ela vai
/// tocar** — "Escreva aqui o seu e-mail" no topo, o campo logo abaixo —, e
/// cada etapa ou grupo mora na sua caixa, em vez de dividir a atenção num
/// cartão só.
///
/// ## É informação, não ação
///
/// "Ação usa pílula e preenchimento; informação nunca usa nenhum dos dois"
/// (FR-012 da 002). A caixa é o **contorno** de uma etapa, e não responde ao
/// toque: raio de cartão (nunca de pílula), fundo de superfície e uma faixa de
/// `superficieAlt` para a frase, sem cor primária. Quem for tocado — o campo, o
/// botão — vai em [child], com a linguagem dele.
///
/// Por isso o componente **não aceita callback de toque**, como o
/// `CampoInformacao`: é ausência de API, não convenção. Uma caixa tocável seria
/// a terceira linguagem visual que a FR-012 proíbe.
///
/// ## Para o leitor de tela
///
/// A frase é cabeçalho e vem **antes** do conteúdo na ordem de leitura, dentro
/// de um mesmo grupo: o TalkBack lê "Escreva aqui o seu e-mail" e só depois o
/// campo. Sem o grupo, a frase e o campo seriam dois focos sem ligação.
///
/// ## Quando a ampliação cresce
///
/// A frase quebra em quantas linhas precisar — sem `maxLinhas`, porque cortar a
/// instrução é tirar dela a única razão de existir —, e o [child] ocupa a
/// largura que sobra, sem teto em pixel.
class CaixaDeEtapa extends StatelessWidget {
  /// A frase que diz o que fazer nesta etapa. Ex.: "Escreva aqui o seu e-mail".
  ///
  /// Escreva no imperativo e no tom da Memora. Uma instrução só: duas ações
  /// merecem duas caixas.
  final String instrucao;

  /// O que a pessoa vê e toca nesta etapa: um campo, um grupo de campos, uma
  /// escolha ou uma explicação.
  final Widget child;

  /// Cria uma caixa de etapa.
  const CaixaDeEtapa({required this.instrucao, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final Color corDaBorda = ehAltoContraste ? cores.borda : cores.bordaSutil;
    final double larguraBorda = ehAltoContraste
        ? MemoraDimensoes.bordaEnfase
        : MemoraDimensoes.espessuraBordaSutil;

    return Semantics(
      // Um grupo só, com a frase e o conteúdo como nós **separados**, lidos
      // nesta ordem. Sem `explicitChildNodes` e sem o `container` em cada
      // metade, o Flutter fundia tudo num nó só — medido: o campo de texto
      // virava "cabeçalho" e a frase entrava no rótulo dele.
      container: true,
      explicitChildNodes: true,
      child: Container(
        width: double.infinity,
        // Recorta a faixa tonal da frase nos cantos arredondados da caixa.
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cores.superficie,
          borderRadius: BorderRadius.circular(MemoraRaio.cartao),
          border: Border.all(color: corDaBorda, width: larguraBorda),
          boxShadow: MemoraElevacao.listaSombrasCartao(cores),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: MemoraEspacamento.md,
                horizontal: MemoraEspacamento.lg,
              ),
              decoration: BoxDecoration(
                color: cores.superficieSutil,
                border: Border(
                  bottom: BorderSide(color: corDaBorda, width: larguraBorda),
                ),
              ),
              child: Semantics(
                container: true,
                child: TextoMemora(
                  instrucao,
                  estilo: EstiloTexto.corpoForte,
                  cabecalho: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(MemoraEspacamento.lg),
              child: Semantics(container: true, child: child),
            ),
          ],
        ),
      ),
    );
  }
}
