import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/hub/domain/hub.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';

/// Cenario H1 do quickstart — o Hub nao mostra porta que nao abre (T030).
///
/// ## O que este arquivo protege
///
/// A FR-003 e a regra menos obvia da US1, e a mais facil de quebrar sem querer:
/// alguem acrescenta uma porta "para depois", e a pessoa toca num botao que nao
/// faz nada. Para quem tem pouca familiaridade, isso e indistinguivel de
/// aparelho quebrado — ou, pior, de erro proprio.
///
/// O teste central aqui **navega** por cada porta e exige que uma tela apareca.
/// Verificar so que o botao existe deixaria passar exatamente o defeito que a
/// FR-003 quer impedir.
void main() {
  /// Uma tela de destino qualquer, para provar que a navegacao aconteceu.
  const Key destino = Key('destino');

  Widget hubCom(List<PortaDoHub> portas) {
    return MaterialApp(
      theme: TemasMemora.claro,
      home: TelaHub(
        nome: 'Ana',
        portas: portas,
        aoSair: () async {},
      ),
    );
  }

  /// Uma porta que leva a algum lugar de verdade.
  PortaDoHub portaQueAbre(
    BuildContext Function() contexto,
    String rotulo,
  ) {
    return PortaDoHub(
      rotulo: rotulo,
      descricao: 'descricao de $rotulo',
      icone: Icons.chat_bubble_outline,
      aoAbrir: () => Navigator.of(contexto()).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext _) => const Scaffold(
            body: Text('cheguei', key: destino),
          ),
        ),
      ),
    );
  }

  group('H1 — o Hub nao mostra porta que nao abre', () {
    testWidgets('toda porta exibida leva a algum lugar', (WidgetTester t) async {
      late BuildContext contexto;

      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: Builder(
            builder: (BuildContext c) {
              contexto = c;
              return TelaHub(
                nome: 'Ana',
                portas: <PortaDoHub>[
                  portaQueAbre(() => contexto, 'Primeira'),
                  portaQueAbre(() => contexto, 'Segunda'),
                ],
                aoSair: () async {},
              );
            },
          ),
        ),
      );

      // Percorre TODAS as portas: e a navegacao que prova a FR-003, nao a
      // presenca do botao.
      for (final String rotulo in <String>['Primeira', 'Segunda']) {
        final Finder porta = find.byKey(TelaHub.chaveDaPorta(rotulo));
        await t.ensureVisible(porta);
        await t.tap(porta);
        await t.pumpAndSettle();

        expect(
          find.byKey(destino),
          findsOneWidget,
          reason: 'a porta "$rotulo" nao levou a lugar nenhum',
        );

        Navigator.of(contexto).pop();
        await t.pumpAndSettle();
      }
    });

    testWidgets('cada porta tem nome escrito E elemento visual (FR-002)',
        (WidgetTester t) async {
      await t.pumpWidget(
        hubCom(<PortaDoHub>[
          PortaDoHub(
            rotulo: 'Conversar',
            descricao: 'me pergunte o que quiser',
            icone: Icons.chat_bubble_outline,
            aoAbrir: () {},
          ),
        ]),
      );

      // Icone isolado e adivinhacao: o Principio III proibe.
      expect(find.text('Conversar'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('a descricao aparece antes do toque (FR-045)',
        (WidgetTester t) async {
      await t.pumpWidget(
        hubCom(<PortaDoHub>[
          PortaDoHub(
            rotulo: 'Servicos do dia a dia',
            descricao: 'Banco e governo — eu te ensino o caminho',
            icone: Icons.account_balance_outlined,
            aoAbrir: () {},
          ),
        ]),
      );

      // "Servicos do dia a dia" nao diz que a Memora so ensina. A pessoa
      // precisa saber disso ANTES de tocar, e nao ao chegar la.
      expect(
        find.text('Banco e governo — eu te ensino o caminho'),
        findsOneWidget,
      );
    });
  });

  group('O Hub e o lugar para onde se volta', () {
    testWidgets('chama a pessoa pelo nome que ela escolheu',
        (WidgetTester t) async {
      await t.pumpWidget(hubCom(const <PortaDoHub>[]));

      expect(find.textContaining('Ana'), findsWidgets);
    });

    testWidgets('a saida existe e e discreta', (WidgetTester t) async {
      bool saiu = false;

      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: TelaHub(
            nome: 'Ana',
            portas: const <PortaDoHub>[],
            aoSair: () async => saiu = true,
          ),
        ),
      );

      final Finder sair = find.byKey(TelaHub.chaveSair);
      await t.ensureVisible(sair);
      await t.tap(sair);
      await t.pumpAndSettle();

      expect(saiu, isTrue);
    });

    testWidgets('no maximo uma porta e a acao principal', (WidgetTester t) async {
      await t.pumpWidget(
        hubCom(<PortaDoHub>[
          PortaDoHub(
            rotulo: 'Principal',
            descricao: 'a acao principal',
            icone: Icons.chat_bubble_outline,
            principal: true,
            aoAbrir: () {},
          ),
          PortaDoHub(
            rotulo: 'Outra',
            descricao: 'uma porta comum',
            icone: Icons.apps_outlined,
            aoAbrir: () {},
          ),
        ]),
      );

      // Duas acoes de mesmo peso dividem a atencao de quem precisa de um
      // caminho so — a regra que a US1 da feature 001 estabeleceu.
      expect(find.byType(BotaoPrimario), findsOneWidget);
    });
  });

  group('Ampliacao — FR-027', () {
    testWidgets('o Hub continua utilizavel com texto a 200%',
        (WidgetTester t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: TelaHub(
              nome: 'Ana',
              portas: <PortaDoHub>[
                PortaDoHub(
                  rotulo: 'Conversar com a Memora',
                  descricao: 'me pergunte qualquer coisa sobre o celular',
                  icone: Icons.chat_bubble_outline,
                  principal: true,
                  aoAbrir: () {},
                ),
              ],
              aoSair: () async {},
            ),
          ),
        ),
      );

      expect(t.takeException(), isNull);
      expect(find.byKey(TelaHub.chaveSaudacao), findsOneWidget);
    });
  });
}
