import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/aprendizado/data/progresso_de_aprendizado.dart';
import 'package:memora/features/aprendizado/domain/guia.dart';
import 'package:memora/features/aprendizado/presentation/tela_seletor_de_secao.dart';
import 'package:memora/l10n/textos_guias.dart';

import '../../suporte/aparelhos.dart';

/// O seletor de seção dos guias extensos (FR-028d, T137).
///
/// O modelo e o primeiro teste vêm da PR #67 (Eduardo); a matriz completa, o
/// alcance dos cartões e da saída para a conversa, o leitor de tela e o
/// "Já aprendeu" são desta tarefa.
void main() {
  Passo passo(int numero) => Passo(
    captura: CapturaDoGuia.paraTeste('gov-br', numero),
    destaque: const RegiaoRelativa(x: 0.1, y: 0.1, largura: 0.8, altura: 0.1),
    texto: 'Toque no botão azul.',
    descricaoDaCaptura: 'Tela de exemplo.',
  );

  final Guia guiaExemplo = Guia(
    chave: 'gov-br',
    titulo: 'Gov.br',
    capturadoEm: DateTime(2026, 11, 13),
    versaoCapturada: '3.6.0',
    secoes: <SecaoDoGuia>[
      SecaoDoGuia(
        chave: 'entrar',
        titulo: 'Entrar na conta Gov.br',
        subtitulo: 'Usar CPF e senha para acessar seus dados.',
        icone: Icons.login,
        passos: <Passo>[passo(1), passo(2), passo(3)],
      ),
      SecaoDoGuia(
        chave: 'certidoes',
        titulo: 'Baixar Certidões',
        subtitulo: 'Emitir documentos e comprovantes oficiais.',
        icone: Icons.description_outlined,
        passos: <Passo>[passo(4), passo(5), passo(6), passo(7), passo(8)],
      ),
      SecaoDoGuia(
        chave: 'perfil',
        titulo: 'Seu perfil',
        subtitulo: 'Ver e conferir os seus dados.',
        icone: Icons.person_outline,
        passos: <Passo>[passo(9), passo(10), passo(11), passo(12)],
      ),
    ],
  );

  Widget tela({
    ProgressoDeAprendizado? progresso,
    String? idDaConta,
    void Function(SecaoDoGuia)? aoEscolher,
    VoidCallback? aoConversar,
    VoidCallback? aoVoltar,
    bool comConversa = true,
  }) => TelaSeletorDeSecao(
    guia: guiaExemplo,
    progresso: progresso,
    idDaConta: idDaConta,
    aoEscolherSecao: aoEscolher ?? (_) {},
    aoVoltar: aoVoltar ?? () {},
    aoConversar: comConversa ? (aoConversar ?? () {}) : null,
  );

  group('TelaSeletorDeSecao', () {
    testWidgets('exibe todas as seções e abre a seção escolhida', (
      WidgetTester t,
    ) async {
      SecaoDoGuia? escolhida;
      bool voltou = false;
      bool conversou = false;

      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.porId(MemoraTemaId.claro),
          home: tela(
            aoEscolher: (SecaoDoGuia s) => escolhida = s,
            aoVoltar: () => voltou = true,
            aoConversar: () => conversou = true,
          ),
        ),
      );
      await t.pumpAndSettle();

      expect(find.text('Entrar na conta Gov.br'), findsOneWidget);
      expect(find.text('Baixar Certidões'), findsOneWidget);
      expect(find.text('Seu perfil'), findsOneWidget);
      expect(find.text(TextosGuias.quantidadeDePassos(3)), findsOneWidget);
      expect(find.text(TextosGuias.quantidadeDePassos(5)), findsOneWidget);

      await t.tap(find.byKey(TelaSeletorDeSecao.chaveDaSecao('certidoes')));
      await t.pumpAndSettle();
      expect(escolhida?.chave, 'certidoes');

      await t.ensureVisible(find.byKey(TelaSeletorDeSecao.chaveConversar));
      await t.tap(find.byKey(TelaSeletorDeSecao.chaveConversar));
      await t.pumpAndSettle();
      expect(conversou, isTrue);

      await t.tap(find.text(TextosGuias.voltar));
      await t.pumpAndSettle();
      expect(voltou, isTrue);
    });

    testWidgets('a pergunta da Memora cita o serviço', (WidgetTester t) async {
      await t.pumpWidget(MaterialApp(theme: TemasMemora.claro, home: tela()));
      await t.pumpAndSettle();

      expect(find.textContaining('O que você quer aprender no'), findsWidgets);
    });

    testWidgets('sem aoConversar, a saída para a conversa não aparece '
        '(saída que não leva a lugar nenhum é pior que nenhuma)', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(
        MaterialApp(theme: TemasMemora.claro, home: tela(comConversa: false)),
      );
      await t.pumpAndSettle();

      expect(find.byKey(TelaSeletorDeSecao.chaveConversar), findsNothing);
    });

    testWidgets('cada cartão é um botão para o leitor de tela e responde ao '
        'toque dele (TalkBack)', (WidgetTester t) async {
      final SemanticsHandle h = t.ensureSemantics();
      SecaoDoGuia? escolhida;
      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: tela(aoEscolher: (SecaoDoGuia s) => escolhida = s),
        ),
      );
      await t.pumpAndSettle();

      final Finder cartao = find.bySemanticsLabel(
        TextosGuias.secaoDescrita(
          'Baixar Certidões',
          'Emitir documentos e comprovantes oficiais.',
          TextosGuias.quantidadeDePassos(5),
        ),
      );
      expect(cartao, findsOneWidget);
      final SemanticsData dados = t.getSemantics(cartao).getSemanticsData();
      expect(dados.flagsCollection.isButton, isTrue);
      expect(dados.hasAction(SemanticsAction.tap), isTrue);

      // O duplo toque do TalkBack é a ação `tap` na própria Semantics.
      t.semantics.tap(find.semantics.byLabel(RegExp(r"Baixar Certid")));
      await t.pumpAndSettle();
      expect(escolhida?.chave, 'certidoes');

      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      h.dispose();
    });

    testWidgets('a seção cujo último passo a pessoa já alcançou diz '
        '"Já aprendeu"', (WidgetTester t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: tela(
            progresso: _ProgressoFalso(<String, int>{'gov-br:certidoes': 2}),
            idDaConta: 'ana',
          ),
        ),
      );
      await t.pumpAndSettle();

      expect(
        find.text(
          TextosGuias.secaoJaAprendida(TextosGuias.quantidadeDePassos(5)),
        ),
        findsOneWidget,
      );
      // As outras seções não ganham a marca.
      expect(find.textContaining('Já aprendeu'), findsOneWidget);
    });

    // A matriz inteira: aparelho x escala x tema. O seletor tem um cartão por
    // seção e a saída para a conversa no fim; todos precisam poder ser
    // tocados, não só "não estourar".
    //
    // O cartão (e o botão da conversa, de rótulo longo) é texto que quebra, e
    // a 150% e 200% pode ser mais alto que a janela: a fonte quadrada do
    // `flutter test` quebra o dobro de linhas que a Atkinson de verdade. Alvo
    // mais alto que a tela não cabe "inteiro à vista", e nem precisa: a pessoa
    // rola até ele e toca no pedaço que está na janela. Por isso cada um é
    // conferido por um toque DE VERDADE nesse pedaço.
    for (final Combinacao c in matriz()) {
      testWidgets('na matriz, ${nomeDa(c)}: sem estouro e tudo alcançável', (
        WidgetTester t,
      ) async {
        vestir(t, c.aparelho);
        SecaoDoGuia? escolhida;
        bool conversou = false;
        await t.pumpWidget(
          naCombinacao(
            c,
            tela(
              aoEscolher: (SecaoDoGuia s) => escolhida = s,
              aoConversar: () => conversou = true,
            ),
          ),
        );
        await t.pumpAndSettle();

        expect(t.takeException(), isNull);
        expect(find.byKey(TelaSeletorDeSecao.chaveLista), findsOneWidget);

        for (final SecaoDoGuia s in guiaExemplo.secoes) {
          escolhida = null;
          await _tocarNoPedacoVisivel(
            t,
            find.byKey(TelaSeletorDeSecao.chaveDaSecao(s.chave)),
            c.aparelho,
            '${nomeDa(c)}, seção ${s.chave}',
          );
          expect(
            escolhida?.chave,
            s.chave,
            reason:
                '${nomeDa(c)}: o toque no cartão ${s.chave} não abriu a seção',
          );
        }

        await _tocarNoPedacoVisivel(
          t,
          find.byKey(TelaSeletorDeSecao.chaveConversar),
          c.aparelho,
          '${nomeDa(c)}, saída para a conversa',
        );
        expect(
          conversou,
          isTrue,
          reason: '${nomeDa(c)}: o toque na saída para a conversa não a abriu',
        );
        expect(t.takeException(), isNull);
      });
    }
  });
}

/// Rola até [alvo], exige que o pedaço dele que cabe na janela tenha o
/// tamanho de um alvo de decisão (ou o alvo inteiro, se for menor) e toca no
/// meio desse pedaço.
Future<void> _tocarNoPedacoVisivel(
  WidgetTester t,
  Finder alvo,
  Size aparelho,
  String contexto,
) async {
  expect(alvo, findsOneWidget, reason: '$contexto: o alvo nem existe');
  await t.ensureVisible(alvo);
  await t.pump();

  final Rect r = t.getRect(alvo);
  final double topo = r.top < 0 ? 0 : r.top;
  final double base = r.bottom > aparelho.height ? aparelho.height : r.bottom;
  final double minimo = r.height < MemoraDimensoes.alvoDecisao
      ? r.height
      : MemoraDimensoes.alvoDecisao;
  expect(
    base - topo,
    greaterThanOrEqualTo(minimo - 0.01),
    reason: '$contexto: o alvo não ficou à vista para tocar ($r)',
  );
  expect(
    r.left >= 0 && r.right <= aparelho.width,
    isTrue,
    reason: '$contexto: o alvo passou da largura da janela ($r)',
  );
  await t.tapAt(Offset(r.center.dx, (topo + base) / 2));
  await t.pump();
}

/// Um progresso que responde na hora, sem disco (I/O de arquivo real não
/// completa dentro de `testWidgets`).
class _ProgressoFalso extends ProgressoDeAprendizado {
  final Map<String, int> _valores;

  _ProgressoFalso(this._valores)
    : super(diretorio: () async => Directory.systemTemp);

  @override
  Future<Map<String, int>> concluidos(String idDaConta) async => _valores;
}
