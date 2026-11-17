import 'package:flutter/material.dart';

import '../../preferencias/reducao_de_movimento.dart';
import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../ilustracao/memora_personagem.dart';
import '../texto/texto_memora.dart';
import '../toque/superficie_tocavel.dart';
import 'cabecalho_de_tela.dart';

/// Barra superior do Memora.
///
/// O botão de voltar **sempre traz a palavra "Voltar"** ao lado da seta. Seta
/// isolada é ambígua para quem tem pouca familiaridade digital, e a FR-016
/// proíbe ícone sem rótulo.
class BarraSuperior extends StatelessWidget implements PreferredSizeWidget {
  /// Título da tela.
  final String titulo;

  /// Acionada ao voltar. Quando nula, o botão não aparece.
  final VoidCallback? aoVoltar;

  /// Ação opcional à direita da barra.
  final Widget? acao;

  /// Expressão opcional da Memora exibida no canto direito (ex.: `mini`).
  final ExpressaoDaMemora? memora;

  /// A Memora do canto está falando: um texto está aparecendo aos poucos.
  /// Troca a expressão por `falando` e liga a boca. Sem [memora], não faz nada;
  /// com "reduzir movimento" ligado a Memora fica em repouso, como a anfitriã.
  final bool memoraFalando;

  /// Cria a barra superior.
  const BarraSuperior({
    required this.titulo,
    this.aoVoltar,
    this.acao,
    this.memora,
    this.memoraFalando = false,
    super.key,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(MemoraDimensoes.alvoDecisao);

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final bool falando = memoraFalando && !context.reduzirMovimento;
    final bool mostrarFigura =
        memora != null &&
        MediaQuery.textScalerOf(context).scale(1) <
            CabecalhoDeTela.ampliacaoQueTiraAFigura;

    return Material(
      color: cores.fundo,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraEspacamento.md,
            vertical: MemoraEspacamento.xs,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: MemoraDimensoes.alvoDecisao,
            ),
            child: Row(
              children: <Widget>[
                if (aoVoltar != null) ...<Widget>[
                  SuperficieTocavel(
                    key: CabecalhoDeTela.chaveVoltar,
                    rotulo: 'Voltar',
                    aoTocar: aoVoltar,
                    fundo: cores.superficieSutil,
                    borda: ehAltoContraste ? cores.borda : cores.bordaSutil,
                    larguraBorda: ehAltoContraste
                        ? MemoraDimensoes.bordaEnfase
                        : MemoraDimensoes.espessuraBordaSutil,
                    raio: BorderRadius.circular(MemoraRaio.pilula),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: MemoraDimensoes.alvoMinimo,
                        minHeight: MemoraDimensoes.alvoMinimo,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MemoraEspacamento.md,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.arrow_back,
                              color: cores.primaria,
                              size: MemoraDimensoes.iconePadrao,
                            ),
                            const SizedBox(width: MemoraEspacamento.xs),
                            // Palavra escrita: seta sozinha é ambígua.
                            TextoMemora(
                              'Voltar',
                              estilo: EstiloTexto.corpoForte,
                              cor: cores.primaria,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: MemoraEspacamento.sm),
                ],
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MemoraEspacamento.xs,
                    ),
                    child: TextoMemora(
                      titulo,
                      estilo: EstiloTexto.corpoForte,
                      cabecalho: true,
                      maxLinhas: 2,
                    ),
                  ),
                ),
                if (mostrarFigura) ...<Widget>[
                  const SizedBox(width: MemoraEspacamento.sm),
                  MemoraPersonagem(
                    expressao: falando ? ExpressaoDaMemora.falando : memora!,
                    tamanho: MemoraDimensoes.alvoMinimo,
                    falando: falando,
                  ),
                ],
                ?acao,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
