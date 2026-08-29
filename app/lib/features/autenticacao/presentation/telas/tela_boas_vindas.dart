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
    final MemoraCores cores = context.memora.cores;

    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MemoraEspacamento.lg),
          child: Cartao(
            padding: const EdgeInsets.all(MemoraEspacamento.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Cabeçalho: o casal à esquerda, a apresentação à direita.
                Row(
                  children: <Widget>[
                    const IlustracaoMemora(Ilustracao.casalIdoso, altura: 84),
                    const SizedBox(width: MemoraEspacamento.md),
                    const Expanded(
                      child: TextoComDestaque(
                        TextosAutenticacao.apresentacao,
                        estilo: EstiloTexto.corpoForte,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: MemoraEspacamento.xxl),

                // O que a pessoa vai aprender, com a ilustração ao lado.
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: TextoComDestaque(
                        TextosAutenticacao.oQueVouEnsinar,
                      ),
                    ),
                    const SizedBox(width: MemoraEspacamento.md),
                    const IlustracaoMemora(
                      Ilustracao.pessoaComCelular,
                      altura: 132,
                    ),
                  ],
                ),

                const SizedBox(height: MemoraEspacamento.lg),
                // A linha que sobe. Recebe a cor do tema porque é desenhada
                // com `currentColor`: sem ela, sumiria no tema escuro.
                IlustracaoMemora(
                  Ilustracao.linhaJornada,
                  // Altura obrigatória: largura infinita sem altura definida
                  // faz o SVG receber restrição infinita e o layout estoura.
                  altura: 40,
                  largura: double.infinity,
                  fit: BoxFit.fill,
                  cor: cores.textoSuave,
                ),
                const SizedBox(height: MemoraEspacamento.lg),

                const TextoComDestaque(TextosAutenticacao.promessa),

                const SizedBox(height: MemoraEspacamento.xxl),

                // A ÚNICA ação principal da tela.
                BotaoPrimario(
                  key: TelaBoasVindas.chaveComecar,
                  rotulo: TextosAutenticacao.botaoComecar,
                  icone: Icons.arrow_forward,
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
          ),
        ),
      ),
    );
  }
}
