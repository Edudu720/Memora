import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/hub/domain/hub.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';

import '../suporte/aparelhos.dart';

/// Acessibilidade do Hub — T070 da 003, FR-026 a FR-030, e T035 e T042 da 004
/// (FR-044: a matriz completa de aparelho × escala × tema).
///
/// A funcionalidade do Hub (FR-003, FR-016, FR-018) tem teste próprio em
/// `tela_hub_test.dart`. Este arquivo cobre os requisitos de acessibilidade, e
/// mede com a fonte **quadrada** do `flutter test`, que é pessimista nas duas
/// direções (R3): o que passa aqui passa com a Atkinson.
///
/// ⚠️ O requisito de **não rolar** (FR-017) mora em
/// `hub_cabe_sem_rolar_test.dart`, e de propósito em outro arquivo: ele mede
/// com a Atkinson **carregada**, e uma fonte carregada vale para o arquivo
/// inteiro — misturá-la aqui tiraria a margem da matriz.
void main() {
  /// As cinco portas que o Hub do aplicativo tem hoje, com o texto real —
  /// a quinta, a Ajuda, entrou na T090.
  List<PortaDoHub> portasDeExemplo({
    VoidCallback? aoAbrirAPrincipal,
    int quantas = 5,
  }) => <PortaDoHub>[
    PortaDoHub(
      rotulo: 'Conversar com a Memora',
      descricao: 'Me pergunte o que quiser',
      ilustracao: Ilustracao.portaConversa,
      principal: true,
      aoAbrir: aoAbrirAPrincipal ?? () {},
    ),
    PortaDoHub(
      rotulo: 'Meus aplicativos',
      descricao: 'Eu te ensino e posso abrir',
      ilustracao: Ilustracao.portaAplicativos,
      aoAbrir: () {},
    ),
    PortaDoHub(
      rotulo: 'Serviços sociais',
      descricao: 'Eu só te ensino o caminho',
      ilustracao: Ilustracao.portaServicos,
      aoAbrir: () {},
    ),
    PortaDoHub(
      rotulo: 'O que eu fiz por você',
      descricao: 'O que eu abri para você',
      ilustracao: Ilustracao.portaRegistro,
      aoAbrir: () {},
    ),
    PortaDoHub(
      rotulo: 'Preciso de ajuda',
      descricao: 'Dúvidas sobre o próprio Memora',
      ilustracao: Ilustracao.portaAjuda,
      aoAbrir: () {},
    ),
  ].take(quantas).toList();

  /// Monta o Hub numa janela do tamanho de um aparelho real.
  ///
  /// `MediaQuery(data: MediaQueryData(size: ...))` sozinho **não** muda as
  /// restrições de verdade do layout — só o valor que widgets leem via
  /// `MediaQuery.of`. Sem `vestir`, o teste roda contra a janela padrão do
  /// `flutter test`, bem maior que qualquer Android, e esconde overflow real.
  Future<void> montar(
    WidgetTester t,
    Combinacao c, {
    VoidCallback? aoAbrirAPrincipal,
    int quantas = 5,
  }) async {
    vestir(t, c.aparelho);
    await t.pumpWidget(
      naCombinacao(
        c,
        TelaHub(
          portas: portasDeExemplo(
            aoAbrirAPrincipal: aoAbrirAPrincipal,
            quantas: quantas,
          ),
          aoVoltar: () {},
        ),
      ),
    );
  }

  const Combinacao padrao = (
    aparelho: referencia,
    escala: 1.0,
    tema: MemoraTemaId.claro,
  );

  group('Alvo de toque — FR-026', () {
    testWidgets('cada porta e o "Voltar" atendem a diretriz de 48 dp', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      await montar(t, padrao);

      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      h.dispose();
    });

    testWidgets('as portas ficam afastadas por pelo menos 8 dp', (
      WidgetTester t,
    ) async {
      await montar(t, padrao);

      final List<Rect> caixas = <Rect>[
        for (final Element e in find.byType(CartaoDePorta).evaluate())
          t.getRect(find.byWidget(e.widget)),
      ];
      for (int i = 1; i < caixas.length; i++) {
        expect(
          caixas[i].top - caixas[i - 1].bottom,
          greaterThanOrEqualTo(MemoraDimensoes.separacaoAlvo),
          reason: 'portas ${i - 1} e $i coladas demais',
        );
      }
    });
  });

  group('Matriz — FR-027 e FR-044', () {
    // A matriz de aparelhos entrou na revisão da PR #27: até então tudo
    // rodava num 390x844, e foi assim que o overflow da conversa passou. Os
    // três temas entraram com a feature 004.
    for (final Combinacao c in matriz()) {
      testWidgets('o Hub com 5 portas não estoura, e a principal é '
          'alcançável e responde em ${nomeDa(c)}', (WidgetTester t) async {
        int abriu = 0;
        await montar(t, c, aoAbrirAPrincipal: () => abriu++);

        expect(t.takeException(), isNull, reason: nomeDa(c));

        final Finder principal = find.byKey(
          TelaHub.chaveDaPorta('Conversar com a Memora'),
        );
        await exigirAlcancavel(
          t,
          principal,
          aparelho: c.aparelho,
          contexto: nomeDa(c),
        );
        await t.tap(principal);
        expect(
          abriu,
          1,
          reason: '${nomeDa(c)}: a ação principal não respondeu ao toque',
        );
      });
    }

    testWidgets('em 200% a lista rola, e a última porta é alcançável', (
      WidgetTester t,
    ) async {
      const Combinacao c = (
        aparelho: Size(320, 568),
        escala: 2.0,
        tema: MemoraTemaId.claro,
      );
      await montar(t, c);

      await exigirAlcancavel(
        t,
        find.byKey(TelaHub.chaveDaPorta('Preciso de ajuda')),
        aparelho: c.aparelho,
        contexto: nomeDa(c),
      );
    });
  });

  group('Leitor de tela anuncia cada porta — FR-026', () {
    testWidgets('a porta principal é anunciada como botão ativo, com a '
        'explicação como dica', (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      await montar(t, padrao);

      expect(
        t.getSemantics(
          find.byKey(TelaHub.chaveDaPorta('Conversar com a Memora')),
        ),
        isSemantics(
          label: 'Conversar com a Memora',
          hint: 'Me pergunte o que quiser',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
        ),
      );
      h.dispose();
    });

    testWidgets('o desenho da porta é decorativo: o leitor não o anuncia', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      await montar(t, padrao);

      // Imagem anunciada a cada porta acrescentaria uma parada à navegação
      // sem informar nada (FR-045).
      expect(
        find.bySemanticsLabel(RegExp('imagem|ilustra', caseSensitive: false)),
        findsNothing,
      );
      h.dispose();
    });
  });

  group('Nenhum gesto complexo — FR-030', () {
    testWidgets('o Hub não usa arrastar nem pressionar e segurar', (
      WidgetTester t,
    ) async {
      await montar(t, padrao);

      final Iterable<GestureDetector> gestos = t.widgetList<GestureDetector>(
        find.byType(GestureDetector),
      );

      for (final GestureDetector g in gestos) {
        expect(
          g.onLongPress,
          isNull,
          reason:
              'Pressionar e segurar exige precisão que não podemos '
              'pressupor.',
        );
        expect(g.onHorizontalDragStart, isNull);
        expect(g.onVerticalDragStart, isNull);
      }
    });
  });
}
