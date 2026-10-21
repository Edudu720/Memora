import 'package:flutter_test/flutter_test.dart';

/// Deixa a Memora terminar de "escrever" a última resposta (FR-020b).
///
/// A resposta vai aparecendo aos poucos, letra a letra, e um teste que olha o
/// texto logo depois de ela chegar vê só o começo. Um quadro de muitos segundos
/// leva a escrita ao fim de uma vez — o relógio dela anda pelo tempo dos
/// quadros —, e o quadro seguinte aplica a rolagem que o último trecho pediu.
///
/// `pumpAndSettle` não serve aqui: não é a escrita que ele esperaria, e sim o
/// que mais houver animando na tela.
Future<void> esperarAEscrita(WidgetTester t) async {
  await t.pump(const Duration(seconds: 10));
  await t.pump();
}
