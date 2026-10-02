import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/presentation/fluxo_autenticacao.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_cadastro.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_confirmar_canal.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_entrega_do_aparelho.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_primeira_entrada.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_login.dart';

import 'dubles_autenticacao.dart';

/// O modo assistido de ponta a ponta (T061-T064, FR-058 a FR-064).
///
/// ## O que se prova aqui
///
/// Que o acompanhante consegue ajudar no preenchimento e **não** consegue
/// chegar à senha, e que a pessoa dona da conta termina o cadastro entrando
/// sozinha. É a User Story 5 inteira, exercitada pela árvore de widgets.
///
/// ## Por que o repositório simulado, e não um dublê
///
/// O simulado reproduz a espera de verificação do servidor: conta assistida
/// nasce pendente e não entra até a posse ser confirmada. Um dublê que
/// aceitasse tudo faria este arquivo passar sem exercitar o que importa.

/// Avança alguns quadros sem esperar quietude — o `Carregando` anima sem parar.
Future<void> _avancar(WidgetTester t, [int quadros = 4]) async {
  for (int i = 0; i < quadros; i++) {
    await t.pump(const Duration(milliseconds: 20));
  }
}

Future<void> _tocarNoTexto(WidgetTester t, String texto) async {
  final Finder alvo = find.text(texto);
  await t.ensureVisible(alvo);
  await t.pump();
  await t.tap(alvo);
  await _avancar(t);
}

Future<void> _tocarNaChave(WidgetTester t, Key chave) async {
  final Finder alvo = find.byKey(chave);
  await t.ensureVisible(alvo);
  await t.pump();
  await t.tap(alvo);
  await _avancar(t);
}

Future<void> _preencher(WidgetTester t, Key chave, String valor) async {
  final Finder entrada = find.descendant(
    of: find.byKey(chave),
    matching: find.byType(TextField),
  );
  await t.ensureVisible(entrada);
  await t.enterText(entrada, valor);
  await t.pump();
}

Future<void> _montarFluxo(
  WidgetTester t, {
  required UltimoAcessoEmMemoria ultimoAcesso,
}) async {
  await t.pumpWidget(
    MaterialApp(
      theme: TemasMemora.claro,
      home: FluxoAutenticacao(
        repositorio: RepositorioAutenticacaoSimulado(demora: Duration.zero),
        ultimoAcesso: ultimoAcesso,
      ),
    ),
  );
  await _avancar(t);
}

/// Preenche nome e canal com o modo assistido ligado, parando antes da senha.
Future<void> _preencherComAcompanhante(WidgetTester t) async {
  await _tocarNoTexto(t, 'Começar minha jornada');
  await _tocarNoTexto(t, 'Tem alguém te ajudando agora?');

  await _preencher(t, TelaCadastro.chaveNome, 'Ana');
  await _preencher(t, TelaCadastro.chaveCanal, 'ana@email.com');
  await _avancar(t);
}

void main() {
  group('A senha não é alcançada pelo acompanhante — FR-059 e FR-060', () {
    testWidgets('com acompanhante, o campo de senha não existe na tela', (
      WidgetTester t,
    ) async {
      await _montarFluxo(t, ultimoAcesso: UltimoAcessoEmMemoria());

      await _preencherComAcompanhante(t);

      expect(
        find.byKey(TelaCadastro.chaveSenha),
        findsNothing,
        reason:
            'A FR-059 manda interromper o fluxo AO CHEGAR na senha. Um '
            'campo presente, ainda que rolado para baixo, já teria sido '
            'preenchido pelo acompanhante.',
      );
    });

    testWidgets('sem acompanhante, o campo de senha está lá desde o começo', (
      WidgetTester t,
    ) async {
      await _montarFluxo(t, ultimoAcesso: UltimoAcessoEmMemoria());

      await _tocarNoTexto(t, 'Começar minha jornada');
      await _preencher(t, TelaCadastro.chaveNome, 'Ana');

      expect(find.byKey(TelaCadastro.chaveSenha), findsOneWidget);
    });

    testWidgets('o pedido de devolver o aparelho aparece e explica o motivo', (
      WidgetTester t,
    ) async {
      await _montarFluxo(t, ultimoAcesso: UltimoAcessoEmMemoria());
      await _preencherComAcompanhante(t);

      await _tocarNaChave(t, TelaCadastro.chavePedirAparelho);

      expect(find.byType(TelaEntregaDoAparelho), findsOneWidget);
      expect(
        find.textContaining('devolva o celular'),
        findsOneWidget,
        reason: 'O pedido precisa ser explícito (FR-059), não uma sugestão.',
      );
    });

    /// A FR-059 interrompe um gesto de cuidado. Sem agradecer, a interrupção
    /// soa como acusação — e quem se sente acusado contorna a regra.
    testWidgets('o texto agradece quem ajudou em vez de acusar', (
      WidgetTester t,
    ) async {
      await _montarFluxo(t, ultimoAcesso: UltimoAcessoEmMemoria());
      await _preencherComAcompanhante(t);
      await _tocarNaChave(t, TelaCadastro.chavePedirAparelho);

      expect(find.textContaining('Você ajudou até aqui'), findsOneWidget);
    });

    testWidgets('depois da entrega, a senha aparece', (WidgetTester t) async {
      await _montarFluxo(t, ultimoAcesso: UltimoAcessoEmMemoria());
      await _preencherComAcompanhante(t);
      await _tocarNaChave(t, TelaCadastro.chavePedirAparelho);

      await _tocarNaChave(t, TelaEntregaDoAparelho.chaveContinuar);

      expect(find.byKey(TelaCadastro.chaveSenha), findsOneWidget);
    });

    /// FR-060: no modo assistido não há como revelar a senha digitada.
    testWidgets('a senha não tem o olhinho de revelar', (WidgetTester t) async {
      await _montarFluxo(t, ultimoAcesso: UltimoAcessoEmMemoria());
      await _preencherComAcompanhante(t);
      await _tocarNaChave(t, TelaCadastro.chavePedirAparelho);
      await _tocarNaChave(t, TelaEntregaDoAparelho.chaveContinuar);

      // `Icons.visibility`, e não `visibility_outlined`: o CampoSenha usa o
      // primeiro. Procurar o ícone errado fazia este teste passar mesmo com
      // `permitirRevelar: true` — descoberto ao quebrar o portão de propósito.
      final Finder olhinho = find.descendant(
        of: find.byKey(TelaCadastro.chaveSenha),
        matching: find.byIcon(Icons.visibility),
      );
      expect(
        olhinho,
        findsNothing,
        reason:
            'Revelar a senha entregaria ao acompanhante, que ainda está '
            'ao lado, exatamente o segredo que este modo protege (FR-060).',
      );
    });
  });

  group('Confirmar a posse e entrar sozinha — FR-062 e FR-063', () {
    testWidgets('o cadastro assistido leva à confirmação, não para dentro', (
      WidgetTester t,
    ) async {
      await _montarFluxo(t, ultimoAcesso: UltimoAcessoEmMemoria());
      await _cadastrarComAcompanhante(t);

      expect(find.byType(TelaConfirmarCanal), findsOneWidget);
      expect(
        find.byKey(TelaHub.chaveSaudacao),
        findsNothing,
        reason:
            'Entrar aqui concluiria o cadastro assistido sem posse '
            'confirmada, que é o que o cenário V4 proíbe.',
      );
    });

    testWidgets('código errado não passa, e o texto não culpa a pessoa', (
      WidgetTester t,
    ) async {
      await _montarFluxo(t, ultimoAcesso: UltimoAcessoEmMemoria());
      await _cadastrarComAcompanhante(t);

      await _preencher(t, TelaConfirmarCanal.chaveCodigo, '000000');
      await _tocarNaChave(t, TelaConfirmarCanal.chaveConfirmar);

      expect(find.byType(TelaConfirmarCanal), findsOneWidget);
      expect(find.textContaining('não conferiu'), findsOneWidget);
    });

    testWidgets('com o código certo, vem a primeira entrada sozinha', (
      WidgetTester t,
    ) async {
      await _montarFluxo(t, ultimoAcesso: UltimoAcessoEmMemoria());
      await _cadastrarComAcompanhante(t);

      await _confirmarCanal(t);

      expect(find.byType(TelaPrimeiraEntrada), findsOneWidget);
    });

    /// O coração da FR-063: a pessoa precisa **entrar**, não ser levada para
    /// dentro. Se esta tela virasse um "continuar" que já autentica, a
    /// confirmação de autonomia deixaria de existir.
    testWidgets('a primeira entrada leva ao login, e não direto para dentro', (
      WidgetTester t,
    ) async {
      await _montarFluxo(t, ultimoAcesso: UltimoAcessoEmMemoria());
      await _cadastrarComAcompanhante(t);
      await _confirmarCanal(t);

      await _tocarNaChave(t, TelaPrimeiraEntrada.chaveEntrar);

      expect(find.byType(TelaLogin), findsOneWidget);
      expect(find.byKey(TelaHub.chaveSaudacao), findsNothing);
    });

    /// A FR-012 remove a barreira de digitar o e-mail inteiro. Ela vale aqui
    /// também: a pessoa que nunca entrou é justamente quem mais precisa.
    testWidgets('o login da primeira entrada já vem com o identificador', (
      WidgetTester t,
    ) async {
      final UltimoAcessoEmMemoria memoria = UltimoAcessoEmMemoria();
      await _montarFluxo(t, ultimoAcesso: memoria);
      await _cadastrarComAcompanhante(t);
      await _confirmarCanal(t);
      await _tocarNaChave(t, TelaPrimeiraEntrada.chaveEntrar);

      expect(memoria.valor, 'ana@email.com');
    });

    testWidgets('e aí ela entra sozinha, com a própria senha', (
      WidgetTester t,
    ) async {
      await _montarFluxo(t, ultimoAcesso: UltimoAcessoEmMemoria());
      await _cadastrarComAcompanhante(t);
      await _confirmarCanal(t);
      await _tocarNaChave(t, TelaPrimeiraEntrada.chaveEntrar);

      await _preencher(t, TelaLogin.chaveIdentificador, 'ana@email.com');
      await _preencher(t, TelaLogin.chaveSenha, 'uma frase que so eu lembro');
      await _tocarNaChave(t, TelaLogin.chaveEntrar);

      expect(find.byKey(TelaHub.chaveSaudacao), findsOneWidget);
    });
  });
}

/// Cadastro assistido completo, até a tela de confirmação de canal.
Future<void> _cadastrarComAcompanhante(WidgetTester t) async {
  await _preencherComAcompanhante(t);
  await _tocarNaChave(t, TelaCadastro.chavePedirAparelho);
  await _tocarNaChave(t, TelaEntregaDoAparelho.chaveContinuar);
  await _preencher(t, TelaCadastro.chaveSenha, 'uma frase que so eu lembro');
  await _tocarNaChave(t, TelaCadastro.chaveEnviar);
  await _avancar(t, 6);
}

/// Digita o código da demonstração e confirma.
Future<void> _confirmarCanal(WidgetTester t) async {
  await _preencher(
    t,
    TelaConfirmarCanal.chaveCodigo,
    RepositorioAutenticacaoSimulado.codigoDaDemonstracao,
  );
  await _tocarNaChave(t, TelaConfirmarCanal.chaveConfirmar);
  await _avancar(t, 6);
}
