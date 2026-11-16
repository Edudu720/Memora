import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../../tokens/tipografia.dart';
import '../texto/texto_memora.dart';
import '../toque/superficie_tocavel.dart';

/// Pastilha interativa de filtro ou categoria com alvo mínimo de 48 dp.
///
/// Mostra o estado selecionado por múltiplos sinais além da cor: preenchimento
/// sólido em `primaria`, negrito reforçado e ícone ou visto de confirmação.
class ChipFiltro extends StatelessWidget {
  /// Texto exibido na pastilha.
  final String rotulo;

  /// Se este filtro está ativo no momento.
  final bool selecionado;

  /// Ícone opcional exibido antes do texto.
  final IconData? icone;

  /// Acionado ao tocar na pastilha.
  final VoidCallback aoTocar;

  /// Cria uma pastilha de filtro.
  const ChipFiltro({
    required this.rotulo,
    required this.selecionado,
    required this.aoTocar,
    this.icone,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final Color fundo = selecionado ? cores.primaria : cores.superficieSutil;
    final Color corTexto = selecionado ? cores.sobrePrimaria : cores.texto;
    final Color borda = ehAltoContraste
        ? cores.borda
        : (selecionado ? cores.primaria : cores.bordaSutil);
    final double larguraBorda = (ehAltoContraste || selecionado)
        ? MemoraDimensoes.bordaEnfase
        : MemoraDimensoes.espessuraBordaSutil;

    final IconData? iconeExibido =
        icone ?? (selecionado ? Icons.check_rounded : null);

    return SuperficieTocavel(
      rotulo: rotulo,
      selecionada: selecionado,
      aoTocar: aoTocar,
      fundo: fundo,
      borda: borda,
      larguraBorda: larguraBorda,
      raio: BorderRadius.circular(MemoraRaio.pilula),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: MemoraDimensoes.alvoMinimo,
          minHeight: MemoraDimensoes.alvoMinimo,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraEspacamento.lg,
            vertical: MemoraEspacamento.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (iconeExibido != null) ...<Widget>[
                Icon(
                  iconeExibido,
                  size: MemoraDimensoes.iconePequeno,
                  color: corTexto,
                ),
                const SizedBox(width: MemoraEspacamento.xs),
              ],
              Flexible(
                child: Text(
                  rotulo,
                  textScaler: escalaTextoLimitada(context),
                  style: MemoraTipografia.apoio.copyWith(
                    color: corTexto,
                    fontWeight: selecionado
                        ? MemoraTipografia.pesoDoNegrito
                        : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
