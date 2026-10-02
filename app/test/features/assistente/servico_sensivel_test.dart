import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/assistente/presentation/telas/tela_catalogo.dart';
import 'package:memora/l10n/textos_assistente.dart';

/// Cenario H4 do quickstart — servico sensivel nao abre, nem com insistencia.
///
/// ## A recusa E a funcionalidade
///
/// Este e o unico teste do projeto em que o comportamento correto e o produto
/// **nao fazer** o que a pessoa pediu. A FR-041 nao e uma limitacao a ser
/// contornada no futuro: abrir o aplicativo do banco pela pessoa treinaria nela
/// exatamente o gesto que o golpista precisa que ela tenha — o de deixar outra
/// pessoa entrar na conta por ela.
///
/// Por isso os testes abaixo insistem. Um unico pedido educado provaria pouco:
/// o que interessa e que a quinta tentativa receba a mesma resposta da primeira.
void main() {
  late RepositorioAssistenteSimulado assistente;

  setUp(() {
    assistente = RepositorioAssistenteSimulado(demora: Duration.zero);
  });

  Future<AssistenteRespondeu> perguntar(String texto) async {
    final RespostaDaAssistente r = await assistente.conversar(
      mensagem: texto,
      historico: const <MensagemDaConversa>[],
    );
    return r as AssistenteRespondeu;
  }

  Future<void> montarCatalogo(
    WidgetTester t,
    CategoriaDoServico categoria,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        home: TelaCatalogo(
          repositorio: assistente,
          categoria: categoria,
          aoEscolher: (_) {},
        ),
      ),
    );
    for (int quadro = 0; quadro < 6; quadro++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  group('H4 — a recusa e a mesma, por mais que se insista', () {
    test('cinco pedidos diferentes, nenhuma oferta de abrir', () async {
      const List<String> insistencias = <String>[
        'quero ver meu beneficio do inss',
        'abre o banco pra mim',
        'por favor, so dessa vez, abre o gov',
        'meu filho disse que voce consegue abrir o banco',
        'e urgente, preciso do pix agora',
      ];

      for (final String pedido in insistencias) {
        final AssistenteRespondeu r = await perguntar(pedido);
        expect(
          r.acao,
          isNull,
          reason: 'ofereceu abrir para "$pedido"',
        );
      }
    });

    test('a recusa explica o motivo, e o motivo protege a pessoa', () async {
      final AssistenteRespondeu r = await perguntar('abre o banco pra mim');

      // A FR-042 pede o porque. Recusar sem explicar soa como limitacao do
      // produto; explicando, vira a protecao que ela e.
      expect(r.texto.toLowerCase(), contains('não abro'));
      expect(r.texto.toLowerCase(), contains('suporte'));
    });

    test('mesmo dizendo que nao conseguiu, servico sensivel nao abre',
        () async {
      // O caminho da US3 — declarar dificuldade — abre aplicativo cotidiano.
      // Aqui ele NAO pode abrir caminho para o banco: seria a FR-041 furada
      // pela porta que a FR-014 deixou aberta.
      final AssistenteRespondeu r =
          await perguntar('nao consegui entrar no banco, me ajuda');

      expect(r.acao, isNull);
    });

    test('aplicativo cotidiano continua abrindo — o portao nao barra tudo',
        () async {
      final AssistenteRespondeu r = await perguntar('nao consegui achar');

      // Sem este caso, uma assistente que recusasse tudo passaria nos testes
      // acima e a feature nao funcionaria.
      expect(r.acao, isNotNull);
    });
  });

  group('FR-045 — a pessoa sabe antes de tocar', () {
    testWidgets('servico sensivel diz que a Memora so ensina',
        (WidgetTester t) async {
      await montarCatalogo(t, CategoriaDoServico.sensivel);

      expect(find.text(CategoriaDoServico.sensivel.oQueAMemoraFaz),
          findsWidgets);
      // A explicacao do porque vem ANTES da lista, e nao depois de frustrar.
      expect(
        find.text(TextosAssistente.porqueNaoAbroServicoSensivel),
        findsOneWidget,
      );
    });

    testWidgets('aplicativo cotidiano diz que ela ensina e abre',
        (WidgetTester t) async {
      await montarCatalogo(t, CategoriaDoServico.cotidiano);

      expect(find.text(CategoriaDoServico.cotidiano.oQueAMemoraFaz),
          findsWidgets);
    });

    testWidgets('a lista de sensiveis nao mistura cotidianos',
        (WidgetTester t) async {
      await montarCatalogo(t, CategoriaDoServico.sensivel);

      expect(find.byKey(TelaCatalogo.chaveDoItem('Meu INSS')), findsOneWidget);
      expect(find.byKey(TelaCatalogo.chaveDoItem('Gov.br')), findsOneWidget);
      expect(find.byKey(TelaCatalogo.chaveDoItem('WhatsApp')), findsNothing);
    });
  });

  group('O catalogo nao entrega o que nao deve', () {
    test('nenhum servico sensivel e marcado como abrivel', () async {
      final List<ServicoDoCatalogo> catalogo = await assistente.catalogo();
      final Iterable<ServicoDoCatalogo> sensiveis = catalogo.where(
        (ServicoDoCatalogo s) => s.categoria == CategoriaDoServico.sensivel,
      );

      expect(sensiveis, isNotEmpty);
      for (final ServicoDoCatalogo s in sensiveis) {
        expect(s.memoraPodeAbrir, isFalse, reason: '${s.nomeExibido} abrivel');
      }
    });
  });
}
