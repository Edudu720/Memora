import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de passo a passo do YouTube (T071 + Feature 016).
final Guia guiaYoutube = Guia(
  chave: 'youtube',
  titulo: TextosGuias.tituloYoutube,
  capturadoEm: DateTime(2026, 11, 19),
  versaoCapturada: '19.38.0',
  passos: const <Passo>[
    Passo(
      captura: CapturaDoGuia.youtube1,
      // Vídeo em destaque na tela inicial.
      destaque: RegiaoRelativa(x: 0.02, y: 0.02, largura: 0.96, altura: 0.34),
      texto: TextosGuias.youtubePasso1,
      descricaoDaCaptura: TextosGuias.youtubeCaptura1,
    ),
    Passo(
      captura: CapturaDoGuia.youtube2,
      // Lupa de pesquisa no alto à direita.
      destaque: RegiaoRelativa(x: 0.88, y: 0.015, largura: 0.11, altura: 0.065),
      texto: TextosGuias.youtubePasso2,
      descricaoDaCaptura: TextosGuias.youtubeCaptura2,
    ),
    Passo(
      captura: CapturaDoGuia.youtube3,
      // Aba Shorts na barra inferior.
      destaque: RegiaoRelativa(x: 0.30, y: 0.94, largura: 0.16, altura: 0.055),
      texto: TextosGuias.youtubePasso3,
      descricaoDaCaptura: TextosGuias.youtubeCaptura3,
    ),
    Passo(
      captura: CapturaDoGuia.youtube4,
      // Aba Inscrições no alto à esquerda.
      destaque: RegiaoRelativa(x: 0.16, y: 0.07, largura: 0.22, altura: 0.045),
      texto: TextosGuias.youtubePasso4,
      descricaoDaCaptura: TextosGuias.youtubeCaptura4,
    ),
    Passo(
      captura: CapturaDoGuia.youtube5,
      // Bloco Histórico na aba Você.
      destaque: RegiaoRelativa(x: 0.03, y: 0.24, largura: 0.94, altura: 0.22),
      texto: TextosGuias.youtubePasso5,
      descricaoDaCaptura: TextosGuias.youtubeCaptura5,
    ),
    Passo(
      captura: CapturaDoGuia.youtube6,
      // Barra de abas dentro do canal.
      destaque: RegiaoRelativa(x: 0.03, y: 0.425, largura: 0.86, altura: 0.055),
      texto: TextosGuias.youtubePasso6,
      descricaoDaCaptura: TextosGuias.youtubeCaptura6,
    ),
    Passo(
      captura: CapturaDoGuia.youtube7,
      // Aba Mais no alto à direita.
      destaque: RegiaoRelativa(x: 0.68, y: 0.07, largura: 0.16, altura: 0.045),
      texto: TextosGuias.youtubePasso7,
      descricaoDaCaptura: TextosGuias.youtubeCaptura7,
    ),
  ],
);

