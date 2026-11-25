import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

/// Verifica que nenhum componente quebra com o texto ampliado.
///
/// Cobre FR-025, FR-026 e o critério SC-003. Aumentar a fonte do sistema é a
/// **primeira** coisa que uma pessoa com baixa visão faz no aparelho — um
/// aplicativo que quebra nessa condição é inutilizável para quem mais precisa
/// dele.

/// Renderiza [filho] com a escala de texto informada, numa tela de tamanho
/// realista de celular.
Widget _comEscala(Widget filho, double escala) {
  return MaterialApp(
    theme: TemasMemora.claro,
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        textScaler: TextScaler.linear(escala),
      ),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(MemoraEspacamento.lg),
            child: filho,
          ),
        ),
      ),
    ),
  );
}

/// Escalas verificadas em todo componente.
const List<double> _escalas = <double>[1.0, 1.5, 2.0];

void main() {
  // SONDA: a janela do teste passa a ser a de um aparelho de verdade.
  setUp(() {
    final TestWidgetsFlutterBinding b =
        TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.implicitView!.physicalSize = const Size(390, 844);
    b.platformDispatcher.implicitView!.devicePixelRatio = 1.0;
  });
  tearDown(() {
    final TestWidgetsFlutterBinding b =
        TestWidgetsFlutterBinding.ensureInitialized();
    b.platformDispatcher.implicitView!.resetPhysicalSize();
    b.platformDispatcher.implicitView!.resetDevicePixelRatio();
  });

  group('Componentes sobrevivem ao texto ampliado — FR-025 e SC-003', () {
    for (final double escala in _escalas) {
      testWidgets('BotaoPrimario em escala $escala',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          _comEscala(
            BotaoPrimario(
              rotulo: 'Quero aprender a usar o WhatsApp',
              aoTocar: () {},
            ),
            escala,
          ),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('BotaoPerigo em escala $escala', (WidgetTester tester) async {
        await tester.pumpWidget(
          _comEscala(
            BotaoPerigo(
              rotulo: 'Apagar todas as minhas fotos',
              icone: Icons.warning_amber_rounded,
              aoTocar: () {},
            ),
            escala,
          ),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('CampoInformacao em escala $escala',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          _comEscala(
            const CampoInformacao(
              rotulo: 'Endereço de e-mail cadastrado',
              valor: 'eduardo.juncker.toras@fatec.sp.gov.br',
            ),
            escala,
          ),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('ListaInformacao em escala $escala',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          _comEscala(
            const ListaInformacao(
              titulo: 'Seus dados cadastrados no Memora',
              campos: <CampoInformacao>[
                CampoInformacao(rotulo: 'Nome completo', valor: 'Ana Maria'),
                CampoInformacao(rotulo: 'Idade', valor: '72 anos'),
              ],
            ),
            escala,
          ),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('TextoMemora em escala $escala', (WidgetTester tester) async {
        await tester.pumpWidget(
          _comEscala(
            const TextoMemora.tituloTela('Bem-vinda ao Memora, Dona Ana'),
            escala,
          ),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('Blocos Memora 2.0 sobrevivem em escala $escala', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _comEscala(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const PainelHeroi(
                  titulo: 'Monitoramento diário de saúde',
                  valorDestaque: '74 bpm',
                  badgeStatus: BadgeDeStatus(
                    rotulo: 'Relógio conectado',
                    icone: Icons.watch_rounded,
                  ),
                ),
                const SizedBox(height: MemoraEspacamento.md),
                CartaoHeroi(
                  titulo: 'Conversar com a Memora',
                  subtitulo: 'Ajuda em passos simples para o dia a dia',
                  rotuloAcao: 'Começar conversa',
                  aoTocar: () {},
                ),
                const SizedBox(height: MemoraEspacamento.md),
                TileAcaoRapida(
                  icone: Icons.apps_rounded,
                  titulo: 'Aplicativos',
                  subtitulo: 'WhatsApp, YouTube e banco',
                  pistaAcao: 'Explorar',
                  aoTocar: () {},
                ),
                const SizedBox(height: MemoraEspacamento.md),
                Wrap(
                  spacing: MemoraEspacamento.sm,
                  runSpacing: MemoraEspacamento.sm,
                  children: <Widget>[
                    ChipFiltro(
                      rotulo: 'Todos os aplicativos',
                      selecionado: true,
                      aoTocar: () {},
                    ),
                    ChipFiltro(
                      rotulo: 'Mensagens e áudio',
                      selecionado: false,
                      aoTocar: () {},
                    ),
                  ],
                ),
                const SizedBox(height: MemoraEspacamento.md),
                LinhaDeLista(
                  titulo: 'Configurar preferência de texto ampliado',
                  subtitulo: 'Ajuste para enxergar com conforto',
                  aoTocar: () {},
                ),
                const SizedBox(height: MemoraEspacamento.md),
                NavegacaoInferior(
                  indiceAtivo: 1,
                  aoSelecionar: (_) {},
                  itens: const <ItemNavegacao>[
                    ItemNavegacao(
                      icone: IconeDeNavegacao.ajustes,
                      rotulo: 'Ajustes',
                    ),
                    ItemNavegacao(
                      icone: IconeDeNavegacao.inicio,
                      rotulo: 'Início',
                    ),
                    ItemNavegacao(
                      icone: IconeDeNavegacao.perfil,
                      rotulo: 'Meu perfil',
                    ),
                  ],
                ),
              ],
            ),
            escala,
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Teto de ampliação — FR-019 e R7', () {
    testWidgets('escala acima do teto é limitada a 2.0',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _comEscala(const TextoMemora('Texto de teste'), 4.0),
      );

      final Text texto = tester.widget<Text>(find.byType(Text));
      final double efetivo = texto.textScaler!.scale(10) / 10;

      expect(
        efetivo,
        MemoraDimensoes.escalaTextoMax,
        reason: 'Sem teto, o layout estoura e a pessoa fica sem saída — a '
            'própria tela de configuração deixa de ser legível.',
      );
    });

    testWidgets('escala dentro do limite é preservada',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _comEscala(const TextoMemora('Texto de teste'), 1.5),
      );

      final Text texto = tester.widget<Text>(find.byType(Text));
      expect(texto.textScaler!.scale(10) / 10, 1.5);
    });
  });

  group('Teto aplicado de forma consistente — T025', () {
    testWidgets('todo componente limita a ampliação ao mesmo teto',
        (WidgetTester tester) async {
      // Escala de sistema muito acima do teto: nenhum componente pode
      // reagir de forma diferente dos demais.
      await tester.pumpWidget(
        _comEscala(
          Column(
            children: <Widget>[
              BotaoPrimario(rotulo: 'Continuar', aoTocar: () {}),
              const CampoInformacao(rotulo: 'Nome', valor: 'Ana'),
              const DestaqueInformacao(rotulo: 'Plano', valor: 'Premium'),
              const TextoMemora('Corpo'),
            ],
          ),
          4.0,
        ),
      );

      final Iterable<Text> textos = tester.widgetList<Text>(find.byType(Text));
      expect(textos, isNotEmpty);

      for (final Text t in textos) {
        expect(
          t.textScaler?.scale(10) ?? 10 * 4.0,
          10 * MemoraDimensoes.escalaTextoMax,
          reason: 'Um componente sem o teto se comporta diferente dos outros '
              'em ampliação extrema, e o layout quebra de forma imprevisível.',
        );
      }
    });
  });

  group('Área de toque preservada com texto ampliado', () {
    testWidgets('botão continua acima do alvo mínimo em escala 2.0',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _comEscala(BotaoPrimario(rotulo: 'Continuar', aoTocar: () {}), 2.0),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });
}
