import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/casca/casca_interna.dart';
import 'package:memora/features/hub/domain/hub.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';
import 'package:memora/features/inicio/presentation/tela_inicio.dart';
import 'package:memora/l10n/textos_assistente.dart';
import 'package:memora/l10n/textos_casca.dart';

import '../../suporte/estados_de_tela.dart';
import '../autenticacao/fluxo_dentro_da_conta.dart';

/// Cenário H1 do quickstart — o Hub não mostra porta que não abre (T030 da
/// 003, T035 da 004).
///
/// ## O que este arquivo protege
///
/// A FR-003 da 003 e a FR-018 da 004 são a regra menos óbvia do Hub, e a mais
/// fácil de quebrar sem querer: alguém acrescenta uma porta "para depois", e a
/// pessoa toca num botão que não faz nada. Para quem tem pouca familiaridade,
/// isso é indistinguível de aparelho quebrado — ou, pior, de erro próprio.
///
/// Os testes centrais **navegam** por cada porta e exigem que uma tela
/// apareça. Verificar só que o botão existe deixaria passar exatamente o
/// defeito que a regra quer impedir. E o teste decisivo é o do **fluxo real**:
/// a tela isolada só prova o que o próprio teste pôs nela.
void main() {
  /// Uma tela de destino qualquer, para provar que a navegação aconteceu.
  const Key destino = Key('destino');

  PortaDoHub porta(
    String rotulo, {
    VoidCallback? aoAbrir,
    bool principal = false,
    Ilustracao ilustracao = Ilustracao.portaConversa,
  }) => PortaDoHub(
    rotulo: rotulo,
    descricao: 'descrição de $rotulo',
    ilustracao: ilustracao,
    principal: principal,
    aoAbrir: aoAbrir ?? () {},
  );

  Widget hubCom(List<PortaDoHub> portas, {VoidCallback? aoVoltar}) {
    return MaterialApp(
      theme: TemasMemora.claro,
      home: TelaHub(portas: portas, aoVoltar: aoVoltar ?? () {}),
    );
  }

  group('H1 — o Hub não mostra porta que não abre', () {
    testWidgets('toda porta exibida leva a algum lugar', (
      WidgetTester t,
    ) async {
      late BuildContext contexto;

      PortaDoHub queAbre(String rotulo) => porta(
        rotulo,
        aoAbrir: () => Navigator.of(contexto).push<void>(
          MaterialPageRoute<void>(
            builder: (BuildContext _) =>
                const Scaffold(body: Text('cheguei', key: destino)),
          ),
        ),
      );

      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: Builder(
            builder: (BuildContext c) {
              contexto = c;
              return TelaHub(
                portas: <PortaDoHub>[queAbre('Primeira'), queAbre('Segunda')],
                aoVoltar: () {},
              );
            },
          ),
        ),
      );

      // Percorre TODAS as portas: é a navegação que prova a regra, não a
      // presença do botão.
      for (final String rotulo in <String>['Primeira', 'Segunda']) {
        final Finder alvo = find.byKey(TelaHub.chaveDaPorta(rotulo));
        await t.ensureVisible(alvo);
        await t.tap(alvo);
        await t.pumpAndSettle();

        expect(
          find.byKey(destino),
          findsOneWidget,
          reason: 'a porta "$rotulo" não levou a lugar nenhum',
        );

        Navigator.of(contexto).pop();
        await t.pumpAndSettle();
      }
    });

    testWidgets('o Hub só desenha as portas que recebe, uma a uma', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(hubCom(<PortaDoHub>[porta('A'), porta('B')]));
      expect(find.byType(CartaoDePorta), findsNWidgets(2));

      await t.pumpWidget(hubCom(<PortaDoHub>[porta('A')]));
      expect(find.byType(CartaoDePorta), findsOneWidget);
    });

    testWidgets('pelo FLUXO REAL, cada porta do Hub abre uma tela de verdade', (
      WidgetTester t,
    ) async {
      final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
      await fluxo.montar(t);
      await FluxoDentroDaConta.irAoHub(t);

      final List<Key> portas = <Key>[
        for (final Widget w in t.widgetList(
          find.byWidgetPredicate(
            (Widget widget) => widget is CartaoHeroi || widget is CartaoDePorta,
          ),
        ))
          w.key!,
      ];
      expect(portas, isNotEmpty, reason: 'o Hub do aplicativo está vazio');

      for (final Key chave in portas) {
        await FluxoDentroDaConta.tocar(t, find.byKey(chave));
        await FluxoDentroDaConta.esperarATransicao(t);

        // O Hub saiu de cima: outra tela o cobriu. Porta que só "aceita o
        // toque" deixaria o Hub exatamente onde estava.
        expect(
          find.byType(TelaHub),
          findsNothing,
          reason: 'a porta $chave não abriu tela nenhuma (FR-003 e FR-018)',
        );

        // "Me tira daqui" volta à raiz do Início, e o Hub se reabre.
        await FluxoDentroDaConta.irPara(t, DestinoDaCasca.inicio);
        await FluxoDentroDaConta.irAoHub(t);
      }
    });
  });

  group('O que a porta mostra — FR-016', () {
    testWidgets('cada porta tem nome escrito, desenho e explicação', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(hubCom(<PortaDoHub>[porta('Conversar')]));

      expect(find.text('Conversar'), findsOneWidget);
      expect(find.text('descrição de Conversar'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CartaoDePorta),
          matching: find.byType(MedalhaoDeIlustracao),
        ),
        findsOneWidget,
        reason: 'a porta precisa de desenho, além do texto (FR-004)',
      );
    });

    testWidgets('no máximo uma porta é a ação principal (FR-002)', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(
        hubCom(<PortaDoHub>[
          porta('Principal', principal: true),
          porta('Outra'),
          porta('Mais uma'),
        ]),
      );

      final int principais = find.byType(CartaoHeroi).evaluate().length;
      // Duas ações de mesmo peso dividem a atenção de quem precisa de um
      // caminho só — a regra que a US1 da feature 001 estabeleceu.
      expect(principais, lessThanOrEqualTo(1));
    });

    testWidgets('pelo fluxo real, a conversa é a única principal', (
      WidgetTester t,
    ) async {
      final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
      await fluxo.montar(t);
      await FluxoDentroDaConta.irAoHub(t);

      expect(find.byType(CartaoHeroi), findsOneWidget);
    });
  });

  group('O que o Hub NÃO tem', () {
    testWidgets('nenhum "Sair" — a saída fica em Ajustes (FR-019)', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(hubCom(<PortaDoHub>[porta('A', principal: true)]));
      expect(find.textContaining('Sair'), findsNothing);
      expect(find.textContaining('sair'), findsNothing);
    });

    testWidgets('nenhum termo técnico no que a pessoa lê (FR-008)', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(hubCom(<PortaDoHub>[porta('A')]));
      expect(find.textContaining('Hub'), findsNothing);
      expect(find.textContaining('Chatbot'), findsNothing);
    });
  });

  group('O caminho de volta — FR-001', () {
    testWidgets('"Voltar" existe, no cabeçalho, e leva de volta ao Início', (
      WidgetTester t,
    ) async {
      int voltou = 0;
      await t.pumpWidget(
        hubCom(<PortaDoHub>[porta('A')], aoVoltar: () => voltou++),
      );

      expect(
        find.descendant(
          of: find.byType(BarraSuperior),
          matching: find.byKey(CabecalhoDeTela.chaveVoltar),
        ),
        findsOneWidget,
      );
      await t.tap(find.byKey(CabecalhoDeTela.chaveVoltar));
      expect(voltou, 1);
    });

    testWidgets(
      'pelo fluxo real, o Hub é empilhado sobre o Início e "Voltar" devolve '
      'ao Início (T040)',
      (WidgetTester t) async {
        final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
        await fluxo.montar(t);

        await FluxoDentroDaConta.irAoHub(t);
        expect(find.byType(TelaHub), findsOneWidget);
        expect(
          find.byKey(TelaInicio.chaveSaudacao),
          findsNothing,
          reason: 'o Início está por baixo, não ao lado',
        );

        await FluxoDentroDaConta.tocar(
          t,
          find.byKey(CabecalhoDeTela.chaveVoltar),
        );
        await FluxoDentroDaConta.esperarATransicao(t);
        expect(find.byType(TelaHub), findsNothing);
        expect(find.byKey(TelaInicio.chaveSaudacao), findsOneWidget);
      },
    );

    testWidgets(
      'T074 (A5): Serviços sociais, Dispositivo de Cuidado e Localizador usam ícones distintos no Hub',
      (WidgetTester t) async {
        final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
        await fluxo.montar(t);

        await FluxoDentroDaConta.irAoHub(t);

        final Finder servicos = find.byKey(
          TelaHub.chaveDaPorta(TextosAssistente.portaServicos),
        );
        final Finder cuidado = find.byKey(
          TelaHub.chaveDaPorta('Dispositivo de Cuidado'),
        );
        final Finder localizador = find.byKey(
          TelaHub.chaveDaPorta('Localizador de Serviços'),
        );

        expect(
          find.descendant(
            of: servicos,
            matching: find.byIcon(Icons.account_balance_rounded),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: cuidado,
            matching: find.byIcon(Icons.favorite_rounded),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: localizador,
            matching: find.byIcon(Icons.location_on_rounded),
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('Estados — FR-006', () {
    testWidgets('o Hub tem o estado vazio, e ele tem desenho e frase', (
      WidgetTester t,
    ) async {
      await exigirOsEstadosDaFr006(
        t,
        tela: 'TelaHub',
        montar: (EstadoDaTela estado) => switch (estado) {
          // O Hub recebe as portas prontas: não carrega, e não falha.
          EstadoDaTela.carregando => null,
          EstadoDaTela.erro => null,
          EstadoDaTela.vazio => hubCom(const <PortaDoHub>[]),
        },
      );
      expect(find.byKey(TelaHub.chaveVazio), findsOneWidget);
      expect(find.text(TextosCasca.hubVazioTitulo), findsOneWidget);
    });
  });
}
