import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// A configuração que o `flutter test` lê antes de **todo** arquivo de teste.
///
/// ## Por que o sistema começa com "reduzir movimento" ligado
///
/// A Memora vetorial (feature 013) repete um relógio **para sempre** quando há
/// movimento permitido, e ela está em quase toda tela. Com ele rodando,
/// `pumpAndSettle` nunca assenta — o relógio sempre pede o quadro seguinte — e
/// dezenas de testes de layout e de fluxo morreriam em "pumpAndSettle timed
/// out" sem ter nada a ver com o que provam. O desenho dela mede o mesmo
/// parado e em movimento, então para tudo o que não é movimento o teste começa
/// com o movimento desligado.
///
/// ## Quem quer movimento pede
///
/// Um arquivo que prova movimento (a Memora, a anfitriã, as rotas) desliga
/// isto com `movimentoLiberado()` (`test/suporte/movimento.dart`) — ou o teste
/// monta o próprio `MediaQuery` com `disableAnimations: false`, que vale mais
/// que o sistema. E o que prova o "reduzir movimento" continua provando: ele
/// liga o que já está ligado.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    final TestWidgetsFlutterBinding binding =
        TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });
  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });
  await testMain();
}
