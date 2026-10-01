import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_assistente.dart';
import '../../../../l10n/textos_autenticacao.dart';
import '../../../autenticacao/presentation/widgets/saida_com_confirmacao.dart';
import '../../domain/hub.dart';

/// O lugar para onde a pessoa sempre volta (T025, US1).
///
/// ## A tela mais vista do produto
///
/// É a primeira coisa depois de entrar, e o destino do caminho de volta de
/// todas as outras. Ela decide se a pessoa se sente perdida ou em casa — e por
/// isso não tem menu escondido, gesto a descobrir, nem nada piscando pedindo
/// atenção.
///
/// ## Ela mostra o que recebe, e só
///
/// A FR-003 exige que porta sem destino não apareça. A tela não decide isso:
/// ela exibe a lista que lhe passam, e [PortaDoHub] torna o destino
/// obrigatório. Quem sabe o que existe é quem monta o fluxo.
///
/// <b>A consequência prática é que o Hub cresce uma porta por entrega.</b> Hoje
/// ele abre com o que de fato está construído; conversa, catálogos e registro
/// entram quando existirem.
///
/// ## Por que botões, e não cartões
///
/// Porta é ação, e ação no Memora usa pílula e preenchimento (FR-012 da feature
/// 001). Cartão é a linguagem de informação, e o `Cartao` do Design System
/// deliberadamente não aceita toque.
class TelaHub extends StatelessWidget {
  /// Chave da saudação, usada pelos testes.
  static const Key chaveSaudacao = Key('hub.saudacao');

  /// Chave do botão de sair.
  static const Key chaveSair = Key('hub.sair');

  /// Chave da confirmação que vem depois do toque em sair (FR-025).
  static const Key chaveConfirmacaoSaida = Key('hub.confirmacao');

  /// Chave de uma porta, pelo rótulo.
  static Key chaveDaPorta(String rotulo) => Key('hub.porta.$rotulo');

  /// Como a pessoa quer ser chamada.
  final String nome;

  /// As portas construídas. Ver a nota sobre a FR-003.
  final List<PortaDoHub> portas;

  /// Encerra a sessão, depois que a pessoa confirmou.
  final Future<void> Function() aoSair;

  /// Cria o Hub.
  const TelaHub({
    required this.nome,
    required this.portas,
    required this.aoSair,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MemoraEspacamento.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: MemoraEspacamento.md),

              // O casal, e não um avatar de perfil: é a mesma ilustração das
              // telas de entrada, e reconhecê-la aqui é o que faz o Hub
              // parecer a continuação do lugar onde a pessoa acabou de entrar.
              const Center(
                child: IlustracaoMemora(Ilustracao.casalIdoso, altura: 96),
              ),
              const SizedBox(height: MemoraEspacamento.lg),

              TextoMemora.tituloTela(
                TextosAssistente.saudacao(nome),
                key: TelaHub.chaveSaudacao,
                alinhamento: TextAlign.center,
              ),

              const SizedBox(height: MemoraEspacamento.xxl),

              for (final PortaDoHub porta in portas) ...<Widget>[
                _Porta(porta: porta),
                const SizedBox(height: MemoraEspacamento.lg),
              ],

              const SizedBox(height: MemoraEspacamento.xl),
              // Sair pede confirmação (FR-025), a mesma da tela de perfil.
              SaidaComConfirmacao(
                chaveConfirmacao: TelaHub.chaveConfirmacaoSaida,
                aoConfirmar: aoSair,
                botao: (VoidCallback aoTocar) => BotaoTerciario(
                  key: TelaHub.chaveSair,
                  rotulo: TextosAutenticacao.botaoSair,
                  aoTocar: aoTocar,
                  larguraTotal: true,
                ),
              ),
              const SizedBox(height: MemoraEspacamento.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uma porta desenhada: o botão e, abaixo dele, o que há do outro lado.
///
/// A descrição fica **fora** do botão de propósito. Dentro, ela dobraria a
/// altura do alvo de toque e faria o rótulo competir com o próprio texto de
/// apoio; fora, o botão continua sendo um alvo limpo e a explicação continua
/// disponível para quem lê antes de tocar.
class _Porta extends StatelessWidget {
  final PortaDoHub porta;

  const _Porta({required this.porta});

  @override
  Widget build(BuildContext context) {
    final Key chave = TelaHub.chaveDaPorta(porta.rotulo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (porta.principal)
          BotaoPrimario(
            key: chave,
            rotulo: porta.rotulo,
            icone: porta.icone,
            aoTocar: porta.aoAbrir,
          )
        else
          BotaoSecundario(
            key: chave,
            rotulo: porta.rotulo,
            icone: porta.icone,
            aoTocar: porta.aoAbrir,
          ),
        const SizedBox(height: MemoraEspacamento.xs),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraEspacamento.md,
          ),
          child: TextoMemora.apoio(
            porta.descricao,
            alinhamento: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
