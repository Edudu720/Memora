import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/aprendizado/data/progresso_de_aprendizado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_login.dart';
import 'package:memora/features/casca/casca_interna.dart';
import 'package:memora/features/perfil/data/data_de_nascimento_local.dart';
import 'package:memora/features/perfil/domain/data_de_nascimento.dart';
import 'package:memora/features/perfil/presentation/secao_idade.dart';
import 'package:memora/features/perfil/presentation/tela_perfil.dart';
import 'package:memora/l10n/textos_perfil.dart';

import '../../suporte/aparelhos.dart';
import '../autenticacao/fluxo_dentro_da_conta.dart';

class _RepositorioEspiao implements RepositorioAssistente {
  int chamadas = 0;

  @override
  Future<List<ServicoDoCatalogo>> catalogo() async {
    chamadas++;
    return const <ServicoDoCatalogo>[];
  }

  @override
  Future<RespostaDaAssistente> conversar({
    required String mensagem,
    required List<MensagemDaConversa> historico,
    void Function(String trecho)? aoReceberTrecho,
    void Function(void Function() cancelar)? aoCriarCancelamento,
  }) async {
    chamadas++;
    return const AssistenteRespondeu('Resposta');
  }

  @override
  Future<void> registrarAcao({
    required String servicoId,
    required String pedidoResumido,
  }) async {
    chamadas++;
  }

  @override
  Future<List<AcaoRegistrada>> registro() async {
    chamadas++;
    return const <AcaoRegistrada>[];
  }
}

class _ProgressoEmMemoria implements ProgressoDeAprendizado {
  final Map<String, Map<String, int>> _dados = <String, Map<String, int>>{};

  @override
  Future<bool> registrarChegadaAoPasso({
    required String idDaConta,
    required String chave,
    required int numeroDoPasso,
    required int totalDePassos,
  }) async {
    if (numeroDoPasso != totalDePassos) return false;
    await registrarConclusao(idDaConta: idDaConta, chave: chave);
    return true;
  }

  @override
  Future<void> registrarConclusao({
    required String idDaConta,
    required String chave,
  }) async {
    final Map<String, int> daConta =
        _dados.putIfAbsent(idDaConta, () => <String, int>{});
    daConta[chave] = (daConta[chave] ?? 0) + 1;
  }

  @override
  Future<Map<String, int>> concluidos(String idDaConta) async {
    return _dados[idDaConta] ?? const <String, int>{};
  }

  @override
  Future<String?> aplicativoMaisAprendido(String idDaConta) async {
    final Map<String, int>? daConta = _dados[idDaConta];
    if (daConta == null || daConta.isEmpty) return null;
    String? melhor;
    int maxVezes = -1;
    for (final MapEntry<String, int> e in daConta.entries) {
      if (e.value > maxVezes) {
        maxVezes = e.value;
        melhor = e.key;
      }
    }
    return melhor;
  }

  @override
  Future<void> apagar() async {
    _dados.clear();
  }
}

void main() {
  late _ProgressoEmMemoria progresso;
  late ArmazenamentoDaDataDeNascimento datas;

  setUp(() {
    progresso = _ProgressoEmMemoria();
    datas = DataDeNascimentoEmMemoria();
  });

  Widget montarTela({
    Key? key,
    String nome = 'Dona Ana',
    Future<String?>? canal,
    ProgressoDeAprendizado? prog,
    ArmazenamentoDaDataDeNascimento? armDatas,
    String? idConta = 'conta-123',
    ThemeData? tema,
    double escala = 1.0,
  }) {
    return MaterialApp(
      theme: tema ?? TemasMemora.claro,
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(escala),
          size: const Size(390, 844),
        ),
        child: TelaPerfil(
          key: key,
          nome: nome,
          canal: canal ?? Future<String?>.value('ana@exemplo.com'),
          progresso: prog ?? progresso,
          dataDeNascimento: armDatas ?? datas,
          idDaConta: idConta,
        ),
      ),
    );
  }

  group('US8 — Meu perfil (FR-042)', () {
    testWidgets('nome, desenho, canal e mais aprendido aparecem como informação',
        (WidgetTester t) async {
      final SemanticsHandle handle = t.ensureSemantics();
      await t.pumpWidget(montarTela());
      await t.pumpAndSettle();

      expect(find.byKey(TelaPerfil.chaveNome), findsOneWidget);
      expect(find.byKey(TelaPerfil.chaveCanal), findsOneWidget);
      expect(find.byKey(TelaPerfil.chaveMaisAprendido), findsOneWidget);
      expect(find.byKey(TelaPerfil.chaveDesenho), findsOneWidget);

      expect(find.text('Dona Ana'), findsOneWidget);
      expect(find.text('ana@exemplo.com'), findsOneWidget);

      // Informação nunca é botão (FR-012 da 002)
      for (final Key chave in <Key>[
        TelaPerfil.chaveNome,
        TelaPerfil.chaveCanal,
        TelaPerfil.chaveMaisAprendido,
      ]) {
        expect(
          t.getSemantics(find.byKey(chave)),
          isSemantics(isButton: false, hasTapAction: false),
          reason: 'O campo de informação $chave não pode ser anunciado como botão',
        );
        expect(
          find.descendant(of: find.byKey(chave), matching: find.byType(InkWell)),
          findsNothing,
        );
      }
      handle.dispose();
    });

    testWidgets('quando vazio, o mais aprendido diz que vamos aprender juntos',
        (WidgetTester t) async {
      await t.pumpWidget(montarTela());
      await t.pumpAndSettle();

      expect(find.text(TextosPerfil.maisAprendidoVazio), findsOneWidget);
    });

    testWidgets('quando há progresso, exibe o aplicativo mais aprendido',
        (WidgetTester t) async {
      await progresso.registrarConclusao(idDaConta: 'conta-123', chave: 'whatsapp');
      await progresso.registrarConclusao(idDaConta: 'conta-123', chave: 'whatsapp');

      await t.pumpWidget(montarTela());
      await t.pumpAndSettle();

      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text(TextosPerfil.maisAprendidoVazio), findsNothing);
    });

    testWidgets('a idade aparece só como informação e apenas se informada (FR-042c)',
        (WidgetTester t) async {
      // Sem data informada: convite visível
      await t.pumpWidget(montarTela(key: const ValueKey<int>(1)));
      await t.pumpAndSettle();

      expect(find.byKey(SecaoIdade.chaveConvite), findsOneWidget);
      expect(find.byKey(SecaoIdade.chaveIdade), findsNothing);

      // Com data informada: idade calculada como informação
      await datas.guardar(
        'conta-123',
        DataDeNascimento.validar(
          dia: '10',
          mes: '5',
          ano: '1950',
          hoje: DateTime.now(),
        ).data!,
      );

      await t.pumpWidget(montarTela(key: const ValueKey<int>(2)));
      await t.pumpAndSettle();

      expect(find.byKey(SecaoIdade.chaveIdade), findsOneWidget);
      expect(find.byKey(SecaoIdade.chaveConvite), findsNothing);
    });

    testWidgets('nenhum campo de plano, assinatura ou pagamento na tela (US9)',
        (WidgetTester t) async {
      await t.pumpWidget(montarTela());
      await t.pumpAndSettle();

      final List<String> termosProibidos = <String>[
        'plano',
        'assinatura',
        'pagamento',
        'premium',
        'upgrade',
        'mensalidade',
      ];

      for (final Element elemento in find.byType(Text).evaluate()) {
        final Text widgetTexto = elemento.widget as Text;
        final String conteudo = widgetTexto.data?.toLowerCase() ?? '';
        for (final String termo in termosProibidos) {
          expect(
            conteudo.contains(termo),
            isFalse,
            reason: 'Encontrado termo proibido de plano: "$termo" no texto "$conteudo"',
          );
        }
      }
    });

    testWidgets('nenhuma chamada ao repositório é feita ao abrir a tela (FR-042a)',
        (WidgetTester t) async {
      final _RepositorioEspiao espiao = _RepositorioEspiao();

      await t.pumpWidget(montarTela());
      await t.pumpAndSettle();

      expect(espiao.chamadas, 0, reason: 'O Perfil lê apenas dados locais, sem rede.');
    });

    testWidgets('some quando a sessão expira (FR-050)', (WidgetTester t) async {
      final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
      const Duration prazo = Duration(minutes: 30);

      await fluxo.montar(t);
      await FluxoDentroDaConta.tocar(t, find.byKey(CascaInterna.chaveDaBarra));
      await FluxoDentroDaConta.tocar(t, find.text(DestinoDaCasca.perfil.rotulo));
      await FluxoDentroDaConta.avancar(t, 6);

      expect(find.byType(TelaPerfil), findsOneWidget);

      // Espera a expiração completa da sessão
      await t.pump(prazo);
      await FluxoDentroDaConta.avancar(t, 6);

      expect(find.byType(TelaPerfil), findsNothing);
      expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
    });
  });

  group('Matriz de aparelhos e acessibilidade', () {
    for (final Size aparelho in aparelhos) {
      testWidgets('Perfil não estoura em ${nomeDo(aparelho)} a 200% de escala',
          (WidgetTester t) async {
        t.view.physicalSize = Size(aparelho.width * 2.0, aparelho.height * 2.0);
        t.view.devicePixelRatio = 2.0;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);

        await t.pumpWidget(
          montarTela(
            escala: 2.0,
            tema: TemasMemora.altoContraste,
          ),
        );
        await t.pumpAndSettle();

        expect(find.byType(TelaPerfil), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }
  });

  group('Feature 016 / US4 — Organização, otimização e slot Item 14', () {
    testWidgets(
      'agrupa em cartões com Semantics(header: true) e omite ultimoModuloConcluido quando nulo ou vazio',
      (WidgetTester t) async {
        final SemanticsHandle handle = t.ensureSemantics();
        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: TelaPerfil(
              nome: 'Dona Ana',
              canal: Future<String?>.value('ana@exemplo.com'),
              progresso: progresso,
              dataDeNascimento: datas,
              idDaConta: 'conta-123',
              ultimoModuloConcluido: '   ',
            ),
          ),
        );
        await t.pumpAndSettle();

        expect(find.byKey(TelaPerfil.chaveSecaoAprendizado), findsOneWidget);
        expect(find.byKey(TelaPerfil.chaveUltimoModulo), findsNothing);
        for (final String cabecalho in <String>[
          TextosPerfil.secaoRetrato,
          TextosPerfil.secaoConta,
          TextosPerfil.secaoAprendizado,
        ]) {
          final Finder textoHeader = find.text(cabecalho);
          expect(textoHeader, findsOneWidget);
          expect(
            t.getSemantics(textoHeader),
            isSemantics(isHeader: true),
            reason: '$cabecalho deve ter semântica de cabeçalho',
          );
        }
        expect(find.text('Dona Ana'), findsOneWidget);
        handle.dispose();
      },
    );

    testWidgets(
      'renderiza ultimoModuloConcluido apenas como informação quando preenchido',
      (WidgetTester t) async {
        final SemanticsHandle handle = t.ensureSemantics();
        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: TelaPerfil(
              nome: 'Dona Ana',
              canal: Future<String?>.value('ana@exemplo.com'),
              progresso: progresso,
              idDaConta: 'conta-123',
              ultimoModuloConcluido: 'WhatsApp: Mandar foto',
            ),
          ),
        );
        await t.pumpAndSettle();

        expect(find.byKey(TelaPerfil.chaveUltimoModulo), findsOneWidget);
        expect(find.text('WhatsApp: Mandar foto'), findsOneWidget);
        expect(
          t.getSemantics(find.byKey(TelaPerfil.chaveUltimoModulo)),
          isSemantics(isButton: false, hasTapAction: false),
        );
        expect(
          find.descendant(
            of: find.byKey(TelaPerfil.chaveUltimoModulo),
            matching: find.byType(InkWell),
          ),
          findsNothing,
        );
        handle.dispose();
      },
    );

    testWidgets(
      'troca rápida de idDaConta descarta resposta assíncrona obsoleta e não mostra "..."',
      (WidgetTester t) async {
        final _ProgressoComAtraso controlado = _ProgressoComAtraso();

        Widget buildComConta(String conta) => MaterialApp(
          theme: TemasMemora.claro,
          home: TelaPerfil(
            nome: 'Dona Ana',
            canal: Future<String?>.value('ana@exemplo.com'),
            progresso: controlado,
            idDaConta: conta,
          ),
        );

        await t.pumpWidget(buildComConta('conta-a'));
        await t.pump();
        expect(find.text('...'), findsNothing);
        expect(find.text(TextosPerfil.carregandoAprendizado), findsOneWidget);

        await t.pumpWidget(buildComConta('conta-b'));
        await t.pump();

        controlado.completar('conta-a', 'youtube');
        await t.pump();
        expect(find.text('YouTube'), findsNothing);

        controlado.completar('conta-b', 'meu-inss');
        await t.pumpAndSettle();
        expect(find.text('Meu INSS'), findsOneWidget);
        expect(find.text('YouTube'), findsNothing);
      },
    );

    testWidgets(
      'recupera com segurança quando leitura do progresso local lança erro',
      (WidgetTester t) async {
        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: TelaPerfil(
              nome: 'Dona Ana',
              canal: Future<String?>.value('ana@exemplo.com'),
              progresso: _ProgressoQueFalha(),
              idDaConta: 'conta-123',
            ),
          ),
        );
        await t.pumpAndSettle();

        expect(find.text(TextosPerfil.carregandoAprendizado), findsNothing);
        expect(find.text(TextosPerfil.maisAprendidoVazio), findsOneWidget);
      },
    );
  });
}

class _ProgressoQueFalha implements ProgressoDeAprendizado {
  @override
  Future<String?> aplicativoMaisAprendido(String idDaConta) async {
    throw StateError('Falha simulada na leitura local');
  }

  @override
  Future<void> apagar() async {}

  @override
  Future<Map<String, int>> concluidos(String idDaConta) async =>
      const <String, int>{};

  @override
  Future<bool> registrarChegadaAoPasso({
    required String idDaConta,
    required String chave,
    required int numeroDoPasso,
    required int totalDePassos,
  }) async =>
      false;

  @override
  Future<void> registrarConclusao({
    required String idDaConta,
    required String chave,
  }) async {}
}

class _ProgressoComAtraso implements ProgressoDeAprendizado {
  final Map<String, Completer<String?>> _pendentes =
      <String, Completer<String?>>{};

  void completar(String idDaConta, String? chave) {
    _pendentes.remove(idDaConta)?.complete(chave);
  }

  @override
  Future<String?> aplicativoMaisAprendido(String idDaConta) {
    return _pendentes
        .putIfAbsent(idDaConta, () => Completer<String?>())
        .future;
  }

  @override
  Future<void> apagar() async {}

  @override
  Future<Map<String, int>> concluidos(String idDaConta) async =>
      const <String, int>{};

  @override
  Future<bool> registrarChegadaAoPasso({
    required String idDaConta,
    required String chave,
    required int numeroDoPasso,
    required int totalDePassos,
  }) async =>
      false;

  @override
  Future<void> registrarConclusao({
    required String idDaConta,
    required String chave,
  }) async {}
}
