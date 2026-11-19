import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/presentation/telas/tela_conversa.dart';
import 'package:memora/features/casca/casca_interna.dart';
import 'package:memora/features/cuidado/presentation/widgets/botao_sos_persistente.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';
import 'package:memora/l10n/textos_assistente.dart';
import 'package:memora/l10n/textos_sos.dart';

import '../../../suporte/aparelhos.dart';
import '../../autenticacao/fluxo_dentro_da_conta.dart';

/// Os portões da bolinha do SOS (feature 014, sessão de 2026-11-18).
///
/// O Henrique, testando o APK 1.0.6 no celular, pediu: uma bolinha vermelha
/// só com "SOS", igual em toda tela; nenhuma faixa no topo; no Início, em Meu
/// perfil, em Ajuda e nos outros cabeçalhos, no canto superior direito, na
/// altura do título; em Ajustes, onde estava a paleta, e a paleta ao lado do
/// título; nas telas com a barra "Voltar", na própria barra.
void main() {
  Finder sos() => find.byKey(CascaInterna.chaveBotaoSos);

  /// O título grande da tela à vista.
  Finder titulo() => find.descendant(
    of: find.byType(TituloComSos),
    matching: find.byWidgetPredicate(
      (Widget w) => w is TextoMemora && w.estilo == EstiloTexto.tituloTela,
    ),
  );

  /// Os retângulos de tudo que se toca na tela à vista, menos o próprio SOS
  /// e quem o contém.
  List<Rect> alvosTocaveis(WidgetTester t) {
    final Element doSos = sos().evaluate().single;
    final Set<Element> acimaDoSos = <Element>{doSos};
    doSos.visitAncestorElements((Element e) {
      acimaDoSos.add(e);
      return true;
    });
    final Set<Element> dentroDoSos = find
        .descendant(of: sos(), matching: find.byWidgetPredicate((Widget _) => true))
        .evaluate()
        .toSet();
    final List<Rect> rects = <Rect>[];
    for (final Element e in <Element>[
      ...find.byType(InkWell).evaluate(),
      ...find.byType(GestureDetector).evaluate(),
    ]) {
      if (acimaDoSos.contains(e) || dentroDoSos.contains(e)) continue;
      final RenderObject? ro = e.renderObject;
      if (ro is! RenderBox || !ro.hasSize || ro.size.isEmpty) continue;
      rects.add(ro.localToGlobal(Offset.zero) & ro.size);
    }
    return rects;
  }

  /// Os textos à vista, menos o "SOS" da bolinha.
  List<Rect> textos(WidgetTester t) {
    final Set<Element> dentroDoSos = find
        .descendant(of: sos(), matching: find.byWidgetPredicate((Widget _) => true))
        .evaluate()
        .toSet();
    final List<Rect> rects = <Rect>[];
    for (final Element e in find.byType(RichText).evaluate()) {
      if (dentroDoSos.contains(e)) continue;
      final RenderObject? ro = e.renderObject;
      if (ro is! RenderBox || !ro.hasSize || ro.size.isEmpty) continue;
      rects.add(ro.localToGlobal(Offset.zero) & ro.size);
    }
    return rects;
  }

  /// Uma bolinha só, um círculo de pelo menos 48 dp, que não cobre texto nem
  /// alvo nenhum e fica a 8 dp de todo outro alvo de toque.
  void exigirBolinhaLivre(WidgetTester t, String onde) {
    expect(sos(), findsOneWidget, reason: '$onde: uma bolinha, e uma só');
    expect(
      find.byKey(CascaInterna.chaveSosFlutuante),
      findsNothing,
      reason: '$onde: a tela tem cabeçalho, e a bolinha devia estar nele',
    );
    final Rect b = t.getRect(sos());
    expect(b.width, greaterThanOrEqualTo(MemoraDimensoes.alvoMinimo));
    expect(b.height, closeTo(b.width, 0.01), reason: '$onde: não é círculo');
    final Size janela =
        t.view.physicalSize / t.view.devicePixelRatio;
    expect(b.left, greaterThanOrEqualTo(0), reason: '$onde: saiu da tela');
    expect(b.right, lessThanOrEqualTo(janela.width), reason: '$onde: saiu');
    expect(b.top, greaterThanOrEqualTo(0), reason: '$onde: saiu da tela');

    final Rect folga = b.inflate(MemoraDimensoes.separacaoAlvo - 0.01);
    for (final Rect r in alvosTocaveis(t)) {
      expect(
        r.overlaps(folga),
        isFalse,
        reason: '$onde: a bolinha ($b) está a menos de 8 dp do alvo $r',
      );
    }
    for (final Rect r in textos(t)) {
      expect(
        r.overlaps(b),
        isFalse,
        reason: '$onde: a bolinha ($b) cobre o texto em $r',
      );
    }
  }

  testWidgets('(a) a bolinha mostra só "SOS", sem ícone, e o leitor de tela '
      'ouve o nome e a dica de sempre', (WidgetTester t) async {
    int toques = 0;
    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        home: Scaffold(
          body: Center(
            child: BotaoSosPersistente(
              key: BotaoSosPersistente.chaveBotao,
              aoTocar: () => toques++,
            ),
          ),
        ),
      ),
    );
    final Finder bolinha = find.byKey(BotaoSosPersistente.chaveBotao);
    final List<String> escritos = find
        .descendant(of: bolinha, matching: find.byType(Text))
        .evaluate()
        .map((Element e) => (e.widget as Text).data ?? '')
        .toList();
    // O literal, e não a constante: trocar a constante por "SOS Ajuda" tem
    // de reprovar aqui (decisão do Henrique, 2026-11-18).
    expect(escritos, <String>['SOS']);
    expect(TextosSos.textoDaBolinha, 'SOS');
    expect(
      find.descendant(of: bolinha, matching: find.byType(Icon)),
      findsNothing,
    );
    final Size lado = t.getSize(bolinha);
    expect(lado.width, greaterThanOrEqualTo(MemoraDimensoes.alvoMinimo));
    expect(lado.height, closeTo(lado.width, 0.01));

    final SemanticsHandle leitor = t.ensureSemantics();
    expect(
      t.getSemantics(bolinha),
      matchesSemantics(
        label: TextosSos.rotuloBotaoSos,
        hint: TextosSos.semanticaBotaoSos,
        isButton: true,
        hasTapAction: true,
        isEnabled: true,
        hasEnabledState: true,
      ),
    );
    leitor.dispose();

    await t.tap(bolinha);
    expect(toques, 1);
  });

  testWidgets('(a) a 200% a bolinha cresce com o "SOS" e a letra não encolhe', (
    WidgetTester t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        home: Builder(
          builder: (BuildContext ctx) => MediaQuery(
            data: MediaQuery.of(
              ctx,
            ).copyWith(textScaler: const TextScaler.linear(2.0)),
            child: Scaffold(
              body: Center(
                child: BotaoSosPersistente(
                  key: BotaoSosPersistente.chaveBotao,
                  aoTocar: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(t.takeException(), isNull);
    final Finder bolinha = find.byKey(BotaoSosPersistente.chaveBotao);
    final Finder texto = find.descendant(
      of: bolinha,
      matching: find.byType(RichText),
    );
    final Rect b = t.getRect(bolinha);
    final Rect r = t.getRect(texto);
    // O texto inteiro dentro do círculo: os quatro cantos do retângulo dele.
    for (final Offset canto in <Offset>[
      r.topLeft,
      r.topRight,
      r.bottomLeft,
      r.bottomRight,
    ]) {
      expect(
        (canto - b.center).distance,
        lessThanOrEqualTo(b.width / 2 + 0.01),
        reason: 'o canto $canto do "SOS" sai do círculo $b',
      );
    }
    // A letra está a 200%: 2 × o tamanho do rótulo de botão.
    final RenderParagraph p = t.renderObject<RenderParagraph>(texto);
    expect(p.textScaler.scale(1), 2.0);
    expect(b.width, greaterThan(MemoraDimensoes.alvoMinimo));
  });

  testWidgets('(b)(c) Início, Ajustes, Meu perfil e Ajuda: a bolinha no canto '
      'superior direito, na altura do título, e nenhuma faixa', (
    WidgetTester t,
  ) async {
    final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
    await fluxo.montar(
      t,
      em: (
        aparelho: referencia,
        escala: 1.0,
        tema: MemoraTemaId.claro,
      ),
    );
    final double largura = referencia.width;

    void exigirNoCanto(String onde) {
      expect(
        find.byKey(CascaInterna.chaveSosFlutuante),
        findsNothing,
        reason: '$onde: a bolinha flutuante apareceu',
      );
      expect(sos(), findsOneWidget, reason: onde);
      final Rect b = t.getRect(sos());
      final Rect tit = t.getRect(titulo());
      // No canto direito: só a margem da tela entre ela e a borda.
      expect(
        largura - b.right,
        lessThanOrEqualTo(MemoraEspacamento.lg + 0.01),
        reason: '$onde: a bolinha ($b) não está no canto direito',
      );
      // Na altura do título.
      expect(
        b.center.dy,
        inInclusiveRange(tit.top, tit.bottom),
        reason: '$onde: a bolinha ($b) não está na altura do título ($tit)',
      );
      // À direita do título, a 8 dp dele.
      expect(
        b.left - tit.right,
        greaterThanOrEqualTo(MemoraDimensoes.separacaoAlvo - 0.01),
        reason: '$onde: a bolinha ($b) encosta no título ($tit)',
      );
    }

    exigirNoCanto('Início');

    await FluxoDentroDaConta.irPara(t, DestinoDaCasca.ajustes);
    exigirNoCanto('Ajustes');
    // A paleta saiu do canto direito: está antes do título, menor.
    final Rect paleta = t.getRect(find.byKey(CabecalhoDeTela.chaveFigura));
    final Rect tituloAjustes = t.getRect(titulo());
    expect(
      paleta.right,
      lessThanOrEqualTo(tituloAjustes.left),
      reason: 'a paleta ($paleta) devia estar antes do título ($tituloAjustes)',
    );
    expect(paleta.width, lessThanOrEqualTo(MemoraDimensoes.ilustracaoCartao));
    expect(
      paleta.center.dy,
      inInclusiveRange(tituloAjustes.top, tituloAjustes.bottom),
    );

    await FluxoDentroDaConta.irPara(t, DestinoDaCasca.perfil);
    exigirNoCanto('Meu perfil');

    await FluxoDentroDaConta.irPara(t, DestinoDaCasca.inicio);
    await FluxoDentroDaConta.tocar(t, find.text(TextosAssistente.portaAjuda));
    await FluxoDentroDaConta.esperarATransicao(t);
    exigirNoCanto('Ajuda');
  });

  testWidgets('(c) tela sem cabeçalho: a bolinha flutua no canto, e a casca '
      'não desenha faixa', (WidgetTester t) async {
    vestir(t, referencia);
    await t.pumpWidget(
      EscopoAparencia(
        controlador: ControladorAparencia(PreferenciaEmMemoria()),
        child: MaterialApp(
          theme: TemasMemora.claro,
          home: CascaInterna(
            aoRegistrarAtividade: () {},
            aoAcionarSos: () {},
            raizes: <DestinoDaCasca, WidgetBuilder>{
              DestinoDaCasca.ajustes: (_) => const SizedBox.expand(),
              DestinoDaCasca.inicio: (_) => const SizedBox.expand(),
              DestinoDaCasca.perfil: (_) => const SizedBox.expand(),
            },
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(sos(), findsOneWidget);
    expect(find.byKey(CascaInterna.chaveSosFlutuante), findsOneWidget);
    // Nada reservado no topo: o corpo começa na borda de cima.
    final Scaffold casca = t.widget<Scaffold>(
      find
          .descendant(
            of: find.byType(CascaInterna),
            matching: find.byType(Scaffold),
          )
          .first,
    );
    expect(casca.appBar, isNull, reason: 'a casca voltou a ter faixa no topo');
  });

  for (final Combinacao c in matriz(temas: <MemoraTemaId>[MemoraTemaId.claro])) {
    testWidgets('(d) a bolinha não cobre nada, em ${nomeDa(c)}', (
      WidgetTester t,
    ) async {
      final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
      await fluxo.montar(t, em: c);

      expect(t.takeException(), isNull);
      exigirBolinhaLivre(t, 'Início, ${nomeDa(c)}');

      await FluxoDentroDaConta.irPara(t, DestinoDaCasca.ajustes);
      expect(t.takeException(), isNull);
      exigirBolinhaLivre(t, 'Ajustes, ${nomeDa(c)}');

      await FluxoDentroDaConta.irPara(t, DestinoDaCasca.perfil);
      expect(t.takeException(), isNull);
      exigirBolinhaLivre(t, 'Meu perfil, ${nomeDa(c)}');

      await FluxoDentroDaConta.irPara(t, DestinoDaCasca.inicio);
      await FluxoDentroDaConta.tocar(t, find.text(TextosAssistente.portaAjuda));
      await FluxoDentroDaConta.esperarATransicao(t);
      expect(t.takeException(), isNull);
      exigirBolinhaLivre(t, 'Ajuda, ${nomeDa(c)}');

      // Já no Início, tocar nele de novo volta à raiz da pilha.
      await FluxoDentroDaConta.irPara(t, DestinoDaCasca.inicio);
      await FluxoDentroDaConta.irAoHub(t);
      expect(find.byType(TelaHub), findsOneWidget);
      expect(t.takeException(), isNull);
      exigirBolinhaLivre(t, 'Hub, ${nomeDa(c)}');

      await FluxoDentroDaConta.tocar(
        t,
        find.byKey(TelaHub.chaveDaPorta(TextosAssistente.portaConversa)),
      );
      await FluxoDentroDaConta.esperarATransicao(t);
      expect(find.byKey(TelaConversa.chaveCampo), findsOneWidget);
      expect(t.takeException(), isNull);
      exigirBolinhaLivre(t, 'Conversa, ${nomeDa(c)}');
    });
  }
}
