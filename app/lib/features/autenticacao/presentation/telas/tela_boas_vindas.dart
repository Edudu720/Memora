import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

/// Primeira tela que a pessoa vê no Memora.
///
/// ## Uma única ação, nenhuma decisão
///
/// O cenário 1 da User Story 1 é explícito: deve existir **exatamente uma**
/// ação principal visível e nenhuma escolha a fazer. Este é o momento de maior
/// evasão do produto — se a Dona Ana travar aqui, ela desinstala e não volta.
///
/// O caminho para quem já tem conta existe, mas em peso visual claramente
/// menor, para não competir com a ação principal.
class TelaBoasVindas extends StatelessWidget {
  /// Acionada ao começar o cadastro.
  final VoidCallback aoComecar;

  /// Acionada por quem já possui conta.
  final VoidCallback? aoJaTerConta;

  /// Cria a tela de boas-vindas.
  const TelaBoasVindas({
    required this.aoComecar,
    this.aoJaTerConta,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MemoraEspacamento.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: MemoraEspacamento.xxl),
              TextoMemora.tituloTela('Memora', cor: cores.primaria),
              const SizedBox(height: MemoraEspacamento.lg),
              const TextoMemora(
                'Eu vou te ensinar a usar o celular, no seu ritmo, '
                'sem pressa nenhuma.',
              ),
              const SizedBox(height: MemoraEspacamento.md),
              const TextoMemora(
                'Não faço nada sem te avisar antes 😊',
              ),

              const SizedBox(height: MemoraEspacamento.xxxl),

              // A ÚNICA ação principal da tela.
              BotaoPrimario(
                rotulo: 'Começar minha jornada',
                icone: Icons.arrow_forward,
                aoTocar: aoComecar,
              ),

              if (aoJaTerConta != null) ...<Widget>[
                const SizedBox(height: MemoraEspacamento.xl),
                BotaoTerciario(
                  rotulo: 'Já tenho uma conta',
                  aoTocar: aoJaTerConta,
                  larguraTotal: true,
                ),
              ],
              const SizedBox(height: MemoraEspacamento.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
