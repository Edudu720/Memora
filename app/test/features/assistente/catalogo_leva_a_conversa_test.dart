import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/conversa_local.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/assistente/presentation/telas/tela_catalogo.dart';
import 'package:memora/features/assistente/presentation/telas/tela_conversa.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/presentation/fluxo_autenticacao.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_cadastro.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';
import 'package:memora/l10n/textos_assistente.dart';

import '../autenticacao/dubles_autenticacao.dart';

/// Tocar num serviço do catálogo leva à conversa que ensina (T077).
///
/// ## O defeito que este arquivo existe para pegar
///
/// O `FluxoAutenticacao` montava a `TelaCatalogo` sem `aoEscolher`, e todo
/// item virava um botão desabilitado — a "porta que não abre" que a FR-003
/// proíbe, nas duas portas de serviço do Hub. A tela em si estava certa; o
/// defeito estava na ligação. Por isso o teste passa pelo **fluxo real**, e não
/// só pela tela: um teste da `TelaCatalogo` com `aoEscolher` preenchido à mão
/// passaria com o defeito no ar.
///
/// ## A pergunta vai escrita, e não enviada
///
/// A conversa abre com a pergunta no campo, e quem envia é a pessoa. Nenhuma
/// conversa do limite diário é gasta sem gesto dela, e ela vê — e pode mudar —
/// o que vai ser perguntado.
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

/// Bombeia alguns quadros sem esperar quietude: o `Carregando` anima sem parar.
Future<void> _avancar(WidgetTester t, [int quadros = 4]) async {
  for (int i = 0; i < quadros; i++) {
    await t.pump(const Duration(milliseconds: 20));
  }
}

Future<void> _tocar(WidgetTester t, Finder alvo) async {
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

/// Monta o fluxo real e entra pelo cadastro, até o Hub.
Future<void> _chegarAoHub(WidgetTester t) async {
  await t.pumpWidget(
    MaterialApp(
      theme: TemasMemora.claro,
      home: FluxoAutenticacao(
        repositorio: RepositorioAutenticacaoSimulado(demora: Duration.zero),
        assistente: RepositorioAssistenteSimulado(demora: Duration.zero),
        conversaLocal: _ConversaEmMemoria.new,
        ultimoAcesso: UltimoAcessoEmMemoria(),
      ),
    ),
  );
  await _avancar(t);

  await _tocar(t, find.text('Começar minha jornada'));
  await _preencher(t, TelaCadastro.chaveNome, 'Ana');
  await _preencher(t, TelaCadastro.chaveCanal, 'ana@email.com');
  await _preencher(t, TelaCadastro.chaveSenha, 'uma frase que so eu lembro');
  await _tocar(t, find.byKey(TelaCadastro.chaveEnviar));
  await _avancar(t, 6);

  expect(find.byKey(TelaHub.chaveSaudacao), findsOneWidget);
}

String _textoDoCampo(WidgetTester t) {
  final TextField campo = t.widget<TextField>(
    find.descendant(
      of: find.byKey(TelaConversa.chaveCampo),
      matching: find.byType(TextField),
    ),
  );
  return campo.controller!.text;
}

void main() {
  for (final (String porta, String servico) in <(String, String)>[
    (TextosAssistente.portaAplicativos, 'WhatsApp'),
    (TextosAssistente.portaServicos, 'Gov.br'),
  ]) {
    testWidgets('em "$porta", tocar em $servico abre a conversa já perguntando', (
      WidgetTester t,
    ) async {
      await _chegarAoHub(t);

      await _tocar(t, find.byKey(TelaHub.chaveDaPorta(porta)));
      await _tocar(t, find.byKey(TelaCatalogo.chaveDoItem(servico)));

      expect(
        find.byType(TelaConversa),
        findsOneWidget,
        reason:
            'O item do catálogo precisa levar a algum lugar. Botão que não '
            'abre nada faz quem toca concluir que quebrou o aparelho (FR-003).',
      );
      expect(_textoDoCampo(t), TextosAssistente.perguntaSobre(servico));
      expect(
        find.text(TextosAssistente.perguntaSobre(servico)),
        findsOneWidget,
        reason:
            'A pergunta fica no campo, e não vira mensagem: quem envia é a '
            'pessoa.',
      );
    });
  }

  test('o estado vazio do catálogo não promete "em breve" (H1)', () {
    // O H1 do quickstart: nenhuma porta leva a tela vazia ou a "em breve".
    // Promessa sem data, para este público, é o mesmo que porta que não abre.
    expect(
      TextosAssistente.catalogoVazioTitulo.toLowerCase(),
      isNot(contains('breve')),
    );
    expect(
      TextosAssistente.catalogoVazioExplicacao.toLowerCase(),
      isNot(contains('breve')),
    );
  });
}
