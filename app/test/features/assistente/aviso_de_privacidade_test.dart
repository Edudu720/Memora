import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/conversa_local.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/assistente/presentation/controladores/controlador_conversa.dart';
import 'package:memora/features/assistente/presentation/telas/tela_conversa.dart';
import 'package:memora/l10n/textos_assistente.dart';

import '../../suporte/aceite_em_memoria.dart';
import '../../suporte/aparelhos.dart';

/// O aviso de privacidade da conversa — FR-051, T101.
///
/// ## O que este arquivo protege
///
/// O que a pessoa escreve vai a um serviço de fora do Memora, e pessoas de lá
/// podem ler. O aviso é o que a deixa **saber disso a cada conversa**, e a
/// pedir que não escreva o que não deve — os quatro tipos de dado da FR-051.
/// Ele mora na mesma caixa do aviso antigolpe, e portanto tem a mesma
/// permanência.
///
/// ## O portão
///
/// Reprova se o aviso sumir da tela, ou se o texto perder qualquer um dos
/// quatro. Roda na matriz de aparelhos × escalas, porque o aviso é maior que o
/// antigolpe sozinho, e o piso de 13% da lista de mensagens é o que o teto de
/// 45% da caixa protege.
class _ConversaEmMemoria implements ConversaLocal {
  List<MensagemDaConversa> _guardadas = <MensagemDaConversa>[];

  @override
  Future<List<MensagemDaConversa>> ler() async => _guardadas;

  @override
  Future<void> guardar(List<MensagemDaConversa> mensagens) async {
    _guardadas = List<MensagemDaConversa>.from(mensagens);
  }

  @override
  Future<void> apagar() async => _guardadas = <MensagemDaConversa>[];
}

void main() {
  Future<void> avancar(WidgetTester t) async {
    for (int quadro = 0; quadro < 6; quadro++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  Future<ControladorConversa> montar(
    WidgetTester t, {
    Size aparelho = referencia,
    double escala = 1.0,
    bool aceito = true,
  }) async {
    t.view.physicalSize = aparelho;
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    final ControladorConversa c = ControladorConversa(
      RepositorioAssistenteSimulado(demora: Duration.zero),
      _ConversaEmMemoria(),
      aceite: AceiteEmMemoria(aceito: aceito),
    );
    addTearDown(c.dispose);

    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        // Herda o tamanho da janela e troca só a escala: um `MediaQueryData`
        // novo teria altura zero, e o aviso aberto mede o teto dele por ela.
        home: Builder(
          builder: (BuildContext contexto) => MediaQuery(
            data: MediaQuery.of(
              contexto,
            ).copyWith(textScaler: TextScaler.linear(escala)),
            child: TelaConversa(controlador: c),
          ),
        ),
      ),
    );
    await avancar(t);
    return c;
  }

  group('O texto do aviso cobre os quatro tipos de dado', () {
    final String texto = TextosAssistente.avisoPrivacidade.toLowerCase();

    for (final (String tipo, List<String> palavras) in <(String, List<String>)>[
      ('senha', <String>['senha']),
      ('documento', <String>['documento']),
      ('endereço', <String>['endereço']),
      ('saúde', <String>['saúde']),
      ('dinheiro', <String>['dinheiro']),
    ]) {
      test('diz "$tipo"', () {
        expect(
          palavras.every(texto.contains),
          isTrue,
          reason:
              'o aviso da FR-051 perdeu "$tipo": quem lê não fica sabendo '
              'que isso não deve ser escrito na conversa',
        );
      });
    }

    test('diz que o texto vai para fora do Memora e que pessoas podem ler', () {
      expect(texto, contains('fora do memora'));
      expect(texto, contains('podem ler'));
    });

    test('o título pede para não escrever dados pessoais', () {
      expect(
        TextosAssistente.tituloAvisoPrivacidade.toLowerCase(),
        contains('dados pessoais'),
      );
    });
  });

  group(
    'O aviso está na tela e não sai (FR-051, mesma permanência da FR-033)',
    () {
      testWidgets('está lá desde antes da primeira pergunta, com o antigolpe', (
        WidgetTester t,
      ) async {
        await montar(t);

        expect(find.byKey(TelaConversa.chaveAvisoPrivacidade), findsOneWidget);
        expect(
          find.byKey(TelaConversa.chaveAviso),
          findsOneWidget,
          reason: 'o aviso novo não pode ter tomado o lugar do antigolpe',
        );
      });

      testWidgets('continua lá depois de a conversa acontecer', (
        WidgetTester t,
      ) async {
        final ControladorConversa c = await montar(t);

        await t.enterText(
          find.byKey(TelaConversa.chaveCampo),
          'como mando foto',
        );
        await avancar(t);
        await t.ensureVisible(find.byKey(TelaConversa.chaveEnviar));
        await t.pump();
        await t.tap(find.byKey(TelaConversa.chaveEnviar));
        await avancar(t);

        expect(
          c.mensagens,
          isNotEmpty,
          reason: 'a pergunta precisa ter sido enviada',
        );
        expect(find.byKey(TelaConversa.chaveAvisoPrivacidade), findsOneWidget);
      });

      testWidgets('continua lá enquanto a explicação do aceite está aberta', (
        WidgetTester t,
      ) async {
        await montar(t, aceito: false);

        expect(find.byKey(TelaConversa.chaveAceite), findsOneWidget);
        expect(find.byKey(TelaConversa.chaveAvisoPrivacidade), findsOneWidget);
      });

      testWidgets('o aviso mostra o título e o texto escritos', (
        WidgetTester t,
      ) async {
        await montar(t);

        // Antes da primeira mensagem o aviso está aberto, com os dois textos
        // inteiros num parágrafo só — por isso `textContaining`.
        expect(
          find.textContaining(TextosAssistente.tituloAvisoPrivacidade),
          findsOneWidget,
        );
        expect(
          find.textContaining(TextosAssistente.avisoPrivacidade),
          findsOneWidget,
        );
      });
    },
  );

  group('Na matriz de aparelhos × escalas o aviso continua alcançável', () {
    for (final Size aparelho in aparelhos) {
      for (final double escala in escalas) {
        testWidgets('em ${nomeDo(aparelho)} a $escala', (WidgetTester t) async {
          await montar(t, aparelho: aparelho, escala: escala);

          expect(
            t.takeException(),
            isNull,
            reason: 'o aviso maior não pode estourar a tela',
          );

          // A caixa tem teto, e o texto rola dentro dela. Rolar tem que
          // trazer o COMEÇO do parágrafo de privacidade para dentro da janela
          // da caixa — e a janela da caixa tem que estar dentro da tela.
          //
          // Só o começo, e não o parágrafo inteiro: o `flutter test` mede todo
          // texto com uma fonte quadrada, que ocupa o dobro da largura real,
          // e o parágrafo passa da janela mesmo em 100%. O que importa é que
          // rolar chega nele.
          //
          // Desde a integração com a 004, os dois avisos são um texto só, na
          // caixa do `AvisoCompacto`: o que rola é o texto inteiro, e o de
          // privacidade vem depois do de golpe.
          final Finder privacidade = find.descendant(
            of: find.byKey(TelaConversa.chaveAvisoPrivacidade),
            matching: find.textContaining(TextosAssistente.avisoPrivacidade),
          );
          expect(privacidade, findsOneWidget);
          final Rect janela = t.getRect(
            find
                .ancestor(
                  of: privacidade,
                  matching: find.byType(SingleChildScrollView),
                )
                .first,
          );
          expect(janela.top, greaterThanOrEqualTo(0));
          expect(
            janela.bottom,
            lessThanOrEqualTo(aparelho.height),
            reason:
                'a caixa dos avisos passou da tela em '
                '${nomeDo(aparelho)} a $escala',
          );

          await t.ensureVisible(privacidade);
          await t.pump();
          final Rect r = t.getRect(privacidade);
          expect(r.top, greaterThanOrEqualTo(janela.top - 1));
          expect(
            r.top,
            lessThan(janela.bottom),
            reason:
                'o aviso de privacidade ficou inalcançável em '
                '${nomeDo(aparelho)} a $escala',
          );

          // E a conversa continua com espaço: o aviso maior não a esmaga.
          final double alturaDaLista = t
              .getSize(find.byType(ListView).first)
              .height;
          expect(
            alturaDaLista,
            greaterThanOrEqualTo(48),
            reason:
                'sobraram ${alturaDaLista.toStringAsFixed(0)} px para '
                'a lista de mensagens',
          );
        });
      }
    }
  });
}
