import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/aprendizado/domain/guia.dart';
import 'package:memora/l10n/textos_guias.dart';

import '../suporte/aparelhos.dart';

void main() {
  const Passo passoPadrao = Passo(
    captura: CapturaDoGuia.paraTeste('tiktok', 1),
    destaque: RegiaoRelativa(x: 0.1, y: 0.2, largura: 0.4, altura: 0.2),
    texto: 'Toque no ícone de perfil no canto inferior direito.',
    descricaoDaCaptura: 'Tela inicial do aplicativo com a barra de navegação.',
  );

  const Passo passoComSenha = Passo(
    captura: CapturaDoGuia.paraTeste('gov-br', 2),
    destaque: RegiaoRelativa(x: 0.1, y: 0.3, largura: 0.8, altura: 0.1),
    texto: 'Digite a sua senha cadastrada no gov.br.',
    descricaoDaCaptura: 'Tela oficial do gov.br com campo para digitar a senha.',
    temCampoDeSenha: true,
  );

  Widget app(
    Widget filho, {
    MemoraTemaId tema = MemoraTemaId.claro,
    double escala = 1.0,
  }) {
    return MaterialApp(
      theme: TemasMemora.porId(tema),
      home: MediaQuery(
        data: const MediaQueryData().copyWith(
          textScaler: TextScaler.linear(escala),
        ),
        child: Scaffold(body: filho),
      ),
    );
  }

  group('PassoIlustrado e IndicadorDePasso — T065 (FR-026, FR-028)', () {
    testWidgets('selo Exemplo sempre presente na tela', (WidgetTester t) async {
      await t.pumpWidget(
        app(
          const PassoIlustrado(
            passo: passoPadrao,
            posicao: 1,
            total: 3,
          ),
        ),
      );

      expect(find.byKey(PassoIlustrado.chaveSeloExemplo), findsOneWidget);
      expect(find.text(TextosGuias.exemplo), findsOneWidget);
      expect(find.byType(CaixaDeEtapa), findsOneWidget);
    });

    testWidgets('IndicadorDePasso exibe texto Passo N de M e barra de progresso', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(
        app(
          const PassoIlustrado(
            passo: passoPadrao,
            posicao: 2,
            total: 4,
          ),
        ),
      );

      expect(find.byType(IndicadorDePasso), findsOneWidget);
      expect(find.text('Passo 2 de 4'), findsOneWidget);
      expect(find.bySemanticsLabel('Passo a passo, passo 2 de 4'), findsOneWidget);
    });

    testWidgets('anel de destaque presente sobre a captura', (WidgetTester t) async {
      await t.pumpWidget(
        app(
          const PassoIlustrado(
            passo: passoPadrao,
            posicao: 1,
            total: 3,
          ),
        ),
      );

      expect(find.byKey(PassoIlustrado.chaveDestaque), findsOneWidget);
    });

    testWidgets('passo com senha exibe aviso inteiro da FR-032 (nunca compacto)', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(
        app(
          const PassoIlustrado(
            passo: passoComSenha,
            posicao: 2,
            total: 3,
          ),
        ),
      );

      expect(find.byKey(PassoIlustrado.chaveAvisoSenha), findsOneWidget);
      expect(find.text(TextosGuias.avisoSenha), findsOneWidget);
      expect(find.byType(AvisoCompacto), findsNothing);
    });

    testWidgets('passo sem senha não exibe o aviso de senha', (WidgetTester t) async {
      await t.pumpWidget(
        app(
          const PassoIlustrado(
            passo: passoPadrao,
            posicao: 1,
            total: 3,
          ),
        ),
      );

      expect(find.byKey(PassoIlustrado.chaveAvisoSenha), findsNothing);
    });

    testWidgets('dispara callbacks de continuar, voltar e tela diferente', (
      WidgetTester t,
    ) async {
      int continuou = 0;
      int voltou = 0;
      int telaDiferente = 0;

      await t.pumpWidget(
        app(
          PassoIlustrado(
            passo: passoPadrao,
            posicao: 2,
            total: 3,
            aoContinuar: () => continuou++,
            aoVoltar: () => voltou++,
            aoTelaDiferente: () => telaDiferente++,
          ),
        ),
      );

      await t.ensureVisible(find.byKey(PassoIlustrado.chaveContinuar));
      await t.tap(find.byKey(PassoIlustrado.chaveContinuar));
      await t.pump();
      expect(continuou, 1);

      await t.ensureVisible(find.byKey(PassoIlustrado.chaveTelaDiferente));
      await t.tap(find.byKey(PassoIlustrado.chaveTelaDiferente));
      await t.pump();
      expect(telaDiferente, 1);

      await t.ensureVisible(find.byKey(PassoIlustrado.chaveVoltar));
      await t.tap(find.byKey(PassoIlustrado.chaveVoltar));
      await t.pump();
      expect(voltou, 1);
    });

    testWidgets('último passo muda o texto do botão principal para Voltar ao Hub', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(
        app(
          const PassoIlustrado(
            passo: passoPadrao,
            posicao: 3,
            total: 3,
          ),
        ),
      );

      expect(find.text(TextosGuias.voltarAoHub), findsOneWidget);
      expect(find.text(TextosGuias.parabens), findsOneWidget);
    });

    testWidgets(
      'separa itens de legenda com quebra de linha usando espaçamento vertical adequado '
      'e empilha a mascote em escalaTextoAlta',
      (WidgetTester t) async {
        const Passo passoMultilinha = Passo(
          captura: CapturaDoGuia.whatsapp5,
          destaque: RegiaoRelativa(x: 0.04, y: 0.88, largura: 0.92, altura: 0.08),
          texto: TextosGuias.whatsappPasso5,
          descricaoDaCaptura: TextosGuias.whatsappCaptura5,
        );

        await t.pumpWidget(
          app(
            const PassoIlustrado(
              passo: passoMultilinha,
              posicao: 5,
              total: 5,
            ),
            escala: MemoraDimensoes.escalaTextoMax,
          ),
        );

        final List<String> linhas = TextosGuias.whatsappPasso5
            .split('\n')
            .map((String l) => l.trim())
            .where((String l) => l.isNotEmpty)
            .toList();

        for (final String linha in linhas) {
          expect(find.text(linha), findsOneWidget);
        }

        // Verifica que cada linha numerada fica abaixo da anterior com espaçamento >= MemoraEspacamento.sm
        for (int i = 1; i < linhas.length; i++) {
          final Rect anterior = t.getRect(find.text(linhas[i - 1]));
          final Rect atual = t.getRect(find.text(linhas[i]));
          expect(
            atual.top - anterior.bottom,
            greaterThanOrEqualTo(MemoraEspacamento.sm),
          );
        }

        // Em escalaTextoMax (2.0 >= escalaTextoAlta), a mascote fica empilhada acima da legenda
        final Rect rectMascote = t.getRect(find.byType(MemoraPersonagem).last);
        final Rect rectPrimeiraLinha = t.getRect(find.text(linhas.first));
        expect(rectPrimeiraLinha.top, greaterThanOrEqualTo(rectMascote.bottom));
      },
    );
  });

  group('PassoIlustrado — Matriz completa (FR-044)', () {
    for (final Combinacao c in matriz()) {
      testWidgets('não estoura em ${nomeDa(c)}', (WidgetTester t) async {
        vestir(t, c.aparelho);
        await t.pumpWidget(
          naCombinacao(
            c,
            const PassoIlustrado(
              passo: passoComSenha,
              posicao: 2,
              total: 3,
            ),
          ),
        );

        expect(t.takeException(), isNull, reason: nomeDa(c));
        await exigirAlcancavel(
          t,
          find.byKey(PassoIlustrado.chaveContinuar),
          aparelho: c.aparelho,
          contexto: nomeDa(c),
        );
      });
    }
  });
}
