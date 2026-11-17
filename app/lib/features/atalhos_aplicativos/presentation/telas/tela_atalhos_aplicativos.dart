import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_atalhos_aplicativos.dart';
import '../../domain/entidades/atalho_aplicativo.dart';
import '../controllers/atalhos_aplicativos_controller.dart';
import '../controllers/estado_tela_atalhos.dart';
import '../widgets/cartao_atalho_aplicativo.dart';
import '../widgets/dialogo_confirmacao_abertura.dart';
import '../widgets/dialogo_instalacao_play_store.dart';

/// Tela dedicada de atalhos diretos para os aplicativos comuns (Feature 015).
///
/// Apresenta diretamente os 7 aplicativos comuns do cotidiano (WhatsApp,
/// YouTube, Instagram, Facebook, Google Fotos, Telegram e TikTok) sem passos
/// guiados nem serviços sociais. Ao tocar em um item instalado, solicita
/// confirmação segura e redireciona para o aplicativo; se não estiver
/// instalado, orienta para a Google Play Store oficial.
class TelaAtalhosAplicativos extends StatefulWidget {
  /// Chave estável da lista rolável de aplicativos.
  static const Key chaveLista = Key('atalhos.lista');

  /// Chave estável do cartão de orientação no topo da tela.
  static const Key chaveOrientacao = Key('atalhos.orientacao');

  /// Controlador que consulta a instalação e dispara as aberturas.
  final AtalhosAplicativosController controlador;

  /// Callback de retorno à tela anterior.
  final VoidCallback? aoVoltar;

  /// Cria a tela de atalhos diretos para aplicativos.
  const TelaAtalhosAplicativos({
    required this.controlador,
    this.aoVoltar,
    super.key,
  });

  @override
  State<TelaAtalhosAplicativos> createState() => _TelaAtalhosAplicativosState();
}

class _TelaAtalhosAplicativosState extends State<TelaAtalhosAplicativos> {
  @override
  void initState() {
    super.initState();
    widget.controlador.carregar();
  }

  @override
  void didUpdateWidget(covariant TelaAtalhosAplicativos antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.controlador != widget.controlador) {
      widget.controlador.carregar();
    }
  }

  void _aoTocarNoAplicativo(AtalhoAplicativo aplicativo) {
    if (aplicativo.instalado) {
      DialogoConfirmacaoAbertura.mostrar(
        context,
        nomeAplicativo: aplicativo.nomeExibido,
        aoConfirmar: () => _executarAbertura(aplicativo),
      );
      return;
    }

    DialogoInstalacaoPlayStore.mostrar(
      context,
      nomeAplicativo: aplicativo.nomeExibido,
      aoConfirmar: () => _executarAberturaPlayStore(aplicativo),
    );
  }

  Future<void> _executarAbertura(AtalhoAplicativo aplicativo) async {
    final bool abriu = await widget.controlador.abrirAplicativo(aplicativo);
    if (!abriu && mounted) {
      _mostrarAviso(
        TextosAtalhosAplicativos.erroAoAbrirAplicativo(aplicativo.nomeExibido),
      );
    }
  }

  Future<void> _executarAberturaPlayStore(AtalhoAplicativo aplicativo) async {
    final bool abriu = await widget.controlador.abrirNaPlayStore(aplicativo);
    if (!abriu && mounted) {
      _mostrarAviso(
        TextosAtalhosAplicativos.erroAoAbrirLoja(aplicativo.nomeExibido),
      );
    }
  }

  void _mostrarAviso(String mensagem) {
    final MemoraCores cores = context.memora.cores;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: cores.superficie,
          content: Semantics(
            liveRegion: true,
            child: TextoMemora(mensagem, cor: cores.texto),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Scaffold(
      backgroundColor: cores.fundo,
      appBar: BarraSuperior(
        titulo: TextosAtalhosAplicativos.tituloTela,
        aoVoltar: widget.aoVoltar,
      ),
      body: SafeArea(
        top: false,
        child: ValueListenableBuilder<EstadoTelaAtalhos>(
          valueListenable: widget.controlador,
          builder: (BuildContext contexto, EstadoTelaAtalhos estado, _) {
            if (estado.carregando) {
              return const Center(
                child: Carregando(
                  mensagem: TextosAtalhosAplicativos.carregando,
                ),
              );
            }

            final double escala = MediaQuery.textScalerOf(contexto).scale(1);
            final bool mostrarMascote =
                escala < MemoraDimensoes.escalaTextoAlta;

            return SingleChildScrollView(
              key: TelaAtalhosAplicativos.chaveLista,
              padding: const EdgeInsets.all(MemoraEspacamento.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Cartao(
                    key: TelaAtalhosAplicativos.chaveOrientacao,
                    padding: const EdgeInsets.all(MemoraEspacamento.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (mostrarMascote) ...<Widget>[
                          const MemoraPersonagem(
                            expressao: ExpressaoDaMemora.dica,
                            tamanho: MemoraDimensoes.alvoMinimo,
                          ),
                          const SizedBox(width: MemoraEspacamento.md),
                        ],
                        const Expanded(
                          child: TextoMemora(
                            TextosAtalhosAplicativos.orientacaoTopo,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: MemoraEspacamento.lg),
                  for (final AtalhoAplicativo aplicativo
                      in estado.aplicativos) ...<Widget>[
                    CartaoAtalhoAplicativo(
                      aplicativo: aplicativo,
                      aoTocar: () => _aoTocarNoAplicativo(aplicativo),
                    ),
                    const SizedBox(height: MemoraEspacamento.sm),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
