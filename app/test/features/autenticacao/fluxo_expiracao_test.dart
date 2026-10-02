import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/presentation/fluxo_autenticacao.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_login.dart';
import 'package:memora/features/casca/casca_interna.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';
import 'package:memora/l10n/textos_autenticacao.dart';
import 'package:memora/services/seguranca/limpeza_de_sessao.dart';

import 'dubles_autenticacao.dart';
import 'fluxo_dentro_da_conta.dart';

/// Repositório cuja saída só termina quando o teste manda — como a chamada de
/// rede de `encerrarSessao` no servidor real.
class _RepoLento extends RepositorioAutenticacaoSimulado {
  _RepoLento() : super(demora: Duration.zero);
  Completer<void>? saida;
  @override
  Future<void> encerrarSessao() async {
    final Completer<void>? c = saida;
    if (c != null) await c.future;
    await super.encerrarSessao();
  }
}

Future<_RepoLento> _montar(WidgetTester t) async {
  final UltimoAcessoEmMemoria ultimo = UltimoAcessoEmMemoria();
  final _RepoLento repo = _RepoLento()
    ..registrarConta(
      identificador: 'ana@email.com',
      senha: 'uma frase que so eu lembro',
      nome: 'Ana',
    );
  await t.pumpWidget(
    EscopoAparencia(
      controlador: ControladorAparencia(PreferenciaEmMemoria()),
      child: MaterialApp(
        theme: TemasMemora.claro,
        home: FluxoAutenticacao(
          repositorio: repo,
          assistente: RepositorioAssistenteSimulado(demora: Duration.zero),
          ultimoAcesso: ultimo,
          inatividade: const Duration(seconds: 3),
          avisoDeInatividade: const Duration(seconds: 1),
          limpeza: LimpezaDeSessao(
            cofre: CofreQueRegistra(),
            ultimoAcesso: ultimo,
          ),
        ),
      ),
    ),
  );
  await FluxoDentroDaConta.avancar(t);
  await FluxoDentroDaConta.tocar(
      t, find.text(TextosAutenticacao.botaoJaTenhoConta));
  for (final (Key k, String v) in <(Key, String)>[
    (TelaLogin.chaveIdentificador, 'ana@email.com'),
    (TelaLogin.chaveSenha, 'uma frase que so eu lembro'),
  ]) {
    final Finder e =
        find.descendant(of: find.byKey(k), matching: find.byType(TextField));
    await t.ensureVisible(e);
    await t.enterText(e, v);
    await t.pump();
  }
  await FluxoDentroDaConta.tocar(t, find.byKey(TelaLogin.chaveEntrar));
  await FluxoDentroDaConta.avancar(t, 6);
  expect(find.byKey(TelaHub.chaveSaudacao), findsOneWidget);
  return repo;
}

/// A expiração por inatividade (FR-017 da 001), achados da revisão da PR #38.
///
/// Os dois casos vieram de sondas do revisor, e os dois passavam pela suíte
/// sem ninguém ver: o `popUntil` do `_fecharRotasAbertas` podia ser comentado
/// sem reprovar teste nenhum, e o monitor sobrevivia à expiração quando a
/// saída demorava.
void main() {
  testWidgets('a pergunta "Fechar o Memora?" aberta na expiração não fica por '
      'cima do login', (WidgetTester t) async {
    await _montar(t);
    await t.binding.handlePopRoute();
    await FluxoDentroDaConta.avancar(t);
    expect(find.byKey(CascaInterna.chavePerguntaDeFechar), findsOneWidget,
        reason: 'o cenário pressupõe a pergunta aberta');

    await t.pump(const Duration(seconds: 2));
    await FluxoDentroDaConta.avancar(t);
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(milliseconds: 50));
    await t.pump(const Duration(seconds: 1));

    expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
    expect(find.byKey(CascaInterna.chavePerguntaDeFechar), findsNothing,
        reason: 'diálogo é rota do Navigator de fora, e não morre com a '
            'casca: é o popUntil de _fecharRotasAbertas que o tira');
  });

  testWidgets('tocar durante uma saída lenta não deixa o monitor vivo no login',
      (WidgetTester t) async {
    final _RepoLento repo = await _montar(t);
    repo.saida = Completer<void>();

    await t.pump(const Duration(seconds: 2)); // aviso
    await FluxoDentroDaConta.avancar(t);
    expect(find.text(TextosAutenticacao.tituloAvisoInatividade), findsOneWidget);
    await t.pump(const Duration(seconds: 1)); // expira; a saída fica pendente
    await FluxoDentroDaConta.avancar(t);

    // A pessoa volta no último segundo e toca "Estou aqui". A expiração já
    // começou: esse toque não pode reiniciar a contagem.
    if (t.any(find.text(TextosAutenticacao.botaoContinuar))) {
      await t.tap(find.text(TextosAutenticacao.botaoContinuar));
      await FluxoDentroDaConta.avancar(t);
    }

    repo.saida!.complete();
    repo.saida = null;
    await FluxoDentroDaConta.avancar(t, 6);
    expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);

    // Parada no login: não há sessão, e não pode haver monitor.
    for (int i = 0; i < 3; i++) {
      await t.pump(const Duration(seconds: 2));
      await FluxoDentroDaConta.avancar(t);
      expect(find.text(TextosAutenticacao.tituloAvisoInatividade), findsNothing,
          reason: 'aviso de inatividade por cima do LOGIN');
    }
  });
}
