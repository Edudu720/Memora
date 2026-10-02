import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

import 'estados_de_tela.dart';

/// O auxiliar da FR-006 reprova o que deve reprovar (T033a).
///
/// Portão novo é quebrado antes de ser dado como pronto: estes casos são a
/// quebra, deixada no repositório para não depender de alguém repeti-la.
void main() {
  Widget app(Widget corpo) => MaterialApp(
    theme: TemasMemora.claro,
    home: Scaffold(body: corpo),
  );

  testWidgets('aprova a tela que tem frase e desenho nos três estados', (
    WidgetTester t,
  ) async {
    await exigirOsEstadosDaFr006(
      t,
      tela: 'tela de exemplo',
      montar: (EstadoDaTela e) => app(switch (e) {
        EstadoDaTela.carregando => const Carregando(
          mensagem: 'Procurando os seus aplicativos…',
        ),
        EstadoDaTela.vazio => const EstadoVazio(
          titulo: 'Nada por aqui ainda',
          explicacao: 'Quando houver, aparece aqui.',
        ),
        EstadoDaTela.erro => const MensagemErro(
          mensagem: 'Não consegui carregar. Confira a internet.',
        ),
      }),
    );
  });

  testWidgets('reprova a tela em branco enquanto carrega', (
    WidgetTester t,
  ) async {
    await expectLater(
      () => exigirOsEstadosDaFr006(
        t,
        tela: 'tela em branco',
        montar: (EstadoDaTela e) =>
            e == EstadoDaTela.carregando ? app(const SizedBox()) : null,
      ),
      throwsA(isA<TestFailure>()),
    );
  });

  testWidgets('reprova o giro sozinho, sem dizer o que se espera', (
    WidgetTester t,
  ) async {
    await expectLater(
      () => exigirOsEstadosDaFr006(
        t,
        tela: 'só o giro',
        montar: (EstadoDaTela e) => e == EstadoDaTela.carregando
            ? app(const Center(child: CircularProgressIndicator()))
            : null,
      ),
      throwsA(isA<TestFailure>()),
    );
  });

  testWidgets('reprova a frase sozinha, sem desenho', (WidgetTester t) async {
    await expectLater(
      () => exigirOsEstadosDaFr006(
        t,
        tela: 'só a frase',
        montar: (EstadoDaTela e) => e == EstadoDaTela.erro
            ? app(const TextoMemora('Deu errado.'))
            : null,
      ),
      throwsA(isA<TestFailure>()),
    );
  });
}
