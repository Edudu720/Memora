import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_autenticacao.dart';

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
///
/// ## Sobre a forma, vinda do protótipo
///
/// Cartão claro sobre o fundo, ilustrações de pessoas idosas e palavras-chave
/// realçadas — a figura 4 de `docs/design/prototipo/04_image3.png`.
///
/// O que **não** veio de lá é o fundo fotográfico. O Memora tem três temas, e
/// uma foto fixa não muda com o tema: no de alto contraste, que existe para
/// quem enxerga pouco, ela seria ruído atrás do texto. A silhueta é a mesma
/// usando a superfície do tema.
///
/// As ilustrações mostram pessoas idosas **usando o próprio celular**, e não
/// sendo ajudadas por alguém. É o Princípio VII na primeira tela: ensinar,
/// nunca substituir.
class TelaBoasVindas extends StatelessWidget {
  /// Chave do botão principal, usada pelos testes.
  static const Key chaveComecar = Key('boas_vindas.comecar');

  /// Acionada ao começar o cadastro.
  final VoidCallback aoComecar;

  /// Acionada por quem já possui conta.
  final VoidCallback? aoJaTerConta;

  /// Cria a tela de boas-vindas.
  const TelaBoasVindas({required this.aoComecar, this.aoJaTerConta, super.key});

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final double escala = MediaQuery.textScalerOf(context).scale(1);
    final bool ocultarVisuais = escala >= MemoraDimensoes.escalaTextoAlta;
    final bool compacto = escala >= MemoraDimensoes.escalaColapsoGrade;

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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(MemoraEspacamento.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: alturaMinima),
                child: Cartao(
                  padding: EdgeInsets.all(
                    compacto ? MemoraEspacamento.lg : MemoraEspacamento.xl,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // Cabeçalho editorial: Memora neutra acenando + apresentação.
                          Row(
                            children: <Widget>[
                              if (!ocultarVisuais) ...<Widget>[
                                MemoraPersonagem(
                                  tamanho: compacto
                                      ? MemoraDimensoes.alvoDecisao
                                      : MemoraDimensoes.ilustracaoCabecalho,
                                ),
                                const SizedBox(width: MemoraEspacamento.md),
                              ],
                              const Expanded(
                                child: TextoComDestaque(
                                  TextosAutenticacao.apresentacao,
                                  estilo: EstiloTexto.corpoForte,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: MemoraEspacamento.md),
                          // Indicadores editoriais em pílula sem uso de literais visuais.
                          Row(
                            children: <Widget>[
                              Expanded(
                                flex: 2,
                                child: Container(
                                  height: MemoraDimensoes.alturaIndicadorDePasso,
                                  decoration: BoxDecoration(
                                    color: cores.primaria,
                                    borderRadius: BorderRadius.circular(
                                      MemoraRaio.pilula,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: MemoraEspacamento.sm),
                              Expanded(
                                child: Container(
                                  height: MemoraDimensoes.alturaIndicadorDePasso,
                                  decoration: BoxDecoration(
                                    color: cores.destaque,
                                    borderRadius: BorderRadius.circular(
                                      MemoraRaio.pilula,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: MemoraEspacamento.xl),

                          // Bloco de destaque. A Memora aparece uma vez só na tela (FR-006).
                          Container(
                            padding: const EdgeInsets.all(MemoraEspacamento.lg),
                            decoration: BoxDecoration(
                              color: cores.superficieSutil,
                              borderRadius: BorderRadius.circular(
                                MemoraRaio.cartaoMedio,
                              ),
                              border: ehAltoContraste
                                  ? Border.all(
                                      color: cores.borda,
                                      width: MemoraDimensoes.bordaEnfase,
                                    )
                                  : Border.all(
                                      color: cores.bordaSutil,
                                    ),
                            ),
                            child: const TextoComDestaque(
                              TextosAutenticacao.oQueVouEnsinar,
                            ),
                          ),

                          const SizedBox(height: MemoraEspacamento.lg),

                          const TextoComDestaque(TextosAutenticacao.promessa),
                        ],
                      ),

                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const SizedBox(height: MemoraEspacamento.xxl),

                          // A ÚNICA ação principal da tela.
                          BotaoPrimario(
                            key: TelaBoasVindas.chaveComecar,
                            rotulo: TextosAutenticacao.botaoComecar,
                            icone: Icons.arrow_forward_rounded,
                            aoTocar: aoComecar,
                          ),

                          if (aoJaTerConta != null) ...<Widget>[
                            const SizedBox(height: MemoraEspacamento.lg),
                            BotaoTerciario(
                              rotulo: TextosAutenticacao.botaoJaTenhoConta,
                              aoTocar: aoJaTerConta,
                              larguraTotal: true,
                            ),
                          ],
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
