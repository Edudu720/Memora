import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/cuidado/data/provedores/provedor_telemetria_simulado.dart';
import 'package:memora/features/cuidado/data/repositorios/repositorio_contato_emergencia_local.dart';
import 'package:memora/features/cuidado/presentation/controladores/controlador_dispositivo_cuidado.dart';
import 'package:memora/features/cuidado/presentation/telas/tela_dispositivo_cuidado.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../suporte/aparelhos.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('TelaDispositivoCuidado', () {
    testWidgets('exibe título, medidores e botões de conexão', (WidgetTester tester) async {
      final RepositorioContatoEmergenciaLocal repo = RepositorioContatoEmergenciaLocal();
      final ProvedorDeTelemetriaSimulado provedor = ProvedorDeTelemetriaSimulado();
      final ControladorDispositivoCuidado ctrl = ControladorDispositivoCuidado(
        repositorioContato: repo,
        provedorInicial: provedor,
      );

      final Combinacao combinacaoPadrao = (
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
      expect(find.text('Estado de Movimento'), findsOneWidget);
      expect(find.text('Contato de Emergência'), findsOneWidget);

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
  });
}

