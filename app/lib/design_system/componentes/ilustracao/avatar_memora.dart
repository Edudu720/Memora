import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import 'ilustracao_memora.dart';

/// O retrato circular que fica sobre a borda de cima do cartão.
///
/// É o elemento que amarra o cadastro e o login do protótipo: um círculo com o
/// casal dentro, metade dele saindo para fora do cartão.
///
/// ## Por que o círculo é desenhado aqui, e não no arquivo
///
/// A mesma ilustração aparece **sem** círculo no cabeçalho das boas-vindas. Um
/// fundo embutido no SVG obrigaria a manter dois arquivos quase iguais, que é
/// como duas versões da mesma figura começam a divergir.
///
/// ## Não é clicável, e nem parece
///
/// Foto de perfil em aplicativo costuma abrir alguma coisa. Esta não abre nada:
/// é retrato, não ação (FR-012). Também não tem sombra nem realce de toque.
class AvatarMemora extends StatelessWidget {
  /// Diâmetro do círculo, em pixels lógicos.
  final double tamanho;

  /// Ilustração exibida dentro do círculo.
  final Ilustracao ilustracao;

  /// Cria o avatar.
  const AvatarMemora({
    this.tamanho = 132,
    this.ilustracao = Ilustracao.casalIdoso,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return ExcludeSemantics(
      child: Container(
        width: tamanho,
        height: tamanho,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cores.superficieAlt,
          // A borda usa a cor de fundo da tela, não uma linha: é ela que
          // recorta o círculo do cartão quando ele fica por cima da borda,
          // como no protótipo.
          border: Border.all(
            color: cores.fundo,
            width: MemoraDimensoes.bordaAvatar,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Align(
          // Alinhado ao rodapé: os ombros das figuras terminam na base do
          // quadro, e centralizar deixaria uma faixa vazia embaixo.
          alignment: Alignment.bottomCenter,
          child: IlustracaoMemora(ilustracao, altura: tamanho * 0.92),
        ),
      ),
    );
  }
}
