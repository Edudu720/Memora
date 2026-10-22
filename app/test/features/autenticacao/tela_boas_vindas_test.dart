import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/presentation/fluxo_autenticacao.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_boas_vindas.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_cadastro.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_de_volta.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_login.dart';
import 'package:memora/l10n/textos_autenticacao.dart';

import '../../suporte/aparelhos.dart';
import 'dubles_autenticacao.dart';

Future<void> _avancar(WidgetTester t, [int quadros = 4]) async {
  for (int i = 0; i < quadros; i++) {
    await t.pump(const Duration(milliseconds: 20));
  }
}

Future<void> _montarFluxo(
  WidgetTester t, {
  required UltimoAcessoEmMemoria ultimoAcesso,
}) async {
  await t.pumpWidget(
    MaterialApp(
      theme: TemasMemora.claro,
      home: FluxoAutenticacao(
        repositorio: RepositorioAutenticacaoSimulado(demora: Duration.zero),
        ultimoAcesso: ultimoAcesso,
      ),
    ),
  );
  await _avancar(t);
}

void main() {
  group('Decisão das boas-vindas pelo último acesso — FR-009, FR-009a, T127', () {
    testWidgets(
      'aparelho sem último acesso abre TelaBoasVindas (FR-009)',
      (WidgetTester t) async {
        final UltimoAcessoEmMemoria memoria = UltimoAcessoEmMemoria();
        await _montarFluxo(t, ultimoAcesso: memoria);

        expect(
          find.byType(TelaBoasVindas),
          findsOneWidget,
          reason: 'Aparelho novo deve mostrar a tela de boas-vindas completa.',
        );
        expect(find.byType(TelaDeVolta), findsNothing);
        expect(find.byKey(TelaBoasVindas.chaveComecar), findsOneWidget);
        expect(find.text(TextosAutenticacao.botaoJaTenhoConta), findsOneWidget);
      },
    );

    testWidgets(
      'aparelho com último acesso abre TelaDeVolta (FR-009a)',
      (WidgetTester t) async {
        final UltimoAcessoEmMemoria memoria =
            UltimoAcessoEmMemoria('ana@email.com');
        await _montarFluxo(t, ultimoAcesso: memoria);

        expect(
          find.byType(TelaDeVolta),
          findsOneWidget,
          reason: 'Quem já acessou neste aparelho deve ver a tela de volta.',
        );
        expect(find.byType(TelaBoasVindas), findsNothing);
        expect(find.byKey(TelaDeVolta.chaveEntrar), findsOneWidget);
        expect(find.byKey(TelaDeVolta.chaveCriarConta), findsOneWidget);
      },
    );

    testWidgets(
      'navegação na TelaBoasVindas: começar leva a cadastro, e voltar devolve às boas-vindas',
      (WidgetTester t) async {
        final UltimoAcessoEmMemoria memoria = UltimoAcessoEmMemoria();
        await _montarFluxo(t, ultimoAcesso: memoria);

        await t.tap(find.byKey(TelaBoasVindas.chaveComecar));
        await _avancar(t);

        expect(find.byType(TelaCadastro), findsOneWidget);

        // Voltar na tela de cadastro deve retornar para as boas-vindas
        final Finder botaoVoltar = find.bySemanticsLabel('Voltar');
        expect(botaoVoltar, findsOneWidget);
        await t.tap(botaoVoltar);
        await _avancar(t);

        expect(find.byType(TelaBoasVindas), findsOneWidget);
      },
    );

    testWidgets(
      'navegação na TelaBoasVindas: já tenho conta leva ao login, e voltar devolve às boas-vindas',
      (WidgetTester t) async {
        final UltimoAcessoEmMemoria memoria = UltimoAcessoEmMemoria();
        await _montarFluxo(t, ultimoAcesso: memoria);

        await t.tap(find.text(TextosAutenticacao.botaoJaTenhoConta));
        await _avancar(t);

        expect(find.byType(TelaLogin), findsOneWidget);

        final Finder botaoVoltar = find.bySemanticsLabel('Voltar');
        expect(botaoVoltar, findsOneWidget);
        await t.tap(botaoVoltar);
        await _avancar(t);

        expect(find.byType(TelaBoasVindas), findsOneWidget);
      },
    );

    testWidgets(
      'navegação na TelaDeVolta: entrar leva ao login, e voltar devolve à tela de volta',
      (WidgetTester t) async {
        final UltimoAcessoEmMemoria memoria =
            UltimoAcessoEmMemoria('ana@email.com');
        await _montarFluxo(t, ultimoAcesso: memoria);

        await t.tap(find.byKey(TelaDeVolta.chaveEntrar));
        await _avancar(t);

        expect(find.byType(TelaLogin), findsOneWidget);

        final Finder botaoVoltar = find.bySemanticsLabel('Voltar');
        expect(botaoVoltar, findsOneWidget);
        await t.tap(botaoVoltar);
        await _avancar(t);

        expect(find.byType(TelaDeVolta), findsOneWidget);
      },
    );

    testWidgets(
      'navegação na TelaDeVolta: criar outra conta leva a cadastro, e voltar devolve à tela de volta',
      (WidgetTester t) async {
        final UltimoAcessoEmMemoria memoria =
            UltimoAcessoEmMemoria('ana@email.com');
        await _montarFluxo(t, ultimoAcesso: memoria);

        await t.tap(find.byKey(TelaDeVolta.chaveCriarConta));
        await _avancar(t);

        expect(find.byType(TelaCadastro), findsOneWidget);

        final Finder botaoVoltar = find.bySemanticsLabel('Voltar');
        expect(botaoVoltar, findsOneWidget);
        await t.tap(botaoVoltar);
        await _avancar(t);

        expect(find.byType(TelaDeVolta), findsOneWidget);
      },
    );
  });

  group('TelaBoasVindas — Ocupação vertical e matriz (FR-009, FR-044)', () {
    testWidgets(
      'ocupa a altura disponível sem deixar rodapé vazio em tela alta',
      (WidgetTester t) async {
        vestir(t, referencia); // 390x844
        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: TelaBoasVindas(
              aoComecar: () {},
              aoJaTerConta: () {},
            ),
          ),
        );

        final Rect rectCartao = t.getRect(find.byType(Cartao));
        // A tela tem 844 de altura e padding vertical total de 2 * MemoraEspacamento.lg (32px).
        // O cartão deve ter pelo menos a altura útil calculada.
        expect(rectCartao.height, greaterThanOrEqualTo(844.0 - 2 * MemoraEspacamento.lg));
      },
    );

    for (final Combinacao c in matriz()) {
      testWidgets(
        'TelaBoasVindas sem estouro e com ações alcançáveis em ${nomeDa(c)}',
        (WidgetTester t) async {
          vestir(t, c.aparelho);
          int comecou = 0;
          int jaTemConta = 0;

          await t.pumpWidget(
            naCombinacao(
              c,
              TelaBoasVindas(
                aoComecar: () => comecou++,
                aoJaTerConta: () => jaTemConta++,
              ),
            ),
          );

          expect(t.takeException(), isNull, reason: nomeDa(c));

          await exigirAlcancavel(
            t,
            find.byKey(TelaBoasVindas.chaveComecar),
            aparelho: c.aparelho,
            contexto: nomeDa(c),
          );
          await t.tap(find.byKey(TelaBoasVindas.chaveComecar));
          expect(comecou, 1, reason: '${nomeDa(c)}: chaveComecar não respondeu');

          await exigirAlcancavel(
            t,
            find.text(TextosAutenticacao.botaoJaTenhoConta),
            aparelho: c.aparelho,
            contexto: nomeDa(c),
          );
          await t.tap(find.text(TextosAutenticacao.botaoJaTenhoConta));
          expect(jaTemConta, 1, reason: '${nomeDa(c)}: botaoJaTenhoConta não respondeu');
        },
      );
    }
  });

  group('TelaDeVolta — Ocupação vertical e matriz (FR-009a, FR-044)', () {
    testWidgets(
      'ocupa a altura disponível sem deixar rodapé vazio em tela alta',
      (WidgetTester t) async {
        vestir(t, referencia); // 390x844
        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: TelaDeVolta(
              aoEntrar: () {},
              aoCriarConta: () {},
            ),
          ),
        );

        final Rect rectCartao = t.getRect(find.byType(Cartao));
        expect(rectCartao.height, greaterThanOrEqualTo(844.0 - 2 * MemoraEspacamento.lg));
      },
    );

    for (final Combinacao c in matriz()) {
      testWidgets(
        'TelaDeVolta sem estouro e com ações alcançáveis em ${nomeDa(c)}',
        (WidgetTester t) async {
          vestir(t, c.aparelho);
          int entrou = 0;
          int criouConta = 0;

          await t.pumpWidget(
            naCombinacao(
              c,
              TelaDeVolta(
                aoEntrar: () => entrou++,
                aoCriarConta: () => criouConta++,
              ),
            ),
          );

          expect(t.takeException(), isNull, reason: nomeDa(c));

          final Finder memora = find.byKey(TelaDeVolta.chaveIlustracao);
          if (memora.evaluate().isNotEmpty) {
            expect(
              t.getSize(memora).height,
              lessThanOrEqualTo(
                c.aparelho.height * MemoraDimensoes.fracaoDaFiguraDoInicio + 0.01,
              ),
              reason: '${nomeDa(c)}: figura passou da fração permitida',
            );
          }

          await exigirAlcancavel(
            t,
            find.byKey(TelaDeVolta.chaveEntrar),
            aparelho: c.aparelho,
            contexto: nomeDa(c),
          );
          await t.tap(find.byKey(TelaDeVolta.chaveEntrar));
          expect(entrou, 1, reason: '${nomeDa(c)}: chaveEntrar não respondeu');

          await exigirAlcancavel(
            t,
            find.byKey(TelaDeVolta.chaveCriarConta),
            aparelho: c.aparelho,
            contexto: nomeDa(c),
          );
          await t.tap(find.byKey(TelaDeVolta.chaveCriarConta));
          expect(criouConta, 1, reason: '${nomeDa(c)}: chaveCriarConta não respondeu');
        },
      );
    }
  });
}
