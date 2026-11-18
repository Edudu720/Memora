import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_sos.dart';
import '../../domain/entidades/contato_emergencia.dart';
import '../controladores/controlador_sos_emergencia.dart';

/// Exibe o diálogo de confirmação e encaminhamento do pedido SOS no `Navigator`
/// ativo para nunca sobreviver a uma expiração de sessão (BR-005).
Future<void> mostrarDialogoSosEmergencia({
  required BuildContext context,
  required ControladorSosEmergencia controlador,
}) {
  return showDialog<void>(
    context: context,
    useRootNavigator: false,
    builder: (BuildContext _) => DialogoSosEmergencia(controlador: controlador),
  );
}

/// Modal acessível de confirmação, envio e contingência do Botão SOS (Feature 014).
class DialogoSosEmergencia extends StatefulWidget {
  /// Chave raiz do diálogo modal.
  static const Key chaveDialogo = Key('sos.dialogo');

  /// Chave do botão que confirma o pedido SOS.
  static const Key chaveConfirmar = Key('sos.confirmar');

  /// Chave do botão que cancela o pedido SOS antes do envio.
  static const Key chaveCancelar = Key('sos.cancelar');

  /// Chave do botão de contingência para acionar o contato pelo celular.
  static const Key chaveAcionarAparelho = Key('sos.acionar_aparelho');

  /// Chave do botão explícito de chamada para o SAMU (192).
  static const Key chaveLigar192 = Key('sos.ligar_192');

  /// Chave do botão de fechar após resultado ou falha.
  static const Key chaveFechar = Key('sos.fechar');

  /// Controlador que gerencia o ciclo deste diálogo.
  final ControladorSosEmergencia controlador;

  /// Cria o diálogo modal do botão SOS.
  const DialogoSosEmergencia({
    required this.controlador,
    super.key,
  });

  @override
  State<DialogoSosEmergencia> createState() => _DialogoSosEmergenciaState();
}

class _DialogoSosEmergenciaState extends State<DialogoSosEmergencia> {
  @override
  void initState() {
    super.initState();
    if (!widget.controlador.preparacaoConcluida) {
      widget.controlador.prepararConfirmacao();
    }
  }

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;

    return Dialog(
      key: DialogoSosEmergencia.chaveDialogo,
      backgroundColor: cores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MemoraRaio.cartao),
        side: BorderSide(
          color: ehAltoContraste ? cores.borda : cores.bordaSutil,
          width: ehAltoContraste
              ? MemoraDimensoes.bordaSelecao
              : MemoraDimensoes.espessuraBordaSutil,
        ),
      ),
      child: ListenableBuilder(
        listenable: widget.controlador,
        builder: (BuildContext contexto, _) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(MemoraEspacamento.lg),
              child: switch (widget.controlador.etapa) {
                EtapaFluxoSos.confirmacao => _construirConfirmacao(
                  contexto,
                  cores,
                  ehAltoContraste,
                ),
                EtapaFluxoSos.processando => _construirProcessando(cores),
                EtapaFluxoSos.enviado => _construirEnviado(contexto, cores),
                EtapaFluxoSos.falhaConexao ||
                EtapaFluxoSos.falhaEntrega =>
                  _construirFalha(contexto, cores),
              },
            ),
          );
        },
      ),
    );
  }

  Widget _construirConfirmacao(
    BuildContext context,
    MemoraCores cores,
    bool ehAltoContraste,
  ) {
    final ContatoEmergencia? contato = widget.controlador.contato;
    final bool temContato = widget.controlador.temContatoValido;
    final bool temLoc = widget.controlador.localizacaoAtual != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              Icons.sos_rounded,
              color: cores.perigo,
              size: MemoraDimensoes.iconeDestaque,
            ),
            const SizedBox(width: MemoraEspacamento.sm),
            const Expanded(
              child: TextoMemora.tituloSecao(TextosSos.tituloConfirmacao),
            ),
          ],
        ),
        const SizedBox(height: MemoraEspacamento.md),
        TextoMemora(
          temContato
              ? TextosSos.mensagemConfirmacao
              : TextosSos.mensagemSemContatoConfirmacao,
        ),
        if (temContato && contato != null) ...<Widget>[
          const SizedBox(height: MemoraEspacamento.md),
          Cartao(
            comBorda: ehAltoContraste,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextoMemora.apoio(
                  TextosSos.contatoIdentificado,
                  cor: cores.textoSuave,
                ),
                const SizedBox(height: MemoraEspacamento.xs),
                TextoMemora(
                  '${contato.nome} (${contato.telefone})',
                  estilo: EstiloTexto.corpoForte,
                ),
                const SizedBox(height: MemoraEspacamento.xs),
                TextoMemora.apoio(
                  contato.temEmailValido
                      ? contato.email.trim()
                      : TextosSos.avisoContatoSemEmail,
                  cor: cores.textoSuave,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: MemoraEspacamento.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              temLoc ? Icons.location_on_rounded : Icons.location_off_rounded,
              color: cores.textoSuave,
              size: MemoraDimensoes.iconePequeno,
            ),
            const SizedBox(width: MemoraEspacamento.xs),
            Expanded(
              child: TextoMemora.apoio(
                temLoc
                    ? TextosSos.localizacaoAutorizada
                    : TextosSos.localizacaoNaoAutorizada,
                cor: cores.textoSuave,
              ),
            ),
          ],
        ),
        const SizedBox(height: MemoraEspacamento.lg),
        if (temContato)
          BotaoPrimario(
            key: DialogoSosEmergencia.chaveConfirmar,
            rotulo: TextosSos.botaoConfirmarSos,
            icone: Icons.sos_rounded,
            aoTocar: widget.controlador.confirmarEnvioSos,
          )
        else ...<Widget>[
          BotaoPrimario(
            key: DialogoSosEmergencia.chaveLigar192,
            rotulo: TextosSos.botaoLigar192,
            icone: Icons.local_hospital_rounded,
            aoTocar: widget.controlador.ligarEmergencia192,
          ),
          const SizedBox(height: MemoraEspacamento.md),
          BotaoSecundario(
            key: DialogoSosEmergencia.chaveConfirmar,
            rotulo: TextosSos.botaoConfirmarSos,
            icone: Icons.sos_rounded,
            aoTocar: widget.controlador.confirmarEnvioSos,
          ),
        ],
        const SizedBox(height: MemoraEspacamento.md),
        BotaoSecundario(
          key: DialogoSosEmergencia.chaveCancelar,
          rotulo: TextosSos.botaoCancelarSos,
          icone: Icons.close_rounded,
          aoTocar: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: MemoraEspacamento.md),
        TextoMemora.apoio(
          TextosSos.orientacaoEmergenciaPublica,
          cor: cores.textoSuave,
        ),
      ],
    );
  }

  Widget _construirProcessando(MemoraCores cores) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Align(
          alignment: Alignment.centerLeft,
          child: BadgeDeStatus(
            rotulo: TextosSos.tituloProcessando,
            tom: TomBadgeStatus.neutro,
            icone: Icons.hourglass_top_rounded,
          ),
        ),
        const SizedBox(height: MemoraEspacamento.md),
        const TextoMemora(TextosSos.mensagemProcessando),
        const SizedBox(height: MemoraEspacamento.lg),
        const Carregando(mensagem: TextosSos.tituloProcessando),
      ],
    );
  }

  Widget _construirEnviado(BuildContext context, MemoraCores cores) {
    final bool temContato = widget.controlador.temContatoValido;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Align(
          alignment: Alignment.centerLeft,
          child: BadgeDeStatus(
            rotulo: TextosSos.tituloEnviado,
            icone: Icons.check_circle_rounded,
          ),
        ),
        const SizedBox(height: MemoraEspacamento.md),
        TextoMemora(widget.controlador.mensagemResultado),
        const SizedBox(height: MemoraEspacamento.lg),
        if (temContato) ...<Widget>[
          BotaoSecundario(
            key: DialogoSosEmergencia.chaveAcionarAparelho,
            rotulo: TextosSos.botaoAcionarPeloAparelho,
            icone: Icons.phone_forwarded_rounded,
            aoTocar: widget.controlador.acionarContatoPeloAparelho,
          ),
          const SizedBox(height: MemoraEspacamento.md),
        ],
        BotaoSecundario(
          key: DialogoSosEmergencia.chaveLigar192,
          rotulo: TextosSos.botaoLigar192,
          icone: Icons.local_hospital_rounded,
          aoTocar: widget.controlador.ligarEmergencia192,
        ),
        const SizedBox(height: MemoraEspacamento.md),
        BotaoPrimario(
          key: DialogoSosEmergencia.chaveFechar,
          rotulo: TextosSos.botaoFecharSos,
          icone: Icons.check_rounded,
          aoTocar: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _construirFalha(BuildContext context, MemoraCores cores) {
    final bool ehSemInternet =
        widget.controlador.etapa == EtapaFluxoSos.falhaConexao;
    final bool temContato = widget.controlador.temContatoValido;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: BadgeDeStatus(
            rotulo: ehSemInternet
                ? TextosSos.tituloFalhaConexao
                : TextosSos.tituloFalhaEntrega,
            tom: TomBadgeStatus.atencao,
            icone: Icons.warning_amber_rounded,
          ),
        ),
        const SizedBox(height: MemoraEspacamento.md),
        TextoMemora(widget.controlador.mensagemResultado),
        const SizedBox(height: MemoraEspacamento.lg),
        if (temContato) ...<Widget>[
          BotaoPrimario(
            key: DialogoSosEmergencia.chaveAcionarAparelho,
            rotulo: TextosSos.botaoAcionarPeloAparelho,
            icone: Icons.phone_forwarded_rounded,
            aoTocar: widget.controlador.acionarContatoPeloAparelho,
          ),
          const SizedBox(height: MemoraEspacamento.md),
          BotaoSecundario(
            key: DialogoSosEmergencia.chaveLigar192,
            rotulo: TextosSos.botaoLigar192,
            icone: Icons.local_hospital_rounded,
            aoTocar: widget.controlador.ligarEmergencia192,
          ),
        ] else ...<Widget>[
          BotaoPrimario(
            key: DialogoSosEmergencia.chaveLigar192,
            rotulo: TextosSos.botaoLigar192,
            icone: Icons.local_hospital_rounded,
            aoTocar: widget.controlador.ligarEmergencia192,
          ),
        ],
        const SizedBox(height: MemoraEspacamento.md),
        BotaoSecundario(
          key: DialogoSosEmergencia.chaveFechar,
          rotulo: TextosSos.botaoFecharSos,
          icone: Icons.close_rounded,
          aoTocar: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
