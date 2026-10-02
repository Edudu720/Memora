import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/conversa_local.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/presentation/fluxo_autenticacao.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_login.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';
import 'package:memora/l10n/textos_autenticacao.dart';
import 'package:memora/services/seguranca/cofre_de_credenciais.dart';
import 'package:memora/services/seguranca/limpeza_de_sessao.dart';

import 'dubles_autenticacao.dart';

/// Monta o `FluxoAutenticacao` real, com assistente e limpeza, e entra na
/// conta pelo login. Compartilhado pelos testes que exercitam o fluxo por
/// dentro (saida com confirmacao, rotas e inatividade).
class FluxoDentroDaConta {
  /// Dado local que registra quantas vezes a limpeza o apagou.
  final DadoLocalQueRegistra dado = DadoLocalQueRegistra();

  /// Cofre que registra as limpezas.
  final CofreQueRegistra cofre = CofreQueRegistra();

  /// Bombeia alguns quadros sem esperar quietude: o `Carregando` anima sem
  /// parar e `pumpAndSettle` travaria.
  static Future<void> avancar(WidgetTester t, [int quadros = 4]) async {
    for (int i = 0; i < quadros; i++) {
      await t.pump(const Duration(milliseconds: 20));
    }
  }

  /// Rola ate o alvo, toca e bombeia alguns quadros.
  static Future<void> tocar(WidgetTester t, Finder alvo) async {
    await t.ensureVisible(alvo);
    await t.pump();
    await t.tap(alvo);
    await avancar(t);
  }

  /// Monta o fluxo e deixa a pessoa no Hub.
  Future<void> montar(
    WidgetTester t, {
    Duration inatividade = const Duration(minutes: 30),
    Duration aviso = const Duration(minutes: 2),
  }) async {
    final UltimoAcessoEmMemoria ultimoAcesso = UltimoAcessoEmMemoria();
    final RepositorioAutenticacaoSimulado repositorio =
        RepositorioAutenticacaoSimulado(demora: Duration.zero)..registrarConta(
          identificador: 'ana@email.com',
          senha: 'uma frase que so eu lembro',
          nome: 'Ana',
        );

    // O `EscopoAparencia` em volta, como no `main.dart` de verdade: sem ele, a
    // tela de aparência — que a casca abre em Ajustes — não encontra quem a
    // controla. Um arnês que monta menos que o aplicativo testa menos que ele.
    await t.pumpWidget(
      EscopoAparencia(
        controlador: ControladorAparencia(PreferenciaEmMemoria()),
        child: MaterialApp(
          theme: TemasMemora.claro,
          home: FluxoAutenticacao(
            repositorio: repositorio,
            assistente: RepositorioAssistenteSimulado(demora: Duration.zero),
            conversaLocal: _ConversaEmMemoria.new,
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
      ),
    );
    await avancar(t);

    await tocar(t, find.text(TextosAutenticacao.botaoJaTenhoConta));
    await _preencher(t, TelaLogin.chaveIdentificador, 'ana@email.com');
    await _preencher(t, TelaLogin.chaveSenha, 'uma frase que so eu lembro');
    await tocar(t, find.byKey(TelaLogin.chaveEntrar));
    await avancar(t, 6);

    expect(
      find.byKey(TelaHub.chaveSaudacao),
      findsOneWidget,
      reason: 'o cenario pressupoe a pessoa dentro da conta',
    );
    expect(dado.apagamentos, 0);
  }
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

class _ConversaEmMemoria implements ConversaLocal {
  List<MensagemDaConversa> _guardadas = <MensagemDaConversa>[];

  @override
  Future<List<MensagemDaConversa>> ler() async => _guardadas;

  @override
  Future<void> guardar(List<MensagemDaConversa> mensagens) async {
    _guardadas = List<MensagemDaConversa>.from(mensagens);
  }

  @override
  Future<void> apagar() async => _guardadas = <MensagemDaConversa>[];
}

/// Dado local que so conta quantas vezes foi apagado.
class DadoLocalQueRegistra implements DadoLocalDaPessoa {
  /// Quantas vezes `apagar` rodou.
  int apagamentos = 0;

  @override
  Future<void> apagar() async => apagamentos++;
}

/// Cofre que so conta quantas vezes foi limpo.
class CofreQueRegistra implements CofreDeCredenciais {
  /// Quantas vezes `limpar` rodou.
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

/// Preferência de aparência que não toca o disco: dentro de `testWidgets`,
/// I/O de arquivo real nunca completa.
class PreferenciaEmMemoria implements RepositorioPreferenciaAparencia {
  @override
  Future<PreferenciaAparencia> carregar() async => PreferenciaAparencia.padrao;

  @override
  Future<void> salvar(PreferenciaAparencia preferencia) async {}
}
