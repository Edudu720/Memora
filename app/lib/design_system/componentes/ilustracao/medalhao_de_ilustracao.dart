import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import 'ilustracao_memora.dart';

/// Uma ilustração colorida sobre o círculo claro do Memora (R4 da feature 004).
///
/// ## Por que o círculo é sempre claro
///
/// As ilustrações têm cores próprias, desenhadas para fundo claro. No tema
/// escuro, sobre o azul-marinho do fundo, a parte azul-escura delas **some** —
/// foi o que o rascunho de renderização da T010 mostrou com a cabeça da
/// Memora. Fazer três versões de cada desenho é como elas começam a divergir;
/// um medalhão claro resolve as três de uma vez, e é o recurso que o próprio
/// wireframe usa nos círculos atrás dos rostos.
///
/// ## Por que o desenho não encosta na borda
///
/// O desenho ocupa [proporcaoDoDesenho] do círculo. Encostado, ele parece
/// cortado — e, recortado pela borda, deixa de ser reconhecível em tamanho
/// pequeno, que é onde ele mais aparece.
class MedalhaoDeIlustracao extends StatelessWidget {
  /// Quanto do diâmetro o desenho ocupa.
  static const double proporcaoDoDesenho = 0.7;

  /// Qual ilustração exibir.
  final Ilustracao ilustracao;

  /// Diâmetro do círculo, em pixels lógicos.
  final double tamanho;

  /// O que a figura comunica. Nulo é decorativa, e o leitor de tela a ignora.
  final String? descricao;

  /// Cria o medalhão.
  const MedalhaoDeIlustracao(
    this.ilustracao, {
    required this.tamanho,
    this.descricao,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    return SizedBox.square(
      dimension: tamanho,
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: cores.medalhao),
        child: Center(
          child: IlustracaoMemora(
            ilustracao,
            altura: tamanho * proporcaoDoDesenho,
            largura: tamanho * proporcaoDoDesenho,
            descricao: descricao,
          ),
        ),
      ),
    );
  }
}
