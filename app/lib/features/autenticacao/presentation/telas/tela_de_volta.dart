import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_autenticacao.dart';

/// Tela de boas-vindas de volta para quem já entrou neste aparelho (FR-009a, T117).
///
/// ## Por que existe
///
/// A revisão de design da T044 decidiu que a tela de apresentação completa
/// ("Começar minha jornada", o que vou ensinar, casal idoso) só faz sentido
/// para quem **nunca entrou neste aparelho**. Quem já possui uma conta conhecida
/// aqui vê uma tela acolhedora de volta, onde "Entrar" é a ação principal e há o
/// caminho para quem quiser criar outra conta.
///
/// ## Ocupa a altura da tela
///
/// Assim como a `TelaBoasVindas` (FR-009) e a `TelaInicio` (T115), o conteúdo
/// ocupa a altura da área útil, repartindo o respiro de forma harmoniosa sem
/// deixar espaço vazio em branco no rodapé em aparelhos altos.
class TelaDeVolta extends StatelessWidget {
  /// Chave do botão principal de entrar.
  static const Key chaveEntrar = Key('volta.entrar');

  /// Chave do caminho para criar outra conta.
  static const Key chaveCriarConta = Key('volta.criar_conta');

  /// Chave da ilustração.
  static const Key chaveIlustracao = Key('volta.ilustracao');

  /// Chave do título.
  static const Key chaveTitulo = Key('volta.titulo');

  /// Acionada ao tocar em "Entrar".
  final VoidCallback aoEntrar;

  /// Acionada ao tocar em "Criar outra conta".
  final VoidCallback aoCriarConta;

  /// Cria a tela de boas-vindas de volta.
  const TelaDeVolta({
    required this.aoEntrar,
    required this.aoCriarConta,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints caixa) {
            final double alturaMinima =
                (caixa.maxHeight - 2 * MemoraEspacamento.lg).clamp(
                  0.0,
                  double.infinity,
                );

            final double fracaoFigura =
                caixa.maxHeight * MemoraDimensoes.fracaoDaFiguraDoInicio;
            final double figura = fracaoFigura < MemoraDimensoes.ilustracaoHeroi
                ? fracaoFigura
                : MemoraDimensoes.ilustracaoHeroi;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(MemoraEspacamento.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: alturaMinima),
                child: Cartao(
                  padding: const EdgeInsets.all(MemoraEspacamento.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Bloco superior: Ilustração e boas-vindas
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          if (figura >=
                              MemoraDimensoes.pisoDeIlustracao) ...<Widget>[
                            Center(
                              child: MemoraPersonagem(
                                key: chaveIlustracao,
                                tamanho: figura,
                              ),
                            ),
                            const SizedBox(height: MemoraEspacamento.xl),
                          ],
                          const TextoMemora(
                            TextosAutenticacao.tituloBoasVindasDeVolta,
                            key: chaveTitulo,
                            estilo: EstiloTexto.destaque,
                            alinhamento: TextAlign.center,
                          ),
                          const SizedBox(height: MemoraEspacamento.md),
                          const TextoMemora(
                            TextosAutenticacao.mensagemBoasVindasDeVolta,
                            alinhamento: TextAlign.center,
                          ),
                        ],
                      ),

                      // Bloco inferior: Ações
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const SizedBox(height: MemoraEspacamento.xxl),
                          BotaoPrimario(
                            key: chaveEntrar,
                            rotulo: TextosAutenticacao.botaoEntrar,
                            icone: Icons.arrow_forward,
                            aoTocar: aoEntrar,
                          ),
                          const SizedBox(height: MemoraEspacamento.md),
                          BotaoTerciario(
                            key: chaveCriarConta,
                            rotulo: TextosAutenticacao.botaoCriarOutraConta,
                            aoTocar: aoCriarConta,
                            larguraTotal: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

