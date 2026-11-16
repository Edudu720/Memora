import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/casca/casca_interna.dart';
import 'package:memora/l10n/textos_casca.dart';

import '../../suporte/aparelhos.dart';
import '../../suporte/movimento.dart';

/// A casca de quem está dentro da conta — T023, FR-015 e
/// contracts/navegacao.md da feature 004.
void main() {
  movimentoLiberado();
  late GlobalKey<CascaInternaState> casca;
  late int atividades;
  late int fechou;

  setUp(() {
    casca = GlobalKey<CascaInternaState>();
    atividades = 0;
    fechou = 0;
  });

  Widget raiz(String nome) => Scaffold(
    body: Center(child: TextoMemora('raiz de $nome', key: Key('raiz.$nome'))),
  );

  Widget app({MediaQueryData? midia, bool reduzir = false}) {
    final Widget c = CascaInterna(
      key: casca,
      aoRegistrarAtividade: () => atividades++,
      aoFecharOMemora: () async => fechou++,
      raizes: <DestinoDaCasca, WidgetBuilder>{
        DestinoDaCasca.ajustes: (_) => raiz('ajustes'),
        DestinoDaCasca.inicio: (_) => raiz('inicio'),
        DestinoDaCasca.perfil: (_) => raiz('perfil'),
      },
    );
    return MaterialApp(
      theme: TemasMemora.claro,
      builder: reduzir
          ? (BuildContext context, Widget? child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            )
          : null,
      home: midia == null ? c : MediaQuery(data: midia, child: c),
    );
  }

  Future<void> empilhar(WidgetTester t, String nome) async {
    casca.currentState!.empilhar<void>(
      MaterialPageRoute<void>(builder: (_) => raiz(nome)),
    );
    await t.pumpAndSettle();
  }

  Finder destino(DestinoDaCasca d) => find.descendant(
    of: find.byKey(CascaInterna.chaveDaBarra),
    matching: find.text(d.rotulo),
  );

  /// O arquivo SVG que o destino da [posicao] (de 1 a 3) está desenhando.
  String desenhoDe(WidgetTester t, int posicao) {
    final SvgPicture figura = t.widget<SvgPicture>(
      find.descendant(
        of: find.byKey(NavegacaoInferior.chaveDoIcone(posicao)),
        matching: find.byType(SvgPicture),
      ),
    );
    return (figura.bytesLoader as SvgAssetLoader).assetName;
  }

  group('A barra — FR-015', () {
    testWidgets('três destinos, cada um com desenho e nome escrito', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app());
      for (final DestinoDaCasca d in DestinoDaCasca.values) {
        expect(destino(d), findsOneWidget, reason: d.rotulo);
        // O desenho é o do próprio destino, e não o de outro: o arquivo leva o
        // nome dele.
        expect(
          desenhoDe(t, d.index + 1),
          anyOf(d.icone.caminhoContornado, d.icone.caminhoPreenchido),
          reason: 'ícone de ${d.rotulo}',
        );
      }
    });

    testWidgets(
      'o destino atual tem o ícone preenchido; os outros, só o contorno',
      (WidgetTester t) async {
        await t.pumpWidget(app());
        // Início é o segundo destino.
        expect(desenhoDe(t, 2), DestinoDaCasca.inicio.icone.caminhoPreenchido);
        expect(desenhoDe(t, 1), DestinoDaCasca.ajustes.icone.caminhoContornado);
        expect(desenhoDe(t, 3), DestinoDaCasca.perfil.icone.caminhoContornado);

        await t.tap(destino(DestinoDaCasca.perfil));
        await t.pumpAndSettle();
        expect(desenhoDe(t, 3), DestinoDaCasca.perfil.icone.caminhoPreenchido);
        expect(desenhoDe(t, 2), DestinoDaCasca.inicio.icone.caminhoContornado);
        expect(desenhoDe(t, 1), DestinoDaCasca.ajustes.icone.caminhoContornado);
      },
    );

    testWidgets('os três ícones ocupam a mesma caixa, atual ou não', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app());
      for (final DestinoDaCasca atual in DestinoDaCasca.values) {
        await t.tap(destino(atual));
        await t.pumpAndSettle();
        for (int i = 1; i <= DestinoDaCasca.values.length; i++) {
          expect(
            t.getSize(find.byKey(NavegacaoInferior.chaveDoIcone(i))),
            const Size.square(MemoraDimensoes.iconeDestaque),
            reason: 'ícone $i com ${atual.rotulo} à vista',
          );
        }
      }
    });

    testWidgets('começa no Início', (WidgetTester t) async {
      await t.pumpWidget(app());
      expect(casca.currentState!.destinoAtual, DestinoDaCasca.inicio);
      expect(find.byKey(const Key('raiz.inicio')), findsOneWidget);
    });

    testWidgets('o destino atual tem o traço e é anunciado como selecionado', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      await t.pumpWidget(app());
      // Início é o segundo destino.
      expect(find.byKey(NavegacaoInferior.chaveDoTraco(2)), findsOneWidget);
      expect(find.byKey(NavegacaoInferior.chaveDoTraco(1)), findsNothing);
      // A chave sozinha não prova nada: ela é aplicada pelo mesmo `ativo ?` que
      // pinta o traço, e um traço transparente passaria (revisão da #38).
      final Container traco = t.widget<Container>(
        find.byKey(NavegacaoInferior.chaveDoTraco(2)),
      );
      expect(
        (traco.decoration! as BoxDecoration).color,
        MemoraCores.claro.primaria,
      );
      expect(
        t.getSemantics(destino(DestinoDaCasca.inicio)),
        isSemantics(label: TextosCasca.destinoInicio, isSelected: true),
      );

      await t.tap(destino(DestinoDaCasca.perfil));
      await t.pumpAndSettle();
      expect(find.byKey(NavegacaoInferior.chaveDoTraco(3)), findsOneWidget);
      expect(find.byKey(NavegacaoInferior.chaveDoTraco(2)), findsNothing);
      h.dispose();
    });
  });

  group('A troca de destino — FR-011, R3 (V8)', () {
    /// A posição horizontal, na tela, do centro da raiz de [nome].
    double x(WidgetTester t, String nome) =>
        t.getCenter(find.byKey(Key('raiz.$nome'), skipOffstage: false)).dx;

    // A janela do teste é de 800 por 600: o centro fica em 400.
    const double centro = 400;

    testWidgets('para um destino à direita, ele entra pela direita', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app());
      await t.tap(destino(DestinoDaCasca.perfil));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      expect(x(t, 'perfil'), greaterThan(centro), reason: 'entra da direita');
      expect(x(t, 'inicio'), lessThan(centro), reason: 'o Início sai à esquerda');

      await t.pumpAndSettle();
      expect(x(t, 'perfil'), centro);
      expect(find.byKey(const Key('raiz.inicio')), findsNothing);
    });

    testWidgets('para um destino à esquerda, ele entra pela esquerda', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app());
      await t.tap(destino(DestinoDaCasca.ajustes));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      expect(x(t, 'ajustes'), lessThan(centro), reason: 'entra da esquerda');
      expect(x(t, 'inicio'), greaterThan(centro), reason: 'o Início sai à direita');
      await t.pumpAndSettle();
    });

    testWidgets('a posição relativa vale também de um lado para o outro', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app());
      await t.tap(destino(DestinoDaCasca.perfil));
      await t.pumpAndSettle();

      // Do Perfil (à direita) para o Ajustes (à esquerda): entra pela esquerda.
      await t.tap(destino(DestinoDaCasca.ajustes));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(x(t, 'ajustes'), lessThan(centro));
      expect(x(t, 'perfil'), greaterThan(centro));
      await t.pumpAndSettle();
    });

    testWidgets('termina em no máximo 500 ms (SC-004)', (WidgetTester t) async {
      await t.pumpWidget(app());
      await t.tap(destino(DestinoDaCasca.perfil));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(x(t, 'perfil'), centro);
      expect(
        find.byKey(const Key('raiz.inicio')),
        findsNothing,
        reason: 'o deslize já acabou e o destino que saiu foi para fora',
      );
    });

    testWidgets('a pilha de cada destino continua viva, com o estado dela', (
      WidgetTester t,
    ) async {
      final List<int> nasceu = <int>[];
      await t.pumpWidget(app());
      casca.currentState!.empilhar<void>(
        MaterialPageRoute<void>(
          builder: (_) => _TelaComContador(aoNascer: () => nasceu.add(1)),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.byKey(_TelaComContador.chaveDoBotao));
      await t.tap(find.byKey(_TelaComContador.chaveDoBotao));
      await t.pump();
      expect(find.text('toques: 2'), findsOneWidget);

      // Vai e volta por todos os destinos, devagar e depressa.
      await t.tap(destino(DestinoDaCasca.perfil));
      await t.pump(const Duration(milliseconds: 100));
      await t.tap(destino(DestinoDaCasca.ajustes));
      await t.pumpAndSettle();
      await t.tap(destino(DestinoDaCasca.inicio));
      await t.pumpAndSettle();

      expect(nasceu, hasLength(1), reason: 'a tela foi recriada');
      expect(
        find.text('toques: 2'),
        findsOneWidget,
        reason: 'a pessoa perdeu onde estava',
      );
    });

    testWidgets('o que está fora da tela não anima e não recebe nada', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      await t.pumpWidget(app());
      await t.tap(destino(DestinoDaCasca.perfil));
      await t.pumpAndSettle();

      final Finder foraDaTela = find.byKey(
        const Key('raiz.inicio'),
        skipOffstage: false,
      );
      expect(TickerMode.valuesOf(t.element(foraDaTela)).enabled, isFalse);
      expect(
        find.bySemanticsLabel('raiz de inicio'),
        findsNothing,
        reason: 'o leitor de tela não deve ler o destino que saiu',
      );
      expect(
        find.bySemanticsLabel('raiz de perfil'),
        findsOneWidget,
        reason: 'o destino à vista é lido',
      );
      h.dispose();
    });

    testWidgets('com "reduzir movimento", a troca é instantânea', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(reduzir: true));
      await t.tap(destino(DestinoDaCasca.perfil));
      await t.pump();
      await t.pump();

      expect(x(t, 'perfil'), centro, reason: 'chegou sem deslizar');
      expect(find.byKey(const Key('raiz.inicio')), findsNothing);

      await t.tap(destino(DestinoDaCasca.ajustes));
      await t.pump();
      await t.pump();
      expect(x(t, 'ajustes'), centro);
      expect(find.byKey(const Key('raiz.perfil')), findsNothing);
    });

    testWidgets('o "voltar" do aparelho na raiz também desliza para o Início', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app());
      await t.tap(destino(DestinoDaCasca.perfil));
      await t.pumpAndSettle();

      await t.binding.handlePopRoute();
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      // O Início está à esquerda do Perfil: entra pela esquerda.
      expect(x(t, 'inicio'), lessThan(centro));
      expect(x(t, 'perfil'), greaterThan(centro));
      await t.pumpAndSettle();
    });
  });

  group('Uma pilha por destino', () {
    testWidgets('quem volta ao Início encontra a tela onde deixou', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app());
      await empilhar(t, 'conversa');
      expect(find.byKey(const Key('raiz.conversa')), findsOneWidget);

      await t.tap(destino(DestinoDaCasca.perfil));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('raiz.perfil')), findsOneWidget);

      await t.tap(destino(DestinoDaCasca.inicio));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('raiz.conversa')), findsOneWidget);
    });

    testWidgets('tocar no destino em que já se está volta à raiz dele', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app());
      await empilhar(t, 'catalogo');
      await empilhar(t, 'passo');
      await t.tap(destino(DestinoDaCasca.inicio));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('raiz.passo')), findsNothing);
      expect(find.byKey(const Key('raiz.inicio')), findsOneWidget);
    });

    testWidgets('a barra continua à vista sobre a tela empilhada', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app());
      await empilhar(t, 'conversa');
      expect(find.byKey(CascaInterna.chaveDaBarra), findsOneWidget);
    });
  });

  group('O "voltar" do aparelho — contracts/navegacao.md, regra 4', () {
    testWidgets('desempilha a tela do destino atual', (WidgetTester t) async {
      await t.pumpWidget(app());
      await empilhar(t, 'conversa');
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.byKey(const Key('raiz.inicio')), findsOneWidget);
      expect(fechou, 0);
    });

    testWidgets('na raiz de outro destino, volta ao Início', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app());
      await t.tap(destino(DestinoDaCasca.ajustes));
      await t.pumpAndSettle();
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(casca.currentState!.destinoAtual, DestinoDaCasca.inicio);
      expect(fechou, 0);
    });

    testWidgets('na raiz do Início, pergunta antes de fechar o Memora', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app());
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.byKey(CascaInterna.chavePerguntaDeFechar), findsOneWidget);
      expect(fechou, 0, reason: 'fechar em silêncio é o Memora sumir');

      await t.tap(find.text(TextosCasca.botaoFicar));
      await t.pumpAndSettle();
      expect(find.byKey(CascaInterna.chavePerguntaDeFechar), findsNothing);
      expect(fechou, 0);

      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      await t.tap(find.text(TextosCasca.botaoFecharMemora));
      await t.pumpAndSettle();
      expect(fechou, 1);
    });
  });

  group('Atividade — FR-017 da 001', () {
    testWidgets('um toque numa tela empilhada conta como atividade', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app());
      await empilhar(t, 'conversa');
      final int antes = atividades;
      await t.tap(find.byKey(const Key('raiz.conversa')));
      expect(atividades, greaterThan(antes));
    });
  });

  group('Teclado aberto — FR-015', () {
    testWidgets('a barra sai com o teclado e volta quando ele fecha', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(
        app(
          midia: const MediaQueryData(
            size: referencia,
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
        ),
      );
      expect(find.byKey(CascaInterna.chaveDaBarra), findsNothing);

      await t.pumpWidget(app(midia: const MediaQueryData(size: referencia)));
      expect(find.byKey(CascaInterna.chaveDaBarra), findsOneWidget);
    });
  });

  group('Matriz — FR-044', () {
    for (final Combinacao c in matriz()) {
      testWidgets('a barra não estoura em ${nomeDa(c)}', (
        WidgetTester t,
      ) async {
        vestir(t, c.aparelho);
        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.porId(c.tema),
            home: MediaQuery(
              data: MediaQueryData(
                size: c.aparelho,
                textScaler: TextScaler.linear(c.escala),
              ),
              child: CascaInterna(
                aoRegistrarAtividade: () {},
                raizes: <DestinoDaCasca, WidgetBuilder>{
                  for (final DestinoDaCasca d in DestinoDaCasca.values)
                    d: (_) => raiz(d.name),
                },
              ),
            ),
          ),
        );
        expect(t.takeException(), isNull, reason: nomeDa(c));
        // A barra não pode tomar a tela: metade é o teto de qualquer faixa
        // fixa (lição do teto da conversa).
        expect(
          t.getSize(find.byType(NavegacaoInferior)).height,
          lessThan(c.aparelho.height / 2),
          reason: nomeDa(c),
        );
      });
    }
  });
}

/// Uma tela com estado, para provar que a pilha do destino não é recriada.
class _TelaComContador extends StatefulWidget {
  const _TelaComContador({required this.aoNascer});

  final VoidCallback aoNascer;

  static const Key chaveDoBotao = Key('contador.botao');

  @override
  State<_TelaComContador> createState() => _TelaComContadorState();
}

class _TelaComContadorState extends State<_TelaComContador> {
  int _toques = 0;

  @override
  void initState() {
    super.initState();
    widget.aoNascer();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        key: _TelaComContador.chaveDoBotao,
        onPressed: () => setState(() => _toques++),
        child: Text('toques: $_toques'),
      ),
    ),
  );
}
