import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

Widget _app(Widget filho, {ThemeData? tema, double escala = 1.0}) => MaterialApp(
  theme: tema ?? TemasMemora.claro,
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(escala)),
    child: Scaffold(body: filho),
  ),
);

void main() {
  group('TextoComDestaque — a marcação', () {
    test('separa os trechos entre asteriscos', () {
      expect(
        TextoComDestaque.trechos('Eu mostro o caminho e *você faz*.'),
        <(String, bool)>[
          ('Eu mostro o caminho e ', false),
          ('você faz', true),
          ('.', false),
        ],
      );
    });

    test('aceita mais de um destaque na mesma frase', () {
      final List<(String, bool)> t =
          TextoComDestaque.trechos('a *b* c *d* e');
      expect(t.where(((String, bool) x) => x.$2).map(((String, bool) x) => x.$1),
          <String>['b', 'd']);
    });

    test('asterisco solto vira caractere comum, e não come a frase', () {
      // Perder a frase inteira por causa de um símbolo digitado a mais seria
      // pior do que exibir o símbolo.
      final List<(String, bool)> t =
          TextoComDestaque.trechos('promoção de 50* por cento');
      expect(t.every(((String, bool) x) => !x.$2), isTrue);
      expect(
        t.map(((String, bool) x) => x.$1).join(),
        'promoção de 50 por cento',
      );
    });

    testWidgets('o leitor de tela recebe a frase sem os asteriscos',
        (WidgetTester t) async {
      await t.pumpWidget(
        _app(const TextoComDestaque('Eu mostro e *você faz*.')),
      );

      // O realce é informação visual. Anunciá-lo em voz não acrescenta nada e
      // atrapalha quem depende do leitor.
      expect(find.bySemanticsLabel('Eu mostro e você faz.'), findsOneWidget);
    });

    testWidgets('nenhuma palavra destacada responde ao toque',
        (WidgetTester t) async {
      await t.pumpWidget(
        _app(const TextoComDestaque('Eu mostro e *você faz*.')),
      );

      // Este é o portão do componente. Azul é a cor das ações no Memora, e
      // palavra azul que aceita toque sem fazer nada é indistinguível de
      // aparelho quebrado para quem tem pouca familiaridade.
      final Text texto = t.widget<Text>(find.byType(Text));
      final List<InlineSpan> filhos =
          (texto.textSpan! as TextSpan).children!;

      expect(filhos, isNotEmpty);
      for (final InlineSpan span in filhos) {
        expect(
          (span as TextSpan).recognizer,
          isNull,
          reason: 'trecho "${span.text}" ficou tocável',
        );
      }
    });

    testWidgets('respeita o teto de ampliação do Memora',
        (WidgetTester t) async {
      await t.pumpWidget(
        _app(const TextoComDestaque('a *b* c'), escala: 4.0),
      );

      final Text texto = t.widget<Text>(find.byType(Text));
      // O sistema pediu 4x; o teto do Memora é 2x. Sem o limite, a frase
      // estouraria o cartão e a pessoa ficaria sem saída.
      expect(
        texto.textScaler!.scale(10),
        lessThanOrEqualTo(10 * MemoraDimensoes.escalaTextoMax),
      );
    });
  });

  group('IlustracaoMemora', () {
    testWidgets('é decorativa por padrão: fica fora do leitor de tela',
        (WidgetTester t) async {
      await t.pumpWidget(
        _app(const IlustracaoMemora(Ilustracao.casalIdoso, altura: 80)),
      );

      // Contar `ExcludeSemantics` não serviria: o próprio `SvgPicture` traz um
      // por dentro. O que importa é qual widget o componente põe por fora.
      final Finder porFora = find.descendant(
        of: find.byType(IlustracaoMemora),
        matching: find.byWidgetPredicate((Widget _) => true),
      );
      expect(t.widgetList(porFora).first, isA<ExcludeSemantics>());
    });

    testWidgets('é anunciada quando recebe descrição', (WidgetTester t) async {
      await t.pumpWidget(
        _app(
          const IlustracaoMemora(
            Ilustracao.casalIdoso,
            altura: 80,
            descricao: 'Um casal de idosos sorrindo',
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Um casal de idosos sorrindo'),
        findsOneWidget,
      );
    });

    test('todo caminho de ilustração aponta para a pasta de assets', () {
      for (final Ilustracao i in Ilustracao.values) {
        expect(i.caminho, startsWith('assets/ilustracoes/'));
        expect(i.caminho, endsWith('.svg'));
      }
    });
  });

  group('AvatarMemora e CartaoComAvatar', () {
    testWidgets('o avatar não é tocável', (WidgetTester t) async {
      await t.pumpWidget(_app(const AvatarMemora()));

      // Retrato de perfil costuma abrir alguma coisa. Este não abre: é
      // informação, e informação não usa linguagem de ação (FR-012).
      expect(find.byType(InkWell), findsNothing);
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('o conteúdo do cartão começa abaixo do avatar',
        (WidgetTester t) async {
      const Key conteudo = Key('conteudo');
      await t.pumpWidget(
        _app(
          const CartaoComAvatar(
            tamanhoDoAvatar: 120,
            child: SizedBox(key: conteudo, height: 40, width: 200),
          ),
        ),
      );

      final double baseDoAvatar =
          t.getBottomLeft(find.byType(AvatarMemora)).dy;
      final double topoDoConteudo = t.getTopLeft(find.byKey(conteudo)).dy;

      // Sem esse recuo, o primeiro campo do formulário ficaria por baixo do
      // retrato e a pessoa tocaria no lugar errado.
      expect(topoDoConteudo, greaterThanOrEqualTo(baseDoAvatar));
    });
  });

  group('Ilustrações e a Memora — feature 004 (T012, T013)', () {
    test('todo arquivo do enum existe e é um SVG que se desenha', () async {
      // Enum que aponta para arquivo inexistente compila, e vira um quadro
      // vazio no aparelho de alguém. O nome do arquivo não é checado pelo
      // compilador; isto é.
      for (final Ilustracao i in Ilustracao.values) {
        final File arquivo = File(i.caminho);
        expect(arquivo.existsSync(), isTrue, reason: '${i.name}: ${i.caminho}');
        final PictureInfo info = await vg.loadPicture(
          SvgStringLoader(arquivo.readAsStringSync()),
          null,
        );
        expect(info.size.isEmpty, isFalse, reason: '${i.name} não tem tamanho');
        info.picture.dispose();
      }
    });

    test('toda ilustração tem a origem registrada em LICENCAS.md', () {
      // Ilustração sem origem conhecida não pode ser apresentada numa entrega
      // pública (R4). A regra estava só no texto do LICENCAS.md; agora reprova.
      final String licencas =
          File('assets/ilustracoes/LICENCAS.md').readAsStringSync();
      for (final Ilustracao i in Ilustracao.values) {
        final String arquivo = i.caminho.split('/').last;
        expect(licencas, contains('`$arquivo`'),
            reason: '$arquivo não tem linha em assets/ilustracoes/LICENCAS.md');
      }
    });

    test('o medalhão é claro nos três temas', () {
      // Escuro, ele apagaria a cabeça azul da Memora — foi o que o rascunho
      // de renderização mostrou. "Claro" aqui é luminância acima da do texto
      // suave do tema claro: longe de qualquer azul-marinho.
      double luminancia(Color c) {
        double canal(double v) => v <= 0.04045
            ? v / 12.92
            : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
        return 0.2126 * canal(c.r) + 0.7152 * canal(c.g) + 0.0722 * canal(c.b);
      }

      for (final MemoraTheme tema in MemoraTheme.todos) {
        expect(luminancia(tema.cores.medalhao), greaterThan(0.6),
            reason: 'medalhão escuro demais no tema ${tema.id.name}');
      }
    });

    test('cada expressão da Memora usa um desenho da Memora', () {
      final Set<Ilustracao> usadas = <Ilustracao>{
        for (final ExpressaoDaMemora e in ExpressaoDaMemora.values) e.ilustracao,
      };
      expect(usadas.length, ExpressaoDaMemora.values.length,
          reason: 'duas expressões com o mesmo desenho');
      for (final Ilustracao i in usadas) {
        expect(i.name, startsWith('memora'));
      }
    });

    for (final MemoraTheme tema in MemoraTheme.todos) {
      testWidgets('Memora e medalhão sobre o círculo claro no tema '
          '${tema.id.name}', (WidgetTester t) async {
        await t.pumpWidget(
          _app(
            const Column(
              children: <Widget>[
                MemoraPersonagem(),
                MedalhaoDeIlustracao(Ilustracao.portaConversa, tamanho: 56),
              ],
            ),
            tema: TemasMemora.porId(tema.id),
          ),
        );

        final Iterable<DecoratedBox> circulos = t
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .where((DecoratedBox d) =>
                d.decoration is BoxDecoration &&
                (d.decoration as BoxDecoration).shape == BoxShape.circle);
        expect(circulos.length, 2);
        for (final DecoratedBox d in circulos) {
          expect((d.decoration as BoxDecoration).color, tema.cores.medalhao);
        }
      });
    }

    testWidgets('a Memora é decorativa por padrão e anunciada com descrição',
        (WidgetTester t) async {
      await t.pumpWidget(_app(const MemoraPersonagem()));
      expect(find.bySemanticsLabel(RegExp('.')), findsNothing);

      await t.pumpWidget(
        _app(
          const MemoraPersonagem(
            expressao: ExpressaoDaMemora.preocupada,
            descricao: 'A Memora, preocupada',
          ),
        ),
      );
      expect(find.bySemanticsLabel('A Memora, preocupada'), findsOneWidget);
    });

    testWidgets('nem a Memora nem o medalhão aceitam toque',
        (WidgetTester t) async {
      // São retrato, não ação (FR-012 da 002).
      await t.pumpWidget(
        _app(
          const Column(
            children: <Widget>[
              MemoraPersonagem(),
              MedalhaoDeIlustracao(Ilustracao.portaAjuda, tamanho: 56),
            ],
          ),
        ),
      );
      expect(find.byType(InkWell), findsNothing);
      expect(find.byType(GestureDetector), findsNothing);
    });
  });
}
