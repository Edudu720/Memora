import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/componentes/ilustracao/memora_animada/pintores/contexto_de_pintura.dart';
import 'package:memora/design_system/componentes/ilustracao/memora_animada/pintores/pintor_da_memora.dart';
import 'package:memora/design_system/design_system.dart';

/// Fotografa a anfitriã para **olhar** (T087 e T090 da feature 013).
///
/// Não compara nada: fica pulado, a menos que `MEMORA_RENDER_DIR` aponte uma
/// pasta. Ele pinta a anfitriã direto com o pintor, em quadros escolhidos (o
/// giro, o pulo esticado, a boca aberta...), porque uma foto do app rodando
/// pegaria um instante qualquer do sorteio dos comportamentos.
///
/// ```powershell
/// $env:MEMORA_RENDER_DIR = "C:\memora-tmp\anfitria"; cd app; flutter test test/design_system/memora_anfitria_render_test.dart
/// ```
void main() {
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

  /// Um quadro: [ajustar] recebe o contexto-base e devolve o do quadro.
  Widget quadro(
    ThemeData tema,
    double lado,
    ContextoDePintura Function(ContextoDePintura base) ajustar, {
    bool detalhada = true,
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
                painter: PintorDaMemora((double l) {
                  final ContextoDePintura base = ContextoDePintura(
                    lado: l,
                    cores: context.memora.personagem,
                    pose: ValoresDaPose.de(PoseDaMemora.neutra),
                    detalhada: detalhada,
                  );
                  return ajustar(base);
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ContextoDePintura com(
    ContextoDePintura b, {
    PoseDaMemora? pose,
    double fala = 0,
    double aceno = 0,
    double pulo = 0,
    double balanco = 0,
    double antena = 0,
    double ajeita = 0,
    double giro = 0,
    double flutua = 0,
    double esticar = 0,
    double olharX = 0,
    double olharY = 0,
    double inclina = 0,
  }) {
    final ValoresDaPose p = (pose != null ? ValoresDaPose.de(pose) : b.pose)
        .copiar(olharX: olharX, olharY: olharY, inclinacaoDaCabeca: inclina);
    return ContextoDePintura(
      lado: b.lado,
      cores: b.cores,
      pose: p,
      fala: fala,
      aceno: aceno,
      pulo: pulo,
      balanco: balanco,
      antena: antena,
      ajeita: ajeita,
      giro: giro,
      flutua: flutua,
      esticar: esticar,
      detalhada: b.detalhada,
    );
  }

  testWidgets('grava a anfitriã em quadros escolhidos', (WidgetTester t) async {
    const double lado = 150;
    final GlobalKey chave = GlobalKey();

    final List<ContextoDePintura Function(ContextoDePintura)> cenas =
        <ContextoDePintura Function(ContextoDePintura)>[
          // 0 repouso
          (ContextoDePintura b) => com(b, flutua: 0.3),
          // 1 giro à esquerda
          (ContextoDePintura b) =>
              com(b, giro: -0.9, olharX: -1.4, inclina: -0.03, flutua: 0.6),
          // 2 giro à direita
          (ContextoDePintura b) =>
              com(b, giro: 0.9, olharX: 1.4, inclina: 0.03, flutua: 0.6),
          // 3 inclina a cabeça
          (ContextoDePintura b) =>
              com(b, inclina: 0.1, olharX: 0.6, giro: 0.15, flutua: 0.8),
          // 4 pulo esticado
          (ContextoDePintura b) =>
              com(b, pulo: 0.7, esticar: 0.8, antena: 0.6, olharY: -0.4),
          // 5 encolhida
          (ContextoDePintura b) => com(b, esticar: -0.9, ajeita: 0.2),
          // 6 acena
          (ContextoDePintura b) => com(
            b,
            pose: PoseDaMemora.acenando,
            aceno: 0.8,
            balanco: 0.6,
            flutua: 0.4,
          ),
          // 7 fala
          (ContextoDePintura b) => com(
            b,
            pose: PoseDaMemora.falando,
            fala: 0.9,
            giro: 0.2,
            flutua: 0.5,
          ),
        ];

    final List<Widget> linhas = <Widget>[
      for (final MemoraTemaId id in MemoraTemaId.values)
        Row(
          children: <Widget>[
            for (final ContextoDePintura Function(ContextoDePintura) c in cenas)
              quadro(TemasMemora.porId(id), lado, c),
          ],
        ),
      // Para comparar: a Memora comum (sem o acabamento) e a anfitriã em
      // outras paletas.
      Row(
        children: <Widget>[
          quadro(
            TemasMemora.claro,
            lado,
            (ContextoDePintura b) => com(b),
            detalhada: false,
          ),
          quadro(TemasMemora.claro, lado, (ContextoDePintura b) => com(b)),
          quadro(
            TemasMemora.porId(MemoraTemaId.claro, paleta: 'verde'),
            lado,
            (ContextoDePintura b) => com(b, giro: 0.5, olharX: 0.8),
          ),
          quadro(
            TemasMemora.porId(MemoraTemaId.claro, paleta: 'rosa'),
            lado,
            (ContextoDePintura b) => com(b, pulo: 0.5, esticar: 0.6),
          ),
          quadro(
            TemasMemora.porId(MemoraTemaId.escuro, paleta: 'roxo'),
            lado,
            (ContextoDePintura b) => com(b, giro: -0.6, olharX: -1),
          ),
        ],
      ),
    ];

    t.view.physicalSize = const Size(1500, 1010);
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
                child: Column(mainAxisSize: MainAxisSize.min, children: linhas),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pump();
    await salvar(t, chave, 'resumo.png', 1.5);

    // Três quadros grandes, no tema claro, para ver o detalhe.
    final Map<String, ContextoDePintura Function(ContextoDePintura)> grandes =
        <String, ContextoDePintura Function(ContextoDePintura)>{
          'repouso': cenas[0],
          'giro': cenas[2],
          'pulo': cenas[4],
        };
    for (final MapEntry<String, ContextoDePintura Function(ContextoDePintura)> g
        in grandes.entries) {
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
                child: quadro(TemasMemora.claro, 340, g.value),
              ),
            ),
          ),
        ),
      );
      await t.pump();
      await salvar(t, k, 'detalhe_${g.key}.png', 2);
    }
  }, skip: !ligado);

  testWidgets('grava a anfitriã inteira, com o balão, nos três temas', (
    WidgetTester t,
  ) async {
    final GlobalKey chave = GlobalKey();
    t.view.physicalSize = const Size(1200, 520);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    Widget coluna(MemoraTemaId id, int indice) => SizedBox(
      width: 400,
      child: Theme(
        data: TemasMemora.porId(id),
        child: Builder(
          builder: (BuildContext context) => ColoredBox(
            color: context.memora.cores.fundo,
            child: Padding(
              padding: const EdgeInsets.all(MemoraEspacamento.lg),
              child: MemoraAnfitria(indiceInicial: indice, sementeDaAgenda: 4),
            ),
          ),
        ),
      ),
    );

    await t.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1200, 520)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: chave,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  coluna(MemoraTemaId.claro, 0),
                  coluna(MemoraTemaId.escuro, 2),
                  coluna(MemoraTemaId.altoContraste, 5),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // Deixa o texto aparecer por inteiro e a Memora fazer o que fizer.
    for (int i = 0; i < 40; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await salvar(t, chave, 'anfitria_inteira.png', 1.5);
  }, skip: !ligado);
}
