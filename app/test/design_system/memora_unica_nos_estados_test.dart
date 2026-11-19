import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/ajuda/data/compartilhar.dart';
import 'package:memora/features/ajuda/domain/assunto_de_ajuda.dart';
import 'package:memora/features/ajuda/presentation/tela_assunto.dart';
import 'package:memora/features/aprendizado/domain/guia.dart';
import 'package:memora/features/aprendizado/presentation/tela_passo_a_passo.dart';
import 'package:memora/features/assistente/data/catalogo_guardado.dart';
import 'package:memora/features/assistente/data/conversa_local.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/assistente/presentation/controladores/controlador_conversa.dart';
import 'package:memora/features/assistente/presentation/telas/tela_catalogo.dart';
import 'package:memora/features/assistente/presentation/telas/tela_conversa.dart';
import 'package:memora/features/assistente/presentation/telas/tela_registro.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/domain/autenticacao.dart';
import 'package:memora/features/autenticacao/presentation/controladores/controlador_cadastro.dart';
import 'package:memora/features/autenticacao/presentation/controladores/controlador_login.dart';
import 'package:memora/features/autenticacao/presentation/controladores/controlador_recuperacao.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_cadastro.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_login.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_recuperacao.dart';
import 'package:memora/features/cuidado/data/provedores/provedor_telemetria_simulado.dart';
import 'package:memora/features/cuidado/data/repositorios/repositorio_contato_emergencia_local.dart';
import 'package:memora/features/cuidado/presentation/controladores/controlador_dispositivo_cuidado.dart';
import 'package:memora/features/cuidado/presentation/telas/tela_dispositivo_cuidado.dart';
import 'package:memora/features/hub/domain/hub.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';
import 'package:memora/l10n/textos_ajuda.dart';
import 'package:memora/l10n/textos_assistente.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/autenticacao/dubles_autenticacao.dart';
import '../suporte/aceite_em_memoria.dart';
import '../suporte/fonte.dart';

/// Os estados de carregando, vazio e erro mostram a Memora na expressão certa,
/// **e uma só por tela** (feature 013, T073 e T096; FR-001, FR-002, FR-006).
///
/// ## A regra
///
/// | Estado | Expressão | Quando a tela já tem a dela |
/// |---|---|---|
/// | Carregando | `carregando` (segura a barra) | a outra cede (T095) |
/// | Vazio | `falando` | `EstadoVazio(comMemora: false)` |
/// | Erro | `preocupada` | `MensagemErro(comMemora: false)` |
///
/// Um estado que **traz** a Memora dele ao lado da Memora do cartão, da barra
/// ou do balão deixa a tela com duas. O componente sozinho não sabe: quem sabe
/// é a tela, e este arquivo é o que a obriga a saber.
///
/// Cada caso monta a tela real no estado e conta as [MemoraAnimada] da árvore.
/// `MemoraPersonagem`, o balão e a barra desenham todos uma `MemoraAnimada`,
/// então a contagem pega a Memora de onde ela vier.

Widget _app(Widget filho) => MaterialApp(theme: TemasMemora.claro, home: filho);

/// Todas as Memoras na árvore, de qualquer pose.
Finder get _memoras => find.byType(MemoraAnimada);

Finder _naPose(PoseDaMemora pose) => find.byWidgetPredicate(
  (Widget w) => w is MemoraAnimada && w.expressao == pose,
);

void _celular(WidgetTester t) {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<void> _avancar(WidgetTester t) async {
  for (int quadro = 0; quadro < 6; quadro++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// A tela na pose esperada, e só uma Memora na árvore.
void _umaNaPose(PoseDaMemora pose, String onde) {
  expect(
    _memoras,
    findsOneWidget,
    reason: '$onde: FR-006 — uma Memora só na tela.',
  );
  expect(
    _naPose(pose),
    findsOneWidget,
    reason: '$onde: FR-001/FR-002 — a expressão tem de combinar com o estado.',
  );
}

/// O registro cuja lista não chega.
class _RegistroQueFalha implements RepositorioAssistente {
  @override
  Future<List<AcaoRegistrada>> registro() async =>
      throw Exception('sem conexão');

  @override
  Future<RespostaDaAssistente> conversar({
    required String mensagem,
    required List<MensagemDaConversa> historico,
    void Function(String trecho)? aoReceberTrecho,
    void Function(void Function() cancelar)? aoCriarCancelamento,
  }) => throw UnimplementedError();

  @override
  Future<List<ServicoDoCatalogo>> catalogo() => throw UnimplementedError();

  @override
  Future<void> registrarAcao({
    required String servicoId,
    required String pedidoResumido,
  }) => throw UnimplementedError();
}

class _ConversaEmMemoria implements ConversaLocal {
  List<MensagemDaConversa> _guardadas = <MensagemDaConversa>[];

  @override
  Future<List<MensagemDaConversa>> ler() async => _guardadas;

  @override
  Future<void> guardar(List<MensagemDaConversa> mensagens) async =>
      _guardadas = List<MensagemDaConversa>.from(mensagens);

  @override
  Future<void> apagar() async => _guardadas = <MensagemDaConversa>[];
}

/// O login recusa e o cadastro/recuperação falham, de pronto.
class _RepositorioQueRecusa extends RepositorioDeTeste {
  @override
  Future<ResultadoAutenticacao> entrar(DadosDeEntrada dados) async =>
      const AutenticacaoFalhou(FalhaAutenticacao.credenciaisInvalidas);

  @override
  Future<ResultadoAutenticacao> renovarSessao() async =>
      const AutenticacaoFalhou(FalhaAutenticacao.credenciaisInvalidas);

  @override
  Future<ResultadoDeCanal> solicitarRecuperacao(String identificador) async =>
      const CanalFalhou(FalhaAutenticacao.semConexao);
}

Finder _entrada(Key chave) =>
    find.descendant(of: find.byKey(chave), matching: find.byType(TextField));

Future<void> _digitar(WidgetTester t, Key chave, String valor) async {
  await t.ensureVisible(_entrada(chave));
  await t.enterText(_entrada(chave), valor);
  await t.pump();
}

Future<void> _tocar(WidgetTester t, Key chave) async {
  await t.ensureVisible(find.byKey(chave));
  await t.tap(find.byKey(chave));
  await t.pump(const Duration(milliseconds: 10));
  await t.pump(const Duration(milliseconds: 10));
}

void main() {
  setUpAll(carregarAtkinson);

  group('Registro: o cartão tem a Memora, o estado não traz outra (T096)', () {
    testWidgets('carregando: só a que segura a barra', (WidgetTester t) async {
      _celular(t);
      await t.pumpWidget(
        _app(
          TelaRegistro(
            repositorio: RepositorioAssistenteSimulado(demora: Duration.zero),
          ),
        ),
      );

      _umaNaPose(PoseDaMemora.carregando, 'registro carregando');
    });

    testWidgets('vazio: só a do cartão, falando', (WidgetTester t) async {
      _celular(t);
      await t.pumpWidget(
        _app(
          TelaRegistro(
            repositorio: RepositorioAssistenteSimulado(demora: Duration.zero),
          ),
        ),
      );
      await _avancar(t);

      expect(find.byType(EstadoVazio), findsOneWidget);
      _umaNaPose(PoseDaMemora.falando, 'registro vazio');
    });

    testWidgets('erro: só a do cartão, e a mensagem continua', (
      WidgetTester t,
    ) async {
      _celular(t);
      await t.pumpWidget(_app(TelaRegistro(repositorio: _RegistroQueFalha())));
      await _avancar(t);

      expect(find.byType(MensagemErro), findsOneWidget);
      expect(find.text(TextosAssistente.semConexao), findsOneWidget);
      _umaNaPose(PoseDaMemora.falando, 'registro com erro');
    });
  });

  group('Catálogo (T073, T096)', () {
    for (final (String estado, PoseDaMemora pose) in <(String, PoseDaMemora)>[
      ('carregando', PoseDaMemora.carregando),
      ('erro', PoseDaMemora.preocupada),
      ('vazio', PoseDaMemora.falando),
    ]) {
      testWidgets('$estado: uma Memora, na pose do estado', (
        WidgetTester t,
      ) async {
        _celular(t);
        await t.pumpWidget(
          _app(
            TelaCatalogo(
              repositorio: RepositorioAssistenteSimulado(demora: Duration.zero),
              categoria: CategoriaDoServico.cotidiano,
              estadoDeTeste: estado,
            ),
          ),
        );
        await t.pump(const Duration(milliseconds: 50));

        _umaNaPose(pose, 'catálogo $estado');
      });
    }

    testWidgets('nada achado na aba dos serviços sociais: só a do cartão', (
      WidgetTester t,
    ) async {
      _celular(t);
      await t.pumpWidget(
        _app(
          TelaCatalogo(
            repositorio: RepositorioAssistenteSimulado(demora: Duration.zero),
            categoria: CategoriaDoServico.cotidiano,
          ),
        ),
      );
      await _avancar(t);

      await t.tap(find.text('Serviços sociais'));
      await _avancar(t);
      await _digitar(t, TelaCatalogo.chaveBusca, 'zzzxxyy');
      await _avancar(t);

      expect(find.text('Nenhum aplicativo encontrado'), findsOneWidget);
      // O cartão que explica por que a Memora não abre serviço sensível.
      _umaNaPose(PoseDaMemora.dica, 'catálogo sensível sem resultado');
    });

    testWidgets('nada achado na aba comum: a Memora do estado, falando', (
      WidgetTester t,
    ) async {
      _celular(t);
      await t.pumpWidget(
        _app(
          TelaCatalogo(
            repositorio: RepositorioAssistenteSimulado(demora: Duration.zero),
            categoria: CategoriaDoServico.cotidiano,
          ),
        ),
      );
      await _avancar(t);

      await _digitar(t, TelaCatalogo.chaveBusca, 'zzzxxyy');
      await _avancar(t);

      expect(find.text('Nenhum aplicativo encontrado'), findsOneWidget);
      _umaNaPose(PoseDaMemora.falando, 'catálogo comum sem resultado');
    });
  });

  testWidgets('Conversa com erro: só a da barra, sem a preocupada (T096)', (
    WidgetTester t,
  ) async {
    _celular(t);
    final ControladorConversa c = ControladorConversa(
      RepositorioAssistenteSimulado(
        demora: Duration.zero,
        falhaForcada: FalhaDaAssistente.semConexao,
      ),
      _ConversaEmMemoria(),
      aceite: AceiteEmMemoria(),
    );
    addTearDown(c.dispose);
    await t.pumpWidget(_app(TelaConversa(controlador: c)));
    await _avancar(t);
    await t.enterText(find.byKey(TelaConversa.chaveCampo), 'oi');
    await _avancar(t);
    await t.ensureVisible(find.byKey(TelaConversa.chaveEnviar));
    await t.pump();
    await t.tap(find.byKey(TelaConversa.chaveEnviar));
    await _avancar(t);

    expect(find.byKey(TelaConversa.chaveErro), findsOneWidget);
    // O rosto do convite é a voz dela e não conta (FR-006 e FR-042, rev.
    // 2026-11-18); fora dele, só a da barra.
    final Finder doConvite = find.descendant(
      of: find.byKey(TelaConversa.chaveConvite),
      matching: _memoras,
    );
    expect(doConvite, findsOneWidget);
    expect(
      _memoras.evaluate().length - doConvite.evaluate().length,
      1,
      reason: 'FR-006: a da barra, e só.',
    );
    expect(_naPose(PoseDaMemora.preocupada), findsNothing);
  });

  testWidgets('Ajuda, falha ao compartilhar: só a do balão (T096)', (
    WidgetTester t,
  ) async {
    _celular(t);
    final CompartilhadorSimulado envio = CompartilhadorSimulado(
      'https://exemplo.memora.invalid',
    )..falharNoProximo = true;
    final AssuntoDeAjuda assunto = AssuntoDeAjuda.disponiveis(
      podeCompartilhar: true,
    ).firstWhere((AssuntoDeAjuda a) => a.id == IdDoAssunto.compartilhar);
    await t.pumpWidget(
      _app(
        TelaAssunto(assunto: assunto, compartilhador: envio, aoVoltar: () {}),
      ),
    );

    Future<void> tocarAdiante(Finder alvo) async {
      await t.ensureVisible(alvo);
      await t.pump();
      await t.tap(alvo);
      await t.pump(const Duration(milliseconds: 50));
      await t.pump(const Duration(milliseconds: 400));
    }

    await tocarAdiante(find.byKey(TelaAssunto.chaveCompartilhar));
    await tocarAdiante(find.text(TextosAjuda.simCompartilhar));

    expect(find.byKey(TelaAssunto.chaveErro), findsOneWidget);
    expect(_naPose(PoseDaMemora.preocupada), findsNothing);
    expect(_memoras.evaluate().length, lessThanOrEqualTo(1), reason: 'FR-006.');
  });

  group('Autenticação: o cartão tem a Memora, o erro não traz outra', () {
    testWidgets('login recusado: só a do cartão', (WidgetTester t) async {
      _celular(t);
      final ControladorLogin c = ControladorLogin(
        _RepositorioQueRecusa(),
        UltimoAcessoEmMemoria(),
      );
      addTearDown(c.dispose);
      await t.pumpWidget(
        _app(TelaLogin(controlador: c, aoEntrar: (PessoaAutenticada _) {})),
      );
      await t.pump(const Duration(milliseconds: 10));
      await t.pump(const Duration(milliseconds: 10));
      await _digitar(t, TelaLogin.chaveIdentificador, 'ana@email.com');
      await _digitar(t, TelaLogin.chaveSenha, 'uma frase que so eu lembro');
      await _tocar(t, TelaLogin.chaveEntrar);

      expect(find.byType(MensagemErro), findsOneWidget);
      expect(_memoras, findsOneWidget, reason: 'FR-006: a do cartão, e só.');
      expect(_naPose(PoseDaMemora.preocupada), findsNothing);
    });

    testWidgets('cadastro com falha: só a do convite', (WidgetTester t) async {
      _celular(t);
      final ControladorCadastro c = ControladorCadastro(
        RepositorioAutenticacaoSimulado(
          demora: Duration.zero,
          falhaForcada: FalhaAutenticacao.semConexao,
        ),
      );
      addTearDown(c.dispose);
      await t.pumpWidget(
        _app(
          TelaCadastro(controlador: c, aoConcluir: (PessoaAutenticada _) {}),
        ),
      );
      await _digitar(t, TelaCadastro.chaveNome, 'Ana');
      await _digitar(t, TelaCadastro.chaveCanal, 'ana@email.com');
      await _digitar(t, TelaCadastro.chaveSenha, 'uma frase que so eu lembro');
      await _tocar(t, TelaCadastro.chaveEnviar);

      expect(find.byType(MensagemErro), findsOneWidget);
      expect(_memoras, findsOneWidget, reason: 'FR-006: a do convite, e só.');
      expect(_naPose(PoseDaMemora.preocupada), findsNothing);
    });

    testWidgets('recuperação com falha: o erro não acrescenta Memora', (
      WidgetTester t,
    ) async {
      _celular(t);
      final ControladorRecuperacao c = ControladorRecuperacao(
        _RepositorioQueRecusa(),
      );
      addTearDown(c.dispose);
      await t.pumpWidget(
        _app(
          TelaRecuperacao(controlador: c, aoConcluir: (PessoaAutenticada _) {}),
        ),
      );
      // TODO(T073): em repouso a tela tem duas (o rosto do aviso antigolpe e o
      // do convite) — fixado em `espera_com_uma_memora_test.dart` desde a
      // T095, contra a FR-006. Decidir qual sai é de desenho, não de estado.
      final int emRepouso = _memoras.evaluate().length;

      await _digitar(t, TelaRecuperacao.chaveIdentificador, 'ana@email.com');
      await _tocar(t, TelaRecuperacao.chavePedirCodigo);

      expect(find.byType(MensagemErro), findsOneWidget);
      expect(
        _memoras.evaluate().length,
        emRepouso,
        reason: 'O erro não pode acrescentar uma Memora à tela.',
      );
    });
  });

  testWidgets('Cuidado: a Memora do painel é a única da tela (T096)', (
    WidgetTester t,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    _celular(t);
    final ControladorDispositivoCuidado c = ControladorDispositivoCuidado(
      repositorioContato: RepositorioContatoEmergenciaLocal(),
      provedorInicial: ProvedorDeTelemetriaSimulado(),
    );
    addTearDown(c.dispose);
    await t.pumpWidget(
      _app(TelaDispositivoCuidado(controlador: c, aoVoltar: () {})),
    );
    await t.pump();

    expect(_memoras, findsOneWidget, reason: 'FR-006: a do painel, e só.');
  });

  testWidgets('Hub sem portas: a Memora do estado vazio, falando', (
    WidgetTester t,
  ) async {
    _celular(t);
    await t.pumpWidget(
      _app(TelaHub(portas: const <PortaDoHub>[], aoVoltar: () {})),
    );
    await t.pump();

    expect(find.byType(EstadoVazio), findsOneWidget);
    _umaNaPose(PoseDaMemora.falando, 'hub vazio');
  });

  group('Passo a passo: a barra não traz Memora, o estado traz a dele', () {
    final Guia guia = Guia(
      chave: 'tiktok',
      titulo: 'Aprender a usar o TikTok',
      capturadoEm: DateTime(2026, 10),
      versaoCapturada: '34.0.0',
    );

    for (final (String estado, PoseDaMemora pose) in <(String, PoseDaMemora)>[
      ('carregando', PoseDaMemora.carregando),
      ('erro', PoseDaMemora.preocupada),
      ('vazio', PoseDaMemora.falando),
    ]) {
      testWidgets('$estado: uma Memora, na pose do estado', (
        WidgetTester t,
      ) async {
        _celular(t);
        await t.pumpWidget(
          _app(
            TelaPassoAPasso(
              guia: guia,
              origemDoCatalogo: OrigemDoCatalogo.servidor,
              estadoDeTeste: estado,
            ),
          ),
        );
        await t.pump(const Duration(milliseconds: 50));

        _umaNaPose(pose, 'passo a passo $estado');
      });
    }
  });
}
