import 'package:flutter/material.dart';

import '../../tokens/espacamento.dart';
import '../ilustracao/avatar_memora.dart';
import '../ilustracao/ilustracao_memora.dart';
import 'cartao.dart';

/// Cartão com o retrato circular saindo pela borda de cima.
///
/// É a forma das telas de cadastro e de login do protótipo. Existe como
/// componente, e não copiado nas duas, porque um recuo ajustado numa e não na
/// outra faria o avatar flutuar em uma das telas sem ninguém notar.
///
/// ## O recuo de cima não é decoração
///
/// O conteúdo começa abaixo da metade do avatar que invade o cartão. Sem esse
/// espaço, o primeiro campo do formulário ficaria **por baixo** do retrato — e
/// a pessoa tocaria no rótulo achando que toca no campo.
class CartaoComAvatar extends StatelessWidget {
  /// Conteúdo do cartão.
  final Widget child;

  /// Diâmetro do retrato.
  final double tamanhoDoAvatar;

  /// Ilustração exibida no retrato.
  final Ilustracao ilustracao;

  /// Cria o cartão com avatar.
  const CartaoComAvatar({
    required this.child,
    this.tamanhoDoAvatar = 128,
    this.ilustracao = Ilustracao.casalIdoso,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final double metade = tamanhoDoAvatar / 2;

    return Stack(
      // O avatar precisa ultrapassar a borda do cartão; recortá-lo devolveria
      // um semicírculo colado no topo, que é outro desenho.
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: metade),
          child: Cartao(
            padding: EdgeInsets.fromLTRB(
              MemoraEspacamento.lg,
              metade + MemoraEspacamento.lg,
              MemoraEspacamento.lg,
              MemoraEspacamento.lg,
            ),
            child: child,
          ),
        ),
        AvatarMemora(tamanho: tamanhoDoAvatar, ilustracao: ilustracao),
      ],
    );
  }
}
