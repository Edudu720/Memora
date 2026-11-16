import 'package:flutter/material.dart';

import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de passo a passo do Telegram organizado em seções (T072).
final Guia guiaTelegram = Guia(
  chave: 'telegram',
  titulo: TextosGuias.tituloTelegram,
  capturadoEm: DateTime(2026, 11),
  versaoCapturada: '2026.11',
  secoes: const <SecaoDoGuia>[
    SecaoDoGuia(
      chave: 'conversas-contatos',
      titulo: TextosGuias.telegramSecao1Titulo,
      subtitulo: TextosGuias.telegramSecao1Subtitulo,
      icone: Icons.chat_bubble_outline,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.telegram1,
          destaque: RegiaoRelativa(x: 0.08, y: 0.10, largura: 0.84, altura: 0.75),
          texto: TextosGuias.telegramPasso1,
          descricaoDaCaptura: TextosGuias.telegramCaptura1,
        ),
        Passo(
          captura: CapturaDoGuia.telegram2,
          destaque: RegiaoRelativa(x: 0.08, y: 0.10, largura: 0.84, altura: 0.75),
          texto: TextosGuias.telegramPasso2,
          descricaoDaCaptura: TextosGuias.telegramCaptura2,
        ),
        Passo(
          captura: CapturaDoGuia.telegram3,
          destaque: RegiaoRelativa(x: 0.08, y: 0.10, largura: 0.84, altura: 0.75),
          texto: TextosGuias.telegramPasso3,
          descricaoDaCaptura: TextosGuias.telegramCaptura3,
        ),
        Passo(
          captura: CapturaDoGuia.telegram4,
          destaque: RegiaoRelativa(x: 0.08, y: 0.10, largura: 0.84, altura: 0.75),
          texto: TextosGuias.telegramPasso4,
          descricaoDaCaptura: TextosGuias.telegramCaptura4,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'perfil-configuracoes',
      titulo: TextosGuias.telegramSecao2Titulo,
      subtitulo: TextosGuias.telegramSecao2Subtitulo,
      icone: Icons.settings_outlined,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.telegram5,
          destaque: RegiaoRelativa(x: 0.08, y: 0.10, largura: 0.84, altura: 0.75),
          texto: TextosGuias.telegramPasso5,
          descricaoDaCaptura: TextosGuias.telegramCaptura5,
        ),
        Passo(
          captura: CapturaDoGuia.telegram6,
          destaque: RegiaoRelativa(x: 0.08, y: 0.10, largura: 0.84, altura: 0.75),
          texto: TextosGuias.telegramPasso6,
          descricaoDaCaptura: TextosGuias.telegramCaptura6,
        ),
        Passo(
          captura: CapturaDoGuia.telegram7,
          destaque: RegiaoRelativa(x: 0.08, y: 0.10, largura: 0.84, altura: 0.75),
          texto: TextosGuias.telegramPasso7,
          descricaoDaCaptura: TextosGuias.telegramCaptura7,
        ),
        Passo(
          captura: CapturaDoGuia.telegram8,
          destaque: RegiaoRelativa(x: 0.08, y: 0.10, largura: 0.84, altura: 0.75),
          texto: TextosGuias.telegramPasso8,
          descricaoDaCaptura: TextosGuias.telegramCaptura8,
        ),
      ],
    ),
  ],
);
