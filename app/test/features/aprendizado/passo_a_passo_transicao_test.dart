import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/aprendizado/data/progresso_de_aprendizado.dart';
import 'package:memora/features/aprendizado/domain/guia.dart';
import 'package:memora/features/aprendizado/presentation/tela_passo_a_passo.dart';
import 'package:memora/features/aprendizado/presentation/tela_seletor_de_secao.dart';
import 'package:memora/features/assistente/data/catalogo_guardado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';

import '../../suporte/movimento.dart';

/// T072 da feature 013 (US6): o passo a passo e o seletor de seções.
///
/// - A Memora **comemora** na conclusão (FR-003): a última etapa do guia e o
///   seletor com todas as seções aprendidas. Uma Memora só por tela (FR-006).
/// - Avançar e voltar entre passos **desliza com direção** (FR-009): o passo
///   novo entra pela direita ao avançar e pela esquerda ao voltar.
/// - Com "reduzir movimento" a troca é instantânea (FR-013).
///
/// Os testes começam com "reduzir movimento" ligado (`flutter_test_config`);
/// quem prova movimento o libera com `liberarMovimento`.
///
/// O toque no passo que sai (FR-014) é provado em
/// `test/design_system/troca_de_passo_test.dart`.
void main() {
  Passo passo(int n, String texto) => Passo(
    captura: CapturaDoGuia.paraTeste('tiktok', n),
    destaque: const RegiaoRelativa(x: 0.1, y: 0.1, largura: 0.8, altura: 0.2),
    texto: texto,
    descricaoDaCaptura: 'Tela de exemplo $n.',
  );

  const String textoUm = 'Toque na barra de pesquisa no alto da tela.';
  const String textoDois = 'Digite o que você quer assistir.';
  const String textoTres = 'Toque no primeiro vídeo para assistir.';

  final Guia guia = Guia(
    chave: 'tiktok',
    titulo: 'Aprender a usar o TikTok',
    capturadoEm: DateTime(2026, 10),
    versaoCapturada: '34.0.0',
    passos: <Passo>[
      passo(1, textoUm),
      passo(2, textoDois),
      passo(3, textoTres),
    ],
  );

  const ServicoDoCatalogo servico = ServicoDoCatalogo(
    id: 's-1',
    chave: 'tiktok',
    nomeExibido: 'TikTok',
    descricaoCurta: 'Vídeos curtos',
    categoria: CategoriaDoServico.cotidiano,
    memoraPodeAbrir: true,
  );

  Widget app(Widget tela) => MaterialApp(theme: TemasMemora.claro, home: tela);

  Widget telaDoGuia({void Function(String)? aoPedirParaAbrir}) =>
      TelaPassoAPasso(
        guia: guia,
        servico: servico,
        origemDoCatalogo: OrigemDoCatalogo.servidor,
        aoPedirParaAbrir: aoPedirParaAbrir,
      );

  final Finder proximo = find.text('Próximo');
  final Finder anterior = find.text('Anterior');

  double largura(WidgetTester t) =>
      t.view.physicalSize.width / t.view.devicePixelRatio;

  double esquerdaDoTexto(WidgetTester t, String texto) =>
      t.getTopLeft(find.text(texto, skipOffstage: false)).dx;

  PoseDaMemora poseDaMemora(WidgetTester t) =>
      t.widget<MemoraAnimada>(find.byType(MemoraAnimada)).expressao;

  /// Deixa a tela montar (os passos são preparados de forma assíncrona) sem
  /// `pumpAndSettle`, que não assenta com a Memora animando.
  Future<void> montar(WidgetTester t, Widget tela) async {
    await t.pumpWidget(app(tela));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
  }

  group('A Memora comemora na conclusão (FR-003)', () {
    testWidgets('só a última etapa do guia tem a Memora comemorando', (
      WidgetTester t,
    ) async {
      await montar(t, telaDoGuia());
      expect(find.byType(MemoraAnimada), findsOneWidget);
      expect(poseDaMemora(t), PoseDaMemora.falando);

      await t.tap(proximo);
      await t.pumpAndSettle();
      expect(poseDaMemora(t), PoseDaMemora.falando, reason: 'passo do meio');

      await t.tap(proximo);
      await t.pumpAndSettle();
      expect(find.byType(MemoraAnimada), findsOneWidget, reason: 'FR-006');
      expect(
        poseDaMemora(t),
        PoseDaMemora.comemorando,
        reason: 'a conclusão é comemorada',
      );
    });

    testWidgets('a Memora da conclusão é decorativa para o leitor de tela', (
      WidgetTester t,
    ) async {
      final SemanticsHandle h = t.ensureSemantics();
      await montar(t, telaDoGuia());
      await t.tap(proximo);
      await t.pumpAndSettle();
      await t.tap(proximo);
      await t.pumpAndSettle();

      expect(poseDaMemora(t), PoseDaMemora.comemorando);
      expect(
        find.ancestor(
          of: find.byType(MemoraAnimada),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
        reason: 'a Memora não é anunciada: o texto já diz tudo',
      );
      h.dispose();
    });

    testWidgets('o seletor com todas as seções aprendidas tem a Memora '
        'comemorando; com seções por aprender, não', (WidgetTester t) async {
      final Guia guiaComSecoes = Guia(
        chave: 'gov-br',
        titulo: 'Gov.br',
        capturadoEm: DateTime(2026, 11, 13),
        versaoCapturada: '3.6.0',
        secoes: <SecaoDoGuia>[
          SecaoDoGuia(
            chave: 'entrar',
            titulo: 'Entrar',
            subtitulo: 'Usar CPF e senha.',
            icone: Icons.login,
            passos: <Passo>[passo(1, textoUm), passo(2, textoDois)],
          ),
          SecaoDoGuia(
            chave: 'perfil',
            titulo: 'Perfil',
            subtitulo: 'Ver os dados.',
            icone: Icons.person_outline,
            passos: <Passo>[passo(3, textoTres)],
          ),
        ],
      );

      Widget seletor(Map<String, int> feitos) => app(
        TelaSeletorDeSecao(
          // Chave por progresso: o seletor lê o progresso ao nascer.
          key: ValueKey<int>(feitos.length),
          guia: guiaComSecoes,
          progresso: _ProgressoFalso(feitos),
          idDaConta: 'ana',
          aoEscolherSecao: (_) {},
          aoVoltar: () {},
        ),
      );

      // Uma seção por aprender: a Memora do balão está em repouso.
      await t.pumpWidget(seletor(<String, int>{'gov-br:entrar': 2}));
      await t.pumpAndSettle();
      expect(find.byType(MemoraAnimada), findsOneWidget);
      expect(poseDaMemora(t), PoseDaMemora.mini);

      // Todas aprendidas: ela comemora, e continua sendo uma só (FR-006).
      await t.pumpWidget(
        seletor(<String, int>{'gov-br:entrar': 2, 'gov-br:perfil': 1}),
      );
      await t.pumpAndSettle();
      expect(find.byType(MemoraAnimada), findsOneWidget);
      expect(poseDaMemora(t), PoseDaMemora.comemorando);
    });
  });

  group('Avançar e voltar entre passos — FR-009', () {
    testWidgets('avançar traz o passo novo pela direita e leva o antigo para '
        'a esquerda', (WidgetTester t) async {
      liberarMovimento(t);
      await montar(t, telaDoGuia());
      final double w = largura(t);
      final double paradoEm = esquerdaDoTexto(t, textoUm);

      await t.tap(proximo);
      await t.pump();
      await t.pump(const Duration(milliseconds: 150));

      expect(
        esquerdaDoTexto(t, textoDois),
        greaterThan(paradoEm),
        reason: 'o passo novo vem da direita',
      );
      expect(esquerdaDoTexto(t, textoDois), lessThan(paradoEm + w));
      expect(
        esquerdaDoTexto(t, textoUm),
        lessThan(paradoEm),
        reason: 'o passo antigo sai pela esquerda',
      );

      await t.pump(const Duration(milliseconds: 500));
      expect(esquerdaDoTexto(t, textoDois), paradoEm);
      expect(find.text(textoUm), findsNothing);
    });

    testWidgets('voltar traz o passo anterior pela esquerda e leva o de agora '
        'para a direita', (WidgetTester t) async {
      liberarMovimento(t);
      await montar(t, telaDoGuia());
      final double paradoEm = esquerdaDoTexto(t, textoUm);

      await t.tap(proximo);
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text(textoUm), findsNothing);

      await t.tap(anterior);
      await t.pump();
      await t.pump(const Duration(milliseconds: 150));

      expect(
        esquerdaDoTexto(t, textoUm),
        lessThan(paradoEm),
        reason: 'o passo anterior vem da esquerda',
      );
      expect(
        esquerdaDoTexto(t, textoDois),
        greaterThan(paradoEm),
        reason: 'o passo de agora sai pela direita',
      );

      await t.pump(const Duration(milliseconds: 500));
      expect(esquerdaDoTexto(t, textoUm), paradoEm);
      expect(find.text(textoDois), findsNothing);
    });

    testWidgets('o "Peça à Memora para abrir" do último passo continua '
        'funcionando depois da transição', (WidgetTester t) async {
      liberarMovimento(t);
      String? pedido;
      await montar(t, telaDoGuia(aoPedirParaAbrir: (String p) => pedido = p));

      for (int i = 0; i < 2; i++) {
        await t.tap(proximo);
        await t.pump();
        await t.pump(const Duration(milliseconds: 500));
      }

      expect(find.byKey(PassoIlustrado.chavePedirParaAbrir), findsOneWidget);
      await t.ensureVisible(find.byKey(PassoIlustrado.chavePedirParaAbrir));
      await t.tap(find.byKey(PassoIlustrado.chavePedirParaAbrir));
      await t.pump();
      expect(pedido, isNotNull);
    });
  });

  group('Reduzir movimento — FR-013', () {
    testWidgets('a troca de passo é instantânea e sem deslocamento', (
      WidgetTester t,
    ) async {
      // O teste já começa com "reduzir movimento" do sistema ligado.
      await montar(t, telaDoGuia());
      final double paradoEm = esquerdaDoTexto(t, textoUm);

      await t.tap(proximo);
      // Um único quadro: não houve instante de deslize.
      await t.pump();
      expect(esquerdaDoTexto(t, textoDois), paradoEm);
      expect(find.text(textoUm), findsNothing);

      await t.tap(anterior);
      await t.pump();
      expect(esquerdaDoTexto(t, textoUm), paradoEm);
      expect(find.text(textoDois), findsNothing);
    });
  });
}

class _ProgressoFalso extends ProgressoDeAprendizado {
  final Map<String, int> _valores;

  _ProgressoFalso(this._valores)
    : super(diretorio: () async => Directory.systemTemp);

  @override
  Future<Map<String, int>> concluidos(String idDaConta) async => _valores;
}
