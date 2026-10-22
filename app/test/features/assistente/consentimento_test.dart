import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/aceite_do_aviso.dart';
import 'package:memora/features/assistente/data/conversa_local.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/assistente/presentation/controladores/controlador_conversa.dart';
import 'package:memora/features/assistente/presentation/telas/tela_conversa.dart';
import 'package:memora/l10n/textos_assistente.dart';
import 'package:memora/services/ambiente/ambiente.dart';
import 'package:memora/services/ambiente/composicao.dart';
import 'package:memora/services/seguranca/limpeza_de_sessao.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../suporte/aceite_em_memoria.dart';
import '../autenticacao/dubles_autenticacao.dart';
import '../autenticacao/fluxo_dentro_da_conta.dart';

/// O consentimento antes da primeira mensagem — FR-051, T102.
///
/// ## O que este arquivo protege
///
/// O serviço que gera as respostas é de fora do Memora, do nível gratuito: pode
/// usar o que recebe e deixar pessoas lerem. Por isso **nada** vai a ele antes
/// de a pessoa dizer que entendeu, e o aceite é de quem está na conta: sai
/// junto com ela.
///
/// Os dois portões:
///
/// 1. o `RepositorioAssistente` **não é chamado** antes do aceite — nem pelo
///    controlador, nem pela tela;
/// 2. a `LimpezaDeSessao` **apaga** o aceite, pela `Composicao` de verdade.
///
/// Os dois foram provados quebrando (ver o relatório da T102).
class _RepositorioQueConta implements RepositorioAssistente {
  int chamadas = 0;

  @override
  Future<RespostaDaAssistente> conversar({
    required String mensagem,
    required List<MensagemDaConversa> historico,
    void Function(String trecho)? aoReceberTrecho,
  }) async {
    chamadas++;
    return const AssistenteRespondeu('Vamos juntos, um passo de cada vez.');
  }

  @override
  Future<List<ServicoDoCatalogo>> catalogo() => throw UnimplementedError();

  @override
  Future<void> registrarAcao({
    required String servicoId,
    required String pedidoResumido,
  }) => throw UnimplementedError();

  @override
  Future<List<AcaoRegistrada>> registro() => throw UnimplementedError();
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

void main() {
  late _RepositorioQueConta repositorio;
  late AceiteEmMemoria aceite;

  setUp(() {
    repositorio = _RepositorioQueConta();
    aceite = AceiteEmMemoria(aceito: false);
  });

  ControladorConversa criar() =>
      ControladorConversa(repositorio, _ConversaEmMemoria(), aceite: aceite);

  Future<void> avancar(WidgetTester t) async {
    for (int quadro = 0; quadro < 6; quadro++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> montar(
    WidgetTester t,
    ControladorConversa c, {
    VoidCallback? aoVoltar,
  }) async {
    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        home: TelaConversa(controlador: c, aoVoltar: aoVoltar),
      ),
    );
    await avancar(t);
  }

  group('Portão 1 — nada vai ao serviço de fora antes do aceite (FR-051)', () {
    test('o controlador não envia, mesmo com a pergunta escrita', () async {
      final ControladorConversa c = criar();
      addTearDown(c.dispose);
      await c.iniciar();

      c.escrever('como vejo as fotos do meu neto');
      expect(c.podeEnviar, isFalse);

      await c.enviar();

      expect(
        repositorio.chamadas,
        0,
        reason:
            'o serviço de fora recebeu uma mensagem sem a pessoa ter '
            'dito que entendeu o aviso',
      );
      expect(c.mensagens, isEmpty);
    });

    test('depois de aceitar, envia — e o aceite fica guardado', () async {
      final ControladorConversa c = criar();
      addTearDown(c.dispose);
      await c.iniciar();

      await c.aceitar();
      c.escrever('como vejo as fotos do meu neto');
      await c.enviar();

      expect(repositorio.chamadas, 1);
      expect(aceite.registros, 1);
      expect(await aceite.aceitou(), isTrue);
    });

    test('quem já aceitou antes não é perguntado de novo', () async {
      aceite = AceiteEmMemoria();
      final ControladorConversa c = criar();
      addTearDown(c.dispose);
      await c.iniciar();

      expect(c.precisaDoAceite, isFalse);
      c.escrever('oi');
      expect(c.podeEnviar, isTrue);
    });

    testWidgets('na tela, a explicação ocupa o lugar do campo e do botão', (
      WidgetTester t,
    ) async {
      final ControladorConversa c = criar();
      addTearDown(c.dispose);
      await montar(t, c);

      expect(find.byKey(TelaConversa.chaveAceite), findsOneWidget);
      expect(find.byKey(TelaConversa.chaveAceitar), findsOneWidget);
      expect(find.byKey(TelaConversa.chaveRecusarAceite), findsOneWidget);
      expect(find.text(TextosAssistente.tituloAceite), findsOneWidget);
      expect(find.text(TextosAssistente.corpoDoAceite), findsOneWidget);

      // Sem aceite não há por onde escrever — nem por onde enviar.
      expect(find.byKey(TelaConversa.chaveCampo), findsNothing);
      expect(find.byKey(TelaConversa.chaveEnviar), findsNothing);
      expect(repositorio.chamadas, 0);
    });

    testWidgets(
      'os avisos permanentes continuam à vista durante a explicação',
      (WidgetTester t) async {
        final ControladorConversa c = criar();
        addTearDown(c.dispose);
        await montar(t, c);

        expect(find.byKey(TelaConversa.chaveAviso), findsOneWidget);
        expect(find.byKey(TelaConversa.chaveAvisoPrivacidade), findsOneWidget);
      },
    );

    testWidgets('tocar em "Entendi" libera o campo, e o envio funciona', (
      WidgetTester t,
    ) async {
      final ControladorConversa c = criar();
      addTearDown(c.dispose);
      await montar(t, c);

      await t.ensureVisible(find.byKey(TelaConversa.chaveAceitar));
      await t.pump();
      await t.tap(find.byKey(TelaConversa.chaveAceitar));
      await avancar(t);

      expect(find.byKey(TelaConversa.chaveAceite), findsNothing);
      expect(find.byKey(TelaConversa.chaveCampo), findsOneWidget);
      expect(aceite.registros, 1);

      await t.enterText(find.byKey(TelaConversa.chaveCampo), 'oi');
      await avancar(t);
      await t.ensureVisible(find.byKey(TelaConversa.chaveEnviar));
      await t.pump();
      await t.tap(find.byKey(TelaConversa.chaveEnviar));
      await avancar(t);

      expect(repositorio.chamadas, 1);
    });

    testWidgets('"Agora não" volta, e nada é enviado nem aceito', (
      WidgetTester t,
    ) async {
      bool voltou = false;
      final ControladorConversa c = criar();
      addTearDown(c.dispose);
      await montar(t, c, aoVoltar: () => voltou = true);

      await t.ensureVisible(find.byKey(TelaConversa.chaveRecusarAceite));
      await t.pump();
      await t.tap(find.byKey(TelaConversa.chaveRecusarAceite));
      await avancar(t);

      expect(
        voltou,
        isTrue,
        reason: 'quem recusa continua com o restante do Memora',
      );
      expect(aceite.registros, 0, reason: 'recusar não é aceitar');
      expect(repositorio.chamadas, 0);
    });
  });

  group('A explicação diz o que a FR-051 exige', () {
    test('o texto avisa dos quatro tipos de dado', () {
      final String texto = TextosAssistente.corpoDoAceite.toLowerCase();
      for (final String dado in <String>[
        'senha',
        'documento',
        'endereço',
        'saúde',
        'dinheiro',
      ]) {
        expect(
          texto,
          contains(dado),
          reason: 'a explicação não pode deixar de dizer "$dado"',
        );
      }
    });

    test('diz que sai do Memora, que pode ser usado e que gente pode ler', () {
      final String texto = TextosAssistente.corpoDoAceite.toLowerCase();
      expect(texto, contains('fora do memora'));
      expect(texto, contains('melhorar'));
      expect(texto, contains('podem lê-la'));
    });
  });

  group('Portão 2 — o aceite sai junto com a conta (FR-051, FR-048)', () {
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    test('o aceite local grava e lê um booleano', () async {
      final AceiteDoAvisoLocal local = await AceiteDoAvisoLocal.abrir();
      expect(await local.aceitou(), isFalse);

      await local.registrar();
      expect(await local.aceitou(), isTrue);
    });

    test('a LimpezaDeSessao apaga o aceite', () async {
      final AceiteDoAvisoLocal local = await AceiteDoAvisoLocal.abrir();
      await local.registrar();

      await LimpezaDeSessao(
        cofre: CofreQueRegistra(),
        ultimoAcesso: UltimoAcessoEmMemoria(),
        dadosLocais: <DadoLocalDaPessoa>[local],
      ).executar();

      expect(await local.aceitou(), isFalse);
    });

    test('a Composicao de verdade põe o aceite na lista da limpeza', () async {
      // Este é o que pega o esquecimento: o aceite existir, funcionar, e
      // ninguém o ter posto na lista do que a saída leva.
      final AceiteDoAvisoLocal local = await AceiteDoAvisoLocal.abrir();
      await local.registrar();

      final Composicao composicao = Composicao.resolver(
        ambiente: const Ambiente(urlBase: '', usaServidorReal: false),
        cofre: CofreQueRegistra(),
        ultimoAcesso: UltimoAcessoEmMemoria(),
        aceiteDoAviso: local,
      );
      expect(await composicao.aceiteDoAviso.aceitou(), isTrue);

      await composicao.limpeza.executar();

      expect(
        await local.aceitou(),
        isFalse,
        reason:
            'quem entra depois neste aparelho, com outra conta, '
            'precisa ler o aviso de novo',
      );
    });

    test('depois da saída, a conversa volta a pedir o aceite', () async {
      final AceiteDoAvisoLocal local = await AceiteDoAvisoLocal.abrir();
      final Composicao composicao = Composicao.resolver(
        ambiente: const Ambiente(urlBase: '', usaServidorReal: false),
        cofre: CofreQueRegistra(),
        ultimoAcesso: UltimoAcessoEmMemoria(),
        aceiteDoAviso: local,
      );

      final ControladorConversa primeira = ControladorConversa(
        repositorio,
        _ConversaEmMemoria(),
        aceite: composicao.aceiteDoAviso,
      );
      addTearDown(primeira.dispose);
      await primeira.iniciar();
      await primeira.aceitar();
      expect(primeira.precisaDoAceite, isFalse);

      await composicao.limpeza.executar();

      final ControladorConversa segunda = ControladorConversa(
        repositorio,
        _ConversaEmMemoria(),
        aceite: composicao.aceiteDoAviso,
      );
      addTearDown(segunda.dispose);
      await segunda.iniciar();
      expect(segunda.precisaDoAceite, isTrue);
      segunda.escrever('oi');
      await segunda.enviar();
      expect(repositorio.chamadas, 0);
    });
  });
}
