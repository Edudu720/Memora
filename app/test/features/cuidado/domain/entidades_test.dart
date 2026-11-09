import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/cuidado/domain/entidades/contato_emergencia.dart';
import 'package:memora/features/cuidado/domain/entidades/dispositivo_cuidado.dart';
import 'package:memora/features/cuidado/domain/entidades/enums_cuidado.dart';
import 'package:memora/features/cuidado/domain/entidades/evento_queda.dart';
import 'package:memora/features/cuidado/domain/entidades/telemetria_iot.dart';

void main() {
  group('TelemetriaIot', () {
    test('converte de json com campos corretos do ESP32 físico', () {
      const String payloadEsp32 =
          '{"bpm":75,"bpm_valido":true,"movimento":15.4,"aceleracao":1.05,"em_movimento":true,"estado":"EM_MOVIMENTO","timestamp":1728512345000}';
      final Map<String, dynamic> json =
          jsonDecode(payloadEsp32) as Map<String, dynamic>;

      final TelemetriaIot telemetria = TelemetriaIot.fromJson(json);

      expect(telemetria.bpm, 75);
      expect(telemetria.bpmValido, isTrue);
      expect(telemetria.nivelMovimento, 15.4);
      expect(telemetria.aceleracaoG, 1.05);
      expect(telemetria.emMovimento, isTrue);
      expect(telemetria.estadoSensor, 'EM_MOVIMENTO');
      expect(telemetria.timestamp.millisecondsSinceEpoch, 1728512345000);
    });

    test('normaliza timestamp de millis() do ESP32 e bpm_valido falso', () {
      const String payloadSemDedo =
          '{"bpm":0,"bpm_valido":false,"movimento":0.8,"aceleracao":1.00,"em_movimento":false,"estado":"INERTE","timestamp":45200}';
      final Map<String, dynamic> json =
          jsonDecode(payloadSemDedo) as Map<String, dynamic>;

      final TelemetriaIot telemetria = TelemetriaIot.fromJson(json);

      expect(telemetria.bpm, 0);
      expect(telemetria.bpmValido, isFalse);
      expect(telemetria.emMovimento, isFalse);
      expect(telemetria.estadoSensor, 'INERTE');
      expect(
        telemetria.timestamp.millisecondsSinceEpoch,
        greaterThan(1000000000000),
      );
    });

    test('toJson serializa valores esperados incluindo bpm_valido', () {
      final DateTime data = DateTime.fromMillisecondsSinceEpoch(1000000);
      final TelemetriaIot telemetria = TelemetriaIot(
        timestamp: data,
        bpm: 80,
        aceleracaoG: 1.0,
        nivelMovimento: 10.0,
        emMovimento: true,
        estadoSensor: 'INERTE',
      );

      final Map<String, dynamic> json = telemetria.toJson();
      expect(json['bpm'], 80);
      expect(json['bpm_valido'], isTrue);
      expect(json['movimento'], 10.0);
      expect(json['em_movimento'], isTrue);
    });
  });

  group('EventoQueda', () {
    test('cria evento novo com 45 segundos padrão e status aguardandoConfirmacao', () {
      final EventoQueda evento = EventoQueda.novo(bpm: 85, aceleracao: 2.9);

      expect(evento.bpmNoImpacto, 85);
      expect(evento.bpmValido, isTrue);
      expect(evento.bpmAntesDaQueda, 85);
      expect(evento.aceleracaoNoImpacto, 2.9);
      expect(evento.status, StatusConfirmacaoQueda.aguardandoConfirmacao);
      expect(evento.tempoRestanteSegundos, 45);
    });

    test('fromJson interpreta payload completo do ESP32 físico com fallback de bpm_antes_da_queda', () {
      const String payloadAlertaEsp32 =
          '{"evento":"QUEDA_DETECTADA","bpm":0,"bpm_valido":false,"bpm_antes_da_queda":82,"aceleracao":3.10,"movimento_pos_impacto":3.4,"timestamp":128500}';
      final Map<String, dynamic> json =
          jsonDecode(payloadAlertaEsp32) as Map<String, dynamic>;

      final EventoQueda evento = EventoQueda.fromJson(json);
      expect(evento.bpmNoImpacto, 82);
      expect(evento.bpmValido, isFalse);
      expect(evento.bpmAntesDaQueda, 82);
      expect(evento.aceleracaoNoImpacto, 3.10);
      expect(evento.movimentoPosImpacto, 3.4);
      expect(evento.tempoRestanteSegundos, 45);
    });
  });

  group('ContatoEmergencia', () {
    test('valida telefone brasileiro de 11 dígitos com DDD', () {
      const ContatoEmergencia contato = ContatoEmergencia(
        id: '1',
        nome: 'Mariana',
        telefone: '(19) 98765-4321',
        parentesco: 'Filha',
      );

      expect(contato.telefoneNumeros, '19987654321');
      expect(contato.ehValido, isTrue);
    });

    test('valida telefone brasileiro de 10 dígitos (fixo com DDD)', () {
      const ContatoEmergencia contato = ContatoEmergencia(
        id: '2',
        nome: 'Carlos',
        telefone: '(19) 3456-7890',
        parentesco: 'Filho',
      );

      expect(contato.telefoneNumeros, '1934567890');
      expect(contato.ehValido, isTrue);
    });

    test('normaliza telefone com DDI +55', () {
      const ContatoEmergencia contato = ContatoEmergencia(
        id: '5',
        nome: 'João',
        telefone: '+55 (19) 98765-4321',
        parentesco: 'Neto',
      );

      expect(contato.telefoneNumeros, '19987654321');
      expect(contato.ehValido, isTrue);
    });

    test('reprova telefone incompleto ou nome vazio', () {
      const ContatoEmergencia semNome = ContatoEmergencia(
        id: '3',
        nome: '   ',
        telefone: '(19) 98765-4321',
        parentesco: 'Filha',
      );
      expect(semNome.ehValido, isFalse);

      const ContatoEmergencia telefoneInvalido = ContatoEmergencia(
        id: '4',
        nome: 'Carlos',
        telefone: '12345',
        parentesco: 'Filho',
      );
      expect(telefoneInvalido.ehValido, isFalse);
    });
  });

  group('DispositivoCuidado', () {
    test('possui defaults corretos e status desconectado inicialmente', () {
      const DispositivoCuidado dispositivo = DispositivoCuidado(
        id: 'demo-1',
        nome: 'Minha Pulseira',
      );

      expect(dispositivo.estaConectado, isFalse);
      expect(dispositivo.statusConexao, StatusConexaoIot.desconectado);
      expect(dispositivo.modoOperacao, ModoOperacaoIot.simulado);
      expect(dispositivo.brokerHost, 'broker.hivemq.com');
    });
  });
}
