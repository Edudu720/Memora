import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entidades/estabelecimento_servico.dart';

/// Mapa acessível em alto contraste com marcadores táteis ampliados e zoom dedicado (FR-009, NFR-001).
class MapaServicosAcessivel extends StatefulWidget {
  /// Lista de estabelecimentos exibidos como pinos no mapa.
  final List<EstabelecimentoServico> estabelecimentos;

  /// Coordenada inicial centralizada ao abrir o mapa.
  final LatLng centroInicial;

  /// Callback acionado quando a pessoa toca em um marcador.
  final ValueChanged<EstabelecimentoServico> aoSelecionar;

  /// Cria o mapa interativo acessível de serviços.
  const MapaServicosAcessivel({
    required this.estabelecimentos,
    required this.centroInicial,
    required this.aoSelecionar,
    super.key,
  });

  /// Chave do botão dedicado para aproximar o mapa.
  static const Key chaveZoomMais = Key('mapa.zoom_mais');

  /// Chave do botão dedicado para afastar o mapa.
  static const Key chaveZoomMenos = Key('mapa.zoom_menos');

  /// Chave do marcador tátil de um estabelecimento pelo seu [id].
  static Key chaveMarcador(String id) => Key('mapa.marcador.$id');

  @override
  State<MapaServicosAcessivel> createState() => _MapaServicosAcessivelState();
}

class _MapaServicosAcessivelState extends State<MapaServicosAcessivel> {
  final MapController _mapController = MapController();
  double _zoomAtual = 14.5;

  void _ajustarZoom(double delta) {
    setState(() {
      _zoomAtual = (_zoomAtual + delta).clamp(3.0, 18.0);
      _mapController.move(_mapController.camera.center, _zoomAtual);
    });
  }

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;

    final List<Marker> marcadores = widget.estabelecimentos
        .where((EstabelecimentoServico e) => e.temCoordenadas)
        .map((EstabelecimentoServico e) {
      final Color corPino = e.categoria.name == 'emergencia'
          ? cores.perigo
          : cores.primaria;

      return Marker(
        point: LatLng(e.latitude!, e.longitude!),
        width: MemoraDimensoes.alvoDecisao,
        height: MemoraDimensoes.alvoDecisao,
        child: GestureDetector(
          key: MapaServicosAcessivel.chaveMarcador(e.id),
          onTap: () => widget.aoSelecionar(e),
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(MemoraEspacamento.xs),
                decoration: BoxDecoration(
                  color: corPino,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ehAltoContraste ? cores.borda : cores.superficie,
                    width: MemoraDimensoes.bordaEnfase,
                  ),
                  boxShadow: MemoraElevacao.listaSombrasCartao(cores),
                ),
                child: Icon(
                  e.categoria.icone,
                  size: MemoraDimensoes.iconePadrao,
                  color: cores.sobrePrimaria,
                ),
              ),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: MemoraDimensoes.iconePequeno,
                color: corPino,
              ),
            ],
          ),
        ),
      );
    }).toList();

    return Stack(
      children: <Widget>[
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.centroInicial,
            initialZoom: _zoomAtual,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: <Widget>[
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'br.fatec.memora',
            ),
            MarkerLayer(markers: marcadores),
          ],
        ),

        // Botões táteis de zoom (+ Mais / - Menos) com alvo ampliado e >= 8 dp de separação
        Positioned(
          right: MemoraEspacamento.md,
          bottom: MemoraEspacamento.md,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              _BotaoZoom(
                key: MapaServicosAcessivel.chaveZoomMais,
                icone: Icons.add_rounded,
                rotuloTexto: 'Mais',
                rotuloSemantico: 'Aumentar zoom do mapa',
                aoTocar: () => _ajustarZoom(1.0),
              ),
              const SizedBox(height: MemoraEspacamento.sm),
              _BotaoZoom(
                key: MapaServicosAcessivel.chaveZoomMenos,
                icone: Icons.remove_rounded,
                rotuloTexto: 'Menos',
                rotuloSemantico: 'Diminuir zoom do mapa',
                aoTocar: () => _ajustarZoom(-1.0),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BotaoZoom extends StatelessWidget {
  final IconData icone;
  final String rotuloTexto;
  final String rotuloSemantico;
  final VoidCallback aoTocar;

  const _BotaoZoom({
    required this.icone,
    required this.rotuloTexto,
    required this.rotuloSemantico,
    required this.aoTocar,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;

    return Semantics(
      button: true,
      label: rotuloSemantico,
      child: ExcludeSemantics(
        child: Material(
          color: cores.superficie,
          elevation: MemoraElevacao.flutuante,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MemoraRaio.pilula),
            side: BorderSide(
              color: ehAltoContraste ? cores.borda : cores.bordaSutil,
              width: ehAltoContraste
                  ? MemoraDimensoes.bordaEnfase
                  : MemoraDimensoes.espessuraBordaSutil,
            ),
          ),
          child: InkWell(
            onTap: aoTocar,
            borderRadius: BorderRadius.circular(MemoraRaio.pilula),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: MemoraDimensoes.alvoDecisao,
                minHeight: MemoraDimensoes.alvoDecisao,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MemoraEspacamento.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      icone,
                      size: MemoraDimensoes.iconePadrao,
                      color: cores.primaria,
                    ),
                    const SizedBox(width: MemoraEspacamento.xs),
                    TextoMemora(
                      rotuloTexto,
                      estilo: EstiloTexto.apoio,
                      cor: cores.primaria,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
