import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/cuidado/data/provedores/provedor_telemetria_simulado.dart';
import 'package:memora/features/cuidado/data/repositorios/repositorio_contato_emergencia_local.dart';
import 'package:memora/features/cuidado/domain/entidades/contato_emergencia.dart';
import 'package:memora/features/cuidado/domain/entidades/enums_cuidado.dart';
import 'package:memora/features/cuidado/domain/entidades/evento_queda.dart';
import 'package:memora/features/cuidado/domain/entidades/telemetria_iot.dart';
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
      expect(telemetria.emMovimento, isTrue);

      await provedor.desconectar();
      expect(provedor.statusAtual, StatusConexaoIot.desconectado);

      provedor.descartar();
    });

    test('simularQueda emite evento no streamQueda', () async {
      final ProvedorDeTelemetriaSimulado provedor =
          ProvedorDeTelemetriaSimulado();

      final Future<EventoQueda> futuroQueda = provedor.streamQueda.first;
      provedor.simularQueda(bpmNoImpacto: 92);

      final EventoQueda quedaRecebida = await futuroQueda;
      expect(quedaRecebida.bpmNoImpacto, 92);
      expect(quedaRecebida.tempoRestanteSegundos, 45);

      provedor.descartar();
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
  });
}

