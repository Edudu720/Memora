import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/domain/autenticacao.dart';
import 'package:memora/features/autenticacao/presentation/controladores/controlador_cadastro.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_boas_vindas.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_cadastro.dart';

Widget _app(Widget filho) => MaterialApp(theme: TemasMemora.claro, home: filho);

Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

/// Digita num campo identificado por chave.
///
/// Localizar por chave em vez de por texto: o rótulo do campo aparece em mais
/// de um lugar da árvore e o localizador por texto pegava o widget errado.
Future<void> _preencher(WidgetTester tester, Key chave, String valor) async {
  final Finder entrada = find.descendant(
    of: find.byKey(chave),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(entrada);
  await tester.enterText(entrada, valor);
  await tester.pumpAndSettle();
}

Future<void> _preencherTudo(WidgetTester tester) async {
  await _preencher(tester, TelaCadastro.chaveNome, 'Ana');
  await _preencher(tester, TelaCadastro.chaveCanal, 'ana@email.com');
  await _preencher(
      tester, TelaCadastro.chaveSenha, 'uma frase que so eu lembro');
}

void main() {
  group('Tela de boas-vindas — US1 cenário 1', () {
    testWidgets('tem exatamente uma ação principal', (WidgetTester t) async {
      await t.pumpWidget(_app(TelaBoasVindas(aoComecar: () {})));

      expect(
        find.byType(BotaoPrimario),
        findsOneWidget,
        reason: 'Duas ações de mesmo peso obrigam a pessoa a decidir algo que '
            'a decisão é nossa. Este é o ponto de maior evasão do produto.',
      );
    });

    testWidgets('quem já tem conta tem caminho, mas sem competir com a ação '
        'principal', (WidgetTester t) async {
      await t.pumpWidget(
        _app(TelaBoasVindas(aoComecar: () {}, aoJaTerConta: () {})),
      );

      expect(find.byType(BotaoPrimario), findsOneWidget);
      expect(find.byType(BotaoTerciario), findsOneWidget);
    });
  });

  group('Cadastro — fluxo completo', () {
    testWidgets('conclui e devolve a pessoa já autenticada (FR-009)',
        (WidgetTester t) async {
      PessoaAutenticada? autenticada;
      final ControladorCadastro c = ControladorCadastro(
        RepositorioAutenticacaoSimulado(demora: Duration.zero),
      );

      await t.pumpWidget(
        _app(TelaCadastro(
          controlador: c,
          aoConcluir: (PessoaAutenticada p) => autenticada = p,
        )),
      );

      await _preencherTudo(t);
      await _tocar(t, find.byKey(TelaCadastro.chaveEnviar));

      expect(
        autenticada,
        isNotNull,
        reason: 'O protótipo mandava para o login depois de cadastrar. Pedir '
            'a senha que a pessoa acabou de criar é onde ela desiste.',
      );
      expect(autenticada!.nomeTratamento, 'Ana');
    });

    testWidgets('o botão só habilita quando tudo está válido',
        (WidgetTester t) async {
      final ControladorCadastro c = ControladorCadastro(
        RepositorioAutenticacaoSimulado(demora: Duration.zero),
      );
      await t.pumpWidget(
        _app(TelaCadastro(controlador: c, aoConcluir: (_) {})),
      );

      expect(c.podeEnviar, isFalse);

      await _preencher(t, TelaCadastro.chaveNome, 'Ana');
      await _preencher(t, TelaCadastro.chaveCanal, 'ana@email.com');
      expect(c.podeEnviar, isFalse, reason: 'Senha ainda não atende às regras.');

      await _preencher(
          t, TelaCadastro.chaveSenha, 'uma frase que so eu lembro');
      expect(c.podeEnviar, isTrue);
    });

    testWidgets('erro preserva o que já foi digitado (FR-006)',
        (WidgetTester t) async {
      final ControladorCadastro c = ControladorCadastro(
        RepositorioAutenticacaoSimulado(
          demora: Duration.zero,
          falhaForcada: FalhaAutenticacao.semConexao,
        ),
      );
      await t.pumpWidget(
        _app(TelaCadastro(controlador: c, aoConcluir: (_) {})),
      );

      await _preencherTudo(t);
      await _tocar(t, find.byKey(TelaCadastro.chaveEnviar));

      expect(find.byType(MensagemErro), findsOneWidget);
      expect(
        c.nome,
        'Ana',
        reason: 'Apagar o formulário de quem errou é a forma mais rápida de '
            'fazer a pessoa desistir.',
      );
      expect(c.canal, 'ana@email.com');
    });

    testWidgets('no modo assistido a senha não pode ser revelada (FR-060)',
        (WidgetTester t) async {
      final ControladorCadastro c = ControladorCadastro(
        RepositorioAutenticacaoSimulado(demora: Duration.zero),
      );
      await t.pumpWidget(
        _app(TelaCadastro(controlador: c, aoConcluir: (_) {})),
      );

      expect(find.text('Mostrar senha'), findsOneWidget);

      await _tocar(t, find.text('Tem alguém te ajudando agora?'));

      expect(
        find.text('Mostrar senha'),
        findsNothing,
        reason: 'Com o acompanhante ao lado, revelar a senha entregaria a ele '
            'o segredo que o modo assistido existe para proteger.',
      );
    });

    testWidgets('as regras da senha aparecem antes de digitar (FR-008)',
        (WidgetTester t) async {
      final ControladorCadastro c = ControladorCadastro(
        RepositorioAutenticacaoSimulado(demora: Duration.zero),
      );
      await t.pumpWidget(
        _app(TelaCadastro(controlador: c, aoConcluir: (_) {})),
      );

      expect(find.text('Sua senha precisa:'), findsOneWidget);
      expect(find.text('Ter pelo menos 10 letras'), findsOneWidget);
    });

    testWidgets('o formulário tem exatamente três campos (FR-001, FR-043)',
        (WidgetTester t) async {
      final ControladorCadastro c = ControladorCadastro(
        RepositorioAutenticacaoSimulado(demora: Duration.zero),
      );
      await t.pumpWidget(
        _app(TelaCadastro(controlador: c, aoConcluir: (_) {})),
      );

      expect(
        find.byType(TextField),
        findsNWidgets(3),
        reason: 'Nome, canal e senha. Nenhum campo de CPF, documento ou dado '
            'bancário — pedir esses dados normaliza o golpe que usa '
            'exatamente esse pedido como isca.',
      );
    });

    testWidgets('a tela avisa que nunca pede CPF nem dado bancário',
        (WidgetTester t) async {
      final ControladorCadastro c = ControladorCadastro(
        RepositorioAutenticacaoSimulado(demora: Duration.zero),
      );
      await t.pumpWidget(
        _app(TelaCadastro(controlador: c, aoConcluir: (_) {})),
      );

      expect(
        find.textContaining('Nada de CPF'),
        findsOneWidget,
        reason: 'Dizer o que nunca pedimos transforma o pedido de um golpista '
            'em sinal de alerta para a pessoa.',
      );
    });
  });
}
