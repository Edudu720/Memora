import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/apresentacao/data/apresentacao_vista.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_login.dart';
import 'package:memora/features/casca/casca_interna.dart';
import 'package:memora/features/configuracoes/presentation/tela_configuracoes.dart';
import 'package:memora/features/configuracoes/presentation/tela_conta.dart';
import 'package:memora/features/configuracoes/presentation/tela_privacidade.dart';
import 'package:memora/features/inicio/presentation/tela_inicio.dart';
import 'package:memora/features/perfil/data/data_de_nascimento_local.dart';
import 'package:memora/features/perfil/domain/data_de_nascimento.dart';
import 'package:memora/l10n/textos_apresentacao.dart';
import 'package:memora/l10n/textos_autenticacao.dart';
import 'package:memora/l10n/textos_configuracoes.dart';

import '../../suporte/aparelhos.dart';
import '../../suporte/estados_de_tela.dart';
import '../autenticacao/fluxo_dentro_da_conta.dart';

/// Configurações — a US7 da feature 004 (T091, T092, T094, T095).
///
/// Cobre os quatro grupos de Ajustes (FR-038), Privacidade (FR-040) e Conta
/// (FR-041, FR-036a) — as telas isoladas, na matriz de aparelhos, e **pelo
/// fluxo de verdade**, que é onde a FR-025 e a FR-026 já ficaram furadas uma
/// vez porque o portão testava uma tela que o aplicativo não mostrava.
void main() {
  /// Um toque de verdade, depois de rolar até o alvo. Sem `pumpAndSettle`: o
  /// `Carregando` anima sem parar.
  Future<void> tocar(WidgetTester t, Finder alvo) async {
    await t.ensureVisible(alvo);
    await t.pump();
    await t.tap(alvo);
    await t.pump(const Duration(milliseconds: 50));
    await t.pump(const Duration(milliseconds: 400));
  }

  Widget app(Widget filho) =>
      MaterialApp(theme: TemasMemora.claro, home: filho);

  final Finder fraseDeTerCerteza = find.text('Tem certeza mesmo?');
  final Finder simPodeApagar = find.text('Sim, pode apagar');

  // ===========================================================================
  // Ajustes — as quatro portas
  // ===========================================================================
  group('Ajustes tem os quatro grupos, e só eles — FR-038', () {
    Widget ajustes({VoidCallback? galeria, List<String>? abertas}) =>
        TelaConfiguracoes(
          aoAbrirAparencia: () => abertas?.add('aparencia'),
          aoAbrirAcessibilidade: () => abertas?.add('acessibilidade'),
          aoAbrirPrivacidade: () => abertas?.add('privacidade'),
          aoAbrirConta: () => abertas?.add('conta'),
          aoAbrirGaleria: galeria,
        );

    testWidgets('Aparência, Acessibilidade, Privacidade e Conta abrem', (
      WidgetTester t,
    ) async {
      final List<String> abertas = <String>[];
      await t.pumpWidget(app(ajustes(abertas: abertas)));

      for (final Key porta in <Key>[
        TelaConfiguracoes.chaveAparencia,
        TelaConfiguracoes.chaveAcessibilidade,
        TelaConfiguracoes.chavePrivacidade,
        TelaConfiguracoes.chaveConta,
      ]) {
        await tocar(t, find.byKey(porta));
      }

      expect(abertas, <String>[
        'aparencia',
        'acessibilidade',
        'privacidade',
        'conta',
      ]);
      expect(find.byType(CartaoDePorta), findsNWidgets(4));
    });

    testWidgets('não há "Notificações" nem "Idiomas": só aparecem quando '
        'existirem', (WidgetTester t) async {
      await t.pumpWidget(app(ajustes()));

      expect(find.textContaining('Notificações'), findsNothing);
      expect(find.textContaining('Idiomas'), findsNothing);
      expect(find.textContaining('Idioma'), findsNothing);
    });

    testWidgets('a saída não é uma porta de Ajustes: mora em Conta', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(ajustes()));

      expect(
        find.text(TextosAutenticacao.botaoSair),
        findsNothing,
        reason: 'FR-019: um toque errado na lista não pode custar a sessão',
      );
      expect(find.byType(BotaoSecundario), findsNothing);
      expect(find.byType(BotaoPerigo), findsNothing);
    });

    testWidgets('sem galeria disponível, não há linha que leve a ela', (
      WidgetTester t,
    ) async {
      // Fora do `kDebugMode`, `GaleriaMemora.paraDesenvolvimento()` devolve
      // nulo (R9 da 002) e quem monta Ajustes o passa adiante: nulo é nenhuma
      // linha — e não uma linha que leva a uma recusa.
      await t.pumpWidget(app(ajustes()));

      expect(find.byKey(TelaConfiguracoes.chaveGaleria), findsNothing);
      expect(find.text(TextosConfiguracoes.galeria), findsNothing);
    });

    testWidgets('com galeria disponível, a linha existe e abre', (
      WidgetTester t,
    ) async {
      int abriu = 0;
      await t.pumpWidget(app(ajustes(galeria: () => abriu++)));

      await tocar(t, find.byKey(TelaConfiguracoes.chaveGaleria));

      expect(abriu, 1);
    });

    testWidgets('nenhuma porta é "principal": é uma lista, e não um '
        'caminho só (FR-002)', (WidgetTester t) async {
      await t.pumpWidget(app(ajustes()));

      final Iterable<CartaoDePorta> portas = t.widgetList<CartaoDePorta>(
        find.byType(CartaoDePorta),
      );
      expect(portas.where((CartaoDePorta p) => p.principal), isEmpty);
    });
  });

  // ===========================================================================
  // Privacidade
  // ===========================================================================
  group('Privacidade diz o que fica guardado — FR-040', () {
    Widget privacidade({Future<void> Function()? aoApagar}) => TelaPrivacidade(
      aoApagarConversa: aoApagar ?? () async {},
      aoVoltar: () {},
    );

    testWidgets('diz, em linguagem comum, as quatro coisas guardadas', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(privacidade()));

      for (final String rotulo in <String>[
        TextosConfiguracoes.guardadoConversa,
        TextosConfiguracoes.guardadoIdade,
        TextosConfiguracoes.guardadoApresentacao,
        TextosConfiguracoes.guardadoContato,
      ]) {
        expect(find.text(rotulo), findsOneWidget, reason: rotulo);
      }
      expect(find.text(TextosConfiguracoes.guardadoNuncaFica), findsOneWidget);
    });

    testWidgets('é informação: só o botão de apagar aceita toque', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(privacidade()));

      // A lista do que fica guardado não tem botão nenhum (FR-012 da 002).
      expect(
        find.descendant(
          of: find.byType(ListaInformacao),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
      expect(find.byType(BotaoSecundario), findsOneWidget);
    });
  });

  group(
    'Apagar a conversa exige as duas etapas da confirmação irreversível',
    () {
      testWidgets('um toque só não apaga nada: ele só faz a pergunta', (
        WidgetTester t,
      ) async {
        int apagou = 0;
        await t.pumpWidget(
          app(
            TelaPrivacidade(
              aoApagarConversa: () async => apagou++,
              aoVoltar: () {},
            ),
          ),
        );

        await tocar(t, find.byKey(TelaPrivacidade.chaveApagar));

        expect(find.byKey(TelaPrivacidade.chaveConfirmacao), findsOneWidget);
        expect(apagou, 0, reason: 'o primeiro toque não pode apagar');
      });

      testWidgets('o primeiro toque na confirmação ainda não apaga: pede '
          '"Tem certeza mesmo?"', (WidgetTester t) async {
        int apagou = 0;
        await t.pumpWidget(
          app(
            TelaPrivacidade(
              aoApagarConversa: () async => apagou++,
              aoVoltar: () {},
            ),
          ),
        );
        await tocar(t, find.byKey(TelaPrivacidade.chaveApagar));

        await tocar(
          t,
          find.descendant(
            of: find.byKey(TelaPrivacidade.chaveConfirmacao),
            matching: find.text(TextosConfiguracoes.botaoApagarConversa),
          ),
        );

        expect(
          fraseDeTerCerteza,
          findsOneWidget,
          reason: 'FR-040: a segunda etapa da confirmação irreversível',
        );
        expect(apagou, 0, reason: 'duas etapas: o primeiro toque não apaga');
      });

      testWidgets('só o segundo toque apaga, e a tela avisa', (
        WidgetTester t,
      ) async {
        int apagou = 0;
        await t.pumpWidget(
          app(
            TelaPrivacidade(
              aoApagarConversa: () async => apagou++,
              aoVoltar: () {},
            ),
          ),
        );
        await tocar(t, find.byKey(TelaPrivacidade.chaveApagar));
        await tocar(
          t,
          find.descendant(
            of: find.byKey(TelaPrivacidade.chaveConfirmacao),
            matching: find.text(TextosConfiguracoes.botaoApagarConversa),
          ),
        );

        await tocar(t, simPodeApagar);

        expect(apagou, 1);
        expect(find.byKey(TelaPrivacidade.chaveApagada), findsOneWidget);
        expect(find.text(TextosConfiguracoes.conversaApagada), findsOneWidget);
      });

      testWidgets('o botão de apagar não fica ao lado do de recusar, em '
          'nenhuma das duas etapas', (WidgetTester t) async {
        await t.pumpWidget(
          app(TelaPrivacidade(aoApagarConversa: () async {}, aoVoltar: () {})),
        );
        await tocar(t, find.byKey(TelaPrivacidade.chaveApagar));

        Future<void> exigirLonge(String etapa) async {
          final Finder confirmacao = find.byKey(
            TelaPrivacidade.chaveConfirmacao,
          );
          final Rect recusar = t.getRect(
            find.descendant(
              of: confirmacao,
              matching: find.byType(BotaoSecundario),
            ),
          );
          final Rect apagar = t.getRect(
            find.descendant(
              of: confirmacao,
              matching: find.byType(BotaoPerigo),
            ),
          );
          expect(
            apagar.top - recusar.bottom,
            greaterThanOrEqualTo(MemoraEspacamento.xxxl),
            reason: '$etapa: o botão de apagar ficou perto do de recusar',
          );
        }

        await exigirLonge('primeira etapa');
        await tocar(
          t,
          find.descendant(
            of: find.byKey(TelaPrivacidade.chaveConfirmacao),
            matching: find.text(TextosConfiguracoes.botaoApagarConversa),
          ),
        );
        await exigirLonge('segunda etapa');
      });

      testWidgets('recusar na primeira etapa volta ao botão e não apaga', (
        WidgetTester t,
      ) async {
        int apagou = 0;
        await t.pumpWidget(
          app(
            TelaPrivacidade(
              aoApagarConversa: () async => apagou++,
              aoVoltar: () {},
            ),
          ),
        );
        await tocar(t, find.byKey(TelaPrivacidade.chaveApagar));

        await tocar(t, find.text(TextosConfiguracoes.botaoManterConversa));

        expect(find.byKey(TelaPrivacidade.chaveApagar), findsOneWidget);
        expect(find.byKey(TelaPrivacidade.chaveConfirmacao), findsNothing);
        expect(apagou, 0);
      });

      testWidgets('recusar na segunda etapa volta à primeira, e não apaga', (
        WidgetTester t,
      ) async {
        int apagou = 0;
        await t.pumpWidget(
          app(
            TelaPrivacidade(
              aoApagarConversa: () async => apagou++,
              aoVoltar: () {},
            ),
          ),
        );
        await tocar(t, find.byKey(TelaPrivacidade.chaveApagar));
        await tocar(
          t,
          find.descendant(
            of: find.byKey(TelaPrivacidade.chaveConfirmacao),
            matching: find.text(TextosConfiguracoes.botaoApagarConversa),
          ),
        );

        await tocar(t, find.text('Não, deixa como está'));

        expect(fraseDeTerCerteza, findsNothing);
        expect(
          find.text(TextosConfiguracoes.perguntaApagarConversa),
          findsOneWidget,
        );
        expect(apagou, 0);
      });

      testWidgets('se apagar falha, a tela diz que NÃO apagou', (
        WidgetTester t,
      ) async {
        await t.pumpWidget(
          app(
            TelaPrivacidade(
              aoApagarConversa: () async => throw StateError('disco cheio'),
              aoVoltar: () {},
            ),
          ),
        );
        await tocar(t, find.byKey(TelaPrivacidade.chaveApagar));
        await tocar(
          t,
          find.descendant(
            of: find.byKey(TelaPrivacidade.chaveConfirmacao),
            matching: find.text(TextosConfiguracoes.botaoApagarConversa),
          ),
        );
        await tocar(t, simPodeApagar);

        expect(find.byKey(TelaPrivacidade.chaveFalha), findsOneWidget);
        expect(find.byKey(TelaPrivacidade.chaveApagada), findsNothing);
        expect(find.text(TextosConfiguracoes.conversaApagada), findsNothing);
      });
    },
  );

  // ===========================================================================
  // Conta
  // ===========================================================================
  group('Conta — FR-041 e FR-036a', () {
    Widget conta({
      Future<String?>? canal,
      Future<void> Function()? aoSair,
      Future<void> Function()? aoEsquecer,
    }) => TelaConta(
      canal: canal ?? Future<String?>.value('ana@email.com'),
      aoSair: aoSair ?? () async {},
      aoSairEEsquecer: aoEsquecer ?? () async {},
      aoVoltar: () {},
    );

    testWidgets('mostra o canal da conta, como informação', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(conta()));
      await t.pump();

      expect(find.byKey(TelaConta.chaveContato), findsOneWidget);
      expect(find.text('ana@email.com'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(TelaConta.chaveContato),
          matching: find.byType(InkWell),
        ),
        findsNothing,
        reason: 'o canal é informação, e não botão (FR-012 da 002)',
      );
    });

    testWidgets('diz o que ninguém do Memora faz, nas quatro frases '
        '(FR-036a)', (WidgetTester t) async {
      await t.pumpWidget(app(conta()));
      await t.pump();

      for (final String frase in TextosApresentacao.nuncaFaco) {
        expect(
          find.descendant(
            of: find.byKey(TelaConta.chaveNuncaFaco),
            matching: find.text(frase),
          ),
          findsOneWidget,
          reason: 'a Conta perdeu uma frase da FR-036a: $frase',
        );
      }
      expect(find.text(TextosApresentacao.seAlguemPedir), findsOneWidget);
    });

    testWidgets('a FR-036a diz o que a spec manda, e não só o que o texto '
        'de hoje diz', (WidgetTester t) async {
      // Ancoras LITERAIS: se alguém trocar a frase compartilhada por uma que
      // perde o "por telefone, mensagem ou e-mail" (que torna a frase
      // verdadeira, porque o Memora pede a senha no login), a Conta reprova.
      await t.pumpWidget(app(conta()));
      await t.pump();

      for (final String ancora in <String>[
        'por telefone, mensagem ou e-mail',
        'liga para você',
        'fora da loja oficial',
        'cobro',
      ]) {
        expect(
          find.descendant(
            of: find.byKey(TelaConta.chaveNuncaFaco),
            matching: find.textContaining(ancora),
          ),
          findsOneWidget,
          reason: 'a Conta não diz mais "$ancora" (FR-036a)',
        );
      }
    });

    testWidgets('"Sair" pergunta antes, e não sai com um toque', (
      WidgetTester t,
    ) async {
      int saiu = 0;
      await t.pumpWidget(app(conta(aoSair: () async => saiu++)));
      await t.pump();

      await tocar(t, find.byKey(TelaConta.chaveSair));

      expect(find.byKey(TelaConta.chaveConfirmacao), findsOneWidget);
      expect(saiu, 0);
    });

    testWidgets('"Sair e esquecer este aparelho" fica separado e abaixo '
        'do "Sair", com a frase de para que serve', (WidgetTester t) async {
      await t.pumpWidget(app(conta()));
      await t.pump();

      final Rect sair = t.getRect(find.byKey(TelaConta.chaveSair));
      final Rect esquecer = t.getRect(find.byKey(TelaConta.chaveEsquecer));
      final Rect frase = t.getRect(
        find.text(TextosConfiguracoes.paraQueServeEsquecer),
      );

      expect(
        esquecer.top - sair.bottom,
        greaterThanOrEqualTo(MemoraEspacamento.xxxl),
        reason: 'FR-041: a mais destrutiva não fica adjacente à comum',
      );
      // O que separa os dois é espaço de verdade, e não só o título e a frase
      // que ficam no meio: o título da segunda parte começa longe do "Sair".
      final Rect titulo = t.getRect(
        find.text(TextosConfiguracoes.tituloEsquecer),
      );
      expect(
        titulo.top - sair.bottom,
        greaterThanOrEqualTo(MemoraEspacamento.xxxl),
        reason: 'FR-041: a segunda parte começa colada ao "Sair"',
      );
      expect(frase.top, greaterThan(sair.bottom));
      expect(
        frase.bottom,
        lessThanOrEqualTo(esquecer.top),
        reason: 'a frase de para que serve vem antes do botão que ela explica',
      );
      expect(
        find.textContaining('vendido'),
        findsOneWidget,
        reason:
            'a frase diz para quem serve: aparelho compartilhado ou '
            'que vai ser vendido',
      );
    });

    testWidgets('"Sair e esquecer" também pede as duas etapas', (
      WidgetTester t,
    ) async {
      int esqueceu = 0;
      await t.pumpWidget(app(conta(aoEsquecer: () async => esqueceu++)));
      await t.pump();

      await tocar(t, find.byKey(TelaConta.chaveEsquecer));
      expect(find.byKey(TelaConta.chaveConfirmacaoEsquecer), findsOneWidget);
      expect(esqueceu, 0);

      await tocar(
        t,
        find.descendant(
          of: find.byKey(TelaConta.chaveConfirmacaoEsquecer),
          matching: find.byType(BotaoPerigo),
        ),
      );
      expect(fraseDeTerCerteza, findsOneWidget);
      expect(esqueceu, 0);

      await tocar(t, simPodeApagar);
      expect(esqueceu, 1);
    });

    testWidgets('uma saída por vez: esquecer depois de sair não roda duas '
        'vezes', (WidgetTester t) async {
      int saiu = 0;
      int esqueceu = 0;
      await t.pumpWidget(
        app(
          conta(aoSair: () async => saiu++, aoEsquecer: () async => esqueceu++),
        ),
      );
      await t.pump();

      await tocar(t, find.byKey(TelaConta.chaveSair));
      await tocar(t, find.text(TextosAutenticacao.botaoConfirmarSaida));
      expect(saiu, 1);

      await tocar(t, find.byKey(TelaConta.chaveEsquecer));
      await tocar(
        t,
        find.descendant(
          of: find.byKey(TelaConta.chaveConfirmacaoEsquecer),
          matching: find.byType(BotaoPerigo),
        ),
      );
      await tocar(t, simPodeApagar);

      expect(esqueceu, 0, reason: 'a primeira saída ainda não terminou');
    });
  });

  group('Os estados da Conta — FR-006', () {
    testWidgets('carregando, sem contato e erro têm frase e desenho', (
      WidgetTester t,
    ) async {
      await exigirOsEstadosDaFr006(
        t,
        tela: 'Conta',
        montar: (EstadoDaTela estado) => switch (estado) {
          EstadoDaTela.carregando => app(
            TelaConta(
              canal: Completer<String?>().future,
              aoSair: () async {},
              aoSairEEsquecer: () async {},
              aoVoltar: () {},
            ),
          ),
          EstadoDaTela.vazio => app(
            TelaConta(
              canal: Future<String?>.value(),
              aoSair: () async {},
              aoSairEEsquecer: () async {},
              aoVoltar: () {},
            ),
          ),
          EstadoDaTela.erro => app(
            TelaConta(
              canal: Future<String?>.error(StateError('sem leitura'))..ignore(),
              aoSair: () async {},
              aoSairEEsquecer: () async {},
              aoVoltar: () {},
            ),
          ),
        },
      );
    });

    testWidgets('mesmo sem contato, a FR-036a continua na tela', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(
        app(
          TelaConta(
            canal: Future<String?>.value(),
            aoSair: () async {},
            aoSairEEsquecer: () async {},
            aoVoltar: () {},
          ),
        ),
      );
      await t.pump();

      expect(find.text(TextosConfiguracoes.semContatoTitulo), findsOneWidget);
      expect(find.byKey(TelaConta.chaveNuncaFaco), findsOneWidget);
    });
  });

  // ===========================================================================
  // A matriz — FR-044
  // ===========================================================================
  group('Matriz — FR-044', () {
    for (final Combinacao c in matriz()) {
      testWidgets('Ajustes não estoura e as portas são alcançáveis em '
          '${nomeDa(c)}', (WidgetTester t) async {
        vestir(t, c.aparelho);
        final List<String> abertas = <String>[];
        await t.pumpWidget(
          naCombinacao(
            c,
            TelaConfiguracoes(
              aoAbrirAparencia: () => abertas.add('aparencia'),
              aoAbrirAcessibilidade: () => abertas.add('acessibilidade'),
              aoAbrirPrivacidade: () => abertas.add('privacidade'),
              aoAbrirConta: () => abertas.add('conta'),
            ),
          ),
        );
        expect(t.takeException(), isNull, reason: nomeDa(c));

        for (final Key porta in <Key>[
          TelaConfiguracoes.chaveAparencia,
          TelaConfiguracoes.chaveAcessibilidade,
          TelaConfiguracoes.chavePrivacidade,
          TelaConfiguracoes.chaveConta,
        ]) {
          await exigirAlcancavel(
            t,
            find.byKey(porta),
            aparelho: c.aparelho,
            contexto: '${nomeDa(c)} / $porta',
          );
          await t.tap(find.byKey(porta));
        }
        expect(abertas, hasLength(4), reason: nomeDa(c));
      });

      testWidgets('Privacidade não estoura e apagar é alcançável, nas '
          'duas etapas, em ${nomeDa(c)}', (WidgetTester t) async {
        vestir(t, c.aparelho);
        int apagou = 0;
        await t.pumpWidget(
          naCombinacao(
            c,
            TelaPrivacidade(
              aoApagarConversa: () async => apagou++,
              aoVoltar: () {},
            ),
          ),
        );
        expect(t.takeException(), isNull, reason: nomeDa(c));

        await exigirAlcancavel(
          t,
          find.byKey(TelaPrivacidade.chaveApagar),
          aparelho: c.aparelho,
          contexto: '${nomeDa(c)} / apagar',
        );
        await t.tap(find.byKey(TelaPrivacidade.chaveApagar));
        await t.pump();
        expect(t.takeException(), isNull, reason: '${nomeDa(c)}: 1ª etapa');

        final Finder perigo = find.descendant(
          of: find.byKey(TelaPrivacidade.chaveConfirmacao),
          matching: find.text(TextosConfiguracoes.botaoApagarConversa),
        );
        await exigirAlcancavel(
          t,
          perigo,
          aparelho: c.aparelho,
          contexto: '${nomeDa(c)} / apagar (1ª etapa)',
        );
        await t.tap(perigo);
        await t.pump();
        expect(t.takeException(), isNull, reason: '${nomeDa(c)}: 2ª etapa');

        await exigirAlcancavel(
          t,
          simPodeApagar,
          aparelho: c.aparelho,
          contexto: '${nomeDa(c)} / apagar (2ª etapa)',
        );
        await t.tap(simPodeApagar);
        await t.pump();
        expect(apagou, 1, reason: nomeDa(c));
      });

      testWidgets('Conta não estoura e as duas saídas são alcançáveis em '
          '${nomeDa(c)}', (WidgetTester t) async {
        vestir(t, c.aparelho);
        int saiu = 0;
        int esqueceu = 0;
        await t.pumpWidget(
          naCombinacao(
            c,
            TelaConta(
              canal: Future<String?>.value('ana@email.com'),
              aoSair: () async => saiu++,
              aoSairEEsquecer: () async => esqueceu++,
              aoVoltar: () {},
            ),
          ),
        );
        await t.pump();
        expect(t.takeException(), isNull, reason: nomeDa(c));

        await exigirAlcancavel(
          t,
          find.byKey(TelaConta.chaveSair),
          aparelho: c.aparelho,
          contexto: '${nomeDa(c)} / sair',
        );
        await exigirAlcancavel(
          t,
          find.byKey(TelaConta.chaveEsquecer),
          aparelho: c.aparelho,
          contexto: '${nomeDa(c)} / esquecer',
        );

        await t.ensureVisible(find.byKey(TelaConta.chaveSair));
        await t.pump();
        await t.tap(find.byKey(TelaConta.chaveSair));
        await t.pump();
        expect(t.takeException(), isNull, reason: '${nomeDa(c)}: sair');
        await exigirAlcancavel(
          t,
          find.text(TextosAutenticacao.botaoConfirmarSaida),
          aparelho: c.aparelho,
          contexto: '${nomeDa(c)} / confirmar a saída',
        );
        await t.tap(find.text(TextosAutenticacao.botaoConfirmarSaida));
        await t.pump();
        expect(saiu, 1, reason: nomeDa(c));
        expect(esqueceu, 0, reason: nomeDa(c));
      });

      testWidgets('Conta: a pergunta de esquecer o aparelho cabe e '
          'confirma em ${nomeDa(c)}', (WidgetTester t) async {
        vestir(t, c.aparelho);
        int esqueceu = 0;
        await t.pumpWidget(
          naCombinacao(
            c,
            TelaConta(
              canal: Future<String?>.value('ana@email.com'),
              aoSair: () async {},
              aoSairEEsquecer: () async => esqueceu++,
              aoVoltar: () {},
            ),
          ),
        );
        await t.pump();

        await t.ensureVisible(find.byKey(TelaConta.chaveEsquecer));
        await t.pump();
        await t.tap(find.byKey(TelaConta.chaveEsquecer));
        await t.pump();
        expect(t.takeException(), isNull, reason: '${nomeDa(c)}: 1ª etapa');

        final Finder perigo = find.descendant(
          of: find.byKey(TelaConta.chaveConfirmacaoEsquecer),
          matching: find.byType(BotaoPerigo),
        );
        await exigirAlcancavel(
          t,
          perigo,
          aparelho: c.aparelho,
          contexto: '${nomeDa(c)} / esquecer (1ª etapa)',
        );
        await t.tap(perigo);
        await t.pump();
        expect(t.takeException(), isNull, reason: '${nomeDa(c)}: 2ª etapa');
        await exigirAlcancavel(
          t,
          simPodeApagar,
          aparelho: c.aparelho,
          contexto: '${nomeDa(c)} / esquecer (2ª etapa)',
        );
        await t.tap(simPodeApagar);
        await t.pump();
        expect(esqueceu, 1, reason: nomeDa(c));
      });
    }
  });

  // ===========================================================================
  // Pelo fluxo de verdade
  // ===========================================================================
  group('Pelo fluxo de verdade', () {
    late FluxoDentroDaConta fluxo;
    late DataDeNascimentoEmMemoria datas;
    late ApresentacaoVistaEmMemoria vistas;

    final DataDeNascimento nascida = DataDeNascimento.validar(
      dia: '15',
      mes: '3',
      ano: '1952',
      hoje: DateTime(2026, 10),
    ).data!;

    setUp(() {
      fluxo = FluxoDentroDaConta();
      datas = DataDeNascimentoEmMemoria();
      vistas = ApresentacaoVistaEmMemoria();
    });

    Future<void> entrar(WidgetTester t) async {
      await datas.guardar(FluxoDentroDaConta.idDaAna, nascida);
      await fluxo.montar(t, datas: datas, vistas: vistas);
      expect(
        await vistas.jaViu(FluxoDentroDaConta.idDaAna),
        isTrue,
        reason: 'o cenário pressupõe a apresentação já vista por esta conta',
      );
      expect(await datas.ler(FluxoDentroDaConta.idDaAna), isNotNull);
      expect(await fluxo.ultimoAcesso.identificador(), 'ana@email.com');
    }

    Future<void> confirmarEsquecer(WidgetTester t) async {
      await FluxoDentroDaConta.tocarEmEsquecer(t);
      await FluxoDentroDaConta.tocar(
        t,
        find.descendant(
          of: find.byKey(TelaConta.chaveConfirmacaoEsquecer),
          matching: find.byType(BotaoPerigo),
        ),
      );
      await FluxoDentroDaConta.tocar(t, simPodeApagar);
      await FluxoDentroDaConta.avancar(t, 6);
    }

    testWidgets('Ajustes é a raiz do destino, com as quatro portas', (
      WidgetTester t,
    ) async {
      await entrar(t);

      await FluxoDentroDaConta.irPara(t, DestinoDaCasca.ajustes);

      expect(find.byType(TelaConfiguracoes), findsOneWidget);
      expect(find.byType(CartaoDePorta), findsNWidgets(4));
    });

    testWidgets('Conta mostra o canal que o aparelho lembra (R10)', (
      WidgetTester t,
    ) async {
      await entrar(t);

      await FluxoDentroDaConta.irAConta(t);
      await FluxoDentroDaConta.avancar(t);

      expect(
        find.descendant(
          of: find.byKey(TelaConta.chaveContato),
          matching: find.text('ana@email.com'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('o "Sair" comum NÃO apaga a data de nascimento, a '
        'apresentação vista nem o identificador', (WidgetTester t) async {
      await entrar(t);

      await FluxoDentroDaConta.tocarEmSair(t);
      await FluxoDentroDaConta.tocar(
        t,
        find.text(TextosAutenticacao.botaoConfirmarSaida),
      );
      await FluxoDentroDaConta.avancar(t, 6);

      expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
      expect(fluxo.dado.apagamentos, 1, reason: 'a conversa sai em toda saída');
      expect(fluxo.cofre.limpezas, greaterThan(0));
      expect(
        await datas.ler(FluxoDentroDaConta.idDaAna),
        isNotNull,
        reason: 'FR-042c: a saída comum mantém a data de nascimento',
      );
      expect(
        await vistas.jaViu(FluxoDentroDaConta.idDaAna),
        isTrue,
        reason: 'FR-013: sair e voltar não repete a apresentação',
      );
      expect(
        await fluxo.ultimoAcesso.identificador(),
        'ana@email.com',
        reason: 'FR-012 × FR-026: a decisão de 2026-09-08',
      );
    });

    testWidgets('"Sair e esquecer este aparelho" apaga TUDO: conversa, '
        'data de nascimento, apresentação vista e identificador', (
      WidgetTester t,
    ) async {
      await entrar(t);

      await confirmarEsquecer(t);

      expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
      expect(fluxo.dado.apagamentos, 1);
      expect(fluxo.cofre.limpezas, greaterThan(0));
      expect(
        await datas.ler(FluxoDentroDaConta.idDaAna),
        isNull,
        reason: 'T123: a data de nascimento sai com esquecerTudo',
      );
      expect(
        await vistas.jaViu(FluxoDentroDaConta.idDaAna),
        isFalse,
        reason: 'T048: a apresentação vista sai com esquecerTudo',
      );
      expect(
        await fluxo.ultimoAcesso.identificador(),
        isNull,
        reason: 'FR-041: sair esquecendo também o identificador lembrado',
      );
    });

    testWidgets('um toque no "Sair e esquecer" não sai: são duas etapas e '
        'nada é apagado antes da segunda', (WidgetTester t) async {
      await entrar(t);

      await FluxoDentroDaConta.tocarEmEsquecer(t);
      expect(find.byKey(TelaConta.chaveConfirmacaoEsquecer), findsOneWidget);
      await FluxoDentroDaConta.tocar(
        t,
        find.descendant(
          of: find.byKey(TelaConta.chaveConfirmacaoEsquecer),
          matching: find.byType(BotaoPerigo),
        ),
      );

      expect(fraseDeTerCerteza, findsOneWidget);
      expect(find.byKey(CascaInterna.chaveDaBarra), findsOneWidget);
      expect(fluxo.dado.apagamentos, 0);
      expect(fluxo.cofre.limpezas, 0);
      expect(await datas.ler(FluxoDentroDaConta.idDaAna), isNotNull);
      expect(await fluxo.ultimoAcesso.identificador(), 'ana@email.com');
    });

    testWidgets('Privacidade apaga a conversa do aparelho, só depois das '
        'duas etapas', (WidgetTester t) async {
      await entrar(t);
      await fluxo.conversa.guardar(<MensagemDaConversa>[
        MensagemDaConversa(
          autor: AutorDaMensagem.pessoa,
          texto: 'Como eu mando uma foto?',
          momento: DateTime(2026, 10),
        ),
      ]);

      await FluxoDentroDaConta.irAPrivacidade(t);
      await FluxoDentroDaConta.tocar(
        t,
        find.byKey(TelaPrivacidade.chaveApagar),
      );
      expect(fluxo.conversa.guardadas, isNotEmpty, reason: '1 toque');
      await FluxoDentroDaConta.tocar(
        t,
        find.descendant(
          of: find.byKey(TelaPrivacidade.chaveConfirmacao),
          matching: find.text(TextosConfiguracoes.botaoApagarConversa),
        ),
      );
      expect(fluxo.conversa.guardadas, isNotEmpty, reason: '2 toques');

      await FluxoDentroDaConta.tocar(t, simPodeApagar);

      expect(fluxo.conversa.guardadas, isEmpty);
      expect(find.byKey(TelaPrivacidade.chaveApagada), findsOneWidget);
    });

    testWidgets('apagar em Privacidade esvazia também a conversa que está '
        'aberta no Início, e ela não volta na próxima pergunta', (
      WidgetTester t,
    ) async {
      await entrar(t);
      await fluxo.conversa.guardar(<MensagemDaConversa>[
        MensagemDaConversa(
          autor: AutorDaMensagem.pessoa,
          texto: 'Como eu mando uma foto?',
          momento: DateTime(2026, 10),
        ),
      ]);
      await FluxoDentroDaConta.tocar(t, find.byKey(TelaInicio.chaveConversar));
      await FluxoDentroDaConta.esperarATransicao(t);
      expect(find.text('Como eu mando uma foto?'), findsOneWidget);

      await FluxoDentroDaConta.irAPrivacidade(t);
      await FluxoDentroDaConta.tocar(
        t,
        find.byKey(TelaPrivacidade.chaveApagar),
      );
      await FluxoDentroDaConta.tocar(
        t,
        find.descendant(
          of: find.byKey(TelaPrivacidade.chaveConfirmacao),
          matching: find.text(TextosConfiguracoes.botaoApagarConversa),
        ),
      );
      await FluxoDentroDaConta.tocar(t, simPodeApagar);
      await FluxoDentroDaConta.irPara(t, DestinoDaCasca.inicio);
      await FluxoDentroDaConta.esperarATransicao(t);

      expect(
        find.text('Como eu mando uma foto?'),
        findsNothing,
        reason:
            'a conversa aberta continuou mostrando o que foi apagado '
            '(e a próxima pergunta o regravaria no aparelho)',
      );
      expect(fluxo.conversa.guardadas, isEmpty);
    });
  });
}
