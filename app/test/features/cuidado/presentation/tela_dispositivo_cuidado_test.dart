import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_login.dart';
import 'package:memora/features/cuidado/data/provedores/provedor_telemetria_mqtt.dart';
import 'package:memora/features/cuidado/data/provedores/provedor_telemetria_simulado.dart';
import 'package:memora/features/cuidado/data/repositorios/repositorio_contato_emergencia_local.dart';
import 'package:memora/features/cuidado/domain/entidades/contato_emergencia.dart';
import 'package:memora/features/cuidado/domain/entidades/enums_cuidado.dart';
import 'package:memora/features/cuidado/domain/entidades/evento_queda.dart';
import 'package:memora/features/cuidado/domain/entidades/telemetria_iot.dart';
import 'package:memora/features/cuidado/domain/repositorios/repositorio_contato_emergencia.dart';
import 'package:memora/features/cuidado/presentation/controladores/controlador_dispositivo_cuidado.dart';
import 'package:memora/features/cuidado/presentation/telas/tela_dispositivo_cuidado.dart';
import 'package:memora/features/cuidado/presentation/telas/tela_verificacao_queda.dart';
import 'package:memora/l10n/textos_casca.dart';
import 'package:memora/l10n/textos_cuidado.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../suporte/aparelhos.dart';
import '../../autenticacao/fluxo_dentro_da_conta.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('TelaDispositivoCuidado', () {
    testWidgets('exibe título, medidores, orientação do sensor óptico e seção ESP32', (WidgetTester tester) async {
      final RepositorioContatoEmergenciaLocal repo = RepositorioContatoEmergenciaLocal();
      final ProvedorDeTelemetriaSimulado provedor = ProvedorDeTelemetriaSimulado();
      final ControladorDispositivoCuidado ctrl = ControladorDispositivoCuidado(
        repositorioContato: repo,
        provedorInicial: provedor,
      );

      const Combinacao combinacaoPadrao = (
        aparelho: referencia,
        escala: 1.0,
        tema: MemoraTemaId.claro,
      );

      vestir(tester, combinacaoPadrao.aparelho);
      await tester.pumpWidget(
        naCombinacao(
          combinacaoPadrao,
          TelaDispositivoCuidado(
            controlador: ctrl,
            aoVoltar: () {},
          ),
        ),
      );

      expect(find.text('Dispositivo de Cuidado'), findsOneWidget);
      expect(find.text('Frequência Cardíaca'), findsOneWidget);
      expect(find.text('Posicione o dedo no sensor para medir'), findsOneWidget);
      expect(find.text('Estado de Movimento'), findsOneWidget);
      expect(find.text('Contato de Emergência'), findsOneWidget);
      expect(find.text('Conexão ESP32 & Testes'), findsOneWidget);

      expect(find.byType(PainelHeroi), findsOneWidget);
      final SemanticsHandle handle = tester.ensureSemantics();
      final SemanticsNode noHeroi = tester.getSemantics(find.byType(PainelHeroi));
      expect(noHeroi.flagsCollection.isButton, isFalse);
      handle.dispose();

      ctrl.dispose();
    });

    testWidgets('diálogo de contato valida e salva contato de emergência', (WidgetTester tester) async {
      final RepositorioContatoEmergenciaLocal repo = RepositorioContatoEmergenciaLocal();
      final ProvedorDeTelemetriaSimulado provedor = ProvedorDeTelemetriaSimulado();
      final ControladorDispositivoCuidado ctrl = ControladorDispositivoCuidado(
        repositorioContato: repo,
        provedorInicial: provedor,
      );

      const Combinacao combinacaoPadrao = (
        aparelho: referencia,
        escala: 1.0,
        tema: MemoraTemaId.claro,
      );

      vestir(tester, combinacaoPadrao.aparelho);
      await tester.pumpWidget(
        naCombinacao(
          combinacaoPadrao,
          TelaDispositivoCuidado(
            controlador: ctrl,
            aoVoltar: () {},
          ),
        ),
      );

      await tester.ensureVisible(find.text('Contato de Emergência'));
      await tester.tap(find.text('Contato de Emergência'));
      await tester.pumpAndSettle();

      expect(find.text('Salvar contato'), findsOneWidget);
      await tester.ensureVisible(find.text('Cancelar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      ctrl.dispose();
    });

    testWidgets('zero estouro de layout na matriz completa de aparelhos', (WidgetTester tester) async {
      for (final Combinacao c in matriz()) {
        final RepositorioContatoEmergenciaLocal repo = RepositorioContatoEmergenciaLocal();
        final ProvedorDeTelemetriaSimulado provedor = ProvedorDeTelemetriaSimulado();
        final ControladorDispositivoCuidado ctrl = ControladorDispositivoCuidado(
          repositorioContato: repo,
          provedorInicial: provedor,
        );

        vestir(tester, c.aparelho);
        await tester.pumpWidget(
          naCombinacao(
            c,
            TelaDispositivoCuidado(
              controlador: ctrl,
              aoVoltar: () {},
            ),
          ),
        );

        expect(
          tester.takeException(),
          isNull,
          reason: 'Estouro de layout na TelaDispositivoCuidado no aparelho ${nomeDo(c.aparelho)} com escala ${c.escala}',
        );

        ctrl.dispose();
      }
    });

    testWidgets(
      'simular queda abre TelaVerificacaoQueda com ESP32 MQTT desconectado e cancela sem socorro',
      (WidgetTester tester) async {
        final RepositorioContatoEmergenciaLocal repo =
            RepositorioContatoEmergenciaLocal();
        final ProvedorDeTelemetriaMqtt provedor = ProvedorDeTelemetriaMqtt();
        final ControladorDispositivoCuidado ctrl =
            ControladorDispositivoCuidado(
          repositorioContato: repo,
          provedorInicial: provedor,
        );
        expect(ctrl.dispositivo.modoOperacao, ModoOperacaoIot.mqtt);

        const Combinacao combinacaoPadrao = (
          aparelho: referencia,
          escala: 1.0,
          tema: MemoraTemaId.claro,
        );

        vestir(tester, combinacaoPadrao.aparelho);
        await tester.pumpWidget(
          naCombinacao(
            combinacaoPadrao,
            TelaDispositivoCuidado(controlador: ctrl, aoVoltar: () {}),
          ),
        );

        await tester.ensureVisible(
          find.text(TextosCuidado.tituloConexaoEsp32Testes),
        );
        await tester.tap(find.text(TextosCuidado.tituloConexaoEsp32Testes));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text(TextosCuidado.botaoSimularQueda));
        await tester.tap(find.text(TextosCuidado.botaoSimularQueda));
        await tester.pumpAndSettle();

        expect(find.byType(TelaVerificacaoQueda), findsOneWidget);
        expect(find.text(TextosCuidado.tituloVerificacaoQueda), findsOneWidget);

        await tester.ensureVisible(find.text(TextosCuidado.botaoEstouBem));
        await tester.tap(find.text(TextosCuidado.botaoEstouBem));
        await tester.pumpAndSettle();

        expect(find.byType(TelaVerificacaoQueda), findsNothing);
        expect(find.text(TextosCuidado.tituloDispositivo), findsOneWidget);

        ctrl.dispose();
      },
    );

    testWidgets(
      'simular queda com MQTT conectado não empilha modais em toque duplo rápido',
      (WidgetTester tester) async {
        final RepositorioContatoEmergenciaLocal repo =
            RepositorioContatoEmergenciaLocal();
        final _ProvedorMqttControlado provedor = _ProvedorMqttControlado();
        final ControladorDispositivoCuidado ctrl =
            ControladorDispositivoCuidado(
          repositorioContato: repo,
          provedorInicial: provedor,
        );
        await ctrl.conectar();
        provedor.emitirTelemetria(
          TelemetriaIot(
            timestamp: DateTime(2026, 11, 19),
            bpm: 84,
            aceleracaoG: 1.0,
            nivelMovimento: 5,
            emMovimento: true,
            estadoSensor: 'MOVIMENTO',
          ),
        );

        const Combinacao combinacaoPadrao = (
          aparelho: referencia,
          escala: 1.0,
          tema: MemoraTemaId.claro,
        );

        vestir(tester, combinacaoPadrao.aparelho);
        await tester.pumpWidget(
          naCombinacao(
            combinacaoPadrao,
            TelaDispositivoCuidado(controlador: ctrl, aoVoltar: () {}),
          ),
        );

        await tester.ensureVisible(
          find.text(TextosCuidado.tituloConexaoEsp32Testes),
        );
        await tester.tap(find.text(TextosCuidado.tituloConexaoEsp32Testes));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text(TextosCuidado.botaoSimularQueda));
        await tester.tap(find.text(TextosCuidado.botaoSimularQueda));
        await tester.pump();
        // Segundo acionamento rápido enquanto a verificação já está aberta.
        ctrl.simularQuedaTeste();
        await tester.pumpAndSettle();

        expect(find.byType(TelaVerificacaoQueda), findsOneWidget);

        await tester.ensureVisible(find.text(TextosCuidado.botaoEstouBem));
        await tester.tap(find.text(TextosCuidado.botaoEstouBem));
        await tester.pumpAndSettle();

        expect(provedor.comandosCessar, 1);
        expect(find.byType(TelaVerificacaoQueda), findsNothing);

        ctrl.dispose();
      },
    );

    testWidgets(
      'simular queda segue funcionando no modo simulado e retorna ao cancelar',
      (WidgetTester tester) async {
        final RepositorioContatoEmergenciaLocal repo =
            RepositorioContatoEmergenciaLocal();
        final ProvedorDeTelemetriaSimulado provedor =
            ProvedorDeTelemetriaSimulado();
        final ControladorDispositivoCuidado ctrl =
            ControladorDispositivoCuidado(
          repositorioContato: repo,
          provedorInicial: provedor,
        );

        const Combinacao combinacaoPadrao = (
          aparelho: referencia,
          escala: 1.0,
          tema: MemoraTemaId.claro,
        );

        vestir(tester, combinacaoPadrao.aparelho);
        await tester.pumpWidget(
          naCombinacao(
            combinacaoPadrao,
            TelaDispositivoCuidado(controlador: ctrl, aoVoltar: () {}),
          ),
        );

        await tester.ensureVisible(
          find.text(TextosCuidado.tituloConexaoEsp32Testes),
        );
        await tester.tap(find.text(TextosCuidado.tituloConexaoEsp32Testes));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text(TextosCuidado.botaoSimularQueda));
        await tester.tap(find.text(TextosCuidado.botaoSimularQueda));
        await tester.pumpAndSettle();

        expect(find.byType(TelaVerificacaoQueda), findsOneWidget);

        await tester.ensureVisible(find.text(TextosCuidado.botaoEstouBem));
        await tester.tap(find.text(TextosCuidado.botaoEstouBem));
        await tester.pumpAndSettle();

        expect(find.byType(TelaVerificacaoQueda), findsNothing);
        ctrl.dispose();
      },
    );

    testWidgets(
      'atualiza o ouvinte de queda quando recebe novo controlador via didUpdateWidget',
      (WidgetTester tester) async {
        final RepositorioContatoEmergenciaLocal repo =
            RepositorioContatoEmergenciaLocal();
        final ControladorDispositivoCuidado ctrl1 = ControladorDispositivoCuidado(
          repositorioContato: repo,
          provedorInicial: _ProvedorMqttControlado(),
        );
        final ControladorDispositivoCuidado ctrl2 = ControladorDispositivoCuidado(
          repositorioContato: repo,
          provedorInicial: _ProvedorMqttControlado(),
        );

        const Combinacao combinacaoPadrao = (
          aparelho: referencia,
          escala: 1.0,
          tema: MemoraTemaId.claro,
        );

        vestir(tester, combinacaoPadrao.aparelho);
        await tester.pumpWidget(
          naCombinacao(
            combinacaoPadrao,
            TelaDispositivoCuidado(controlador: ctrl1, aoVoltar: () {}),
          ),
        );
        await tester.pumpWidget(
          naCombinacao(
            combinacaoPadrao,
            TelaDispositivoCuidado(controlador: ctrl2, aoVoltar: () {}),
          ),
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.text(TextosCuidado.tituloConexaoEsp32Testes),
        );
        await tester.tap(find.text(TextosCuidado.tituloConexaoEsp32Testes));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text(TextosCuidado.botaoSimularQueda));
        await tester.tap(find.text(TextosCuidado.botaoSimularQueda));
        await tester.pumpAndSettle();

        expect(find.byType(TelaVerificacaoQueda), findsOneWidget);

        await tester.ensureVisible(find.text(TextosCuidado.botaoEstouBem));
        await tester.tap(find.text(TextosCuidado.botaoEstouBem));
        await tester.pumpAndSettle();

        expect(find.byType(TelaVerificacaoQueda), findsNothing);
        ctrl1.dispose();
        ctrl2.dispose();
      },
    );

    test(
      'dispose com Futures pendentes não notifica nem reconecta após descarte',
      () async {
        final _RepositorioContatoComAtraso repo =
            _RepositorioContatoComAtraso();
        final _ProvedorMqttComAtraso provedorInicial =
            _ProvedorMqttComAtraso();
        final ControladorDispositivoCuidado ctrl =
            ControladorDispositivoCuidado(
          repositorioContato: repo,
          provedorInicial: provedorInicial,
        );
        int notificacoes = 0;
        ctrl.addListener(() => notificacoes++);

        final Future<void> salvamento = ctrl.salvarContato(
          const ContatoEmergencia(
            id: 'c1',
            nome: 'Filha',
            telefone: '19999999999',
            parentesco: 'Filha',
          ),
        );
        final Future<void> alternancia =
            ctrl.alternarModo(ModoOperacaoIot.simulado);

        ctrl.dispose();

        repo.completarObter(null);
        repo.completarSalvar();
        provedorInicial.completarDesconectar();
        await Future.wait<void>(<Future<void>>[salvamento, alternancia]);

        expect(notificacoes, 0);
        expect(ctrl.provedor, same(provedorInicial));
        expect(provedorInicial.descartes, 1);
      },
    );

    testWidgets(
      'descarga do Dispositivo de Cuidado ocorre ao expirar sessão dentro da conta (sem timer vazado)',
      (WidgetTester tester) async {
        final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
        const Duration prazo = Duration(minutes: 30);

        await fluxo.montar(tester);
        await FluxoDentroDaConta.tocar(
          tester,
          find.text(TextosCasca.atalhoCuidado),
        );
        expect(find.byType(TelaDispositivoCuidado), findsOneWidget);

        // Ativa o simulador para iniciar o Timer.periodic interno.
        await FluxoDentroDaConta.tocar(
          tester,
          find.text(TextosCuidado.botaoUsarSimulador),
        );
        expect(find.text(TextosCuidado.badgeMonitoramentoAtivo), findsOneWidget);

        // Expirar a sessão força o desmonte do Navigator interno sem completar rota.popped.
        await tester.pump(prazo);
        await FluxoDentroDaConta.avancar(tester, 6);

        expect(find.byType(TelaDispositivoCuidado), findsNothing);
        expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
      },
    );
  });
}

class _RepositorioContatoComAtraso implements RepositorioContatoEmergencia {
  final Completer<ContatoEmergencia?> _obter = Completer<ContatoEmergencia?>();
  final Completer<void> _salvar = Completer<void>();

  void completarObter(ContatoEmergencia? contato) {
    if (!_obter.isCompleted) _obter.complete(contato);
  }

  void completarSalvar() {
    if (!_salvar.isCompleted) _salvar.complete();
  }

  @override
  Future<ContatoEmergencia?> obterContato() => _obter.future;

  @override
  Future<void> removerContato() async {}

  @override
  Future<void> salvarContato(ContatoEmergencia contato) => _salvar.future;
}

class _ProvedorMqttComAtraso extends _ProvedorMqttControlado {
  final Completer<void> _desconectar = Completer<void>();
  int descartes = 0;

  void completarDesconectar() {
    if (!_desconectar.isCompleted) _desconectar.complete();
  }

  @override
  Future<void> desconectar() => _desconectar.future;

  @override
  void descartar() {
    descartes++;
    super.descartar();
  }
}

class _ProvedorMqttControlado extends ProvedorDeTelemetriaMqtt {
  final StreamController<TelemetriaIot> _telemetria =
      StreamController<TelemetriaIot>.broadcast();
  final StreamController<EventoQueda> _queda =
      StreamController<EventoQueda>.broadcast();
  final StreamController<StatusConexaoIot> _status =
      StreamController<StatusConexaoIot>.broadcast();

  int comandosCessar = 0;

  @override
  Stream<TelemetriaIot> get streamTelemetria => _telemetria.stream;

  @override
  Stream<EventoQueda> get streamQueda => _queda.stream;

  @override
  Stream<StatusConexaoIot> get streamStatusConexao => _status.stream;

  @override
  Future<void> conectar() async {
    if (!_status.isClosed) _status.add(StatusConexaoIot.conectado);
  }

  @override
  Future<void> desconectar() async {
    if (!_status.isClosed) _status.add(StatusConexaoIot.desconectado);
  }

  @override
  Future<void> enviarComandoCessarAlarme() async {
    comandosCessar++;
  }

  void emitirTelemetria(TelemetriaIot item) {
    if (!_telemetria.isClosed) _telemetria.add(item);
  }

  @override
  void descartar() {
    if (!_telemetria.isClosed) _telemetria.close();
    if (!_queda.isClosed) _queda.close();
    if (!_status.isClosed) _status.close();
  }
}
