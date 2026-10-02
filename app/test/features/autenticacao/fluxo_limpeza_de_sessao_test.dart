import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/presentation/fluxo_autenticacao.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_login.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';
import 'package:memora/l10n/textos_autenticacao.dart';
import 'package:memora/services/seguranca/cofre_de_credenciais.dart';
import 'package:memora/services/seguranca/limpeza_de_sessao.dart';

import 'dubles_autenticacao.dart';

/// A fiação da limpeza dentro do fluxo (FR-048, FR-026).
///
/// `conversa_sai_do_aparelho_test.dart` prova que a `LimpezaDeSessao` apaga o
/// que lhe entregam. Faltava provar que o `FluxoAutenticacao` **a chama** —
/// sem isto, apagar a linha `limpeza?.executar()` de `_sair` ou do caminho de
/// inatividade não reprovava nada, e a conversa ficaria no aparelho.
void main() {
  late _DadoLocalQueRegistra dado;
  late _CofreQueRegistra cofre;

  Future<void> avancar(WidgetTester t, [int quadros = 4]) async {
    for (int i = 0; i < quadros; i++) {
      await t.pump(const Duration(milliseconds: 20));
    }
  }

  /// Monta o fluxo com limpeza real e já dentro da conta.
  Future<void> montarDentro(
    WidgetTester t, {
    Duration inatividade = const Duration(minutes: 30),
    Duration aviso = const Duration(minutes: 2),
  }) async {
    dado = _DadoLocalQueRegistra();
    cofre = _CofreQueRegistra();
    final UltimoAcessoEmMemoria ultimoAcesso = UltimoAcessoEmMemoria();
    final RepositorioAutenticacaoSimulado repositorio =
        RepositorioAutenticacaoSimulado(demora: Duration.zero)..registrarConta(
          identificador: 'ana@email.com',
          senha: 'uma frase que so eu lembro',
          nome: 'Ana',
        );

    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        home: FluxoAutenticacao(
          repositorio: repositorio,
          ultimoAcesso: ultimoAcesso,
          inatividade: inatividade,
          avisoDeInatividade: aviso,
          limpeza: LimpezaDeSessao(
            cofre: cofre,
            ultimoAcesso: ultimoAcesso,
            dadosLocais: <DadoLocalDaPessoa>[dado],
          ),
        ),
      ),
    );
    await avancar(t);

    // Entra pelo login, que é o caminho de quem já tem conta.
    final Finder tenho = find.text(TextosAutenticacao.botaoJaTenhoConta);
    await t.ensureVisible(tenho);
    await t.pump();
    await t.tap(tenho);
    await avancar(t);

    await _preencher(t, TelaLogin.chaveIdentificador, 'ana@email.com');
    await _preencher(t, TelaLogin.chaveSenha, 'uma frase que so eu lembro');
    final Finder entrar = find.byKey(TelaLogin.chaveEntrar);
    await t.ensureVisible(entrar);
    await t.pump();
    await t.tap(entrar);
    await avancar(t, 6);

    expect(
      find.byKey(TelaHub.chaveSaudacao),
      findsOneWidget,
      reason: 'o cenario pressupoe a pessoa dentro da conta',
    );
    expect(dado.apagamentos, 0);
  }

  testWidgets('sair da conta apaga o dado local da pessoa', (
    WidgetTester t,
  ) async {
    await montarDentro(t);

    final Finder sair = find.byKey(TelaHub.chaveSair);
    await t.ensureVisible(sair);
    await t.pump();
    await t.tap(sair);
    await avancar(t);

    // Sair pede confirmacao (FR-025): o segundo toque e o que encerra.
    final Finder confirmar = find.text(TextosAutenticacao.botaoConfirmarSaida);
    await t.ensureVisible(confirmar);
    await t.pump();
    await t.tap(confirmar);
    await avancar(t, 6);

    expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
    expect(
      dado.apagamentos,
      1,
      reason: 'a saida deliberada precisa chamar a LimpezaDeSessao',
    );
    expect(cofre.limpezas, greaterThan(0));
  });

  testWidgets('a saída por inatividade também apaga o dado local', (
    WidgetTester t,
  ) async {
    await montarDentro(
      t,
      inatividade: const Duration(seconds: 3),
      aviso: const Duration(seconds: 1),
    );

    await t.pump(const Duration(seconds: 2));
    await avancar(t);
    await t.pump(const Duration(seconds: 1));
    await avancar(t, 8);

    expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
    expect(
      dado.apagamentos,
      1,
      reason:
          'o celular esquecido na mesa e o caso que a FR-017 existe '
          'para cobrir, e e ali que a conversa precisa sair',
    );
  });
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

class _DadoLocalQueRegistra implements DadoLocalDaPessoa {
  int apagamentos = 0;

  @override
  Future<void> apagar() async => apagamentos++;
}

class _CofreQueRegistra implements CofreDeCredenciais {
  int limpezas = 0;

  @override
  Future<void> guardarSessao({
    required String tokenAcesso,
    required String refreshToken,
  }) async {}

  @override
  Future<String?> tokenAcesso() async => null;

  @override
  Future<String?> refreshToken() async => null;

  @override
  Future<void> limpar() async => limpezas++;
}
