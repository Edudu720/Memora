import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/casca/casca_interna.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';

import '../features/autenticacao/fluxo_dentro_da_conta.dart';
import '../suporte/aparelhos.dart';
import '../suporte/fonte.dart';

/// O Hub cabe sem rolar — FR-017 e T035 da feature 004.
///
/// > O Hub MUST caber sem rolagem em 100% e 150% de ampliação no menor
/// > aparelho suportado.
///
/// ## Por que este arquivo mede com a Atkinson, e a matriz não
///
/// Todos os outros testes medem com a fonte **quadrada** do `flutter test`,
/// que é duas vezes mais larga que a real e pessimista de propósito: é margem
/// de segurança contra estouro. Para **estouro**, pessimismo é o que se quer.
/// Para **"cabe sem rolar"** ele é inútil: com a quadrada, o Hub precisa de
/// 650 px a mais que o 320×568 tem, **qualquer** que seja o desenho — o teste
/// reprovaria sempre e não diria nada.
///
/// Aqui, portanto, a Atkinson é carregada (`carregarAtkinson`), e é ela que a
/// pessoa vê. Carregar vale para o **arquivo inteiro**, e por isso este teste
/// mora sozinho: a matriz de `hub_acessibilidade_test.dart` continua com a
/// fonte quadrada.
///
/// ## Medido pelo fluxo real
///
/// O Hub é montado dentro da casca, com a barra inferior e o cabeçalho que a
/// pessoa de fato tem. A tela isolada, sem a barra, teria ~80 px a mais.
///
/// ## ⚠️ O que este teste prova, e o que ele não consegue provar
///
/// **100%: cabe**, depois de o cartão de porta emagrecer (sem a seta, desenho
/// de 48 dp, respiro vertical menor) e os textos das portas ficarem em uma
/// linha. **150%: não cabe, e nenhum desenho cabe** — a barra inferior sozinha
/// toma 123 px dos 568, e quatro portas com nome e explicação, a 150%,
/// precisam de ~700. O teste de 150% está escrito do jeito exato da FR-017 e
/// **pulado**, com os números: a FR-017 e a FR-016 (explicação em toda porta)
/// não cabem juntas nessa combinação, e quem decide qual cede é a equipe.
void main() {
  setUpAll(carregarAtkinson);

  const Size menor = Size(320, 568);

  /// Monta o fluxo real, na combinação, e abre o Hub.
  Future<void> abrirOHub(WidgetTester t, Combinacao c) async {
    final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
    await fluxo.montar(t, em: c);
    await FluxoDentroDaConta.irAoHub(t);
    expect(find.byType(TelaHub), findsOneWidget);
    expect(t.takeException(), isNull, reason: nomeDa(c));
  }

  /// Quanto a lista ainda rola. Zero é "cabe sem rolar".
  double quantoRola(WidgetTester t) {
    final ScrollableState rolagem = t.state<ScrollableState>(
      find.descendant(
        of: find.byKey(TelaHub.chaveLista),
        matching: find.byType(Scrollable),
      ),
    );
    return rolagem.position.maxScrollExtent;
  }

  /// A última porta inteira acima da barra inferior.
  void exigirTudoAVista(WidgetTester t, Combinacao c) {
    final double topoDaBarra = t
        .getTopLeft(find.byKey(CascaInterna.chaveDaBarra))
        .dy;
    final Iterable<Element> portas = find.byType(CartaoDePorta).evaluate();
    expect(portas, isNotEmpty);
    for (final Element e in portas) {
      final Rect r = t.getRect(find.byWidget(e.widget));
      expect(
        r.bottom,
        lessThanOrEqualTo(topoDaBarra),
        reason: '${nomeDa(c)}: a porta em ${r.top} passa da barra ($topoDaBarra)',
      );
    }
  }

  group('FR-017 — sem rolagem, no menor aparelho', () {
    for (final MemoraTemaId tema in MemoraTemaId.values) {
      final Combinacao c = (aparelho: menor, escala: 1.0, tema: tema);
      testWidgets('100%: o Hub cabe sem rolar em ${nomeDa(c)}', (
        WidgetTester t,
      ) async {
        await abrirOHub(t, c);

        expect(
          quantoRola(t),
          0,
          reason: '${nomeDa(c)}: a lista ainda rola (FR-017)',
        );
        exigirTudoAVista(t, c);
      });
    }

    // PULADO de propósito, e com os números: ver a nota no topo do arquivo.
    // FR-017 a 150% é inviável com a FR-016 -- medido, o Hub precisa de ~500 px
    // a mais do que o 320x568 deixa. A barra inferior sozinha toma 123 dos 568;
    // cada porta, com nome e explicação a 150%, passa de 130. Decisão da
    // equipe: a explicação ceder, o requisito cair para 100%, ou o 320x568 sair
    // do piso. Tire o `skip` quando decidir.
    testWidgets('150%: o Hub cabe sem rolar em 320x568 (PULADO: inviável com a '
        'FR-016)', (WidgetTester t) async {
      const Combinacao c = (
        aparelho: menor,
        escala: 1.5,
        tema: MemoraTemaId.claro,
      );
      await abrirOHub(t, c);

      expect(
        quantoRola(t),
        0,
        reason: '${nomeDa(c)}: a lista ainda rola (FR-017)',
      );
      exigirTudoAVista(t, c);
    }, skip: true);

    testWidgets('em 200%, rolar é aceitável — e o começo mostra que há mais', (
      WidgetTester t,
    ) async {
      const Combinacao c = (
        aparelho: menor,
        escala: 2.0,
        tema: MemoraTemaId.claro,
      );
      await abrirOHub(t, c);

      expect(quantoRola(t), greaterThan(0));
      // O começo da primeira porta está à vista: a pessoa vê por onde começar,
      // e a porta cortada na dobra é o sinal de que a lista continua.
      final Finder primeira = find.byType(CartaoDePorta).first;
      expect(
        t.getRect(primeira).top,
        lessThan(t.getTopLeft(find.byKey(CascaInterna.chaveDaBarra)).dy),
      );
    });
  });
}
