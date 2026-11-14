import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

/// Garante que informação nunca seja confundida com ação — nem visualmente,
/// nem semanticamente.
///
/// Cobre a FR-012 e o critério SC-006. Corresponde ao defeito mais grave
/// encontrado no protótipo: na tela de Perfil, nome, idade e e-mail apareciam
/// como pílulas azuis **idênticas aos botões do Hub**.
Widget _comTema(Widget filho) {
  return MaterialApp(
    theme: TemasMemora.claro,
    home: Scaffold(body: Center(child: filho)),
  );
}

void main() {
  group('Componentes de informação não são botões — FR-012', () {
    testWidgets('CampoInformacao não expõe semântica de botão',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _comTema(const CampoInformacao(rotulo: 'Nome', valor: 'Ana')),
      );

      expect(
        tester.getSemantics(find.byType(CampoInformacao)),
        isSemantics(isButton: false, hasTapAction: false),
        reason: 'Se o leitor de tela anunciar "botão", a pessoa vai tentar '
            'tocar num dado. É exatamente o erro do Perfil do protótipo.',
      );
      handle.dispose();
    });

    testWidgets('DestaqueInformacao não expõe semântica de botão',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _comTema(const DestaqueInformacao(rotulo: 'Plano', valor: 'Premium')),
      );

      expect(
        tester.getSemantics(find.byType(DestaqueInformacao)),
        isSemantics(isButton: false, hasTapAction: false),
      );
      handle.dispose();
    });

    testWidgets('CampoInformacao não reage ao toque',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _comTema(const CampoInformacao(rotulo: 'E-mail', valor: 'a@b.com')),
      );

      // Não deve existir nenhuma superfície de toque dentro do componente.
      expect(
        find.descendant(
          of: find.byType(CampoInformacao),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(CampoInformacao),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
    });

    testWidgets('botão expõe semântica de botão, ao contrário da informação',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _comTema(BotaoPrimario(rotulo: 'Continuar', aoTocar: () {})),
      );

      expect(
        tester.getSemantics(find.byType(BotaoPrimario)),
        isSemantics(isButton: true, isEnabled: true, hasTapAction: true),
        reason: 'O contraste com o teste anterior é o ponto: leitor de tela '
            'precisa distinguir dado de ação tanto quanto a visão. E anunciar '
            '"botão" sem expor ação de toque é pior que não anunciar nada — a '
            'pessoa tenta ativar e nada acontece.',
      );
      handle.dispose();
    });

    testWidgets('botão desabilitado não expõe ação de toque',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _comTema(const BotaoPrimario(rotulo: 'Continuar')),
      );

      expect(
        tester.getSemantics(find.byType(BotaoPrimario)),
        isSemantics(isButton: true, isEnabled: false, hasTapAction: false),
        reason: 'Desabilitado precisa ser anunciado como indisponível, e não '
            'oferecer uma ativação que não faz nada.',
      );
      handle.dispose();
    });

    testWidgets('Cartao é estritamente passivo e sem ação de toque', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _comTema(const Cartao(child: Text('Resumo informativo'))),
      );
      expect(
        tester.getSemantics(find.byType(Cartao)),
        isSemantics(isButton: false, hasTapAction: false),
      );
      expect(
        find.descendant(of: find.byType(Cartao), matching: find.byType(InkWell)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(Cartao),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
      handle.dispose();
    });

    testWidgets('PainelHeroi é informativo e nunca vira botão', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _comTema(
          const PainelHeroi(
            titulo: 'Frequência cardíaca',
            valorDestaque: '74 bpm',
            badgeStatus: BadgeDeStatus(rotulo: 'Normal'),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(PainelHeroi)),
        isSemantics(isButton: false, hasTapAction: false),
      );
      expect(
        find.descendant(
          of: find.byType(PainelHeroi),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(PainelHeroi),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
      handle.dispose();
    });

    testWidgets('BadgeDeStatus é informativo e não responde ao toque', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _comTema(const BadgeDeStatus(rotulo: 'Relógio conectado')),
      );
      expect(
        tester.getSemantics(find.byType(BadgeDeStatus)),
        isSemantics(isButton: false, hasTapAction: false),
      );
      expect(
        find.descendant(
          of: find.byType(BadgeDeStatus),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
      handle.dispose();
    });

    testWidgets('CaixaDeEtapa não expõe semântica de botão nem toque', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _comTema(
          const CaixaDeEtapa(
            instrucao: 'Leia com calma',
            child: Text('Conteúdo'),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(CaixaDeEtapa)),
        isSemantics(isButton: false, hasTapAction: false),
      );
      handle.dispose();
    });

    testWidgets('LinhaDeLista sem aoTocar não tem seta nem ação de toque', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _comTema(
          const LinhaDeLista(
            titulo: 'Última atualização',
            subtitulo: 'Hoje às 10:00',
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(LinhaDeLista)),
        isSemantics(isButton: false, hasTapAction: false),
      );
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
      expect(
        find.descendant(
          of: find.byType(LinhaDeLista),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
      handle.dispose();
    });

    testWidgets('componentes interativos 2.0 expõem semântica de botão', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _comTema(
          SingleChildScrollView(
            child: Column(
              children: <Widget>[
                CartaoHeroi(
                  titulo: 'Conversar',
                  rotuloAcao: 'Abrir',
                  aoTocar: () {},
                ),
                TileAcaoRapida(
                  icone: Icons.apps,
                  titulo: 'Aplicativos',
                  aoTocar: () {},
                ),
                ChipFiltro(
                  rotulo: 'Todos',
                  selecionado: true,
                  aoTocar: () {},
                ),
                LinhaDeLista(
                  titulo: 'Abrir item',
                  aoTocar: () {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(CartaoHeroi)),
        isSemantics(isButton: true, isEnabled: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.byType(TileAcaoRapida)),
        isSemantics(isButton: true, isEnabled: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.byType(ChipFiltro)),
        isSemantics(isButton: true, isEnabled: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.byType(LinhaDeLista)),
        isSemantics(isButton: true, isEnabled: true, hasTapAction: true),
      );
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      handle.dispose();
    });

    testWidgets('ListaInformacao aceita apenas campos de informação',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _comTema(
          const ListaInformacao(
            titulo: 'Seus dados',
            campos: <CampoInformacao>[
              CampoInformacao(rotulo: 'Nome', valor: 'Ana'),
              CampoInformacao(rotulo: 'Idade', valor: '72'),
            ],
          ),
        ),
      );

      expect(find.byType(CampoInformacao), findsNWidgets(2));
      expect(find.text('Seus dados'), findsOneWidget);
      // A tipagem de `campos` impede, em tempo de compilação, que um botão
      // seja misturado aos dados.
      expect(
        find.descendant(
          of: find.byType(ListaInformacao),
          matching: find.byType(BotaoPrimario),
        ),
        findsNothing,
      );
    });
  });

  group('Informação cresce com o texto ampliado — FR-026', () {
    testWidgets('CampoInformacao não estoura em escala 2.0',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: const MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(MemoraDimensoes.escalaTextoMax),
            ),
            child: Scaffold(
              body: Center(
                child: CampoInformacao(
                  rotulo: 'Endereço de e-mail cadastrado',
                  valor: 'eduardo.juncker.toras@fatec.sp.gov.br',
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
