import 'package:android_intent_plus/android_intent.dart';
import '../entidades/contato_emergencia.dart';

/// Caso de uso que realiza o acionamento de emergência via WhatsApp com mensagem
/// pré-pronta (e fallback resiliente para wa.me, SMS e discador nativo).
class DispararSocorroEmergencia {
  /// Cria uma instância de [DispararSocorroEmergencia].
  const DispararSocorroEmergencia();

  /// Executa a abertura do WhatsApp com a conversa do contato e a mensagem de
  /// socorro pré-pronta, recorrendo a fallbacks caso o WhatsApp não esteja disponível.
  Future<void> executar({
    required ContatoEmergencia contato,
    required String nomeIdoso,
    required DateTime horarioOcorrencia,
  }) async {
    final String numeroLimpo = contato.telefoneNumeros;
    if (numeroLimpo.isEmpty) return;

    final String mensagem = formatarMensagemSocorro(
      nomeIdoso: nomeIdoso,
      horario: horarioOcorrencia,
    );

    // 1. Prioridade máxima: abrir diretamente a conversa no WhatsApp com a mensagem pré-pronta
    final String uriWhatsapp = formatarUriWhatsapp(
      contato: contato,
      nomeIdoso: nomeIdoso,
      horario: horarioOcorrencia,
    );
    try {
      final AndroidIntent intentWhatsapp = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: uriWhatsapp,
        package: 'com.whatsapp',
      );
      await intentWhatsapp.launch();
      return;
    } catch (_) {
      // Prossegue para o fallback universal wa.me caso o pacote com.whatsapp falhe
    }

    // 2. Fallback universal: link https://wa.me/<telefone_ddi_55>?text=<mensagem>
    final String uriWaMe =
        'https://wa.me/${contato.telefoneWhatsapp}?text=${Uri.encodeComponent(mensagem)}';
    try {
      final AndroidIntent intentWaMe = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: uriWaMe,
      );
      await intentWaMe.launch();
      return;
    } catch (_) {
      // Prossegue para o fallback de SMS e discador nativo
    }

    // 3. Fallback nativo: SMS com texto preenchido + Discador com número preenchido
    try {
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

    try {
      final AndroidIntent intentLigacao = AndroidIntent(
        action: 'android.intent.action.DIAL',
        data: 'tel:$numeroLimpo',
      );
      await intentLigacao.launch();
    } catch (_) {
      // Ignora erro se plataforma não suportar intent nativa
    }
  }

  /// Gera a URI `whatsapp://send?phone=55...&text=...` com a mensagem de socorro codificada.
  static String formatarUriWhatsapp({
    required ContatoEmergencia contato,
    required String nomeIdoso,
    required DateTime horario,
  }) {
    final String mensagem = formatarMensagemSocorro(
      nomeIdoso: nomeIdoso,
      horario: horario,
    );
    return 'whatsapp://send?phone=${contato.telefoneWhatsapp}&text=${Uri.encodeComponent(mensagem)}';
  }

  /// Gera a mensagem padronizada em conformidade com o Princípio II (Antigolpe).
  static String formatarMensagemSocorro({
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
