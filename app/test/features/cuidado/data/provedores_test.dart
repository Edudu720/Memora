import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/cuidado/data/provedores/provedor_telemetria_mqtt.dart';
import 'package:memora/features/cuidado/data/provedores/provedor_telemetria_simulado.dart';
import 'package:memora/features/cuidado/data/repositorios/repositorio_contato_emergencia_local.dart';
import 'package:memora/features/cuidado/domain/entidades/contato_emergencia.dart';
import 'package:memora/features/cuidado/domain/entidades/enums_cuidado.dart';
import 'package:memora/features/cuidado/domain/entidades/evento_queda.dart';
import 'package:memora/features/cuidado/domain/entidades/telemetria_iot.dart';
import 'package:memora/services/seguranca/limpeza_de_sessao.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ProvedorDeTelemetriaSimulado', () {
    test('conecta e emite status conectado e telemetria periódica', () async {
      final ProvedorDeTelemetriaSimulado provedor =
          ProvedorDeTelemetriaSimulado(
        intervaloEnvio: const Duration(milliseconds: 50),
      );

      final List<StatusConexaoIot> statuses = <StatusConexaoIot>[];
      provedor.streamStatusConexao.listen(statuses.add);

      await provedor.conectar();
      expect(provedor.statusAtual, StatusConexaoIot.conectado);

      final TelemetriaIot telemetria = await provedor.streamTelemetria.first;
      expect(telemetria.bpm, inInclusiveRange(40, 180));
      expect(telemetria.bpmValido, isTrue);
      expect(telemetria.emMovimento, isTrue);

      await provedor.desconectar();
      expect(provedor.statusAtual, StatusConexaoIot.desconectado);

      provedor.descartar();
    });

    test('simularQueda emite evento no streamQueda e aceita enviarComandoCessarAlarme', () async {
      final ProvedorDeTelemetriaSimulado provedor =
          ProvedorDeTelemetriaSimulado();

      final Future<EventoQueda> futuroQueda = provedor.streamQueda.first;
      provedor.simularQueda(bpmNoImpacto: 92);

      final EventoQueda quedaRecebida = await futuroQueda;
      expect(quedaRecebida.bpmNoImpacto, 92);
      expect(quedaRecebida.tempoRestanteSegundos, 45);

      await provedor.enviarComandoCessarAlarme();
      provedor.descartar();
    });

    test('processa contrato de alerta pós-impacto do ESP32 físico', () {
      const String payloadAlerta =
          '{"evento":"QUEDA_DETECTADA","bpm":76,"bpm_valido":true,"bpm_antes_da_queda":74,"aceleracao":2.95,"movimento_pos_impacto":2.8,"timestamp":95400}';
      final EventoQueda queda = EventoQueda.fromJson(
        jsonDecode(payloadAlerta) as Map<String, dynamic>,
      );

      expect(queda.bpmNoImpacto, 76);
      expect(queda.bpmValido, isTrue);
      expect(queda.bpmAntesDaQueda, 74);
      expect(queda.aceleracaoNoImpacto, 2.95);
      expect(queda.movimentoPosImpacto, 2.8);
    });
  });

  group('RepositorioContatoEmergenciaLocal', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('salva, obtém e remove contato de emergência corretamente', () async {
      final RepositorioContatoEmergenciaLocal repo =
          RepositorioContatoEmergenciaLocal();

      expect(await repo.obterContato(), isNull);

      const ContatoEmergencia contato = ContatoEmergencia(
        id: 'c1',
        nome: 'Filha Laura',
        telefone: '(19) 99999-8888',
        parentesco: 'Filha',
      );

      await repo.salvarContato(contato);

      final ContatoEmergencia? recuperado = await repo.obterContato();
      expect(recuperado, isNotNull);
      expect(recuperado?.nome, 'Filha Laura');
      expect(recuperado?.telefoneNumeros, '19999998888');

      await repo.removerContato();
      expect(await repo.obterContato(), isNull);
    });

    test('implementa DadoLocalDaPessoa e apaga contato de emergência na saída da sessão', () async {
      final RepositorioContatoEmergenciaLocal repo =
          RepositorioContatoEmergenciaLocal();
      expect(repo, isA<DadoLocalDaPessoa>());

      await repo.salvarContato(
        const ContatoEmergencia(
          id: 'c2',
          nome: 'Filho Pedro',
          telefone: '(19) 98888-7777',
          parentesco: 'Filho',
        ),
      );
      expect(await repo.obterContato(), isNotNull);

      final DadoLocalDaPessoa dadoLocal = repo;
      await dadoLocal.apagar();
      expect(await repo.obterContato(), isNull);
    });
  });

  group('ProvedorDeTelemetriaMqtt', () {
    test('ativa TLS automaticamente na porta 8883 ou quando usarTls=true e aceita credenciais', () {
      final ProvedorDeTelemetriaMqtt padrao = ProvedorDeTelemetriaMqtt();
      expect(padrao.porta, 1883);
      expect(padrao.tlsAtivo, isFalse);
      expect(padrao.usuario, isNull);
      padrao.descartar();

      final ProvedorDeTelemetriaMqtt portaTls = ProvedorDeTelemetriaMqtt(
        broker: 'cluster.hivemq.cloud',
        porta: 8883,
        usuario: 'memora_iot',
        senha: 'segredo_mqtt',
      );
      expect(portaTls.tlsAtivo, isTrue);
      expect(portaTls.usuario, 'memora_iot');
      expect(portaTls.senha, 'segredo_mqtt');
      portaTls.descartar();

      final ProvedorDeTelemetriaMqtt flagTls = ProvedorDeTelemetriaMqtt(
        usarTls: true,
      );
      expect(flagTls.tlsAtivo, isTrue);
      flagTls.descartar();
    });
  });
}
