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

/// As falhas da conversa e quando oferecem tentar de novo — FR-052, FR-057,
/// T103.
///
/// ## A regra
///
/// Só as falhas **passageiras** oferecem "tentar de novo": a conexão, o serviço
/// de fora fora do ar e a falha inesperada. O limite do dia diz que a conversa
/// volta amanhã — um botão ali prometeria o que não vai acontecer —, e a sessão
/// caída não se resolve reenviando a mesma pergunta.
///
/// ## Cada falha tem a sua frase
///
/// E nenhuma culpa a pessoa. A do serviço de fora (FR-057) é a mesma frase que
/// o servidor usa para `ASSISTENTE_INDISPONIVEL`: se o texto divergisse, a
/// pessoa leria duas explicações diferentes para a mesma dificuldade.
/// Falha sempre do mesmo jeito, e conta quantas vezes foi chamado: é o que
/// prova que "tentar de novo" REENVIOU, e não só que o erro continua na tela.
class _RepositorioQueFalha implements RepositorioAssistente {
  final FalhaDaAssistente falha;
  final List<String> mensagens = <String>[];

  _RepositorioQueFalha(this.falha);

  @override
  Future<RespostaDaAssistente> conversar({
    required String mensagem,
    required List<MensagemDaConversa> historico,
    void Function(String trecho)? aoReceberTrecho,
    void Function(void Function() cancelar)? aoCriarCancelamento,
  }) async {
    mensagens.add(mensagem);
    return AssistenteFalhou(falha);
  }

  @override
  Future<List<ServicoDoCatalogo>> catalogo() => throw UnimplementedError();

  @override
  Future<void> registrarAcao({
    required String servicoId,
    required String pedidoResumido,
  }) => throw UnimplementedError();

  @override
  Future<List<AcaoRegistrada>> registro() => throw UnimplementedError();
}

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

  /// Monta a conversa, pergunta algo e devolve com a falha na tela.
  Future<ControladorConversa> falhar(
    WidgetTester t,
    FalhaDaAssistente falha,
  ) async {
    final ControladorConversa c = ControladorConversa(
      RepositorioAssistenteSimulado(demora: Duration.zero, falhaForcada: falha),
      _ConversaEmMemoria(),
      aceite: AceiteEmMemoria(),
    );
    addTearDown(c.dispose);

    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        home: TelaConversa(controlador: c),
      ),
    );
    await avancar(t);

    await t.enterText(find.byKey(TelaConversa.chaveCampo), 'oi');
    await avancar(t);
    await t.ensureVisible(find.byKey(TelaConversa.chaveEnviar));
    await t.pump();
    await t.tap(find.byKey(TelaConversa.chaveEnviar));
    await avancar(t);
    return c;
  }

  Finder botaoDeTentarDeNovo() => find.descendant(
    of: find.byKey(TelaConversa.chaveErro),
    matching: find.byType(BotaoSecundario),
  );

  const Map<FalhaDaAssistente, String> frases = <FalhaDaAssistente, String>{
    FalhaDaAssistente.semConexao: TextosAssistente.semRespostaDaConversa,
    FalhaDaAssistente.assistenteIndisponivel:
        TextosAssistente.assistenteIndisponivel,
    FalhaDaAssistente.inesperada: TextosAssistente.inesperada,
    FalhaDaAssistente.limiteDeConversas: TextosAssistente.limiteDeConversas,
    FalhaDaAssistente.sessaoExpirada: TextosAssistente.sessaoExpirada,
  };

  group('Cada falha mostra a sua frase', () {
    frases.forEach((FalhaDaAssistente falha, String frase) {
      testWidgets(falha.name, (WidgetTester t) async {
        final ControladorConversa c = await falhar(t, falha);

        expect(c.mensagemDeErro, frase);
        expect(find.byKey(TelaConversa.chaveErro), findsOneWidget);
        expect(find.text(frase), findsOneWidget);
      });
    });

    test('nenhuma das cinco frases é igual a outra', () {
      expect(frases.values.toSet(), hasLength(frases.length));
    });

    test('a do serviço indisponível diz que a dificuldade é da Memora', () {
      const String frase = TextosAssistente.assistenteIndisponivel;
      expect(frase, contains('não foi nada que você fez'));
      expect(frase.toLowerCase(), isNot(contains('erro')));
      expect(frase.toLowerCase(), isNot(contains('falha')));
    });
  });

  group('"Tentar de novo" só nas falhas passageiras (FR-052, FR-057)', () {
    for (final FalhaDaAssistente falha in <FalhaDaAssistente>[
      FalhaDaAssistente.semConexao,
      FalhaDaAssistente.assistenteIndisponivel,
      FalhaDaAssistente.inesperada,
    ]) {
      testWidgets('${falha.name} oferece o botão', (WidgetTester t) async {
        final ControladorConversa c = await falhar(t, falha);

        expect(c.podeTentarDeNovo, isTrue);
        expect(botaoDeTentarDeNovo(), findsOneWidget);
      });
    }

    for (final FalhaDaAssistente falha in <FalhaDaAssistente>[
      FalhaDaAssistente.limiteDeConversas,
      FalhaDaAssistente.sessaoExpirada,
    ]) {
      testWidgets('${falha.name} NÃO oferece o botão', (WidgetTester t) async {
        final ControladorConversa c = await falhar(t, falha);

        expect(c.podeTentarDeNovo, isFalse);
        expect(
          botaoDeTentarDeNovo(),
          findsNothing,
          reason: 'um botão aqui prometeria o que não vai acontecer',
        );
      });
    }

    testWidgets('tocar em tentar de novo, com o serviço fora do ar, reenvia '
        'a mesma pergunta sem a pessoa reescrever', (WidgetTester t) async {
      final _RepositorioQueFalha repositorio = _RepositorioQueFalha(
        FalhaDaAssistente.assistenteIndisponivel,
      );
      final ControladorConversa c = ControladorConversa(
        repositorio,
        _ConversaEmMemoria(),
        aceite: AceiteEmMemoria(),
      );
      addTearDown(c.dispose);
      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: TelaConversa(controlador: c),
        ),
      );
      await avancar(t);

      await t.enterText(find.byKey(TelaConversa.chaveCampo), 'oi');
      await avancar(t);
      await t.ensureVisible(find.byKey(TelaConversa.chaveEnviar));
      await t.pump();
      await t.tap(find.byKey(TelaConversa.chaveEnviar));
      await avancar(t);
      expect(repositorio.mensagens, <String>['oi']);
      // A pergunta voltou ao campo, e é ela que o botão reenvia.
      expect(c.rascunho, 'oi');

      await t.ensureVisible(botaoDeTentarDeNovo());
      await t.pump();
      await t.tap(botaoDeTentarDeNovo());
      await avancar(t);

      expect(
        repositorio.mensagens,
        <String>['oi', 'oi'],
        reason: 'a mesma pergunta, sem ninguém ter digitado nada',
      );
      expect(c.mensagemDeErro, TextosAssistente.assistenteIndisponivel);
    });
  });

  group('FalhaDaAssistente.passageira', () {
    test('é a única fonte da regra', () {
      expect(
        FalhaDaAssistente.values
            .where((FalhaDaAssistente f) => f.passageira)
            .toSet(),
        <FalhaDaAssistente>{
          FalhaDaAssistente.semConexao,
          FalhaDaAssistente.assistenteIndisponivel,
          FalhaDaAssistente.inesperada,
        },
      );
    });
  });

  // Achado no celular em 2026-10-21: a falha devolve a pergunta ao campo e a
  // tira da conversa, que volta a ficar vazia — e o aviso, que decidia abrir
  // por "conversa vazia", se recriava ABERTO a cada erro do serviço de fora.
  group('A falha não reabre o aviso (FR-022 da 004)', () {
    testWidgets('depois da primeira falha o aviso continua recolhido', (
      WidgetTester t,
    ) async {
      final ControladorConversa c = await falhar(
        t,
        FalhaDaAssistente.assistenteIndisponivel,
      );

      expect(c.mensagens, isEmpty, reason: 'a pergunta voltou ao campo');
      expect(find.byKey(TelaConversa.chaveAviso), findsOneWidget);
      expect(
        find.byKey(AvisoCompacto.chaveTextoCompleto),
        findsNothing,
        reason: 'a pessoa já viu o aviso aberto antes de perguntar',
      );
    });

    testWidgets('nem depois de tentar de novo e falhar outra vez', (
      WidgetTester t,
    ) async {
      await falhar(t, FalhaDaAssistente.assistenteIndisponivel);
      await t.ensureVisible(botaoDeTentarDeNovo());
      await t.pump();
      await t.tap(botaoDeTentarDeNovo());
      await avancar(t);

      expect(find.byKey(TelaConversa.chaveErro), findsOneWidget);
      expect(find.byKey(AvisoCompacto.chaveTextoCompleto), findsNothing);
    });
  });
}
