import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_casca.dart';
import '../../domain/hub.dart';

/// Hub completo do Memora: lista todas as áreas disponíveis (Feature 007).
///
/// Destaca a ação principal ([PortaDoHub.principal]) com [CartaoHeroi] e exibe
/// as demais portas em [CartaoDePorta] modernizados, mantendo o indicador de
/// rolagem ([chaveHaMais]) quando o conteúdo excede a área visível.
class TelaHub extends StatefulWidget {
  /// Lista rolável das portas do Hub.
  static const Key chaveLista = Key('hub.lista');

  /// Estado vazio exibido quando nenhuma porta foi construída.
  static const Key chaveVazio = Key('hub.vazio');

  /// Faixa indicadora de que existem mais opções abaixo da dobra.
  static const Key chaveHaMais = Key('hub.ha_mais');

  /// Identificador estável de cada porta pelo rótulo.
  static Key chaveDaPorta(String rotulo) => Key('hub.porta.$rotulo');

  /// Portas disponíveis para a pessoa neste momento.
  final List<PortaDoHub> portas;

  /// Volta ao Início.
  final VoidCallback aoVoltar;

  /// Cria a tela do Hub.
  const TelaHub({required this.portas, required this.aoVoltar, super.key});

  @override
  State<TelaHub> createState() => _TelaHubState();
}

class _TelaHubState extends State<TelaHub> {
  final ScrollController _rolagem = ScrollController();
  bool _haMaisAbaixo = false;

  @override
  void initState() {
    super.initState();
    _rolagem.addListener(_atualizarIndicadorDeRolagem);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _atualizarIndicadorDeRolagem(),
    );
  }

  @override
  void didUpdateWidget(covariant TelaHub oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.portas.length != widget.portas.length) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _atualizarIndicadorDeRolagem(),
      );
    }
  }

  @override
  void dispose() {
    _rolagem
      ..removeListener(_atualizarIndicadorDeRolagem)
      ..dispose();
    super.dispose();
  }

  void _atualizarIndicadorDeRolagem() {
    if (!mounted || !_rolagem.hasClients) return;
    final ScrollPosition pos = _rolagem.position;
    final bool podeRolarParaBaixo = pos.maxScrollExtent - pos.pixels > 0.1;
    if (podeRolarParaBaixo != _haMaisAbaixo) {
      setState(() => _haMaisAbaixo = podeRolarParaBaixo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Scaffold(
      backgroundColor: cores.fundo,
      appBar: BarraSuperior(
        titulo: TextosCasca.tituloHub,
        aoVoltar: widget.aoVoltar,
      ),
      body: SafeArea(
        top: false,
        child: widget.portas.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(MemoraEspacamento.lg),
                child: EstadoVazio(
                  key: TelaHub.chaveVazio,
                  titulo: TextosCasca.hubVazioTitulo,
                  explicacao: TextosCasca.hubVazioExplicacao,
                ),
              )
            : Stack(
                children: <Widget>[
                  SingleChildScrollView(
                    key: TelaHub.chaveLista,
                    controller: _rolagem,
                    padding: const EdgeInsets.symmetric(
                      horizontal: MemoraEspacamento.md,
                      vertical: MemoraEspacamento.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _construirPortas(),
                    ),
                  ),
                  if (_haMaisAbaixo)
                    const Align(
                      alignment: Alignment.bottomCenter,
                      child: _FaixaHaMais(key: TelaHub.chaveHaMais),
                    ),
                ],
              ),
      ),
    );
  }

  List<Widget> _construirPortas() {
    final List<Widget> widgets = <Widget>[];
    bool principalUsada = false;

    for (int i = 0; i < widget.portas.length; i++) {
      if (i > 0) {
        widgets.add(const SizedBox(height: MemoraEspacamento.sm));
      }
      final PortaDoHub porta = widget.portas[i];
      if (porta.principal && !principalUsada) {
        principalUsada = true;
        widgets.add(
          CartaoHeroi(
            key: TelaHub.chaveDaPorta(porta.rotulo),
            titulo: porta.rotulo,
            subtitulo: porta.descricao,
            rotuloAcao: TextosCasca.acaoComecarConversa,
            icone: Icons.chat_bubble_outline_rounded,
            aoTocar: porta.aoAbrir,
          ),
        );
      } else {
        widgets.add(
          CartaoDePorta(
            key: TelaHub.chaveDaPorta(porta.rotulo),
            nome: porta.rotulo,
            explicacao: porta.descricao,
            ilustracao: porta.ilustracao,
            icone: porta.icone,
            aoAbrir: porta.aoAbrir,
          ),
        );
      }
    }
    return widgets;
  }
}

class _FaixaHaMais extends StatelessWidget {
  const _FaixaHaMais({super.key});

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final double escala = MediaQuery.textScalerOf(context).scale(1);

    if (escala >= MemoraDimensoes.escalaTextoAlta) {
      return IgnorePointer(
        child: Semantics(
          container: true,
          label: TextosCasca.hubHaMaisLeitor,
          child: ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: MemoraDimensoes.iconePadrao,
                  color: cores.primaria,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return IgnorePointer(
      child: Semantics(
        container: true,
        label: TextosCasca.hubHaMaisLeitor,
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[cores.fundo.withValues(alpha: 0), cores.fundo],
                stops: const <double>[0, 0.5],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                MemoraEspacamento.lg,
                MemoraEspacamento.xl,
                MemoraEspacamento.lg,
                MemoraEspacamento.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: MemoraDimensoes.iconePadrao,
                    color: cores.primaria,
                  ),
                  const SizedBox(width: MemoraEspacamento.sm),
                  Flexible(
                    child: TextoMemora(
                      TextosCasca.hubHaMais,
                      estilo: EstiloTexto.corpoForte,
                      cor: cores.primaria,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
