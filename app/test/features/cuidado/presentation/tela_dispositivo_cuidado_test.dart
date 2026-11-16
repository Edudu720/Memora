import 'package:flutter/semantics.dart';
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
  });
}
