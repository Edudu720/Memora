import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

/// V9 — redução de movimento (FR-027, FR-028).
///
/// ## As duas metades do cenário
///
/// O V9 pede duas coisas, e a segunda é a que se esquece: *"nenhuma animação
/// ocorre — **e nenhuma informação se perde por causa disso**"*. Desligar o
/// movimento é fácil; garantir que nada era comunicado **só** pelo movimento
/// é o que exige teste.
///
/// ## Por que o portão varre a galeria inteira
///
/// Hoje só dois componentes animam, e os dois respeitam a preferência. O
/// problema não é o hoje: é o terceiro componente animado, escrito daqui a
/// três meses por quem não leu isto. Varrer a galeria — que monta todos —
/// pega esse terceiro no dia em que ele nascer, sem ninguém precisar lembrar
/// de escrever um caso para ele.
void main() {
  Future<void> montar(
    WidgetTester t,
    Widget filho, {
    required bool reduzirMovimento,
  }) async {
    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduzirMovimento),
          child: Scaffold(body: filho),
        ),
      ),
    );
  }

  /// A duração das animações **nossas** na árvore montada.
  ///
  /// ⚠️ Só `AnimatedContainer`, e a restrição não é preguiça: uma árvore
  /// Material montada traz `AnimatedTheme`, `AnimatedPhysicalModel`,
  /// `AnimatedDefaultTextStyle` e `_MaterialInterior` — todos em 200 ms,
  /// **todos do Flutter**, e nenhum deles consulta `disableAnimations`.
  /// Medido: seis deles aparecem só para montar um botão.
  ///
  /// Exigir zero de todos reprovaria contra código que não é nosso e não temos
  /// como consertar. O que está ao nosso alcance é o `AnimatedContainer` que
  /// **nós** escrevemos — e o portão de código-fonte, mais abaixo, cobre o
  /// caso geral sem depender de o que quer que seja estar montado.
  List<Duration> duracoesDe(WidgetTester t) => t
      .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
      .map((AnimatedContainer w) => w.duration)
      .toList();

  group('Com "reduzir movimento" ligado, nada anima', () {
    testWidgets('o botão não anima', (WidgetTester t) async {
      await montar(
        t,
        BotaoPrimario(rotulo: 'Continuar', aoTocar: () {}),
        reduzirMovimento: true,
      );

      expect(duracoesDe(t), isNotEmpty,
          reason: 'se o botao deixar de usar animacao implicita, este teste '
              'passa a nao provar nada — e precisa ser reescrito, nao apagado');
      expect(duracoesDe(t), everyElement(Duration.zero));
    });

    testWidgets('a opção selecionável não anima', (WidgetTester t) async {
      await montar(
        t,
        OpcaoSelecionavel(
          rotulo: 'Tem alguém te ajudando agora?',
          selecionada: true,
          aoSelecionar: () {},
        ),
        reduzirMovimento: true,
      );

      expect(duracoesDe(t), isNotEmpty);
      expect(duracoesDe(t), everyElement(Duration.zero));
    });
  });

  group('Com a preferência desligada, a animação existe', () {
    // Sem este grupo, um `MemoraMovimento.efetiva` que devolvesse `zero`
    // sempre passaria nos testes acima — e o aplicativo inteiro ficaria sem
    // movimento nenhum, sem ninguém ter pedido.
    testWidgets('o botão anima', (WidgetTester t) async {
      await montar(
        t,
        BotaoPrimario(rotulo: 'Continuar', aoTocar: () {}),
        reduzirMovimento: false,
      );

      expect(duracoesDe(t), contains(MemoraMovimento.rapido));
    });

    testWidgets('a opção selecionável anima', (WidgetTester t) async {
      await montar(
        t,
        OpcaoSelecionavel(
          rotulo: 'Tem alguém te ajudando agora?',
          selecionada: true,
          aoSelecionar: () {},
        ),
        reduzirMovimento: false,
      );

      expect(duracoesDe(t), contains(MemoraMovimento.rapido));
    });
  });

  test('toda animacao do aplicativo passa por MemoraMovimento.efetiva', () {
    // O portão contra o componente animado que ainda não existe.
    //
    // ⚠️ **A primeira versão disto varria a galeria montada, e não servia.**
    // A `ListView` da galeria é preguiçosa: só constrói o que está na dobra,
    // então os componentes animados nem apareciam na árvore. Um portão que
    // olha para uma árvore incompleta reprova nada — e teria passado a
    // impressão de cobrir tudo, que é pior que não existir.
    //
    // O código-fonte não tem dobra. Quem escrever `duration:` sem passar por
    // `MemoraMovimento.efetiva` reprova aqui, esteja o componente visível ou
    // não.
    final List<String> fora = <String>[];

    for (final FileSystemEntity arquivo
        in Directory('lib').listSync(recursive: true)) {
      if (arquivo is! File || !arquivo.path.endsWith('.dart')) continue;
      // O próprio token é quem define `efetiva` — ele não passa por si mesmo.
      if (arquivo.path.endsWith('movimento.dart')) continue;

      final List<String> linhas = arquivo.readAsLinesSync();
      for (int i = 0; i < linhas.length; i++) {
        final String linha = linhas[i].split('//').first;
        if (!linha.contains('duration:')) continue;

        // A chamada costuma quebrar em várias linhas; olha a linha e a
        // seguinte, que é onde `efetiva(` aparece no estilo daqui.
        final String trecho =
            linha + (i + 1 < linhas.length ? linhas[i + 1] : '');
        if (!trecho.contains('MemoraMovimento.efetiva')) {
          fora.add('${arquivo.path}:${i + 1}: ${linhas[i].trim()}');
        }
      }
    }

    expect(
      fora,
      isEmpty,
      reason: 'animacao que nao passa por MemoraMovimento.efetiva ignora '
          '"reduzir movimento" do sistema (FR-027). Use '
          '`MemoraMovimento.efetiva(<token>, reduzirMovimento: '
          'MediaQuery.disableAnimationsOf(context))`.',
    );
  });

  testWidgets('o que o giro comunica, o texto também comunica (FR-028)',
      (WidgetTester t) async {
    // A segunda metade do V9. O `CircularProgressIndicator` do Material gira
    // independentemente da preferência — não é nosso para desligar. O que
    // está ao nosso alcance é garantir que ele não seja o ÚNICO portador da
    // informação: quem não percebe o movimento continua sabendo que a Memora
    // está pensando, porque está escrito e anunciado.
    final SemanticsHandle h = t.ensureSemantics();
    await montar(
      t,
      const Carregando(mensagem: 'Estou pensando...'),
      reduzirMovimento: true,
    );

    expect(find.text('Estou pensando...'), findsOneWidget);
    expect(
      t.getSemantics(find.byType(Carregando)),
      isSemantics(label: 'Estou pensando...'),
    );
    h.dispose();
  });
}
