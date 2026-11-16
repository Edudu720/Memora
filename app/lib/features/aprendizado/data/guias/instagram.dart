import 'package:flutter/material.dart' show Icons;

import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de passo a passo do Instagram (T071; refeito na T135).
///
/// Doze telas úteis, então cinco seções (FR-028d), todas partindo do início do
/// aplicativo (captura 1), que aparece em cada uma destacando um botão
/// diferente.
///
/// **As imagens são prints do Galaxy S20 FE com os dados pessoais trocados**:
/// a interface é a do aparelho, e a IA só substituiu nomes, fotos e
/// conteúdo por uma conta e pessoas fictícias (FR-028). A capa de música do
/// story (captura 11) é obra publicada, não dado pessoal (clarify de
/// 2026-11-13).
final Guia guiaInstagram = Guia(
  chave: 'instagram',
  titulo: TextosGuias.tituloInstagram,
  capturadoEm: DateTime(2026, 11),
  versaoCapturada: 'a confirmar',
  secoes: const <SecaoDoGuia>[
    SecaoDoGuia(
      chave: 'ver',
      titulo: TextosGuias.instagramSecaoVer,
      subtitulo: TextosGuias.instagramSecaoVerSubtitulo,
      icone: Icons.photo_library_outlined,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.instagram1,
          // Curtir, comentar e enviar, embaixo da foto.
          destaque: RegiaoRelativa(x: 0.01, y: 0.89, largura: 0.30, altura: 0.05),
          texto: TextosGuias.instagramVer1,
          descricaoDaCaptura: TextosGuias.instagramCaptura1,
        ),
        Passo(
          captura: CapturaDoGuia.instagram1,
          // O story de um amigo, no alto.
          destaque: RegiaoRelativa(x: 0.27, y: 0.08, largura: 0.24, altura: 0.155),
          texto: TextosGuias.instagramVerStory1,
          descricaoDaCaptura: TextosGuias.instagramCaptura1,
        ),
        Passo(
          captura: CapturaDoGuia.instagram11,
          // "Enviar mensagem", embaixo.
          destaque: RegiaoRelativa(x: 0.01, y: 0.92, largura: 0.66, altura: 0.065),
          texto: TextosGuias.instagramVerStory2,
          descricaoDaCaptura: TextosGuias.instagramCaptura11,
        ),
        Passo(
          captura: CapturaDoGuia.instagram1,
          // A aba Reels, embaixo.
          destaque: RegiaoRelativa(x: 0.24, y: 0.945, largura: 0.12, altura: 0.05),
          texto: TextosGuias.instagramVer2,
          descricaoDaCaptura: TextosGuias.instagramCaptura1,
        ),
        Passo(
          captura: CapturaDoGuia.instagram2,
          // Curtir, comentar e compartilhar, à direita.
          destaque: RegiaoRelativa(x: 0.85, y: 0.46, largura: 0.13, altura: 0.33),
          texto: TextosGuias.instagramVer3,
          descricaoDaCaptura: TextosGuias.instagramCaptura2,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'story',
      titulo: TextosGuias.instagramSecaoStory,
      subtitulo: TextosGuias.instagramSecaoStorySubtitulo,
      icone: Icons.add_circle_outline,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.instagram1,
          // "Seu story", no alto, à esquerda.
          destaque: RegiaoRelativa(x: 0.02, y: 0.08, largura: 0.24, altura: 0.155),
          texto: TextosGuias.instagramStory1,
          descricaoDaCaptura: TextosGuias.instagramCaptura1,
        ),
        Passo(
          captura: CapturaDoGuia.instagram3,
          // Uma foto em "Recentes".
          destaque: RegiaoRelativa(x: 0.34, y: 0.33, largura: 0.33, altura: 0.225),
          texto: TextosGuias.instagramStory2,
          descricaoDaCaptura: TextosGuias.instagramCaptura3,
        ),
        Passo(
          captura: CapturaDoGuia.instagram4,
          // O botão "Seu story", embaixo, à esquerda.
          destaque: RegiaoRelativa(x: 0.03, y: 0.935, largura: 0.42, altura: 0.06),
          texto: TextosGuias.instagramStory3,
          descricaoDaCaptura: TextosGuias.instagramCaptura4,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'avisos-e-mensagens',
      titulo: TextosGuias.instagramSecaoAvisos,
      subtitulo: TextosGuias.instagramSecaoAvisosSubtitulo,
      icone: Icons.notifications_none,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.instagram1,
          // O coração, no alto, à direita.
          destaque: RegiaoRelativa(x: 0.76, y: 0.01, largura: 0.09, altura: 0.055),
          texto: TextosGuias.instagramAvisos1,
          descricaoDaCaptura: TextosGuias.instagramCaptura1,
        ),
        Passo(
          captura: CapturaDoGuia.instagram5,
          // Uma sugestão de perfil para seguir.
          destaque: RegiaoRelativa(x: 0.01, y: 0.305, largura: 0.98, altura: 0.075),
          texto: TextosGuias.instagramAvisos2,
          descricaoDaCaptura: TextosGuias.instagramCaptura5,
        ),
        Passo(
          captura: CapturaDoGuia.instagram1,
          // O aviãozinho de papel, embaixo, no meio.
          destaque: RegiaoRelativa(x: 0.44, y: 0.945, largura: 0.12, altura: 0.05),
          texto: TextosGuias.instagramAvisos3,
          descricaoDaCaptura: TextosGuias.instagramCaptura1,
        ),
        Passo(
          captura: CapturaDoGuia.instagram6,
          // A primeira conversa da lista.
          destaque: RegiaoRelativa(x: 0.01, y: 0.39, largura: 0.98, altura: 0.08),
          texto: TextosGuias.instagramAvisos4,
          descricaoDaCaptura: TextosGuias.instagramCaptura6,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'procurar',
      titulo: TextosGuias.instagramSecaoProcurar,
      subtitulo: TextosGuias.instagramSecaoProcurarSubtitulo,
      icone: Icons.search,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.instagram1,
          // A lupa, embaixo.
          destaque: RegiaoRelativa(x: 0.64, y: 0.945, largura: 0.12, altura: 0.05),
          texto: TextosGuias.instagramProcurar1,
          descricaoDaCaptura: TextosGuias.instagramCaptura1,
        ),
        Passo(
          captura: CapturaDoGuia.instagram7,
          // A barra de pesquisa, no alto.
          destaque: RegiaoRelativa(x: 0.01, y: 0.005, largura: 0.87, altura: 0.05),
          texto: TextosGuias.instagramProcurar2,
          descricaoDaCaptura: TextosGuias.instagramCaptura7,
        ),
        Passo(
          captura: CapturaDoGuia.instagram8,
          // O primeiro nome das pesquisas recentes.
          destaque: RegiaoRelativa(x: 0.01, y: 0.115, largura: 0.85, altura: 0.075),
          texto: TextosGuias.instagramProcurar3,
          descricaoDaCaptura: TextosGuias.instagramCaptura8,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'conta-privada',
      titulo: TextosGuias.instagramSecaoPrivada,
      subtitulo: TextosGuias.instagramSecaoPrivadaSubtitulo,
      icone: Icons.lock_outline,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.instagram1,
          // A foto do perfil, embaixo, à direita.
          destaque: RegiaoRelativa(x: 0.84, y: 0.945, largura: 0.13, altura: 0.05),
          texto: TextosGuias.instagramPrivada1,
          descricaoDaCaptura: TextosGuias.instagramCaptura1,
        ),
        Passo(
          captura: CapturaDoGuia.instagram9,
          // As três linhas, no alto, à direita.
          destaque: RegiaoRelativa(x: 0.91, y: 0.005, largura: 0.085, altura: 0.055),
          texto: TextosGuias.instagramPrivada2,
          descricaoDaCaptura: TextosGuias.instagramCaptura9,
        ),
        Passo(
          captura: CapturaDoGuia.instagram10,
          // "Privacidade da conta", embaixo.
          destaque: RegiaoRelativa(x: 0.01, y: 0.93, largura: 0.98, altura: 0.055),
          texto: TextosGuias.instagramPrivada3,
          descricaoDaCaptura: TextosGuias.instagramCaptura10,
        ),
      ],
    ),
  ],
);
