import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_cuidado.dart';
import '../controladores/controlador_verificacao_queda.dart';
import '../widgets/cronometro_regressivo_queda.dart';

/// Tela de alerta exibida imediatamente após a detecção de uma queda potencial.
///
/// Pergunta *"Você está bem?"* e oferece dois caminhos com alta affordance:
/// 1. "Estou bem" (cessa alarme local e silencia ESP32 via MQTT).
/// 2. "Preciso de ajuda" ou expiração do tempo de 45 s (aciona discador e mensagem).
class TelaVerificacaoQueda extends StatelessWidget {
  /// Cria a tela de verificação de queda.
  const TelaVerificacaoQueda({
    required this.controlador,
    super.key,
  });

  /// Controlador do cronômetro e ações de confirmação.
  final ControladorVerificacaoQueda controlador;

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final double escala = MediaQuery.textScalerOf(context).scale(1);
    final bool mostrarMascote = escala < MemoraDimensoes.escalaTextoAlta;

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
                      minHeight: constraints.maxHeight > MemoraEspacamento.lg
                          ? constraints.maxHeight - MemoraEspacamento.lg
                          : 0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Cartao(
                          comBorda: ehAltoContraste,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              if (mostrarMascote) ...<Widget>[
                                const MemoraPersonagem(
                                  expressao: ExpressaoDaMemora.preocupada,
                                ),
                                const SizedBox(height: MemoraEspacamento.md),
                              ],
                              const BadgeDeStatus(
                                rotulo: TextosCuidado.badgeAtencaoQueda,
                                icone: Icons.warning_amber_rounded,
                                tom: TomBadgeStatus.atencao,
                              ),
                              const SizedBox(height: MemoraEspacamento.md),
                              const TextoMemora(
                                TextosCuidado.tituloVerificacaoQueda,
                                estilo: EstiloTexto.destaque,
                                alinhamento: TextAlign.center,
                                cabecalho: true,
                              ),
                              const SizedBox(height: MemoraEspacamento.sm),
                              TextoMemora(
                                TextosCuidado.subtituloVerificacaoQueda,
                                alinhamento: TextAlign.center,
                                cor: cores.textoSuave,
                              ),
                              const SizedBox(height: MemoraEspacamento.lg),
                              CronometroRegressivoQueda(
                                segundosRestantes:
                                    controlador.segundosRestantes,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: MemoraEspacamento.lg),
                        BotaoPrimario(
                          rotulo: TextosCuidado.botaoEstouBem,
                          icone: Icons.check_circle_outline_rounded,
                          aoTocar: controlador.responderEstouBem,
                        ),
                        const SizedBox(height: MemoraEspacamento.xl),
                        BotaoPerigo(
                          rotulo: TextosCuidado.botaoPrecisoDeAjuda,
                          icone: Icons.warning_amber_rounded,
                          aoTocar: controlador.responderPrecisoDeAjuda,
                        ),
                        const SizedBox(height: MemoraEspacamento.lg),
                        Cartao(
                          comBorda: true,
                          padding: const EdgeInsets.all(MemoraEspacamento.md),
                          child: TextoMemora.apoio(
                            TextosCuidado.avisoAntigolpeQueda,
                            cor: cores.textoSuave,
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
