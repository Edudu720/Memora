import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/aprendizado/domain/guia.dart';

/// T133 — o destaque cai sobre a **imagem**, não sobre a caixa (FR-028c).
///
/// O defeito: o anel era posicionado pela caixa da moldura e a imagem entrava
/// nela com `BoxFit.contain`. Com uma captura de proporção diferente da caixa
/// os dois divergiam, e os desenhos provisórios (1:2) escondiam isso.
///
/// O portão mede o que a pessoa vê: o retângulo do anel dentro do retângulo
/// **pintado** da imagem, no lugar que a [RegiaoRelativa] aponta.
void main() {
  const Size caixa = Size(300, 380);

  Passo passoCom(RegiaoRelativa regiao) => Passo(
    captura: const CapturaDoGuia.paraTeste('tiktok', 1),
    destaque: regiao,
    texto: 'Toque no ícone.',
    descricaoDaCaptura: 'Tela de teste.',
  );

  Widget app(Widget filho) => MaterialApp(
    theme: TemasMemora.porId(MemoraTemaId.claro),
    home: Scaffold(
      body: Center(
        child: SizedBox(width: caixa.width, height: caixa.height, child: filho),
      ),
    ),
  );

  /// Reprova se o anel não estiver onde a região manda, **dentro da imagem**.
  void exigirAnelNoLugar(WidgetTester t, RegiaoRelativa r, {String? contexto}) {
    final Rect imagem = t.getRect(find.byKey(CapturaComDestaque.chaveImagem));
    final Rect anel = t.getRect(find.byKey(CapturaComDestaque.chaveDestaque));
    final Rect esperado = Rect.fromLTWH(
      imagem.left + imagem.width * r.x,
      imagem.top + imagem.height * r.y,
      imagem.width * r.largura,
      imagem.height * r.altura,
    );
    const double tolerancia = 1;
    final String motivo =
        '${contexto ?? ''} imagem=$imagem anel=$anel esperado=$esperado';
    expect(anel.left, closeTo(esperado.left, tolerancia), reason: motivo);
    expect(anel.top, closeTo(esperado.top, tolerancia), reason: motivo);
    expect(anel.width, closeTo(esperado.width, tolerancia), reason: motivo);
    expect(anel.height, closeTo(esperado.height, tolerancia), reason: motivo);
  }

  group('o anel cai sobre a imagem, qualquer que seja a proporção', () {
    const RegiaoRelativa regiao = RegiaoRelativa(
      x: 0.1,
      y: 0.2,
      largura: 0.4,
      altura: 0.2,
    );

    // 9:20 é o print de celular; 1:2 é o desenho provisório; as outras três
    // são mais largas que a caixa de 300x380 e mais estreitas.
    for (final double proporcao in <double>[9 / 20, 1 / 2, 9 / 16, 1, 2]) {
      testWidgets('proporção ${proporcao.toStringAsFixed(2)}', (
        WidgetTester t,
      ) async {
        await t.pumpWidget(
          app(
            CapturaComDestaque(passo: passoCom(regiao), proporcao: proporcao),
          ),
        );

        final Rect imagem = t.getRect(
          find.byKey(CapturaComDestaque.chaveImagem),
        );
        expect(
          imagem.width / imagem.height,
          closeTo(proporcao, 0.001),
          reason: 'a imagem tem de ser desenhada na proporção dela',
        );
        // Contida na caixa e centralizada nela.
        expect(imagem.width, lessThanOrEqualTo(caixa.width + 0.01));
        expect(imagem.height, lessThanOrEqualTo(caixa.height + 0.01));
        expect(imagem.center.dx, closeTo(400, 0.5));
        expect(imagem.center.dy, closeTo(300, 0.5));

        exigirAnelNoLugar(t, regiao, contexto: 'proporção $proporcao');
      });
    }

    testWidgets('com várias regiões, o anel acompanha a região na imagem', (
      WidgetTester t,
    ) async {
      const List<RegiaoRelativa> regioes = <RegiaoRelativa>[
        RegiaoRelativa(x: 0, y: 0, largura: 0.3, altura: 0.1),
        RegiaoRelativa(x: 0.7, y: 0.9, largura: 0.3, altura: 0.1),
        RegiaoRelativa(x: 0.25, y: 0.45, largura: 0.5, altura: 0.1),
      ];
      for (final RegiaoRelativa r in regioes) {
        await t.pumpWidget(
          app(
            CapturaComDestaque(
              key: UniqueKey(),
              passo: passoCom(r),
              proporcao: 9 / 20,
            ),
          ),
        );
        exigirAnelNoLugar(t, r, contexto: '$r');
      }
    });
  });

  group('a proporção vem da própria imagem', () {
    /// Um PNG de verdade, de [largura]x[altura]. Gerar e decodificar imagem é
    /// I/O que o relógio falso de `testWidgets` não completa: vai por
    /// `runAsync`.
    Future<Uint8List> png(WidgetTester t, int largura, int altura) async {
      final Uint8List? bytes = await t.runAsync(() async {
        final ui.PictureRecorder gravador = ui.PictureRecorder();
        ui.Canvas(gravador).drawRect(
          Rect.fromLTWH(0, 0, largura.toDouble(), altura.toDouble()),
          ui.Paint()..color = const Color(0xFF336699),
        );
        final ui.Image imagem = await gravador.endRecording().toImage(
          largura,
          altura,
        );
        final ByteData? dados = await imagem.toByteData(
          format: ui.ImageByteFormat.png,
        );
        imagem.dispose();
        return dados!.buffer.asUint8List();
      });
      return bytes!;
    }

    testWidgets('uma captura 9:20 fica 9:20, e o anel cai sobre ela', (
      WidgetTester t,
    ) async {
      const RegiaoRelativa regiao = RegiaoRelativa(
        x: 0.2,
        y: 0.7,
        largura: 0.6,
        altura: 0.1,
      );
      final Uint8List bytes = await png(t, 90, 200);

      await t.pumpWidget(
        app(
          CapturaComDestaque(
            passo: passoCom(regiao),
            imagem: MemoryImage(bytes),
          ),
        ),
      );
      // Antes da imagem chegar vale a proporção de reserva (9:20).
      final Rect antes = t.getRect(find.byKey(CapturaComDestaque.chaveImagem));
      expect(
        antes.width / antes.height,
        closeTo(CapturaComDestaque.proporcaoDeReserva, 0.001),
      );

      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await t.pump();

      final Rect depois = t.getRect(find.byKey(CapturaComDestaque.chaveImagem));
      expect(depois.width / depois.height, closeTo(90 / 200, 0.001));
      exigirAnelNoLugar(t, regiao);
    });

    testWidgets('uma captura larga (2:1) ocupa a largura e o anel a segue', (
      WidgetTester t,
    ) async {
      const RegiaoRelativa regiao = RegiaoRelativa(
        x: 0.5,
        y: 0.5,
        largura: 0.4,
        altura: 0.4,
      );
      final Uint8List bytes = await png(t, 200, 100);

      await t.pumpWidget(
        app(
          CapturaComDestaque(
            passo: passoCom(regiao),
            imagem: MemoryImage(bytes),
          ),
        ),
      );
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await t.pump();

      final Rect imagem = t.getRect(find.byKey(CapturaComDestaque.chaveImagem));
      expect(imagem.width, closeTo(caixa.width, 0.01));
      expect(imagem.height, closeTo(caixa.width / 2, 0.01));
      exigirAnelNoLugar(t, regiao);
    });
  });

  group('captura que não existe (FR-028a)', () {
    testWidgets('mostra o aviso no lugar da imagem e avisa quem usa', (
      WidgetTester t,
    ) async {
      final List<bool> avisos = <bool>[];

      await t.pumpWidget(
        app(
          CapturaComDestaque(
            passo: passoCom(
              const RegiaoRelativa(x: 0, y: 0, largura: 0.5, altura: 0.5),
            ),
            // Bytes que não são uma imagem: a decodificação falha.
            imagem: MemoryImage(Uint8List.fromList(<int>[1, 2, 3, 4])),
            pendente: (BuildContext _) => const Text('captura pendente'),
            aoMudarPendente: avisos.add,
          ),
        ),
      );
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await t.pump();
      await t.pump();

      expect(find.text('captura pendente'), findsOneWidget);
      expect(find.byKey(CapturaComDestaque.chaveImagem), findsNothing);
      expect(find.byKey(CapturaComDestaque.chaveDestaque), findsNothing);
      expect(avisos, <bool>[true]);
    });
  });

  // O anel tinha uma `BoxShadow` opaca sem desfoque: o Flutter a pinta como um
  // retângulo cheio atrás da caixa, e o destaque escondia o botão que
  // destacava. O portão olha o que a pessoa vê — os pixels do miolo do anel.
  testWidgets('o miolo do anel mostra a imagem: o destaque não a cobre', (
    WidgetTester t,
  ) async {
    const Color vermelho = Color(0xFFFF0000);
    final Uint8List? bytes = await t.runAsync(() async {
      final ui.PictureRecorder gravador = ui.PictureRecorder();
      ui.Canvas(gravador).drawRect(
        const Rect.fromLTWH(0, 0, 90, 200),
        ui.Paint()..color = vermelho,
      );
      final ui.Image imagem = await gravador.endRecording().toImage(90, 200);
      final ByteData? dados = await imagem.toByteData(
        format: ui.ImageByteFormat.png,
      );
      imagem.dispose();
      return dados!.buffer.asUint8List();
    });

    final GlobalKey limite = GlobalKey();
    await t.pumpWidget(
      app(
        RepaintBoundary(
          key: limite,
          child: CapturaComDestaque(
            passo: passoCom(
              const RegiaoRelativa(x: 0.2, y: 0.4, largura: 0.6, altura: 0.2),
            ),
            imagem: MemoryImage(bytes!),
            proporcao: 90 / 200,
          ),
        ),
      ),
    );
    // A decodificação é I/O de verdade: espera fora do relógio falso.
    for (int i = 0; i < 5; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await t.pump();
    }

    final RenderRepaintBoundary fronteira =
        limite.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final Rect area = t.getRect(find.byKey(limite));
    final Rect anel = t.getRect(find.byKey(CapturaComDestaque.chaveDestaque));
    final Offset miolo = anel.center - area.topLeft;

    final ByteData? pixels = await t.runAsync(() async {
      final ui.Image quadro = await fronteira.toImage();
      final ByteData? dados = await quadro.toByteData();
      final ByteData resultado = ByteData(4)
        ..setUint32(
          0,
          dados!.getUint32(
            (miolo.dy.round() * quadro.width + miolo.dx.round()) * 4,
          ),
        );
      quadro.dispose();
      return resultado;
    });

    // RGBA: vermelho cheio, nada de verde nem de azul por cima.
    final int r = pixels!.getUint8(0);
    final int g = pixels.getUint8(1);
    final int b = pixels.getUint8(2);
    expect(
      <int>[r, g, b],
      <int>[255, 0, 0],
      reason: 'No centro do anel aparece rgb($r, $g, $b), e não a imagem',
    );
  });
}
