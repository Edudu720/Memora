import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/autenticacao/domain/autenticacao.dart';
import 'package:memora/features/autenticacao/presentation/controladores/controlador_cadastro.dart';
import 'package:memora/features/autenticacao/presentation/controladores/controlador_login.dart';
import 'package:memora/features/autenticacao/presentation/controladores/controlador_recuperacao.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_cadastro.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_confirmar_canal.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_login.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_recuperacao.dart';
import 'package:memora/l10n/textos_autenticacao.dart';

import '../../suporte/aparelhos.dart';
import '../../suporte/fonte.dart';
import 'dubles_autenticacao.dart';

/// Uma Memora por tela, também na espera (feature 013, FR-006 e FR-059, T095).
///
/// O `Carregando` traz a Memora segurando a barra. Onde a tela já tinha a dela
/// (o cartão de boas-vindas do login, o convite do cadastro e da recuperação,
/// o aviso antigolpe), a outra cede o lugar durante a espera: sem isto, a
/// pessoa veria duas — ou três — Memoras de uma vez.
///
/// Cada repositório daqui **nunca responde**: a tela fica esperando, que é o
/// momento que se mede.

Widget _app(Widget filho) => MaterialApp(theme: TemasMemora.claro, home: filho);

/// Repositório que aceita o pedido e nunca devolve a resposta.
class _RepositorioQueEspera extends RepositorioDeTeste {
  @override
  Future<ResultadoAutenticacao> entrar(DadosDeEntrada dados) =>
      Completer<ResultadoAutenticacao>().future;

  @override
  Future<ResultadoAutenticacao> cadastrar(DadosDeCadastro dados) =>
      Completer<ResultadoAutenticacao>().future;

  // A tela de confirmação pede o primeiro código sozinha, ao abrir.
  @override
  Future<ResultadoDeCanal> enviarCodigoDeCanal(String canalId) async =>
      const CanalConcluido();

  @override
  Future<ResultadoDeCanal> confirmarCanal(String canalId, String codigo) =>
      Completer<ResultadoDeCanal>().future;

  @override
  Future<ResultadoDeCanal> solicitarRecuperacao(String identificador) =>
      Completer<ResultadoDeCanal>().future;

  // A renovação automática do login: sem sessão, a tela abre o formulário.
  @override
  Future<ResultadoAutenticacao> renovarSessao() async =>
      const AutenticacaoFalhou(FalhaAutenticacao.credenciaisInvalidas);
}

/// Quantas Memoras há na tela, de qualquer pose.
Finder get _todasAsMemoras => find.byType(MemoraAnimada);

/// A Memora da espera: a que segura a barra.
Finder get _daEspera => find.byWidgetPredicate(
  (Widget w) => w is MemoraAnimada && w.expressao == PoseDaMemora.carregando,
);

void _telaDeCelular(WidgetTester t) {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Finder _entrada(Key chave) =>
    find.descendant(of: find.byKey(chave), matching: find.byType(TextField));

Future<void> _digitar(WidgetTester t, Key chave, String valor) async {
  await t.ensureVisible(_entrada(chave));
  await t.enterText(_entrada(chave), valor);
  await t.pump();
}

Future<void> _tocar(WidgetTester t, Key chave) async {
  await t.ensureVisible(find.byKey(chave));
  await t.tap(find.byKey(chave));
  await t.pump(const Duration(milliseconds: 10));
  await t.pump(const Duration(milliseconds: 10));
}

void main() {
  setUpAll(carregarAtkinson);

  testWidgets('login: a Memora do cartão cede à da espera', (
    WidgetTester t,
  ) async {
    _telaDeCelular(t);
    final ControladorLogin c = ControladorLogin(
      _RepositorioQueEspera(),
      UltimoAcessoEmMemoria(),
    );
    addTearDown(c.dispose);
    await t.pumpWidget(
      _app(TelaLogin(controlador: c, aoEntrar: (PessoaAutenticada _) {})),
    );
    await t.pump(const Duration(milliseconds: 10));
    await t.pump(const Duration(milliseconds: 10));

    expect(
      _todasAsMemoras,
      findsOneWidget,
      reason: 'Antes de esperar, a Memora do cartão está na tela.',
    );
    expect(_daEspera, findsNothing);

    await _digitar(t, TelaLogin.chaveIdentificador, 'ana@email.com');
    await _digitar(t, TelaLogin.chaveSenha, 'uma frase que so eu lembro');
    await _tocar(t, TelaLogin.chaveEntrar);

    expect(c.enviando, isTrue, reason: 'O repositório nunca responde.');
    expect(_daEspera, findsOneWidget);
    expect(
      _todasAsMemoras,
      findsOneWidget,
      reason: 'FR-006: durante a espera, só a Memora da barra fica.',
    );
  });

  testWidgets('cadastro: a Memora do convite cede à da espera', (
    WidgetTester t,
  ) async {
    _telaDeCelular(t);
    final ControladorCadastro c = ControladorCadastro(_RepositorioQueEspera());
    addTearDown(c.dispose);
    await t.pumpWidget(
      _app(TelaCadastro(controlador: c, aoConcluir: (PessoaAutenticada _) {})),
    );

    expect(_todasAsMemoras, findsOneWidget);
    expect(_daEspera, findsNothing);

    await _digitar(t, TelaCadastro.chaveNome, 'Ana');
    await _digitar(t, TelaCadastro.chaveCanal, 'ana@email.com');
    await _digitar(t, TelaCadastro.chaveSenha, 'uma frase que so eu lembro');
    await _tocar(t, TelaCadastro.chaveEnviar);

    expect(c.enviando, isTrue, reason: 'O repositório nunca responde.');
    expect(_daEspera, findsOneWidget);
    expect(
      _todasAsMemoras,
      findsOneWidget,
      reason: 'FR-006: durante a espera, só a Memora da barra fica.',
    );
  });

  testWidgets(
    'recuperação: nem o convite nem o aviso antigolpe mostram a Memora '
    'durante a espera',
    (WidgetTester t) async {
      _telaDeCelular(t);
      final ControladorRecuperacao c = ControladorRecuperacao(
        _RepositorioQueEspera(),
      );
      addTearDown(c.dispose);
      await t.pumpWidget(
        _app(
          TelaRecuperacao(controlador: c, aoConcluir: (PessoaAutenticada _) {}),
        ),
      );

      expect(
        _todasAsMemoras,
        findsNWidgets(2),
        reason: 'Sem espera: a do aviso antigolpe e a do convite.',
      );

      await _digitar(t, TelaRecuperacao.chaveIdentificador, 'ana@email.com');
      await _tocar(t, TelaRecuperacao.chavePedirCodigo);

      expect(c.enviando, isTrue, reason: 'O repositório nunca responde.');
      expect(_daEspera, findsOneWidget);
      expect(
        _todasAsMemoras,
        findsOneWidget,
        reason: 'FR-006: durante a espera, só a Memora da barra fica.',
      );
      // O texto do aviso nunca sai (FR-023): só o rosto.
      expect(
        find.text(TextosAutenticacao.tituloAvisoAntigolpe),
        findsOneWidget,
      );
    },
  );

  group('A espera cabe em toda a matriz (aparelho x escala)', () {
    // A Memora (72 dp) mais a frase, dentro das telas de formulário, a 200%:
    // a espera pode crescer, mas nunca estourar nem sair do alcance.
    for (final Combinacao c in matriz(
      temas: <MemoraTemaId>[MemoraTemaId.claro],
    )) {
      testWidgets('login enviando — ${nomeDa(c)}', (WidgetTester t) async {
        vestir(t, c.aparelho);
        final ControladorLogin ctrl = ControladorLogin(
          _RepositorioQueEspera(),
          UltimoAcessoEmMemoria(),
        );
        addTearDown(ctrl.dispose);
        await t.pumpWidget(
          naCombinacao(
            c,
            TelaLogin(controlador: ctrl, aoEntrar: (PessoaAutenticada _) {}),
          ),
        );
        await t.pump(const Duration(milliseconds: 10));
        await t.pump(const Duration(milliseconds: 10));
        await _digitar(t, TelaLogin.chaveIdentificador, 'ana@email.com');
        await _digitar(t, TelaLogin.chaveSenha, 'uma frase que so eu lembro');
        await _tocar(t, TelaLogin.chaveEntrar);

        expect(ctrl.enviando, isTrue);
        expect(t.takeException(), isNull);
        await exigirAlcancavel(
          t,
          find.byType(Carregando),
          aparelho: c.aparelho,
          contexto: 'login enviando, ${nomeDa(c)}',
        );
        expect(_todasAsMemoras, findsOneWidget);
      });

      testWidgets('cadastro enviando — ${nomeDa(c)}', (WidgetTester t) async {
        vestir(t, c.aparelho);
        final ControladorCadastro ctrl = ControladorCadastro(
          _RepositorioQueEspera(),
        );
        addTearDown(ctrl.dispose);
        await t.pumpWidget(
          naCombinacao(
            c,
            TelaCadastro(
              controlador: ctrl,
              aoConcluir: (PessoaAutenticada _) {},
            ),
          ),
        );
        await _digitar(t, TelaCadastro.chaveNome, 'Ana');
        await _digitar(t, TelaCadastro.chaveCanal, 'ana@email.com');
        await _digitar(
          t,
          TelaCadastro.chaveSenha,
          'uma frase que so eu lembro',
        );
        await _tocar(t, TelaCadastro.chaveEnviar);

        expect(ctrl.enviando, isTrue);
        expect(t.takeException(), isNull);
        await exigirAlcancavel(
          t,
          find.byType(Carregando),
          aparelho: c.aparelho,
          contexto: 'cadastro enviando, ${nomeDa(c)}',
        );
        expect(_todasAsMemoras, findsOneWidget);
      });
    }
  });

  testWidgets('confirmar o canal: a Memora do cartão cede à da espera', (
    WidgetTester t,
  ) async {
    _telaDeCelular(t);
    await t.pumpWidget(
      _app(
        TelaConfirmarCanal(
          repositorio: _RepositorioQueEspera(),
          canalId: 'canal-1',
          canalVisivel: 'a***@email.com',
          aoConfirmar: () {},
        ),
      ),
    );

    expect(_todasAsMemoras, findsOneWidget);
    expect(_daEspera, findsNothing);

    await _digitar(t, TelaConfirmarCanal.chaveCodigo, '123456');
    await _tocar(t, TelaConfirmarCanal.chaveConfirmar);

    expect(_daEspera, findsOneWidget);
    expect(
      _todasAsMemoras,
      findsOneWidget,
      reason: 'FR-006: durante a espera, só a Memora da barra fica.',
    );
  });
}
