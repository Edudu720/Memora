import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/aprendizado/data/guias/guias.dart';
import 'package:memora/features/aprendizado/data/progresso_de_aprendizado.dart';
import 'package:memora/features/aprendizado/domain/guia.dart';
import 'package:memora/features/assistente/data/conversa_local.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/assistente/presentation/telas/tela_catalogo.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/presentation/fluxo_autenticacao.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_cadastro.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';
import 'package:memora/features/inicio/presentation/tela_inicio.dart';
import 'package:memora/l10n/textos_assistente.dart';
import 'package:memora/l10n/textos_guias.dart';

import '../../suporte/aceite_em_memoria.dart';
import '../../suporte/aparelhos.dart';
import '../autenticacao/dubles_autenticacao.dart';

class _ProgressoEmMemoria extends ProgressoDeAprendizado {
  final Map<String, Map<String, int>> _contagens =
      <String, Map<String, int>>{};
  final StreamController<void> _ctrl = StreamController<void>.broadcast();

  _ProgressoEmMemoria() : super(diretorio: () async => Directory.systemTemp);

  @override
  Stream<void> get alteracoes => _ctrl.stream;

  @override
  Future<void> registrarConclusao({
    required String idDaConta,
    required String chave,
  }) async {
    final Map<String, int> daConta =
        _contagens.putIfAbsent(idDaConta, () => <String, int>{});
    daConta[chave] = (daConta[chave] ?? 0) + 1;
    _ctrl.add(null);
  }

  @override
  Future<Map<String, int>> concluidos(String idDaConta) async =>
      Map<String, int>.from(_contagens[idDaConta] ?? const <String, int>{});

  @override
  Future<void> apagar() async {
    _contagens.clear();
    _ctrl.add(null);
  }
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
  await t.pump(const Duration(milliseconds: 400));
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

void main() {
  group('Selo "Concluído" nos módulos do Catálogo (020)', () {
    testWidgets(
      'marca guia direto concluído como readOnly e ignora seccionado incompleto',
      (WidgetTester t) async {
        final SemanticsHandle h = t.ensureSemantics();
        final _ProgressoEmMemoria prog = _ProgressoEmMemoria();
        await prog.registrarConclusao(idDaConta: 'ana', chave: 'whatsapp');

        final Guia govBr = guiaDe('gov-br')!;
        // Conclui só parte das seções do Gov.br.
        for (final SecaoDoGuia s in govBr.secoes.take(2)) {
          await prog.registrarConclusao(
            idDaConta: 'ana',
            chave: 'gov-br:${s.chave}',
          );
        }

        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: TelaCatalogo(
              repositorio: RepositorioAssistenteSimulado(demora: Duration.zero),
              categoria: CategoriaDoServico.cotidiano,
              progresso: prog,
              idDaConta: 'ana',
            ),
          ),
        );
        await _avancar(t);

        final Finder seloWhatsapp = find.byKey(
          TelaCatalogo.chaveConcluidoDoItem('whatsapp'),
        );
        expect(seloWhatsapp, findsOneWidget);
        expect(
          find.descendant(
            of: seloWhatsapp,
            matching: find.text(TextosGuias.moduloConcluido),
          ),
          findsOneWidget,
        );
        expect(
          t.getSemantics(seloWhatsapp),
          isSemantics(isButton: false, hasTapAction: false, label: 'Concluído'),
        );
        expect(
          find.byKey(TelaCatalogo.chaveConcluidoDoItem('youtube')),
          findsNothing,
        );

        // Muda para Serviços sociais: Gov.br incompleto NÃO é marcado.
        await t.tap(find.text('Serviços sociais'));
        await _avancar(t);
        expect(
          find.byKey(TelaCatalogo.chaveConcluidoDoItem('gov-br')),
          findsNothing,
        );

        // Ao concluir as seções restantes do Gov.br, o catálogo atualiza ao vivo.
        for (final SecaoDoGuia s in govBr.secoes.skip(2)) {
          await prog.registrarConclusao(
            idDaConta: 'ana',
            chave: 'gov-br:${s.chave}',
          );
        }
        await _avancar(t);

        expect(
          find.byKey(TelaCatalogo.chaveConcluidoDoItem('gov-br')),
          findsOneWidget,
        );

        // Ao apagar na saída, a marcação desaparece.
        await prog.apagar();
        await _avancar(t);
        expect(
          find.byKey(TelaCatalogo.chaveConcluidoDoItem('gov-br')),
          findsNothing,
        );
        h.dispose();
      },
    );

    testWidgets(
      'FluxoAutenticacao conecta progresso ao catálogo e reflete conclusão ao voltar do passo a passo',
      (WidgetTester t) async {
        final _ProgressoEmMemoria prog = _ProgressoEmMemoria();
        final Guia youtube = guiaDe('youtube')!;

        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: FluxoAutenticacao(
              repositorio: RepositorioAutenticacaoSimulado(demora: Duration.zero),
              assistente: RepositorioAssistenteSimulado(demora: Duration.zero),
              conversaLocal: _ConversaEmMemoria.new,
              aceiteDoAviso: AceiteEmMemoria(),
              ultimoAcesso: UltimoAcessoEmMemoria(),
              progresso: prog,
            ),
          ),
        );
        await _avancar(t);

        await _tocar(t, find.text('Começar minha jornada'));
        await _preencher(t, TelaCadastro.chaveNome, 'Ana');
        await _preencher(t, TelaCadastro.chaveCanal, 'ana@email.com');
        await _preencher(
          t,
          TelaCadastro.chaveSenha,
          'uma frase que so eu lembro',
        );
        await _tocar(t, find.byKey(TelaCadastro.chaveEnviar));
        await _avancar(t, 6);

        await _tocar(t, find.byKey(TelaInicio.chaveVerTudo));
        await _tocar(
          t,
          find.byKey(TelaHub.chaveDaPorta(TextosAssistente.portaAplicativos)),
        );

        expect(
          find.byKey(TelaCatalogo.chaveConcluidoDoItem('youtube')),
          findsNothing,
        );

        // Entra no passo a passo do YouTube e percorre até o último passo.
        await _tocar(t, find.byKey(TelaCatalogo.chaveDoItem('YouTube')));
        for (int i = 0; i < youtube.passos.length - 1; i++) {
          await _tocar(t, find.byKey(PassoIlustrado.chaveContinuar));
        }

        // Volta ao catálogo pela ação de conclusão no último passo.
        await _tocar(t, find.text('Voltar ao início'));

        expect(
          find.byKey(TelaCatalogo.chaveConcluidoDoItem('youtube')),
          findsOneWidget,
        );
      },
    );

    for (final Size aparelho in aparelhos) {
      testWidgets(
        'catálogo com selo "Concluído" não estoura em ${nomeDo(aparelho)} a 200%',
        (WidgetTester t) async {
          t.view.physicalSize = aparelho;
          t.view.devicePixelRatio = 1.0;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);

          final _ProgressoEmMemoria prog = _ProgressoEmMemoria();
          await prog.registrarConclusao(idDaConta: 'ana', chave: 'whatsapp');

          await t.pumpWidget(
            MaterialApp(
              theme: TemasMemora.altoContraste,
              home: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
                child: TelaCatalogo(
                  repositorio: RepositorioAssistenteSimulado(
                    demora: Duration.zero,
                  ),
                  categoria: CategoriaDoServico.cotidiano,
                  progresso: prog,
                  idDaConta: 'ana',
                ),
              ),
            ),
          );
          await _avancar(t);

          expect(t.takeException(), isNull);
          expect(
            find.byKey(TelaCatalogo.chaveConcluidoDoItem('whatsapp')),
            findsOneWidget,
          );
        },
      );
    }
  });
}
