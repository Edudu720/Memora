import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/presentation/telas/tela_conversa.dart';
import 'package:memora/features/casca/casca_interna.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';
import 'package:memora/features/inicio/presentation/tela_inicio.dart';
import 'package:memora/l10n/textos_assistente.dart';

import '../../suporte/aparelhos.dart';
import '../autenticacao/fluxo_dentro_da_conta.dart';

/// A matriz completa (FR-044) das telas de dentro da conta, **pelo fluxo real**
/// (T042 da feature 004).
///
/// ## Por que, se cada tela já tem a matriz dela
///
/// A matriz da tela isolada não tem a barra inferior, e a barra é o que mais
/// toma altura de quem amplia o texto: 78 px a 100% e 147 a 200% num 320×568,
/// medidos com a fonte real (e mais com a quadrada). "A ação principal
/// alcançável" só quer dizer alguma coisa **acima da barra** — uma ação que
/// rola para trás dela está à vista no teste e invisível para a pessoa.
///
/// O que se monta aqui é o `FluxoAutenticacao` de verdade: o cadastro
/// simulado, o login, a casca com as três pilhas, o Início e o Hub empilhado
/// sobre ele.
void main() {
  /// Reprova se [alvo] não ficar à vista **acima da barra inferior**.
  ///
  /// Um alvo **mais alto que a área à vista** não tem como caber inteiro: com
  /// a fonte quadrada, a porta da conversa a 200% num 320x568 tem 424 px, e a
  /// área acima da barra tem 355. Aí o que se exige é o que ainda é verdade — o
  /// topo dele está à vista, **e o centro também**, que é onde o toque cai.
  Future<void> exigirAcimaDaBarra(
    WidgetTester t,
    Finder alvo,
    Combinacao c,
  ) async {
    await t.ensureVisible(alvo);
    await t.pump();
    final Rect r = t.getRect(alvo);
    final double topoDaBarra = t
        .getTopLeft(find.byKey(CascaInterna.chaveDaBarra))
        .dy;
    expect(
      r.top,
      // Folga de ruído de ponto flutuante: `ensureVisible` alinha o alvo ao
      // topo e o topo sai como -1e-13 (visto no "ver tudo" do Início, T115).
      greaterThanOrEqualTo(-0.01),
      reason: '${nomeDa(c)}: o alvo ficou acima da janela ($r)',
    );
    if (r.height <= topoDaBarra) {
      expect(
        r.bottom,
        lessThanOrEqualTo(topoDaBarra),
        reason:
            '${nomeDa(c)}: o alvo ($r) ficou atrás da barra inferior '
            '(que começa em $topoDaBarra)',
      );
    } else {
      expect(
        r.center.dy,
        lessThan(topoDaBarra),
        reason:
            '${nomeDa(c)}: o alvo ($r) é mais alto que a área à vista e o '
            'centro dele ficou atrás da barra ($topoDaBarra)',
      );
    }
  }

  for (final Combinacao c in matriz()) {
    testWidgets('o Início e o Hub, dentro da casca, em ${nomeDa(c)}', (
      WidgetTester t,
    ) async {
      final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
      await fluxo.montar(t, em: c);

      // --- Início
      expect(t.takeException(), isNull, reason: 'Início, ${nomeDa(c)}');
      // A anfitriã (T053/T054) está lá, uma só, e o toque nela chega à vista
      // acima da barra: encolher é o que ela faz para isso (o balão é texto, e
      // texto longo rola: não é ação).
      expect(find.byKey(TelaInicio.chaveMemora), findsOneWidget);
      await exigirAcimaDaBarra(t, find.byKey(MemoraAnfitria.chaveDaAcao), c);
      await exigirAcimaDaBarra(t, find.byKey(TelaInicio.chaveConversar), c);
      await exigirAcimaDaBarra(t, find.byKey(TelaInicio.chaveVerTudo), c);

      // --- Hub
      await FluxoDentroDaConta.irAoHub(t);
      expect(find.byType(TelaHub), findsOneWidget);
      expect(t.takeException(), isNull, reason: 'Hub, ${nomeDa(c)}');
      final Finder conversa = find.byKey(
        TelaHub.chaveDaPorta(TextosAssistente.portaConversa),
      );
      await exigirAcimaDaBarra(t, conversa, c);

      // A ação principal responde: o toque leva à conversa de verdade.
      await t.tap(conversa);
      await FluxoDentroDaConta.esperarATransicao(t);
      expect(
        find.byKey(TelaConversa.chaveCampo),
        findsOneWidget,
        reason:
            '${nomeDa(c)}: tocar na ação principal do Hub não abriu a '
            'conversa',
      );
      expect(t.takeException(), isNull, reason: 'Conversa, ${nomeDa(c)}');
    });
  }
}
