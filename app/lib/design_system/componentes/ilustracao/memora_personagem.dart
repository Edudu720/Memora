import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import 'ilustracao_memora.dart';

/// Como a Memora está, em cada momento.
enum ExpressaoDaMemora {
  /// Em repouso: cabeçalhos, Início.
  neutra(Ilustracao.memoraNeutra),

  /// Falando: apresentação, conversa, ajuda guiada.
  falando(Ilustracao.memoraFalando),

  /// Comemorando: fim do passo a passo, conta criada.
  comemorando(Ilustracao.memoraComemorando),

  /// Preocupada: ao lado dos avisos de segurança. **Preocupada, não brava** —
  /// a primeira versão do desenho lia como raiva, e um aviso dado com raiva
  /// assusta quem precisava ser protegido.
  preocupada(Ilustracao.memoraPreocupada);

  const ExpressaoDaMemora(this.ilustracao);

  /// O desenho desta expressão.
  final Ilustracao ilustracao;
}

/// O rosto da Memora (FR-003 da feature 004).
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
/// a informação — por exemplo, a expressão preocupada sozinha num aviso.
///
/// ## Sobre o círculo
///
/// Sempre claro, nos três temas, como o [MedalhaoDeIlustracao]: a cabeça azul
/// da Memora some sobre o azul-marinho dos temas escuros. O corpo dela é
/// recortado pela base do círculo, como no wireframe, e por isso o desenho é
/// alinhado embaixo, e não centralizado.
class MemoraPersonagem extends StatelessWidget {
  /// A expressão.
  final ExpressaoDaMemora expressao;

  /// Diâmetro do círculo, em pixels lógicos.
  final double tamanho;

  /// O que o rosto comunica. Nulo é decorativa.
  final String? descricao;

  /// Cria o rosto da Memora.
  const MemoraPersonagem({
    this.expressao = ExpressaoDaMemora.neutra,
    this.tamanho = MemoraDimensoes.ilustracaoCabecalho,
    this.descricao,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    return SizedBox.square(
      dimension: tamanho,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cores.medalhao,
        ),
        child: ClipOval(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: IlustracaoMemora(
              expressao.ilustracao,
              altura: tamanho,
              largura: tamanho,
              descricao: descricao,
            ),
          ),
        ),
      ),
    );
  }
}
