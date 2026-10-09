import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../texto/texto_memora.dart';
import '../toque/superficie_tocavel.dart';
import 'icone_de_navegacao.dart';

/// Um destino da navegação inferior.
@immutable
class ItemNavegacao {
  /// Desenho do destino: contornado quando não é o atual, preenchido quando é.
  final IconeDeNavegacao icone;

  /// Rótulo escrito. **Obrigatório** (FR-016).
  final String rotulo;

  /// Cria um item de navegação.
  const ItemNavegacao({required this.icone, required this.rotulo});
}

/// Navegação inferior do Memora.
///
/// **Todo item tem ícone e rótulo escrito.** No protótipo, a barra inferior
/// tinha apenas três ícones — engrenagem, casa e pessoa — sem nenhum texto.
/// Ícone isolado depende de convenção que este público não necessariamente
/// conhece, e a FR-016 proíbe.
class NavegacaoInferior extends StatelessWidget {
  /// Destinos exibidos.
  final List<ItemNavegacao> itens;

  /// Índice do destino ativo.
  final int indiceAtivo;

  /// Acionada ao escolher um destino.
  final ValueChanged<int> aoSelecionar;

  /// Chave do traço do destino ativo, para os testes.
  static Key chaveDoTraco(int posicao) => Key('navegacao.traco.$posicao');

  /// Chave da caixa que reserva o ícone de cada destino, para os testes.
  static Key chaveDoIcone(int posicao) => Key('navegacao.icone.$posicao');

  /// Cria a navegação inferior.
  const NavegacaoInferior({
    required this.itens,
    required this.indiceAtivo,
    required this.aoSelecionar,
    super.key,
  }) : assert(itens.length >= 2, 'Navegação exige ao menos dois destinos.');

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Material(
      color: cores.superficieAlt,
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            for (int i = 0; i < itens.length; i++)
              Expanded(
                child: _Item(
                  item: itens[i],
                  ativo: i == indiceAtivo,
                  posicao: i + 1,
                  total: itens.length,
                  aoTocar: () => aoSelecionar(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final ItemNavegacao item;
  final bool ativo;
  final int posicao;
  final int total;
  final VoidCallback aoTocar;

  const _Item({
    required this.item,
    required this.ativo,
    required this.posicao,
    required this.total,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final Color cor = ativo ? cores.primaria : cores.texto;

    // O destino ativo é marcado por QUATRO sinais além da cor (FR-015 da 004):
    // o traço em primária no topo, a pílula atrás do ícone, o ícone
    // preenchido (os outros são só contorno) e o rótulo em negrito. A pílula
    // sozinha não bastaria — o `destaque` mede só 1,1 a
    // 1,6:1 contra a barra —, e por isso o traço, que é par validado como
    // gráfico (primária sobre superficieAlt), vem junto.
    return SuperficieTocavel(
      rotulo: item.rotulo,
      dica: '$posicao de $total',
      selecionada: ativo,
      aoTocar: aoTocar,
      fundo: Colors.transparent,
      raio: BorderRadius.zero,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: MemoraDimensoes.alvoDecisao,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: MemoraEspacamento.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                key: ativo ? NavegacaoInferior.chaveDoTraco(posicao) : null,
                height: MemoraDimensoes.bordaSelecao,
                width: MemoraDimensoes.larguraDaPilulaDeNavegacao,
                decoration: BoxDecoration(
                  color: ativo ? cores.primaria : Colors.transparent,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(MemoraRaio.pilula),
                  ),
                ),
              ),
              const SizedBox(height: MemoraEspacamento.xs),
              Container(
                width: MemoraDimensoes.larguraDaPilulaDeNavegacao,
                height: MemoraDimensoes.alturaDaPilulaDeNavegacao,
                decoration: BoxDecoration(
                  color: ativo ? cores.destaque : Colors.transparent,
                  borderRadius: BorderRadius.circular(MemoraRaio.pilula),
                ),
                alignment: Alignment.center,
                // Os três desenhos ocupam a mesma caixa, e a caixa é a mesma nas
                // duas versões: trocar de contorno para cheio não mexe em nada.
                // A cor vem do tema por filtro — o arquivo não tem cor própria.
                child: SizedBox(
                  key: NavegacaoInferior.chaveDoIcone(posicao),
                  width: MemoraDimensoes.iconeDestaque,
                  height: MemoraDimensoes.iconeDestaque,
                  child: SvgPicture.asset(
                    item.icone.caminho(preenchido: ativo),
                    width: MemoraDimensoes.iconeDestaque,
                    height: MemoraDimensoes.iconeDestaque,
                    colorFilter: ColorFilter.mode(cor, BlendMode.srcIn),
                    // Decoração: o destino é anunciado pelo rótulo escrito.
                    excludeFromSemantics: true,
                  ),
                ),
              ),
              const SizedBox(height: MemoraEspacamento.xs),
              // Rótulo escrito, sempre.
              TextoMemora(
                item.rotulo,
                estilo: ativo ? EstiloTexto.corpoForte : EstiloTexto.apoio,
                cor: cor,
                alinhamento: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
