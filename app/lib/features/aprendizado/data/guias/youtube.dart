import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de passo a passo do YouTube (T071).
final Guia guiaYoutube = Guia(
  chave: 'youtube',
  titulo: TextosGuias.tituloYoutube,
  capturadoEm: DateTime(2026, 10),
  versaoCapturada: '19.38.0',
  passos: const <Passo>[
    Passo(
      captura: CapturaDoGuia.youtube1,
      destaque: RegiaoRelativa(x: 0.8, y: 0.05, largura: 0.15, altura: 0.06),
      texto: TextosGuias.youtubePasso1,
      descricaoDaCaptura: TextosGuias.youtubeCaptura1,
    ),
    Passo(
      captura: CapturaDoGuia.youtube2,
      destaque: RegiaoRelativa(x: 0.1, y: 0.05, largura: 0.75, altura: 0.06),
      texto: TextosGuias.youtubePasso2,
      descricaoDaCaptura: TextosGuias.youtubeCaptura2,
    ),
    Passo(
      captura: CapturaDoGuia.youtube3,
      destaque: RegiaoRelativa(x: 0.05, y: 0.15, largura: 0.9, altura: 0.25),
      texto: TextosGuias.youtubePasso3,
      descricaoDaCaptura: TextosGuias.youtubeCaptura3,
    ),
    Passo(
      captura: CapturaDoGuia.youtube4,
      destaque: RegiaoRelativa(x: 0.35, y: 0.2, largura: 0.3, altura: 0.15),
      texto: TextosGuias.youtubePasso4,
      descricaoDaCaptura: TextosGuias.youtubeCaptura4,
    ),
  ],
);

