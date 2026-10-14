import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/aprendizado/data/progresso_de_aprendizado.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/presentation/fluxo_autenticacao.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_login.dart';
import 'package:memora/features/inicio/presentation/tela_inicio.dart';
import 'package:memora/l10n/textos_autenticacao.dart';
import 'package:memora/services/seguranca/cofre_de_credenciais.dart';
import 'package:memora/services/seguranca/limpeza_de_sessao.dart';

import 'dubles_autenticacao.dart';
import 'fluxo_dentro_da_conta.dart';

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
    List<DadoLocalDaPessoa> maisDados = const <DadoLocalDaPessoa>[],
  }) async {
    dado = _DadoLocalQueRegistra();
    cofre = _CofreQueRegistra();
    final UltimoAcessoEmMemoria ultimoAcesso = UltimoAcessoEmMemoria();
    final RepositorioAutenticacaoSimulado repositorio =
        RepositorioAutenticacaoSimulado(demora: Duration.zero)
          ..registrarConta(
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
            dadosLocais: <DadoLocalDaPessoa>[dado, ...maisDados],
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

    expect(find.byKey(TelaInicio.chaveSaudacao), findsOneWidget,
        reason: 'o cenario pressupoe a pessoa dentro da conta');
    expect(dado.apagamentos, 0);
  }

  testWidgets('sair da conta apaga o dado local da pessoa',
      (WidgetTester t) async {
    await montarDentro(t);

    // O unico "Sair" fica em Ajustes (FR-019 da feature 004).
    await FluxoDentroDaConta.tocarEmSair(t);

    // Sair pede confirmacao (FR-025): o segundo toque e o que encerra.
    final Finder confirmar = find.text(TextosAutenticacao.botaoConfirmarSaida);
    await t.ensureVisible(confirmar);
    await t.pump();
    await t.tap(confirmar);
    await avancar(t, 6);

    expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
    expect(dado.apagamentos, 1,
        reason: 'a saida deliberada precisa chamar a LimpezaDeSessao');
    expect(cofre.limpezas, greaterThan(0));
  });

  testWidgets('a saída por inatividade também apaga o dado local',
      (WidgetTester t) async {
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
    expect(dado.apagamentos, 1,
        reason: 'o celular esquecido na mesa e o caso que a FR-017 existe '
            'para cobrir, e e ali que a conversa precisa sair');
  });

  group('o progresso de aprendizado sai em toda saída (FR-042b)', () {
    late Directory pasta;
    late ProgressoDeAprendizado progresso;

    File arquivo() =>
        File('${pasta.path}/${ProgressoDeAprendizado.nomeDoArquivo}');

    /// Prepara o progresso no disco de verdade. Disco real só anda dentro de
    /// `runAsync`: o relógio do `testWidgets` é falso.
    Future<void> guardarProgresso(WidgetTester t) async {
      await t.runAsync(() async {
        pasta = Directory.systemTemp.createTempSync('memora_fluxo_progresso_');
        progresso = ProgressoDeAprendizado(diretorio: () async => pasta);
        await progresso.registrarConclusao(idDaConta: 'ana', chave: 'tiktok');
      });
      addTearDown(() {
        if (pasta.existsSync()) pasta.deleteSync(recursive: true);
      });
      expect(arquivo().existsSync(), isTrue,
          reason: 'o cenario pressupoe progresso guardado antes da saida');
    }

    /// Dá ao disco real o tempo de terminar, bombeando quadros entre uma
    /// espera e outra para as continuações do relógio falso andarem.
    Future<void> esperarSumir(WidgetTester t) async {
      for (int i = 0; i < 100 && arquivo().existsSync(); i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await t.pump(const Duration(milliseconds: 20));
      }
      // O arquivo some antes de o `delete()` avisar que terminou: sem estas
      // voltas a mais, a saida ainda esta esperando por esse aviso.
      for (int i = 0; i < 3; i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await t.pump(const Duration(milliseconds: 20));
      }
    }

    testWidgets('sair da conta o apaga, mesmo quando outro dado local falha',
        (WidgetTester t) async {
      await guardarProgresso(t);
      await montarDentro(
        t,
        maisDados: <DadoLocalDaPessoa>[_QueFalha(), progresso],
      );

      await FluxoDentroDaConta.tocarEmSair(t);
      final Finder confirmar =
          find.text(TextosAutenticacao.botaoConfirmarSaida);
      await t.ensureVisible(confirmar);
      await t.pump();
      await t.tap(confirmar);
      await avancar(t, 6);
      await esperarSumir(t);

      expect(arquivo().existsSync(), isFalse,
          reason: 'o progresso fica para trás se a saida parar no dado que '
              'falhou');
    });

    testWidgets('a saída por inatividade também o apaga, mesmo com falha',
        (WidgetTester t) async {
      await guardarProgresso(t);
      await montarDentro(
        t,
        inatividade: const Duration(seconds: 3),
        aviso: const Duration(seconds: 1),
        maisDados: <DadoLocalDaPessoa>[_QueFalha(), progresso],
      );

      await t.pump(const Duration(seconds: 2));
      await avancar(t);
      await t.pump(const Duration(seconds: 1));
      await avancar(t, 8);
      await esperarSumir(t);
      await avancar(t, 6);

      expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
      expect(arquivo().existsSync(), isFalse,
          reason: 'celular esquecido na mesa: o que a pessoa ainda nao sabe '
              'fazer nao pode ficar para quem pegar o aparelho');
    });
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

class _QueFalha implements DadoLocalDaPessoa {
  @override
  Future<void> apagar() async => throw StateError('disco cheio');
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
