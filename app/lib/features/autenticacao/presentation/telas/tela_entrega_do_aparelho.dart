import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_autenticacao.dart';

/// Interrompe o cadastro assistido antes da senha (T062, FR-059).
///
/// ## Por que uma tela inteira, e não um aviso
///
/// A FR-059 manda **interromper o fluxo**. Um aviso no meio do formulário seria
/// lido depois de a senha já ter sido digitada — e a essa altura o acompanhante
/// já a viu, que é justamente o que este modo existe para impedir.
///
/// Ocupar a tela toda obriga um toque deliberado de quem está com o aparelho, e
/// esse toque é o momento da entrega.
///
/// ## O texto fala com quem está ajudando
///
/// É essa pessoa que está com o celular na mão agora. Falar com a dona da conta
/// aqui seria escrever para quem não está lendo.
///
/// ## Isto é o que realmente protege a FR-062
///
/// Confirmar a posse do canal, no servidor, prova que alguém *alcança* aquele
/// contato — não prova de quem ele é, e o acompanhante ao lado digitaria o
/// código sem esforço. A separação real entre ajudar e assumir a conta acontece
/// aqui e na primeira entrada sozinha ([TelaPrimeiraEntrada]).
class TelaEntregaDoAparelho extends StatelessWidget {
  /// Chave do botão que segue para a senha.
  static const Key chaveContinuar = Key('entrega.continuar');

  /// Chave do botão que adia o cadastro.
  static const Key chaveAdiar = Key('entrega.adiar');

  /// Chamada quando o aparelho volta à pessoa dona da conta.
  final VoidCallback aoReceberOAparelho;

  /// Chamada quando a pessoa prefere continuar depois.
  ///
  /// Existe porque a alternativa seria prender quem não pode seguir agora — e
  /// quem fica preso numa tela busca o caminho de fora dela, que costuma ser
  /// deixar o acompanhante terminar.
  final VoidCallback? aoAdiar;

  /// Cria a tela de entrega do aparelho.
  const TelaEntregaDoAparelho({
    required this.aoReceberOAparelho,
    this.aoAdiar,
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
              const SizedBox(height: MemoraEspacamento.lg),
              Center(
                child: Container(
                  width: MemoraDimensoes.ilustracaoCabecalho,
                  height: MemoraDimensoes.ilustracaoCabecalho,
                  decoration: BoxDecoration(
                    color: cores.destaque,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: MemoraPersonagem(
                      expressao: ExpressaoDaMemora.falando,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: MemoraEspacamento.lg),
              const TextoMemora.tituloTela(
                TextosAutenticacao.tituloEntregaDoAparelho,
                alinhamento: TextAlign.center,
              ),
              const SizedBox(height: MemoraEspacamento.lg),
              const Cartao(
                child: Column(
                  children: <Widget>[
                    TextoMemora(
                      TextosAutenticacao.pedidoEntregaDoAparelho,
                      alinhamento: TextAlign.center,
                    ),
                    SizedBox(height: MemoraEspacamento.md),
                    TextoMemora.apoio(
                      TextosAutenticacao.motivoEntregaDoAparelho,
                      alinhamento: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MemoraEspacamento.xxxl),
              BotaoPrimario(
                key: chaveContinuar,
                rotulo: TextosAutenticacao.botaoAparelhoEntregue,
                icone: Icons.check_rounded,
                aoTocar: aoReceberOAparelho,
              ),
              if (aoAdiar != null) ...<Widget>[
                const SizedBox(height: MemoraEspacamento.md),
                BotaoTerciario(
                  key: chaveAdiar,
                  rotulo: TextosAutenticacao.botaoPrecisoDeAjudaComASenha,
                  aoTocar: aoAdiar,
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
