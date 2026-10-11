import 'package:flutter/material.dart';
import '../../../../design_system/design_system.dart';
import '../controladores/controlador_verificacao_queda.dart';
import '../widgets/cronometro_regressivo_queda.dart';

/// Tela de alerta exibida imediatamente após a detecção de uma queda potencial.
///
/// Pergunta *"Você está bem?"* e oferece dois caminhos com alta affordance:
/// 1. "Estou bem" (cessa alarme local e silencia ESP32 via MQTT).
/// 2. "Preciso de ajuda" ou expiração do tempo de 45 s (aciona discador e mensagem).
class TelaVerificacaoQueda extends StatelessWidget {
  const TelaVerificacaoQueda({
    required this.controlador,
    super.key,
  });

  final ControladorVerificacaoQueda controlador;

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return AnimatedBuilder(
      animation: controlador,
      builder: (BuildContext ctx, Widget? _) {
        return Scaffold(
          backgroundColor: cores.fundo,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MemoraEspacamento.lg,
                    vertical: MemoraEspacamento.md,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - MemoraEspacamento.lg,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // Topo: Identificação e Alerta
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            const SizedBox(height: MemoraEspacamento.md),
                            Container(
                              padding: const EdgeInsets.all(MemoraEspacamento.md),
                              decoration: BoxDecoration(
                                color: cores.perigo.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: cores.perigo,
                                size: MemoraDimensoes.iconeEstadoVazio,
                              ),
                            ),
                            const SizedBox(height: MemoraEspacamento.md),
                            Text(
                              'Você está bem?',
                              textAlign: TextAlign.center,
                              style: MemoraTipografia.destaque.copyWith(
                                color: cores.texto,
                                fontWeight: FontWeight.bold,
                              ),
                              textScaler: escalaTextoLimitada(context),
                            ),
                            const SizedBox(height: MemoraEspacamento.sm),
                            Text(
                              'O sensor detectou um movimento brusco que pode ser uma queda.',
                              textAlign: TextAlign.center,
                              style: MemoraTipografia.corpo.copyWith(
                                color: cores.textoSuave,
                              ),
                              textScaler: escalaTextoLimitada(context),
                            ),
                            const SizedBox(height: MemoraEspacamento.lg),
                            CronometroRegressivoQueda(
                              segundosRestantes: controlador.segundosRestantes,
                            ),
                          ],
                        ),

                        // Ações principais: Dois botões grandes e separados
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: MemoraEspacamento.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              BotaoPrimario(
                                rotulo: 'Estou bem',
                                icone: Icons.check_circle_outline_rounded,
                                aoTocar: controlador.responderEstouBem,
                              ),
                              const SizedBox(height: MemoraEspacamento.md),
                              BotaoPerigo(
                                rotulo: 'Preciso de ajuda',
                                icone: Icons.warning_amber_rounded,
                                aoTocar: controlador.responderPrecisoDeAjuda,
                              ),
                              const SizedBox(height: MemoraEspacamento.md),
                              // Aviso Antigolpe (Princípio II da Constituição)
                              Text(
                                'Aviso de segurança: O Memora nunca solicita senhas, transferências bancárias ou PIX em alertas.',
                                textAlign: TextAlign.center,
                                style: MemoraTipografia.apoio.copyWith(
                                  color: cores.textoSuave,
                                ),
                                textScaler: escalaTextoLimitada(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
