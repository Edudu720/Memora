import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/componentes/ilustracao/memora_animada/pintores/contexto_de_pintura.dart';
import 'package:memora/design_system/componentes/ilustracao/memora_animada/pintores/pintor_da_memora.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/design_system/tokens/abertura.dart';
import 'package:memora/features/abertura/presentation/abertura_memora.dart';

import '../../suporte/fonte.dart';
import '../../suporte/movimento.dart';

/// Fotografa a abertura para **olhar** (T092 da feature 013): a anfitriã
/// segurando a barra de carregamento.
///
/// Não compara nada: fica pulado, a menos que `MEMORA_RENDER_DIR` aponte uma
/// pasta. A barra é pintada em pontos escolhidos da passada (e parada, como
/// fica com "reduzir movimento"), nos três temas e em outras paletas; e a
/// tela inteira da abertura, num aparelho de referência.
///
/// ```powershell
/// $env:MEMORA_RENDER_DIR = "C:\memora-tmp\abertura"; cd app; flutter test test/features/abertura/abertura_render_test.dart
/// ```
void main() {
  // A tela inteira mostra a barra correndo: o movimento do sistema volta ao
  // normal (o flutter_test_config.dart o desliga, e com ele o próprio
  // AnimationController encurta a passada a quase nada).
  movimentoLiberado();
  final String? destino = Platform.environment['MEMORA_RENDER_DIR'];
  final bool ligado = destino != null && destino.isNotEmpty;

  Future<void> salvar(
    WidgetTester t,
    GlobalKey chave,
    String arquivo,
    double pixelRatio,
  ) async {
    await t.runAsync(() async {
      final RenderRepaintBoundary limite =
          chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image imagem = await limite.toImage(pixelRatio: pixelRatio);
      final ByteData? bytes = await imagem.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final File f = File('$destino/$arquivo');
      await f.parent.create(recursive: true);
      await f.writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  Widget quadro(
    ThemeData tema,
    double lado, {
    double? ciclo,
    double flutua = 0.3,
    double balanco = 0,
    double giro = 0,
  }) {
    return Theme(
      data: tema,
      child: Builder(
        builder: (BuildContext context) => ColoredBox(
          color: context.memora.cores.fundo,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              MemoraEspacamento.sm,
              MemoraEspacamento.xl,
              MemoraEspacamento.sm,
              MemoraEspacamento.sm,
            ),
            child: SizedBox.square(
              dimension: lado,
              child: CustomPaint(
                painter: PintorDaMemora(
                  (double l) => ContextoDePintura(
                    lado: l,
                    cores: context.memora.personagem,
                    pose: ValoresDaPose.de(PoseDaMemora.carregando),
                    detalhada: true,
                    cicloDaBarra: ciclo,
                    flutua: flutua,
                    balanco: balanco,
                    giro: giro,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget foto(GlobalKey chave, Widget filho) => MediaQuery(
    data: const MediaQueryData(disableAnimations: true),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(key: chave, child: filho),
      ),
    ),
  );

  testWidgets('grava a anfitriã segurando a barra', (WidgetTester t) async {
    const double lado = 160;
    final GlobalKey chave = GlobalKey();
    const List<double?> ciclos = <double?>[null, 0.15, 0.4, 0.65, 0.9];

    t.view.physicalSize = const Size(1000, 1100);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(
      foto(
        chave,
        ColoredBox(
          color: const Color(0xFFFFFFFF),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final MemoraTemaId id in MemoraTemaId.values)
                Row(
                  children: <Widget>[
                    for (final double? c in ciclos)
                      quadro(TemasMemora.porId(id), lado, ciclo: c),
                  ],
                ),
              Row(
                children: <Widget>[
                  for (final String nome in <String>[
                    'verde',
                    'rosa',
                    'grafite',
                  ])
                    quadro(
                      TemasMemora.porId(MemoraTemaId.claro, paleta: nome),
                      lado,
                      ciclo: 0.45,
                      giro: 0.4,
                      balanco: 0.5,
                    ),
                  quadro(
                    TemasMemora.porId(MemoraTemaId.escuro, paleta: 'roxo'),
                    lado,
                    ciclo: 0.55,
                    giro: -0.5,
                    balanco: -0.5,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await t.pump();
    await salvar(t, chave, 'barra_resumo.png', 1.5);

    final GlobalKey grande = GlobalKey();
    await t.pumpWidget(
      foto(grande, quadro(TemasMemora.claro, 340, ciclo: 0.45)),
    );
    await t.pump();
    await salvar(t, grande, 'barra_detalhe.png', 2);
  }, skip: !ligado);

  testWidgets('grava a tela inteira da abertura (360x800)', (
    WidgetTester t,
  ) async {
    // A frase com a fonte de verdade, e não a quadrada do flutter test.
    await t.runAsync(carregarAtkinson);
    final GlobalKey chave = GlobalKey();
    t.view.physicalSize = const Size(360, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final Completer<int> carga = Completer<int>();
    for (final MemoraTemaId id in <MemoraTemaId>[
      MemoraTemaId.claro,
      MemoraTemaId.escuro,
    ]) {
      await t.pumpWidget(
        RepaintBoundary(
          key: chave,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: TemasMemora.porId(id),
            builder: (BuildContext context, Widget? filho) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: false),
              child: filho!,
            ),
            home: AberturaMemora<int>(
              carregar: () => carga.future,
              aoConcluir: (int _) {},
            ),
          ),
        ),
      );
      // Passa dos 4 s, para a frase aparecer, e para no meio de uma passada.
      // (Um relógio que recomeça só conta a partir do quadro seguinte: daí o
      // quadro curto no meio.)
      await t.pump(MemoraAbertura.limiteDaDemora);
      await t.pump(const Duration(milliseconds: 16));
      await t.pump(const Duration(milliseconds: 650));
      await salvar(t, chave, 'abertura_${id.name}.png', 2);
      await t.pumpWidget(const SizedBox.shrink());
    }
  }, skip: !ligado);
}
