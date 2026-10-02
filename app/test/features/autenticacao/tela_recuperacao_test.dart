import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/domain/autenticacao.dart';
import 'package:memora/features/autenticacao/presentation/controladores/controlador_recuperacao.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_recuperacao.dart';
import 'package:memora/features/autenticacao/presentation/widgets/aviso_antigolpe.dart';
import 'package:memora/l10n/textos_autenticacao.dart';

Widget _app(Widget filho) => MaterialApp(theme: TemasMemora.claro, home: filho);

const String _senhaAntiga = 'uma frase que so eu lembro';
const String _senhaNova = 'outra frase bem comprida';

/// Simulado com a conta da Ana, semeada pela via síncrona.
///
/// Dentro de `testWidgets` o relógio é falso: `await repo.cadastrar(...)`
/// esperaria para sempre por um temporizador que só anda quando alguém bombeia
/// quadros.
RepositorioAutenticacaoSimulado _comContaDeAna() =>
    RepositorioAutenticacaoSimulado(demora: Duration.zero)..registrarConta(
      identificador: 'ana@email.com',
      senha: _senhaAntiga,
      nome: 'Ana',
    );

Future<ControladorRecuperacao> _montar(
  WidgetTester t, {
  required RepositorioAutenticacao repositorio,
  String identificadorInicial = '',
  void Function(PessoaAutenticada)? aoConcluir,
  String chave = 'recuperacao',
}) async {
  final ControladorRecuperacao c = ControladorRecuperacao(
    repositorio,
    identificadorInicial: identificadorInicial,
  );
  await t.pumpWidget(
    _app(
      TelaRecuperacao(
        // Chave distinta por montagem: com a mesma, o Flutter reaproveita o
        // State da montagem anterior e o campo nunca recebe o valor inicial do
        // controlador novo.
        key: ValueKey<String>(chave),
        controlador: c,
        aoConcluir: aoConcluir ?? (PessoaAutenticada _) {},
      ),
    ),
  );
  addTearDown(c.dispose);
  await t.pump();
  return c;
}

/// A caixa de digitação **dentro** do componente do Design System.
///
/// A chave fica no componente, que é uma coluna com rótulo, campo e texto de
/// ajuda. `enterText` precisa do [TextField] lá dentro.
Finder _entrada(Key chave) =>
    find.descendant(of: find.byKey(chave), matching: find.byType(TextField));

/// Preenche o identificador e pede o código.
Future<void> _pedirCodigoPara(WidgetTester t, String identificador) async {
  await _digitar(t, TelaRecuperacao.chaveIdentificador, identificador);
  await t.ensureVisible(find.byKey(TelaRecuperacao.chavePedirCodigo));
  await t.tap(find.byKey(TelaRecuperacao.chavePedirCodigo));
  await t.pump(const Duration(milliseconds: 10));
  await t.pump(const Duration(milliseconds: 10));
}

Future<void> _digitar(WidgetTester t, Key campo, String valor) async {
  await t.ensureVisible(_entrada(campo));
  await t.enterText(_entrada(campo), valor);
  await t.pump();
}

/// O que está escrito no campo, para conferir o que não veio da digitação.
String? _textoDoCampo(WidgetTester t, Key chave) =>
    t.widget<TextField>(_entrada(chave)).controller?.text;

/// Digita número e senha nova, e toca no botão que troca.
///
/// Os três `pump` não são superstição: o repositório responde por um
/// `Future.delayed`, e dentro de `testWidgets` esse temporizador só anda
/// quando alguém bombeia quadros. Com um `pump` só, a resposta ainda não
/// chegou e a tela é conferida antes de mudar.
Future<void> _concluirTroca(
  WidgetTester t, {
  required String codigo,
  String senha = _senhaNova,
}) async {
  await _digitar(t, TelaRecuperacao.chaveCodigo, codigo);
  await _digitar(t, TelaRecuperacao.chaveSenhaNova, senha);
  final Finder botao = find.byKey(TelaRecuperacao.chaveTrocarSenha);
  await t.ensureVisible(botao);
  await t.tap(botao);
  await t.pump(const Duration(milliseconds: 10));
  await t.pump(const Duration(milliseconds: 10));
  await t.pump(const Duration(milliseconds: 10));
}

void main() {
  group('FR-019 — a resposta é idêntica exista a conta ou não', () {
    testWidgets('conta existente e inexistente levam à mesma etapa', (
      WidgetTester t,
    ) async {
      final RepositorioAutenticacaoSimulado repo = _comContaDeAna();

      await _montar(t, repositorio: repo, chave: 'existe');
      await _pedirCodigoPara(t, 'ana@email.com');
      final bool campoDeCodigoComConta = find
          .byKey(TelaRecuperacao.chaveCodigo)
          .evaluate()
          .isNotEmpty;

      await _montar(t, repositorio: repo, chave: 'nao-existe');
      await _pedirCodigoPara(t, 'ninguem@email.com');
      final bool campoDeCodigoSemConta = find
          .byKey(TelaRecuperacao.chaveCodigo)
          .evaluate()
          .isNotEmpty;

      expect(campoDeCodigoComConta, isTrue);
      expect(
        campoDeCodigoSemConta,
        isTrue,
        reason:
            'parar na primeira etapa quando a conta não existe diria que '
            'ela não existe',
      );
    });

    testWidgets('a confirmação repete apenas o que a pessoa digitou', (
      WidgetTester t,
    ) async {
      final RepositorioAutenticacaoSimulado repo = _comContaDeAna();

      await _montar(t, repositorio: repo, chave: 'texto-com-conta');
      await _pedirCodigoPara(t, 'ana@email.com');
      final String comConta = t
          .widget<TextoMemora>(find.byKey(TelaRecuperacao.chaveConfirmacao))
          .texto;

      await _montar(t, repositorio: repo, chave: 'texto-sem-conta');
      await _pedirCodigoPara(t, 'ninguem@email.com');
      final String semConta = t
          .widget<TextoMemora>(find.byKey(TelaRecuperacao.chaveConfirmacao))
          .texto;

      // As duas frases só diferem no identificador que a própria pessoa
      // escreveu. Tirando isso, precisam ser a mesma coisa.
      expect(
        comConta.replaceAll('ana@email.com', 'X'),
        equals(semConta.replaceAll('ninguem@email.com', 'X')),
      );
      expect(
        comConta,
        contains('Se existir'),
        reason: 'sem o "se", a frase afirma que a conta existe',
      );
    });

    testWidgets('nenhum código é gerado para identificador sem conta', (
      WidgetTester t,
    ) async {
      final RepositorioAutenticacaoSimulado repo = _comContaDeAna();

      await _montar(t, repositorio: repo);
      await _pedirCodigoPara(t, 'ninguem@email.com');

      // Por fora, indistinguível. Por dentro, não há código nenhum — e é por
      // isso que a etapa seguinte recusa.
      expect(repo.recuperacoesPedidas, isEmpty);
    });
  });

  group('FR-023 — o aviso contra golpe é permanente', () {
    testWidgets('está visível nas três etapas, sem rolar', (
      WidgetTester t,
    ) async {
      final RepositorioAutenticacaoSimulado repo = _comContaDeAna();
      final ControladorRecuperacao c = await _montar(t, repositorio: repo);

      expect(find.byType(AvisoAntigolpe), findsOneWidget);

      await _pedirCodigoPara(t, 'ana@email.com');
      expect(find.byType(AvisoAntigolpe), findsOneWidget);

      await _concluirTroca(
        t,
        codigo: RepositorioAutenticacaoSimulado.codigoDaDemonstracao,
      );

      expect(c.etapa, EtapaRecuperacao.concluida);
      expect(find.byType(AvisoAntigolpe), findsOneWidget);
    });

    testWidgets('avisa sobre o número, não só sobre a senha', (
      WidgetTester t,
    ) async {
      await _montar(t, repositorio: _comContaDeAna());

      // O golpe desta tela pede o código recebido, não a senha. Um aviso que
      // só falasse de senha deixaria de fora o dado que está sendo digitado.
      expect(TextosAutenticacao.avisoAntigolpe, contains('6 dígitos'));
      expect(TextosAutenticacao.avisoAntigolpe, contains('senha'));
      expect(find.byType(AvisoAntigolpe), findsOneWidget);
    });
  });

  group('código recusado', () {
    testWidgets('mostra uma recusa só e oferece pedir outro', (
      WidgetTester t,
    ) async {
      final RepositorioAutenticacaoSimulado repo = _comContaDeAna();
      final ControladorRecuperacao c = await _montar(t, repositorio: repo);

      await _pedirCodigoPara(t, 'ana@email.com');
      await _concluirTroca(t, codigo: '000000');

      expect(c.mensagemDeErro, TextosAutenticacao.codigoNaoConfere);
      expect(find.text(TextosAutenticacao.codigoNaoConfere), findsWidgets);
      expect(find.byKey(TelaRecuperacao.chavePedirOutro), findsOneWidget);

      // O valor recusado sai da tela: deixá-lo ali convida a tocar no botão de
      // novo com exatamente o que acabou de ser negado.
      expect(c.codigo, isEmpty);
    });

    testWidgets('pedir outro número volta para conferir o identificador', (
      WidgetTester t,
    ) async {
      final RepositorioAutenticacaoSimulado repo = _comContaDeAna();
      final ControladorRecuperacao c = await _montar(t, repositorio: repo);

      await _pedirCodigoPara(t, 'ana@emial.com');
      await t.ensureVisible(find.byKey(TelaRecuperacao.chavePedirOutro));
      await t.tap(find.byKey(TelaRecuperacao.chavePedirOutro));
      await t.pump();

      // O motivo mais comum de "não recebi" é o endereço digitado errado, e é
      // por isso que o caminho volta ao campo em vez de reenviar às cegas.
      expect(c.etapa, EtapaRecuperacao.pedirCodigo);
      expect(
        _textoDoCampo(t, TelaRecuperacao.chaveIdentificador),
        'ana@emial.com',
      );
    });
  });

  group('senha nova', () {
    testWidgets('o botão só libera com todas as regras atendidas', (
      WidgetTester t,
    ) async {
      final RepositorioAutenticacaoSimulado repo = _comContaDeAna();
      final ControladorRecuperacao c = await _montar(t, repositorio: repo);

      await _pedirCodigoPara(t, 'ana@email.com');
      await _digitar(
        t,
        TelaRecuperacao.chaveCodigo,
        RepositorioAutenticacaoSimulado.codigoDaDemonstracao,
      );
      await _digitar(t, TelaRecuperacao.chaveSenhaNova, 'curta');

      expect(c.senhaValida, isFalse);
      expect(c.podeTrocarSenha, isFalse);

      await _digitar(t, TelaRecuperacao.chaveSenhaNova, _senhaNova);
      expect(c.podeTrocarSenha, isTrue);
    });

    testWidgets('FR-021 — conta que as outras sessões foram encerradas', (
      WidgetTester t,
    ) async {
      final RepositorioAutenticacaoSimulado repo = _comContaDeAna();
      PessoaAutenticada? entrou;

      final ControladorRecuperacao c = await _montar(
        t,
        repositorio: repo,
        aoConcluir: (PessoaAutenticada p) => entrou = p,
      );

      await _pedirCodigoPara(t, 'ana@email.com');
      await _concluirTroca(
        t,
        codigo: RepositorioAutenticacaoSimulado.codigoDaDemonstracao,
      );

      expect(c.etapa, EtapaRecuperacao.concluida);
      expect(
        find.text(TextosAutenticacao.avisoSessoesEncerradas),
        findsOneWidget,
        reason:
            'entrar em silêncio desperdiça a única notícia que importa '
            'para quem está recuperando a conta porque alguém entrou nela',
      );

      // Só entra quando a pessoa toca — a notícia precisa ter sido vista.
      expect(entrou, isNull);
      await t.ensureVisible(find.byKey(TelaRecuperacao.chaveContinuar));
      await t.tap(find.byKey(TelaRecuperacao.chaveContinuar));
      await t.pump();
      expect(entrou?.nomeTratamento, 'Ana');
    });

    testWidgets('a senha nova passa a valer e a antiga não', (
      WidgetTester t,
    ) async {
      final RepositorioAutenticacaoSimulado repo = _comContaDeAna();
      await _montar(t, repositorio: repo);

      await _pedirCodigoPara(t, 'ana@email.com');
      await _concluirTroca(
        t,
        codigo: RepositorioAutenticacaoSimulado.codigoDaDemonstracao,
      );

      // `runAsync` porque dentro de `testWidgets` o relógio é falso: um
      // `await` direto no repositório esperaria para sempre por um
      // temporizador que só anda quando alguém bombeia quadros.
      final ResultadoAutenticacao? comNova = await t.runAsync(
        () => repo.entrar(
          const DadosDeEntrada(
            identificador: 'ana@email.com',
            senha: _senhaNova,
          ),
        ),
      );
      final ResultadoAutenticacao? comAntiga = await t.runAsync(
        () => repo.entrar(
          const DadosDeEntrada(
            identificador: 'ana@email.com',
            senha: _senhaAntiga,
          ),
        ),
      );

      expect(comNova, isA<AutenticacaoConcluida>());
      expect(comAntiga, isA<AutenticacaoFalhou>());
    });

    testWidgets('FR-020 — o código é de uso único', (WidgetTester t) async {
      final RepositorioAutenticacaoSimulado repo = _comContaDeAna();
      await _montar(t, repositorio: repo);

      await _pedirCodigoPara(t, 'ana@email.com');
      await _concluirTroca(
        t,
        codigo: RepositorioAutenticacaoSimulado.codigoDaDemonstracao,
      );

      // Reapresentar o mesmo código, agora direto no repositório: já foi gasto.
      final ResultadoAutenticacao? segundaVez = await t.runAsync(
        () => repo.confirmarRecuperacao(
          identificador: 'ana@email.com',
          codigo: RepositorioAutenticacaoSimulado.codigoDaDemonstracao,
          novaSenha: 'mais uma frase bem comprida',
        ),
      );
      expect(segundaVez, isA<AutenticacaoFalhou>());
    });
  });

  group('identificador vindo do login', () {
    testWidgets('chega preenchido (FR-012)', (WidgetTester t) async {
      final ControladorRecuperacao c = await _montar(
        t,
        repositorio: _comContaDeAna(),
        identificadorInicial: 'ana@email.com',
      );

      expect(c.podePedirCodigo, isTrue);
      expect(
        _textoDoCampo(t, TelaRecuperacao.chaveIdentificador),
        'ana@email.com',
      );
    });
  });
}
