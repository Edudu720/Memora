import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/ajuda/data/compartilhar.dart';
import 'package:memora/features/ajuda/domain/assunto_de_ajuda.dart';
import 'package:memora/features/ajuda/presentation/ajuda_guiada_da_conversa.dart';
import 'package:memora/features/ajuda/presentation/tela_ajuda.dart';
import 'package:memora/features/ajuda/presentation/tela_assunto.dart';
import 'package:memora/features/apresentacao/data/apresentacao_vista.dart';
import 'package:memora/features/apresentacao/presentation/fluxo_apresentacao.dart';
import 'package:memora/features/assistente/presentation/telas/tela_conversa.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';
import 'package:memora/l10n/textos_ajuda.dart';
import 'package:memora/l10n/textos_apresentacao.dart';
import 'package:memora/l10n/textos_assistente.dart';
import 'package:memora/services/ambiente/ambiente.dart';

import '../../suporte/aparelhos.dart';
import '../../suporte/estados_de_tela.dart';
import '../autenticacao/fluxo_dentro_da_conta.dart';

/// A Ajuda — a US6 da feature 004 (T085 a T090).
///
/// Cobre a lista de assuntos (FR-033), o conteúdo de cada um (FR-034, FR-036,
/// FR-036a), "Compartilhar" (FR-035, FR-037, R12) e a porta no Hub — as telas
/// isoladas, na matriz de aparelhos, e **pelo fluxo de verdade**: o Hub que
/// o aplicativo mostra é que precisa ter a quinta porta.
void main() {
  const String enderecoOficial = 'https://memora.fatec.example/baixar';

  /// Um toque de verdade, depois de rolar até o alvo.
  Future<void> tocar(WidgetTester t, Finder alvo) async {
    await t.ensureVisible(alvo);
    await t.pump();
    await t.tap(alvo);
    await t.pump(const Duration(milliseconds: 50));
    await t.pump(const Duration(milliseconds: 400));
  }

  Widget app(Widget filho) =>
      MaterialApp(theme: TemasMemora.claro, home: filho);

  AssuntoDeAjuda assunto(IdDoAssunto id, {bool compartilhar = true}) =>
      AssuntoDeAjuda.disponiveis(
        podeCompartilhar: compartilhar,
      ).firstWhere((AssuntoDeAjuda a) => a.id == id);

  Widget ajuda({
    bool compartilhar = false,
    VoidCallback? aoVerApresentacao,
    void Function(AssuntoDeAjuda)? aoAbrir,
  }) => TelaAjuda(
    assuntos: AssuntoDeAjuda.disponiveis(podeCompartilhar: compartilhar),
    aoAbrirAssunto: aoAbrir ?? (AssuntoDeAjuda _) {},
    aoVerApresentacao: aoVerApresentacao,
    aoVoltar: () {},
  );

  Widget tela(AssuntoDeAjuda a, {Compartilhador? compartilhador}) =>
      TelaAssunto(assunto: a, compartilhador: compartilhador, aoVoltar: () {});

  // ===========================================================================
  // A lista de assuntos
  // ===========================================================================
  group('Os assuntos têm desenho e nome — FR-033, FR-004', () {
    testWidgets('cada assunto é uma porta com desenho, nome e uma linha', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(ajuda()));

      final List<AssuntoDeAjuda> esperados = AssuntoDeAjuda.disponiveis(
        podeCompartilhar: false,
      );
      for (final AssuntoDeAjuda a in esperados) {
        final Finder porta = find.byKey(TelaAjuda.chaveDoAssunto(a.id));
        await t.ensureVisible(porta);
        expect(porta, findsOneWidget, reason: a.titulo);
        final CartaoDePorta cartao = t.widget<CartaoDePorta>(porta);
        expect(cartao.nome, a.titulo);
        expect(cartao.explicacao, a.explicacao);
        expect(cartao.ilustracao, a.ilustracao, reason: 'FR-004: ${a.titulo}');
      }
    });

    testWidgets('são os assuntos do wireframe que funcionam, e só eles', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(ajuda()));

      expect(
        AssuntoDeAjuda.disponiveis(podeCompartilhar: false).map((a) => a.id),
        <IdDoAssunto>[
          IdDoAssunto.aplicativo,
          IdDoAssunto.memora,
          IdDoAssunto.conversa,
          IdDoAssunto.servicos,
          IdDoAssunto.baixarAplicativo,
          IdDoAssunto.seguranca,
        ],
      );
      // "Planos" não entra (US9).
      expect(find.textContaining('Planos'), findsNothing);
      expect(find.textContaining('Plano'), findsNothing);
      // O site de ajuda do wireframe não é nosso, e link para domínio que não
      // controlamos é o link que um golpista compra (R12).
      expect(find.textContaining('ajudamemora'), findsNothing);
      expect(find.textContaining('www.'), findsNothing);
    });

    testWidgets('tocar num assunto o abre', (WidgetTester t) async {
      final List<IdDoAssunto> abertos = <IdDoAssunto>[];
      await t.pumpWidget(
        app(ajuda(aoAbrir: (AssuntoDeAjuda a) => abertos.add(a.id))),
      );

      await tocar(
        t,
        find.byKey(TelaAjuda.chaveDoAssunto(IdDoAssunto.seguranca)),
      );

      expect(abertos, <IdDoAssunto>[IdDoAssunto.seguranca]);
    });
  });

  // ===========================================================================
  // O conteúdo de cada assunto
  // ===========================================================================
  group('Uma ideia por vez — FR-033, US6 cenário 3', () {
    /// Passa por todas as ideias do assunto, conferindo que **só uma** está na
    /// tela de cada vez. Devolve as que viu, na ordem.
    Future<List<String>> percorrer(WidgetTester t, AssuntoDeAjuda a) async {
      final List<String> vistas = <String>[];
      for (int i = 0; i < a.telas.length; i++) {
        final List<String> naTela = <String>[
          for (final String texto in a.telas)
            if (find.text(texto).evaluate().isNotEmpty) texto,
        ];
        expect(
          naTela,
          <String>[a.telas[i]],
          reason: '${a.titulo}, tela ${i + 1}: deveria mostrar só esta ideia',
        );
        vistas.add(a.telas[i]);
        if (i < a.telas.length - 1) {
          await tocar(t, find.byKey(TelaAssunto.chaveContinuar));
        }
      }
      return vistas;
    }

    testWidgets('"Segurança" mostra uma dica por vez, e todas se alcançam', (
      WidgetTester t,
    ) async {
      final AssuntoDeAjuda seguranca = assunto(IdDoAssunto.seguranca);
      await t.pumpWidget(app(tela(seguranca)));

      final List<String> vistas = await percorrer(t, seguranca);

      expect(vistas, TextosAjuda.dicasDeSeguranca);
      expect(find.byType(BalaoDeFala), findsOneWidget);
    });

    testWidgets('"Segurança" diz o que ninguém do Memora faz — FR-036a', (
      WidgetTester t,
    ) async {
      final AssuntoDeAjuda seguranca = assunto(IdDoAssunto.seguranca);
      await t.pumpWidget(app(tela(seguranca)));

      final List<String> vistas = await percorrer(t, seguranca);

      // As frases são **as mesmas** da apresentação: um texto só, lido de
      // `TextosApresentacao`. Se alguém afrouxar uma delas lá, a Ajuda a
      // acompanha — e se alguém copiar e afrouxar aqui, este teste reprova.
      for (final String frase in TextosApresentacao.nuncaFaco) {
        expect(
          vistas,
          contains(frase),
          reason: 'FR-036a: a Segurança perdeu "$frase"',
        );
      }
      expect(vistas, contains(TextosApresentacao.seAlguemPedir));
    });

    testWidgets('"Segurança" ensina o que fazer num golpe por telefone — US6', (
      WidgetTester t,
    ) async {
      final AssuntoDeAjuda seguranca = assunto(IdDoAssunto.seguranca);
      await t.pumpWidget(app(tela(seguranca)));

      // Logo na primeira tela, sem rolar a lista inteira de dicas.
      expect(find.textContaining('por telefone'), findsWidgets);
      expect(find.textContaining('Desligue'), findsOneWidget);
    });

    testWidgets('o contador diz "Dica 1 de N" e avança; "Anterior" volta', (
      WidgetTester t,
    ) async {
      final AssuntoDeAjuda seguranca = assunto(IdDoAssunto.seguranca);
      final int total = seguranca.telas.length;
      await t.pumpWidget(app(tela(seguranca)));

      expect(find.text(TextosAjuda.dica(1, total)), findsOneWidget);
      expect(find.byKey(TelaAssunto.chaveAnterior), findsNothing);

      await tocar(t, find.byKey(TelaAssunto.chaveContinuar));
      expect(find.text(TextosAjuda.dica(2, total)), findsOneWidget);
      expect(find.text(TextosAjuda.proximaDica), findsOneWidget);

      await tocar(t, find.byKey(TelaAssunto.chaveAnterior));
      expect(find.text(TextosAjuda.dica(1, total)), findsOneWidget);
    });

    testWidgets('na última ideia, o botão leva de volta à Ajuda', (
      WidgetTester t,
    ) async {
      int voltou = 0;
      final AssuntoDeAjuda memora = assunto(IdDoAssunto.memora);
      await t.pumpWidget(
        app(TelaAssunto(assunto: memora, aoVoltar: () => voltou++)),
      );

      await percorrer(t, memora);
      expect(find.byKey(TelaAssunto.chaveContinuar), findsNothing);
      await tocar(t, find.byKey(TelaAssunto.chaveSair));

      expect(voltou, 1);
    });

    testWidgets('"Como baixar um aplicativo" ensina a loja oficial, o porquê e '
        'a conferência do desenvolvedor — FR-036', (WidgetTester t) async {
      final AssuntoDeAjuda baixar = assunto(IdDoAssunto.baixarAplicativo);
      await t.pumpWidget(app(tela(baixar)));

      final String tudo = (await _percorrerTexto(t, baixar, tocar)).join(' ');

      expect(tudo, contains('loja oficial'));
      expect(tudo, contains('Por quê'));
      expect(
        tudo,
        contains('desenvolvedor'),
        reason:
            'FR-036: conferir o desenvolvedor na loja é o que separa o '
            'aplicativo de verdade da cópia',
      );
      // E o pedido do golpista, dito de frente (FR-036a).
      expect(tudo, contains('para o Memora funcionar'));
    });

    testWidgets('"Os serviços" diz que a Memora só ensina, e nunca abre por '
        'você (D2)', (WidgetTester t) async {
      final AssuntoDeAjuda servicos = assunto(IdDoAssunto.servicos);
      await t.pumpWidget(app(tela(servicos)));

      final String tudo = (await _percorrerTexto(t, servicos, tocar)).join(' ');

      expect(tudo, contains('só te ensino'));
      expect(tudo, contains('nunca abro'));
    });

    testWidgets('cada assunto tem a Memora e escreve o próprio título', (
      WidgetTester t,
    ) async {
      for (final AssuntoDeAjuda a in AssuntoDeAjuda.disponiveis(
        podeCompartilhar: true,
      ).where((AssuntoDeAjuda a) => a.id != IdDoAssunto.conversa)) {
        await t.pumpWidget(
          app(tela(a, compartilhador: CompartilhadorSimulado(enderecoOficial))),
        );
        expect(find.text(a.titulo), findsWidgets, reason: a.titulo);
        // FR-003: a Memora aparece na ajuda — no balão de cada ideia.
        expect(find.byType(MemoraPersonagem), findsWidgets, reason: a.titulo);
      }
    });
  });

  // ===========================================================================
  // Ver a apresentação de novo
  // ===========================================================================
  group('Ver a apresentação de novo — FR-013, US6 cenário 5', () {
    testWidgets('a porta existe e leva à apresentação', (WidgetTester t) async {
      int pediu = 0;
      await t.pumpWidget(app(ajuda(aoVerApresentacao: () => pediu++)));

      await tocar(t, find.byKey(TelaAjuda.chaveReverApresentacao));

      expect(find.text(TextosAjuda.reverApresentacao), findsOneWidget);
      expect(pediu, 1);
    });

    testWidgets('sem destino, a porta não existe — FR-018', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(ajuda()));

      expect(find.byKey(TelaAjuda.chaveReverApresentacao), findsNothing);
      expect(find.text(TextosAjuda.reverApresentacao), findsNothing);
    });

    testWidgets('pelo fluxo de verdade: a apresentação volta, e "Pular" '
        'devolve à Ajuda', (WidgetTester t) async {
      final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
      await fluxo.montar(t, vistas: ApresentacaoVistaEmMemoria());
      await FluxoDentroDaConta.irAoHub(t);
      await FluxoDentroDaConta.tocar(
        t,
        find.byKey(TelaHub.chaveDaPorta(TextosAssistente.portaAjuda)),
      );
      await FluxoDentroDaConta.esperarATransicao(t);

      await FluxoDentroDaConta.tocar(
        t,
        find.byKey(TelaAjuda.chaveReverApresentacao),
      );
      await FluxoDentroDaConta.esperarATransicao(t);

      expect(find.byType(FluxoApresentacao), findsOneWidget);

      await FluxoDentroDaConta.tocar(
        t,
        find.byKey(FluxoApresentacao.chavePular),
      );
      await FluxoDentroDaConta.esperarATransicao(t);

      expect(find.byType(FluxoApresentacao), findsNothing);
      expect(find.byType(TelaAjuda), findsOneWidget);
    });
  });

  // ===========================================================================
  // Compartilhar
  // ===========================================================================
  group('Compartilhar — FR-035, FR-037, R12', () {
    testWidgets('SEM endereço oficial de download, "Compartilhar" não existe', (
      WidgetTester t,
    ) async {
      // `Compartilhador.doAmbiente` é a única porta de entrada do endereço:
      // sem `MEMORA_URL_DOWNLOAD`, é nulo, e a lista de assuntos nasce sem ele.
      const Ambiente semEndereco = Ambiente(
        urlBase: '',
        usaServidorReal: false,
      );
      final Compartilhador? compartilhador = Compartilhador.doAmbiente(
        semEndereco,
      );
      expect(compartilhador, isNull);

      await t.pumpWidget(app(ajuda(compartilhar: compartilhador != null)));

      expect(
        find.byKey(TelaAjuda.chaveDoAssunto(IdDoAssunto.compartilhar)),
        findsNothing,
      );
      expect(find.text(TextosAjuda.tituloCompartilhar), findsNothing);
      expect(
        AssuntoDeAjuda.disponiveis(podeCompartilhar: false).map((a) => a.id),
        isNot(contains(IdDoAssunto.compartilhar)),
      );
    });

    testWidgets('um endereço que não é https não cria o assunto', (
      WidgetTester t,
    ) async {
      for (final String ruim in <String>[
        'http://memora.example/baixar',
        'https://play.google.com@golpe.example/x',
        'https://memora.example/a b',
        '   ',
      ]) {
        expect(
          Compartilhador.doAmbiente(
            Ambiente(urlBase: '', usaServidorReal: false, urlDownload: ruim),
          ),
          isNull,
          reason: 'um endereço assim levaria a pessoa ao golpe: "$ruim"',
        );
      }
    });

    testWidgets('COM endereço, o assunto existe', (WidgetTester t) async {
      final Compartilhador? compartilhador = Compartilhador.doAmbiente(
        const Ambiente(
          urlBase: '',
          usaServidorReal: false,
          urlDownload: enderecoOficial,
        ),
      );
      expect(compartilhador, isNotNull);
      expect(compartilhador!.endereco, enderecoOficial);

      await t.pumpWidget(app(ajuda(compartilhar: true)));

      expect(
        find.byKey(TelaAjuda.chaveDoAssunto(IdDoAssunto.compartilhar)),
        findsOneWidget,
      );
    });

    testWidgets('avisa ANTES: nada sai até a pessoa confirmar', (
      WidgetTester t,
    ) async {
      final CompartilhadorSimulado envio = CompartilhadorSimulado(
        enderecoOficial,
      );
      await t.pumpWidget(
        app(tela(assunto(IdDoAssunto.compartilhar), compartilhador: envio)),
      );

      await tocar(t, find.byKey(TelaAssunto.chaveCompartilhar));

      // O aviso diz que vai para fora do Memora, e mostra para onde (FR-037).
      expect(find.byKey(TelaAssunto.chaveConfirmacao), findsOneWidget);
      expect(
        find.text(TextosAjuda.avisoCompartilhar(enderecoOficial)),
        findsOneWidget,
      );
      expect(find.textContaining('para fora do Memora'), findsWidgets);
      expect(find.textContaining(enderecoOficial), findsOneWidget);
      expect(
        envio.enviados,
        isEmpty,
        reason: 'FR-035: nada pode sair antes do "sim"',
      );
    });

    testWidgets('"Agora não" não envia nada', (WidgetTester t) async {
      final CompartilhadorSimulado envio = CompartilhadorSimulado(
        enderecoOficial,
      );
      await t.pumpWidget(
        app(tela(assunto(IdDoAssunto.compartilhar), compartilhador: envio)),
      );

      await tocar(t, find.byKey(TelaAssunto.chaveCompartilhar));
      await tocar(t, find.text(TextosAjuda.naoCompartilhar));

      expect(envio.enviados, isEmpty);
      expect(find.byKey(TelaAssunto.chaveConfirmacao), findsNothing);
    });

    testWidgets('com o "sim", sai SÓ o endereço oficial', (
      WidgetTester t,
    ) async {
      final CompartilhadorSimulado envio = CompartilhadorSimulado(
        enderecoOficial,
      );
      await t.pumpWidget(
        app(tela(assunto(IdDoAssunto.compartilhar), compartilhador: envio)),
      );

      await tocar(t, find.byKey(TelaAssunto.chaveCompartilhar));
      await tocar(t, find.text(TextosAjuda.simCompartilhar));

      expect(
        envio.enviados,
        <String>[enderecoOficial],
        reason: 'FR-035: só o endereço oficial, uma vez, e mais nada',
      );
    });

    test('o que viaja na intenção do Android é o endereço, e MAIS NADA', () {
      final intencao = intencaoDeCompartilhamento(enderecoOficial);

      // O plugin repassa ao Android o texto como esta, fora de 'action_view' e
      // poucos outros: so a constante inteira chega como ACTION_SEND.
      expect(intencao.action, 'android.intent.action.SEND');
      expect(intencao.type, 'text/plain');
      expect(intencao.arguments, <String, dynamic>{
        'android.intent.extra.TEXT': enderecoOficial,
      });
      // Nenhum extra de assunto, de destinatário, de arquivo — e nenhum
      // aplicativo escolhido por nós: quem decide para onde vai é a pessoa.
      expect(intencao.arrayArguments, isNull);
      expect(intencao.package, isNull);
      expect(intencao.componentName, isNull);
      expect(intencao.data, isNull);
    });

    testWidgets('se a folha não abre, a Memora diz, com frase e sem erro '
        'técnico', (WidgetTester t) async {
      final CompartilhadorSimulado envio = CompartilhadorSimulado(
        enderecoOficial,
      )..falharNoProximo = true;
      await t.pumpWidget(
        app(tela(assunto(IdDoAssunto.compartilhar), compartilhador: envio)),
      );

      await tocar(t, find.byKey(TelaAssunto.chaveCompartilhar));
      await tocar(t, find.text(TextosAjuda.simCompartilhar));

      expect(find.byKey(TelaAssunto.chaveErro), findsOneWidget);
      expect(find.text(TextosAjuda.erroAoCompartilhar), findsOneWidget);
      expect(find.byType(MensagemErro), findsOneWidget);
      expect(envio.enviados, isEmpty);
    });
  });

  // ===========================================================================
  // A ajuda guiada da conversa
  // ===========================================================================
  group('A ajuda guiada da conversa — FR-034, Figuras 15 a 19', () {
    Widget guiada({VoidCallback? aoConversar, VoidCallback? aoVoltar}) =>
        AjudaGuiadaDaConversa(
          aoConversar: aoConversar ?? () {},
          aoVoltar: aoVoltar ?? () {},
        );

    testWidgets('mostra a conversa passo a passo, com "Continuar"', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(app(guiada()));

      for (int i = 0; i < TextosAjuda.totalDeTelasDaConversa - 1; i++) {
        expect(
          find.byKey(AjudaGuiadaDaConversa.chaveDaTela(i)),
          findsOneWidget,
          reason: 'tela ${i + 1}',
        );
        expect(find.byType(BalaoDeFala), findsWidgets);
        await tocar(t, find.byKey(AjudaGuiadaDaConversa.chaveContinuar));
      }

      expect(
        find.byKey(
          AjudaGuiadaDaConversa.chaveDaTela(
            TextosAjuda.totalDeTelasDaConversa - 1,
          ),
        ),
        findsOneWidget,
      );
      expect(find.byKey(AjudaGuiadaDaConversa.chaveContinuar), findsNothing);
    });

    testWidgets('a conversa de exemplo tem a pergunta da pessoa e a resposta '
        'da Memora, e avisa que é só exemplo', (WidgetTester t) async {
      await t.pumpWidget(app(guiada()));
      await tocar(t, find.byKey(AjudaGuiadaDaConversa.chaveContinuar));

      expect(find.text(TextosAjuda.guiadaPergunta), findsOneWidget);
      expect(find.text(TextosAjuda.guiadaResposta), findsOneWidget);
      expect(find.text(TextosAjuda.guiadaSoExemplo), findsOneWidget);
      // Nada para digitar: é exemplo. Campo de texto aqui convidaria a
      // escrever numa conversa que não responde.
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('a pergunta de abrir um aplicativo é só texto: sem botão '
        'Sim/Não que não faz nada', (WidgetTester t) async {
      await t.pumpWidget(app(guiada()));
      for (int i = 0; i < 3; i++) {
        await tocar(t, find.byKey(AjudaGuiadaDaConversa.chaveContinuar));
      }

      expect(find.text(TextosAjuda.guiadaPerguntaDeAbrir), findsOneWidget);
      // Botão desabilitado de "Sim" seria porta pintada na parede (FR-018).
      expect(find.text('Sim'), findsNothing);
      expect(find.text('Não'), findsNothing);
    });

    testWidgets('a saída vai DIRETO para a conversa, sem tela no meio', (
      WidgetTester t,
    ) async {
      int conversou = 0;
      await t.pumpWidget(app(guiada(aoConversar: () => conversou++)));
      for (int i = 0; i < TextosAjuda.totalDeTelasDaConversa - 1; i++) {
        await tocar(t, find.byKey(AjudaGuiadaDaConversa.chaveContinuar));
      }

      await tocar(t, find.byKey(AjudaGuiadaDaConversa.chaveConversar));

      expect(conversou, 1, reason: 'um toque, e a conversa abre');
    });

    testWidgets('a saída para a conversa só aparece na última tela; as '
        'outras só avançam', (WidgetTester t) async {
      await t.pumpWidget(app(guiada()));

      expect(find.byKey(AjudaGuiadaDaConversa.chaveConversar), findsNothing);
      expect(find.byKey(AjudaGuiadaDaConversa.chaveContinuar), findsOneWidget);
    });

    testWidgets('pelo fluxo de verdade: A conversa → saída → a conversa real '
        'abre', (WidgetTester t) async {
      final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
      await fluxo.montar(t);
      await FluxoDentroDaConta.irAoHub(t);
      await FluxoDentroDaConta.tocar(
        t,
        find.byKey(TelaHub.chaveDaPorta(TextosAssistente.portaAjuda)),
      );
      await FluxoDentroDaConta.esperarATransicao(t);

      await FluxoDentroDaConta.tocar(
        t,
        find.byKey(TelaAjuda.chaveDoAssunto(IdDoAssunto.conversa)),
      );
      await FluxoDentroDaConta.esperarATransicao(t);
      expect(find.byType(AjudaGuiadaDaConversa), findsOneWidget);

      for (int i = 0; i < TextosAjuda.totalDeTelasDaConversa - 1; i++) {
        await FluxoDentroDaConta.tocar(
          t,
          find.byKey(AjudaGuiadaDaConversa.chaveContinuar),
        );
      }
      await FluxoDentroDaConta.tocar(
        t,
        find.byKey(AjudaGuiadaDaConversa.chaveConversar),
      );
      await FluxoDentroDaConta.esperarATransicao(t);

      expect(find.byKey(TelaConversa.chaveCampo), findsOneWidget);
    });
  });

  // ===========================================================================
  // A porta no Hub
  // ===========================================================================
  group('A porta "Preciso de ajuda" no Hub — T090', () {
    testWidgets('o Hub do aplicativo tem a porta, e ela abre a Ajuda', (
      WidgetTester t,
    ) async {
      final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
      await fluxo.montar(t);
      await FluxoDentroDaConta.irAoHub(t);

      final Finder porta = find.byKey(
        TelaHub.chaveDaPorta(TextosAssistente.portaAjuda),
      );
      expect(porta, findsOneWidget);
      final CartaoDePorta cartao = t.widget<CartaoDePorta>(porta);
      expect(cartao.nome, TextosAssistente.portaAjuda);
      expect(cartao.explicacao, TextosAssistente.descricaoAjuda);
      expect(cartao.ilustracao, Ilustracao.portaAjuda);

      await FluxoDentroDaConta.tocar(t, porta);
      await FluxoDentroDaConta.esperarATransicao(t);

      expect(find.byType(TelaAjuda), findsOneWidget);
    });

    testWidgets('sem endereço de download, a Ajuda do aplicativo não tem '
        'Compartilhar', (WidgetTester t) async {
      final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
      await fluxo.montar(t);
      await FluxoDentroDaConta.irAoHub(t);
      await FluxoDentroDaConta.tocar(
        t,
        find.byKey(TelaHub.chaveDaPorta(TextosAssistente.portaAjuda)),
      );
      await FluxoDentroDaConta.esperarATransicao(t);

      expect(
        find.byKey(TelaAjuda.chaveDoAssunto(IdDoAssunto.compartilhar)),
        findsNothing,
      );
    });

    testWidgets('com endereço de download, a Ajuda do aplicativo o oferece', (
      WidgetTester t,
    ) async {
      final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
      await fluxo.montar(
        t,
        compartilhador: CompartilhadorSimulado(enderecoOficial),
      );
      await FluxoDentroDaConta.irAoHub(t);
      await FluxoDentroDaConta.tocar(
        t,
        find.byKey(TelaHub.chaveDaPorta(TextosAssistente.portaAjuda)),
      );
      await FluxoDentroDaConta.esperarATransicao(t);

      expect(
        find.byKey(TelaAjuda.chaveDoAssunto(IdDoAssunto.compartilhar)),
        findsOneWidget,
      );
    });
  });

  // ===========================================================================
  // Estados — FR-006
  // ===========================================================================
  group('Estados — FR-006', () {
    testWidgets('a Ajuda é conteúdo embarcado: não carrega, não está vazia e '
        'não falha', (WidgetTester t) async {
      // Nenhum dos três estados existe: os assuntos moram no aplicativo, e a
      // lista nunca é vazia. O único erro possível é a folha de compartilhar
      // que não abre, e esse tem teste próprio acima (frase e `MensagemErro`).
      await exigirOsEstadosDaFr006(
        t,
        tela: 'TelaAjuda',
        montar: (EstadoDaTela estado) => switch (estado) {
          EstadoDaTela.carregando => null,
          EstadoDaTela.vazio => null,
          EstadoDaTela.erro => null,
        },
      );
    });
  });

  // ===========================================================================
  // Matriz — FR-044
  // ===========================================================================
  group('Matriz de aparelhos × escalas × temas — FR-044', () {
    Future<void> exigirSemEstouro(
      WidgetTester t,
      Combinacao c,
      Widget filho,
      String oQue, {
      List<Finder> alcancaveis = const <Finder>[],
      List<Finder> portas = const <Finder>[],
    }) async {
      vestir(t, c.aparelho);
      await t.pumpWidget(naCombinacao(c, filho));
      await t.pump(const Duration(milliseconds: 50));

      expect(t.takeException(), isNull, reason: '$oQue em ${nomeDa(c)}');
      for (final Finder alvo in alcancaveis) {
        await exigirAlcancavel(
          t,
          alvo,
          aparelho: c.aparelho,
          contexto: '$oQue em ${nomeDa(c)}',
        );
      }
      // Uma porta pode ser mais alta que a janela com a fonte quadrada do
      // `flutter test` (que mede o dobro da Atkinson, R3), e então o que vale
      // é o topo dela estar à vista com o alvo de toque inteiro — a mesma
      // regra que a FR-017 usa para a porta principal do Hub.
      for (final Finder porta in portas) {
        await t.ensureVisible(porta);
        await t.pump();
        final Rect r = t.getRect(porta);
        final String onde = '$oQue em ${nomeDa(c)}';
        expect(r.top, greaterThanOrEqualTo(-0.01), reason: '$onde: $r');
        expect(
          r.top + MemoraDimensoes.alvoDecisao,
          lessThanOrEqualTo(c.aparelho.height + 0.01),
          reason: '$onde: nem o alvo de toque da porta está à vista ($r)',
        );
        expect(
          r.left >= 0 && r.right <= c.aparelho.width,
          isTrue,
          reason: onde,
        );
      }
    }

    for (final Combinacao c in matriz()) {
      testWidgets('a Ajuda não estoura e o último assunto se alcança em '
          '${nomeDa(c)}', (WidgetTester t) async {
        await exigirSemEstouro(
          t,
          c,
          ajuda(compartilhar: true, aoVerApresentacao: () {}),
          'a lista de assuntos',
          portas: <Finder>[
            find.byKey(TelaAjuda.chaveDoAssunto(IdDoAssunto.seguranca)),
            find.byKey(TelaAjuda.chaveReverApresentacao),
          ],
        );
      });

      testWidgets('um assunto de dicas não estoura e o botão se alcança em '
          '${nomeDa(c)}', (WidgetTester t) async {
        await exigirSemEstouro(
          t,
          c,
          tela(assunto(IdDoAssunto.seguranca)),
          'Segurança',
          alcancaveis: <Finder>[find.byKey(TelaAssunto.chaveContinuar)],
        );
      });

      testWidgets('Baixar um aplicativo (a ideia mais longa) não estoura em '
          '${nomeDa(c)}', (WidgetTester t) async {
        // A terceira ideia é a mais comprida: confere o desenvolvedor.
        vestir(t, c.aparelho);
        await t.pumpWidget(
          naCombinacao(c, tela(assunto(IdDoAssunto.baixarAplicativo))),
        );
        await tocar(t, find.byKey(TelaAssunto.chaveContinuar));
        await tocar(t, find.byKey(TelaAssunto.chaveContinuar));

        expect(t.takeException(), isNull, reason: nomeDa(c));
        await exigirAlcancavel(
          t,
          find.byKey(TelaAssunto.chaveContinuar),
          aparelho: c.aparelho,
          contexto: 'Baixar, ideia 3, ${nomeDa(c)}',
        );
      });

      testWidgets('Compartilhar com o aviso aberto não estoura, e os dois '
          'botões se alcançam em ${nomeDa(c)}', (WidgetTester t) async {
        vestir(t, c.aparelho);
        await t.pumpWidget(
          naCombinacao(
            c,
            tela(
              assunto(IdDoAssunto.compartilhar),
              compartilhador: CompartilhadorSimulado(enderecoOficial),
            ),
          ),
        );
        await tocar(t, find.byKey(TelaAssunto.chaveCompartilhar));

        expect(t.takeException(), isNull, reason: nomeDa(c));
        for (final Finder alvo in <Finder>[
          find.text(TextosAjuda.simCompartilhar),
          find.text(TextosAjuda.naoCompartilhar),
        ]) {
          await exigirAlcancavel(
            t,
            alvo,
            aparelho: c.aparelho,
            contexto: 'o aviso de compartilhar, ${nomeDa(c)}',
          );
        }
      });

      testWidgets('a ajuda guiada não estoura, e a saída para a conversa se '
          'alcança em ${nomeDa(c)}', (WidgetTester t) async {
        vestir(t, c.aparelho);
        await t.pumpWidget(
          naCombinacao(
            c,
            AjudaGuiadaDaConversa(aoConversar: () {}, aoVoltar: () {}),
          ),
        );
        for (int i = 0; i < TextosAjuda.totalDeTelasDaConversa; i++) {
          expect(
            t.takeException(),
            isNull,
            reason: 'tela ${i + 1} em ${nomeDa(c)}',
          );
          if (i < TextosAjuda.totalDeTelasDaConversa - 1) {
            await exigirAlcancavel(
              t,
              find.byKey(AjudaGuiadaDaConversa.chaveContinuar),
              aparelho: c.aparelho,
              contexto: 'ajuda guiada, tela ${i + 1}, ${nomeDa(c)}',
            );
            await tocar(t, find.byKey(AjudaGuiadaDaConversa.chaveContinuar));
          }
        }
        await exigirAlcancavel(
          t,
          find.byKey(AjudaGuiadaDaConversa.chaveConversar),
          aparelho: c.aparelho,
          contexto: 'ajuda guiada, saída, ${nomeDa(c)}',
        );
      });
    }
  });
}

/// Passa por todas as ideias de um assunto, tocando em "Continuar", e devolve
/// os textos na ordem.
Future<List<String>> _percorrerTexto(
  WidgetTester t,
  AssuntoDeAjuda a,
  Future<void> Function(WidgetTester, Finder) tocar,
) async {
  final List<String> vistas = <String>[];
  for (int i = 0; i < a.telas.length; i++) {
    expect(find.text(a.telas[i]), findsOneWidget, reason: '${a.titulo} $i');
    vistas.add(a.telas[i]);
    if (i < a.telas.length - 1) {
      await tocar(t, find.byKey(TelaAssunto.chaveContinuar));
    }
  }
  return vistas;
}
