import 'package:flutter/material.dart';

import '../../tokens/dimensoes.dart';
import 'memora_animada/memora_animada.dart';
import 'memora_animada/poses.dart';

/// Como a Memora está, em cada momento.
///
/// Cada expressão é uma [PoseDaMemora] da Memora vetorial 2.5D
/// ([MemoraAnimada]), e é por [pose] que a `MemoraPersonagem` a desenha.
enum ExpressaoDaMemora {
  /// Em repouso: cabeçalhos, Início, Boas-vindas.
  neutra(PoseDaMemora.neutra),

  /// Falando: apresentação, conversa, ajuda guiada.
  falando(PoseDaMemora.falando),

  /// Comemorando: fim do passo a passo, conta criada.
  comemorando(PoseDaMemora.comemorando),

  /// Preocupada: ao lado dos avisos de segurança (com escudo).
  preocupada(PoseDaMemora.preocupada),

  /// Dica: explicação rápida, sugestões e orientação passo a passo (com livro).
  dica(PoseDaMemora.dica),

  /// Mini: só a cabeça, para cabeçalhos estreitos e resposta inline.
  mini(PoseDaMemora.mini);

  const ExpressaoDaMemora(this.pose);

  /// A pose com que a Memora vetorial desenha esta expressão.
  final PoseDaMemora pose;
}

/// A Memora, em qualquer tela (FR-003 da feature 004; feature 013, T047).
///
/// É a **porta de entrada única** do personagem: as telas pedem uma
/// [ExpressaoDaMemora] e um [tamanho], e ela monta a [MemoraAnimada] — o robô
/// vetorial desenhado pelo aplicativo, que segue a paleta e o tema (as cores
/// vêm de `context.memora.personagem`) e fica parado com "reduzir movimento".
/// Antes eram imagens PNG paradas dentro de um medalhão; o medalhão saiu
/// porque o desenho traz o aro que garante a silhueta nos três temas (FR-007).
///
/// ## Não confundir com o `AvatarMemora`
///
/// O `AvatarMemora` é o retrato do **casal** que fica sobre o cartão do
/// cadastro e do login — o nome dele é anterior a este componente. Quem fala
/// com a pessoa é a Memora, e é este o rosto dela.
///
/// ## Decorativa por padrão
///
/// Onde a Memora aparece, o texto ao lado já diz o que ela diz. Anunciar
/// "imagem da Memora" a cada balão acrescentaria uma parada à navegação do
/// leitor de tela sem informar nada. Passe [descricao] só quando o rosto **é**
/// a informação — por exemplo, a expressão preocupada sozinha num aviso. O
/// gesto de toque nunca aparece para o leitor de tela (FR-005b).
///
/// ## O toque
///
/// Por padrão ([reageAoToque]) ela responde ao toque com um aceno ou uma
/// piscada e mais nada (FR-005a). A área que responde é o quadrado inteiro de
/// [tamanho] e **não pode ficar a menos de 8 dp de um botão** (FR-005c): onde
/// ela estiver encostada num alvo de toque — dentro de uma linha tocável, por
/// exemplo —, passe `reageAoToque: false` e o toque cai no alvo.
class MemoraPersonagem extends StatelessWidget {
  /// A expressão.
  final ExpressaoDaMemora expressao;

  /// O lado do quadrado que ela ocupa, em pixels lógicos.
  final double tamanho;

  /// O que o rosto comunica. Nulo é decorativa.
  final String? descricao;

  /// Se o toque nela dispara um aceno ou uma piscada (FR-005a).
  final bool reageAoToque;

  /// Cria a Memora.
  const MemoraPersonagem({
    this.expressao = ExpressaoDaMemora.neutra,
    this.tamanho = MemoraDimensoes.ilustracaoCabecalho,
    this.descricao,
    this.reageAoToque = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Widget conteudo = MemoraAnimada(
      expressao: expressao.pose,
      tamanho: tamanho,
      reageAoToque: reageAoToque,
    );

    if (descricao == null) {
      return ExcludeSemantics(child: conteudo);
    }
    return Semantics(image: true, label: descricao, child: conteudo);
  }
}
