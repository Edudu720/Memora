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
    final MemoraCores cores = context.memora.cores;

    return Semantics(
      label: 'O que sua senha precisa ter',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const TextoMemora.apoio('Sua senha precisa:'),
            const SizedBox(height: MemoraEspacamento.sm),
            for (int i = 0; i < RegraDeSenha.todas.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: MemoraEspacamento.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      atendidas[i]
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 22,
                      color: atendidas[i] ? cores.sucesso : cores.textoSuave,
                    ),
                    const SizedBox(width: MemoraEspacamento.sm),
                    Expanded(
                      child: TextoMemora(
                        RegraDeSenha.todas[i].descricao,
                        estilo: EstiloTexto.apoio,
                        cor: atendidas[i] ? cores.sucesso : cores.textoSuave,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
