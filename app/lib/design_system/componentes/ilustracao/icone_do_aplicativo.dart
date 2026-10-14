import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';

/// Ícone visual reconhecível para um aplicativo ou serviço do catálogo.
///
/// ## Por que ícones próprios (R7 da feature 004)
///
/// As pessoas idosas reconhecem aplicativos pela cor e formato do ícone
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
    if (normalizada.contains('whatsapp')) {
      return Container(
        color: const Color(0xFF25D366),
        alignment: Alignment.center,
        child: Icon(
          Icons.chat_bubble_rounded,
          color: Colors.white,
          size: tamanho * 0.65,
        ),
      );
    }

    if (normalizada.contains('facebook')) {
      return Container(
        color: const Color(0xFF1877F2),
        alignment: Alignment.bottomRight,
        child: Transform.translate(
          offset: Offset(tamanho * 0.05, tamanho * 0.05),
          child: Text(
            'f',
            style: TextStyle(
              color: Colors.white,
              fontSize: tamanho * 0.88,
              fontWeight: FontWeight.bold,
              fontFamily: 'sans-serif',
              height: 1.0,
            ),
          ),
        ),
      );
    }

    if (normalizada.contains('instagram')) {
      return Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, 0.8),
            radius: 1.2,
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
        child: Icon(
          Icons.camera_alt_outlined,
          color: Colors.white,
          size: tamanho * 0.62,
        ),
      );
    }

    if (normalizada.contains('youtube')) {
      return Container(
        color: const Color(0xFFFF0000),
        alignment: Alignment.center,
        child: Container(
          width: tamanho * 0.65,
          height: tamanho * 0.45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(tamanho * 0.12),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.play_arrow_rounded,
            color: const Color(0xFFFF0000),
            size: tamanho * 0.42,
          ),
        ),
      );
    }

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
                width: tamanho * 0.28,
                height: tamanho * 0.28,
                decoration: const BoxDecoration(
                  color: Color(0xFFEA4335), // vermelho
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 0,
              child: Container(
                width: tamanho * 0.28,
                height: tamanho * 0.28,
                decoration: const BoxDecoration(
                  color: Color(0xFF4285F4), // azul
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                width: tamanho * 0.28,
                height: tamanho * 0.28,
                decoration: const BoxDecoration(
                  color: Color(0xFF34A853), // verde
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 0,
              child: Container(
                width: tamanho * 0.28,
                height: tamanho * 0.28,
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

    if (normalizada.contains('telegram')) {
      return Container(
        color: const Color(0xFF229ED9),
        alignment: Alignment.center,
        child: Icon(
          Icons.send_rounded,
          color: Colors.white,
          size: tamanho * 0.58,
        ),
      );
    }

    if (normalizada.contains('gov')) {
      return Container(
        color: const Color(0xFF003399),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.account_balance_rounded,
              color: Colors.white,
              size: tamanho * 0.52,
            ),
            Text(
              'gov.br',
              style: TextStyle(
                color: const Color(0xFFFFCC29),
                fontSize: tamanho * 0.20,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
          ],
        ),
      );
    }

    if (normalizada.contains('inss')) {
      return Container(
        color: const Color(0xFF0B2B6B),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.health_and_safety_rounded,
              color: const Color(0xFFFFCC29),
              size: tamanho * 0.52,
            ),
            Text(
              'INSS',
              style: TextStyle(
                color: Colors.white,
                fontSize: tamanho * 0.22,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
          ],
        ),
      );
    }

    // Padrão genérico
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
