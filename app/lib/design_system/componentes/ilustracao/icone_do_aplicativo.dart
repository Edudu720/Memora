import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  /// Mapa constante dos 7 ícones vetoriais compartilhados em `assets/icones_apps/`
  /// (Feature 016, Issue #106 Item 6).
  static const Map<String, String> _iconesSvgPorChave = <String, String>{
    'youtube': 'assets/icones_apps/youtube.svg',
    'tiktok': 'assets/icones_apps/tiktok.svg',
    'googlefotos': 'assets/icones_apps/google-fotos.svg',
    'meuinss': 'assets/icones_apps/meu-inss.svg',
    'poupatempo': 'assets/icones_apps/poupatempo.svg',
    'carteiradigital': 'assets/icones_apps/carteira-digital.svg',
    'carteiradetrabalho': 'assets/icones_apps/carteira-de-trabalho.svg',
  };

  static String? _buscarSvgPorChave(String normalizada) {
    final String? direto = _iconesSvgPorChave[normalizada];
    if (direto != null) return direto;
    if (normalizada.contains('trabalho')) {
      return _iconesSvgPorChave['carteiradetrabalho'];
    }
    if (normalizada.contains('carteira')) {
      return _iconesSvgPorChave['carteiradigital'];
    }
    if (normalizada.contains('youtube')) {
      return _iconesSvgPorChave['youtube'];
    }
    if (normalizada.contains('tiktok')) {
      return _iconesSvgPorChave['tiktok'];
    }
    if (normalizada.contains('foto') ||
        (normalizada.contains('google') && !normalizada.contains('gov'))) {
      return _iconesSvgPorChave['googlefotos'];
    }
    if (normalizada.contains('inss')) {
      return _iconesSvgPorChave['meuinss'];
    }
    if (normalizada.contains('poupatempo')) {
      return _iconesSvgPorChave['poupatempo'];
    }
    return null;
  }

  Widget _desenharIcone(
    BuildContext context,
    String normalizada,
    MemoraCores cores,
  ) {
    final String? caminhoSvg = _buscarSvgPorChave(normalizada);
    if (caminhoSvg != null) {
      return SvgPicture.asset(
        caminhoSvg,
        width: tamanho,
        height: tamanho,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
      );
    }

    // 1. WhatsApp (logo oficial fornecida)
    if (normalizada.contains('whatsapp')) {
      return Image.asset(
        'assets/ilustracoes/whatsapp_logo.png',
        width: tamanho,
        height: tamanho,
        fit: BoxFit.contain,
      );
    }

    // 3. Instagram (reservado para Item 13 — @Henrique-Sandrini)
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

    // 6. Telegram (logo oficial fornecida)
    if (normalizada.contains('telegram')) {
      return Image.asset(
        'assets/ilustracoes/telegram_logo.png',
        width: tamanho,
        height: tamanho,
        fit: BoxFit.contain,
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

    // 10. E-Título (Verde Eleitoral — reservado para Item 13)
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

    // 12. FGTS (Azul Caixa com Laranja — reservado para Item 13)
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
