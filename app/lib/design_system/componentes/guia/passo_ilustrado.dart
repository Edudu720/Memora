import 'package:flutter/material.dart';

import '../../../features/aprendizado/domain/guia.dart';
import '../../../l10n/textos_guias.dart';
import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/elevacao.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../botoes/botao_primario.dart';
import '../botoes/botao_secundario.dart';
import '../botoes/botao_terciario.dart';
import '../cartoes/caixa_de_etapa.dart';
import '../ilustracao/ilustracao_memora.dart';
import '../ilustracao/memora_personagem.dart';
import '../texto/texto_memora.dart';
import 'captura_ampliada.dart';
import 'captura_com_destaque.dart';
import 'indicador_de_passo.dart';
import 'selo_exemplo.dart';

/// Uma tela do passo a passo visual e interativo (T065, FR-026, FR-028).
///
/// Desenha a moldura de celular, a captura, o selo "Exemplo" no canto superior,
/// o anel de destaque na região relativa correspondente e as instruções da Memora.
class PassoIlustrado extends StatelessWidget {
  /// Chave do selo visual "Exemplo".
  static const Key chaveSeloExemplo = Key('passo.selo_exemplo');

  /// Chave do anel de destaque sobre a captura.
  static const Key chaveDestaque = CapturaComDestaque.chaveDestaque;

  /// Chave da captura quando ela pode ser tocada para ampliar (FR-028b).
  static const Key chaveCapturaTocavel = Key('passo.captura_tocavel');

  /// Chave do botão "Ver a imagem maior" (FR-028b).
  static const Key chaveVerImagemMaior = Key('passo.ver_imagem_maior');

  /// Chave do aviso permanente de senha (quando presente).
  static const Key chaveAvisoSenha = Key('passo.aviso_senha');

  /// Chave do botão principal para continuar / concluir.
  static const Key chaveContinuar = Key('passo.continuar');

  /// Chave do botão secundário para relatar tela diferente.
  static const Key chaveTelaDiferente = Key('passo.tela_diferente');

  /// Chave do botão para voltar ao passo anterior.
  static const Key chaveVoltar = Key('passo.voltar');

  /// Chave do botão para sair do guia (FR-026).
  static const Key chaveSair = Key('passo.sair');

  /// Chave do botão para pedir para a Memora abrir o aplicativo (FR-027).
  static const Key chavePedirParaAbrir = Key('passo.pedir_para_abrir');

  /// Chave do botão para tirar dúvidas com o chatbot no final do guia.
  static const Key chaveTirarDuvida = Key('passo.tirar_duvida');

  /// Os dados da etapa atual.
  final Passo passo;

  /// Posição desta etapa (1-based).
  final int posicao;

  /// Total de etapas do guia.
  final int total;

  /// Chamada ao tocar no botão de avançar.
  final VoidCallback? aoContinuar;

  /// Chamada ao tocar em "Voltar".
  final VoidCallback? aoVoltar;

  /// Chamada ao tocar em "Sair do passo a passo".
  final VoidCallback? aoSair;

  /// Chamada ao tocar em "A minha tela está diferente".
  final VoidCallback? aoTelaDiferente;

  /// Chamada ao tocar em "Peça à Memora para abrir" no último passo.
  final VoidCallback? aoPedirParaAbrir;

  /// Chamada ao tocar em "Ficou com alguma dúvida? Pode perguntar" no último passo.
  final VoidCallback? aoTirarDuvida;

  /// Se deve envolver o conteúdo em um [SingleChildScrollView].
  final bool rolar;

  /// Cria a exibição da etapa ilustrada.
  const PassoIlustrado({
    required this.passo,
    required this.posicao,
    required this.total,
    this.aoContinuar,
    this.aoVoltar,
    this.aoSair,
    this.aoTelaDiferente,
    this.aoPedirParaAbrir,
    this.aoTirarDuvida,
    this.rolar = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final bool eUltimoPasso = posicao == total;

    final Widget conteudo = Padding(
      padding: const EdgeInsets.all(MemoraEspacamento.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 1. Indicador textual e barra de progresso
          IndicadorDePasso(posicao: posicao, total: total),
          const SizedBox(height: MemoraEspacamento.lg),

          // 2. Moldura de celular com a captura, selo "Exemplo", anel de destaque
          //    e o botão que amplia a imagem (FR-028b)
          _CapturaDoPasso(passo: passo),
          const SizedBox(height: MemoraEspacamento.lg),

          // 3. Aviso obrigatório se a etapa envolver senha (FR-032, FR-049)
          if (passo.temCampoDeSenha) ...<Widget>[
            Semantics(
              key: chaveAvisoSenha,
              container: true,
              label: TextosGuias.tituloAvisoSenha,
              value: TextosGuias.avisoSenha,
              child: Container(
                decoration: BoxDecoration(
                  color: cores.superficie,
                  borderRadius: BorderRadius.circular(MemoraRaio.padrao),
                  border: Border.all(
                    color: cores.perigo,
                    width: MemoraDimensoes.bordaEnfase,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: MemoraElevacao.sombra,
                      blurRadius: MemoraElevacao.porta,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(MemoraEspacamento.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const MemoraPersonagem(
                      expressao: ExpressaoDaMemora.preocupada,
                      tamanho: MemoraDimensoes.alvoMinimo,
                    ),
                    const SizedBox(width: MemoraEspacamento.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TextoMemora(
                            TextosGuias.tituloAvisoSenha,
                            estilo: EstiloTexto.corpoForte,
                            cor: cores.perigo,
                          ),
                          const SizedBox(height: MemoraEspacamento.xs),
                          TextoMemora(
                            TextosGuias.avisoSenha,
                            cor: cores.texto,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: MemoraEspacamento.md),
          ],

          // 4. Caixa da instrução da Memora (informação acolhedora)
          Container(
            padding: const EdgeInsets.all(MemoraEspacamento.md),
            decoration: BoxDecoration(
              color: cores.superficie,
              borderRadius: BorderRadius.circular(MemoraRaio.cartao),
              border: Border.all(color: cores.borda),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: MemoraElevacao.sombra,
                  blurRadius: MemoraElevacao.cartao * 4,
                  offset: const Offset(0, MemoraElevacao.cartao),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                MemoraPersonagem(
                  expressao: eUltimoPasso
                      ? ExpressaoDaMemora.comemorando
                      : ExpressaoDaMemora.falando,
                  tamanho: MemoraDimensoes.alvoMinimo,
                ),
                const SizedBox(width: MemoraEspacamento.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (eUltimoPasso) ...<Widget>[
                        TextoMemora(
                          TextosGuias.parabens,
                          estilo: EstiloTexto.destaque,
                          cor: cores.primaria,
                        ),
                        const SizedBox(height: MemoraEspacamento.xs),
                      ],
                      TextoMemora(
                        passo.texto,
                        estilo: EstiloTexto.corpoForte,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MemoraEspacamento.xl),

          // 5. Ações (Avançar/Concluir, Dúvidas, Minha tela está diferente, Voltar, Sair)
          CaixaDeEtapa(
            instrucao: eUltimoPasso
                ? TextosGuias.instrucaoConclusao
                : TextosGuias.instrucaoAcoesPasso,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (eUltimoPasso && aoPedirParaAbrir != null) ...<Widget>[
                  BotaoSecundario(
                    key: chavePedirParaAbrir,
                    rotulo: TextosGuias.pecaParaAbrir,
                    icone: Icons.chat_bubble_outline,
                    aoTocar: aoPedirParaAbrir,
                  ),
                  const SizedBox(height: MemoraEspacamento.md),
                ],
                if (eUltimoPasso && aoTirarDuvida != null) ...<Widget>[
                  BotaoSecundario(
                    key: chaveTirarDuvida,
                    rotulo: TextosGuias.ficouComDuvida,
                    icone: Icons.chat_bubble_outline,
                    aoTocar: aoTirarDuvida,
                  ),
                  const SizedBox(height: MemoraEspacamento.md),
                ],
                BotaoPrimario(
                  key: chaveContinuar,
                  rotulo: eUltimoPasso
                      ? TextosGuias.voltarAoHub
                      : TextosGuias.continuar,
                  icone: eUltimoPasso
                      ? Icons.check_circle_outline
                      : Icons.arrow_forward,
                  aoTocar: aoContinuar,
                ),
                if (aoTelaDiferente != null) ...<Widget>[
                  const SizedBox(height: MemoraEspacamento.md),
                  BotaoSecundario(
                    key: chaveTelaDiferente,
                    rotulo: TextosGuias.telaDiferente,
                    icone: Icons.help_outline,
                    aoTocar: aoTelaDiferente,
                  ),
                ],
                if (aoVoltar != null) ...<Widget>[
                  const SizedBox(height: MemoraEspacamento.sm),
                  BotaoTerciario(
                    key: chaveVoltar,
                    rotulo: TextosGuias.voltar,
                    aoTocar: aoVoltar,
                    larguraTotal: true,
                  ),
                ],
                if (aoSair != null) ...<Widget>[
                  const SizedBox(height: MemoraEspacamento.xs),
                  BotaoTerciario(
                    key: chaveSair,
                    rotulo: TextosGuias.sairDoGuia,
                    aoTocar: aoSair,
                    larguraTotal: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (!rolar) return conteudo;
    return SingleChildScrollView(child: conteudo);
  }
}

/// A captura do passo: a moldura, o toque que a amplia e o botão logo abaixo
/// (FR-028b).
///
/// É um `State` porque precisa saber se a captura **existe**: quando ela
/// falta (FR-028a) não há o que ampliar, e oferecer a ampliação de um aviso
/// seria uma ação que não leva a nada.
class _CapturaDoPasso extends StatefulWidget {
  final Passo passo;

  const _CapturaDoPasso({required this.passo});

  @override
  State<_CapturaDoPasso> createState() => _EstadoDaCapturaDoPasso();
}

class _EstadoDaCapturaDoPasso extends State<_CapturaDoPasso> {
  bool _pendente = false;

  /// Mantém o estado da moldura quando ela troca de lugar na árvore (com a
  /// captura pendente ela deixa de ser um botão). Sem isto a captura seria
  /// buscada de novo — e reprovada de novo — a cada troca.
  final GlobalKey _chaveDaMoldura = GlobalKey(debugLabel: 'moldura do passo');

  void _ampliar() => CapturaAmpliada.abrir(context, passo: widget.passo);

  @override
  Widget build(BuildContext context) {
    final Widget moldura = _MolduraDeCelular(
      key: _chaveDaMoldura,
      passo: widget.passo,
      aoMudarPendente: (bool pendente) {
        if (pendente != _pendente) setState(() => _pendente = pendente);
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_pendente)
          moldura
        else
          // `onTap` na própria Semantics: sem ele o TalkBack anuncia o botão e
          // o duplo toque não ativa nada.
          Semantics(
            key: PassoIlustrado.chaveCapturaTocavel,
            button: true,
            label:
                '${widget.passo.descricaoDaCaptura}. ${TextosGuias.areaDestacada}',
            hint: TextosGuias.dicaAmpliar,
            onTap: _ampliar,
            excludeSemantics: true,
            child: GestureDetector(onTap: _ampliar, child: moldura),
          ),
        if (!_pendente) ...<Widget>[
          const SizedBox(height: MemoraEspacamento.sm),
          BotaoTerciario(
            key: PassoIlustrado.chaveVerImagemMaior,
            rotulo: TextosGuias.verImagemMaior,
            icone: Icons.zoom_in,
            larguraTotal: true,
            aoTocar: _ampliar,
          ),
        ],
      ],
    );
  }
}

/// Moldura que simula a tela do celular com imagem, selo de exemplo e anel de foco.
class _MolduraDeCelular extends StatelessWidget {
  final Passo passo;
  final ValueChanged<bool> aoMudarPendente;

  const _MolduraDeCelular({
    required this.passo,
    required this.aoMudarPendente,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Container(
      constraints: const BoxConstraints(
        minHeight: MemoraDimensoes.alturaMinimaMolduraPasso,
        maxHeight: MemoraDimensoes.alturaMaximaMolduraPasso,
      ),
      decoration: BoxDecoration(
        color: cores.superficieAlt,
        borderRadius: BorderRadius.circular(MemoraRaio.cartao),
        border: Border.all(
          color: cores.borda,
          width: MemoraDimensoes.bordaEnfase,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: MemoraElevacao.sombra,
            blurRadius: MemoraElevacao.porta * 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // A imagem na proporção dela, com o anel sobre a imagem (FR-028c).
          CapturaComDestaque(
            passo: passo,
            aoMudarPendente: aoMudarPendente,
            pendente: (BuildContext _) => _AvisoDeCapturaPendente(passo: passo),
          ),

          // Selo visual permanente "Exemplo" no topo direito
          const Positioned(
            key: PassoIlustrado.chaveSeloExemplo,
            top: MemoraEspacamento.sm,
            right: MemoraEspacamento.sm,
            child: SeloExemplo(),
          ),
        ],
      ),
    );
  }
}

/// O aviso que ocupa o lugar de uma captura que ainda não existe (FR-028a).
class _AvisoDeCapturaPendente extends StatelessWidget {
  final Passo passo;

  const _AvisoDeCapturaPendente({required this.passo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MemoraEspacamento.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const IlustracaoMemora(Ilustracao.estadoVazio, altura: 48),
            const SizedBox(height: MemoraEspacamento.sm),
            TextoMemora(
              TextosGuias.capturaPendente,
              estilo: EstiloTexto.corpoForte,
              alinhamento: TextAlign.center,
            ),
            const SizedBox(height: MemoraEspacamento.xs),
            TextoMemora.apoio(
              passo.descricaoDaCaptura,
              alinhamento: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
