import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/aprendizado/data/progresso_de_aprendizado.dart';
import 'package:memora/features/aprendizado/domain/guia.dart';
import 'package:memora/features/aprendizado/presentation/tela_passo_a_passo.dart';
import 'package:memora/l10n/textos_guias.dart';

import '../../suporte/aparelhos.dart';

/// O passo a passo de uma SEÇÃO de um guia extenso (FR-028d, T137): só os
/// passos dela, o título dela no cabeçalho, o progresso por seção e a dúvida
/// com o nome da seção.
void main() {
  Passo passo(int numero, String texto) => Passo(
    captura: CapturaDoGuia.paraTeste('gov-br', numero),
    destaque: const RegiaoRelativa(x: 0.1, y: 0.1, largura: 0.8, altura: 0.1),
    texto: texto,
    descricaoDaCaptura: 'Tela de exemplo $numero.',
  );

  final Guia guia = Guia(
    chave: 'gov-br',
    titulo: 'Aprender a usar o Gov.br',
    capturadoEm: DateTime(2026, 11, 13),
    versaoCapturada: '3.6.0',
    secoes: <SecaoDoGuia>[
      SecaoDoGuia(
        chave: 'entrar',
        titulo: 'Entrar na conta',
        subtitulo: 'Usar CPF e senha.',
        icone: Icons.login,
        passos: <Passo>[
          passo(1, 'Primeiro passo de entrar.'),
          passo(2, 'Segundo passo de entrar.'),
          passo(3, 'Terceiro passo de entrar.'),
        ],
      ),
      SecaoDoGuia(
        chave: 'certidoes',
        titulo: 'Baixar Certidões',
        subtitulo: 'Emitir comprovantes.',
        icone: Icons.description_outlined,
        passos: <Passo>[
          passo(4, 'Primeiro passo das certidões.'),
          passo(5, 'Segundo passo das certidões.'),
          passo(6, 'Terceiro passo das certidões.'),
          passo(7, 'Quarto passo das certidões.'),
        ],
      ),
    ],
  );
  final SecaoDoGuia certidoes = guia.secoes[1];

  Widget tela({
    ProgressoDeAprendizado? progresso,
    void Function(String)? aoTirarDuvida,
  }) => MaterialApp(
    theme: TemasMemora.claro,
    home: TelaPassoAPasso(
      guia: guia,
      secao: certidoes,
      progresso: progresso,
      idDaConta: progresso == null ? null : 'ana',
      aoTirarDuvida: aoTirarDuvida,
    ),
  );

  testWidgets('percorre só os passos da seção, com o título dela', (
    WidgetTester t,
  ) async {
    vestir(t, referencia);
    await t.pumpWidget(tela());
    await t.pumpAndSettle();

    // O cabeçalho é o da seção, e o total é o dela (4), não o do guia (7).
    expect(find.text('Baixar Certidões'), findsOneWidget);
    expect(find.text('Aprender a usar o Gov.br'), findsNothing);
    expect(find.text(TextosGuias.passo(1, 4)), findsOneWidget);
    expect(find.text('Primeiro passo das certidões.'), findsOneWidget);
    expect(find.text('Primeiro passo de entrar.'), findsNothing);
  });

  testWidgets(
    'chegar ao último passo registra o progresso da SEÇÃO (guia:seção), '
    'e a dúvida do fim leva o nome da seção',
    (WidgetTester t) async {
      vestir(t, referencia);
      final _ProgressoGravador progresso = _ProgressoGravador();
      String? duvida;
      await t.pumpWidget(
        tela(progresso: progresso, aoTirarDuvida: (String d) => duvida = d),
      );
      await t.pumpAndSettle();
      expect(progresso.chegadas, isEmpty);

      for (int i = 0; i < 3; i++) {
        await t.ensureVisible(find.byKey(PassoIlustrado.chaveContinuar));
        await t.tap(find.byKey(PassoIlustrado.chaveContinuar));
        await t.pumpAndSettle();
      }

      expect(find.text(TextosGuias.passo(4, 4)), findsOneWidget);
      expect(progresso.chegadas, <String>['gov-br:certidoes@4/4']);

      await t.ensureVisible(find.byKey(PassoIlustrado.chaveTirarDuvida));
      await t.tap(find.byKey(PassoIlustrado.chaveTirarDuvida));
      await t.pumpAndSettle();
      expect(
        duvida,
        TextosGuias.rascunhoDuvida(
          'Aprender a usar o Gov.br (Baixar Certidões)',
        ),
      );
    },
  );
}

/// Anota cada chegada a um passo, sem disco (I/O de arquivo real não completa
/// dentro de `testWidgets`).
class _ProgressoGravador extends ProgressoDeAprendizado {
  final List<String> chegadas = <String>[];

  _ProgressoGravador() : super(diretorio: () async => Directory.systemTemp);

  @override
  Future<bool> registrarChegadaAoPasso({
    required String idDaConta,
    required String chave,
    required int numeroDoPasso,
    required int totalDePassos,
  }) async {
    chegadas.add('$chave@$numeroDoPasso/$totalDePassos');
    return numeroDoPasso == totalDePassos;
  }
}
