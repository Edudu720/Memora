import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/abridor_de_aplicativo.dart';
import 'package:memora/features/assistente/data/conversa_local.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/assistente/presentation/controladores/controlador_conversa.dart';
import 'package:memora/features/assistente/presentation/telas/tela_conversa.dart';
import 'package:memora/l10n/textos_assistente.dart';
import '../../suporte/aceite_em_memoria.dart';
import '../../suporte/escrita_da_resposta.dart';

/// Cenarios H7 e H8 — confirmar antes, e avisar antes de sair (T056).
///
/// ## O que estes testes protegem
///
/// A FR-015 exige que a pessoa saiba **o que vai acontecer** antes de qualquer
/// coisa acontecer, e a FR-021 exige aviso antes de sair do Memora. Sao duas
/// regras diferentes que, nesta tela, moram na mesma frase — e por isso podem
/// ser perdidas juntas por quem "melhorar" o texto sem saber.
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

void main() {
  late _ConversaEmMemoria local;
  late AbridorDeAplicativoSimulado abridor;
  late RepositorioAssistenteSimulado assistente;

  setUp(() {
    local = _ConversaEmMemoria();
    abridor = AbridorDeAplicativoSimulado();
    assistente = RepositorioAssistenteSimulado(demora: Duration.zero);
  });

  ControladorConversa criarControlador() =>
      ControladorConversa(
        assistente,
        local,
        aceite: AceiteEmMemoria(),
        abridor: abridor,
      );

  Future<void> avancar(WidgetTester t) async {
    for (int quadro = 0; quadro < 6; quadro++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> montar(WidgetTester t, ControladorConversa c) async {
    await t.pumpWidget(
      MaterialApp(theme: TemasMemora.claro, home: TelaConversa(controlador: c)),
    );
    await avancar(t);
  }

  Future<void> perguntar(WidgetTester t, String texto) async {
    await t.enterText(find.byKey(TelaConversa.chaveCampo), texto);
    await avancar(t);
    final Finder enviar = find.byKey(TelaConversa.chaveEnviar);
    await t.ensureVisible(enviar);
    await t.tap(enviar);
    await avancar(t);
    await esperarAEscrita(t);
  }

  /// Confirma a acao e deixa a tela reagir.
  ///
  /// Funciona com `await` direto porque `RepositorioAssistenteSimulado` nao
  /// cria timer quando `demora` e zero. Sem esse cuidado, um
  /// `Future.delayed(Duration.zero)` dentro de `testWidgets` nunca completa —
  /// o relogio e falso, e o `await` impede que alguem bombeie quadros. Custou
  /// duas rodadas desta feature antes de ser corrigido na raiz.
  Future<void> confirmar(WidgetTester t, ControladorConversa c) async {
    await c.confirmarAcao();
    await avancar(t);
  }

  /// Chega ate a oferta de abrir, declarando dificuldade.
  Future<ControladorConversa> chegarNaOferta(WidgetTester t) async {
    final ControladorConversa c = criarControlador();
    addTearDown(c.dispose);
    await montar(t, c);
    await perguntar(t, 'nao consegui achar');
    expect(c.acaoOferecida, isNotNull, reason: 'a oferta nao apareceu');
    return c;
  }

  group('H7 — nada acontece antes da confirmacao (FR-015)', () {
    testWidgets('a oferta esta na tela e NADA foi aberto ainda',
        (WidgetTester t) async {
      await chegarNaOferta(t);

      // O portao: a acao esta autorizada pelo servidor, e mesmo assim nenhum
      // aplicativo foi aberto. Autorizado nao e consentido.
      expect(abridor.abertos, isEmpty);
      expect(find.byKey(TelaConversa.chaveConfirmarAbrir), findsOneWidget);
    });

    testWidgets('a pergunta diz exatamente o que vai acontecer',
        (WidgetTester t) async {
      final ControladorConversa c = await chegarNaOferta(t);
      final String nome = c.acaoOferecida!.nomeExibido;

      expect(
        find.text(TextosAssistente.pedidoDeAbertura(nome)),
        findsOneWidget,
      );
    });

    testWidgets('recusar nao abre nada, e a oferta some (FR-016)',
        (WidgetTester t) async {
      final ControladorConversa c = await chegarNaOferta(t);

      c.recusarAcao();
      await avancar(t);

      expect(abridor.abertos, isEmpty);
      expect(c.acaoOferecida, isNull);
      expect(find.byKey(TelaConversa.chaveConfirmarAbrir), findsNothing);
    });

    testWidgets('confirmar abre o aplicativo certo', (WidgetTester t) async {
      final ControladorConversa c = await chegarNaOferta(t);
      final String pacote = c.acaoOferecida!.identificadorAndroid;

      await confirmar(t, c);

      expect(abridor.abertos, <String>[pacote]);
    });
  });

  group('H8 — a pessoa e avisada antes de sair do Memora (FR-021)', () {
    testWidgets('o pedido de confirmacao avisa que ela sai do aplicativo',
        (WidgetTester t) async {
      final ControladorConversa c = await chegarNaOferta(t);
      final String pergunta =
          TextosAssistente.pedidoDeAbertura(c.acaoOferecida!.nomeExibido);

      // A FR-021 vive dentro da frase da FR-015. Quem reescrever o texto sem
      // saber disso derruba uma exigencia do Principio II sem perceber.
      expect(pergunta.toLowerCase(), contains('sair do memora'));
      expect(find.text(pergunta), findsOneWidget);
    });
  });

  group('FR-019 — o caminho percorrido aparece depois', () {
    testWidgets('a Memora mostra o caminho que fez', (WidgetTester t) async {
      final ControladorConversa c = await chegarNaOferta(t);
      final String nome = c.acaoOferecida!.nomeExibido;

      await confirmar(t, c);

      // Se a pessoa so vê o resultado, ela aprendeu que a Memora resolve.
      expect(
        c.mensagens.last.texto,
        TextosAssistente.caminhoPercorrido(nome),
      );
    });

    testWidgets('a acao executada e registrada (FR-020)',
        (WidgetTester t) async {
      final ControladorConversa c = await chegarNaOferta(t);

      await confirmar(t, c);

      expect(assistente.acoesRegistradas, hasLength(1));
    });
  });

  group('Quando o aplicativo nao esta no celular (FR-046)', () {
    testWidgets('a Memora avisa sem culpar a pessoa', (WidgetTester t) async {
      final ControladorConversa c = await chegarNaOferta(t);
      final String nome = c.acaoOferecida!.nomeExibido;
      abridor.falharNaProxima = true;

      await confirmar(t, c);

      expect(c.mensagens.last.texto, TextosAssistente.naoConsegiAbrir(nome));
      // Nem "erro", nem "falha", nem nome de pacote.
      expect(c.mensagens.last.texto.toLowerCase(), isNot(contains('erro')));
    });

    testWidgets('a acao que NAO aconteceu tambem nao e registrada',
        (WidgetTester t) async {
      final ControladorConversa c = await chegarNaOferta(t);
      abridor.falharNaProxima = true;

      await confirmar(t, c);

      // A FR-023 mostra este registro a pessoa. Gravar uma abertura que nunca
      // aconteceu faria ela ler "abri o WhatsApp" numa tarde em que ele nunca
      // abriu — e desconfiar do registro inteiro.
      expect(assistente.acoesRegistradas, isEmpty);
    });
  });
}
