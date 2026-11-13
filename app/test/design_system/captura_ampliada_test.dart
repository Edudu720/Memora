import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/aprendizado/domain/guia.dart';
import 'package:memora/l10n/textos_guias.dart';

import '../suporte/aparelhos.dart';

/// T134 — ampliar a captura (FR-028b).
///
/// A pinça sozinha não basta (WCAG 2.5.1 e 2.5.7): o portão exige o botão
/// "Aproximar" que leva ao destaque, o "Afastar", o "Fechar" sempre à vista, o
/// selo "Exemplo" e o anel na imagem ampliada, a descrição para o leitor de
/// tela e nenhuma animação com "reduzir movimento".
void main() {
  const Passo passo = Passo(
    captura: CapturaDoGuia.paraTeste('tiktok', 1),
    // Fora do centro, para centralizar no destaque se distinguir de centralizar
    // na imagem.
    destaque: RegiaoRelativa(x: 0.2, y: 0.3, largura: 0.6, altura: 0.2),
    texto: 'Toque no ícone de perfil.',
    descricaoDaCaptura: 'Tela inicial do aplicativo com a barra de navegação.',
  );

  const Passo passoPendente = Passo(
    captura: CapturaDoGuia.paraTeste('nao-existe', 9),
    destaque: RegiaoRelativa(x: 0.2, y: 0.3, largura: 0.6, altura: 0.2),
    texto: 'Toque no ícone de perfil.',
    descricaoDaCaptura: 'Captura que ainda não existe.',
  );

  Widget appComPasso({
    Passo p = passo,
    MemoraTemaId tema = MemoraTemaId.claro,
    bool semAnimacao = false,
  }) {
    return MaterialApp(
      theme: TemasMemora.porId(tema),
      builder: (BuildContext context, Widget? filho) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: semAnimacao),
        child: filho!,
      ),
      home: Scaffold(body: PassoIlustrado(passo: p, posicao: 1, total: 3)),
    );
  }

  Finder naAmpliacao(Finder f) =>
      find.descendant(of: find.byType(CapturaAmpliada), matching: f);

  TransformationController controle(WidgetTester t) => t
      .widget<InteractiveViewer>(find.byKey(CapturaAmpliada.chaveVisor))
      .transformationController!;

  double escala(WidgetTester t) => controle(t).value.getMaxScaleOnAxis();

  bool habilitado(WidgetTester t, Key chave) =>
      t.widget<BotaoSecundario>(find.byKey(chave)).aoTocar != null;

  Future<void> abrirPeloBotao(WidgetTester t) async {
    await t.tap(find.byKey(PassoIlustrado.chaveVerImagemMaior));
    await t.pumpAndSettle();
  }

  group('abrir a ampliação', () {
    testWidgets('tocar na captura abre a ampliação', (WidgetTester t) async {
      await t.pumpWidget(appComPasso());
      expect(find.byType(CapturaAmpliada), findsNothing);

      await t.tap(find.byKey(PassoIlustrado.chaveCapturaTocavel));
      await t.pumpAndSettle();

      expect(find.byType(CapturaAmpliada), findsOneWidget);
    });

    testWidgets('o botão "Ver a imagem maior" abre a ampliação', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(appComPasso());
      expect(find.text(TextosGuias.verImagemMaior), findsOneWidget);

      await abrirPeloBotao(t);

      expect(find.byType(CapturaAmpliada), findsOneWidget);
    });

    testWidgets('a captura e o botão são botões para o leitor de tela', (
      WidgetTester t,
    ) async {
      final SemanticsHandle semantica = t.ensureSemantics();
      await t.pumpWidget(appComPasso());

      // O TalkBack anuncia o botão; sem `onTap` na própria Semantics o duplo
      // toque não ativaria nada.
      expect(
        t.getSemantics(find.byKey(PassoIlustrado.chaveCapturaTocavel)),
        isSemantics(
          label: '${passo.descricaoDaCaptura}. ${TextosGuias.areaDestacada}',
          hint: TextosGuias.dicaAmpliar,
          isButton: true,
          hasTapAction: true,
        ),
      );
      expect(find.bySemanticsLabel(TextosGuias.verImagemMaior), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('captura pendente não oferece a ampliação (FR-028a)', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(appComPasso(p: passoPendente));
      // O arquivo falta de verdade: o erro chega por I/O real, sem hora marcada.
      for (int i = 0; i < 20; i++) {
        if (find.text(TextosGuias.capturaPendente).evaluate().isNotEmpty) break;
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await t.pump();
      }
      // Depois de pendente, o aviso fica: a captura não é buscada em laço.
      for (int i = 0; i < 3; i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await t.pump();
      }

      expect(find.text(TextosGuias.capturaPendente), findsOneWidget);
      expect(find.byKey(PassoIlustrado.chaveVerImagemMaior), findsNothing);
      expect(find.byKey(PassoIlustrado.chaveCapturaTocavel), findsNothing);
    });
  });

  group('o que a ampliação mostra', () {
    testWidgets('selo "Exemplo", anel e os três botões estão presentes', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(appComPasso());
      await abrirPeloBotao(t);

      expect(find.byKey(CapturaAmpliada.chaveSelo), findsOneWidget);
      expect(find.text(TextosGuias.exemplo), findsOneWidget);
      expect(
        naAmpliacao(find.byKey(CapturaComDestaque.chaveDestaque)),
        findsOneWidget,
      );
      expect(find.byKey(CapturaAmpliada.chaveFechar), findsOneWidget);
      expect(find.byKey(CapturaAmpliada.chaveAproximar), findsOneWidget);
      expect(find.byKey(CapturaAmpliada.chaveAfastar), findsOneWidget);
    });

    testWidgets('o selo fica fixo na janela e o anel acompanha a escala', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(appComPasso());
      await abrirPeloBotao(t);

      final Rect seloAntes = t.getRect(find.byKey(CapturaAmpliada.chaveSelo));
      final Rect anelAntes = t.getRect(
        naAmpliacao(find.byKey(CapturaComDestaque.chaveDestaque)),
      );

      await t.tap(find.byKey(CapturaAmpliada.chaveAproximar));
      await t.pumpAndSettle();

      expect(
        t.getRect(find.byKey(CapturaAmpliada.chaveSelo)),
        seloAntes,
        reason: 'o selo nao pode se mexer nem crescer com o zoom',
      );
      final Rect anelDepois = t.getRect(
        naAmpliacao(find.byKey(CapturaComDestaque.chaveDestaque)),
      );
      expect(anelDepois.width, closeTo(anelAntes.width * 2, 0.5));
      expect(anelDepois.height, closeTo(anelAntes.height * 2, 0.5));
    });

    testWidgets('a imagem tem a descrição da captura para o leitor de tela', (
      WidgetTester t,
    ) async {
      final SemanticsHandle semantica = t.ensureSemantics();
      await t.pumpWidget(appComPasso());
      await abrirPeloBotao(t);

      expect(find.bySemanticsLabel(passo.descricaoDaCaptura), findsOneWidget);
      expect(find.bySemanticsLabel(TextosGuias.aproximar), findsOneWidget);
      expect(find.bySemanticsLabel(TextosGuias.afastar), findsOneWidget);
      expect(find.bySemanticsLabel(TextosGuias.fecharImagem), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('a ampliação atual é escrita e anunciada (região viva)', (
      WidgetTester t,
    ) async {
      final SemanticsHandle semantica = t.ensureSemantics();
      await t.pumpWidget(appComPasso());
      await abrirPeloBotao(t);

      expect(find.text('Imagem inteira'), findsOneWidget);

      await t.tap(find.byKey(CapturaAmpliada.chaveAproximar));
      await t.pumpAndSettle();

      expect(find.text('Ampliada 2 vezes'), findsOneWidget);
      expect(
        t.getSemantics(find.byKey(CapturaAmpliada.chaveAmpliacaoAtual)),
        isSemantics(label: 'Ampliada 2 vezes', isLiveRegion: true),
      );
      semantica.dispose();
    });
  });

  group('aproximar e afastar', () {
    testWidgets('Aproximar sobe em degraus e para em 4x, desabilitado', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(appComPasso());
      await abrirPeloBotao(t);
      expect(escala(t), closeTo(1, 1e-6));
      expect(habilitado(t, CapturaAmpliada.chaveAproximar), isTrue);

      for (final double esperada in <double>[2, 3, 4]) {
        await t.tap(find.byKey(CapturaAmpliada.chaveAproximar));
        await t.pumpAndSettle();
        expect(escala(t), closeTo(esperada, 1e-6));
      }

      expect(
        habilitado(t, CapturaAmpliada.chaveAproximar),
        isFalse,
        reason: 'em 4x nao ha mais para onde aproximar',
      );
      await t.tap(find.byKey(CapturaAmpliada.chaveAproximar));
      await t.pumpAndSettle();
      expect(escala(t), closeTo(4, 1e-6));
    });

    testWidgets('Afastar desce e em 1x volta à imagem inteira', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(appComPasso());
      await abrirPeloBotao(t);
      expect(
        habilitado(t, CapturaAmpliada.chaveAfastar),
        isFalse,
        reason: 'na imagem inteira nao ha o que afastar',
      );

      for (int i = 0; i < 3; i++) {
        await t.tap(find.byKey(CapturaAmpliada.chaveAproximar));
        await t.pumpAndSettle();
      }
      expect(escala(t), closeTo(4, 1e-6));

      for (final double esperada in <double>[3, 2, 1]) {
        await t.tap(find.byKey(CapturaAmpliada.chaveAfastar));
        await t.pumpAndSettle();
        expect(escala(t), closeTo(esperada, 1e-6));
      }

      expect(controle(t).value, Matrix4.identity());
      expect(habilitado(t, CapturaAmpliada.chaveAfastar), isFalse);
    });

    testWidgets('Aproximar leva o destaque para o meio da janela', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(appComPasso());
      await abrirPeloBotao(t);

      await t.tap(find.byKey(CapturaAmpliada.chaveAproximar));
      await t.pumpAndSettle();

      final Offset meioDaJanela = t.getCenter(
        find.byKey(CapturaAmpliada.chaveVisor),
      );
      final Offset meioDoAnel = t.getCenter(
        naAmpliacao(find.byKey(CapturaComDestaque.chaveDestaque)),
      );
      expect(meioDoAnel.dx, closeTo(meioDaJanela.dx, 1));
      expect(meioDoAnel.dy, closeTo(meioDaJanela.dy, 1));
    });

    testWidgets('um toque na imagem ampliada centraliza naquele ponto', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(appComPasso());
      await abrirPeloBotao(t);
      await t.tap(find.byKey(CapturaAmpliada.chaveAproximar));
      await t.pumpAndSettle();

      final Rect janela = t.getRect(find.byKey(CapturaAmpliada.chaveVisor));
      final Offset alvo = janela.center + const Offset(20, 40);
      final Offset cenaAntes = controle(t).toScene(alvo - janela.topLeft);

      await t.tapAt(alvo);
      await t.pumpAndSettle();

      expect(escala(t), closeTo(2, 1e-6), reason: 'tocar nao muda a escala');
      final Offset cenaNoMeio = controle(
        t,
      ).toScene(janela.center - janela.topLeft);
      expect(cenaNoMeio.dx, closeTo(cenaAntes.dx, 1));
      expect(cenaNoMeio.dy, closeTo(cenaAntes.dy, 1));
    });

    testWidgets('na imagem inteira, tocar não move nada', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(appComPasso());
      await abrirPeloBotao(t);

      await t.tapAt(
        t.getCenter(find.byKey(CapturaAmpliada.chaveVisor)) +
            const Offset(30, 30),
      );
      await t.pumpAndSettle();

      expect(controle(t).value, Matrix4.identity());
    });
  });

  group('fechar', () {
    testWidgets('"Fechar" sai da ampliação e volta ao passo', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(appComPasso());
      await abrirPeloBotao(t);

      await t.tap(find.byKey(CapturaAmpliada.chaveFechar));
      await t.pumpAndSettle();

      expect(find.byType(CapturaAmpliada), findsNothing);
      expect(find.byKey(PassoIlustrado.chaveVerImagemMaior), findsOneWidget);
    });

    testWidgets('o "Fechar" continua à vista com a imagem muito ampliada', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(appComPasso());
      await abrirPeloBotao(t);
      for (int i = 0; i < 3; i++) {
        await t.tap(find.byKey(CapturaAmpliada.chaveAproximar));
        await t.pumpAndSettle();
      }

      expect(find.byKey(CapturaAmpliada.chaveFechar), findsOneWidget);
      await t.tap(find.byKey(CapturaAmpliada.chaveFechar));
      await t.pumpAndSettle();
      expect(find.byType(CapturaAmpliada), findsNothing);
    });
  });

  group('reduzir movimento (FR-027)', () {
    testWidgets('com "reduzir movimento" a aproximação é instantânea', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(appComPasso(semAnimacao: true));
      await t.tap(find.byKey(PassoIlustrado.chaveVerImagemMaior));
      // Um quadro só: a rota também não anima.
      await t.pump();
      expect(find.byType(CapturaAmpliada), findsOneWidget);

      await t.tap(find.byKey(CapturaAmpliada.chaveAproximar));
      await t.pump();

      expect(escala(t), closeTo(2, 1e-6));
    });

    testWidgets('sem "reduzir movimento" a aproximação anima', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(appComPasso());
      await abrirPeloBotao(t);

      await t.tap(find.byKey(CapturaAmpliada.chaveAproximar));
      await t.pump();
      await t.pump(const Duration(milliseconds: 60));
      final double aMeio = escala(t);
      expect(aMeio, greaterThan(1));
      expect(aMeio, lessThan(2));

      await t.pumpAndSettle();
      expect(escala(t), closeTo(2, 1e-6));
    });
  });

  group('ampliação inteira na matriz (FR-044)', () {
    for (final Combinacao c in matriz()) {
      testWidgets('sem estouro em ${nomeDa(c)}', (WidgetTester t) async {
        vestir(t, c.aparelho);
        await t.pumpWidget(
          naCombinacao(c, const CapturaAmpliada(passo: passo)),
        );
        expect(t.takeException(), isNull, reason: nomeDa(c));

        final Rect janela = Offset.zero & c.aparelho;
        for (final Key chave in <Key>[
          CapturaAmpliada.chaveFechar,
          CapturaAmpliada.chaveAproximar,
          CapturaAmpliada.chaveAfastar,
          CapturaAmpliada.chaveSelo,
        ]) {
          final Rect r = t.getRect(find.byKey(chave));
          expect(
            janela.inflate(0.01).contains(r.topLeft) &&
                janela.inflate(0.01).contains(r.bottomRight),
            isTrue,
            reason: '${nomeDa(c)}: $chave fora da janela ($r)',
          );
        }
        for (final Key chave in <Key>[
          CapturaAmpliada.chaveFechar,
          CapturaAmpliada.chaveAproximar,
        ]) {
          expect(
            t.getSize(find.byKey(chave)).height,
            greaterThanOrEqualTo(MemoraDimensoes.alvoMinimo),
            reason: '${nomeDa(c)}: alvo de toque menor que 48 dp',
          );
        }

        // "Não estourar" não é "continuar utilizável": a imagem precisa de
        // espaço para ser vista.
        expect(
          t.getSize(find.byKey(CapturaAmpliada.chaveVisor)).height,
          greaterThanOrEqualTo(MemoraDimensoes.alvoMinimo * 3),
          reason: '${nomeDa(c)}: a imagem ficou sem espaço',
        );

        await t.tap(find.byKey(CapturaAmpliada.chaveAproximar));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: '${nomeDa(c)} ampliada');
        expect(escala(t), closeTo(2, 1e-6));
      });
    }
  });

  group('o passo com o botão, na matriz (FR-044)', () {
    for (final Combinacao c in matriz()) {
      testWidgets('"Ver a imagem maior" alcançável em ${nomeDa(c)}', (
        WidgetTester t,
      ) async {
        vestir(t, c.aparelho);
        await t.pumpWidget(
          naCombinacao(
            c,
            const Scaffold(
              body: PassoIlustrado(passo: passo, posicao: 1, total: 3),
            ),
          ),
        );
        expect(t.takeException(), isNull, reason: nomeDa(c));
        await exigirAlcancavel(
          t,
          find.byKey(PassoIlustrado.chaveVerImagemMaior),
          aparelho: c.aparelho,
          contexto: nomeDa(c),
        );
      });
    }
  });
}
