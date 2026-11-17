import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/presentation/fluxo_autenticacao.dart';
import 'package:memora/features/casca/casca_interna.dart';
import 'package:memora/features/cuidado/data/repositorios/repositorio_emergencia_sos_api.dart';
import 'package:memora/features/cuidado/data/repositorios/repositorio_emergencia_sos_simulado.dart';
import 'package:memora/features/cuidado/domain/entidades/contato_emergencia.dart';
import 'package:memora/features/cuidado/domain/entidades/evento_emergencia_sos.dart';
import 'package:memora/features/cuidado/domain/repositorios/repositorio_contato_emergencia.dart';
import 'package:memora/features/cuidado/presentation/controladores/controlador_sos_emergencia.dart';
import 'package:memora/features/cuidado/presentation/telas/dialogo_contato_emergencia.dart';
import 'package:memora/features/cuidado/presentation/telas/dialogo_sos_emergencia.dart';
import 'package:memora/features/cuidado/presentation/widgets/botao_sos_persistente.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';
import 'package:memora/features/inicio/presentation/tela_inicio.dart';
import 'package:memora/l10n/textos_autenticacao.dart';
import 'package:memora/l10n/textos_cuidado.dart';
import 'package:memora/l10n/textos_sos.dart';

import '../../../suporte/aparelhos.dart';
import '../../autenticacao/dubles_autenticacao.dart';
import '../../autenticacao/fluxo_dentro_da_conta.dart';

class _RepositorioContatoEmMemoria implements RepositorioContatoEmergencia {
  ContatoEmergencia? contato;

  _RepositorioContatoEmMemoria([this.contato]);

  @override
  Future<ContatoEmergencia?> obterContato() async => contato;

  @override
  Future<void> removerContato() async {
    contato = null;
  }

  @override
  Future<void> salvarContato(ContatoEmergencia contato) async {
    this.contato = contato;
  }
}

void main() {
  const ContatoEmergencia contatoPadrao = ContatoEmergencia(
    id: 'c1',
    nome: 'Maria Silva',
    telefone: '11988887777',
    parentesco: 'Filha',
  );

  Future<RepositorioEmergenciaSosSimulado> entrarNoFluxo(
    WidgetTester t, {
    ContatoEmergencia? contato = contatoPadrao,
    RepositorioEmergenciaSosSimulado? repositorioSos,
    Future<LocalizacaoSos?> Function()? obterLocalizacaoSos,
  }) async {
    final RepositorioEmergenciaSosSimulado sos =
        repositorioSos ?? RepositorioEmergenciaSosSimulado();
    final RepositorioAutenticacaoSimulado auth = RepositorioAutenticacaoSimulado(
      demora: Duration.zero,
    )..registrarConta(
        identificador: 'ana@email.com',
        senha: 'uma frase que so eu lembro',
        nome: 'Ana',
      );

    await t.pumpWidget(
      EscopoAparencia(
        controlador: ControladorAparencia(PreferenciaEmMemoria()),
        child: MaterialApp(
          theme: TemasMemora.claro,
          home: FluxoAutenticacao(
            repositorio: auth,
            assistente: RepositorioAssistenteSimulado(demora: Duration.zero),
            ultimoAcesso: UltimoAcessoEmMemoria(),
            emergenciaSos: sos,
            contatoEmergencia: _RepositorioContatoEmMemoria(contato),
            obterLocalizacaoSos: obterLocalizacaoSos,
          ),
        ),
      ),
    );
    await FluxoDentroDaConta.avancar(t);
    await FluxoDentroDaConta.tocar(
      t,
      find.text(TextosAutenticacao.botaoJaTenhoConta),
    );
    await FluxoDentroDaConta.entrarComConta(
      t,
      'ana@email.com',
      'uma frase que so eu lembro',
    );
    expect(find.byKey(TelaInicio.chaveSaudacao), findsOneWidget);
    return sos;
  }

  testWidgets(
    'botão SOS permanece visível e acessível nas 3 abas e em telas empilhadas',
    (WidgetTester t) async {
      await entrarNoFluxo(t);

      void validarBotao() {
        final Finder finder = find.byKey(CascaInterna.chaveBotaoSos);
        expect(finder, findsOneWidget);
        expect(find.text(TextosSos.rotuloBotaoSos), findsOneWidget);
        final Size tamanho = t.getSize(finder);
        expect(tamanho.width, greaterThanOrEqualTo(MemoraDimensoes.alvoMinimo));
        expect(tamanho.height, greaterThanOrEqualTo(MemoraDimensoes.alvoMinimo));
      }

      final SemanticsHandle handle = t.ensureSemantics();
      validarBotao();
      expect(
        t.getSemantics(find.byKey(CascaInterna.chaveBotaoSos)),
        matchesSemantics(
          label: TextosSos.rotuloBotaoSos,
          hint: TextosSos.semanticaBotaoSos,
          isButton: true,
          hasTapAction: true,
          isEnabled: true,
          hasEnabledState: true,
        ),
      );

      // Aba Ajustes
      await FluxoDentroDaConta.irPara(t, DestinoDaCasca.ajustes);
      validarBotao();

      // Aba Meu perfil
      await FluxoDentroDaConta.irPara(t, DestinoDaCasca.perfil);
      validarBotao();

      // Volta ao Início e empilha o Hub
      await FluxoDentroDaConta.irPara(t, DestinoDaCasca.inicio);
      await FluxoDentroDaConta.irAoHub(t);
      expect(find.byType(TelaHub), findsOneWidget);
      validarBotao();

      handle.dispose();
    },
  );

  testWidgets(
    'tocar no botão SOS abre confirmação; cancelar fecha sem enviar evento',
    (WidgetTester t) async {
      final RepositorioEmergenciaSosSimulado sos = await entrarNoFluxo(t);

      await t.tap(find.byKey(CascaInterna.chaveBotaoSos));
      await t.pumpAndSettle();

      expect(find.byKey(DialogoSosEmergencia.chaveDialogo), findsOneWidget);
      expect(find.text(TextosSos.tituloConfirmacao), findsOneWidget);
      expect(find.textContaining('Maria Silva'), findsOneWidget);

      await t.ensureVisible(find.byKey(DialogoSosEmergencia.chaveCancelar));
      await t.tap(find.byKey(DialogoSosEmergencia.chaveCancelar));
      await t.pumpAndSettle();

      expect(find.byKey(DialogoSosEmergencia.chaveDialogo), findsNothing);
      expect(sos.requisicoes, isEmpty);
      expect(sos.historico, isEmpty);
    },
  );

  testWidgets(
    'confirmar envia SOS_MANUAL com mensagem honesta sem prometer leitura',
    (WidgetTester t) async {
      final RepositorioEmergenciaSosSimulado sos = await entrarNoFluxo(t);

      await t.tap(find.byKey(CascaInterna.chaveBotaoSos));
      await t.pumpAndSettle();

      await t.ensureVisible(find.byKey(DialogoSosEmergencia.chaveConfirmar));
      await t.tap(find.byKey(DialogoSosEmergencia.chaveConfirmar));
      await t.pumpAndSettle();

      expect(sos.historico, hasLength(1));
      expect(sos.historico.single.tipo, TipoEventoEmergencia.sosManual);
      expect(sos.historico.single.estado, EstadoEventoSos.enviado);

      expect(find.text(TextosSos.tituloEnviado), findsOneWidget);
      expect(find.text(TextosSos.mensagemEnviado), findsOneWidget);
      expect(TextosSos.mensagemEnviado, contains('não confirma que o contato já leu'));
    },
  );

  testWidgets(
    'anexa localização somente quando autorizada e não bloqueia quando ausente',
    (WidgetTester t) async {
      const LocalizacaoSos coordenadas = LocalizacaoSos(
        latitude: -22.0154,
        longitude: -47.8911,
      );
      final RepositorioEmergenciaSosSimulado sosComLoc = await entrarNoFluxo(
        t,
        obterLocalizacaoSos: () async => coordenadas,
      );

      await t.tap(find.byKey(CascaInterna.chaveBotaoSos));
      await t.pumpAndSettle();
      expect(find.text(TextosSos.localizacaoAutorizada), findsOneWidget);

      await t.ensureVisible(find.byKey(DialogoSosEmergencia.chaveConfirmar));
      await t.tap(find.byKey(DialogoSosEmergencia.chaveConfirmar));
      await t.pumpAndSettle();
      expect(sosComLoc.historico.single.localizacao, coordenadas);

      // Sem permissão de localização
      final RepositorioEmergenciaSosSimulado sosSemLoc =
          RepositorioEmergenciaSosSimulado();
      final ControladorSosEmergencia controlador = ControladorSosEmergencia(
        repositorioSos: sosSemLoc,
        repositorioContato: _RepositorioContatoEmMemoria(contatoPadrao),
        obterLocalizacaoAutorizada: () async => null,
      );

      await controlador.prepararConfirmacao();
      await controlador.confirmarEnvioSos();

      expect(sosSemLoc.historico.single.localizacao, isNull);
      expect(controlador.etapa, EtapaFluxoSos.enviado);
      controlador.dispose();
    },
  );

  testWidgets(
    'exibe alternativas claras em falha de conexão e sem contato cadastrado',
    (WidgetTester t) async {
      final RepositorioEmergenciaSosSimulado sosRedeOff =
          RepositorioEmergenciaSosSimulado(simularErroConexao: true);
      int ligou192 = 0;

      final ControladorSosEmergencia ctrlRedeOff = ControladorSosEmergencia(
        repositorioSos: sosRedeOff,
        repositorioContato: _RepositorioContatoEmMemoria(contatoPadrao),
        aoLigar192: () async => ligou192++,
      );

      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: Builder(
            builder: (BuildContext _) => DialogoSosEmergencia(
              controlador: ctrlRedeOff,
            ),
          ),
        ),
      );
      await t.pumpAndSettle();

      await t.ensureVisible(find.byKey(DialogoSosEmergencia.chaveConfirmar));
      await t.tap(find.byKey(DialogoSosEmergencia.chaveConfirmar));
      await t.pumpAndSettle();

      expect(find.text(TextosSos.tituloFalhaConexao), findsOneWidget);
      expect(find.text(TextosSos.mensagemFalhaConexao), findsOneWidget);
      expect(find.byKey(DialogoSosEmergencia.chaveAcionarAparelho), findsOneWidget);
      expect(find.byKey(DialogoSosEmergencia.chaveLigar192), findsOneWidget);

      await t.ensureVisible(find.byKey(DialogoSosEmergencia.chaveLigar192));
      await t.tap(find.byKey(DialogoSosEmergencia.chaveLigar192));
      await t.pump();
      expect(ligou192, 1);

      ctrlRedeOff.dispose();

      // Sem contato cadastrado no fluxo
      await entrarNoFluxo(t, contato: null);
      await t.tap(find.byKey(CascaInterna.chaveBotaoSos));
      await t.pumpAndSettle();

      expect(find.text(TextosSos.mensagemSemContatoConfirmacao), findsOneWidget);
      expect(find.byKey(DialogoSosEmergencia.chaveLigar192), findsOneWidget);
    },
  );

  testWidgets(
    'cliques repetidos rápidos não geram solicitações SOS duplicadas',
    (WidgetTester t) async {
      final RepositorioEmergenciaSosSimulado sosLento =
          RepositorioEmergenciaSosSimulado(
            atraso: const Duration(milliseconds: 200),
          );
      final ControladorSosEmergencia ctrl = ControladorSosEmergencia(
        repositorioSos: sosLento,
        repositorioContato: _RepositorioContatoEmMemoria(contatoPadrao),
      );
      await ctrl.prepararConfirmacao();

      final Future<void> chamada1 = ctrl.confirmarEnvioSos();
      final Future<void> chamada2 = ctrl.confirmarEnvioSos();
      final Future<void> chamada3 = ctrl.confirmarEnvioSos();
      await t.pump(const Duration(milliseconds: 250));
      await Future.wait<void>(<Future<void>>[chamada1, chamada2, chamada3]);

      expect(sosLento.requisicoes, hasLength(1));
      expect(sosLento.historico, hasLength(1));
      expect(ctrl.etapa, EtapaFluxoSos.enviado);

      ctrl.dispose();
    },
  );

  testWidgets(
    'BotaoSosPersistente garante contraste elevado no tema alto contraste',
    (WidgetTester t) async {
      int toques = 0;
      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.altoContraste,
          home: Scaffold(
            body: Center(
              child: BotaoSosPersistente(
                key: BotaoSosPersistente.chaveBotao,
                aoTocar: () => toques++,
              ),
            ),
          ),
        ),
      );

      final Finder btn = find.byKey(BotaoSosPersistente.chaveBotao);
      expect(btn, findsOneWidget);
      final Size size = t.getSize(btn);
      expect(size.width, greaterThanOrEqualTo(MemoraDimensoes.alvoDecisao));
      expect(size.height, greaterThanOrEqualTo(MemoraDimensoes.alvoMinimo));

      await t.tap(btn);
      expect(toques, 1);
    },
  );

  testWidgets(
    'faixa SOS na CascaInterna reserva espaço próprio sem sobreposição a 200%',
    (WidgetTester t) async {
      vestir(t, const Size(320, 568));
      await t.pumpWidget(
        EscopoAparencia(
          controlador: ControladorAparencia(PreferenciaEmMemoria()),
          child: MaterialApp(
            theme: TemasMemora.claro,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 568),
                textScaler: TextScaler.linear(2.0),
              ),
              child: CascaInterna(
                aoRegistrarAtividade: () {},
                aoAcionarSos: () {},
                raizes: <DestinoDaCasca, WidgetBuilder>{
                  DestinoDaCasca.ajustes: (_) => const SizedBox.shrink(),
                  DestinoDaCasca.inicio: (_) => TelaInicio(
                    nome: 'Ana',
                    aoConversar: () {},
                    aoVerTudo: () {},
                  ),
                  DestinoDaCasca.perfil: (_) => const SizedBox.shrink(),
                },
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();

      expect(t.takeException(), isNull);
      final Rect faixa = t.getRect(find.byKey(CascaInterna.chaveFaixaSos));
      final Rect botao = t.getRect(find.byKey(CascaInterna.chaveBotaoSos));
      final Rect saudacao = t.getRect(find.byKey(TelaInicio.chaveSaudacao));

      expect(
        faixa.bottom - botao.bottom,
        greaterThanOrEqualTo(MemoraDimensoes.separacaoAlvo),
      );
      expect(
        saudacao.top - faixa.bottom,
        greaterThanOrEqualTo(MemoraDimensoes.separacaoAlvo),
      );
      expect(botao.overlaps(saudacao), isFalse);
    },
  );

  test(
    'ContatoEmergencia e RepositorioEmergenciaSosApi priorizam e-mail quando cadastrado',
    () async {
      const ContatoEmergencia semEmail = ContatoEmergencia(
        id: 'c1',
        nome: 'Maria Silva',
        telefone: '11988887777',
        parentesco: 'Filha',
      );
      final ContatoEmergencia comEmail = ContatoEmergencia.fromJson(
        semEmail.copyWith(email: 'maria@email.com').toJson(),
      );

      expect(semEmail.temEmailValido, isFalse);
      expect(semEmail.emailValidoOuVazio, isTrue);
      expect(semEmail.destinoNotificacaoRemota, '11988887777');
      expect(comEmail.temEmailValido, isTrue);
      expect(comEmail.destinoNotificacaoRemota, 'maria@email.com');
      expect(
        semEmail.copyWith(email: 'invalido').emailValidoOuVazio,
        isFalse,
      );

      final List<Map<String, dynamic>> payloads = <Map<String, dynamic>>[];
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.memora.test/api/v1'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (RequestOptions opts, RequestInterceptorHandler h) {
            final Map<String, dynamic> corpo = Map<String, dynamic>.from(
              opts.data as Map<dynamic, dynamic>,
            );
            payloads.add(corpo);
            h.resolve(
              Response<dynamic>(
                requestOptions: opts,
                statusCode: 200,
                data: <String, dynamic>{
                  'eventoId': corpo['eventoId'],
                  'tipo': 'SOS_MANUAL',
                  'status': 'ENVIADO',
                  'mensagem': TextosSos.mensagemEnviado,
                  'ocorridoEm': '2026-11-16T20:00:00Z',
                },
              ),
            );
          },
        ),
      );

      final RepositorioEmergenciaSosApi api = RepositorioEmergenciaSosApi(dio: dio);
      await api.solicitarSos(
        eventoId: 'ev-1',
        tipo: TipoEventoEmergencia.sosManual,
        contato: comEmail,
      );
      await api.solicitarSos(
        eventoId: 'ev-2',
        tipo: TipoEventoEmergencia.sosManual,
        contato: semEmail,
      );

      expect(payloads[0]['contatoDestino'], 'maria@email.com');
      expect(payloads[1]['contatoDestino'], '11988887777');
    },
  );

  testWidgets(
    'diálogo SOS avisa quando contato não tem e-mail e DialogoContatoEmergencia valida o campo',
    (WidgetTester t) async {
      await entrarNoFluxo(t);
      await t.tap(find.byKey(CascaInterna.chaveBotaoSos));
      await t.pumpAndSettle();
      expect(find.text(TextosSos.avisoContatoSemEmail), findsOneWidget);

      await t.ensureVisible(find.byKey(DialogoSosEmergencia.chaveCancelar));
      await t.tap(find.byKey(DialogoSosEmergencia.chaveCancelar));
      await t.pumpAndSettle();

      ContatoEmergencia? salvo;
      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext ctx) => Center(
                child: ElevatedButton(
                  onPressed: () => DialogoContatoEmergencia.exibir(
                    context: ctx,
                    contatoAtual: contatoPadrao,
                    aoSalvar: (ContatoEmergencia c) => salvo = c,
                  ),
                  child: const Text('Abrir contato'),
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('Abrir contato'));
      await t.pumpAndSettle();

      await t.enterText(
        find.widgetWithText(CampoTexto, TextosCuidado.rotuloEmailContato),
        'email-invalido',
      );
      await t.ensureVisible(find.text(TextosCuidado.botaoSalvarContato));
      await t.tap(find.text(TextosCuidado.botaoSalvarContato));
      await t.pumpAndSettle();
      expect(find.text(TextosCuidado.erroEmailContato), findsOneWidget);
      expect(salvo, isNull);

      await t.enterText(
        find.widgetWithText(CampoTexto, TextosCuidado.rotuloEmailContato),
        'maria@email.com',
      );
      await t.ensureVisible(find.text(TextosCuidado.botaoSalvarContato));
      await t.tap(find.text(TextosCuidado.botaoSalvarContato));
      await t.pumpAndSettle();
      expect(salvo?.email, 'maria@email.com');
    },
  );
}
