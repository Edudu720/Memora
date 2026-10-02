/// Carrega a Atkinson Hyperlegible Next nos testes que **olham** a tela, e só
/// neles (T007 e T043 da feature 004, R3 e R13).
///
/// ## Por que a matriz não usa isto
///
/// O `flutter test` desenha todo texto com uma fonte **quadrada**, de 1 em por
/// caractere, seja qual for a família pedida — mais larga e com mais quebras
/// que a real. Medido: "Esqueci minha senha" a 18 sp ocupa 342 px na matriz e
/// 168 px com a Atkinson carregada. A matriz de estouro fica, portanto,
/// pessimista nas duas direções, e é isso que se quer dela: o que passa nela
/// passa com a fonte real.
///
/// Carregar a Atkinson **nela** tiraria metade dessa margem. Por isso este
/// auxiliar existe separado, e quem o chama diz por quê: o álbum de telas
/// existe para olhar, não para reprovar.
///
/// ## Como usar
///
/// Dentro de `setUpAll`, antes de qualquer `pumpWidget`. Lê os arquivos do
/// disco — I/O real, que dentro de `testWidgets` nunca completa por causa do
/// relógio falso, e por isso **não** pode ser chamado de lá.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:memora/design_system/design_system.dart';

const String _pasta = 'assets/fontes/atkinson_hyperlegible_next';

/// Os três pesos que `MemoraTipografia` usa (400, 600 e 700).
const List<String> _arquivos = <String>[
  'AtkinsonHyperlegibleNext-Regular.ttf',
  'AtkinsonHyperlegibleNext-SemiBold.ttf',
  'AtkinsonHyperlegibleNext-Bold.ttf',
];

/// Registra a família [MemoraTipografia.familia] no motor de texto.
///
/// Sem isto, mesmo pedindo `AtkinsonHyperlegibleNext`, o teste desenha com a
/// fonte quadrada.
Future<void> carregarAtkinson() async {
  final FontLoader carregador = FontLoader(MemoraTipografia.familia);
  for (final String arquivo in _arquivos) {
    final Uint8List bytes = File('$_pasta/$arquivo').readAsBytesSync();
    carregador.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  await carregador.load();
}
