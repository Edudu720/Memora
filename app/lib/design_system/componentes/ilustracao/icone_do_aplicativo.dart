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
    final String normalizada = _normalizarChave(
      chave.isNotEmpty ? chave : (nome ?? ''),
    );

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

  /// Mapa constante dos 10 ícones vetoriais compartilhados em
  /// `assets/icones_apps/` (Feature 016 Item 6 + Feature 019 Item 13).
  static const Map<String, String> _iconesSvgPorChave = <String, String>{
    'youtube': 'assets/icones_apps/youtube.svg',
    'tiktok': 'assets/icones_apps/tiktok.svg',
    'googlefotos': 'assets/icones_apps/google-fotos.svg',
    'meuinss': 'assets/icones_apps/meu-inss.svg',
    'poupatempo': 'assets/icones_apps/poupatempo.svg',
    'carteiradigital': 'assets/icones_apps/carteira-digital.svg',
    'carteiradetrabalho': 'assets/icones_apps/carteira-de-trabalho.svg',
    'instagram': 'assets/icones_apps/instagram.svg',
    'etitulo': 'assets/icones_apps/e-titulo.svg',
    'fgts': 'assets/icones_apps/fgts.svg',
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
    if (normalizada.contains('instagram')) {
      return _iconesSvgPorChave['instagram'];
    }
    if (normalizada.contains('titulo')) {
      return _iconesSvgPorChave['etitulo'];
    }
    if (normalizada.contains('fgts')) {
      return _iconesSvgPorChave['fgts'];
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

    // 11. Serasa (logo oficial fornecida)
    if (normalizada.contains('serasa')) {
      return Image.asset(
        'assets/ilustracoes/serasa_logo.png',
        width: tamanho,
        height: tamanho,
        fit: BoxFit.contain,
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

  static String _normalizarChave(String entrada) {
    final String semAcento = entrada
        .toLowerCase()
        .replaceAll(RegExp(r'[áàãâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòõôö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c');
    return semAcento.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
