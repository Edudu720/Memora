import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/abridor_de_aplicativo.dart';
import 'package:memora/features/assistente/data/conversa_local.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/assistente/presentation/controladores/controlador_conversa.dart';
import 'package:memora/features/assistente/presentation/telas/tela_conversa.dart';
import 'package:memora/features/assistente/presentation/telas/tela_registro.dart';
import 'package:memora/l10n/textos_assistente.dart';
import '../../suporte/aceite_em_memoria.dart';

/// Cenario H9 — o registro mostra o que foi feito, e so isso (T060).
///
/// ## O que este arquivo protege
///
/// A FR-025 diz que orientacao apenas ensinada **nao** entra no registro. E a
/// regra mais facil de violar por boa intencao: parece util listar tudo que a
/// Memora respondeu, e listar isso tiraria da pessoa o credito de ter feito.
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
  late RepositorioAssistenteSimulado assistente;
  late AbridorDeAplicativoSimulado abridor;

  setUp(() {
    assistente = RepositorioAssistenteSimulado(demora: Duration.zero);
    abridor = AbridorDeAplicativoSimulado();
  });

  Future<void> avancar(WidgetTester t) async {
    for (int quadro = 0; quadro < 6; quadro++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> montarRegistro(WidgetTester t) async {
    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        home: TelaRegistro(repositorio: assistente),
      ),
    );
    await avancar(t);
  }

  /// Conversa, chega na oferta e confirma — deixando uma acao registrada.
  Future<ControladorConversa> executarUmaAcao(WidgetTester t) async {
    final ControladorConversa c = ControladorConversa(
      assistente,
      _ConversaEmMemoria(),
      aceite: AceiteEmMemoria(),
      abridor: abridor,
    );
    addTearDown(c.dispose);

    await t.pumpWidget(
      MaterialApp(theme: TemasMemora.claro, home: TelaConversa(controlador: c)),
    );
    await avancar(t);

    await t.enterText(find.byKey(TelaConversa.chaveCampo), 'nao consegui achar');
    await avancar(t);
    await t.tap(find.byKey(TelaConversa.chaveEnviar));
    await avancar(t);

    // `runAsync` porque o simulado usa `Future.delayed`, e dentro de
    // `testWidgets` o relogio e falso.
    await t.runAsync(() => c.confirmarAcao());
    await avancar(t);
    return c;
  }

  group('H9 — o registro mostra o que foi feito', () {
    testWidgets('a acao executada aparece, em linguagem comum',
        (WidgetTester t) async {
      await executarUmaAcao(t);
      await montarRegistro(t);

      final List<AcaoRegistrada> acoes = await assistente.registro();
      expect(acoes, hasLength(1));

      expect(
        find.text(
          TextosAssistente.oQueFoiFeito(
            acoes.first.nomeExibido,
            acoes.first.pedidoResumido,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('nenhum segredo ou codigo chega ao registro (FR-036, T079)',
        (WidgetTester t) async {
      final ControladorConversa c = ControladorConversa(
        assistente,
        _ConversaEmMemoria(),
        aceite: AceiteEmMemoria(),
        abridor: abridor,
      );
      addTearDown(c.dispose);

      await t.pumpWidget(
        MaterialApp(theme: TemasMemora.claro, home: TelaConversa(controlador: c)),
      );
      await avancar(t);

      // Usuário relata problema contendo código
      await t.enterText(
        find.byKey(TelaConversa.chaveCampo),
        'não consegui achar meu código é 123456',
      );
      await avancar(t);
      await t.tap(find.byKey(TelaConversa.chaveEnviar));
      await avancar(t);

      await t.runAsync(() => c.confirmarAcao());
      await avancar(t);

      final List<AcaoRegistrada> acoes = await assistente.registro();
      expect(acoes, hasLength(1));
      expect(acoes.first.pedidoResumido, isNot(contains('123456')));

      await montarRegistro(t);
      expect(find.textContaining('123456'), findsNothing);
    });

    testWidgets('a tarefa so ENSINADA nao aparece (FR-025)',
        (WidgetTester t) async {
      final ControladorConversa c = ControladorConversa(
        assistente,
        _ConversaEmMemoria(),
        aceite: AceiteEmMemoria(),
        abridor: abridor,
      );
      addTearDown(c.dispose);

      await t.pumpWidget(
        MaterialApp(theme: TemasMemora.claro, home: TelaConversa(controlador: c)),
      );
      await avancar(t);

      // Uma pergunta comum: a Memora ensina, e ninguem executa nada.
      await t.enterText(
        find.byKey(TelaConversa.chaveCampo),
        'como vejo as fotos do meu neto',
      );
      await avancar(t);
      await t.tap(find.byKey(TelaConversa.chaveEnviar));
      await avancar(t);

      // Quem fez foi a pessoa. Listar isso como "o que a Memora fez" tiraria
      // dela o credito, bem no lugar onde ela vem conferir.
      expect(await assistente.registro(), isEmpty);

      await montarRegistro(t);
      expect(find.text(TextosAssistente.registroVazio), findsOneWidget);
    });

    testWidgets('lista vazia e apresentada como boa noticia',
        (WidgetTester t) async {
      await montarRegistro(t);

      // "Nada encontrado" faria a pessoa achar que perdeu alguma coisa.
      expect(find.text('Você fez tudo sozinha até agora'), findsOneWidget);
    });

    testWidgets('o registro nao e clicavel — e informacao, nao acao',
        (WidgetTester t) async {
      await executarUmaAcao(t);
      await montarRegistro(t);

      // CampoInformacao nao aceita callback de toque, por ausencia de API. Se
      // alguem trocar por um cartao clicavel, este teste avisa.
      expect(
        find.descendant(
          of: find.byKey(TelaRegistro.chaveLista),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
    });
  });

  group('A data e escrita do jeito que uma pessoa fala', () {
    test('mes por extenso, e nao dd/MM/yyyy', () {
      final String texto =
          TextosAssistente.quandoAconteceu(DateTime(2026, 8, 29, 14, 5));

      expect(texto, contains('agosto'));
      expect(texto, contains('14h05'));
      // Quem le isto nao esta auditando um sistema, esta lembrando de um dia.
      expect(texto, isNot(contains('/')));
    });
  });
}
