import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_antigolpe.dart';
import '../../domain/entidades/analise_golpe.dart';
import '../../domain/servicos/analisador_local_de_golpes.dart';
import '../controladores/controlador_analise_golpe.dart';

/// Tela dedicada à análise de mensagens e links suspeitos contra golpes.
///
/// Segue integralmente a skill `memora-ux`:
/// - no máximo uma `MemoraPersonagem` / `MemoraAnimada` na tela em qualquer estado;
/// - links colados ou exibidos nunca viram hiperlinks clicáveis;
/// - blocos curtos, acessibilidade WCAG 2.2 e uso exclusivo de tokens.
class TelaAnaliseGolpe extends StatefulWidget {
  /// Chave raiz da tela.
  static const Key chaveTela = Key('antigolpe.tela');

  /// Chave do campo de texto.
  static const Key chaveCampo = Key('antigolpe.campo');

  /// Chave do botão de colar da área de transferência.
  static const Key chaveBotaoColar = Key('antigolpe.colar');

  /// Chave do botão de limpar o campo e o resultado.
  static const Key chaveBotaoLimpar = Key('antigolpe.limpar');

  /// Chave do botão principal de análise.
  static const Key chaveBotaoAnalisar = Key('antigolpe.analisar');

  /// Chave do cartão de resultado.
  static const Key chaveCartaoResultado = Key('antigolpe.resultado');

  /// Chave do selo de risco.
  static const Key chaveBadgeRisco = Key('antigolpe.badge_risco');

  /// Chave do selo de origem (IA do servidor ou verificação local).
  static const Key chaveBadgeOrigem = Key('antigolpe.badge_origem');

  /// Chave do aviso exibido no modo offline.
  static const Key chaveAvisoOffline = Key('antigolpe.aviso_offline');

  /// Chave da mensagem de erro.
  static const Key chaveErro = Key('antigolpe.erro');

  /// Controlador da análise antigolpe.
  final ControladorAnaliseGolpe controlador;

  /// Callback de retorno à tela anterior.
  final VoidCallback? aoVoltar;

  /// Cria a tela de análise antigolpe.
  const TelaAnaliseGolpe({
    required this.controlador,
    this.aoVoltar,
    super.key,
  });

  @override
  State<TelaAnaliseGolpe> createState() => _TelaAnaliseGolpeState();
}

class _TelaAnaliseGolpeState extends State<TelaAnaliseGolpe> {
  final TextEditingController _campoController = TextEditingController();

  @override
  void dispose() {
    _campoController.dispose();
    super.dispose();
  }

  Future<void> _colarDaAreaTransferencia() async {
    final String? colado = await widget.controlador.colar(() async {
      final ClipboardData? dados = await Clipboard.getData(
        Clipboard.kTextPlain,
      );
      return dados?.text;
    });
    if (!mounted || colado == null) return;
    _campoController.value = TextEditingValue(
      text: colado,
      selection: TextSelection.collapsed(offset: colado.length),
    );
  }

  void _limparTudo() {
    _campoController.clear();
    widget.controlador.limpar();
  }

  void _analisar() {
    FocusScope.of(context).unfocus();
    widget.controlador.analisar(_campoController.text);
  }

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return ListenableBuilder(
      listenable: widget.controlador,
      builder: (BuildContext context, _) {
        final ControladorAnaliseGolpe c = widget.controlador;

        return Scaffold(
          key: TelaAnaliseGolpe.chaveTela,
          backgroundColor: cores.fundo,
          appBar: BarraSuperior(
            titulo: TextosAntigolpe.titulo,
            aoVoltar: widget.aoVoltar,
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(MemoraEspacamento.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (!c.carregando &&
                      c.erro == null &&
                      c.resultado == null) ...<Widget>[
                    const _CartaoConvite(),
                    const SizedBox(height: MemoraEspacamento.md),
                  ],
                  CaixaDeEtapa(
                    instrucao: TextosAntigolpe.etapaEntrada,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        CampoTexto(
                          key: TelaAnaliseGolpe.chaveCampo,
                          rotulo: TextosAntigolpe.rotuloCampo,
                          textoAjuda: TextosAntigolpe.ajudaCampo,
                          controlador: _campoController,
                          erro: c.erroCampo,
                          habilitado: !c.carregando,
                          tipoTeclado: TextInputType.multiline,
                          formatadores: <TextInputFormatter>[
                            LengthLimitingTextInputFormatter(
                              AnalisadorLocalDeGolpes.limiteCaracteres,
                            ),
                          ],
                          aoMudar: (_) => c.aoAlterarTexto(),
                        ),
                        const SizedBox(height: MemoraEspacamento.md),
                        Wrap(
                          spacing: MemoraEspacamento.sm,
                          runSpacing: MemoraEspacamento.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            BotaoSecundario(
                              key: TelaAnaliseGolpe.chaveBotaoColar,
                              rotulo: TextosAntigolpe.botaoColar,
                              icone: Icons.content_paste_rounded,
                              larguraTotal: false,
                              aoTocar: c.carregando
                                  ? null
                                  : _colarDaAreaTransferencia,
                            ),
                            BotaoTerciario(
                              key: TelaAnaliseGolpe.chaveBotaoLimpar,
                              rotulo: TextosAntigolpe.botaoLimpar,
                              icone: Icons.delete_outline_rounded,
                              aoTocar: c.carregando ? null : _limparTudo,
                            ),
                          ],
                        ),
                        const SizedBox(height: MemoraEspacamento.md),
                        BotaoPrimario(
                          key: TelaAnaliseGolpe.chaveBotaoAnalisar,
                          rotulo: TextosAntigolpe.botaoAnalisar,
                          icone: Icons.search_rounded,
                          carregando: c.carregando,
                          aoTocar: c.carregando ? null : _analisar,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: MemoraEspacamento.md),
                  if (c.carregando)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: MemoraEspacamento.lg,
                      ),
                      child: Center(
                        child: Carregando(mensagem: TextosAntigolpe.carregando),
                      ),
                    )
                  else if (c.erro != null)
                    MensagemErro(
                      key: TelaAnaliseGolpe.chaveErro,
                      mensagem: c.erro!,
                      aoTentarNovamente: _analisar,
                    )
                  else if (c.resultado != null)
                    _CartaoResultado(
                      key: TelaAnaliseGolpe.chaveCartaoResultado,
                      resultado: c.resultado!,
                    )
                  else
                    const _CartaoDicaSeguranca(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CartaoConvite extends StatelessWidget {
  const _CartaoConvite();

  @override
  Widget build(BuildContext context) {
    final bool escalaAlta =
        MediaQuery.textScalerOf(context).scale(1) >=
        MemoraDimensoes.escalaTextoAlta;

    return Cartao(
      child: escalaAlta
          ? const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Center(
                  child: MemoraPersonagem(
                    reageAoToque: false,
                  ),
                ),
                SizedBox(height: MemoraEspacamento.sm),
                TextoMemora.tituloSecao(TextosAntigolpe.conviteTitulo),
                SizedBox(height: MemoraEspacamento.xs),
                TextoMemora(TextosAntigolpe.conviteDescricao),
              ],
            )
          : const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                MemoraPersonagem(
                  reageAoToque: false,
                ),
                SizedBox(width: MemoraEspacamento.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextoMemora.tituloSecao(TextosAntigolpe.conviteTitulo),
                      SizedBox(height: MemoraEspacamento.xs),
                      TextoMemora(TextosAntigolpe.conviteDescricao),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _CartaoDicaSeguranca extends StatelessWidget {
  const _CartaoDicaSeguranca();

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Semantics(
      container: true,
      child: Cartao(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.verified_user_rounded,
              size: MemoraDimensoes.iconeDestaque,
              color: cores.primaria,
            ),
            const SizedBox(width: MemoraEspacamento.md),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextoMemora(
                    TextosAntigolpe.dicaFixaTitulo,
                    estilo: EstiloTexto.corpoForte,
                    cabecalho: true,
                  ),
                  SizedBox(height: MemoraEspacamento.xs),
                  TextoMemora.apoio(TextosAntigolpe.dicaFixaTexto),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoResultado extends StatelessWidget {
  final AnaliseGolpe resultado;

  const _CartaoResultado({required this.resultado, super.key});

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final bool ehOffline = resultado.ehOffline;

    final (
      TomBadgeStatus tomRisco,
      String rotuloRisco,
      IconData iconeRisco,
      ExpressaoDaMemora expressao,
      Color corBorda,
    ) = switch (resultado.risco) {
      NivelRisco.seguro => (
        TomBadgeStatus.positivo,
        TextosAntigolpe.riscoSeguro,
        Icons.verified_user_rounded,
        ExpressaoDaMemora.comemorando,
        cores.sucesso,
      ),
      NivelRisco.atencao => (
        TomBadgeStatus.informativo,
        TextosAntigolpe.riscoAtencao,
        Icons.warning_amber_rounded,
        ExpressaoDaMemora.preocupada,
        cores.primaria,
      ),
      NivelRisco.altoRisco => (
        TomBadgeStatus.atencao,
        TextosAntigolpe.riscoAlto,
        Icons.gpp_bad_rounded,
        ExpressaoDaMemora.preocupada,
        cores.perigo,
      ),
    };

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(MemoraEspacamento.lg),
        decoration: BoxDecoration(
          color: cores.superficie,
          borderRadius: BorderRadius.circular(MemoraRaio.cartao),
          border: Border.all(
            color: corBorda,
            width: MemoraDimensoes.bordaEnfase,
          ),
          boxShadow: MemoraElevacao.listaSombrasCartao(cores),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Wrap(
              spacing: MemoraEspacamento.sm,
              runSpacing: MemoraEspacamento.sm,
              children: <Widget>[
                BadgeDeStatus(
                  key: TelaAnaliseGolpe.chaveBadgeRisco,
                  rotulo: rotuloRisco,
                  icone: iconeRisco,
                  tom: tomRisco,
                ),
                BadgeDeStatus(
                  key: TelaAnaliseGolpe.chaveBadgeOrigem,
                  rotulo: ehOffline
                      ? TextosAntigolpe.origemLocalOffline
                      : TextosAntigolpe.origemServidorIa,
                  icone: ehOffline
                      ? Icons.wifi_off_rounded
                      : Icons.auto_awesome_rounded,
                  tom: ehOffline ? TomBadgeStatus.neutro : TomBadgeStatus.informativo,
                ),
              ],
            ),
            const SizedBox(height: MemoraEspacamento.md),
            Center(
              child: MemoraPersonagem(
                expressao: expressao,
                reageAoToque: false,
              ),
            ),
            const SizedBox(height: MemoraEspacamento.md),
            TextoMemora.tituloSecao(resultado.titulo),
            const SizedBox(height: MemoraEspacamento.xs),
            TextoMemora(resultado.explicacao),
            if (ehOffline) ...<Widget>[
              const SizedBox(height: MemoraEspacamento.md),
              Container(
                key: TelaAnaliseGolpe.chaveAvisoOffline,
                width: double.infinity,
                padding: const EdgeInsets.all(MemoraEspacamento.md),
                decoration: BoxDecoration(
                  color: cores.superficieSutil,
                  borderRadius: BorderRadius.circular(MemoraRaio.padrao),
                  border: Border.all(
                    color: cores.bordaSutil,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.info_outline_rounded,
                      size: MemoraDimensoes.iconePadrao,
                      color: cores.primaria,
                    ),
                    const SizedBox(width: MemoraEspacamento.sm),
                    const Expanded(
                      child: TextoMemora.apoio(TextosAntigolpe.avisoOffline),
                    ),
                  ],
                ),
              ),
            ],
            if (resultado.sinaisDetectados.isNotEmpty) ...<Widget>[
              const SizedBox(height: MemoraEspacamento.lg),
              const TextoMemora(
                TextosAntigolpe.tituloSinais,
                estilo: EstiloTexto.corpoForte,
                cabecalho: true,
              ),
              const SizedBox(height: MemoraEspacamento.sm),
              for (final String sinal in resultado.sinaisDetectados)
                Padding(
                  padding: const EdgeInsets.only(bottom: MemoraEspacamento.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.warning_amber_rounded,
                        size: MemoraDimensoes.iconePequeno,
                        color: resultado.risco == NivelRisco.seguro
                            ? cores.primaria
                            : cores.perigo,
                      ),
                      const SizedBox(width: MemoraEspacamento.sm),
                      Expanded(child: TextoMemora(sinal)),
                    ],
                  ),
                ),
            ],
            if (resultado.orientacoes.isNotEmpty) ...<Widget>[
              const SizedBox(height: MemoraEspacamento.lg),
              const TextoMemora(
                TextosAntigolpe.tituloOrientacoes,
                estilo: EstiloTexto.corpoForte,
                cabecalho: true,
              ),
              const SizedBox(height: MemoraEspacamento.sm),
              for (final String orientacao in resultado.orientacoes)
                Padding(
                  padding: const EdgeInsets.only(bottom: MemoraEspacamento.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: MemoraDimensoes.iconePequeno,
                        color: cores.sucessoTexto,
                      ),
                      const SizedBox(width: MemoraEspacamento.sm),
                      Expanded(child: TextoMemora(orientacao)),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
