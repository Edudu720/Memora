import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import 'ilustracao_memora.dart';

/// Como a Memora está, em cada momento (alinhado com as ideias de design).
enum ExpressaoDaMemora {
  /// Em repouso: cabeçalhos, Início, Boas-vindas (acenando).
  neutra(Ilustracao.memoraNeutra, 'memora_perfil_robo.png'),

  /// Falando / Ajuda: apresentação, conversa, ajuda guiada (pensando).
  falando(Ilustracao.memoraFalando, 'memora_ajuda_robo.png'),

  /// Comemorando / Conclusão: fim do passo a passo, conta criada (sucesso).
  comemorando(Ilustracao.memoraComemorando, 'memora_conclusao_robo.png'),

  /// Preocupada / Alerta: ao lado dos avisos de segurança (com escudo).
  preocupada(Ilustracao.memoraPreocupada, 'memora_alerta_robo.png');

  const ExpressaoDaMemora(this.ilustracao, [this.imagemPng]);

  /// O desenho desta expressão em SVG.
  final Ilustracao ilustracao;

  /// Imagem em alta resolução, se disponível.
  final String? imagemPng;
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
    final int cachePx = (tamanho * 2.5).clamp(48, 512).round();
    final Widget imagem = expressao.imagemPng != null
        ? Image.asset(
            'assets/ilustracoes/${expressao.imagemPng}',
            width: tamanho,
            height: tamanho,
            fit: BoxFit.contain,
            cacheWidth: cachePx,
            cacheHeight: cachePx,
          )
        : IlustracaoMemora(
            expressao.ilustracao,
            altura: tamanho,
            largura: tamanho,
            descricao: descricao,
          );

    final Widget conteudo = SizedBox.square(
      dimension: tamanho,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cores.medalhao,
        ),
        child: ClipOval(
          child: Align(
            child: imagem,
          ),
        ),
      ),
    );

    if (descricao == null) {
      return ExcludeSemantics(child: conteudo);
    }
    return Semantics(image: true, label: descricao, child: conteudo);
  }
}
