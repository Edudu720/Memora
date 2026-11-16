import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_boas_vindas.dart';
import 'package:memora/main.dart';
import 'package:memora/services/ambiente/ambiente.dart';
import 'package:memora/services/ambiente/composicao.dart';
import 'package:memora/services/seguranca/limpeza_de_sessao.dart';

import '../features/autenticacao/dubles_autenticacao.dart';
import '../features/autenticacao/fluxo_dentro_da_conta.dart';
import '../suporte/aceite_em_memoria.dart';
import 'package:memora/services/seguranca/sessao_perdida.dart';

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

    testWidgets(
      'o botão suprime a escala ao pressionar (1.0) mas mantém o anel de foco externo',
      (WidgetTester t) async {
        await montar(
          t,
          BotaoPrimario(rotulo: 'Continuar', aoTocar: () {}),
          reduzirMovimento: true,
        );

        await t.sendKeyEvent(LogicalKeyboardKey.tab);
        await t.pump();

        final AnimatedContainer superficie = t.widget<AnimatedContainer>(
          find.descendant(
            of: find.byType(BotaoPrimario),
            matching: find.byType(AnimatedContainer),
          ),
        );
        final BoxDecoration anel =
            superficie.foregroundDecoration! as BoxDecoration;
        expect((anel.border! as Border).top.width, MemoraDimensoes.bordaSelecao);

        final TestGesture gesto = await t.startGesture(
          t.getCenter(find.byType(BotaoPrimario)),
        );
        await t.pump(kPressTimeout);

        final AnimatedScale escala = t.widget<AnimatedScale>(
          find.descendant(
            of: find.byType(BotaoPrimario),
            matching: find.byType(AnimatedScale),
          ),
        );
        expect(escala.scale, 1.0);
        expect(escala.duration, Duration.zero);

        await gesto.up();
        await t.pump();
      },
    );

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
        // `duration:` dos widgets e a duração das rotas (`transitionDuration` e
        // `reverseTransitionDuration`, feature 013): uma rota que dura o que
        // quiser ignora "reduzir movimento" do mesmo jeito. Na rota só se
        // olha quem **escreve** uma duração (`Duration(...)` ou um token):
        // `Duration.zero` (troca sem animação) e uma variável já calculada
        // com `efetiva` não precisam passar por ela de novo.
        final String adiante =
            linha + (i + 1 < linhas.length ? linhas[i + 1] : '');
        final bool ehDuracaoDeRota =
            RegExp(r'ransitionDuration').hasMatch(linha) &&
            RegExp(r'Duration\(|MemoraMovimento\.').hasMatch(adiante);
        if (!linha.contains('duration:') && !ehDuracaoDeRota) continue;

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

  group('A preferência "reduzir movimento" do aplicativo — FR-039a, T093', () {
    // O que o aplicativo faz com a escolha da pessoa: ela chega ao MediaQuery
    // que todo componente nosso consulta (`disableAnimationsOf`), e soma-se à
    // do sistema — nunca a desfaz.
    Future<bool> reduzSob(
      WidgetTester t, {
      required bool sistema,
      required bool aplicativo,
    }) async {
      late bool reduz;
      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: sistema),
            child: AmpliacaoDeTexto(
              fatorDoAplicativo: 1,
              reduzirMovimento: aplicativo,
              child: Builder(
                builder: (BuildContext context) {
                  reduz = MediaQuery.disableAnimationsOf(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );
      return reduz;
    }

    testWidgets('ligada no aplicativo, o MediaQuery manda reduzir', (
      WidgetTester t,
    ) async {
      expect(await reduzSob(t, sistema: false, aplicativo: true), isTrue);
    });

    testWidgets('desligada, só a configuração do sistema vale', (
      WidgetTester t,
    ) async {
      expect(await reduzSob(t, sistema: false, aplicativo: false), isFalse);
      expect(
        await reduzSob(t, sistema: true, aplicativo: false),
        isTrue,
        reason: 'quem pediu menos movimento ao celular não o perde por ter '
            'deixado a opção do Memora desligada',
      );
    });

    testWidgets('ligada nos dois, continua reduzindo', (WidgetTester t) async {
      expect(await reduzSob(t, sistema: true, aplicativo: true), isTrue);
    });

    testWidgets('um componente nosso para de animar quando a pessoa liga a '
        'opção, sem o sistema pedir', (WidgetTester t) async {
      Future<List<Duration>> duracoes({required bool reduzir}) async {
        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: AmpliacaoDeTexto(
              fatorDoAplicativo: 1,
              reduzirMovimento: reduzir,
              child: Scaffold(
                body: BotaoPrimario(rotulo: 'Continuar', aoTocar: () {}),
              ),
            ),
          ),
        );
        return duracoesDe(t);
      }

      expect(await duracoes(reduzir: false), contains(MemoraMovimento.rapido));
      final List<Duration> reduzido = await duracoes(reduzir: true);
      expect(reduzido, isNotEmpty);
      expect(reduzido, everyElement(Duration.zero));
    });

    testWidgets('no aplicativo de verdade (main.dart), a preferência chega '
        'a todas as telas — e a pré-visualização vale na hora', (
      WidgetTester t,
    ) async {
      final UltimoAcessoEmMemoria ultimoAcesso = UltimoAcessoEmMemoria();
      final ControladorAparencia aparencia = ControladorAparencia(
        PreferenciaEmMemoria(),
      );
      await t.pumpWidget(
        AplicativoMemora(
          controlador: aparencia,
          ultimoAcesso: ultimoAcesso,
          composicao: Composicao(
            aceiteDoAviso: AceiteEmMemoria(),
            sessaoPerdida: SessaoPerdida(),
            ambiente: const Ambiente(urlBase: '', usaServidorReal: false),
            autenticacao: RepositorioAutenticacaoSimulado(
              demora: Duration.zero,
            ),
            assistente: RepositorioAssistenteSimulado(demora: Duration.zero),
            limpeza: LimpezaDeSessao(
              cofre: CofreQueRegistra(),
              ultimoAcesso: ultimoAcesso,
            ),
          ),
        ),
      );
      await t.pump();

      bool reduz() => MediaQuery.disableAnimationsOf(
        t.element(find.byType(TelaBoasVindas)),
      );
      expect(reduz(), isFalse);

      aparencia.preVisualizarReducaoDeMovimento(reduzir: true);
      await t.pump();
      expect(
        reduz(),
        isTrue,
        reason: 'o builder do MaterialApp não aplica a preferência',
      );

      aparencia.descartar();
      await t.pump();
      expect(reduz(), isFalse);
    });
  });
}
