import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/cuidado/domain/entidades/contato_emergencia.dart';
import 'package:memora/features/cuidado/domain/entidades/dispositivo_cuidado.dart';
import 'package:memora/features/cuidado/domain/entidades/enums_cuidado.dart';
import 'package:memora/features/cuidado/domain/entidades/evento_queda.dart';
import 'package:memora/features/cuidado/domain/entidades/telemetria_iot.dart';

void main() {
  group('TelemetriaIot', () {
    test('converte de json com campos corretos', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'bpm': 75,
        'movimento': 15.4,
        'aceleracao': 1.05,
        'em_movimento': true,
        'estado': 'MOVIMENTO',
        'timestamp': 1728512345000,
      };

      final TelemetriaIot telemetria = TelemetriaIot.fromJson(json);

      expect(telemetria.bpm, 75);
      expect(telemetria.nivelMovimento, 15.4);
      expect(telemetria.aceleracaoG, 1.05);
      expect(telemetria.emMovimento, isTrue);
      expect(telemetria.estadoSensor, 'MOVIMENTO');
      expect(telemetria.timestamp.millisecondsSinceEpoch, 1728512345000);
    });

    test('toJson serializa valores esperados', () {
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
      expect(json['movimento'], 10.0);
      expect(json['em_movimento'], isTrue);
    });
  });

  group('EventoQueda', () {
    test('cria evento novo com 45 segundos padrão e status aguardandoConfirmacao', () {
      final EventoQueda evento = EventoQueda.novo(bpm: 85, aceleracao: 2.9);

      expect(evento.bpmNoImpacto, 85);
      expect(evento.aceleracaoNoImpacto, 2.9);
      expect(evento.status, StatusConfirmacaoQueda.aguardandoConfirmacao);
      expect(evento.tempoRestanteSegundos, 45);
    });

    test('fromJson interpreta campos de alerta', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'id': 'queda-123',
        'bpm': 90,
        'aceleracao': 3.1,
        'tempo_restante': 45,
      };

      final EventoQueda evento = EventoQueda.fromJson(json);
      expect(evento.id, 'queda-123');
      expect(evento.bpmNoImpacto, 90);
      expect(evento.aceleracaoNoImpacto, 3.1);
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
