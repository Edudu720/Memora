import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/presentation/fluxo_autenticacao.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_cadastro.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_login.dart';
import 'package:memora/l10n/textos_autenticacao.dart';

import 'dubles_autenticacao.dart';

/// Avança alguns quadros sem esperar quietude.
///
/// `pumpAndSettle` não serve aqui: o `Carregando` anima sem parar, e a espera
/// por uma árvore parada nunca terminaria.
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

/// Toca por chave, e nao por texto.
///
/// Mais estavel: o rotulo de um botao muda quando alguem melhora a frase, e um
/// teste que quebra por isso vira ruido. Foi o que aconteceu quando o Hub
/// substituiu a tela provisoria e "Sair da conta" virou "Sair da minha conta".
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
  Duration inatividade = const Duration(minutes: 30),
  Duration aviso = const Duration(minutes: 2),
}) async {
  await t.pumpWidget(
    MaterialApp(
      theme: TemasMemora.claro,
      home: FluxoAutenticacao(
        repositorio: RepositorioAutenticacaoSimulado(demora: Duration.zero),
        ultimoAcesso: ultimoAcesso,
        inatividade: inatividade,
        avisoDeInatividade: aviso,
      ),
    ),
  );
  await _avancar(t);
}

/// Faz o cadastro completo, do botão de começar até estar dentro.
Future<void> _cadastrar(WidgetTester t) async {
  await _tocarNoTexto(t, 'Começar minha jornada');

  await _preencher(t, TelaCadastro.chaveNome, 'Ana');
  await _preencher(t, TelaCadastro.chaveCanal, 'ana@email.com');
  await _preencher(t, TelaCadastro.chaveSenha, 'uma frase que so eu lembro');

  final Finder enviar = find.byKey(TelaCadastro.chaveEnviar);
  await t.ensureVisible(enviar);
  await t.tap(enviar);
  await _avancar(t, 6);
}

void main() {
  group('Do cadastro ao login — US1 e US2 juntas', () {
    testWidgets('cadastrar já conta como acesso, e o login vem preenchido',
        (WidgetTester t) async {
      final UltimoAcessoEmMemoria memoria = UltimoAcessoEmMemoria();
      await _montarFluxo(t, ultimoAcesso: memoria);

      await _cadastrar(t);
      expect(
        find.byKey(TelaHub.chaveSaudacao),
        findsOneWidget,
        reason: 'A FR-009 diz que a pessoa entra direto ao cadastrar, sem '
            'passar pelo login.',
      );

      expect(
        memoria.valor,
        'ana@email.com',
        reason: 'Cadastrar É um acesso bem-sucedido. Não lembrar o canal aqui '
            'obrigaria a pessoa a digitar o e-mail inteiro no primeiro login, '
            'que é a barreira que a FR-012 existe para remover.',
      );

      await _tocarNaChave(t, TelaHub.chaveSair);
      await _tocarNoTexto(t, TextosAutenticacao.botaoConfirmarSaida);
      await _avancar(t, 6);

      expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
      expect(
        find.text(TextosAutenticacao.identificadorLembrado),
        findsOneWidget,
        reason: 'Sair e voltar precisa deixar só a senha faltando — é o '
            'cenário 2 da US2.',
      );
    });

    testWidgets('sair encerra a sessão, e a renovação automática não a ressuscita',
        (WidgetTester t) async {
      await _montarFluxo(t, ultimoAcesso: UltimoAcessoEmMemoria());

      await _cadastrar(t);
      await _tocarNaChave(t, TelaHub.chaveSair);
      await _tocarNoTexto(t, TextosAutenticacao.botaoConfirmarSaida);
      await _avancar(t, 6);

      expect(
        find.byKey(TelaLogin.chaveEntrar),
        findsOneWidget,
        reason: 'Sem apagar a credencial local, a renovação automática do '
            'ControladorLogin colocaria a pessoa de volta dentro no mesmo '
            'instante — e o botão de sair seria enfeite.',
      );
    });
  });

  group('Expiração por inatividade — FR-017', () {
    testWidgets('avisa antes e depois devolve a pessoa ao login',
        (WidgetTester t) async {
      await _montarFluxo(
        t,
        ultimoAcesso: UltimoAcessoEmMemoria(),
        inatividade: const Duration(seconds: 3),
        aviso: const Duration(seconds: 1),
      );

      await _cadastrar(t);
      expect(find.byKey(TelaHub.chaveSaudacao), findsOneWidget);

      // Dois segundos parada: chega a hora do aviso.
      await t.pump(const Duration(seconds: 2));
      await _avancar(t);

      expect(
        find.text(TextosAutenticacao.tituloAvisoInatividade),
        findsOneWidget,
        reason: 'Sessão que cai sem avisar é indistinguível de defeito.',
      );

      // Mais um segundo sem responder: a sessão cai.
      await t.pump(const Duration(seconds: 1));
      await _avancar(t, 8);

      expect(
        find.text(TextosAutenticacao.tituloAvisoInatividade),
        findsNothing,
        reason: 'Deixar o aviso aberto por cima do login ofereceria um "pode '
            'continuar" que já não continua nada.',
      );
      expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
    });

    testWidgets('responder ao aviso mantém a pessoa dentro',
        (WidgetTester t) async {
      await _montarFluxo(
        t,
        ultimoAcesso: UltimoAcessoEmMemoria(),
        inatividade: const Duration(seconds: 3),
        aviso: const Duration(seconds: 1),
      );

      await _cadastrar(t);
      await t.pump(const Duration(seconds: 2));
      await _avancar(t);
      expect(find.text(TextosAutenticacao.tituloAvisoInatividade),
          findsOneWidget);

      await _tocarNoTexto(t, TextosAutenticacao.botaoContinuar);
      await _avancar(t, 6);

      // Passa o prazo que teria expirado se o botão não valesse nada.
      await t.pump(const Duration(seconds: 2));
      await _avancar(t);

      expect(
        find.byKey(TelaHub.chaveSaudacao),
        findsOneWidget,
        reason: 'Expirar depois de a pessoa dizer que está ali torna o botão '
            'do aviso uma mentira.',
      );
    });
  });
}
