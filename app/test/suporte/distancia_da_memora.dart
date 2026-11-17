import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

/// Quanto a área de toque da Memora fica longe dos alvos de toque de verdade
/// (FR-005c e FR-055): 8 dp, para um toque destinado a um botão não cair nela.
const double distanciaMinimaDaMemora = 8;

/// Os retângulos, em coordenadas da janela, onde o toque na Memora **faz
/// alguma coisa** agora.
///
/// - A `MemoraAnimada` que reage ao toque (`reageAoToque` ligado e o movimento
///   permitido) tem um `GestureDetector` dentro dela, e a área é a dele: o
///   **quadrado inteiro**, margens transparentes incluídas, porque é onde o
///   dedo cai.
/// - A anfitriã é a exceção da FR-005b: o toque é uma ação, e a área é a
///   `chaveDaAcao` (o quadrado do desenho, com a folga de cima).
List<Rect> areasDeToqueDaMemora(WidgetTester t) {
  final List<Rect> areas = <Rect>[];
  for (final Element e in find.byType(MemoraAnimada).evaluate()) {
    final Finder gesto = find.descendant(
      of: find.byWidget(e.widget),
      matching: find.byType(GestureDetector),
    );
    if (gesto.evaluate().isNotEmpty) areas.add(t.getRect(gesto.first));
  }
  final Finder anfitria = find.byKey(MemoraAnfitria.chaveDaAcao);
  if (anfitria.evaluate().isNotEmpty) areas.add(t.getRect(anfitria));
  return areas;
}

/// Os alvos de toque da tela: todo nó de semântica com ação de toque, **menos**
/// os da própria anfitriã (o desenho e o balão dela são a mesma Memora).
///
/// Precisa da semântica ligada (`t.ensureSemantics()`), e é por ela que se
/// acha o que é alvo de verdade: botão, linha de lista, cartão, campo.
List<Rect> alvosDeToque(WidgetTester t) {
  final List<Rect> excluir = <Rect>[
    for (final Key k in <Key>[
      MemoraAnfitria.chaveDaAcao,
      MemoraAnfitria.chaveDoBalao,
    ])
      if (find.byKey(k).evaluate().isNotEmpty) t.getRect(find.byKey(k)),
  ];
  final List<Rect> alvos = <Rect>[];
  final SemanticsNode? raiz =
      t.binding.renderViews.first.owner?.semanticsOwner?.rootSemanticsNode;
  if (raiz == null) return alvos;

  void visitar(SemanticsNode no, Matrix4 acumulada) {
    final Matrix4 m = no.transform == null
        ? acumulada
        : acumulada.multiplied(no.transform!);
    final Rect r = MatrixUtils.transformRect(m, no.rect);
    final SemanticsData d = no.getSemanticsData();
    // Também os escondidos pela rolagem: a distância é do desenho da tela, e o
    // botão que está abaixo da dobra é o que a pessoa toca depois de rolar.
    final bool alvo =
        d.hasAction(SemanticsAction.tap) && r.width > 0 && r.height > 0;
    final bool daAnfitria = excluir.any(
      (Rect x) =>
          (x.left - r.left).abs() < 1 &&
          (x.top - r.top).abs() < 1 &&
          (x.right - r.right).abs() < 1 &&
          (x.bottom - r.bottom).abs() < 1,
    );
    if (alvo && !daAnfitria) alvos.add(r);
    no.visitChildren((SemanticsNode filho) {
      visitar(filho, m);
      return true;
    });
  }

  // A raiz da semântica está em pixels do aparelho: dividir pela densidade
  // devolve as coordenadas lógicas da janela, as mesmas do `getRect`.
  final double densidade = t.view.devicePixelRatio;
  visitar(raiz, Matrix4.diagonal3Values(1 / densidade, 1 / densidade, 1));
  return alvos;
}

/// A distância entre dois retângulos (0 se se tocam ou se cruzam).
double distanciaEntre(Rect a, Rect b) {
  final double dx = <double>[
    a.left - b.right,
    b.left - a.right,
    0,
  ].reduce((double x, double y) => x > y ? x : y);
  final double dy = <double>[
    a.top - b.bottom,
    b.top - a.bottom,
    0,
  ].reduce((double x, double y) => x > y ? x : y);
  return Offset(dx, dy).distance;
}

/// As áreas de Memora medidas e as violações da regra dos 8 dp (uma frase por
/// par que fica perto demais).
typedef MedidaDaMemora = ({int memoras, List<String> violacoes});

/// Mede a tela: quantas áreas de toque de Memora há e quais ficam a menos de
/// [distanciaMinimaDaMemora] de um alvo de toque. Liga a semântica sozinho.
Future<MedidaDaMemora> medirMemora(
  WidgetTester t, {
  required String contexto,
}) async {
  final SemanticsHandle semantica = t.ensureSemantics();
  // A árvore de semântica só nasce no quadro seguinte ao pedido.
  await t.pump();
  try {
    final List<Rect> memoras = areasDeToqueDaMemora(t);
    final List<Rect> alvos = alvosDeToque(t);
    final List<String> violacoes = <String>[];
    for (final Rect m in memoras) {
      for (final Rect a in alvos) {
        final double d = distanciaEntre(m, a);
        if (d < distanciaMinimaDaMemora - 0.01) {
          violacoes.add(
            '$contexto: a área de toque da Memora ($m) fica a '
            '${d.toStringAsFixed(1)} dp do alvo $a (mínimo '
            '${distanciaMinimaDaMemora.toStringAsFixed(0)}) — um toque para '
            'ele pode cair nela',
          );
        }
      }
    }
    return (memoras: memoras.length, violacoes: violacoes);
  } finally {
    semantica.dispose();
  }
}

/// Reprova se a área de toque de alguma Memora da tela ficar a menos de
/// [distanciaMinimaDaMemora] de um alvo de toque (FR-005c, FR-055).
///
/// Devolve quantas áreas de Memora foram medidas, para o teste saber se há o
/// que medir.
Future<int> exigirMemoraAfastada(
  WidgetTester t, {
  required String contexto,
}) async {
  final MedidaDaMemora m = await medirMemora(t, contexto: contexto);
  expect(m.violacoes, isEmpty);
  return m.memoras;
}
