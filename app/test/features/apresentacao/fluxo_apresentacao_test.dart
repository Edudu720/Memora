import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/apresentacao/data/apresentacao_vista.dart';
import 'package:memora/features/apresentacao/presentation/fluxo_apresentacao.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/presentation/fluxo_autenticacao.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_cadastro.dart';
import 'package:memora/features/casca/casca_interna.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_login.dart';
import 'package:memora/features/inicio/presentation/tela_inicio.dart';
import 'package:memora/l10n/textos_apresentacao.dart';
import 'package:memora/l10n/textos_autenticacao.dart';
import 'package:memora/l10n/textos_casca.dart';
import 'package:memora/services/seguranca/limpeza_de_sessao.dart';

import '../../suporte/aparelhos.dart';
import '../../suporte/estados_de_tela.dart';
import '../autenticacao/dubles_autenticacao.dart';
import '../autenticacao/fluxo_dentro_da_conta.dart';

/// A apresentação da Memora (T045, US1, FR-012, FR-013, FR-036a): três telas
/// com "Continuar" e "Pular", que aparecem **uma vez por conta**, dizem o que
/// ninguém do Memora faz e cabem em todos os aparelhos.
///
/// Dois níveis, de propósito. As telas sozinhas respondem pelo desenho e pelo
/// que cada botão grava; o **fluxo de verdade** (`FluxoAutenticacao`, o mesmo
/// que o `main.dart` monta) responde pelo que a pessoa vê: testar o componente
/// não prova a tela que o aplicativo mostra.
void main() {
  const String contaAna = 'conta-ana';
  const String senha = 'uma frase que so eu lembro';

  Future<void> avancar(WidgetTester t, [int quadros = 6]) =>
      FluxoDentroDaConta.avancar(t, quadros);

  Future<void> tocar(WidgetTester t, Finder alvo) =>
      FluxoDentroDaConta.tocar(t, alvo);

  Finder tela(int indice) => find.byKey(FluxoApresentacao.chaveDaTela(indice));

  // ---------------------------------------------------------------------------
  // As três telas, sozinhas
  // ---------------------------------------------------------------------------

  group('As três telas', () {
    late ApresentacaoVistaEmMemoria vistas;
    late int concluiu;
    late int fechou;

    setUp(() {
      vistas = ApresentacaoVistaEmMemoria();
      concluiu = 0;
      fechou = 0;
    });

    Widget app({ApresentacaoVista? vista, String nome = 'Ana'}) {
      return MaterialApp(
        theme: TemasMemora.claro,
        home: FluxoApresentacao(
          nome: nome,
          idDaConta: contaAna,
          vista: vista ?? vistas,
          aoConcluir: () => concluiu++,
          aoFecharOMemora: () async => fechou++,
        ),
      );
    }

    Future<void> montar(WidgetTester t, {ApresentacaoVista? vista}) async {
      await t.pumpWidget(app(vista: vista));
      await avancar(t);
    }

    testWidgets('são três, cada uma com Continuar e Pular', (t) async {
      await montar(t);

      for (int i = 0; i < FluxoApresentacao.totalDeTelas; i++) {
        expect(tela(i), findsOneWidget, reason: 'a tela ${i + 1} existe');
        expect(
          find.byKey(FluxoApresentacao.chaveContinuar),
          findsOneWidget,
          reason: 'a tela ${i + 1} tem "Continuar"',
        );
        expect(
          find.byKey(FluxoApresentacao.chavePular),
          findsOneWidget,
          reason: 'a tela ${i + 1} tem "Pular"',
        );
        expect(find.text(TextosApresentacao.continuar), findsOneWidget);
        expect(find.text(TextosApresentacao.pular), findsOneWidget);
        expect(
          find.text(TextosApresentacao.passo(i + 1, 3)),
          findsOneWidget,
          reason: 'a pessoa sabe quanto falta',
        );

        if (i < FluxoApresentacao.totalDeTelas - 1) {
          await tocar(t, find.byKey(FluxoApresentacao.chaveContinuar));
          expect(concluiu, 0, reason: 'ainda não é o fim');
        }
      }
      expect(FluxoApresentacao.totalDeTelas, lessThanOrEqualTo(3));
    });

    testWidgets('a primeira chama a pessoa pelo nome; sem nome, não inventa', (
      t,
    ) async {
      await t.pumpWidget(app());
      await avancar(t);
      expect(find.textContaining('Olá, Ana!'), findsOneWidget);

      await t.pumpWidget(app(nome: '  '));
      await avancar(t);
      expect(find.textContaining('Olá! Eu sou a Memora'), findsOneWidget);
    });

    testWidgets('chegar ao fim grava como vista e conclui', (t) async {
      await montar(t);
      expect(await vistas.jaViu(contaAna), isFalse);

      await tocar(t, find.byKey(FluxoApresentacao.chaveContinuar));
      await tocar(t, find.byKey(FluxoApresentacao.chaveContinuar));
      expect(await vistas.jaViu(contaAna), isFalse, reason: 'faltou a última');

      await tocar(t, find.byKey(FluxoApresentacao.chaveContinuar));

      expect(await vistas.jaViu(contaAna), isTrue);
      expect(concluiu, 1);
    });

    for (int i = 0; i < FluxoApresentacao.totalDeTelas; i++) {
      testWidgets('pular na tela ${i + 1} grava como vista e conclui', (
        t,
      ) async {
        await montar(t);
        for (int passo = 0; passo < i; passo++) {
          await tocar(t, find.byKey(FluxoApresentacao.chaveContinuar));
        }
        expect(tela(i), findsOneWidget);

        await tocar(t, find.byKey(FluxoApresentacao.chavePular));

        expect(await vistas.jaViu(contaAna), isTrue);
        expect(concluiu, 1);
      });
    }

    testWidgets('interrompida no meio, não grava nada e recomeça do início', (
      t,
    ) async {
      await montar(t);
      await tocar(t, find.byKey(FluxoApresentacao.chaveContinuar));
      expect(tela(1), findsOneWidget);

      // O aplicativo é fechado aqui: a tela sai da árvore sem concluir.
      await t.pumpWidget(const SizedBox());
      expect(
        await vistas.jaViu(contaAna),
        isFalse,
        reason: 'interrompida no meio não conta como vista (FR-013)',
      );
      expect(concluiu, 0);

      // E ao abrir de novo, é a primeira tela.
      await montar(t);
      expect(tela(0), findsOneWidget);
      expect(tela(1), findsNothing);
    });

    testWidgets('"voltar" do aparelho na tela 3 e na 2 volta uma tela, sem '
        'gravar nada (FR-013)', (t) async {
      await montar(t);
      await tocar(t, find.byKey(FluxoApresentacao.chaveContinuar));
      await tocar(t, find.byKey(FluxoApresentacao.chaveContinuar));
      expect(tela(2), findsOneWidget);

      expect(await t.binding.handlePopRoute(), isTrue);
      await avancar(t);
      expect(tela(1), findsOneWidget);

      expect(await t.binding.handlePopRoute(), isTrue);
      await avancar(t);
      expect(tela(0), findsOneWidget);

      expect(fechou, 0, reason: 'voltar de tela não fecha o aplicativo');
      expect(concluiu, 0);
      expect(
        await vistas.jaViu(contaAna),
        isFalse,
        reason: 'só o fim ou o pulo gravam a apresentação como vista',
      );
    });

    testWidgets('"voltar" do aparelho na tela 1 pergunta antes de fechar', (
      t,
    ) async {
      await montar(t);

      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.byKey(CascaInterna.chavePerguntaDeFechar), findsOneWidget);
      expect(fechou, 0, reason: 'fechar em silêncio é o Memora sumir');

      await t.tap(find.text(TextosCasca.botaoFicar));
      await t.pumpAndSettle();
      expect(find.byKey(CascaInterna.chavePerguntaDeFechar), findsNothing);
      expect(tela(0), findsOneWidget, reason: 'ficou onde estava');
      expect(fechou, 0);

      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      await t.tap(find.text(TextosCasca.botaoFecharMemora));
      await t.pumpAndSettle();
      expect(fechou, 1);
      expect(concluiu, 0);
      expect(await vistas.jaViu(contaAna), isFalse);
    });

    testWidgets('dois toques seguidos em Pular concluem uma vez só', (t) async {
      await montar(t);

      final Finder pular = find.byKey(FluxoApresentacao.chavePular);
      await t.tap(pular);
      await t.tap(pular);
      await avancar(t);

      expect(concluiu, 1);
    });

    testWidgets('se gravar falhar, a pessoa segue do mesmo jeito', (t) async {
      await montar(t, vista: _VistaQueFalhaAoGravar());

      await tocar(t, find.byKey(FluxoApresentacao.chavePular));

      expect(
        concluiu,
        1,
        reason: 'uma gravação recusada não pode prender a pessoa na tela',
      );
      expect(t.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // O que a Memora nunca faz (FR-036a)
  // ---------------------------------------------------------------------------

  group('A primeira tela diz o que ninguém do Memora faz (FR-036a)', () {
    Future<void> montarPrimeira(WidgetTester t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: FluxoApresentacao(
            nome: 'Ana',
            idDaConta: contaAna,
            vista: ApresentacaoVistaEmMemoria(),
            aoConcluir: () {},
          ),
        ),
      );
      await avancar(t);
    }

    String textoDe(WidgetTester t, Finder dentro) {
      return t
          .widgetList<Text>(
            find.descendant(of: dentro, matching: find.byType(Text)),
          )
          .map((Text x) => x.data ?? '')
          .join(' ');
    }

    testWidgets('o quadro existe na primeira tela, e só nela', (t) async {
      await montarPrimeira(t);
      expect(find.byKey(FluxoApresentacao.chaveNuncaFaco), findsOneWidget);
      expect(find.text(TextosApresentacao.tituloNunca), findsOneWidget);

      await tocar(t, find.byKey(FluxoApresentacao.chaveContinuar));
      expect(find.byKey(FluxoApresentacao.chaveNuncaFaco), findsNothing);
    });

    testWidgets('diz, em linguagem comum, as quatro coisas que ninguém faz', (
      t,
    ) async {
      await montarPrimeira(t);
      final String dito = textoDe(
        t,
        find.byKey(FluxoApresentacao.chaveNuncaFaco),
      ).toLowerCase();

      // Pedir senha ou código, por telefone, mensagem ou e-mail.
      expect(dito, contains('senha'));
      expect(dito, contains('código'));
      expect(dito, contains('telefone'));
      expect(dito, contains('mensagem'));
      expect(dito, contains('e-mail'));
      // Ligar para a pessoa.
      expect(dito, contains('liga para você'));
      // Pedir para instalar fora da loja oficial, ou "para o Memora funcionar".
      expect(dito, contains('loja oficial'));
      expect(dito, contains('para o memora funcionar'));
      // Cobrar.
      expect(dito, contains('cobro'));
      // E o que fazer.
      expect(dito, contains('golpe'));
      expect(dito, contains('desligar'));
    });

    testWidgets('não diz que o Memora "nunca pede senha" sem a ressalva', (
      t,
    ) async {
      // O Memora pede a senha no login, na recuperação e na confirmação do
      // canal. A frase só é verdade com o meio: "por telefone, mensagem ou
      // e-mail". Sem ele a apresentação mentiria no primeiro minuto de uso.
      for (final String frase in TextosApresentacao.nuncaFaco) {
        if (frase.toLowerCase().contains('senha')) {
          expect(frase, contains('por telefone, mensagem ou e-mail'));
        }
      }
    });

    testWidgets('o quadro é informação: nada nele responde ao toque', (
      t,
    ) async {
      await montarPrimeira(t);
      final Finder quadro = find.byKey(FluxoApresentacao.chaveNuncaFaco);

      for (final Type tipo in <Type>[
        InkWell,
        GestureDetector,
        BotaoPrimario,
        BotaoSecundario,
        BotaoTerciario,
      ]) {
        expect(
          find.descendant(of: quadro, matching: find.byType(tipo)),
          findsNothing,
          reason: 'informação nunca é ação (FR-012 da 002): $tipo',
        );
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Os estados da FR-006
  // ---------------------------------------------------------------------------

  group('Os estados da FR-006', () {
    testWidgets('a espera pela conferência tem desenho e frase', (t) async {
      // As três telas não carregam nada, e por isso não têm vazio nem erro. O
      // único instante de espera é o da conferência, entre entrar e saber se a
      // conta já viu a apresentação.
      await exigirOsEstadosDaFr006(
        t,
        tela: 'Preparando a apresentação',
        montar: (EstadoDaTela estado) => estado == EstadoDaTela.carregando
            ? MaterialApp(
                theme: TemasMemora.claro,
                home: const TelaPreparandoApresentacao(),
              )
            : null,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // A matriz (FR-044)
  // ---------------------------------------------------------------------------

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
      testWidgets('as três telas cabem em ${nomeDa(c)}', (t) async {
        vestir(t, c.aparelho);
        await t.pumpWidget(
          naCombinacao(
            c,
            FluxoApresentacao(
              nome: 'Maria Aparecida',
              idDaConta: contaAna,
              vista: ApresentacaoVistaEmMemoria(),
              aoConcluir: () {},
            ),
          ),
        );
        await avancar(t);

        for (int i = 0; i < FluxoApresentacao.totalDeTelas; i++) {
          final String contexto = '${nomeDa(c)}, tela ${i + 1}';
          expect(tela(i), findsOneWidget, reason: contexto);
          expect(t.takeException(), isNull, reason: contexto);

          // As duas saídas precisam estar à mão: "Pular" visível sem rolar
          // (FR-012) e "Continuar" alcançável depois de rolar.
          final Rect pular = t.getRect(
            find.byKey(FluxoApresentacao.chavePular),
          );
          expect(
            pular.top >= 0 && pular.bottom <= c.aparelho.height,
            isTrue,
            reason:
                '$contexto: "Pular" precisa estar à vista sem rolar ($pular)',
          );
          expect(
            pular.right,
            lessThanOrEqualTo(c.aparelho.width),
            reason: '$contexto: "Pular" passou da largura ($pular)',
          );
          await exigirAlcancavel(
            t,
            find.byKey(FluxoApresentacao.chaveContinuar),
            aparelho: c.aparelho,
            contexto: contexto,
          );
          if (i == 0) {
            // Um parágrafo a 200% num 360x640 é mais alto que a janela, e não
            // precisa caber: precisa que se **comece a lê-lo** (o topo à
            // vista, dentro da largura) e que a rolagem leve até o fim.
            for (final String ponta in <String>[
              TextosApresentacao.tituloNunca,
              ...TextosApresentacao.nuncaFaco,
              TextosApresentacao.seAlguemPedir,
            ]) {
              final Finder texto = find.text(ponta);
              await t.ensureVisible(texto);
              await t.pump();
              final Rect r = t.getRect(texto);
              expect(
                r.top >= 0 && r.top < c.aparelho.height,
                isTrue,
                reason: '$contexto: o começo de "$ponta" ficou fora ($r)',
              );
              expect(
                r.left >= 0 && r.right <= c.aparelho.width,
                isTrue,
                reason: '$contexto: "$ponta" passou da largura ($r)',
              );
            }
          }

          if (i < FluxoApresentacao.totalDeTelas - 1) {
            // Rolar até o ponto de ler o quadro afasta o botão da janela.
            await tocar(t, find.byKey(FluxoApresentacao.chaveContinuar));
          }
        }
      });
    }
  });

  // ---------------------------------------------------------------------------
  // Pelo fluxo de verdade
  // ---------------------------------------------------------------------------

  group('Pelo fluxo de verdade', () {
    late ApresentacaoVistaEmMemoria vistas;
    late UltimoAcessoEmMemoria ultimoAcesso;
    late RepositorioAutenticacaoSimulado repositorio;
    late CofreQueRegistra cofre;
    late LimpezaDeSessao limpeza;

    setUp(() {
      vistas = ApresentacaoVistaEmMemoria();
      ultimoAcesso = UltimoAcessoEmMemoria();
      cofre = CofreQueRegistra();
      repositorio = RepositorioAutenticacaoSimulado(demora: Duration.zero)
        ..registrarConta(
          identificador: 'ana@email.com',
          senha: senha,
          nome: 'Ana',
        )
        ..registrarConta(
          identificador: 'bia@email.com',
          senha: senha,
          nome: 'Bia',
        );
      limpeza = LimpezaDeSessao(
        cofre: cofre,
        ultimoAcesso: ultimoAcesso,
        dadosDoAparelho: <DadoLocalDoAparelho>[vistas],
      );
    });

    Future<void> montar(
      WidgetTester t, {
      ApresentacaoVista? vista,
      Duration inatividade = const Duration(minutes: 30),
      Duration aviso = const Duration(minutes: 2),
      Combinacao? em,
    }) async {
      if (em != null) vestir(t, em.aparelho);
      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.porId(em?.tema ?? MemoraTemaId.claro),
          builder: em == null
              ? null
              : (BuildContext contexto, Widget? filho) => MediaQuery(
                  data: MediaQuery.of(
                    contexto,
                  ).copyWith(textScaler: TextScaler.linear(em.escala)),
                  child: filho!,
                ),
          home: FluxoAutenticacao(
            repositorio: repositorio,
            ultimoAcesso: ultimoAcesso,
            limpeza: limpeza,
            apresentacaoVista: vista ?? vistas,
            inatividade: inatividade,
            avisoDeInatividade: aviso,
          ),
        ),
      );
      await avancar(t);
    }

    Future<void> preencher(WidgetTester t, Key chave, String valor) async {
      final Finder entrada = find.descendant(
        of: find.byKey(chave),
        matching: find.byType(TextField),
      );
      await t.ensureVisible(entrada);
      await t.enterText(entrada, valor);
      await t.pump();
    }

    /// Com o login na tela, preenche e entra.
    Future<void> preencherLogin(WidgetTester t, String quem) async {
      await preencher(t, TelaLogin.chaveIdentificador, '$quem@email.com');
      await preencher(t, TelaLogin.chaveSenha, senha);
      await tocar(t, find.byKey(TelaLogin.chaveEntrar));
      await avancar(t, 8);
    }

    /// Das boas-vindas até ter entrado pelo login.
    Future<void> entrarPeloLogin(WidgetTester t, String quem) async {
      await tocar(t, find.text(TextosAutenticacao.botaoJaTenhoConta));
      await preencherLogin(t, quem);
    }

    Future<void> cadastrar(WidgetTester t) async {
      await tocar(t, find.text(TextosAutenticacao.botaoComecar));
      await preencher(t, TelaCadastro.chaveNome, 'Carla');
      await preencher(t, TelaCadastro.chaveCanal, 'carla@email.com');
      await preencher(t, TelaCadastro.chaveSenha, senha);
      await tocar(t, find.byKey(TelaCadastro.chaveEnviar));
      await avancar(t, 8);
    }

    /// Sai da conta pelo caminho de verdade: Ajustes, Sair, confirmar.
    Future<void> sair(WidgetTester t) async {
      await FluxoDentroDaConta.tocarEmSair(t);
      await tocar(t, find.text(TextosAutenticacao.botaoConfirmarSaida));
      await avancar(t, 8);
      expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
    }

    void exigirApresentacao(String motivo) {
      expect(
        find.byKey(FluxoApresentacao.chaveContinuar),
        findsOneWidget,
        reason: motivo,
      );
      expect(
        find.byKey(TelaInicio.chaveSaudacao),
        findsNothing,
        reason: motivo,
      );
    }

    void exigirInicioDireto(String motivo) {
      expect(
        find.byKey(TelaInicio.chaveSaudacao),
        findsOneWidget,
        reason: motivo,
      );
      expect(
        find.byKey(FluxoApresentacao.chaveContinuar),
        findsNothing,
        reason: motivo,
      );
    }

    Future<void> fechar(WidgetTester t) async {
      // O monitor de inatividade tem um Timer vivo enquanto a pessoa está
      // dentro; descartar a árvore o cancela antes da checagem do teste.
      await t.pumpWidget(const SizedBox());
    }

    testWidgets('depois da primeira entrada, a apresentação aparece', (
      t,
    ) async {
      await montar(t);
      await entrarPeloLogin(t, 'ana');

      exigirApresentacao('conta que nunca a viu passa por ela');
      expect(find.textContaining('Olá, Ana!'), findsOneWidget);
      expect(find.byKey(FluxoApresentacao.chavePular), findsOneWidget);

      await fechar(t);
    });

    testWidgets('depois do cadastro, a apresentação aparece', (t) async {
      await montar(t);
      await cadastrar(t);

      exigirApresentacao('quem acabou de criar a conta a vê (FR-009 e FR-012)');
      expect(find.textContaining('Olá, Carla!'), findsOneWidget);

      await fechar(t);
    });

    testWidgets('pular leva ao Início e grava como vista', (t) async {
      await montar(t);
      await entrarPeloLogin(t, 'ana');

      await tocar(t, find.byKey(FluxoApresentacao.chavePular));

      exigirInicioDireto('Pular leva ao Início (US1, cenário 3)');
      expect(
        await vistas.jaViu('simulado-${'ana@email.com'.hashCode.abs()}'),
        isTrue,
      );

      await fechar(t);
    });

    testWidgets('percorrer até o fim também leva ao Início', (t) async {
      await montar(t);
      await entrarPeloLogin(t, 'ana');

      await tocar(t, find.byKey(FluxoApresentacao.chaveContinuar));
      await tocar(t, find.byKey(FluxoApresentacao.chaveContinuar));
      expect(tela(2), findsOneWidget);
      await tocar(t, find.byKey(FluxoApresentacao.chaveContinuar));

      exigirInicioDireto('o fim leva ao Início');

      await fechar(t);
    });

    testWidgets('NÃO aparece de novo depois de sair e entrar (FR-013)', (
      t,
    ) async {
      await montar(t);
      await entrarPeloLogin(t, 'ana');
      await tocar(t, find.byKey(FluxoApresentacao.chavePular));
      exigirInicioDireto('primeira vez');

      await sair(t);
      await preencherLogin(t, 'ana');

      exigirInicioDireto(
        'uma vez por conta: quem já viu não vê de novo ao entrar (FR-013)',
      );

      await fechar(t);
    });

    testWidgets('quem chegou ao fim também não a vê de novo', (t) async {
      await montar(t);
      await entrarPeloLogin(t, 'ana');
      for (int i = 0; i < 3; i++) {
        await tocar(t, find.byKey(FluxoApresentacao.chaveContinuar));
      }

      await sair(t);
      await preencherLogin(t, 'ana');

      exigirInicioDireto('o fim conta como vista');

      await fechar(t);
    });

    testWidgets('outra conta no mesmo aparelho ainda a vê', (t) async {
      await montar(t);
      await entrarPeloLogin(t, 'ana');
      await tocar(t, find.byKey(FluxoApresentacao.chavePular));
      await sair(t);

      await preencherLogin(t, 'bia');

      exigirApresentacao(
        'a Bia nunca viu: é uma vez por CONTA, não por aparelho',
      );
      expect(find.textContaining('Olá, Bia!'), findsOneWidget);

      await fechar(t);
    });

    testWidgets(
      'a saída comum mantém, e o esquecerTudo devolve a apresentação',
      (t) async {
        await montar(t);
        await entrarPeloLogin(t, 'ana');
        await tocar(t, find.byKey(FluxoApresentacao.chavePular));

        // A saída pela tela é a comum: a conta continua tendo visto.
        await sair(t);
        expect(
          await vistas.jaViu('simulado-${'ana@email.com'.hashCode.abs()}'),
          isTrue,
        );

        // Aparelho que vai ser vendido: esquece tudo (R11).
        await limpeza.executar(esquecerTudo: true);
        await preencherLogin(t, 'ana');

        exigirApresentacao('sem a marca, a conta é como nova');

        await fechar(t);
      },
    );

    testWidgets('interrompida no meio, na próxima entrada recomeça', (t) async {
      await montar(t);
      await entrarPeloLogin(t, 'ana');
      await tocar(t, find.byKey(FluxoApresentacao.chaveContinuar));
      expect(tela(1), findsOneWidget);

      // O aplicativo é fechado no meio e aberto de novo.
      await fechar(t);
      await montar(t);
      // A sessão continua válida no repositório: ao abrir o login, ela é
      // renovada em silêncio (FR-016) e a pessoa entra sem digitar nada.
      await tocar(t, find.text(TextosAutenticacao.botaoJaTenhoConta));
      await avancar(t, 8);

      exigirApresentacao('não terminou nem pulou: não foi vista');
      expect(tela(0), findsOneWidget, reason: 'recomeça do início');

      await fechar(t);
    });

    testWidgets(
      'enquanto confere, mostra desenho e frase, não tela em branco',
      (t) async {
        final _VistaLenta lenta = _VistaLenta();
        await montar(t, vista: lenta);
        await entrarPeloLogin(t, 'ana');

        expect(find.byType(Carregando), findsOneWidget);
        expect(find.text(TextosApresentacao.preparando), findsOneWidget);
        expect(find.byKey(TelaInicio.chaveSaudacao), findsNothing);

        lenta.responder(jaViu: true);
        await avancar(t);

        exigirInicioDireto('a conta já tinha visto');

        await fechar(t);
      },
    );

    testWidgets(
      'se a leitura falhar, mostra a apresentação (e dá para pular)',
      (t) async {
        await montar(t, vista: _VistaQueFalhaAoLer());
        await entrarPeloLogin(t, 'ana');

        exigirApresentacao('sem saber, a pessoa vê uma tela pulável');
        await tocar(t, find.byKey(FluxoApresentacao.chavePular));
        exigirInicioDireto('e segue');

        await fechar(t);
      },
    );

    testWidgets('sair no meio da conferência não abre a apresentação depois', (
      t,
    ) async {
      final _VistaLenta lenta = _VistaLenta();
      await montar(
        t,
        vista: lenta,
        inatividade: const Duration(seconds: 3),
        aviso: const Duration(seconds: 1),
      );
      await entrarPeloLogin(t, 'ana');
      expect(find.byType(Carregando), findsOneWidget);

      // A sessão expira enquanto a conferência ainda não respondeu.
      await t.pump(const Duration(seconds: 2));
      await avancar(t);
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(milliseconds: 50));
      await t.pump(const Duration(seconds: 1));
      expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);

      lenta.responder(jaViu: false);
      await avancar(t);

      expect(
        find.byKey(TelaLogin.chaveEntrar),
        findsOneWidget,
        reason: 'a resposta tardia não pode tirar a pessoa do login',
      );
      expect(find.byKey(FluxoApresentacao.chaveContinuar), findsNothing);
    });

    testWidgets(
      'a resposta velha da conferência não decide pela entrada nova',
      (t) async {
        final _VistaLentaPorLeitura lenta = _VistaLentaPorLeitura();
        await montar(
          t,
          vista: lenta,
          inatividade: const Duration(seconds: 3),
          aviso: const Duration(seconds: 1),
        );
        await entrarPeloLogin(t, 'ana');
        expect(lenta.leituras, 1);

        // A sessão da Ana expira com a leitura dela ainda no ar.
        await t.pump(const Duration(seconds: 2));
        await avancar(t);
        await t.pump(const Duration(seconds: 1));
        await t.pump(const Duration(milliseconds: 50));
        await t.pump(const Duration(seconds: 1));
        expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);

        // A Bia entra, e a leitura dela também fica no ar.
        await preencherLogin(t, 'bia');
        expect(lenta.leituras, 2);
        expect(find.byType(Carregando), findsOneWidget);

        // A leitura velha (a da Ana: "já viu") chega agora.
        lenta.responder(0, jaViu: true);
        await avancar(t);
        expect(
          find.byType(Carregando),
          findsOneWidget,
          reason: 'a resposta da Ana não decide pela entrada da Bia',
        );
        expect(find.byKey(TelaInicio.chaveSaudacao), findsNothing);

        // A leitura da Bia ("nunca viu") é a que vale.
        lenta.responder(1, jaViu: false);
        await avancar(t);
        exigirApresentacao('a Bia nunca a viu');
        expect(find.textContaining('Olá, Bia!'), findsOneWidget);

        await fechar(t);
      },
    );

    testWidgets('a inatividade vale também durante a apresentação', (t) async {
      await montar(
        t,
        inatividade: const Duration(seconds: 3),
        aviso: const Duration(seconds: 1),
      );
      await entrarPeloLogin(t, 'ana');
      exigirApresentacao('o cenário pressupõe a apresentação na tela');

      await t.pump(const Duration(seconds: 2));
      await avancar(t);
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(milliseconds: 50));
      await t.pump(const Duration(seconds: 1));

      expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
      expect(find.byKey(FluxoApresentacao.chaveContinuar), findsNothing);
      expect(
        await vistas.jaViu('simulado-${'ana@email.com'.hashCode.abs()}'),
        isFalse,
        reason: 'expirar não é pular',
      );
    });

    testWidgets('tocar na apresentação conta como atividade', (t) async {
      await montar(
        t,
        inatividade: const Duration(seconds: 3),
        aviso: const Duration(seconds: 1),
      );
      await entrarPeloLogin(t, 'ana');
      exigirApresentacao('o cenário pressupõe a apresentação na tela');

      for (int i = 0; i < 5; i++) {
        await t.pump(const Duration(seconds: 1));
        // O aviso não pode estar na tela antes do toque: o "Continuar" dele
        // registra atividade sozinho e esconderia um `Listener` quebrado.
        expect(
          find.text(TextosAutenticacao.tituloAvisoInatividade),
          findsNothing,
          reason: 'o aviso apareceu no meio da atividade',
        );
        await t.tap(find.text(TextosApresentacao.tituloOla));
        await avancar(t);
      }

      expect(
        find.byKey(FluxoApresentacao.chaveContinuar),
        findsOneWidget,
        reason: 'quem lê devagar não pode ser expulso',
      );
      expect(find.byKey(TelaLogin.chaveEntrar), findsNothing);

      await fechar(t);
    });

    testWidgets('a apresentação, pelo fluxo, cabe no 320x568 a 200%', (
      t,
    ) async {
      final Combinacao c = (
        aparelho: aparelhos.last,
        escala: 2.0,
        tema: MemoraTemaId.claro,
      );
      await montar(t, em: c);
      await entrarPeloLogin(t, 'ana');

      exigirApresentacao('o cenário pressupõe a apresentação na tela');
      expect(t.takeException(), isNull);
      await exigirAlcancavel(
        t,
        find.byKey(FluxoApresentacao.chaveContinuar),
        aparelho: c.aparelho,
        contexto: nomeDa(c),
      );

      await fechar(t);
    });
  });
}

/// Uma guarda cuja leitura só responde quando o teste manda.
class _VistaLenta implements ApresentacaoVista {
  final Completer<bool> _resposta = Completer<bool>();

  void responder({required bool jaViu}) => _resposta.complete(jaViu);

  @override
  Future<bool> jaViu(String idDaConta) => _resposta.future;

  @override
  Future<void> marcarComoVista(String idDaConta) async {}
}

/// Cada leitura de `jaViu` fica no ar até o teste responder àquela, pela
/// ordem em que foram feitas.
class _VistaLentaPorLeitura implements ApresentacaoVista {
  final List<Completer<bool>> _respostas = <Completer<bool>>[];

  int get leituras => _respostas.length;

  void responder(int leitura, {required bool jaViu}) =>
      _respostas[leitura].complete(jaViu);

  @override
  Future<bool> jaViu(String idDaConta) {
    final Completer<bool> c = Completer<bool>();
    _respostas.add(c);
    return c.future;
  }

  @override
  Future<void> marcarComoVista(String idDaConta) async {}
}

class _VistaQueFalhaAoLer implements ApresentacaoVista {
  @override
  Future<bool> jaViu(String idDaConta) async => throw StateError('disco');

  @override
  Future<void> marcarComoVista(String idDaConta) async {}
}

class _VistaQueFalhaAoGravar implements ApresentacaoVista {
  @override
  Future<bool> jaViu(String idDaConta) async => false;

  @override
  Future<void> marcarComoVista(String idDaConta) async =>
      throw StateError('disco cheio');
}
