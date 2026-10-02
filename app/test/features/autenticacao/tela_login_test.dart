import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/data/ultimo_acesso_local.dart';
import 'package:memora/features/autenticacao/domain/autenticacao.dart';
import 'package:memora/features/autenticacao/presentation/controladores/controlador_login.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_login.dart';
import 'package:memora/l10n/textos_autenticacao.dart';

import 'dubles_autenticacao.dart';

Widget _app(Widget filho) => MaterialApp(theme: TemasMemora.claro, home: filho);

/// Repositório que sempre consegue renovar a sessão (cenário 1 da US2).
class _RepositorioComSessaoViva extends RepositorioDeTeste {
  @override
  Future<ResultadoAutenticacao> renovarSessao() async =>
      const AutenticacaoConcluida(
        PessoaAutenticada(id: 'x', nomeTratamento: 'Ana'),
      );
}

const String _senhaDeAna = 'uma frase que so eu lembro';

/// Cria um simulado já com a conta da Ana, **sem sessão aberta**.
///
/// Semeia pela via síncrona de propósito: dentro de `testWidgets` o relógio é
/// falso, e `await repo.cadastrar(...)` esperaria para sempre por um
/// temporizador que só anda quando o teste bombeia quadros.
RepositorioAutenticacaoSimulado _comContaDeAna({
  List<int> escada = const <int>[3],
}) {
  return RepositorioAutenticacaoSimulado(
    demora: Duration.zero,
    escadaDeBloqueio: escada,
  )..registrarConta(
      identificador: 'ana@email.com',
      senha: _senhaDeAna,
      nome: 'Ana',
    );
}

/// Monta a tela e deixa a renovação automática terminar.
///
/// Não usa `pumpAndSettle`: o `Carregando` do estado inicial anima sem parar, e
/// esperar por quietude nunca terminaria.
Future<ControladorLogin> _montar(
  WidgetTester t, {
  required RepositorioAutenticacao repositorio,
  UltimoAcesso? ultimoAcesso,
  void Function(PessoaAutenticada)? aoEntrar,
  String chave = 'login',
}) async {
  final ControladorLogin c = ControladorLogin(
    repositorio,
    ultimoAcesso ?? UltimoAcessoEmMemoria(),
  );
  await t.pumpWidget(
    _app(
      TelaLogin(
        // Chave distinta por montagem: com a mesma, o Flutter reaproveita o
        // State da tela anterior, `initState` não roda de novo e a renovação
        // automática nunca é disparada para o controlador novo.
        key: ValueKey<String>(chave),
        controlador: c,
        aoEntrar: aoEntrar ?? (PessoaAutenticada _) {},
      ),
    ),
  );
  addTearDown(c.dispose);
  await t.pump(const Duration(milliseconds: 10));
  await t.pump(const Duration(milliseconds: 10));
  await t.pump(const Duration(milliseconds: 10));
  return c;
}

Finder _entrada(Key chave) => find.descendant(
      of: find.byKey(chave),
      matching: find.byType(TextField),
    );

Future<void> _preencher(WidgetTester t, Key chave, String valor) async {
  await t.ensureVisible(_entrada(chave));
  await t.enterText(_entrada(chave), valor);
  await t.pump();
}

/// Deixa a contagem do bloqueio chegar ao fim.
///
/// Necessário porque o `Timer.periodic` da contagem sobrevive ao corpo do
/// teste, e a checagem de temporizador pendente roda **antes** do `tearDown` —
/// descartar o controlador ali não chega a tempo.
Future<void> _esperarOBloqueioPassar(WidgetTester t) async {
  await t.pump(const Duration(seconds: 4));
}

/// Uma tentativa de login completa, do preenchimento à resposta.
Future<void> _tentar(
  WidgetTester t, {
  String identificador = 'ana@email.com',
  required String senha,
}) async {
  await _preencher(t, TelaLogin.chaveIdentificador, identificador);
  await _preencher(t, TelaLogin.chaveSenha, senha);

  final Finder botao = find.byKey(TelaLogin.chaveEntrar);
  await t.ensureVisible(botao);
  await t.tap(botao);
  await t.pump(const Duration(milliseconds: 10));
  await t.pump(const Duration(milliseconds: 10));
  await t.pump(const Duration(milliseconds: 10));
}

void main() {
  group('Formulário — FR-011', () {
    testWidgets('pede exatamente duas coisas', (WidgetTester t) async {
      await _montar(t, repositorio: _comContaDeAna());

      expect(
        find.byType(TextField),
        findsNWidgets(2),
        reason: 'A FR-011 é literal: identificador e senha. Qualquer campo a '
            'mais é uma decisão devolvida a quem já achava difícil entrar.',
      );
    });

    testWidgets('não pergunta se é e-mail ou telefone', (WidgetTester t) async {
      await _montar(t, repositorio: _comContaDeAna());

      expect(
        find.byType(OpcaoSelecionavel),
        findsNothing,
        reason: 'Escolher entre e-mail e telefone devolve à pessoa a pergunta '
            '"com qual dos dois eu me cadastrei?" — que é o que a FR-051 '
            'existe para evitar. Quem decide é o servidor, pela presença do @.',
      );
    });
  });

  group('Pré-preenchimento do último acesso — FR-012', () {
    testWidgets('traz o identificador de quem entrou por último',
        (WidgetTester t) async {
      await _montar(
        t,
        repositorio: _comContaDeAna(),
        ultimoAcesso: UltimoAcessoEmMemoria('ana@email.com'),
      );

      expect(
        _textoDoCampo(t, TelaLogin.chaveIdentificador),
        'ana@email.com',
        reason: 'O cenário 2 da US2 diz que só a senha deveria faltar.',
      );
      expect(find.text(TextosAutenticacao.identificadorLembrado),
          findsOneWidget);
    });

    testWidgets('aparelho novo começa com o campo vazio',
        (WidgetTester t) async {
      await _montar(t, repositorio: _comContaDeAna());

      expect(_textoDoCampo(t, TelaLogin.chaveIdentificador), '');
      expect(
        find.text(TextosAutenticacao.identificadorLembrado),
        findsNothing,
        reason: 'Dizer "deixei preenchido do seu último acesso" com o campo '
            'vazio é uma frase que não descreve nada do que está na tela.',
      );
    });

    testWidgets('o aviso some quando a pessoa edita o campo',
        (WidgetTester t) async {
      await _montar(
        t,
        repositorio: _comContaDeAna(),
        ultimoAcesso: UltimoAcessoEmMemoria('ana@email.com'),
      );

      await _preencher(t, TelaLogin.chaveIdentificador, 'outra@email.com');

      expect(
        find.text(TextosAutenticacao.identificadorLembrado),
        findsNothing,
        reason: 'O aviso mentiria sobre um valor que a pessoa acabou de '
            'digitar ela mesma.',
      );
    });

    testWidgets('só grava o identificador depois que o login dá certo',
        (WidgetTester t) async {
      final UltimoAcessoEmMemoria memoria = UltimoAcessoEmMemoria();
      await _montar(
        t,
        repositorio: _comContaDeAna(),
        ultimoAcesso: memoria,
      );

      await _tentar(t, senha: 'senha errada');
      expect(
        memoria.valor,
        isNull,
        reason: 'Gravar na tentativa transformaria um erro de digitação em '
            'pré-preenchimento errado para sempre.',
      );

      await _tentar(t, senha: _senhaDeAna);
      expect(memoria.valor, 'ana@email.com');
    });
  });

  group('Recusa genérica — FR-013', () {
    testWidgets('senha errada e conta inexistente dizem a MESMA coisa',
        (WidgetTester t) async {
      final RepositorioAutenticacaoSimulado repo = _comContaDeAna();

      await _montar(t, repositorio: repo);
      await _tentar(t, senha: 'senha errada');
      final bool comSenhaErrada =
          find.text(TextosAutenticacao.credenciaisInvalidas).evaluate().isNotEmpty;

      await _montar(t, repositorio: _comContaDeAna(), chave: 'segunda');
      await _tentar(
        t,
        identificador: 'ninguem@email.com',
        senha: 'qualquer coisa',
      );
      final bool comContaInexistente =
          find.text(TextosAutenticacao.credenciaisInvalidas).evaluate().isNotEmpty;

      expect(
        comSenhaErrada && comContaInexistente,
        isTrue,
        reason: 'Distinguir os dois casos entrega a um golpista a lista de '
            'quem tem conta no Memora, que é o insumo do ataque direcionado '
            'descrito na tabela de ameaças.',
      );
    });
  });

  group('Bloqueio progressivo — FR-014 e FR-015', () {
    testWidgets('a quinta falha bloqueia, e o botão sai do ar',
        (WidgetTester t) async {
      await _montar(t, repositorio: _comContaDeAna());

      for (int i = 0; i < 5; i++) {
        await _tentar(t, senha: 'senha errada $i');
      }

      expect(
        find.byKey(TelaLogin.chaveContagem),
        findsOneWidget,
        reason: 'Sem a contagem, "tente mais tarde" obriga a pessoa a '
            'adivinhar quando o mais tarde chegou.',
      );
      expect(
        find.byKey(TelaLogin.chaveEntrar),
        findsNothing,
        reason: 'Botão que continua ali e não responde é onde o idoso conclui '
            'que o aparelho quebrou.',
      );

      await _esperarOBloqueioPassar(t);
    });

    testWidgets('a espera termina sozinha e o botão volta',
        (WidgetTester t) async {
      await _montar(t, repositorio: _comContaDeAna(escada: <int>[3]));

      for (int i = 0; i < 5; i++) {
        await _tentar(t, senha: 'senha errada $i');
      }
      expect(find.byKey(TelaLogin.chaveEntrar), findsNothing);

      // A contagem do controlador roda em segundos reais de tempo simulado.
      for (int i = 0; i < 4; i++) {
        await t.pump(const Duration(seconds: 1));
      }

      expect(
        find.byKey(TelaLogin.chaveEntrar),
        findsOneWidget,
        reason: 'Exigir que a pessoa saia e volte à tela para destravar seria '
            'uma instrução que ninguém deu a ela.',
      );
      expect(find.byKey(TelaLogin.chaveContagem), findsNothing);
    });

    testWidgets('a mensagem acolhe, explica e oferece saída',
        (WidgetTester t) async {
      await _montar(t, repositorio: _comContaDeAna());

      for (int i = 0; i < 5; i++) {
        await _tentar(t, senha: 'senha errada $i');
      }

      expect(
        find.textContaining('Acontece com todo mundo'),
        findsOneWidget,
        reason: 'A FR-015 proíbe tom de punição.',
      );
      expect(
        find.textContaining('adivinhar sua senha'),
        findsOneWidget,
        reason: 'A FR-015 exige o motivo. Sem ele a espera parece castigo.',
      );
      expect(
        find.textContaining('criar uma nova com você'),
        findsOneWidget,
        reason: 'A FR-015 exige o caminho de recuperação. Quem esqueceu a '
            'senha não sai da espera esperando mais.',
      );

      await _esperarOBloqueioPassar(t);
    });
  });

  group('Sessão mantida entre usos — FR-016', () {
    testWidgets('quem tem sessão válida entra sem ver formulário nenhum',
        (WidgetTester t) async {
      PessoaAutenticada? entrou;

      await _montar(
        t,
        repositorio: _RepositorioComSessaoViva(),
        aoEntrar: (PessoaAutenticada p) => entrou = p,
      );

      expect(
        entrou?.nomeTratamento,
        'Ana',
        reason: 'O cenário 1 da US2 é literal: reabro e continuo conectada '
            'sem digitar nada.',
      );
      expect(
        find.byKey(TelaLogin.chaveEntrar),
        findsNothing,
        reason: 'Pedir a senha a quem já tem sessão válida é a barreira que a '
            'FR-016 existe para remover.',
      );
    });
  });
}

/// Lê o texto atualmente dentro de um campo, pela chave.
String _textoDoCampo(WidgetTester t, Key chave) {
  final TextField campo = t.widget<TextField>(_entrada(chave));
  return campo.controller?.text ?? '';
}
