import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/inicio/presentation/tela_inicio.dart';

import '../../suporte/aparelhos.dart';
import '../../suporte/fonte.dart';
import '../../suporte/movimento.dart';

/// Fotografa o Início com a anfitriã para **olhar** (T053, feature 013).
///
/// Não compara nada: fica pulado, a menos que `MEMORA_RENDER_DIR` aponte uma
/// pasta. Com a Atkinson (a fonte que a pessoa vê) e o movimento ligado, para
/// a boca falar e a dica já escrita.
///
/// ```powershell
/// $env:MEMORA_RENDER_DIR = "C:\memora-tmp\inicio"; cd app; flutter test test/features/inicio/inicio_render_test.dart
/// ```
void main() {
  final String? destino = Platform.environment['MEMORA_RENDER_DIR'];
  final bool ligado = destino != null && destino.isNotEmpty;

  movimentoLiberado();
  setUpAll(carregarAtkinson);

  Future<void> salvar(WidgetTester t, GlobalKey chave, String arquivo) async {
    await t.runAsync(() async {
      final RenderRepaintBoundary limite =
          chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image imagem = await limite.toImage(pixelRatio: 2);
      final ByteData? bytes = await imagem.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final File f = File('$destino/$arquivo');
      await f.parent.create(recursive: true);
      await f.writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  for (final MemoraTemaId tema in MemoraTemaId.values) {
    for (final double escala in <double>[1.0, 2.0]) {
      testWidgets(
        'grava o Início no tema ${tema.name} a ${(escala * 100).round()}%',
        (WidgetTester t) async {
          vestir(t, referencia);
          final GlobalKey chave = GlobalKey();
          await t.pumpWidget(
            RepaintBoundary(
              key: chave,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: TemasMemora.porId(tema),
                builder: (BuildContext context, Widget? filho) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(escala)),
                  child: filho!,
                ),
                home: TelaInicio(
                  nome: 'Ana',
                  aoConversar: () {},
                  aoVerTudo: () {},
                  aoAbrirAplicativos: () {},
                  aoAbrirServicos: () {},
                  aoAbrirAjuda: () {},
                ),
              ),
            ),
          );
          // A dica é escrita aos poucos e a Memora chega crescendo: deixa.
          await t.pump(const Duration(milliseconds: 400));
          await t.pump(const Duration(seconds: 5));
          expect(t.takeException(), isNull);
          await salvar(
            t,
            chave,
            'inicio_${tema.name}_${(escala * 100).round()}.png',
          );
        },
        skip: !ligado,
      );
    }
  }
}
