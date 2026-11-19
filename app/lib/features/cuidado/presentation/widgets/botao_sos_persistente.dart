import 'package:flutter/material.dart';

import '../../../../design_system/componentes/toque/superficie_tocavel.dart';
import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_sos.dart';

/// Botão SOS persistente acessível nas telas principais internas (Feature 014).
///
/// Respeita o piso mínimo de toque (`MemoraDimensoes.alvoMinimo`), sempre exibe
/// texto explícito ao lado do ícone (`FR-002`) e garante contraste elevado nos
/// três temas do aplicativo.
class BotaoSosPersistente extends StatelessWidget {
  /// Chave padrão quando usado isoladamente em widgets/testes.
  static const Key chaveBotao = Key('botao_sos_persistente');

  /// Ação chamada ao tocar no botão (sempre abre a confirmação antes do envio).
  final VoidCallback aoTocar;

  /// Cria o botão SOS persistente.
  const BotaoSosPersistente({
    required this.aoTocar,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final double escala = MediaQuery.textScalerOf(context).scale(1);
    final bool escalaAlta = escala >= MemoraDimensoes.escalaTextoAlta;

    return SuperficieTocavel(
      rotulo: TextosSos.rotuloBotaoSos,
      dica: TextosSos.semanticaBotaoSos,
      fundo: cores.perigo,
      borda: ehAltoContraste ? cores.borda : cores.sobrePerigo,
      raio: BorderRadius.circular(MemoraRaio.pilula),
      sombra: !ehAltoContraste,
      conteinerSemantico: true,
      aoTocar: aoTocar,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: MemoraDimensoes.alvoDecisao,
          minHeight: MemoraDimensoes.alvoMinimo,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MemoraEspacamento.md,
            vertical: escalaAlta ? 0 : MemoraEspacamento.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.sos_rounded,
                color: cores.sobrePerigo,
                size: MemoraDimensoes.iconePadrao,
              ),
              const SizedBox(width: MemoraEspacamento.xs),
              Flexible(
                child: TextoMemora(
                  TextosSos.rotuloBotaoSos,
                  estilo: escalaAlta
                      ? EstiloTexto.apoio
                      : EstiloTexto.corpoForte,
                  cor: cores.sobrePerigo,
                  maxLinhas: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
