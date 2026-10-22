import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/componentes/botoes/botao_base.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/casca/casca_interna.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_login.dart';
import 'package:memora/features/casca/raizes_provisorias.dart';
import 'package:memora/features/perfil/data/data_de_nascimento_local.dart';
import 'package:memora/features/perfil/domain/data_de_nascimento.dart';
import 'package:memora/features/perfil/presentation/secao_idade.dart';
import 'package:memora/features/perfil/presentation/tela_data_de_nascimento.dart';
import 'package:memora/features/perfil/presentation/tela_perfil.dart';
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

    testWidgets('mês fora do calendário: o erro aparece no campo Mês', (
      t,
    ) async {
      await abrir(t);

      await preencherData(t, '15', '13', '1952');
      await tocar(t, find.byKey(TelaDataDeNascimento.chaveGuardar));

      final Finder erro = find.text(TextosPerfil.erroImpossivel);
      expect(erro, findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(TelaDataDeNascimento.chaveMes),
          matching: erro,
        ),
        findsOneWidget,
        reason: 'o campo a corrigir é o mês',
      );
    });

    testWidgets('dia que não existe no mês: o erro continua no campo Dia', (
      t,
    ) async {
      await abrir(t);

      await preencherData(t, '31', '2', '1952');
      await tocar(t, find.byKey(TelaDataDeNascimento.chaveGuardar));

      expect(
        find.descendant(
          of: find.byKey(TelaDataDeNascimento.chaveDia),
          matching: find.text(TextosPerfil.erroImpossivel),
        ),
        findsOneWidget,
      );
    });

    testWidgets('se guardar falhar, avisa e destrava os botões', (t) async {
      final _QueFalhaAoGuardar datas = _QueFalhaAoGuardar();
      await montar(t, datas);
      await tocar(t, find.byKey(SecaoIdade.chaveInformar));

      await preencherData(t, '15', '3', '1952');
      await tocar(t, find.byKey(TelaDataDeNascimento.chaveGuardar));

      expect(
        find.byKey(TelaDataDeNascimento.chaveErroAoGuardar),
        findsOneWidget,
      );
      expect(find.text(TextosPerfil.erroAoGuardar), findsOneWidget);
      expect(
        find.byKey(TelaDataDeNascimento.chaveDia),
        findsOneWidget,
        reason: 'continua na tela de entrada',
      );
      for (final Key chave in <Key>[
        TelaDataDeNascimento.chaveGuardar,
        TelaDataDeNascimento.chaveCancelar,
      ]) {
        await t.ensureVisible(find.byKey(chave));
        expect(
          t
              .widget<BotaoBase>(
                find.descendant(
                  of: find.byKey(chave),
                  matching: find.byType(BotaoBase),
                ),
              )
              .aoTocar,
          isNotNull,
          reason: 'botão travado depois da falha',
        );
      }

      // E dá para tentar de novo.
      datas.falha = false;
      await tocar(t, find.byKey(TelaDataDeNascimento.chaveGuardar));
      expect(find.byKey(SecaoIdade.chaveIdade), findsOneWidget);
    });

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
    // A matriz completa no tema claro; os três temas só no aparelho mais
    // estreito, a 200% — o padrão da galeria.
    final List<Combinacao> combinacoes = <Combinacao>[
      ...matriz(temas: <MemoraTemaId>[MemoraTemaId.claro]),
      ...matriz(
        de: <Size>[aparelhos.last],
        em: <double>[2.0],
        temas: <MemoraTemaId>[MemoraTemaId.escuro, MemoraTemaId.altoContraste],
      ),
    ];

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

  group('O Perfil sem id de conta não mostra a idade', () {
    Future<void> perfil(
      WidgetTester t,
      ArmazenamentoDaDataDeNascimento datas,
      String? id,
    ) async {
      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: PerfilProvisorio(
            nome: 'Ana',
            canal: Future<String?>.value('ana@email.com'),
            dataDeNascimento: datas,
            idDaConta: id,
          ),
        ),
      );
      await avancar(t);
    }

    for (final String? id in <String?>[null, '', '   ']) {
      testWidgets('id ${id == null ? 'ausente' : "'$id'"}', (t) async {
        // Uma guarda que daria a data a qualquer id, até o vazio: a tela é que
        // não pode perguntar.
        await perfil(t, _QueDaAData(nascida), id);

        expect(find.byType(SecaoIdade), findsNothing);
        expect(find.byKey(SecaoIdade.chaveIdade), findsNothing);
        expect(find.byKey(SecaoIdade.chaveConvite), findsNothing);
      });
    }

    testWidgets('com id de verdade, a seção aparece', (t) async {
      await perfil(t, DataDeNascimentoEmMemoria(), conta);
      expect(find.byType(SecaoIdade), findsOneWidget);
    });
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
      expect(find.byType(TelaPerfil), findsOneWidget);
    });

    testWidgets('uma conta não vê a idade de outra no mesmo aparelho', (
      t,
    ) async {
      // As mesmas instâncias entre as entradas: é o mesmo aparelho.
      final DataDeNascimentoEmMemoria datas = DataDeNascimentoEmMemoria();
      final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
      await fluxo.montar(t, datas: datas);
      fluxo.repositorio.registrarConta(
        identificador: 'bia@email.com',
        senha: 'outra frase que so a bia sabe',
        nome: 'Bia',
      );

      // A conta A informa a data.
      await FluxoDentroDaConta.irPara(t, DestinoDaCasca.perfil);
      await tocar(t, find.byKey(SecaoIdade.chaveInformar));
      await preencherData(t, '15', '3', '1952');
      await tocar(t, find.byKey(TelaDataDeNascimento.chaveGuardar));
      expect(find.byKey(SecaoIdade.chaveIdade), findsOneWidget);

      // A conta B entra no mesmo aparelho: vê o convite, nunca a idade de A.
      await FluxoDentroDaConta.sairConfirmando(t);
      expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
      await FluxoDentroDaConta.entrarComConta(
        t,
        'bia@email.com',
        'outra frase que so a bia sabe',
      );
      await FluxoDentroDaConta.irPara(t, DestinoDaCasca.perfil);
      expect(find.byKey(SecaoIdade.chaveConvite), findsOneWidget);
      expect(
        find.byKey(SecaoIdade.chaveIdade),
        findsNothing,
        reason: 'a idade de Ana não pode aparecer na conta da Bia',
      );

      // A volta de A: a saída comum manteve a data (FR-042c).
      await FluxoDentroDaConta.sairConfirmando(t);
      await FluxoDentroDaConta.entrarComConta(
        t,
        'ana@email.com',
        'uma frase que so eu lembro',
      );
      await FluxoDentroDaConta.irPara(t, DestinoDaCasca.perfil);
      expect(find.byKey(SecaoIdade.chaveIdade), findsOneWidget);
      expect(find.text('74 anos'), findsOneWidget);
      expect(find.byKey(SecaoIdade.chaveConvite), findsNothing);
    });
  });
}

/// Armazenamento cujo `guardar` falha enquanto [falha] for verdadeiro.
class _QueFalhaAoGuardar extends DataDeNascimentoEmMemoria {
  bool falha = true;

  @override
  Future<void> guardar(String idDaConta, DataDeNascimento data) async {
    if (falha) throw StateError('disco cheio');
    await super.guardar(idDaConta, data);
  }
}

/// Guarda que devolve [data] para qualquer id, inclusive o vazio.
class _QueDaAData implements ArmazenamentoDaDataDeNascimento {
  final DataDeNascimento data;

  _QueDaAData(this.data);

  @override
  Future<DataDeNascimento?> ler(String idDaConta) async => data;

  @override
  Future<void> guardar(String idDaConta, DataDeNascimento data) async {}

  @override
  Future<void> apagar(String idDaConta) async {}
}
