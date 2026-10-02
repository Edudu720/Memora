import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

import '../suporte/aparelhos.dart';

/// O controle "Mostrar senha" contra a ampliação de texto.
///
/// ## Por que este arquivo existe
///
/// O rótulo do controle de revelar é escrito por extenso de propósito — um
/// ícone de olho sozinho não diz se mostra ou esconde. Só que ele vivia numa
/// `Row` sem `Flexible`, e texto sem `Flexible` numa `Row` exige a largura
/// natural dele. A largura natural cresce com a ampliação.
///
/// Resultado, medido na auditoria de 2026-09-15: estouro **horizontal** de
/// 31 px num 320×568 **já em 100%**, 78 px num 390×844 a 150%, e 265 px a
/// 200%. O `CampoSenha` está no cadastro, no login e na recuperação — as três
/// telas em que alguém digita senha.
///
/// ## Por que nenhum teste pegava
///
/// Os testes de ampliação da época declaravam `MediaQueryData(size: Size(390,
/// 844))`, o que **não** muda as restrições de layout: a janela real do
/// `flutter test` é 800×600, larga o bastante para o rótulo caber. O teste
/// parecia validar um telefone e validava uma tela que ninguém tem.
void main() {
  Future<void> montar(
    WidgetTester t, {
    required Size aparelho,
    required double escala,
    bool permitirRevelar = true,
  }) async {
    t.view.physicalSize = aparelho;
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(escala)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(MemoraEspacamento.xl),
                child: CampoSenha(
                  rotulo: 'Crie uma senha',
                  textoAjuda: 'Pelo menos 8 letras ou números',
                  permitirRevelar: permitirRevelar,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('O rótulo de revelar quebra linha em vez de estourar a tela', () {
    for (final Size aparelho in aparelhos) {
      for (final double escala in <double>[1.0, 1.5, 2.0]) {
        testWidgets('${nomeDo(aparelho)}, escala $escala', (
          WidgetTester t,
        ) async {
          await montar(t, aparelho: aparelho, escala: escala);

          expect(
            t.takeException(),
            isNull,
            reason:
                'o controle de revelar nao pode estourar a largura de '
                '${nomeDo(aparelho)} em $escala — e a `Row` dele so nao '
                'estoura porque o rotulo e `Flexible`',
          );

          // Estar dentro da tela não basta: o rótulo precisa continuar
          // legível. Truncar seria tão ruim quanto estourar, porque é o texto
          // que desfaz a ambiguidade do ícone.
          final Finder rotulo = find.text('Mostrar senha');
          expect(rotulo, findsOneWidget);
          expect(
            t.getRect(rotulo).right,
            lessThanOrEqualTo(aparelho.width),
            reason: 'o rotulo precisa caber na largura do aparelho',
          );
        });
      }
    }
  });

  testWidgets('sem permitirRevelar nao ha controle nenhum — FR-060', (
    WidgetTester t,
  ) async {
    await montar(
      t,
      aparelho: referencia,
      escala: MemoraDimensoes.escalaTextoMax,
      permitirRevelar: false,
    );

    expect(t.takeException(), isNull);
    expect(find.text('Mostrar senha'), findsNothing);
  });
}
