import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_cuidado.dart';
import '../../domain/casos_de_uso/disparar_socorro_emergencia.dart';
import '../../domain/entidades/contato_emergencia.dart';
import '../../domain/entidades/enums_cuidado.dart';
import '../../domain/entidades/evento_queda.dart';
import '../../domain/entidades/telemetria_iot.dart';
import '../controladores/controlador_dispositivo_cuidado.dart';
import '../controladores/controlador_verificacao_queda.dart';
import '../widgets/indicador_movimento.dart';
import '../widgets/medidor_bpm.dart';
import 'dialogo_contato_emergencia.dart';
import 'tela_verificacao_queda.dart';

/// Tela dedicada à visualização e integração do Dispositivo de Cuidado (ESP32 Físico / Simulador).
class TelaDispositivoCuidado extends StatefulWidget {
  /// Cria a tela do dispositivo de cuidado.
  const TelaDispositivoCuidado({
    required this.controlador,
    required this.aoVoltar,
    this.nomePessoaIdosa = 'Usuário',
    super.key,
  });

  /// Controlador que gerencia o estado da conexão e telemetria.
  final ControladorDispositivoCuidado controlador;

  /// Callback para retornar à tela anterior.
  final VoidCallback aoVoltar;

  /// Nome da pessoa idosa monitorada.
  final String nomePessoaIdosa;

  @override
  State<TelaDispositivoCuidado> createState() => _TelaDispositivoCuidadoState();
}

class _TelaDispositivoCuidadoState extends State<TelaDispositivoCuidado> {
  late final TextEditingController _controladorBroker;
  late final TextEditingController _controladorTopico;
  bool _painelConexaoAberto = false;

  @override
  void initState() {
    super.initState();
    _controladorBroker = TextEditingController(
      text: widget.controlador.dispositivo.brokerHost,
    );
    _controladorTopico = TextEditingController(
      text: widget.controlador.dispositivo.topicoBase,
    );

    widget.controlador.addListener(_verificarQuedaAtiva);
  }

  @override
  void dispose() {
    widget.controlador.removeListener(_verificarQuedaAtiva);
    _controladorBroker.dispose();
    _controladorTopico.dispose();
    super.dispose();
  }

  void _verificarQuedaAtiva() {
    final EventoQueda? queda = widget.controlador.quedaAtiva;
    if (queda != null && mounted) {
      widget.controlador.limparQuedaAtiva();
      _abrirTelaVerificacaoQueda(queda);
    }
  }

  void _abrirTelaVerificacaoQueda(EventoQueda queda) {
    final ControladorVerificacaoQueda ctrlQueda = ControladorVerificacaoQueda(
      evento: queda,
      provedor: widget.controlador.provedor,
      casoDeUsoSocorro: const DispararSocorroEmergencia(),
      nomePessoaIdosa: widget.nomePessoaIdosa,
      contatoEmergencia: widget.controlador.contatoEmergencia,
      aoEncerrar: () {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );

    Navigator.of(context).push<void>(
      // Uma pergunta que cobre tudo: sobe por cima, e a tela de trás fica
      // onde está (FR-010).
      RotaMemora<void>(
        fullscreenDialog: true,
        direcao: DirecaoDaTransicao.sobrepor,
        builder: (BuildContext ctx) =>
            TelaVerificacaoQueda(controlador: ctrlQueda),
      ),
    );
  }

  void _abrirDialogoContato() {
    DialogoContatoEmergencia.exibir(
      context: context,
      contatoAtual: widget.controlador.contatoEmergencia,
      aoSalvar: (ContatoEmergencia novoContato) {
        widget.controlador.salvarContato(novoContato);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final double escala = MediaQuery.textScalerOf(context).scale(1);

    return AnimatedBuilder(
      animation: widget.controlador,
      builder: (BuildContext ctx, Widget? _) {
        final TelemetriaIot? telemetria =
            widget.controlador.dispositivo.ultimaTelemetria;
        final StatusConexaoIot statusConexao =
            widget.controlador.dispositivo.statusConexao;
        final ContatoEmergencia? contato = widget.controlador.contatoEmergencia;
        final bool estaConectado = widget.controlador.dispositivo.estaConectado;
        final bool modoMqtt =
            widget.controlador.dispositivo.modoOperacao == ModoOperacaoIot.mqtt;
        final bool bpmValido = telemetria?.bpmValido ?? false;
        final String valorHeroi = bpmValido
            ? '${telemetria!.bpm} ${TextosCuidado.unidadeBpm}'
            : '-- ${TextosCuidado.unidadeBpm}';

        return Scaffold(
          backgroundColor: cores.fundo,
          appBar: BarraSuperior(
            titulo: TextosCuidado.tituloDispositivo,
            aoVoltar: widget.aoVoltar,
            // A Memora desta tela é a do painel (FR-006).
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: MemoraEspacamento.md,
                vertical: MemoraEspacamento.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  PainelHeroi(
                    titulo: _textoDoStatus(statusConexao),
                    valorDestaque: valorHeroi,
                    subtitulo:
                        '${modoMqtt ? TextosCuidado.modoMqtt : TextosCuidado.modoSimulador} · ${estaConectado ? TextosCuidado.resumoMonitorando : TextosCuidado.resumoAguardando}',
                    visualEsquerda: const MemoraPersonagem(
                      tamanho: MemoraDimensoes.alvoDecisao,
                    ),
                    badgeStatus: BadgeDeStatus(
                      rotulo: estaConectado
                          ? TextosCuidado.badgeMonitoramentoAtivo
                          : TextosCuidado.badgeAguardandoVinculo,
                      icone: estaConectado
                          ? Icons.favorite_rounded
                          : Icons.sensors_off_rounded,
                      tom: _tomDoBadge(statusConexao),
                    ),
                  ),

                  const SizedBox(height: MemoraEspacamento.md),

                  if (estaConectado)
                    BotaoSecundario(
                      rotulo: TextosCuidado.botaoDesconectar,
                      icone: Icons.link_off_rounded,
                      aoTocar: widget.controlador.desconectar,
                    )
                  else
                    BotaoPrimario(
                      rotulo: TextosCuidado.botaoConectar,
                      icone: Icons.link_rounded,
                      aoTocar: widget.controlador.conectar,
                    ),

                  const SizedBox(height: MemoraEspacamento.lg),

                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints box) {
                      final bool emDuasColunas =
                          box.maxWidth >= MemoraDimensoes.larguraMinimaGrade &&
                          escala < MemoraDimensoes.escalaColapsoGrade;

                      final Widget cardBpm = MedidorBpm(
                        bpm: telemetria?.bpm ?? 0,
                        bpmValido: bpmValido,
                      );
                      final Widget cardMovimento = IndicadorMovimento(
                        emMovimento: telemetria?.emMovimento ?? false,
                        nivelMovimento: telemetria?.nivelMovimento ?? 0,
                      );

                      if (!emDuasColunas) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            cardBpm,
                            const SizedBox(height: MemoraEspacamento.md),
                            cardMovimento,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(child: cardBpm),
                          const SizedBox(width: MemoraEspacamento.sm),
                          Expanded(child: cardMovimento),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: MemoraEspacamento.lg),

                  const TextoMemora(
                    TextosCuidado.tituloAcoesRapidas,
                    estilo: EstiloTexto.tituloSecao,
                    cabecalho: true,
                  ),
                  const SizedBox(height: MemoraEspacamento.sm),

                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints box) {
                      final bool emDuasColunas =
                          box.maxWidth >= MemoraDimensoes.larguraMinimaGrade &&
                          escala < MemoraDimensoes.escalaColapsoGrade;

                      final Widget tileContato = TileAcaoRapida(
                        icone: Icons.contact_phone_rounded,
                        titulo: TextosCuidado.tituloContatoEmergencia,
                        subtitulo: (contato != null && contato.ehValido)
                            ? (contato.temEmailValido
                                  ? '${contato.nome} (${contato.parentesco}) · ${contato.telefone} · ${contato.email.trim()}'
                                  : '${contato.nome} (${contato.parentesco}) · ${contato.telefone}')
                            : TextosCuidado.pistaCadastrarContato,
                        variacao: VarianteBadge.saude,
                        pistaAcao: (contato != null && contato.ehValido)
                            ? TextosCuidado.pistaAlterarContato
                            : TextosCuidado.pistaCadastrarContato,
                        aoTocar: _abrirDialogoContato,
                      );

                      final Widget tileVinculo = TileAcaoRapida(
                        icone: Icons.sensors_rounded,
                        titulo: TextosCuidado.tituloAtalhoConexao,
                        subtitulo: estaConectado
                            ? TextosCuidado.subtituloAtalhoDesconectar
                            : TextosCuidado.subtituloAtalhoConectar,
                        pistaAcao: estaConectado
                            ? TextosCuidado.botaoDesconectar
                            : TextosCuidado.botaoConectar,
                        aoTocar: estaConectado
                            ? widget.controlador.desconectar
                            : widget.controlador.conectar,
                      );

                      final Widget tileSimulador = TileAcaoRapida(
                        icone: Icons.phonelink_setup_rounded,
                        titulo: TextosCuidado.tituloAtalhoSimulador,
                        subtitulo: modoMqtt
                            ? TextosCuidado.subtituloTrocarSimulador
                            : TextosCuidado.subtituloSimuladorAtivo,
                        variacao: VarianteBadge.neutro,
                        pistaAcao: TextosCuidado.pistaAtalhoSimulador,
                        aoTocar: () {
                          widget.controlador.alternarModo(
                            ModoOperacaoIot.simulado,
                          );
                        },
                      );

                      final Widget tileTecnico = TileAcaoRapida(
                        icone: Icons.settings_input_antenna_rounded,
                        titulo: TextosCuidado.tituloAtalhoTecnico,
                        subtitulo: TextosCuidado.subtituloAtalhoTecnico,
                        variacao: VarianteBadge.neutro,
                        pistaAcao: _painelConexaoAberto
                            ? TextosCuidado.pistaFecharTecnico
                            : TextosCuidado.pistaAbrirTecnico,
                        aoTocar: () {
                          setState(() {
                            _painelConexaoAberto = !_painelConexaoAberto;
                          });
                        },
                      );

                      if (!emDuasColunas) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            tileContato,
                            const SizedBox(height: MemoraEspacamento.sm),
                            tileVinculo,
                            const SizedBox(height: MemoraEspacamento.sm),
                            tileSimulador,
                            const SizedBox(height: MemoraEspacamento.sm),
                            tileTecnico,
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(child: tileContato),
                              const SizedBox(width: MemoraEspacamento.sm),
                              Expanded(child: tileVinculo),
                            ],
                          ),
                          const SizedBox(height: MemoraEspacamento.sm),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(child: tileSimulador),
                              const SizedBox(width: MemoraEspacamento.sm),
                              Expanded(child: tileTecnico),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: MemoraEspacamento.md),

                  // Painel técnico recolhível discreto (MQTT / Simulação)
                  Cartao(
                    comBorda: ehAltoContraste,
                    padding: const EdgeInsets.all(MemoraEspacamento.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Semantics(
                          button: true,
                          label: TextosCuidado.tituloConexaoEsp32Testes,
                          hint: TextosCuidado.subtituloDetalhesTecnicos,
                          onTap: () {
                            setState(() {
                              _painelConexaoAberto = !_painelConexaoAberto;
                            });
                          },
                          excludeSemantics: true,
                          child: Material(
                            color: cores.superficieSutil,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                MemoraRaio.cartaoMedio,
                              ),
                              side: ehAltoContraste
                                  ? BorderSide(
                                      color: cores.borda,
                                      width: MemoraDimensoes.bordaEnfase,
                                    )
                                  : BorderSide.none,
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                MemoraRaio.cartaoMedio,
                              ),
                              onTap: () {
                                setState(() {
                                  _painelConexaoAberto = !_painelConexaoAberto;
                                });
                              },
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: MemoraDimensoes.alvoMinimo,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: MemoraEspacamento.md,
                                    vertical: MemoraEspacamento.sm,
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Icon(
                                        Icons.settings_input_antenna_rounded,
                                        color: ehAltoContraste
                                            ? cores.texto
                                            : cores.primaria,
                                        size: MemoraDimensoes.iconePadrao,
                                      ),
                                      const SizedBox(
                                        width: MemoraEspacamento.sm,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            const TextoMemora(
                                              TextosCuidado
                                                  .tituloConexaoEsp32Testes,
                                              estilo: EstiloTexto.corpoForte,
                                            ),
                                            TextoMemora.apoio(
                                              TextosCuidado
                                                  .subtituloDetalhesTecnicos,
                                              cor: cores.textoSuave,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        width: MemoraEspacamento.sm,
                                      ),
                                      Icon(
                                        _painelConexaoAberto
                                            ? Icons.expand_less_rounded
                                            : Icons.expand_more_rounded,
                                        color: cores.texto,
                                        size: MemoraDimensoes.iconePadrao,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_painelConexaoAberto) ...<Widget>[
                          const SizedBox(height: MemoraEspacamento.md),
                          LayoutBuilder(
                            builder:
                                (BuildContext context, BoxConstraints box) {
                              final bool ladoALado =
                                  box.maxWidth >=
                                      MemoraDimensoes.larguraMinimaGrade &&
                                  escala < MemoraDimensoes.escalaColapsoGrade;

                              final Widget btnSimulador = BotaoSecundario(
                                rotulo: modoMqtt
                                    ? TextosCuidado.botaoUsarSimulador
                                    : TextosCuidado.botaoSimuladorAtivo,
                                aoTocar: () {
                                  widget.controlador.alternarModo(
                                    ModoOperacaoIot.simulado,
                                  );
                                },
                              );
                              final Widget btnEsp32 = BotaoSecundario(
                                rotulo: modoMqtt
                                    ? TextosCuidado.botaoEsp32Ativo
                                    : TextosCuidado.botaoUsarEsp32,
                                aoTocar: () {
                                  widget.controlador.alternarModo(
                                    ModoOperacaoIot.mqtt,
                                    broker: _controladorBroker.text.trim(),
                                    topico: _controladorTopico.text.trim(),
                                  );
                                },
                              );

                              if (ladoALado) {
                                return Row(
                                  children: <Widget>[
                                    Expanded(child: btnSimulador),
                                    const SizedBox(width: MemoraEspacamento.sm),
                                    Expanded(child: btnEsp32),
                                  ],
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  btnSimulador,
                                  const SizedBox(height: MemoraEspacamento.sm),
                                  btnEsp32,
                                ],
                              );
                            },
                          ),
                          if (modoMqtt) ...<Widget>[
                            const SizedBox(height: MemoraEspacamento.md),
                            CampoTexto(
                              rotulo: TextosCuidado.rotuloBrokerMqtt,
                              textoAjuda: TextosCuidado.ajudaBrokerMqtt,
                              controlador: _controladorBroker,
                            ),
                            const SizedBox(height: MemoraEspacamento.sm),
                            CampoTexto(
                              rotulo: TextosCuidado.rotuloTopicoBase,
                              textoAjuda: TextosCuidado.ajudaTopicoBase,
                              controlador: _controladorTopico,
                            ),
                            const SizedBox(height: MemoraEspacamento.md),
                            BotaoPrimario(
                              rotulo: TextosCuidado.botaoReconectarEsp32,
                              aoTocar: () {
                                widget.controlador.alternarModo(
                                  ModoOperacaoIot.mqtt,
                                  broker: _controladorBroker.text.trim(),
                                  topico: _controladorTopico.text.trim(),
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: MemoraEspacamento.xl),
                          BotaoPerigo(
                            rotulo: TextosCuidado.botaoSimularQueda,
                            icone: Icons.notification_important_rounded,
                            aoTocar: widget.controlador.simularQuedaTeste,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: MemoraEspacamento.lg),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static TomBadgeStatus _tomDoBadge(StatusConexaoIot status) {
    switch (status) {
      case StatusConexaoIot.conectado:
        return TomBadgeStatus.positivo;
      case StatusConexaoIot.conectando:
        return TomBadgeStatus.informativo;
      case StatusConexaoIot.desconectado:
        return TomBadgeStatus.neutro;
    }
  }

  static String _textoDoStatus(StatusConexaoIot status) {
    switch (status) {
      case StatusConexaoIot.conectado:
        return TextosCuidado.statusConectado;
      case StatusConexaoIot.conectando:
        return TextosCuidado.statusConectando;
      case StatusConexaoIot.desconectado:
        return TextosCuidado.statusDesconectado;
    }
  }
}
