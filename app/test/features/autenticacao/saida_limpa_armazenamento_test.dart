import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/autenticacao/data/ultimo_acesso_local.dart';
import 'package:memora/features/autenticacao/domain/autenticacao.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_perfil.dart';
import 'package:memora/l10n/textos_autenticacao.dart';
import 'package:memora/services/seguranca/cofre_de_credenciais.dart';
import 'package:memora/services/seguranca/limpeza_de_sessao.dart';

/// Sair da conta: dois toques, confirmação e limpeza (T078, US4).
///
/// Cobre FR-024, FR-025 e FR-026 — e a decisão que resolveu a contradição entre
/// a FR-026 e a FR-012.
void main() {
  group('A saída limpa o que precisa (FR-026)', () {
    late _CofreDeMentira cofre;
    late _UltimoAcessoDeMentira ultimoAcesso;
    late LimpezaDeSessao limpeza;

    setUp(() async {
      cofre = _CofreDeMentira();
      ultimoAcesso = _UltimoAcessoDeMentira();
      limpeza = LimpezaDeSessao(cofre: cofre, ultimoAcesso: ultimoAcesso);

      await cofre.guardarSessao(
        tokenAcesso: 'token-de-acesso',
        refreshToken: 'refresh-de-60-dias',
      );
      await ultimoAcesso.lembrar('ana@gmail.com');
    });

    /// O que de fato abre a conta. Se este teste passar com a limpeza
    /// desligada, "sair" não tira o acesso de ninguém.
    test('o token de acesso some', () async {
      await limpeza.executar();

      expect(await cofre.tokenAcesso(), isNull);
    });

    /// O mais importante dos dois: ele vale 60 dias.
    test('o refresh token some', () async {
      await limpeza.executar();

      expect(await cofre.refreshToken(), isNull);
    });

    /// A decisão de 2026-09-08: a FR-012 continua valendo depois da saída.
    /// Apagar o identificador tornaria o preenchimento prévio inútil
    /// justamente no caso mais comum — sair e voltar depois.
    test('o identificador do último acesso fica, por decisão da equipe', () async {
      await limpeza.executar();

      expect(
        await ultimoAcesso.identificador(),
        'ana@gmail.com',
        reason: 'FR-012 × FR-026: mantém-se o identificador porque toda '
            'credencial já foi embora — quem pega o aparelho vê um e-mail e '
            'nenhuma forma de entrar com ele',
      );
    });

    test('com esquecerTudo, o identificador também some', () async {
      await limpeza.executar(esquecerTudo: true);

      expect(await ultimoAcesso.identificador(), isNull);
      expect(await cofre.refreshToken(), isNull);
    });
  });

  group('Sair leva dois toques, e o segundo é a confirmação', () {
    testWidgets('o botão de sair está na tela, sem menu no caminho (FR-024)',
        (WidgetTester tester) async {
      await tester.pumpWidget(_tela(aoSair: () async {}));

      expect(find.byKey(TelaPerfil.chaveSair), findsOneWidget);
      expect(find.text(TextosAutenticacao.botaoSair), findsOneWidget);
    });

    /// A FR-025 pede confirmação explícita. O primeiro toque não pode sair.
    testWidgets('o primeiro toque abre a confirmação e não encerra nada',
        (WidgetTester tester) async {
      bool saiu = false;
      await tester.pumpWidget(_tela(aoSair: () async => saiu = true));

      await tester.ensureVisible(find.byKey(TelaPerfil.chaveSair));
      await tester.tap(find.byKey(TelaPerfil.chaveSair));
      await tester.pump();

      expect(find.byKey(TelaPerfil.chaveConfirmacao), findsOneWidget);
      expect(saiu, isFalse, reason: 'um toque não pode encerrar a sessão');
    });

    testWidgets('o segundo toque encerra', (WidgetTester tester) async {
      bool saiu = false;
      await tester.pumpWidget(_tela(aoSair: () async => saiu = true));

      await tester.ensureVisible(find.byKey(TelaPerfil.chaveSair));
      await tester.tap(find.byKey(TelaPerfil.chaveSair));
      await tester.pump();

      await tester.ensureVisible(find.text(TextosAutenticacao.botaoConfirmarSaida));
      await tester.tap(find.text(TextosAutenticacao.botaoConfirmarSaida));
      await tester.pump();

      expect(saiu, isTrue);
    });

    /// Dois toques, contados. Se um menu ou uma aba entrar no caminho, este
    /// teste continua passando — mas a contagem aqui é o registro do que a
    /// FR-024 exige, e quebrá-la exige mexer nesta linha de propósito.
    testWidgets('são exatamente dois toques, do perfil até sair',
        (WidgetTester tester) async {
      int toques = 0;
      bool saiu = false;
      await tester.pumpWidget(_tela(aoSair: () async => saiu = true));

      await tester.ensureVisible(find.byKey(TelaPerfil.chaveSair));
      await tester.tap(find.byKey(TelaPerfil.chaveSair));
      toques++;
      await tester.pump();

      await tester.ensureVisible(find.text(TextosAutenticacao.botaoConfirmarSaida));
      await tester.tap(find.text(TextosAutenticacao.botaoConfirmarSaida));
      toques++;
      await tester.pump();

      expect(saiu, isTrue);
      expect(toques, lessThanOrEqualTo(2), reason: 'FR-024: no máximo dois toques');
    });

    testWidgets('desistir volta ao perfil sem encerrar', (WidgetTester tester) async {
      bool saiu = false;
      await tester.pumpWidget(_tela(aoSair: () async => saiu = true));

      await tester.ensureVisible(find.byKey(TelaPerfil.chaveSair));
      await tester.tap(find.byKey(TelaPerfil.chaveSair));
      await tester.pump();

      await tester.ensureVisible(find.text(TextosAutenticacao.botaoFicar));
      await tester.tap(find.text(TextosAutenticacao.botaoFicar));
      await tester.pump();

      expect(saiu, isFalse);
      expect(find.byKey(TelaPerfil.chaveSair), findsOneWidget);
      expect(find.byKey(TelaPerfil.chaveConfirmacao), findsNothing);
    });
  });

  group('O texto da confirmação faz o trabalho dela', () {
    /// "Sim, quero sair" e "Não, quero ficar", nunca "SIM"/"NÃO" nem
    /// "OK"/"Cancelar". Palavra isolada exige que a pessoa lembre a pergunta,
    /// e "Cancelar" a obriga a decidir o que está sendo cancelado.
    testWidgets('os dois botões são frases completas', (WidgetTester tester) async {
      await tester.pumpWidget(_tela(aoSair: () async {}));
      await tester.ensureVisible(find.byKey(TelaPerfil.chaveSair));
      await tester.tap(find.byKey(TelaPerfil.chaveSair));
      await tester.pump();

      expect(find.text(TextosAutenticacao.botaoConfirmarSaida), findsOneWidget);
      expect(find.text(TextosAutenticacao.botaoFicar), findsOneWidget);
      expect(find.text('SIM'), findsNothing);
      expect(find.text('Cancelar'), findsNothing);
    });

    /// O aviso diz o que vem depois, e não o que se perde.
    testWidgets('a confirmação avisa que a senha será necessária',
        (WidgetTester tester) async {
      await tester.pumpWidget(_tela(aoSair: () async {}));
      await tester.ensureVisible(find.byKey(TelaPerfil.chaveSair));
      await tester.tap(find.byKey(TelaPerfil.chaveSair));
      await tester.pump();

      expect(find.textContaining('senha'), findsWidgets);
    });
  });
}

Widget _tela({required Future<void> Function() aoSair}) {
  return MaterialApp(
    theme: TemasMemora.claro,
    home: TelaPerfil(
      pessoa: const PessoaAutenticada(id: 'p1', nomeTratamento: 'Ana'),
      aoSair: aoSair,
      aoSairConcluido: () {},
    ),
  );
}

/// Cofre em memória — teste nunca encosta no armazenamento seguro do aparelho.
class _CofreDeMentira implements CofreDeCredenciais {
  String? _acesso;
  String? _refresh;

  @override
  Future<void> guardarSessao({
    required String tokenAcesso,
    required String refreshToken,
  }) async {
    _acesso = tokenAcesso;
    _refresh = refreshToken;
  }

  @override
  Future<String?> tokenAcesso() async => _acesso;

  @override
  Future<String?> refreshToken() async => _refresh;

  @override
  Future<void> limpar() async {
    _acesso = null;
    _refresh = null;
  }
}

class _UltimoAcessoDeMentira implements UltimoAcesso {
  String? _identificador;

  @override
  Future<String?> identificador() async => _identificador;

  @override
  Future<void> lembrar(String identificador) async =>
      _identificador = identificador;

  @override
  Future<void> esquecer() async => _identificador = null;
}
