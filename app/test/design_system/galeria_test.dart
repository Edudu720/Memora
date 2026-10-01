import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

import '../suporte/aparelhos.dart';

/// A galeria do Design System — T045, FR-033.
///
/// ## Por que este arquivo vale mais do que parece
///
/// A galeria monta **todo** componente em **todo** estado. Percorrê-la do
/// topo ao fim é, de graça, um teste de fumaça do sistema inteiro: se um
/// componente estourar a largura no tema de alto contraste a 200% num aparelho
/// estreito, ele estoura aqui — sem ninguém precisar escrever um caso para ele.
///
/// ## Por que é preciso rolar
///
/// A lista da galeria é uma `ListView`, e ela só constrói e mede o que está na
/// janela visível (mais o `cacheExtent`). Uma versão anterior deste teste só
/// montava a galeria e olhava `takeException()`: o campo de senha, o de código,
/// a confirmação e a navegação **nunca eram construídos**, e a "fumaça do
/// sistema inteiro" era a fumaça do topo dela. Agora a lista é percorrida em
/// passos, com a checagem a cada passo, e o fim afirma que cada região da
/// lista chegou a ser construída.
///
/// ## `pumpAndSettle` não serve aqui
///
/// O `Carregando` anima sem parar, e a galeria tem um sempre na tela. Quem
/// chamar `pumpAndSettle` neste arquivo trava o teste até o tempo esgotar.
void main() {
  Future<void> montar(
    WidgetTester t, {
    required Size aparelho,
    double escala = 1.0,
  }) async {
    t.view.physicalSize = aparelho;
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(escala)),
        child: const MaterialApp(home: GaleriaMemora()),
      ),
    );
    await t.pump();
  }

  /// Os tipos de [_esperados] que existem na árvore neste instante.
  Set<Type> construidosAgora(WidgetTester t) => <Type>{
        for (final MapEntry<Type, Finder> e in _esperados.entries)
          if (t.any(e.value)) e.key,
      };

  /// A lista inteira da galeria, do topo ao fim, em passos de meia janela.
  ///
  /// Devolve os tipos de componente que chegaram a ser construídos em algum
  /// passo, para o teste afirmar que a rolagem de fato passou por todos.
  Future<Set<Type>> percorrer(WidgetTester t, {required String onde}) async {
    final Finder lista = find.descendant(
      of: find.byType(GaleriaMemora),
      matching: find.byType(ListView),
    );
    final ScrollableState rolagem = t.state<ScrollableState>(
      find.descendant(of: lista, matching: find.byType(Scrollable)),
    );

    final Set<Type> vistos = <Type>{};

    rolagem.position.jumpTo(0);
    await t.pump();

    for (int passo = 0; passo < 400; passo++) {
      expect(t.takeException(), isNull,
          reason: 'estouro $onde, no passo $passo da rolagem '
              '(posicao ${rolagem.position.pixels.toStringAsFixed(0)})');
      vistos.addAll(construidosAgora(t));

      final ScrollPosition p = rolagem.position;
      if (p.pixels >= p.maxScrollExtent) break;

      final double avanco = (p.viewportDimension / 2).clamp(1.0, 400.0);
      p.jumpTo((p.pixels + avanco).clamp(0.0, p.maxScrollExtent));
      await t.pump();
    }

    expect(t.takeException(), isNull, reason: 'estouro $onde, no fim da lista');
    vistos.addAll(construidosAgora(t));
    return vistos;
  }

  void todosConstruidos(Set<Type> vistos, String onde) {
    final List<Type> ausentes =
        _esperados.keys.where((Type k) => !vistos.contains(k)).toList();
    expect(ausentes, isEmpty,
        reason: 'a rolagem $onde nao chegou a construir $ausentes — a '
            'galeria nao foi medida inteira');
  }

  group('A galeria monta, inteira, em todo aparelho e toda ampliação', () {
    for (final Size aparelho in aparelhos) {
      for (final double escala in <double>[1.0, 1.5, 2.0]) {
        testWidgets('${nomeDo(aparelho)}, escala $escala',
            (WidgetTester t) async {
          await montar(t, aparelho: aparelho, escala: escala);
          final String onde = 'em ${nomeDo(aparelho)} a $escala';

          expect(t.takeException(), isNull, reason: 'estouro $onde, no topo');

          todosConstruidos(await percorrer(t, onde: onde), onde);
        });
      }
    }

    testWidgets('sem rolar, os componentes do fim da lista nao existem',
        (WidgetTester t) async {
      // Prova de que a rolagem acima é o que sustenta o teste: só com o topo
      // montado, os componentes do fim da lista não foram construídos — e um
      // teste que só olhasse o topo aprovaria sem ter medido nada deles.
      await montar(t, aparelho: aparelhos.last, escala: 2.0);

      final Set<Type> vistos = construidosAgora(t);

      expect(vistos.length, lessThan(_esperados.length));
      expect(vistos, isNot(contains(NavegacaoInferior)));
      expect(vistos, isNot(contains(CampoCodigo)));
    });
  });

  group('Os três temas — FR-004', () {
    MemoraTheme memoraDe(MemoraTemaId id) =>
        TemasMemora.porId(id).extension<MemoraTheme>()!;

    Color fundoDaGaleria(WidgetTester t) => t
        .widget<Scaffold>(find.descendant(
          of: find.byType(GaleriaMemora),
          matching: find.byType(Scaffold),
        ))
        .backgroundColor!;

    Future<void> tocarPastilha(WidgetTester t, String rotulo) async {
      final Finder pastilha = find.bySemanticsLabel(rotulo);
      await t.ensureVisible(pastilha);
      await t.tap(pastilha);
      await t.pump();
    }

    const Map<MemoraTemaId, String> rotulos = <MemoraTemaId, String>{
      MemoraTemaId.claro: 'Claro',
      MemoraTemaId.escuro: 'Escuro',
      MemoraTemaId.altoContraste: 'Alto contraste',
    };

    test('os tres temas tem fundos distintos (senao o teste abaixo nao prova)',
        () {
      final Set<Color> fundos = <Color>{
        for (final MemoraTemaId id in MemoraTemaId.values)
          memoraDe(id).cores.fundo,
      };
      expect(fundos.length, MemoraTemaId.values.length);
    });

    for (final MapEntry<MemoraTemaId, String> tema in rotulos.entries) {
      testWidgets('trocar para "${tema.value}" muda o fundo e nao quebra nada',
          (WidgetTester t) async {
        // No aparelho mais estreito, na escala máxima: onde a troca de tema
        // tem mais chance de revelar um componente que só cabia por sorte.
        await montar(
          t,
          aparelho: aparelhos.last,
          escala: MemoraDimensoes.escalaTextoMax,
        );

        // Passa antes por outro tema, para o caso "Claro" também provar uma
        // mudança: a galeria nasce no claro, e tocar nele sem sair de lá
        // passaria mesmo com a troca desligada.
        final MemoraTemaId outro = tema.key == MemoraTemaId.escuro
            ? MemoraTemaId.altoContraste
            : MemoraTemaId.escuro;
        await tocarPastilha(t, rotulos[outro]!);
        expect(fundoDaGaleria(t), memoraDe(outro).cores.fundo);

        await tocarPastilha(t, tema.value);
        expect(fundoDaGaleria(t), memoraDe(tema.key).cores.fundo,
            reason: 'tocar em "${tema.value}" nao trocou o tema da galeria');

        final String onde = 'no tema "${tema.value}" a 200%';
        todosConstruidos(await percorrer(t, onde: onde), onde);
      });
    }
  });

  testWidgets('a ampliação pode ser trocada de dentro da galeria',
      (WidgetTester t) async {
    await montar(t, aparelho: referencia);

    double escalaVista() => MediaQuery.textScalerOf(t.element(find.descendant(
          of: find.byType(GaleriaMemora),
          matching: find.byType(Scaffold),
        ))).scale(10);

    expect(escalaVista(), 10.0, reason: 'a galeria nasce em 100%');

    final Finder duzentos = find.bySemanticsLabel('200%');
    await t.ensureVisible(duzentos);
    await t.tap(duzentos);
    await t.pump();

    expect(escalaVista(), 20.0,
        reason: 'tocar em "200%" nao mudou a ampliacao dentro da galeria');
    expect(t.takeException(), isNull);
  });

  testWidgets('fora do modo de depuração a galeria não existe (R9)',
      (WidgetTester t) async {
    // `flutter test` roda em modo de depuração, então aqui ela existe. O que
    // este caso prende é o **contrato**: o ponto de entrada é anulável, e
    // quem chama precisa continuar tratando o `null`. Se alguém trocar o
    // retorno por `Widget` não-anulável para "simplificar", a galeria passa a
    // acompanhar o aplicativo até a loja, e este teste para de compilar.
    final Widget? galeria = GaleriaMemora.paraDesenvolvimento();

    expect(galeria, isNotNull, reason: 'flutter test roda em kDebugMode');
    expect(galeria, isA<GaleriaMemora>());
  });
}

/// O que a rolagem precisa ter construído ao chegar ao fim — um componente de
/// cada região da lista, do topo ao último.
final Map<Type, Finder> _esperados = <Type, Finder>{
  TextoMemora: find.byType(TextoMemora),
  BotaoPrimario: find.byType(BotaoPrimario),
  BotaoPerigo: find.byType(BotaoPerigo),
  ListaInformacao: find.byType(ListaInformacao),
  CampoTexto: find.byType(CampoTexto),
  CampoSenha: find.byType(CampoSenha),
  CampoCodigo: find.byType(CampoCodigo),
  OpcaoSelecionavel: find.byType(OpcaoSelecionavel),
  ConfirmacaoMemora: find.byType(ConfirmacaoMemora),
  MensagemErro: find.byType(MensagemErro),
  EstadoVazio: find.byType(EstadoVazio),
  CartaoComAvatar: find.byType(CartaoComAvatar),
  BarraSuperior: find.byType(BarraSuperior),
  NavegacaoInferior: find.byType(NavegacaoInferior),
};
