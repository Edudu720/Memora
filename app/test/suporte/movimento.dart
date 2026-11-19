import 'package:flutter_test/flutter_test.dart';

/// Liga o movimento de volta, para o arquivo de teste inteiro.
///
/// O `flutter_test_config.dart` começa **todo** teste com "reduzir movimento"
/// do sistema ligado (a Memora repete o relógio para sempre, e com ele
/// rodando `pumpAndSettle` nunca assenta). Quem prova movimento — a Memora, a
/// anfitriã, as rotas, o que anima ao toque — chama isto no começo do
/// `main()` do arquivo: o sistema volta ao normal e cada teste monta o
/// `MediaQuery` que quiser por cima.
void movimentoLiberado() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
            .platformDispatcher
            .accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
  });
}

/// Liga o movimento de volta **só neste teste** (o `flutter_test_config.dart`
/// o começa desligado). Para arquivo que mistura teste de movimento com teste
/// que assenta com `pumpAndSettle`.
void liberarMovimento(WidgetTester t) {
  t.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures();
}
