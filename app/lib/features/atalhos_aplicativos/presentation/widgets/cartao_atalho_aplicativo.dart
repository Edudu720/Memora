import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_atalhos_aplicativos.dart';
import '../../domain/entidades/atalho_aplicativo.dart';

/// Cartão interativo e acessível de um aplicativo na tela de atalhos diretos.
///
/// Utiliza [LinhaDeLista] do Design System 2.0 para oferecer área de toque
/// ampla, feedback visual em foco/pressão, leitor de tela completo e redução
/// automática de ornamentos sob alta ampliação de texto.
class CartaoAtalhoAplicativo extends StatelessWidget {
  /// Chave estável para localizar o cartão de um aplicativo específico em testes.
  static Key chaveDoAplicativo(String chave) => Key('atalhos.item.$chave');

  /// Dados do aplicativo exibido.
  final AtalhoAplicativo aplicativo;

  /// Ação disparada quando a pessoa toca neste aplicativo.
  final VoidCallback aoTocar;

  /// Cria o cartão de atalho de aplicativo.
  const CartaoAtalhoAplicativo({
    required this.aplicativo,
    required this.aoTocar,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final String textoStatus = aplicativo.instalado
        ? TextosAtalhosAplicativos.statusInstalado
        : TextosAtalhosAplicativos.statusNaoInstalado;

    final String rotuloLeitor =
        '${aplicativo.nomeExibido}. ${aplicativo.descricaoCurta} $textoStatus';

    return LinhaDeLista(
      key: chaveDoAplicativo(aplicativo.chave),
      esquerda: _IconeAplicativoAtalho(aplicativo: aplicativo),
      titulo: aplicativo.nomeExibido,
      subtitulo: aplicativo.descricaoCurta,
      rodape: BadgeDeStatus(
        rotulo: textoStatus,
        icone: aplicativo.instalado
            ? Icons.check_circle_outline
            : Icons.download_outlined,
        tom: aplicativo.instalado
            ? TomBadgeStatus.positivo
            : TomBadgeStatus.neutro,
      ),
      rotuloDoLeitor: rotuloLeitor,
      aoTocar: aoTocar,
    );
  }
}

class _IconeAplicativoAtalho extends StatelessWidget {
  final AtalhoAplicativo aplicativo;

  const _IconeAplicativoAtalho({required this.aplicativo});

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final Uint8List? bytes = aplicativo.iconeBytes;
    final Widget iconePadrao = IconeDoAplicativo(
      chave: aplicativo.chave,
      nome: aplicativo.nomeExibido,
    );

    return Container(
      padding: const EdgeInsets.all(MemoraEspacamento.xs),
      decoration: BoxDecoration(
        color: cores.superficieSutil,
        borderRadius: BorderRadius.circular(MemoraRaio.cartaoMedio),
        border: ehAltoContraste ? Border.all(color: cores.borda) : null,
      ),
      child: bytes != null && bytes.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(MemoraRaio.padrao),
              child: Image.memory(
                bytes,
                width: MemoraDimensoes.ilustracaoCartao,
                height: MemoraDimensoes.ilustracaoCartao,
                fit: BoxFit.contain,
                errorBuilder: (BuildContext _, Object _, StackTrace? _) =>
                    iconePadrao,
              ),
            )
          : iconePadrao,
    );
  }
}
