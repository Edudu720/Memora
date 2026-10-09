import 'package:flutter/material.dart';
import '../../../../design_system/design_system.dart';
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

/// Tela dedicada à visualização e integração do Dispositivo de Cuidado (ESP32 / Wokwi).
class TelaDispositivoCuidado extends StatefulWidget {
  const TelaDispositivoCuidado({
    required this.controlador,
    required this.aoVoltar,
    this.nomePessoaIdosa = 'Usuário',
    super.key,
  });

  final ControladorDispositivoCuidado controlador;
  final VoidCallback aoVoltar;
  final String nomePessoaIdosa;

  @override
  State<TelaDispositivoCuidado> createState() =>
      _TelaDispositivoCuidadoState();
}

class _TelaDispositivoCuidadoState extends State<TelaDispositivoCuidado> {
  late final TextEditingController _controladorBroker;
  late final TextEditingController _controladorTopico;
  bool _painelWokwiAberto = false;

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
    final ControladorVerificacaoQueda ctrlQueda =
        ControladorVerificacaoQueda(
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
      MaterialPageRoute<void>(
        fullscreenDialog: true,
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
    final MemoraCores cores = context.memora.cores;

    return AnimatedBuilder(
      animation: widget.controlador,
      builder: (BuildContext ctx, Widget? _) {
        final TelemetriaIot? telemetria =
            widget.controlador.dispositivo.ultimaTelemetria;
        final StatusConexaoIot statusConexao =
            widget.controlador.dispositivo.statusConexao;
        final ContatoEmergencia? contato =
            widget.controlador.contatoEmergencia;
        final bool estaConectado =
            widget.controlador.dispositivo.estaConectado;
        final bool modoMqtt = widget.controlador.dispositivo.modoOperacao ==
            ModoOperacaoIot.mqtt;

        return Scaffold(
          backgroundColor: cores.fundo,
          body: SafeArea(
            child: Column(
              children: <Widget>[
                // Barra superior com navegação padronizada
                BarraSuperior(
                  titulo: 'Dispositivo de Cuidado',
                  aoVoltar: widget.aoVoltar,
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MemoraEspacamento.md,
                      vertical: MemoraEspacamento.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // Cartão de Estado da Conexão
                        Container(
                          padding: const EdgeInsets.all(MemoraEspacamento.md),
                          decoration: BoxDecoration(
                            color: cores.superficie,
                            borderRadius: BorderRadius.circular(MemoraRaio.padrao),
                            border: Border.all(color: cores.borda),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Container(
                                    width: MemoraEspacamento.md,
                                    height: MemoraEspacamento.md,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _corDoStatus(statusConexao, cores),
                                    ),
                                  ),
                                  const SizedBox(width: MemoraEspacamento.sm),
                                  Text(
                                    _textoDoStatus(statusConexao),
                                    style: MemoraTipografia.corpoForte.copyWith(
                                      color: cores.texto,
                                    ),
                                    textScaler: escalaTextoLimitada(context),
                                  ),
                                  const Spacer(),
                                  Text(
                                    modoMqtt ? 'Wokwi / MQTT' : 'Simulador',
                                    style: MemoraTipografia.apoio.copyWith(
                                      color: cores.textoSuave,
                                    ),
                                    textScaler: escalaTextoLimitada(context),
                                  ),
                                ],
                              ),
                              const SizedBox(height: MemoraEspacamento.sm),
                              Text(
                                estaConectado
                                    ? 'Monitorando movimentação e batimentos em tempo real.'
                                    : 'Aguardando conexão com os sensores.',
                                style: MemoraTipografia.apoio.copyWith(
                                  color: cores.textoSuave,
                                ),
                                textScaler: escalaTextoLimitada(context),
                              ),
                              const SizedBox(height: MemoraEspacamento.md),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: estaConectado
                                        ? BotaoSecundario(
                                            rotulo: 'Desconectar',
                                            aoTocar:
                                                widget.controlador.desconectar,
                                          )
                                        : BotaoPrimario(
                                            rotulo: 'Conectar agora',
                                            aoTocar:
                                                widget.controlador.conectar,
                                          ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: MemoraEspacamento.md),

                        // Medidor de BPM e Indicador de Movimento
                        MedidorBpm(bpm: telemetria?.bpm ?? 0),
                        const SizedBox(height: MemoraEspacamento.md),
                        IndicadorMovimento(
                          emMovimento: telemetria?.emMovimento ?? false,
                          nivelMovimento: telemetria?.nivelMovimento ?? 0,
                        ),

                        const SizedBox(height: MemoraEspacamento.md),

                        // Cartão do Contato de Emergência
                        Container(
                          padding: const EdgeInsets.all(MemoraEspacamento.md),
                          decoration: BoxDecoration(
                            color: cores.superficie,
                            borderRadius: BorderRadius.circular(MemoraRaio.padrao),
                            border: Border.all(color: cores.borda),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.contact_phone_rounded,
                                    color: cores.primaria,
                                    size: MemoraDimensoes.iconePadrao,
                                  ),
                                  const SizedBox(width: MemoraEspacamento.sm),
                                  Text(
                                    'Contato de Emergência',
                                    style: MemoraTipografia.corpoForte.copyWith(
                                      color: cores.texto,
                                    ),
                                    textScaler: escalaTextoLimitada(context),
                                  ),
                                ],
                              ),
                              const SizedBox(height: MemoraEspacamento.xs),
                              if (contato != null && contato.ehValido) ...<Widget>[
                                Text(
                                  '${contato.nome} (${contato.parentesco})',
                                  style: MemoraTipografia.corpoForte.copyWith(
                                    color: cores.texto,
                                  ),
                                  textScaler: escalaTextoLimitada(context),
                                ),
                                const SizedBox(height: MemoraEspacamento.xs),
                                Text(
                                  contato.telefone,
                                  style: MemoraTipografia.apoio.copyWith(
                                    color: cores.textoSuave,
                                  ),
                                  textScaler: escalaTextoLimitada(context),
                                ),
                                const SizedBox(height: MemoraEspacamento.sm),
                                BotaoSecundario(
                                  rotulo: 'Alterar contato',
                                  aoTocar: _abrirDialogoContato,
                                ),
                              ] else ...<Widget>[
                                Text(
                                  'Nenhum contato cadastrado. Cadastre alguém para receber avisos caso sofra uma queda.',
                                  style: MemoraTipografia.apoio.copyWith(
                                    color: cores.textoSuave,
                                  ),
                                  textScaler: escalaTextoLimitada(context),
                                ),
                                const SizedBox(height: MemoraEspacamento.sm),
                                BotaoPrimario(
                                  rotulo: 'Cadastrar contato',
                                  aoTocar: _abrirDialogoContato,
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: MemoraEspacamento.md),

                        // Seção de Testes e Simulação Wokwi
                        Container(
                          padding: const EdgeInsets.all(MemoraEspacamento.md),
                          decoration: BoxDecoration(
                            color: cores.superficie,
                            borderRadius: BorderRadius.circular(MemoraRaio.padrao),
                            border: Border.all(color: cores.borda),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _painelWokwiAberto = !_painelWokwiAberto;
                                  });
                                },
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.settings_input_antenna_rounded,
                                      color: cores.primaria,
                                      size: MemoraDimensoes.iconePadrao,
                                    ),
                                    const SizedBox(width: MemoraEspacamento.sm),
                                    Text(
                                      'Integração Wokwi & Testes',
                                      style: MemoraTipografia.corpoForte.copyWith(
                                        color: cores.texto,
                                      ),
                                      textScaler: escalaTextoLimitada(context),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      _painelWokwiAberto
                                          ? Icons.expand_less_rounded
                                          : Icons.expand_more_rounded,
                                      color: cores.textoSuave,
                                    ),
                                  ],
                                ),
                              ),
                              if (_painelWokwiAberto) ...<Widget>[
                                const SizedBox(height: MemoraEspacamento.md),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: BotaoSecundario(
                                        rotulo: modoMqtt ? 'Usar Simulador' : 'Simulador Ativo',
                                        aoTocar: () {
                                          widget.controlador.alternarModo(
                                            ModoOperacaoIot.simulado,
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: MemoraEspacamento.sm),
                                    Expanded(
                                      child: BotaoSecundario(
                                        rotulo: modoMqtt ? 'Wokwi Ativo' : 'Usar Wokwi',
                                        aoTocar: () {
                                          widget.controlador.alternarModo(
                                            ModoOperacaoIot.mqtt,
                                            broker: _controladorBroker.text.trim(),
                                            topico: _controladorTopico.text.trim(),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                if (modoMqtt) ...<Widget>[
                                  const SizedBox(height: MemoraEspacamento.sm),
                                  CampoTexto(
                                    rotulo: 'Broker MQTT',
                                    textoAjuda: 'Endereço do broker (ex.: broker.hivemq.com)',
                                    controlador: _controladorBroker,
                                  ),
                                  const SizedBox(height: MemoraEspacamento.sm),
                                  CampoTexto(
                                    rotulo: 'Tópico Base',
                                    textoAjuda: 'Prefixo dos tópicos (ex.: memora/iot/demonstracao-01)',
                                    controlador: _controladorTopico,
                                  ),
                                  const SizedBox(height: MemoraEspacamento.sm),
                                  BotaoPrimario(
                                    rotulo: 'Reconectar ao Wokwi',
                                    aoTocar: () {
                                      widget.controlador.alternarModo(
                                        ModoOperacaoIot.mqtt,
                                        broker: _controladorBroker.text.trim(),
                                        topico: _controladorTopico.text.trim(),
                                      );
                                    },
                                  ),
                                ],
                                const SizedBox(height: MemoraEspacamento.md),
                                BotaoPerigo(
                                  rotulo: 'Simular Queda de Teste',
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
              ],
            ),
          ),
        );
      },
    );
  }

  static Color _corDoStatus(StatusConexaoIot status, MemoraCores cores) {
    switch (status) {
      case StatusConexaoIot.conectado:
        return cores.sucesso;
      case StatusConexaoIot.conectando:
        return cores.primaria;
      case StatusConexaoIot.desconectado:
        return cores.textoSuave;
    }
  }

  static String _textoDoStatus(StatusConexaoIot status) {
    switch (status) {
      case StatusConexaoIot.conectado:
        return 'Dispositivo Conectado';
      case StatusConexaoIot.conectando:
        return 'Conectando ao dispositivo...';
      case StatusConexaoIot.desconectado:
        return 'Dispositivo Desconectado';
    }
  }
}
