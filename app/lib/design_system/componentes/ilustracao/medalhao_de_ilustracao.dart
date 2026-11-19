import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
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

  /// Contorno de [MemoraDimensoes.bordaEnfase] nesta cor. Nulo, sem contorno.
  ///
  /// Existe para o medalhão sobre uma superfície da **mesma cor**: no tema
  /// claro o `medalhao` e o `destaque` são o mesmo azul-claro, e o círculo
  /// sobre a porta secundária sumia (aviso da #38). O contorno desenha a forma
  /// sem mexer na paleta, e sem trocar o medalhão por outra cor que o
  /// cabeçalho e a Memora, que o usam sobre o fundo, teriam de acompanhar.
  final Color? contorno;

  /// Cria o medalhão.
  const MedalhaoDeIlustracao(
    this.ilustracao, {
    required this.tamanho,
    this.descricao,
    this.contorno,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final Color corIcone = tema.id == MemoraTemaId.claro
        ? cores.primaria
        : cores.sobrePrimaria;
    return SizedBox.square(
      dimension: tamanho,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cores.medalhao,
          border: contorno == null
              ? null
              : Border.all(
                  color: contorno!,
                  width: MemoraDimensoes.bordaEnfase,
                ),
        ),
        child: Center(
          child: IlustracaoMemora(
            ilustracao,
            altura: tamanho * proporcaoDoDesenho,
            largura: tamanho * proporcaoDoDesenho,
            cor: corIcone,
            descricao: descricao,
          ),
        ),
      ),
    );
  }
}
