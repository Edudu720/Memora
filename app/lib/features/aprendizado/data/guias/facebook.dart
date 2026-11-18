import 'package:flutter/material.dart';

import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de passo a passo do Facebook organizado em seções (T072).
final Guia guiaFacebook = Guia(
  chave: 'facebook',
  titulo: TextosGuias.tituloFacebook,
  capturadoEm: DateTime(2026, 11),
  versaoCapturada: '2026.11',
  secoes: const <SecaoDoGuia>[
    SecaoDoGuia(
      chave: 'feed-reels-marketplace',
      titulo: TextosGuias.facebookSecao1Titulo,
      subtitulo: TextosGuias.facebookSecao1Subtitulo,
      icone: Icons.home_rounded,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.facebook1,
          destaque: RegiaoRelativa(x: 0.08, y: 0.10, largura: 0.84, altura: 0.70),
          texto: TextosGuias.facebookPasso1,
          descricaoDaCaptura: TextosGuias.facebookCaptura1,
        ),
        Passo(
          captura: CapturaDoGuia.facebook2,
          destaque: RegiaoRelativa(x: 0.08, y: 0.10, largura: 0.84, altura: 0.75),
          texto: TextosGuias.facebookPasso2,
          descricaoDaCaptura: TextosGuias.facebookCaptura2,
        ),
        Passo(
          captura: CapturaDoGuia.facebook3,
          destaque: RegiaoRelativa(x: 0.08, y: 0.10, largura: 0.84, altura: 0.70),
          texto: TextosGuias.facebookPasso3,
          descricaoDaCaptura: TextosGuias.facebookCaptura3,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'amigos-notificacoes-menu',
      titulo: TextosGuias.facebookSecao2Titulo,
      subtitulo: TextosGuias.facebookSecao2Subtitulo,
      icone: Icons.people_outline_rounded,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.facebook4,
          destaque: RegiaoRelativa(x: 0.08, y: 0.10, largura: 0.84, altura: 0.70),
          texto: TextosGuias.facebookPasso4,
          descricaoDaCaptura: TextosGuias.facebookCaptura4,
        ),
        Passo(
          captura: CapturaDoGuia.facebook5,
          destaque: RegiaoRelativa(x: 0.08, y: 0.10, largura: 0.84, altura: 0.70),
          texto: TextosGuias.facebookPasso5,
          descricaoDaCaptura: TextosGuias.facebookCaptura5,
        ),
        Passo(
          captura: CapturaDoGuia.facebook6,
          destaque: RegiaoRelativa(x: 0.08, y: 0.10, largura: 0.84, altura: 0.75),
          texto: TextosGuias.facebookPasso6,
          descricaoDaCaptura: TextosGuias.facebookCaptura6,
        ),
        Passo(
          captura: CapturaDoGuia.facebook7,
          destaque: RegiaoRelativa(x: 0.08, y: 0.10, largura: 0.84, altura: 0.75),
          texto: TextosGuias.facebookPasso7,
          descricaoDaCaptura: TextosGuias.facebookCaptura7,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'perfil-informacoes',
      titulo: TextosGuias.facebookSecao3Titulo,
      subtitulo: TextosGuias.facebookSecao3Subtitulo,
      icone: Icons.person_outline_rounded,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.facebook8,
          destaque: RegiaoRelativa(x: 0.08, y: 0.10, largura: 0.84, altura: 0.75),
          texto: TextosGuias.facebookPasso8,
          descricaoDaCaptura: TextosGuias.facebookCaptura8,
        ),
        Passo(
          captura: CapturaDoGuia.facebook9,
          destaque: RegiaoRelativa(x: 0.08, y: 0.10, largura: 0.84, altura: 0.75),
          texto: TextosGuias.facebookPasso9,
          descricaoDaCaptura: TextosGuias.facebookCaptura9,
        ),
        Passo(
          captura: CapturaDoGuia.facebook10,
          destaque: RegiaoRelativa(x: 0.08, y: 0.10, largura: 0.84, altura: 0.75),
          texto: TextosGuias.facebookPasso10,
          descricaoDaCaptura: TextosGuias.facebookCaptura10,
        ),
      ],
    ),
  ],
);
