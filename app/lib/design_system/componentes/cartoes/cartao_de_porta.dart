import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../ilustracao/ilustracao_memora.dart';
import '../ilustracao/medalhao_de_ilustracao.dart';
import '../texto/texto_memora.dart';
import '../toque/superficie_tocavel.dart';

/// Uma porta: do Hub, da Ajuda, das Configurações (feature 004).
///
/// ## É ação, e por isso é pílula preenchida — não cartão
///
/// "Ação usa pílula e preenchimento; informação nunca usa nenhum dos dois"
/// (FR-012 da 002). O `Cartao` do Design System **não é clicável** de
/// propósito, e um cartão tocável seria a terceira linguagem que essa regra
/// proíbe. Esta é a pílula azul do Hub do wireframe, crescida para caber um
/// desenho e uma linha de explicação.
///
/// A porta [principal] vai em primária; as outras no `destaque`, **com a borda
/// em primária** do `BotaoSecundario`: só o `destaque` mede 1,13:1 contra o
/// fundo claro, e a porta quase sumia (revisão da #38). No máximo uma
/// principal por tela (FR-002) — duas ações de mesmo peso dividem a atenção de
/// quem precisa de um caminho só.
///
/// ## A ilustração cede primeiro
///
/// Com texto ampliado, o nome e a explicação precisam da largura. A partir de
/// [ampliacaoQueTiraAIlustracao] o desenho sai, e o cartão inteiro continua
/// sendo o alvo de toque (regra 7 da R2).
class CartaoDePorta extends StatelessWidget {
  /// A partir desta ampliação de texto o desenho sai.
  static const double ampliacaoQueTiraAIlustracao = 1.75;

  /// Nome da porta.
  final String nome;

  /// Uma linha dizendo o que há atrás dela. Quebra em vez de estourar.
  final String explicacao;

  /// O desenho.
  final Ilustracao ilustracao;

  /// Ao abrir. Nula, a porta aparece desabilitada — mas a FR-018 manda não
  /// mostrar porta que não funciona, então isso só existe para a galeria.
  final VoidCallback? aoAbrir;

  /// A ação principal da tela.
  final bool principal;

  /// Cria a porta.
  const CartaoDePorta({
    required this.nome,
    required this.explicacao,
    required this.ilustracao,
    required this.aoAbrir,
    this.principal = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final bool habilitada = aoAbrir != null;
    final Color fundo = !habilitada
        ? cores.superficieAlt
        : (principal ? cores.primaria : cores.destaque);
    final Color texto = !habilitada
        ? cores.textoSuave
        : (principal ? cores.sobrePrimaria : cores.texto);
    final Color seta = !habilitada
        ? cores.textoSuave
        : (principal ? cores.sobrePrimaria : cores.primaria);
    final bool comDesenho =
        MediaQuery.textScalerOf(context).scale(1) < ampliacaoQueTiraAIlustracao;

    return SuperficieTocavel(
      rotulo: nome,
      dica: explicacao,
      aoTocar: aoAbrir,
      fundo: fundo,
      sombra: habilitada,
      raio: BorderRadius.circular(MemoraRaio.porta),
      borda: habilitada && !principal ? cores.primaria : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: MemoraDimensoes.alvoDecisao,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraEspacamento.md,
            vertical: MemoraEspacamento.md,
          ),
          child: Row(
            children: <Widget>[
              if (comDesenho) ...<Widget>[
                MedalhaoDeIlustracao(
                  ilustracao,
                  tamanho: MemoraDimensoes.ilustracaoCartao,
                ),
                const SizedBox(width: MemoraEspacamento.md),
              ] else
                const SizedBox(width: MemoraEspacamento.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextoMemora(
                      nome,
                      estilo: EstiloTexto.corpoForte,
                      cor: texto,
                    ),
                    TextoMemora.apoio(explicacao, cor: texto),
                  ],
                ),
              ),
              const SizedBox(width: MemoraEspacamento.sm),
              Icon(
                Icons.chevron_right,
                color: seta,
                size: MemoraDimensoes.iconeDestaque,
              ),
              const SizedBox(width: MemoraEspacamento.sm),
            ],
          ),
        ),
      ),
    );
  }
}
