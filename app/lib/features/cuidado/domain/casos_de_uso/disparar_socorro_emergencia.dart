import 'package:android_intent_plus/android_intent.dart';
import '../entidades/contato_emergencia.dart';

/// Caso de uso que realiza o acionamento de emergência via telefone nativo e SMS/WhatsApp.
class DispararSocorroEmergencia {
  /// Cria uma instância de [DispararSocorroEmergencia].
  const DispararSocorroEmergencia();

  /// Executa a chamada do discador com o número preenchido e prepara o envio de SMS com o texto padronizado.
  Future<void> executar({
    required ContatoEmergencia contato,
    required String nomeIdoso,
    required DateTime horarioOcorrencia,
  }) async {
    final String numeroLimpo = contato.telefoneNumeros;
    if (numeroLimpo.isEmpty) return;

    // 1. Disparar discador nativo com o número preenchido
    try {
      final AndroidIntent intentLigacao = AndroidIntent(
        action: 'android.intent.action.DIAL',
        data: 'tel:$numeroLimpo',
      );
      await intentLigacao.launch();
    } catch (_) {
      // Ignora erro se plataforma não suportar intent nativa
    }

    // 2. Preparar e enviar SMS nativo com mensagem explicativa e aviso antigolpe
    try {
      final String mensagem = _formatarMensagemSocorro(
        nomeIdoso: nomeIdoso,
        horario: horarioOcorrencia,
      );

      final AndroidIntent intentSms = AndroidIntent(
        action: 'android.intent.action.SENDTO',
        data: 'smsto:$numeroLimpo',
        arguments: <String, dynamic>{
          'sms_body': mensagem,
        },
      );
      await intentSms.launch();
    } catch (_) {
      // Ignora erro se plataforma não suportar intent nativa
    }
  }

  /// Gera a mensagem padronizada em conformidade com o Princípio II (Antigolpe).
  static String _formatarMensagemSocorro({
    required String nomeIdoso,
    required DateTime horario,
  }) {
    final String horaFormatada =
        '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}';
    final String dataFormatada =
        '${horario.day.toString().padLeft(2, '0')}/${horario.month.toString().padLeft(2, '0')}';

    return 'ALERTA MEMORA: O sensor de cuidado de $nomeIdoso detectou uma possível queda em $dataFormatada às $horaFormatada. '
        'A verificação de bem-estar no celular não foi respondida após 45 segundos. '
        'Por favor, ligue para verificar. '
        '(AVISO DE SEGURANÇA: O Memora NUNCA solicita dinheiro, transferências ou senhas).';
  }
}
