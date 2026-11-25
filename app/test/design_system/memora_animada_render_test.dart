import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

/// Fotografa a `MemoraAnimada` para **olhar** (T018 da feature 013).
///
/// ## Para que serve
///
/// O desenho em código só se avalia vendo. Este teste grava PNGs das poses nos
/// três temas e em todas as paletas, para a conferência visual com a folha de
/// expressões. **Não compara nada**: por isso fica pulado, a menos que a
/// variável de ambiente `MEMORA_RENDER_DIR` aponte uma pasta.
///
/// ```powershell
/// $env:MEMORA_RENDER_DIR = "C:\memora-tmp\render"; cd app; flutter test test/design_system/memora_animada_render_test.dart
/// ```
void main() {
  final String? destino = Platform.environment['MEMORA_RENDER_DIR'];
  final bool ligado = destino != null && destino.isNotEmpty;

  /// Fotografa [chave] e grava em [arquivo].
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
      final ByteData? bytes =
          await imagem.toByteData(format: ui.ImageByteFormat.png);
      final File f = File('$destino/$arquivo');
      await f.parent.create(recursive: true);
      await f.writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  Widget celula(ThemeData tema, PoseDaMemora pose, double lado) {
    return Theme(
      data: tema,
      child: Builder(
        builder: (BuildContext context) => ColoredBox(
          color: context.memora.cores.fundo,
          child: Padding(
            padding: const EdgeInsets.all(MemoraEspacamento.sm),
            child: MemoraAnimada(
              expressao: pose,
              tamanho: lado,
              reageAoToque: false,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('grava o resumo e os detalhes da Memora', (WidgetTester t) async {
    const double lado = 150;
    final GlobalKey chave = GlobalKey();

    final List<Widget> linhas = <Widget>[
      for (final MemoraTemaId id in MemoraTemaId.values)
        Row(
          children: <Widget>[
            for (final PoseDaMemora p in PoseDaMemora.values)
              celula(TemasMemora.porId(id), p, lado),
          ],
        ),
      Row(
        children: <Widget>[
          for (final String nome in MemoraCores.paletas.keys)
            celula(
              TemasMemora.porId(MemoraTemaId.claro, paleta: nome),
              PoseDaMemora.acenando,
              lado,
            ),
          for (final String nome in <String>['azul', 'verde'])
            celula(
              TemasMemora.porId(MemoraTemaId.escuro, paleta: nome),
              PoseDaMemora.acenando,
              lado,
            ),
        ],
      ),
    ];

    t.view.physicalSize = const Size(1500, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: chave,
              child: ColoredBox(
                color: const Color(0xFFFFFFFF),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: linhas,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pump();
    await salvar(t, chave, 'resumo.png', 1.5);

    // Cada pose grande, no claro, para ver o detalhe.
    for (final PoseDaMemora p in PoseDaMemora.values) {
      final GlobalKey k = GlobalKey();
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                key: k,
                child: celula(TemasMemora.claro, p, 320),
              ),
            ),
          ),
        ),
      );
      await t.pump();
      await salvar(t, k, 'detalhe_${p.name}.png', 2);
    }
  }, skip: !ligado);
}
