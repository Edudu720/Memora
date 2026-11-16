import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';

/// Ícone visual reconhecível e autêntico para os aplicativos do catálogo.
///
/// ## Por que ícones próprios e autênticos (R7 da feature 004)
///
/// As pessoas idosas reconhecem aplicativos pela cor e formato visual autêntico
/// (o "quadradinho verde com telefone branco", o "quadradinho vermelho com
/// triângulo branco"). Sem os ícones conhecidos, o catálogo parecia uma
/// lista genérica de botões cinzas.
class IconeDoAplicativo extends StatelessWidget {
  /// Chave estável do serviço (ex: 'whatsapp', 'facebook', 'youtube').
  final String chave;

  /// Nome exibido do serviço, usado como fallback de identificação.
  final String? nome;

  /// Tamanho do ícone em pixels lógicos (largura e altura).
  final double tamanho;

  /// Cria o ícone visual do aplicativo.
  const IconeDoAplicativo({
    required this.chave,
    this.nome,
    this.tamanho = 48,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final String normalizada = (chave.isNotEmpty ? chave : (nome ?? ''))
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    return MediaQuery.withNoTextScaling(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tamanho * (12 / 48)),
        child: SizedBox(
          width: tamanho,
          height: tamanho,
          child: _desenharIcone(context, normalizada, cores),
        ),
      ),
    );
  }

  Widget _desenharIcone(
    BuildContext context,
    String normalizada,
    MemoraCores cores,
  ) {
    // 1. WhatsApp (logo oficial fornecida)
    if (normalizada.contains('whatsapp')) {
      return Image.asset(
        'assets/ilustracoes/whatsapp_logo.png',
        width: tamanho,
        height: tamanho,
        fit: BoxFit.contain,
      );
    }

    // 2. YouTube
    if (normalizada.contains('youtube')) {
      return Container(
        color: const Color(0xFFFF0000),
        alignment: Alignment.center,
        child: CustomPaint(
          size: Size(tamanho * 0.48, tamanho * 0.48),
          painter: _TrianguloBrancoPainter(),
        ),
      );
    }

    // 3. Instagram
    if (normalizada.contains('instagram')) {
      return Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, 0.8),
            radius: 1.25,
            colors: <Color>[
              Color(0xFFFFDC80),
              Color(0xFFF77737),
              Color(0xFFF56040),
              Color(0xFFFD1D1D),
              Color(0xFFE1306C),
              Color(0xFFC13584),
              Color(0xFF833AB4),
              Color(0xFF5851DB),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: CustomPaint(
          size: Size(tamanho * 0.65, tamanho * 0.65),
          painter: _CameraInstagramPainter(),
        ),
      );
    }

    // 4. Facebook (logo oficial fornecida)
    if (normalizada.contains('facebook')) {
      return Image.asset(
        'assets/ilustracoes/facebook_logo.png',
        width: tamanho,
        height: tamanho,
        fit: BoxFit.contain,
      );
    }

    // 5. TikTok
    if (normalizada.contains('tiktok')) {
      return Container(
        color: const Color(0xFF010101),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Transform.translate(
              offset: const Offset(-2.0, -1.5),
              child: Icon(
                Icons.music_note_rounded,
                color: const Color(0xFF00F2FE),
                size: tamanho * 0.68,
              ),
            ),
            Transform.translate(
              offset: const Offset(2.0, 1.5),
              child: Icon(
                Icons.music_note_rounded,
                color: const Color(0xFFFE2C55),
                size: tamanho * 0.68,
              ),
            ),
            Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: tamanho * 0.68,
            ),
          ],
        ),
      );
    }

    // 6. Telegram (logo oficial fornecida)
    if (normalizada.contains('telegram')) {
      return Image.asset(
        'assets/ilustracoes/telegram_logo.png',
        width: tamanho,
        height: tamanho,
        fit: BoxFit.contain,
      );
    }

    // 7. Google Fotos
    if (normalizada.contains('foto') || normalizada.contains('google')) {
      return Container(
        color: Colors.white,
        padding: EdgeInsets.all(tamanho * 0.12),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Positioned(
              top: 0,
              child: Container(
                width: tamanho * 0.32,
                height: tamanho * 0.32,
                decoration: const BoxDecoration(
                  color: Color(0xFFEA4335), // vermelho
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 0,
              child: Container(
                width: tamanho * 0.32,
                height: tamanho * 0.32,
                decoration: const BoxDecoration(
                  color: Color(0xFF4285F4), // azul
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                width: tamanho * 0.32,
                height: tamanho * 0.32,
                decoration: const BoxDecoration(
                  color: Color(0xFF34A853), // verde
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 0,
              child: Container(
                width: tamanho * 0.32,
                height: tamanho * 0.32,
                decoration: const BoxDecoration(
                  color: Color(0xFFFBBC05), // amarelo
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 8. Gov.br (logo oficial fornecida)
    if (normalizada.contains('gov')) {
      return Image.asset(
        'assets/ilustracoes/gov_br_logo.png',
        width: tamanho,
        height: tamanho,
        fit: BoxFit.contain,
      );
    }

    // 9. Meu INSS (Azul Previdência)
    if (normalizada.contains('inss')) {
      return Container(
        color: const Color(0xFF003882),
        alignment: Alignment.center,
        child: Icon(
          Icons.health_and_safety_rounded,
          color: const Color(0xFFFFD100),
          size: tamanho * 0.64,
        ),
      );
    }

    // 10. E-Título (Verde Eleitoral)
    if (normalizada.contains('titulo')) {
      return Container(
        color: const Color(0xFF0E5E35),
        alignment: Alignment.center,
        child: Icon(
          Icons.how_to_vote_rounded,
          color: const Color(0xFFFFDF00),
          size: tamanho * 0.62,
        ),
      );
    }

    // 11. Serasa (logo oficial fornecida)
    if (normalizada.contains('serasa')) {
      return Image.asset(
        'assets/ilustracoes/serasa_logo.png',
        width: tamanho,
        height: tamanho,
        fit: BoxFit.contain,
      );
    }

    // 12. FGTS (Azul Caixa com Laranja)
    if (normalizada.contains('fgts')) {
      return Container(
        color: const Color(0xFF005CA9),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: tamanho * 0.28,
              child: Container(color: const Color(0xFFF26522)),
            ),
            Icon(
              Icons.savings_rounded,
              color: Colors.white,
              size: tamanho * 0.60,
            ),
          ],
        ),
      );
    }

    // 13. Poupatempo (Vermelho SP)
    if (normalizada.contains('poupatempo')) {
      return Container(
        color: const Color(0xFFCC1414),
        alignment: Alignment.center,
        child: Icon(
          Icons.schedule_rounded,
          color: Colors.white,
          size: tamanho * 0.64,
        ),
      );
    }

    // 14. Carteira Digital de Trânsito (Verde CDT)
    if (normalizada.contains('carteira') && !normalizada.contains('trabalho')) {
      return Container(
        color: const Color(0xFF146342),
        alignment: Alignment.center,
        child: Icon(
          Icons.drive_eta_rounded,
          color: const Color(0xFFFFD100),
          size: tamanho * 0.62,
        ),
      );
    }

    // 15. Carteira de Trabalho (Azul CTPS)
    if (normalizada.contains('trabalho')) {
      return Container(
        color: const Color(0xFF0B2545),
        alignment: Alignment.center,
        child: Icon(
          Icons.badge_rounded,
          color: Colors.white,
          size: tamanho * 0.62,
        ),
      );
    }

    // 16. Correios (logo oficial fornecida)
    if (normalizada.contains('correios')) {
      return Image.asset(
        'assets/ilustracoes/correios_logo.png',
        width: tamanho,
        height: tamanho,
        fit: BoxFit.contain,
      );
    }

    // Fallback genérico
    return Container(
      color: cores.destaque,
      alignment: Alignment.center,
      child: Icon(
        Icons.apps_rounded,
        color: cores.primaria,
        size: tamanho * 0.6,
      ),
    );
  }
}

/// Desenha o triângulo branco clássico do YouTube.
class _TrianguloBrancoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Path path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.1)
      ..lineTo(size.width * 0.95, size.height * 0.5)
      ..lineTo(size.width * 0.15, size.height * 0.9)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Desenha a silhueta da câmera do Instagram (quadrado arredondado + círculo + ponto).
class _CameraInstagramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, size.width * 0.08);

    final Paint fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Moldura arredondada
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.width * 0.28),
    );
    canvas.drawRRect(rrect, strokePaint);

    // Lente circular central
    final Offset center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width * 0.22, strokePaint);

    // Ponto de flash
    final Offset flash = Offset(size.width * 0.78, size.height * 0.22);
    canvas.drawCircle(flash, size.width * 0.05, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
