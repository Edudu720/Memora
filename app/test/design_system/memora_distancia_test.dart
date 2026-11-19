import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/ajuda/presentation/tela_ajuda.dart';
import 'package:memora/features/apresentacao/data/apresentacao_vista.dart';
import 'package:memora/features/assistente/presentation/telas/tela_conversa.dart';
import 'package:memora/features/inicio/presentation/tela_inicio.dart';
import 'package:memora/l10n/textos_assistente.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';

import '../features/autenticacao/fluxo_dentro_da_conta.dart';
import '../suporte/aparelhos.dart';
import '../suporte/distancia_da_memora.dart';
import '../suporte/movimento.dart';

/// A área de toque da Memora fica longe de qualquer botão (feature 013, T052;
/// FR-005c e FR-055).
///
/// ## Por que existe
///
/// A Memora responde ao toque com um gesto (FR-005a), e a área que responde é
/// o **quadrado inteiro** do desenho, margens transparentes incluídas. Uma
/// pessoa que mira um botão encostado nela e cai um pouco para o lado acaba
/// tocando nela — e nada acontece, que é o pior retorno para quem já tem
/// dificuldade de acertar o alvo. Por isso a regra: 8 dp de distância de
/// qualquer alvo de toque de verdade.
///
/// ## Como se mede
///
/// Com o movimento **ligado** (sem ele a Memora não responde ao toque e não
/// tem área nenhuma para medir): as áreas de toque das `MemoraAnimada` e da
/// anfitriã, contra todo nó de semântica com ação de toque — botão, linha,
/// cartão, campo. `test/suporte/distancia_da_memora.dart` guarda a conta.
///
/// Os testes de baixo percorrem o **fluxo de verdade** (boas-vindas, login,
/// Início, Hub, Ajuda e conversa) na matriz de aparelhos, e não componentes
/// soltos: o defeito que importa é a Memora que a tela de fato põe ao lado de
/// um botão.
void main() {
  movimentoLiberado();

  Widget app(Widget filho) => MaterialApp(
    theme: TemasMemora.claro,
    home: Scaffold(body: filho),
  );

  group('o detector funciona (senão os testes de baixo não provam nada)', () {
    testWidgets('a Memora encostada num botão reprova, a 8 dp passa', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(
        app(
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const MemoraPersonagem(tamanho: 64),
                SizedBox(
                  width: 160,
                  child: BotaoPrimario(rotulo: 'Continuar', aoTocar: () {}),
                ),
              ],
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 500));
      final MedidaDaMemora colada = await medirMemora(t, contexto: 'encostada');
      expect(colada.memoras, 1);
      expect(
        colada.violacoes,
        isNotEmpty,
        reason: 'a Memora colada no botão tem de reprovar',
      );

      await t.pumpWidget(
        app(
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const MemoraPersonagem(tamanho: 64),
                const SizedBox(width: distanciaMinimaDaMemora),
                SizedBox(
                  width: 160,
                  child: BotaoPrimario(rotulo: 'Continuar', aoTocar: () {}),
                ),
              ],
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 500));
      expect(
        await exigirMemoraAfastada(t, contexto: 'a 8 dp'),
        1,
        reason: 'havia uma área de Memora para medir',
      );
    });

    testWidgets('sem reagir ao toque ela não tem área, e não reprova', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(
        app(
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const MemoraPersonagem(tamanho: 64, reageAoToque: false),
                SizedBox(
                  width: 160,
                  child: BotaoPrimario(rotulo: 'Continuar', aoTocar: () {}),
                ),
              ],
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 500));
      expect(await exigirMemoraAfastada(t, contexto: 'sem toque'), 0);
    });
  });

  group('nas telas de verdade, na matriz de aparelhos', () {
    final Iterable<Combinacao> combinacoes = matriz(
      em: const <double>[1.0, 2.0],
      temas: const <MemoraTemaId>[MemoraTemaId.claro],
    );

    for (final Combinacao c in combinacoes) {
      testWidgets('boas-vindas, login, Início, Hub e Ajuda em ${nomeDa(c)}', (
        WidgetTester t,
      ) async {
        int medidas = 0;
        final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
        await fluxo.montar(
          t,
          em: c,
          // Com a apresentação vista, a Ajuda tem a linha "Rever a
          // apresentação", que traz uma Memora dentro de uma linha tocável.
          vistas: ApresentacaoVistaEmMemoria(),
          vigia: (WidgetTester t, String tela) async {
            medidas += await exigirMemoraAfastada(
              t,
              contexto: '$tela, ${nomeDa(c)}',
            );
          },
        );

        expect(find.byKey(TelaInicio.chaveMemora), findsOneWidget);
        medidas += await exigirMemoraAfastada(
          t,
          contexto: 'Início, ${nomeDa(c)}',
        );

        await FluxoDentroDaConta.irAoHub(t);
        expect(find.byType(TelaHub), findsOneWidget);
        medidas += await exigirMemoraAfastada(t, contexto: 'Hub, ${nomeDa(c)}');

        // Toca perto do topo da porta, e não no centro: a 200% no 320x568 a
        // barra com o SOS e o título em duas linhas (feature 014) deixa menos
        // altura à vista que a porta tem, e o centro dela fica atrás da barra
        // inferior — a pessoa toca no que vê.
        final Finder portaAjuda = find.byKey(
          TelaHub.chaveDaPorta(TextosAssistente.portaAjuda),
        );
        await t.ensureVisible(portaAjuda);
        await t.pump();
        await t.tapAt(
          t.getTopLeft(portaAjuda) +
              const Offset(MemoraEspacamento.lg, MemoraEspacamento.lg),
        );
        await FluxoDentroDaConta.avancar(t);
        await FluxoDentroDaConta.esperarATransicao(t);
        expect(find.byType(TelaAjuda), findsOneWidget);
        medidas += await exigirMemoraAfastada(
          t,
          contexto: 'Ajuda, ${nomeDa(c)}',
        );

        expect(
          medidas,
          greaterThan(0),
          reason: 'nenhuma área de Memora foi medida: o teste não prova nada',
        );
      });

      testWidgets('a conversa em ${nomeDa(c)}', (WidgetTester t) async {
        final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
        await fluxo.montar(t, em: c);

        await FluxoDentroDaConta.tocar(
          t,
          find.byKey(TelaInicio.chaveConversar),
        );
        await t.pump(const Duration(milliseconds: 500));
        expect(find.byKey(TelaConversa.chaveCampo), findsOneWidget);
        await exigirMemoraAfastada(t, contexto: 'conversa, ${nomeDa(c)}');
      });
    }
  });
}
