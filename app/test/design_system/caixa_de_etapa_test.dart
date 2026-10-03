import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/design_system/componentes/toque/superficie_tocavel.dart';

import '../suporte/aparelhos.dart';

/// `CaixaDeEtapa` — T114, FR-002a e a regra 8 da R2 da feature 004.
///
/// Três coisas precisam continuar verdadeiras, e cada uma tem o seu portão:
///
/// 1. **Informação, não ação** (FR-012 da 002): nenhuma superfície de toque
///    própria e nenhum contorno de pílula nem fundo de ação.
/// 2. **A frase vem antes do conteúdo**, para quem enxerga e para o TalkBack.
/// 3. **A ampliação não corta a instrução**: a frase quebra em linhas, e a
///    caixa não passa da largura da tela em nenhum aparelho da matriz.
void main() {
  const String frase = 'Escreva aqui o seu e-mail';
  const String fraseLonga =
      'Escreva aqui o endereço de e-mail que você usa todos os dias, '
      'o mesmo que a sua filha usou para te cadastrar';

  Widget caixa({String instrucao = frase, Widget? filho}) => CaixaDeEtapa(
    instrucao: instrucao,
    child:
        filho ??
        const CampoTexto(rotulo: 'Seu e-mail', textoAjuda: 'Para você entrar'),
  );

  Widget app(Widget filho, {MemoraTemaId tema = MemoraTemaId.claro}) =>
      MaterialApp(
        theme: TemasMemora.porId(tema),
        home: Scaffold(body: SingleChildScrollView(child: filho)),
      );

  /// Os `BoxDecoration` desenhados **pela caixa** — o que está dentro do
  /// [child] não conta, e o child dos testes é um campo de texto que tem
  /// decoração própria. Por isso o `child` de teste dos portões visuais é um
  /// `SizedBox`.
  Iterable<BoxDecoration> decoracoes(WidgetTester t) => t
      .widgetList<Container>(
        find.descendant(
          of: find.byType(CaixaDeEtapa),
          matching: find.byType(Container),
        ),
      )
      .map((Container c) => c.decoration)
      .whereType<BoxDecoration>();

  group('A frase e o conteúdo', () {
    testWidgets('mostra a frase e o conteúdo, a frase primeiro', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(caixa()));
      expect(find.text(frase), findsOneWidget);
      expect(find.byType(CampoTexto), findsOneWidget);
      expect(
        t.getTopLeft(find.text(frase)).dy,
        lessThan(t.getTopLeft(find.byType(CampoTexto)).dy),
        reason: 'a instrução vem escrita acima do que se toca',
      );
    });

    testWidgets('a frase é cabeçalho e a caixa é um grupo só', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      await t.pumpWidget(app(caixa()));
      expect(
        t.getSemantics(find.bySemanticsLabel(frase)),
        isSemantics(isHeader: true, label: frase),
      );
      // E o conteúdo continua sendo o que é: sem a fusão que fazia o campo
      // virar "cabeçalho" com a frase dentro do rótulo dele.
      expect(
        t.getSemantics(find.byType(CampoTexto)),
        isSemantics(isHeader: false, isTextField: true),
      );
      expect(
        t.getSemantics(find.byType(CampoTexto)).label,
        isNot(contains(frase)),
        reason: 'frase e campo são dois nós lidos em sequência, não um só',
      );
      h.dispose();
    });
  });

  group('É informação, não ação — FR-012', () {
    testWidgets('a caixa não expõe semântica de botão nem ação de toque', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      await t.pumpWidget(
        app(caixa(filho: const SizedBox(width: 10, height: 10))),
      );
      // A semântica do grupo, e não a do texto dentro dele.
      expect(
        t.getSemantics(find.byType(CaixaDeEtapa)),
        isSemantics(isButton: false, hasTapAction: false),
      );
      h.dispose();
    });

    testWidgets('não tem superfície de toque própria', (WidgetTester t) async {
      await t.pumpWidget(
        app(caixa(filho: const SizedBox(width: 10, height: 10))),
      );
      for (final Type tipo in <Type>[
        InkWell,
        InkResponse,
        GestureDetector,
        SuperficieTocavel,
        TextButton,
        ElevatedButton,
      ]) {
        expect(
          find.descendant(
            of: find.byType(CaixaDeEtapa),
            matching: find.byType(tipo),
          ),
          findsNothing,
          reason:
              'a caixa é informação: $tipo seria uma terceira linguagem '
              'visual (FR-012)',
        );
      }
    });

    for (final MemoraTemaId tema in MemoraTemaId.values) {
      testWidgets('não é pílula nem tem fundo de ação — tema ${tema.name}', (
        WidgetTester t,
      ) async {
        await t.pumpWidget(
          app(caixa(filho: const SizedBox(width: 10, height: 10)), tema: tema),
        );
        final MemoraCores cores = TemasMemora.porId(
          tema,
        ).extension<MemoraTheme>()!.cores;
        final List<BoxDecoration> todas = decoracoes(t).toList();
        expect(todas, isNotEmpty);

        final BoxDecoration externa = todas.first;
        expect(
          externa.borderRadius,
          BorderRadius.circular(MemoraRaio.cartao),
          reason: 'raio de cartão, como o `Cartao` — não de pílula',
        );
        for (final BoxDecoration d in todas) {
          final BorderRadius? raio = d.borderRadius as BorderRadius?;
          if (raio != null) {
            expect(
              raio.topLeft.x,
              lessThan(MemoraRaio.porta),
              reason: 'raio de pílula é a linguagem da ação',
            );
          }
          expect(d.color, isNot(cores.primaria), reason: 'sem fundo de ação');
          expect(d.color, isNot(cores.destaque), reason: 'sem fundo de ação');
        }
      });
    }
  });

  group('A instrução quebra, a caixa não estoura', () {
    testWidgets('a frase longa não tem corte nem reticências', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(caixa(instrucao: fraseLonga)));
      final Text texto = t.widget<Text>(find.text(fraseLonga));
      expect(texto.maxLines, isNull);
      expect(texto.overflow, isNull);
    });

    void caso(Combinacao c) {
      testWidgets('em ${nomeDa(c)}', (WidgetTester t) async {
        vestir(t, c.aparelho);
        await t.pumpWidget(
          naCombinacao(
            c,
            Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    caixa(instrucao: fraseLonga),
                    const CaixaDeEtapa(
                      instrucao: 'Sim',
                      child: SizedBox(height: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(t.takeException(), isNull, reason: nomeDa(c));

        // Nunca passa da largura da tela.
        final Rect r = t.getRect(find.byType(CaixaDeEtapa).first);
        expect(r.left, greaterThanOrEqualTo(0), reason: nomeDa(c));
        expect(
          r.right,
          lessThanOrEqualTo(c.aparelho.width),
          reason: '${nomeDa(c)}: a caixa passou da largura da tela ($r)',
        );

        // Quebra em linhas, em vez de estourar: a frase longa é bem mais alta
        // que uma frase de uma linha só, no mesmo aparelho e na mesma escala.
        final double longa = t.getSize(find.text(fraseLonga)).height;
        final double curta = t.getSize(find.text('Sim')).height;
        expect(
          longa,
          greaterThan(curta * 1.5),
          reason: '${nomeDa(c)}: a frase não quebrou ($longa contra $curta)',
        );

        // E a frase cabe na largura da caixa: nada ficou cortado à direita.
        expect(
          t.getRect(find.text(fraseLonga)).right,
          lessThanOrEqualTo(r.right),
          reason: nomeDa(c),
        );
      });
    }

    // Os quatro aparelhos nas três escalas, no tema claro...
    matriz(temas: <MemoraTemaId>[MemoraTemaId.claro]).forEach(caso);
    // ...e os três temas no aparelho mais estreito, na maior ampliação.
    matriz(
      de: const <Size>[Size(320, 568)],
      em: const <double>[2.0],
    ).where((Combinacao c) => c.tema != MemoraTemaId.claro).forEach(caso);
  });
}
