import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

Widget _comTema(Widget filho) {
  return MaterialApp(
    theme: TemasMemora.claro,
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(MemoraEspacamento.lg),
          child: filho,
        ),
      ),
    ),
  );
}

Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

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

  group('ConfirmacaoMemora — corrige os botões SIM/NÃO do protótipo', () {
    testWidgets('empilha na vertical, não lado a lado',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _comTema(
          ConfirmacaoMemora(
            pergunta: 'Quer que eu abra o Instagram para você?',
            rotuloConfirmar: 'Sim, pode abrir',
            rotuloRecusar: 'Agora não',
            aoConfirmar: () {},
            aoRecusar: () {},
          ),
        ),
      );

      final Offset confirmar = tester.getCenter(find.byType(BotaoPrimario));
      final Offset recusar = tester.getCenter(find.byType(BotaoSecundario));

      expect(confirmar.dx, recusar.dx,
          reason: 'Mesma coluna: a escolha não pode depender de acertar o '
              'lado certo, que é onde o toque acidental acontecia.');
      expect(recusar.dy, greaterThan(confirmar.dy));
    });

    testWidgets('cada opção tem ao menos 56 dp de altura',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _comTema(
          ConfirmacaoMemora(
            pergunta: 'Posso enviar a mensagem?',
            rotuloConfirmar: 'Sim, pode enviar',
            rotuloRecusar: 'Agora não',
            aoConfirmar: () {},
            aoRecusar: () {},
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(BotaoPrimario)).height,
        greaterThanOrEqualTo(MemoraDimensoes.alvoDecisao),
        reason: 'Os botões do protótipo tinham 24 px — metade do exigido.',
      );
      expect(
        tester.getSize(find.byType(BotaoSecundario)).height,
        greaterThanOrEqualTo(MemoraDimensoes.alvoDecisao),
      );
    });

    testWidgets('confirmação comum executa no primeiro toque',
        (WidgetTester tester) async {
      int confirmou = 0;
      await tester.pumpWidget(
        _comTema(
          ConfirmacaoMemora(
            pergunta: 'Posso abrir?',
            rotuloConfirmar: 'Sim, pode abrir',
            rotuloRecusar: 'Agora não',
            aoConfirmar: () => confirmou++,
            aoRecusar: () {},
          ),
        ),
      );

      await _tocar(tester, find.text('Sim, pode abrir'));
      expect(confirmou, 1);
    });

    testWidgets('ação irreversível exige DUAS confirmações',
        (WidgetTester tester) async {
      int apagou = 0;
      await tester.pumpWidget(
        _comTema(
          ConfirmacaoMemora.irreversivel(
            pergunta: 'Quer apagar todas as suas fotos?',
            aviso: 'Depois de apagar, não dá para trazer de volta.',
            rotuloConfirmar: 'Sim, quero apagar',
            rotuloRecusar: 'Não, deixa como está',
            aoConfirmar: () => apagou++,
            aoRecusar: () {},
          ),
        ),
      );

      await _tocar(tester, find.text('Sim, quero apagar'));
      expect(apagou, 0, reason: 'O primeiro toque não pode executar.');
      expect(find.text('Tem certeza mesmo?'), findsOneWidget);

      await _tocar(tester, find.text('Sim, pode apagar'));
      expect(apagou, 1);
    });

    testWidgets('é possível desistir entre as duas confirmações',
        (WidgetTester tester) async {
      int apagou = 0;
      await tester.pumpWidget(
        _comTema(
          ConfirmacaoMemora.irreversivel(
            pergunta: 'Quer apagar sua conta?',
            aviso: 'Não dá para desfazer.',
            rotuloConfirmar: 'Sim, quero apagar',
            rotuloRecusar: 'Não, deixa como está',
            aoConfirmar: () => apagou++,
            aoRecusar: () {},
          ),
        ),
      );

      await _tocar(tester, find.text('Sim, quero apagar'));
      await _tocar(tester, find.text('Não, deixa como está'));

      expect(apagou, 0);
      expect(find.text('Quer apagar sua conta?'), findsOneWidget);
    });

    testWidgets('na variante irreversível a recusa vem antes da ação',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _comTema(
          ConfirmacaoMemora.irreversivel(
            pergunta: 'Apagar?',
            aviso: 'Não dá para desfazer.',
            rotuloConfirmar: 'Sim, quero apagar',
            rotuloRecusar: 'Não, deixa como está',
            aoConfirmar: () {},
            aoRecusar: () {},
          ),
        ),
      );

      final double recusa = tester.getCenter(find.byType(BotaoSecundario)).dy;
      final double perigo = tester.getCenter(find.byType(BotaoPerigo)).dy;

      expect(recusa, lessThan(perigo),
          reason: 'O caminho seguro é lido primeiro e fica mais acessível.');
      expect(perigo - recusa, greaterThanOrEqualTo(MemoraEspacamento.xxxl),
          reason: 'Ação destrutiva precisa ficar isolada da comum (FR-013).');
    });
  });

  group('Campos de entrada', () {
    testWidgets('CampoTexto mantém o rótulo visível ao digitar',
        (WidgetTester tester) async {
      final TextEditingController c = TextEditingController();
      await tester.pumpWidget(
        _comTema(
          CampoTexto(
            rotulo: 'Seu e-mail',
            textoAjuda: 'Usamos para você entrar e recuperar a senha',
            controlador: c,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'ana@email.com');
      await tester.pumpAndSettle();

      expect(find.text('Seu e-mail'), findsOneWidget,
          reason: 'Rótulo que some ao digitar obriga a pessoa a lembrar o que '
              'estava preenchendo.');
      expect(
        find.text('Usamos para você entrar e recuperar a senha'),
        findsOneWidget,
      );
    });

    testWidgets('erro é comunicado por ícone E texto',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _comTema(
          const CampoTexto(
            rotulo: 'Seu e-mail',
            textoAjuda: 'Para entrar no Memora',
            erro: 'Não consegui entender esse e-mail. Pode conferir?',
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(
        find.text('Não consegui entender esse e-mail. Pode conferir?'),
        findsOneWidget,
      );
    });

    testWidgets('CampoSenha revela com rótulo escrito, não só ícone',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _comTema(
          const CampoSenha(
            rotulo: 'Crie sua senha',
            textoAjuda: 'Use uma frase que só você lembre',
          ),
        ),
      );

      expect(find.text('Mostrar senha'), findsOneWidget);
      await _tocar(tester, find.text('Mostrar senha'));
      expect(find.text('Esconder senha'), findsOneWidget);
    });

    testWidgets('no modo assistido a senha não pode ser revelada',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _comTema(
          const CampoSenha(
            rotulo: 'Crie sua senha',
            textoAjuda: 'Só você precisa saber',
            permitirRevelar: false,
          ),
        ),
      );

      expect(find.text('Mostrar senha'), findsNothing,
          reason: 'Com o acompanhante ao lado, revelar a senha entregaria a '
              'ele o segredo que o modo assistido existe para proteger '
              '(FR-060 da feature 001).');

      final TextField campo = tester.widget<TextField>(find.byType(TextField));
      expect(campo.obscureText, isTrue);
    });

    testWidgets('CampoCodigo aceita apenas dígitos, no máximo 6',
        (WidgetTester tester) async {
      final TextEditingController c = TextEditingController();
      await tester.pumpWidget(
        _comTema(CampoCodigo(rotulo: 'Código', controlador: c)),
      );

      await tester.enterText(find.byType(TextField), 'a1b2c3d4e5');
      await tester.pumpAndSettle();

      expect(c.text, '12345');
      await tester.enterText(find.byType(TextField), '1234567890');
      await tester.pumpAndSettle();
      expect(c.text.length, CampoCodigo.digitos);
    });
  });

  group('Navegação — ícone nunca sozinho (FR-016)', () {
    testWidgets('todo item da navegação inferior tem rótulo escrito',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _comTema(
          NavegacaoInferior(
            indiceAtivo: 1,
            aoSelecionar: (_) {},
            itens: const <ItemNavegacao>[
              ItemNavegacao(icone: Icons.settings, rotulo: 'Ajustes'),
              ItemNavegacao(icone: Icons.home, rotulo: 'Início'),
              ItemNavegacao(icone: Icons.person, rotulo: 'Meu perfil'),
            ],
          ),
        ),
      );

      expect(find.text('Ajustes'), findsOneWidget);
      expect(find.text('Início'), findsOneWidget);
      expect(find.text('Meu perfil'), findsOneWidget);
    });

    testWidgets('barra superior escreve a palavra Voltar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: Scaffold(
            appBar: BarraSuperior(titulo: 'Ajuda', aoVoltar: () {}),
            body: const SizedBox.shrink(),
          ),
        ),
      );

      expect(find.text('Voltar'), findsOneWidget,
          reason: 'Seta isolada é ambígua para quem tem pouca familiaridade.');
    });
  });

  group('Retorno ao usuário', () {
    testWidgets('carregando sempre traz texto junto',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _comTema(const Carregando(mensagem: 'Estou entrando na sua conta...')),
      );

      expect(find.text('Estou entrando na sua conta...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('erro é anunciado como região viva ao leitor de tela',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _comTema(
          const MensagemErro(mensagem: 'Não consegui conectar à internet.'),
        ),
      );

      expect(
        tester.getSemantics(find.byType(MensagemErro)),
        isSemantics(isLiveRegion: true),
        reason: 'Sem região viva, quem usa leitor de tela não fica sabendo que '
            'algo mudou na tela.',
      );
      handle.dispose();
    });

    testWidgets('estado vazio explica e oferece caminho',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _comTema(
          EstadoVazio(
            titulo: 'Nenhuma conversa ainda',
            explicacao: 'Quando você falar comigo, tudo fica guardado aqui.',
            rotuloAcao: 'Falar com a Memora',
            aoAgir: () {},
          ),
        ),
      );

      expect(find.text('Nenhuma conversa ainda'), findsOneWidget);
      expect(find.text('Falar com a Memora'), findsOneWidget);
    });
  });

  group('Acessibilidade da fase', () {
    testWidgets('confirmação atende à diretriz de alvo de toque',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _comTema(
          ConfirmacaoMemora(
            pergunta: 'Posso abrir?',
            rotuloConfirmar: 'Sim, pode abrir',
            rotuloRecusar: 'Agora não',
            aoConfirmar: () {},
            aoRecusar: () {},
          ),
        ),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('componentes da fase sobrevivem à ampliação máxima',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(MemoraDimensoes.escalaTextoMax),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    ConfirmacaoMemora(
                      pergunta: 'Quer que eu abra o Instagram para você?',
                      rotuloConfirmar: 'Sim, pode abrir',
                      rotuloRecusar: 'Agora não',
                      aoConfirmar: () {},
                      aoRecusar: () {},
                    ),
                    const CampoTexto(
                      rotulo: 'Seu e-mail',
                      textoAjuda: 'Para entrar e recuperar a senha',
                    ),
                    const MensagemErro(mensagem: 'Não consegui conectar.'),
                  ],
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
