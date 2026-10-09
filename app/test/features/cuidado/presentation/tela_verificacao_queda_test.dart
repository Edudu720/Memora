import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/cuidado/data/provedores/provedor_telemetria_simulado.dart';
import 'package:memora/features/cuidado/domain/casos_de_uso/disparar_socorro_emergencia.dart';
import 'package:memora/features/cuidado/domain/entidades/contato_emergencia.dart';
import 'package:memora/features/cuidado/domain/entidades/enums_cuidado.dart';
import 'package:memora/features/cuidado/domain/entidades/evento_queda.dart';
import 'package:memora/features/cuidado/presentation/controladores/controlador_verificacao_queda.dart';
import 'package:memora/features/cuidado/presentation/telas/tela_verificacao_queda.dart';

import '../../../suporte/aparelhos.dart';

void main() {
  const ContatoEmergencia contatoTeste = ContatoEmergencia(
    id: 'c1',
    nome: 'Filha Mariana',
    telefone: '19987654321',
    parentesco: 'Filha',
  );

  group('TelaVerificacaoQueda', () {
    testWidgets('exibe título, botões e aviso com clareza', (WidgetTester tester) async {
      final ProvedorDeTelemetriaSimulado provedor = ProvedorDeTelemetriaSimulado();
      final ControladorVerificacaoQueda ctrl = ControladorVerificacaoQueda(
        evento: EventoQueda.novo(bpm: 88, aceleracao: 2.7),
        provedor: provedor,
        casoDeUsoSocorro: const DispararSocorroEmergencia(),
        nomePessoaIdosa: 'Dona Maria',
        contatoEmergencia: contatoTeste,
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
          TelaVerificacaoQueda(controlador: ctrl),
        ),
      );

      expect(find.text('Você está bem?'), findsOneWidget);
      expect(find.text('Estou bem'), findsOneWidget);
      expect(find.text('Preciso de ajuda'), findsOneWidget);
      expect(find.textContaining('segundos'), findsOneWidget);

      ctrl.dispose();
      provedor.descartar();
    });

    testWidgets('toque em Estou bem cessa alarme e encerra tela', (WidgetTester tester) async {
      final ProvedorDeTelemetriaSimulado provedor = ProvedorDeTelemetriaSimulado();
      bool encerrou = false;

      final ControladorVerificacaoQueda ctrl = ControladorVerificacaoQueda(
        evento: EventoQueda.novo(bpm: 88, aceleracao: 2.7),
        provedor: provedor,
        casoDeUsoSocorro: const DispararSocorroEmergencia(),
        nomePessoaIdosa: 'Dona Maria',
        contatoEmergencia: contatoTeste,
        aoEncerrar: () => encerrou = true,
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
          TelaVerificacaoQueda(controlador: ctrl),
        ),
      );

      await tester.tap(find.text('Estou bem'));
      await tester.pump();

      expect(ctrl.status, StatusConfirmacaoQueda.canceladoPeloUsuario);
      expect(encerrou, isTrue);

      ctrl.dispose();
      provedor.descartar();
    });

    testWidgets('zero estouro de layout na matriz de aparelhos (320x568 até 390x844)', (WidgetTester tester) async {
      for (final Combinacao c in matrizCompleta()) {
        final ProvedorDeTelemetriaSimulado provedor = ProvedorDeTelemetriaSimulado();
        final ControladorVerificacaoQueda ctrl = ControladorVerificacaoQueda(
          evento: EventoQueda.novo(bpm: 88, aceleracao: 2.7),
          provedor: provedor,
          casoDeUsoSocorro: const DispararSocorroEmergencia(),
          nomePessoaIdosa: 'Dona Maria',
          contatoEmergencia: contatoTeste,
        );

        vestir(tester, c.aparelho);
        await tester.pumpWidget(
          naCombinacao(
            c,
            TelaVerificacaoQueda(controlador: ctrl),
          ),
        );

        expect(
          tester.takeException(),
          isNull,
          reason: 'Estouro de layout no aparelho ${nomeDo(c.aparelho)} com escala ${c.escala}',
        );

        ctrl.dispose();
        provedor.descartar();
      }
    });
  });
}

