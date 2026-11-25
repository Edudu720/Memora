import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../controladores/controlador_cadastro.dart';

/// Mostra as regras da senha e quais já foram atendidas.
///
/// ## Por que aparece antes de digitar
///
/// A FR-008 exige que as regras sejam informadas **antes** de a pessoa começar
/// a digitar. Descobrir a regra só depois de errar é a forma mais rápida de
/// fazer alguém desistir — ela tenta, é recusada, e não entende por quê.
///
/// ## Por que não usa só cor
///
/// Cada regra tem ícone **e** texto (FR-032). Um item que fica verde não
/// comunica nada a quem não distingue matizes.
class RegrasDeSenha extends StatelessWidget {
  /// Quais regras já foram atendidas, na ordem de [RegraDeSenha.todas].
  final List<bool> atendidas;

  /// Cria o indicador de regras.
  const RegrasDeSenha({required this.atendidas, super.key});

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final bool todasAtendidas = atendidas.every((bool x) => x);

    return Semantics(
      label: 'O que sua senha precisa ter',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(MemoraEspacamento.md),
          decoration: BoxDecoration(
            color: cores.superficieSutil,
            borderRadius: BorderRadius.circular(MemoraRaio.cartaoMedio),
            border: ehAltoContraste
                ? Border.all(
                    color: cores.borda,
                    width: MemoraDimensoes.bordaEnfase,
                  )
                : Border.all(
                    color: cores.bordaSutil,
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Wrap(
                spacing: MemoraEspacamento.sm,
                runSpacing: MemoraEspacamento.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  const TextoMemora.apoio('Sua senha precisa:'),
                  BadgeDeStatus(
                    rotulo: todasAtendidas ? 'Pronta' : 'Obrigatório',
                    icone: todasAtendidas ? Icons.check_rounded : null,
                    tom: todasAtendidas
                        ? TomBadgeStatus.positivo
                        : TomBadgeStatus.neutro,
                  ),
                ],
              ),
              const SizedBox(height: MemoraEspacamento.sm),
              for (int i = 0; i < RegraDeSenha.todas.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: MemoraEspacamento.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        atendidas[i]
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: MemoraDimensoes.iconePadrao,
                        color: atendidas[i] ? cores.sucesso : cores.textoSuave,
                      ),
                      const SizedBox(width: MemoraEspacamento.sm),
                      Expanded(
                        child: TextoMemora(
                          RegraDeSenha.todas[i].descricao,
                          estilo: EstiloTexto.apoio,
                          cor: atendidas[i]
                              ? cores.sucessoTexto
                              : cores.textoSuave,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
