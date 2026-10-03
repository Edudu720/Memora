import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/casca/casca_interna.dart';
import 'package:memora/features/casca/raizes_provisorias.dart';
import 'package:memora/features/perfil/data/data_de_nascimento_local.dart';
import 'package:memora/features/perfil/domain/data_de_nascimento.dart';
import 'package:memora/features/perfil/presentation/secao_idade.dart';
import 'package:memora/features/perfil/presentation/tela_data_de_nascimento.dart';
import 'package:memora/l10n/textos_perfil.dart';

import '../../suporte/aparelhos.dart';
import '../autenticacao/fluxo_dentro_da_conta.dart';

/// A idade no Perfil (T123, FR-042c): o convite, a idade como informação, a
/// tela de entrada com as recusas e a matriz de aparelhos.
void main() {
  const String conta = 'conta-ana';
  final DateTime hoje = DateTime(2026, 10, 2);
  final DataDeNascimento nascida = DataDeNascimento.deArmazenado('1952-03-15')!;

  Future<void> avancar(WidgetTester t, [int quadros = 6]) async {
    for (int i = 0; i < quadros; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Widget seccao(DataDeNascimentoEmMemoria datas, {String id = conta}) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(MemoraEspacamento.lg),
        children: <Widget>[
          SecaoIdade(armazenamento: datas, idDaConta: id, agora: () => hoje),
        ],
      ),
    );
  }

  Future<void> montar(
    WidgetTester t,
    DataDeNascimentoEmMemoria datas, {
    Combinacao? em,
  }) async {
    if (em != null) vestir(t, em.aparelho);
    await t.pumpWidget(
      em == null
          ? MaterialApp(theme: TemasMemora.claro, home: seccao(datas))
          : naCombinacao(em, seccao(datas)),
    );
    await avancar(t);
  }

  Future<void> tocar(WidgetTester t, Finder alvo) async {
    await t.ensureVisible(alvo);
    await t.pump();
    await t.tap(alvo);
    await avancar(t);
  }

  Future<void> preencher(WidgetTester t, Key chave, String valor) async {
    final Finder campo = find.descendant(
      of: find.byKey(chave),
      matching: find.byType(TextField),
    );
    await t.ensureVisible(campo);
    await t.enterText(campo, valor);
    await t.pump();
  }

  Future<void> preencherData(
    WidgetTester t,
    String dia,
    String mes,
    String ano,
  ) async {
    await preencher(t, TelaDataDeNascimento.chaveDia, dia);
    await preencher(t, TelaDataDeNascimento.chaveMes, mes);
    await preencher(t, TelaDataDeNascimento.chaveAno, ano);
  }

  group('Sem data: o convite', () {
    testWidgets('mostra o convite e um botão, e nenhuma idade', (t) async {
      await montar(t, DataDeNascimentoEmMemoria());

      expect(find.byKey(SecaoIdade.chaveConvite), findsOneWidget);
      expect(find.text(TextosPerfil.botaoInformar), findsOneWidget);
      expect(find.byKey(SecaoIdade.chaveIdade), findsNothing);
      expect(find.byKey(SecaoIdade.chaveTirar), findsNothing);
    });

    testWidgets('o convite diz que é opcional e que fica no aparelho', (
      t,
    ) async {
      await montar(t, DataDeNascimentoEmMemoria());

      expect(TextosPerfil.convite, contains('não precisa'));
      expect(TextosPerfil.convite, contains('só neste aparelho'));
    });
  });

  group('Com data: a idade é informação', () {
    testWidgets('mostra a idade calculada, como CampoInformacao', (t) async {
      final DataDeNascimentoEmMemoria datas = DataDeNascimentoEmMemoria();
      await datas.guardar(conta, nascida);
      await montar(t, datas);

      expect(find.byKey(SecaoIdade.chaveIdade), findsOneWidget);
      expect(
        t.widget<CampoInformacao>(find.byKey(SecaoIdade.chaveIdade)),
        isA<CampoInformacao>()
            .having((c) => c.rotulo, 'rótulo', TextosPerfil.rotuloIdade)
            .having((c) => c.valor, 'valor', '74 anos'),
      );
      expect(find.byKey(SecaoIdade.chaveConvite), findsNothing);
    });

    testWidgets('a idade não responde ao toque (nada clicável dentro dela)', (
      t,
    ) async {
      final DataDeNascimentoEmMemoria datas = DataDeNascimentoEmMemoria();
      await datas.guardar(conta, nascida);
      await montar(t, datas);

      final Finder dentro = find.byKey(SecaoIdade.chaveIdade);
      expect(
        find.descendant(of: dentro, matching: find.byType(InkWell)),
        findsNothing,
      );
      expect(
        find.descendant(of: dentro, matching: find.byType(GestureDetector)),
        findsNothing,
      );
      expect(
        find.descendant(of: dentro, matching: find.byType(BotaoPrimario)),
        findsNothing,
      );
    });

    testWidgets('a data de outra conta não aparece', (t) async {
      final DataDeNascimentoEmMemoria datas = DataDeNascimentoEmMemoria();
      await datas.guardar('conta-bia', nascida);
      await montar(t, datas);

      expect(find.byKey(SecaoIdade.chaveIdade), findsNothing);
      expect(find.byKey(SecaoIdade.chaveConvite), findsOneWidget);
    });

    testWidgets('mudar e tirar ficam logo abaixo da idade', (t) async {
      final DataDeNascimentoEmMemoria datas = DataDeNascimentoEmMemoria();
      await datas.guardar(conta, nascida);
      await montar(t, datas);

      expect(find.text(TextosPerfil.botaoMudar), findsOneWidget);
      expect(find.text(TextosPerfil.botaoTirar), findsOneWidget);
    });
  });

  group('Tirar a idade pede confirmação', () {
    testWidgets('tocar em tirar só pergunta; a data continua guardada', (
      t,
    ) async {
      final DataDeNascimentoEmMemoria datas = DataDeNascimentoEmMemoria();
      await datas.guardar(conta, nascida);
      await montar(t, datas);

      await tocar(t, find.byKey(SecaoIdade.chaveTirar));

      expect(find.byKey(SecaoIdade.chaveConfirmacao), findsOneWidget);
      expect(await datas.ler(conta), nascida);
    });

    testWidgets('confirmar apaga e volta ao convite', (t) async {
      final DataDeNascimentoEmMemoria datas = DataDeNascimentoEmMemoria();
      await datas.guardar(conta, nascida);
      await montar(t, datas);

      await tocar(t, find.byKey(SecaoIdade.chaveTirar));
      await tocar(t, find.text(TextosPerfil.botaoConfirmarTirar));

      expect(await datas.ler(conta), isNull);
      expect(find.byKey(SecaoIdade.chaveConvite), findsOneWidget);
      expect(find.byKey(SecaoIdade.chaveIdade), findsNothing);
    });

    testWidgets('recusar mantém a data', (t) async {
      final DataDeNascimentoEmMemoria datas = DataDeNascimentoEmMemoria();
      await datas.guardar(conta, nascida);
      await montar(t, datas);

      await tocar(t, find.byKey(SecaoIdade.chaveTirar));
      await tocar(t, find.text(TextosPerfil.botaoManter));

      expect(await datas.ler(conta), nascida);
      expect(find.byKey(SecaoIdade.chaveIdade), findsOneWidget);
      expect(find.byKey(SecaoIdade.chaveConfirmacao), findsNothing);
    });
  });

  group('A tela de entrada', () {
    Future<DataDeNascimentoEmMemoria> abrir(WidgetTester t) async {
      final DataDeNascimentoEmMemoria datas = DataDeNascimentoEmMemoria();
      await montar(t, datas);
      await tocar(t, find.byKey(SecaoIdade.chaveInformar));
      expect(find.byKey(TelaDataDeNascimento.chaveDia), findsOneWidget);
      return datas;
    }

    testWidgets('tem três campos numéricos separados', (t) async {
      await abrir(t);

      for (final Key chave in <Key>[
        TelaDataDeNascimento.chaveDia,
        TelaDataDeNascimento.chaveMes,
        TelaDataDeNascimento.chaveAno,
      ]) {
        final TextField campo = t.widget<TextField>(
          find.descendant(
            of: find.byKey(chave),
            matching: find.byType(TextField),
          ),
        );
        expect(campo.keyboardType, TextInputType.number);
      }
      expect(find.text(TextosPerfil.rotuloDia), findsOneWidget);
      expect(find.text(TextosPerfil.rotuloMes), findsOneWidget);
      expect(find.text(TextosPerfil.rotuloAno), findsOneWidget);
    });

    testWidgets('guardar mostra a idade na seção', (t) async {
      final DataDeNascimentoEmMemoria datas = await abrir(t);

      await preencherData(t, '15', '3', '1952');
      await tocar(t, find.byKey(TelaDataDeNascimento.chaveGuardar));

      expect(find.byKey(TelaDataDeNascimento.chaveDia), findsNothing);
      expect(find.text('74 anos'), findsOneWidget);
      expect(await datas.ler(conta), nascida);
    });

    testWidgets('cancelar não guarda nada', (t) async {
      final DataDeNascimentoEmMemoria datas = await abrir(t);

      await preencherData(t, '15', '3', '1952');
      await tocar(t, find.byKey(TelaDataDeNascimento.chaveCancelar));

      expect(find.byKey(TelaDataDeNascimento.chaveDia), findsNothing);
      expect(find.byKey(SecaoIdade.chaveConvite), findsOneWidget);
      expect(await datas.ler(conta), isNull);
    });

    testWidgets('mudar abre já preenchido', (t) async {
      final DataDeNascimentoEmMemoria datas = DataDeNascimentoEmMemoria();
      await datas.guardar(conta, nascida);
      await montar(t, datas);

      await tocar(t, find.byKey(SecaoIdade.chaveInformar));

      String texto(Key chave) => t
          .widget<TextField>(
            find.descendant(
              of: find.byKey(chave),
              matching: find.byType(TextField),
            ),
          )
          .controller!
          .text;
      expect(texto(TelaDataDeNascimento.chaveDia), '15');
      expect(texto(TelaDataDeNascimento.chaveMes), '3');
      expect(texto(TelaDataDeNascimento.chaveAno), '1952');
    });

    final List<(String, String, String, String, String)> recusas =
        <(String, String, String, String, String)>[
          ('data futura', '3', '10', '2026', TextosPerfil.erroFutura),
          (
            'data impossível (31/02)',
            '31',
            '2',
            '1952',
            TextosPerfil.erroImpossivel,
          ),
          ('mês 13', '15', '13', '1952', TextosPerfil.erroImpossivel),
          ('ano de dois dígitos', '15', '3', '52', TextosPerfil.erroAnoCurto),
          ('mais de 120 anos', '15', '3', '1900', TextosPerfil.erroAntiga),
          ('campo vazio', '15', '', '1952', TextosPerfil.erroIncompleta),
        ];
    for (final (String nome, String d, String m, String a, String erro)
        in recusas) {
      testWidgets('recusa $nome, com texto claro, e não guarda', (t) async {
        final DataDeNascimentoEmMemoria datas = await abrir(t);

        await preencherData(t, d, m, a);
        await tocar(t, find.byKey(TelaDataDeNascimento.chaveGuardar));

        expect(find.text(erro), findsOneWidget);
        expect(
          find.byKey(TelaDataDeNascimento.chaveDia),
          findsOneWidget,
          reason: 'continua na tela de entrada',
        );
        expect(await datas.ler(conta), isNull);
      });
    }

    testWidgets('corrigir depois do erro funciona', (t) async {
      final DataDeNascimentoEmMemoria datas = await abrir(t);

      await preencherData(t, '31', '2', '1952');
      await tocar(t, find.byKey(TelaDataDeNascimento.chaveGuardar));
      expect(find.text(TextosPerfil.erroImpossivel), findsOneWidget);

      await preencher(t, TelaDataDeNascimento.chaveDia, '28');
      await tocar(t, find.byKey(TelaDataDeNascimento.chaveGuardar));

      expect(await datas.ler(conta), isNotNull);
      expect(find.text('74 anos'), findsOneWidget);
    });
  });

  group('Matriz de aparelhos (FR-044)', () {
    final List<Combinacao> combinacoes = matriz(
      temas: <MemoraTemaId>[MemoraTemaId.claro],
    ).toList();

    for (final Combinacao c in combinacoes) {
      testWidgets('o convite cabe em ${nomeDa(c)}', (t) async {
        await montar(t, DataDeNascimentoEmMemoria(), em: c);

        expect(t.takeException(), isNull, reason: nomeDa(c));
        await exigirAlcancavel(
          t,
          find.byKey(SecaoIdade.chaveInformar),
          aparelho: c.aparelho,
          contexto: nomeDa(c),
        );
      });

      testWidgets('a idade e as ações cabem em ${nomeDa(c)}', (t) async {
        final DataDeNascimentoEmMemoria datas = DataDeNascimentoEmMemoria();
        await datas.guardar(conta, nascida);
        await montar(t, datas, em: c);

        expect(t.takeException(), isNull, reason: nomeDa(c));
        await exigirAlcancavel(
          t,
          find.byKey(SecaoIdade.chaveTirar),
          aparelho: c.aparelho,
          contexto: nomeDa(c),
        );
        await tocar(t, find.byKey(SecaoIdade.chaveTirar));
        expect(t.takeException(), isNull, reason: '${nomeDa(c)} (confirmação)');
        await exigirAlcancavel(
          t,
          find.text(TextosPerfil.botaoConfirmarTirar),
          aparelho: c.aparelho,
          contexto: '${nomeDa(c)} (confirmação)',
        );
      });

      testWidgets('a tela de entrada, com erro, cabe em ${nomeDa(c)}', (
        t,
      ) async {
        await montar(t, DataDeNascimentoEmMemoria(), em: c);
        await tocar(t, find.byKey(SecaoIdade.chaveInformar));

        await preencherData(t, '31', '2', '1952');
        await tocar(t, find.byKey(TelaDataDeNascimento.chaveGuardar));
        expect(find.text(TextosPerfil.erroImpossivel), findsOneWidget);
        expect(t.takeException(), isNull, reason: nomeDa(c));

        await preencher(t, TelaDataDeNascimento.chaveDia, '15');
        await preencher(t, TelaDataDeNascimento.chaveMes, '3');
        await preencher(t, TelaDataDeNascimento.chaveAno, '1952');
        await exigirAlcancavel(
          t,
          find.byKey(TelaDataDeNascimento.chaveGuardar),
          aparelho: c.aparelho,
          contexto: nomeDa(c),
        );
        await t.tap(find.byKey(TelaDataDeNascimento.chaveGuardar));
        await avancar(t);

        expect(
          find.text('74 anos'),
          findsOneWidget,
          reason: '${nomeDa(c)}: o botão alcançável também guarda',
        );
      });
    }
  });

  group('Pelo fluxo de verdade', () {
    testWidgets('o Perfil convida, guarda e mostra a idade da conta', (
      t,
    ) async {
      final DataDeNascimentoEmMemoria datas = DataDeNascimentoEmMemoria();
      await FluxoDentroDaConta().montar(t, datas: datas);

      await FluxoDentroDaConta.irPara(t, DestinoDaCasca.perfil);
      expect(find.byKey(SecaoIdade.chaveConvite), findsOneWidget);

      await tocar(t, find.byKey(SecaoIdade.chaveInformar));
      await preencherData(t, '15', '3', '1952');
      await tocar(t, find.byKey(TelaDataDeNascimento.chaveGuardar));

      expect(find.byKey(SecaoIdade.chaveIdade), findsOneWidget);
      expect(find.byType(PerfilProvisorio), findsOneWidget);
    });
  });
}
